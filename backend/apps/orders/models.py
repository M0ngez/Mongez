from django.db import models
from django.utils import timezone
from datetime import timedelta
from apps.users.models import User, Address
from apps.workers.models import ServiceCategory


class Order(models.Model):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    # Worker pressed "Mark as finished" but the client hasn't signed off
    # yet. Two-step completion: the order doesn't actually finish (no
    # completion timestamp, no completed_jobs bump) until the client
    # explicitly confirms.
    WAITING_CONFIRMATION = "WAITING_CONFIRMATION"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"

    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (ACCEPTED, "Accepted"),
        (WAITING_CONFIRMATION, "Waiting for client confirmation"),
        (REJECTED, "Rejected"),
        (CANCELLED, "Cancelled"),
        (COMPLETED, "Completed"),
    ]

    # Why a cancellation happened — set by the cancelling party (client or
    # admin). Nullable so older orders and non-stated reasons stay honest:
    # we never assume a reason nobody recorded.
    WORKER_DELAY = "WORKER_DELAY"
    CANCELLATION_OTHER = "OTHER"
    CANCELLATION_REASON_CHOICES = [
        (WORKER_DELAY, "Worker delay"),
        (CANCELLATION_OTHER, "Other"),
    ]

    URGENCY_LOW = "LOW"
    URGENCY_NORMAL = "NORMAL"
    URGENCY_HIGH = "HIGH"
    URGENCY_CHOICES = [
        (URGENCY_LOW, "Whenever"),
        (URGENCY_NORMAL, "Today"),
        (URGENCY_HIGH, "Now / Emergency"),
    ]

    client = models.ForeignKey(
        User,
        on_delete = models.CASCADE,
        related_name = "my_orders",
    )
    worker = models.ForeignKey(
        User,
        on_delete = models.SET_NULL,
        null = True,
        blank = True,
        related_name = "assigned_orders",
    )

    service_category = models.ForeignKey(
        ServiceCategory,
        on_delete = models.PROTECT,
    )

    # Problem description (what the client wrote)
    description = models.TextField(
        blank=True, max_length=2000,
        help_text="What the client wrote about the issue.",
    )
    address = models.ForeignKey(
        Address,
        on_delete = models.SET_NULL,
        null = True,
        blank = True,
        related_name = "orders",
    )
    address_text = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True,
    )
    urgency = models.CharField(
        max_length=10, choices=URGENCY_CHOICES, default=URGENCY_NORMAL,
    )
    scheduled_for = models.DateTimeField(null=True, blank=True)

    commission = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(
        max_length = 20,
        choices = STATUS_CHOICES,
        default = PENDING,
    )
    cancellation_reason = models.CharField(
        max_length=20, choices=CANCELLATION_REASON_CHOICES,
        null=True, blank=True,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    accepted_at  = models.DateTimeField(null=True, blank=True)
    # Worker pressed "Mark as finished" — the job is physically done but
    # we wait for the client's confirmation before flipping to COMPLETED.
    marked_finished_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["client", "-created_at"]),
            models.Index(fields=["worker", "-created_at"]),
        ]

    def __str__(self):
        return f"Order #{self.id} [{self.status}] — {self.client.username}"

    @classmethod
    def behavior_summary(cls, user, recent_days=30, lookup="client"):
        """Order behavior summary, computed server-side so any
        consumer (admin profile page, future dashboard cards, CSVs) sees
        the same numbers.

        `lookup` selects which side of the order the summary describes:
        "client" (orders a client placed) or "worker" (orders assigned to
        a worker). Defaults to "client", matching the UserProfile page.

        Uses real data only. Cancellations are split into the two buckets
        the cancel endpoint distinguishes: those charged to the worker
        (WORKER_DELAY — the client cancelled only once the 1-hour window
        had elapsed, i.e. the worker was late) and every other one
        (cancelled_by_client). The two always add up to `cancelled_orders`
        so the admin UI can render the breakdown without arithmetic gaps,
        and `cancelled_by_client` is used instead of a strict OTHER filter
        so a legacy row with a blank reason can't fall between them.
        Cancellations that are *not* the client's fault are still reported
        separately so they can be excluded from client-behavior signals
        downstream.
        """
        qs = cls.objects.filter(**{f"{lookup}": user})
        cancelled = qs.filter(status=cls.CANCELLED)
        total = qs.count()

        since = timezone.now() - timedelta(days=recent_days)
        delay_cancellations = cancelled.filter(
            cancellation_reason=cls.WORKER_DELAY,
        )
        return {
            "total_orders": total,
            "completed_orders": qs.filter(status=cls.COMPLETED).count(),
            "cancelled_orders": cancelled.count(),
            "cancellation_rate": round(cancelled.count() / total * 100, 1) if total else 0.0,
            "recent_cancellations_30d": cancelled.filter(
                cancelled_at__gte=since,
            ).count(),
            "cancelled_due_to_worker_delay": delay_cancellations.count(),
            "cancelled_by_client": cancelled.exclude(
                cancellation_reason=cls.WORKER_DELAY,
            ).count(),
        }


class OrderAttachment(models.Model):
    """Photo or audio note a client attaches to an order to explain the issue."""

    KIND_IMAGE = "image"
    KIND_AUDIO = "audio"
    KIND_VIDEO = "video"
    KIND_CHOICES = [
        (KIND_IMAGE, "Image"),
        (KIND_AUDIO, "Audio"),
        (KIND_VIDEO, "Video"),
    ]

    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, related_name="attachments",
    )
    kind = models.CharField(max_length=10, choices=KIND_CHOICES, default=KIND_IMAGE)
    file = models.FileField(upload_to="order_attachments/%Y/%m/")
    caption = models.CharField(max_length=255, blank=True)
    duration_seconds = models.PositiveIntegerField(
        null=True, blank=True,
        help_text="For audio/video: clip length in seconds.",
    )
    size_bytes = models.PositiveBigIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Attachment {self.kind} for Order #{self.order_id}"

    def save(self, *args, **kwargs):
        # Auto-fill size when possible.
        if self.file and not self.size_bytes:
            try:
                self.size_bytes = self.file.size
            except Exception:
                pass
        super().save(*args, **kwargs)
