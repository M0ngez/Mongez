"""Account deletion: one-time signed tokens + PII anonymization.

We never call ``user.delete()``. Doing so would CASCADE through
``Order.client``, ``CommissionPayment`` and ``Rating`` — so a *client*
asking to leave would wipe a technician's work history, their earnings
ledger and the reviews other clients left. Instead we strip every
personally identifiable field in place and flip ``is_active`` off. The
row survives, every foreign key still resolves, and nothing PII remains.

The confirm step runs on the marketing site, which has no client login
(the only ``/login`` route is the admin dashboard). So the mobile app
mints a short-lived HMAC-signed token and hands the browser a URL that
carries it — no web session required.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import logging
import os
import re
import time
import uuid
from pathlib import Path

from django.conf import settings
from django.db import transaction
from django.db.models import Q

logger = logging.getLogger(__name__)

#: Long enough to read the confirmation screen, short enough that a leaked
#: URL is useless later.
TOKEN_TTL_SECONDS = 15 * 60

#: Order states where someone is still waiting on this person — a client
#: with an open job, or a technician who already accepted one. Deleting
#: mid-flight would strand the other party, so we refuse instead.
ACTIVE_ORDER_STATUSES = ("PENDING", "ACCEPTED", "WAITING_CONFIRMATION")

_AUDIO_EXT = {".m4a", ".mp3", ".aac", ".wav", ".ogg", ".opus", ".webm"}
_VIDEO_EXT = {".mp4", ".mov", ".mkv"}


# ── guards ────────────────────────────────────────────────────────────


def active_order_count(user) -> int:
    """Orders on either side of this user that are still in flight.

    Imported lazily: ``apps.orders`` imports ``User`` at module scope, so
    importing it here would be circular.
    """
    from apps.orders.models import Order

    return (
        Order.objects.filter(
            Q(client=user) | Q(worker=user),
            status__in=ACTIVE_ORDER_STATUSES,
        )
        .distinct()
        .count()
    )


# ── one-time token ────────────────────────────────────────────────────


def _sign(body: str) -> str:
    return hmac.new(
        settings.SECRET_KEY.encode(), body.encode(), hashlib.sha256
    ).hexdigest()


def issue_deletion_token(user) -> str:
    """Mint a single-use token bound to ``user``.

    The nonce is persisted on the row, so replaying a captured URL after
    a successful deletion (or after a fresh token was issued) fails.
    """
    nonce = uuid.uuid4().hex
    user.deletion_nonce = nonce
    user.save(update_fields=["deletion_nonce"])

    payload = json.dumps(
        {"uid": user.pk, "exp": int(time.time()) + TOKEN_TTL_SECONDS, "n": nonce}
    )
    body = base64.urlsafe_b64encode(payload.encode()).decode()
    return f"{body}.{_sign(body)}"


def verify_deletion_token(token: str):
    """Return the live ``User`` a token authorizes, or ``None``."""
    from .models import User

    if not token or "." not in token:
        return None

    body, sig = token.split(".", 1)
    if not hmac.compare_digest(_sign(body), sig):
        return None

    try:
        data = json.loads(base64.urlsafe_b64decode(body.encode()).decode())
        uid, exp, nonce = data["uid"], int(data["exp"]), data["n"]
    except Exception:
        return None

    if exp < time.time():
        return None

    # is_active guards the "already deleted" replay; deletion_nonce makes
    # the token one-shot.
    return User.objects.filter(pk=uid, is_active=True, deletion_nonce=nonce).first()


def deletion_url(token: str) -> str:
    base = (
        os.getenv("FRONTEND_URL", "").strip().rstrip("/")
        or "https://mongez-psi.vercel.app"
    )
    return f"{base}/delete-account?token={token}"


# ── file cleanup ──────────────────────────────────────────────────────


def _public_id(url: str) -> str | None:
    """Pull the Cloudinary public_id out of a stored media URL.

    ``django-cloudinary-storage`` writes
    ``https://res.cloudinary.com/<cloud>/image/upload/v1234/<name>`` — the
    version segment is not part of the public_id and must be dropped.
    """
    if not url:
        return None

    if "res.cloudinary.com" in url:
        if "/upload/" not in url:
            return None
        pid = url.split("/upload/", 1)[1].split("?", 1)[0]
        return re.sub(r"^v\d+/", "", pid) or None

    # Local dev fallback: strip MEDIA_URL to get the path under MEDIA_ROOT.
    media_url = settings.MEDIA_URL or "/media/"
    if url.startswith(media_url):
        return url[len(media_url):].lstrip("/")
    return None


def _resource_type(public_id: str) -> str:
    ext = Path(public_id).suffix.lower()
    if ext in _AUDIO_EXT:
        return "audio"
    if ext in _VIDEO_EXT:
        return "video"
    return "image"


def _destroy_files(urls) -> None:
    """Best-effort removal of the media backing ``urls``.

    Runs after the DB commit: a Cloudinary hiccup must not roll back an
    anonymization that already succeeded. A failure here is logged, not
    raised — the PII in the database is what Play audits.
    """
    if not urls:
        return

    cloudinary_configured = bool(settings.CLOUDINARY_STORAGE.get("CLOUD_NAME"))

    if cloudinary_configured:
        import cloudinary

        for url in urls:
            pid = _public_id(url)
            if not pid:
                continue
            try:
                cloudinary.uploader.destroy(pid, resource_type=_resource_type(pid))
            except Exception:
                logger.warning("cloudinary destroy failed for %s", pid, exc_info=True)
        return

    # Local storage (no CLOUDINARY_CLOUD_NAME set).
    for url in urls:
        pid = _public_id(url)
        if not pid:
            continue
        try:
            path = Path(settings.MEDIA_ROOT) / pid
            if path.is_file():
                path.unlink()
        except OSError:
            logger.warning("local media delete failed for %s", pid, exc_info=True)


# ── the anonymization itself ──────────────────────────────────────────


def _collect_files(user) -> list[str]:
    """Every media URL that belongs to this person.

    Order photos and voice notes are the client's own problem
    description and voice, so they go. Attachments on orders where this
    user is the *technician* belong to someone else and stay.
    """
    urls = []
    for field in (user.avatar, user.id_card_image):
        if field:
            urls.append(field.url)

    from apps.orders.models import OrderAttachment

    urls += [
        a.file.url
        for a in OrderAttachment.objects.filter(order__client=user).exclude(file="")
    ]
    return urls


def anonymize_user(user) -> dict:
    """Strip PII from ``user`` and everything hanging off it.

    Returns per-object deletion counts for the response/log. Never raises
    out of the Cloudinary step.
    """
    from apps.notifications.models import DeviceToken, Notification
    from apps.workers.models import WorkerProfile
    from .models import Address

    files = _collect_files(user)
    counts: dict[str, int] = {}

    with transaction.atomic():
        user.first_name = ""
        user.last_name = ""
        user.name_ar = ""
        user.email = ""
        user.phone = ""
        user.address = ""
        user.governorate = ""
        user.city = ""
        user.avatar = None
        user.id_card_image = None
        user.google_picture_url = ""
        # google_id is the OAuth subject — it ties the row back to a real
        # Google account, so it must go. Clearing it also means signing in
        # again starts a genuinely fresh account instead of resurrecting
        # this one (GoogleSignInView uses get_or_create on this column).
        user.google_id = None
        # username embeds the Google sub (``google_<sub>``) and is unique.
        user.username = f"deleted_{uuid.uuid4().hex[:24]}"
        # Random plaintext would be a valid-looking hash; set_unusable marks
        # it so authenticate() can never match it.
        user.set_unusable_password()
        user.deletion_nonce = ""
        user.is_active = False
        user.save()

        # Pre-computed so we still log counts if a queryset cascades.
        counts["addresses"] = Address.objects.filter(user=user).delete()[1].get(
            "users.Address", 0
        )
        counts["notifications"] = Notification.objects.filter(user=user).delete()[1].get(
            "notifications.Notification", 0
        )
        counts["device_tokens"] = DeviceToken.objects.filter(user=user).delete()[1].get(
            "notifications.DeviceToken", 0
        )
        # OneToOne, CASCADE: removes the row rather than leaving a blank
        # profile the admin worker list would keep counting.
        counts["worker_profile"] = WorkerProfile.objects.filter(user=user).delete()[1].get(
            "workers.WorkerProfile", 0
        )

        # Orders, their attachments (for jobs this user opened), the
        # commission ledger and every Rating are deliberately untouched.
        # See the module docstring.

    _destroy_files(files)
    counts["files"] = len(files)
    return counts
