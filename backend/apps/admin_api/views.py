import csv
from django.core.cache import cache
from django.db.models import Avg, Count, Sum, Q
from django.http import HttpResponse
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import JSONParser, FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated


def _coerce_bool(value):
    """Form-data sends booleans as strings; JSON sends actual booleans.
    Normalize so admin patch endpoints can accept either."""
    if isinstance(value, bool):
        return value
    if value is None:
        return None
    return str(value).strip().lower() in {"true", "1", "yes", "on"}

from apps.users.models import User
from apps.users.serializers import UserSerializer, AdminUserCreateSerializer
from apps.workers.models import ServiceCategory, WorkerProfile
from apps.workers.serializers import ServiceCategorySerializer, WorkerProfileSerializer
from apps.orders.models import Order
from apps.payments.models import CommissionPayment
from apps.ratings.models import Rating
from apps.ratings.serializers import RatingSerializer
from apps.notifications.services import notify
from apps.notifications.models import Notification


def admin_only(request):
    if request.user.role != User.Role.ADMIN:
        return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)


_DASHBOARD_STATS_CACHE_KEY = "admin_api:dashboard_stats:v1"
_DASHBOARD_STATS_TTL = 2  # seconds — admins want near-realtime numbers


def _bust_dashboard_cache():
    """Clear the dashboard stats aggregate after any mutation so the next
    poll (dashboard polls every 3 s) reflects the change immediately
    instead of waiting up to a TTL window."""
    cache.delete(_DASHBOARD_STATS_CACHE_KEY)


class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        # Stats aggregate is identical for every admin so we cache it for a
        # few seconds. The dashboard polls every 10 s; with 5 s TTL the
        # query runs at most ~every other poll regardless of how many
        # admins are viewing. The cache is read-through — first request
        # after expiry takes the hit and warms it back up.
        stats = cache.get(_DASHBOARD_STATS_CACHE_KEY)
        if stats is None:
            captured_payments = CommissionPayment.objects.filter(
                payment_status=CommissionPayment.CAPTURED,
            )
            stats = {
                "total_users": User.objects.count(),
                "total_clients": User.objects.filter(role=User.Role.CLIENT).count(),
                "total_workers": User.objects.filter(role=User.Role.WORKER).count(),
                "total_categories": ServiceCategory.objects.count(),
                "total_orders": Order.objects.count(),
                "total_payments": CommissionPayment.objects.count(),
                "total_revenue": captured_payments.aggregate(Sum("amount"))["amount__sum"] or 0,
                "orders_by_status": list(
                    Order.objects.values("status")
                    .annotate(count=Count("id"))
                    .order_by("status"),
                ),
            }
            cache.set(_DASHBOARD_STATS_CACHE_KEY, stats, _DASHBOARD_STATS_TTL)

        # Recent orders are not cached — they're per-request shape (URLs in
        # serializer depend on `request`) and we always want them fresh.
        recent_orders = Order.objects.select_related(
            "client", "worker", "service_category",
        ).order_by("-created_at")[:10]
        from apps.orders.serializers import OrderSerializer
        orders_data = OrderSerializer(
            recent_orders, many=True, context={"request": request},
        ).data

        return Response({"stats": stats, "recent_orders": orders_data})


class AdminUserListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        search = request.query_params.get("search", "")
        role = request.query_params.get("role", "")
        queryset = User.objects.all()
        if search:
            queryset = queryset.filter(Q(username__icontains=search) | Q(phone__icontains=search) | Q(email__icontains=search))
        if role:
            queryset = queryset.filter(role=role)

        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 20))
        start = (page - 1) * page_size
        end = start + page_size
        total = queryset.count()
        users = queryset.order_by("-date_joined")[start:end]

        return Response({
            "count": total,
            "page": page,
            "page_size": page_size,
            "results": UserSerializer(users, many=True, context={"request": request}).data,
        })


class AdminUserCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        serializer = AdminUserCreateSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            user = serializer.save()
            _bust_dashboard_cache()
            return Response(UserSerializer(user, context={"request": request}).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AdminUserDetailView(APIView):
    permission_classes = [IsAuthenticated]
    # MultiPartParser required so avatar uploads (FormData) reach the view.
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(UserSerializer(user, context={"request": request}).data)

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        # `profile_image` was a legacy alias kept here for the older mobile
        # build; it's been gone from both clients for a while now. Drop it.
        text_fields = ["username", "phone", "email", "address", "city",
                       "governorate", "name_ar", "role"]
        for key in text_fields:
            if key in request.data:
                setattr(user, key, request.data.get(key))

        if "is_active" in request.data:
            user.is_active = _coerce_bool(request.data.get("is_active"))

        # `avatar` arrives via request.FILES on multipart requests; DRF
        # exposes it through request.data too, but reading FILES is more
        # explicit about intent.
        avatar = request.FILES.get("avatar")
        if avatar is not None:
            user.avatar = avatar

        password = request.data.get("password")
        if password:
            user.set_password(password)

        user.save()
        _bust_dashboard_cache()
        return Response(UserSerializer(user, context={"request": request}).data)

    def delete(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)
        user.delete()
        _bust_dashboard_cache()
        return Response({"message": "User deleted."}, status=status.HTTP_204_NO_CONTENT)


class AdminCategoryUpdateDeleteView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            category = ServiceCategory.objects.get(pk=pk)
        except ServiceCategory.DoesNotExist:
            return Response({"error": "Category not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = ServiceCategorySerializer(category, data=request.data, partial=True, context={"request": request})
        if serializer.is_valid():
            serializer.save()
            _bust_dashboard_cache()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            category = ServiceCategory.objects.get(pk=pk)
        except ServiceCategory.DoesNotExist:
            return Response({"error": "Category not found."}, status=status.HTTP_404_NOT_FOUND)
        category.delete()
        _bust_dashboard_cache()
        return Response({"message": "Category deleted."}, status=status.HTTP_204_NO_CONTENT)


class AdminPaymentListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        payments = CommissionPayment.objects.select_related("order").all().order_by("-created_at")
        data = []
        for p in payments:
            data.append({
                "id": p.id,
                "order_id": p.order_id,
                "amount": str(p.amount),
                "payment_status": p.payment_status,
                "paymob_transaction_id": p.paymob_transaction_id,
                "created_at": p.created_at,
                "updated_at": p.updated_at,
            })
        return Response(data)


class AdminOrderStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            order = Order.objects.select_related("client", "worker", "service_category").get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get("status")
        valid_statuses = [s[0] for s in Order.STATUS_CHOICES]
        if new_status not in valid_statuses:
            return Response({"error": f"Invalid status. Must be one of: {', '.join(valid_statuses)}"}, status=status.HTTP_400_BAD_REQUEST)

        previous_status = order.status
        order.status = new_status
        now = timezone.now()
        if new_status == Order.ACCEPTED and not order.accepted_at:
            order.accepted_at = now
        elif new_status == Order.COMPLETED and not order.completed_at:
            order.completed_at = now
            if order.worker:
                profile = WorkerProfile.objects.filter(user=order.worker).first()
                if profile:
                    profile.completed_jobs += 1
                    profile.save(update_fields=["completed_jobs"])
        elif new_status == Order.CANCELLED and not order.cancelled_at:
            order.cancelled_at = now
            # Never leave a cancelled order without a reason — the admin UI
            # shows "—" for null, which reads as "unknown" next to the two
            # real buckets. An admin override carries no evidence the worker
            # was late, so it lands on OTHER rather than WORKER_DELAY.
            if not order.cancellation_reason:
                order.cancellation_reason = Order.CANCELLATION_OTHER
        order.save()
        _bust_dashboard_cache()

        # Fan out to the affected client (and worker, if assigned) so the
        # mobile sees the dashboard action immediately via the notification
        # poll + the order-list poll, instead of only via the order poll.
        # We mark it PUSH so FCM fires too when service account is configured.
        if previous_status != new_status:
            payload = {
                "order_id": order.id,
                "status": new_status,
                "changed_by": "admin",
            }
            if order.client_id:
                notify(
                    order.client,
                    notif_type=Notification.PUSH,
                    data=payload,
                    translation_key="admin_status_update_client",
                    translation_params={
                        "order_id": order.id,
                        "status": new_status,
                    },
                )
            if order.worker_id and order.worker_id != order.client_id:
                notify(
                    order.worker,
                    notif_type=Notification.PUSH,
                    data=payload,
                    translation_key="admin_status_update_worker",
                    translation_params={
                        "order_id": order.id,
                        "status": new_status,
                    },
                )

        from apps.orders.serializers import OrderSerializer
        return Response(OrderSerializer(order, context={"request": request}).data)


class AdminOrderListView(APIView):
    """GET /api/admin/orders/ — paginated, newest-first list of every
    order for the admin Orders page.

    Lives on /api/admin/ instead of reusing /api/orders/ on purpose: the
    public endpoint carries IsProfileCompleted, which rejects real admins
    (their profile_completed is False) — the admin page used to get a
    swallowed 403 and show an empty table. Admin only."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        queryset = Order.objects.select_related(
            "client", "worker", "service_category", "address",
        )

        status_filter = (request.query_params.get("status") or "").upper()
        if status_filter:
            valid = [s[0] for s in Order.STATUS_CHOICES]
            if status_filter not in valid:
                return Response(
                    {"error": f"Invalid status. Must be one of: {', '.join(valid)}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            queryset = queryset.filter(status=status_filter)

        # Lets the Orders page isolate worker-delay cancellations — the
        # list a manager actually reviews when holding a worker to account.
        reason_filter = (request.query_params.get("cancellation_reason") or "").upper()
        if reason_filter:
            valid_reasons = [c[0] for c in Order.CANCELLATION_REASON_CHOICES]
            if reason_filter not in valid_reasons:
                return Response(
                    {"error": f"Invalid cancellation_reason. Must be one of: {', '.join(valid_reasons)}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            queryset = queryset.filter(cancellation_reason=reason_filter)

        return Response(_paged_orders(request, queryset))


class AdminWorkerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        search = request.query_params.get("search", "")
        profile_status = (request.query_params.get("status") or "").lower()
        verification = (request.query_params.get("verification") or "").lower()

        queryset = User.objects.filter(role=User.Role.WORKER)
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) | Q(phone__icontains=search)
                | Q(name_ar__icontains=search) | Q(email__icontains=search)
            )

        # Profile completeness filter
        if profile_status == "complete":
            queryset = queryset.filter(worker_profile__isnull=False)
        elif profile_status == "incomplete":
            queryset = queryset.filter(worker_profile__isnull=True)

        # Verification status filter
        if verification in ("pending", "verified", "rejected"):
            queryset = queryset.filter(verification_status=verification)

        # Counts for the dashboard banner
        complete_count = User.objects.filter(
            role=User.Role.WORKER, worker_profile__isnull=False,
        ).count()
        incomplete_count = User.objects.filter(
            role=User.Role.WORKER, worker_profile__isnull=True,
        ).count()
        pending_count = User.objects.filter(
            role=User.Role.WORKER, verification_status=User.VerificationStatus.PENDING,
        ).count()
        verified_count = User.objects.filter(
            role=User.Role.WORKER, verification_status=User.VerificationStatus.VERIFIED,
        ).count()
        rejected_count = User.objects.filter(
            role=User.Role.WORKER, verification_status=User.VerificationStatus.REJECTED,
        ).count()

        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 50))
        start = (page - 1) * page_size
        end = start + page_size
        total = queryset.count()
        users = queryset.order_by("-date_joined")[start:end]

        # How many cancellations on each worker's orders were caused by a
        # worker delay — the Workers table flags repeated incidents.
        delay_counts = dict(
            Order.objects.filter(
                worker__in=users,
                status=Order.CANCELLED,
                cancellation_reason=Order.WORKER_DELAY,
            ).values_list("worker_id").annotate(total=Count("id"))
        )

        # Use the same serializer as the mobile app for consistent data.
        profiles = []
        profile_user_ids = set()
        for u in users:
            profile = getattr(u, "worker_profile", None)
            if profile is not None:
                profiles.append(profile)
                profile_user_ids.add(u.id)

        serialized_profiles = WorkerProfileSerializer(
            profiles, many=True, context={"request": request},
        ).data if profiles else []

        # Build a map of user_id -> serialized profile data.
        profile_map = {}
        for item in serialized_profiles:
            uid = item["user"]["id"] if item.get("user") else None
            if uid is not None:
                profile_map[uid] = item

        results = []
        for u in users:
            if u.id in profile_map:
                entry = profile_map[u.id]
                entry["has_profile"] = True
            else:
                entry = {
                    "id": None,
                    "user": UserSerializer(u, context={"request": request}).data,
                    "has_profile": False,
                }
            entry["delay_cancellations"] = delay_counts.get(u.id, 0)
            results.append(entry)

        return Response({
            "count": total,
            "page": page,
            "page_size": page_size,
            "complete_count": complete_count,
            "incomplete_count": incomplete_count,
            "pending_count": pending_count,
            "verified_count": verified_count,
            "rejected_count": rejected_count,
            "results": results,
        })


class AdminWorkerDetailView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk, role=User.Role.WORKER)
            profile = getattr(user, "worker_profile", None)
        except User.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)

        if profile:
            return Response(
                WorkerProfileSerializer(profile, context={"request": request}).data,
            )
        return Response(UserSerializer(user, context={"request": request}).data)

    def patch(self, request, pk):
        """Admin-side worker update: avatar, id_card_image, profile fields,
        and verification toggles."""
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk, role=User.Role.WORKER)
        except User.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)

        # Avatar lives on User.
        avatar = request.FILES.get("avatar")
        if avatar is not None:
            user.avatar = avatar

        # ID card image lives on User.
        id_card = request.FILES.get("id_card_image")
        if id_card is not None:
            user.id_card_image = id_card

        # Text fields on User.
        user_text_fields = ["name_ar", "phone", "email", "address", "city", "governorate"]
        for key in user_text_fields:
            if key in request.data:
                setattr(user, key, request.data.get(key))

        user.save()
        _bust_dashboard_cache()

        # Also update WorkerProfile fields if profile exists.
        profile = getattr(user, "worker_profile", None)
        if profile:
            profile_text_fields = ["profession", "profession_ar", "bio", "bio_ar", "specialties", "specialties_ar"]
            for key in profile_text_fields:
                if key in request.data:
                    setattr(profile, key, request.data.get(key))

            profile_bool_fields = ["is_verified", "is_featured", "is_available"]
            dirty = []
            for key in profile_bool_fields:
                if key in request.data:
                    setattr(profile, key, _coerce_bool(request.data.get(key)))
                    dirty.append(key)
            if dirty:
                profile.save(update_fields=dirty)

        return Response(
            WorkerProfileSerializer(profile, context={"request": request}).data
            if profile else UserSerializer(user, context={"request": request}).data,
        )


class AdminWorkerVerifyView(APIView):
    """POST /api/admin/workers/<pk>/verify/ — Mark a worker as verified."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk, role=User.Role.WORKER)
        except User.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)

        user.verification_status = User.VerificationStatus.VERIFIED
        user.verified_at = timezone.now()
        user.verified_by = request.user
        user.rejection_reason = ""
        user.save(update_fields=[
            "verification_status", "verified_at", "verified_by", "rejection_reason",
        ])

        # Also set is_verified on WorkerProfile if it exists.
        profile = getattr(user, "worker_profile", None)
        if profile:
            profile.is_verified = True
            profile.save(update_fields=["is_verified"])

        _bust_dashboard_cache()
        return Response({
            "message": "Worker verified successfully.",
            "user": UserSerializer(user, context={"request": request}).data,
        })


class AdminWorkerRejectView(APIView):
    """POST /api/admin/workers/<pk>/reject/ — Reject a worker with a reason."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk, role=User.Role.WORKER)
        except User.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get("reason", "")
        user.verification_status = User.VerificationStatus.REJECTED
        user.rejection_reason = reason
        user.verified_at = None
        user.verified_by = None
        user.save(update_fields=[
            "verification_status", "rejection_reason", "verified_at", "verified_by",
        ])

        # Also set is_verified=False on WorkerProfile if it exists.
        profile = getattr(user, "worker_profile", None)
        if profile:
            profile.is_verified = False
            profile.save(update_fields=["is_verified"])

        _bust_dashboard_cache()
        return Response({
            "message": "Worker rejected.",
            "user": UserSerializer(user, context={"request": request}).data,
        })


def _paged_orders(request, queryset):
    """Slice an orders queryset by ?page & ?page_size (admin-profile shape)."""
    page = int(request.query_params.get("page", 1))
    page_size = min(int(request.query_params.get("page_size", 50)), 100)
    start = (page - 1) * page_size
    end = start + page_size
    total = queryset.count()
    queryset = queryset.order_by("-created_at")[start:end]
    from apps.orders.serializers import OrderSerializer
    return {
        "count": total,
        "page": page,
        "page_size": page_size,
        "results": OrderSerializer(
            queryset, many=True, context={"request": request},
        ).data,
    }


class AdminWorkerProfileView(APIView):
    """GET /api/admin/workers/<pk>/profile/ — the full worker picture in
    one call: profile data, order history with cancellation reasons, and
    ratings. Powers the /admin/workers/<id> profile page. Admin only."""

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk, role=User.Role.WORKER)
        except User.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)

        profile = getattr(user, "worker_profile", None)
        if profile is None:
            return Response(
                {"error": "This worker has no profile yet."},
                status=status.HTTP_404_NOT_FOUND,
            )

        orders = _paged_orders(
            request,
            Order.objects.filter(worker=user).select_related(
                "client", "worker", "service_category", "address",
            ),
        )

        ratings_qs = (
            Rating.objects.filter(worker=user)
            .select_related("client", "order", "order__service_category")
            .order_by("-created_at")
        )
        rating_count = ratings_qs.count()
        rating_avg = (
            ratings_qs.aggregate(avg=Avg("stars"))["avg"] or 0.0
        )

        from apps.ratings.serializers import AdminRatingSerializer
        page = int(request.query_params.get("page", 1))
        page_size = min(int(request.query_params.get("page_size", 50)), 100)
        start = (page - 1) * page_size

        return Response({
            "profile": WorkerProfileSerializer(
                profile, context={"request": request},
            ).data,
            "orders": orders,
            "summary": Order.behavior_summary(user, lookup="worker"),
            "ratings": {
                "count": rating_count,
                "average": round(rating_avg, 2),
                "page": page,
                "page_size": page_size,
                "results": AdminRatingSerializer(
                    ratings_qs[start : start + page_size],
                    many=True,
                ).data,
            },
        })


class AdminUserProfileView(APIView):
    """GET /api/admin/users/<pk>/profile/ — a client's profile with their
    orders and a server-computed behavior summary. The summary is one
    query shape shared with any future dashboard cards.

    Cancellations caused by the worker (WORKER_DELAY) are counted
    separately so they're never mistaken for client misbehavior. Admin
    only."""

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        orders = _paged_orders(
            request,
            Order.objects.filter(client=user).select_related(
                "client", "worker", "service_category", "address",
            ),
        )

        return Response({
            "user": UserSerializer(user, context={"request": request}).data,
            "behavior": Order.behavior_summary(user),
            "orders": orders,
        })


class AdminRatingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        from apps.ratings.serializers import AdminRatingSerializer
        ratings = (
            Rating.objects
            .select_related(
                "client", "worker", "worker__worker_profile",
                "order", "order__service_category",
            )
            .all()
            .order_by("-created_at")
        )
        return Response(
            AdminRatingSerializer(ratings, many=True, context={"request": request}).data,
        )


# ── CSV exports ────────────────────────────────────────────────────────
# Used by the admin dashboard's "Export CSV" buttons. Each view streams
# a UTF-8 CSV with a BOM so Excel opens Arabic text correctly. Volumes
# are small (a few thousand rows at this stage), so we materialize the
# CSV in one HttpResponse instead of streaming.

def _csv_response(filename):
    response = HttpResponse(content_type="text/csv; charset=utf-8")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    # BOM so Excel detects UTF-8 (otherwise Arabic shows as mojibake).
    response.write("﻿")
    return response


def _require_admin(request):
    if request.user.role != User.Role.ADMIN:
        return Response(
            {"error": "Admin access required."},
            status=status.HTTP_403_FORBIDDEN,
        )
    return None


class AdminOrdersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("orders.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "status", "urgency", "category", "category_ar",
            "client_username", "client_name", "client_phone",
            "worker_username", "worker_name", "worker_phone",
            "address", "latitude", "longitude",
            "commission", "created_at", "accepted_at",
            "completed_at", "cancelled_at",
        ])
        qs = (
            Order.objects
            .select_related("client", "worker", "service_category")
            .order_by("-created_at")
        )
        for o in qs.iterator(chunk_size=500):
            cat = o.service_category
            writer.writerow([
                o.id, o.status, o.urgency,
                cat.name if cat else "",
                cat.name_ar if cat else "",
                o.client.username if o.client_id else "",
                (o.client.name_ar or o.client.get_full_name() or "") if o.client_id else "",
                o.client.phone if o.client_id else "",
                o.worker.username if o.worker_id else "",
                (o.worker.name_ar or o.worker.get_full_name() or "") if o.worker_id else "",
                o.worker.phone if o.worker_id else "",
                o.address_text or "",
                o.latitude if o.latitude is not None else "",
                o.longitude if o.longitude is not None else "",
                o.commission,
                o.created_at.isoformat() if o.created_at else "",
                o.accepted_at.isoformat() if o.accepted_at else "",
                o.completed_at.isoformat() if o.completed_at else "",
                o.cancelled_at.isoformat() if o.cancelled_at else "",
            ])
        return response


class AdminWorkersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("workers.csv")
        writer = csv.writer(response)
        writer.writerow([
            "user_id", "username", "name", "phone", "email",
            "governorate", "city", "is_active",
            "profession", "profession_ar", "experience_years",
            "average_rating", "completed_jobs", "accept_rate",
            "is_available", "is_verified", "is_featured",
            "hourly_rate", "minimum_charge", "currency",
            "date_joined", "profile_created_at",
        ])
        qs = (
            User.objects.filter(role=User.Role.WORKER)
            .select_related("worker_profile")
            .order_by("-date_joined")
        )
        for u in qs.iterator(chunk_size=500):
            p = getattr(u, "worker_profile", None)
            writer.writerow([
                u.id, u.username,
                u.name_ar or u.get_full_name() or "",
                u.phone, u.email, u.governorate, u.city, u.is_active,
                p.profession if p else "",
                p.profession_ar if p else "",
                p.experience_years if p else "",
                p.average_rating if p else "",
                p.completed_jobs if p else "",
                p.accept_rate if p else "",
                p.is_available if p else "",
                p.is_verified if p else "",
                p.is_featured if p else "",
                p.hourly_rate if p and p.hourly_rate is not None else "",
                p.minimum_charge if p and p.minimum_charge is not None else "",
                p.currency if p else "",
                u.date_joined.isoformat() if u.date_joined else "",
                p.created_at.isoformat() if p and p.created_at else "",
            ])
        return response


class AdminUsersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("users.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "username", "name", "email", "phone",
            "role", "governorate", "city", "address",
            "is_active", "is_staff", "date_joined", "last_login",
        ])
        qs = User.objects.order_by("-date_joined")
        for u in qs.iterator(chunk_size=500):
            writer.writerow([
                u.id, u.username,
                u.name_ar or u.get_full_name() or "",
                u.email, u.phone, u.role,
                u.governorate, u.city, u.address,
                u.is_active, u.is_staff,
                u.date_joined.isoformat() if u.date_joined else "",
                u.last_login.isoformat() if u.last_login else "",
            ])
        return response


class AdminRatingsCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("ratings.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "stars", "review",
            "order_id", "order_category",
            "client_username", "client_name",
            "worker_username", "worker_name", "worker_profession",
            "created_at",
        ])
        from apps.ratings.models import Rating
        qs = (
            Rating.objects
            .select_related("client", "worker", "worker__worker_profile", "order", "order__service_category")
            .order_by("-created_at")
        )
        for r in qs.iterator(chunk_size=500):
            profile = getattr(r.worker, "worker_profile", None)
            writer.writerow([
                r.id, r.stars, r.review or "",
                r.order_id,
                r.order.service_category.name if r.order and r.order.service_category else "",
                r.client.username if r.client_id else "",
                r.client.name_ar if r.client_id else "",
                r.worker.username if r.worker_id else "",
                r.worker.name_ar if r.worker_id else "",
                profile.profession if profile else "",
                r.created_at.isoformat() if r.created_at else "",
            ])
        return response


class AdminCategoriesCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("categories.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "name", "name_ar", "icon", "image",
            "description", "description_ar",
            "worker_count", "active_worker_count",
        ])
        # Category list is tiny (tens of rows). One small count query per
        # row is fine and keeps the code readable — annotating across the
        # free-text profession field would need a Subquery wrapper that
        # earns nothing at this scale.
        for c in ServiceCategory.objects.order_by("name").iterator(chunk_size=500):
            worker_count = WorkerProfile.objects.filter(
                profession__iexact=c.name,
            ).count()
            active_worker_count = WorkerProfile.objects.filter(
                profession__iexact=c.name,
                is_available=True,
            ).count()
            image_url = ""
            if c.image:
                try:
                    image_url = request.build_absolute_uri(c.image.url)
                except Exception:
                    image_url = c.image.name
            writer.writerow([
                c.id, c.name, c.name_ar, c.icon, image_url,
                c.description, c.description_ar,
                worker_count, active_worker_count,
            ])
        return response


class AdminPaymentsCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("payments.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "order_id", "amount", "payment_status",
            "paymob_order_id", "paymob_transaction_id",
            "created_at", "updated_at",
        ])
        qs = (
            CommissionPayment.objects.select_related("order")
            .order_by("-created_at")
        )
        for p in qs.iterator(chunk_size=500):
            writer.writerow([
                p.id, p.order_id,
                p.amount,
                p.payment_status,
                p.paymob_order_id or "",
                p.paymob_transaction_id or "",
                p.created_at.isoformat() if p.created_at else "",
                p.updated_at.isoformat() if p.updated_at else "",
            ])
        return response
