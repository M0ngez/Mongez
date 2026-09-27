import os
import logging
import urllib.request

from django.conf import settings
from django.contrib.auth import authenticate
from django.core.files.base import ContentFile
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

import google.oauth2.id_token
import google.auth.transport.requests

from config.throttling import AuthRateThrottle, DeletionConfirmThrottle, DeletionMintThrottle
from config.permissions import IsProfileCompleted
from .deletion import (
    TOKEN_TTL_SECONDS,
    active_order_count,
    anonymize_user,
    deletion_url,
    issue_deletion_token,
    verify_deletion_token,
)
from .governorates import GOVERNORATES
from .models import Address, User
from .serializers import (
    AddressSerializer,
    UserSerializer,
    GoogleSignInSerializer,
    AdminLoginSerializer,
    CompleteProfileSerializer,
    UserUpdateSerializer,
)

logger = logging.getLogger(__name__)

GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_WEB_CLIENT_ID", "")


class GovernoratesView(APIView):
    """Static list of Egypt's 27 governorates with English + Arabic labels."""

    permission_classes = [AllowAny]

    def get(self, request):
        return Response(GOVERNORATES)


def get_tokens(user):
    """Generates JWT access + refresh tokens for a user."""
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }


class GoogleSignInView(APIView):
    """POST /api/auth/google/ — Verify Google id_token and return/create user."""

    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    def post(self, request):
        serializer = GoogleSignInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        id_token_str = serializer.validated_data["id_token"]

        logger.warning(f"[GOOGLE AUTH] GOOGLE_WEB_CLIENT_ID = '{GOOGLE_WEB_CLIENT_ID}'")
        logger.warning(f"[GOOGLE AUTH] id_token length = {len(id_token_str)}")

        if not GOOGLE_WEB_CLIENT_ID:
            logger.error("[GOOGLE AUTH] GOOGLE_WEB_CLIENT_ID is empty! Set it in .env")
            return Response(
                {"error": "Server config error: GOOGLE_WEB_CLIENT_ID not set."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        try:
            idinfo = google.oauth2.id_token.verify_oauth2_token(
                id_token_str,
                google.auth.transport.requests.Request(),
                GOOGLE_WEB_CLIENT_ID,
                clock_skew_in_seconds=10,
            )
            logger.warning(f"[GOOGLE AUTH] Token verified OK. email={idinfo.get('email')}, sub={idinfo.get('sub')}")
        except Exception as e:
            logger.error(f"[GOOGLE AUTH] Token verification FAILED: {type(e).__name__}: {e}")
            return Response(
                {"error": f"Invalid Google token: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not idinfo.get("email_verified", False):
            return Response(
                {"error": "Email not verified by Google."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        google_sub = idinfo["sub"]
        email = idinfo.get("email", "")
        name = idinfo.get("name", "")
        picture = idinfo.get("picture", "")

        user, created = User.objects.get_or_create(
            google_id=google_sub,
            defaults={
                "email": email,
                "name_ar": name,
                "username": f"google_{google_sub}",
                "profile_completed": False,
            },
        )

        if not created:
            if not user.is_active:
                return Response(
                    {"error": "This account has been deactivated."},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if email and not user.email:
                user.email = email
            if name and not user.name_ar:
                user.name_ar = name
            user.save(update_fields=["email", "name_ar"])

        if picture and not user.google_picture_url:
            user.google_picture_url = picture
            user.save(update_fields=["google_picture_url"])

        return Response(
            {
                "message": "Google sign-in successful.",
                "user": UserSerializer(user, context={"request": request}).data,
                "tokens": get_tokens(user),
                "profile_completed": user.profile_completed,
                "verification_status": user.verification_status,
                "google_picture_url": picture or "",
            },
            status=status.HTTP_200_OK,
        )


class AdminLoginView(APIView):
    """POST /api/auth/login/ — Username/password login for admin dashboard."""

    permission_classes = [AllowAny]
    throttle_classes = [AuthRateThrottle]

    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = authenticate(
            username=serializer.validated_data["username"],
            password=serializer.validated_data["password"],
        )
        if user is None:
            return Response(
                {"error": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if not user.is_active:
            return Response(
                {"error": "This account has been deactivated."},
                status=status.HTTP_403_FORBIDDEN,
            )

        return Response(
            {
                "user": UserSerializer(user, context={"request": request}).data,
                "tokens": get_tokens(user),
            },
            status=status.HTTP_200_OK,
        )


class CompleteProfileView(APIView):
    """PATCH /api/auth/complete-profile/ — Complete profile after Google Sign-In."""

    permission_classes = [IsAuthenticated]

    def patch(self, request):
        if request.user.profile_completed:
            return Response(
                {"error": "Profile already completed."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CompleteProfileSerializer(
            request.user,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        if serializer.is_valid():
            serializer.save()
            return Response(
                {
                    "message": "Profile completed successfully.",
                    "user": UserSerializer(request.user, context={"request": request}).data,
                    "verification_status": request.user.verification_status,
                }
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DeleteIncompleteProfileView(APIView):
    """DELETE /api/auth/delete-incomplete/ — Delete account if profile not completed."""

    permission_classes = [IsAuthenticated]

    def delete(self, request):
        if request.user.profile_completed:
            return Response(
                {"error": "Cannot delete a completed profile via this endpoint."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


def _active_orders_response(count):
    return Response(
        {
            "error": "Finish or cancel your open orders before deleting your account.",
            "code": "active_orders",
            "active_orders": count,
        },
        status=status.HTTP_409_CONFLICT,
    )


class DeletionTokenView(APIView):
    """POST /api/auth/deletion-token/ — mint a one-time deletion link.

    The marketing site has no client login (the only /login route is the
    admin dashboard), so instead of handing the browser a session we hand
    it a short-lived signed token the confirm endpoint can verify.
    """

    permission_classes = [IsAuthenticated]
    throttle_classes = [DeletionMintThrottle]

    def post(self, request):
        user = request.user
        if user.role == User.Role.ADMIN:
            return Response(
                {"error": "Admin accounts are managed from the dashboard."},
                status=status.HTTP_403_FORBIDDEN,
            )

        in_flight = active_order_count(user)
        if in_flight:
            return _active_orders_response(in_flight)

        token = issue_deletion_token(user)
        return Response(
            {
                "token": token,
                "url": deletion_url(token),
                "expires_in": TOKEN_TTL_SECONDS,
            }
        )


class DeleteAccountView(APIView):
    """POST /api/auth/delete-account/ — apply a deletion token.

    ``AllowAny`` because the caller is a browser tab with no session;
    authorisation is entirely the HMAC token, which is single-use and
    expires in TOKEN_TTL_SECONDS.
    """

    permission_classes = [AllowAny]
    throttle_classes = [DeletionConfirmThrottle]

    def post(self, request):
        token = (request.data.get("token") or "").strip()
        if not token:
            return Response(
                {"error": "Missing deletion token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = verify_deletion_token(token)
        if user is None:
            return Response(
                {"error": "This deletion link is invalid or has expired."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Statuses may have moved between minting the link and confirming.
        in_flight = active_order_count(user)
        if in_flight:
            return _active_orders_response(in_flight)

        counts = anonymize_user(user)
        logger.info("Account anonymized: user_id=%s %s", user.pk, counts)

        return Response({"deleted": True, "cleared": counts})


class MyProfileView(APIView):

    permission_classes = [IsAuthenticated, IsProfileCompleted]

    def get(self, request):
        return Response(
            UserSerializer(request.user, context={"request": request}).data
        )

    def patch(self, request):
        serializer = UserUpdateSerializer(
            request.user,
            data=request.data,
            partial=True,
        )
        if serializer.is_valid():
            serializer.save()
            return Response(
                UserSerializer(request.user, context={"request": request}).data
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    """POST /api/auth/logout/ — blacklist the supplied refresh token."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh = request.data.get("refresh")
        if not refresh:
            return Response(
                {"error": "Provide 'refresh' token to invalidate."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            RefreshToken(refresh).blacklist()
        except Exception:
            pass
        return Response({"message": "Logged out."})


def _ensure_default(user):
    """If the user has no default address, promote the first one."""
    if not Address.objects.filter(user=user, is_default=True).exists():
        first = Address.objects.filter(user=user).first()
        if first:
            first.is_default = True
            first.save()


def _sync_user_default_location(user):
    """Keep the user's public location in sync with their default address.

    Customers see the worker's location on the card/details from the User's
    address/city/governorate fields, so changing the default address must
    propagate there too.
    """
    default = Address.objects.filter(user=user, is_default=True).first()
    if not default:
        return
    fields = {}
    if default.city:
        fields["city"] = default.city
    if default.address:
        fields["address"] = default.address
    if default.governorate:
        fields["governorate"] = default.governorate
    if fields:
        User.objects.filter(pk=user.pk).update(**fields)


class AddressListCreateView(APIView):

    permission_classes = [IsAuthenticated, IsProfileCompleted]

    def get(self, request):
        addresses = Address.objects.filter(user=request.user).order_by("-is_default", "id")
        return Response(AddressSerializer(addresses, many=True).data)

    def post(self, request):
        serializer = AddressSerializer(data=request.data)
        if serializer.is_valid():
            if serializer.validated_data.get("is_default"):
                Address.objects.filter(user=request.user, is_default=True).update(is_default=False)
            serializer.save(user=request.user)
            # If user had 0 addresses, make the new one default automatically.
            _ensure_default(request.user)
            _sync_user_default_location(request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AddressDetailView(APIView):
    """PATCH /api/addresses/<id>/ — update address (set default, etc.)
    DELETE /api/addresses/<id>/ — delete an address."""

    permission_classes = [IsAuthenticated, IsProfileCompleted]

    def patch(self, request, pk):
        try:
            addr = Address.objects.get(pk=pk, user=request.user)
        except Address.DoesNotExist:
            return Response({"error": "Address not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = AddressSerializer(addr, data=request.data, partial=True)
        if serializer.is_valid():
            if serializer.validated_data.get("is_default"):
                Address.objects.filter(user=request.user, is_default=True).update(is_default=False)
            serializer.save()
            _ensure_default(request.user)
            _sync_user_default_location(request.user)
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        try:
            addr = Address.objects.get(pk=pk, user=request.user)
        except Address.DoesNotExist:
            return Response({"error": "Address not found."}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        count = Address.objects.filter(user=user).count()

        if count <= 1:
            return Response(
                {"error": "Cannot delete your only address. Please add another address first."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # If deleting the default, auto-promote another one before deletion.
        if addr.is_default:
            other = Address.objects.filter(user=user).exclude(pk=pk).first()
            if other:
                other.is_default = True
                other.save()

        addr.delete()
        _sync_user_default_location(user)
        return Response({"message": "Address deleted."}, status=status.HTTP_204_NO_CONTENT)
