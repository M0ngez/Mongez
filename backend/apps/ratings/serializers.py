from django.db.models import Avg
from rest_framework import serializers
from apps.orders.models import Order
from .models import Rating


class RatingSerializer(serializers.ModelSerializer):
    order = serializers.PrimaryKeyRelatedField(queryset=Order.objects.all())

    class Meta:
        model = Rating
        fields = ["id", "order", "stars", "review", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_stars(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("Stars must be between 1 and 5.")
        return value

    def validate_order(self, order):
        user = self.context["request"].user

        if order.client != user:
            raise serializers.ValidationError("You can only rate your own orders.")

        if order.status != Order.COMPLETED:
            raise serializers.ValidationError("The order must be completed before rating.")

        if hasattr(order, "rating"):
            raise serializers.ValidationError("You already rated this order.")

        return order

    def create(self, validated_data):
        order = validated_data["order"]
        client = self.context["request"].user
        worker = order.worker

        rating = Rating.objects.create(
            order=order,
            client=client,
            worker=worker,
            stars=validated_data["stars"],
            review=validated_data.get("review", ""),
        )

        # Recalculate and update the worker's average rating immediately
        new_avg = (
            Rating.objects
            .filter(worker=worker)
            .aggregate(avg=Avg("stars"))["avg"]
        ) or 0.0

        # A worker who deleted their account has no profile row (and a
        # profile-less worker is already a state the admin dashboard
        # handles), so the rating is recorded but there is nowhere to
        # persist the running average.
        profile = getattr(worker, "worker_profile", None)
        if profile is not None:
            profile.average_rating = round(new_avg, 2)
            profile.save()

        # Tell the worker — same fan-out the admin status-change uses.
        # In-app row + FCM push (best-effort if service account is configured).
        # Wrapped so a notify() exception never blocks the 201 reply.
        try:
            from apps.notifications.services import notify
            from apps.notifications.models import Notification

            stars = rating.stars
            client_label = client.name_ar or client.username
            data = {
                "kind": "rating",
                "order_id": order.id,
                "rating_id": rating.id,
                "stars": stars,
            }
            if rating.review:
                # The catalog template fully covers both the translated title
                # and the free-text review (inserted via the {review} placeholder
                # as-is). Store key + params so the worker's language change
                # re-translates the row lazily, like the default-rating branch.
                notify(
                    worker,
                    notif_type=Notification.PUSH,
                    data=data,
                    translation_key="rating_received",
                    translation_params={
                        "stars": stars,
                        "client": client_label,
                        "review": rating.review,
                    },
                )
            else:
                # Catalog template only → store key + params so the worker's
                # language change re-translates the notification lazily.
                notify(
                    worker,
                    notif_type=Notification.PUSH,
                    data=data,
                    translation_key="rating_received_default",
                    translation_params={
                        "stars": stars,
                        "client": client_label,
                        "order_id": order.id,
                    },
                )
        except Exception:  # pragma: no cover — best-effort
            pass

        return rating


class WorkerRatingSerializer(serializers.ModelSerializer):
    """Public projection: shows the client's display name but not their account."""

    client_name = serializers.CharField(source="client.display_name", read_only=True)

    class Meta:
        model = Rating
        fields = ["id", "client_name", "stars", "review", "created_at"]
        read_only_fields = fields


class AdminRatingSerializer(serializers.ModelSerializer):
    """Dashboard projection — every column the Ratings page renders.

    The base `RatingSerializer` only exposes ids; the admin needs the
    full names + the order's category + a quick handle on which worker
    was rated. Strings everywhere so the dashboard doesn't have to do
    secondary lookups.
    """

    client_username = serializers.CharField(source="client.username", read_only=True)
    client_name = serializers.CharField(source="client.name_ar", read_only=True)
    worker_username = serializers.CharField(source="worker.username", read_only=True)
    worker_name = serializers.CharField(source="worker.name_ar", read_only=True)
    worker_profession = serializers.SerializerMethodField()
    order_id = serializers.IntegerField(source="order.id", read_only=True)
    order_category = serializers.CharField(
        source="order.service_category.name", read_only=True,
    )

    class Meta:
        model = Rating
        fields = [
            "id",
            "stars",
            "review",
            "created_at",
            "order_id",
            "order_category",
            "client_username",
            "client_name",
            "worker_username",
            "worker_name",
            "worker_profession",
        ]
        read_only_fields = fields

    def get_worker_profession(self, obj):
        profile = getattr(obj.worker, "worker_profile", None)
        return profile.profession if profile else None
