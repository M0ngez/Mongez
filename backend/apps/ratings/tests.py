from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.orders.models import Order
from apps.users.models import User
from apps.workers.models import ServiceCategory, WorkerProfile
from .models import Rating


class RatingTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.category = ServiceCategory.objects.create(name="Plumbing")
        cls.client_user = User.objects.create_user(
            username="cliff", phone="+201000000020", password="Sup3r-Secret!",
            role=User.Role.CLIENT, profile_completed=True,
        )
        cls.worker_user = User.objects.create_user(
            username="will", phone="+201000000021", password="Sup3r-Secret!",
            role=User.Role.WORKER, profile_completed=True,
        )
        cls.profile = WorkerProfile.objects.create(
            user=cls.worker_user, profession="Plumbing", experience_years=3,
        )

    def _completed_order(self):
        return Order.objects.create(
            client=self.client_user,
            worker=self.worker_user,
            service_category=self.category,
            status=Order.COMPLETED,
        )

    def test_client_can_rate_completed_order(self):
        order = self._completed_order()
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 5, "review": "Great work",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.average_rating, 5.0)

    def test_cannot_rate_someone_elses_order(self):
        order = self._completed_order()
        other = User.objects.create_user(
            username="other", phone="+201000000022", password="Sup3r-Secret!",
            role=User.Role.CLIENT, profile_completed=True,
        )
        self.client.force_authenticate(user=other)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 1,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_rate_pending_order(self):
        order = Order.objects.create(
            client=self.client_user, worker=self.worker_user,
            service_category=self.category, status=Order.PENDING,
        )
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 4,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_worker_ratings_list_is_public(self):
        order = self._completed_order()
        Rating.objects.create(
            order=order, client=self.client_user, worker=self.worker_user, stars=4,
        )
        response = self.client.get(
            reverse("rating-worker-list", args=[self.worker_user.id]),
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["stars"], 4)

    def test_worker_ratings_list_by_profile_id(self):
        # The mobile worker home passes the WorkerProfile pk, which is a
        # different sequence from the User pk — must still find the ratings.
        self.assertNotEqual(self.profile.id, self.worker_user.id)
        order = self._completed_order()
        Rating.objects.create(
            order=order, client=self.client_user, worker=self.worker_user, stars=5,
        )
        response = self.client.get(
            reverse("rating-worker-list", args=[self.profile.id]),
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["stars"], 5)

    def test_rating_create_fires_worker_notification(self):
        from apps.notifications.models import Notification
        order = self._completed_order()
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 5, "review": "Excellent!",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        notes = Notification.objects.filter(user=self.worker_user)
        self.assertEqual(notes.count(), 1, "worker should get exactly one rating notification")
        payload = notes.first().data
        self.assertEqual(payload["kind"], "rating")
        self.assertEqual(payload["order_id"], order.id)
        self.assertEqual(payload["stars"], 5)

    def test_admin_ratings_list_returns_enriched_shape(self):
        from django.core.cache import cache
        cache.clear()
        order = self._completed_order()
        Rating.objects.create(
            order=order, client=self.client_user, worker=self.worker_user,
            stars=5, review="Great",
        )
        admin = User.objects.create_user(
            username="admin_rate_view", phone="+201000000099",
            password="AdminPass123", role=User.Role.ADMIN,
        )
        login = self.client.post(reverse("admin-login"), {
            "username": admin.username, "password": "AdminPass123",
        }, format="json")
        self.assertEqual(login.status_code, status.HTTP_200_OK, login.data)
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {login.data["tokens"]["access"]}',
        )

        response = self.client.get(reverse("admin-rating-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        row = response.data[0]
        for key in (
            "id", "stars", "review", "created_at",
            "order_id", "order_category",
            "client_username", "client_name",
            "worker_username", "worker_name", "worker_profession",
        ):
            self.assertIn(key, row, f"missing key: {key}")
        self.assertEqual(row["order_id"], order.id)
        self.assertEqual(row["order_category"], "Plumbing")

    def test_rating_review_notification_lazily_retranslates(self):
        from rest_framework.test import APIRequestFactory
        from apps.notifications.models import Notification
        from apps.notifications.serializers import NotificationSerializer

        order = self._completed_order()
        self.client.force_authenticate(user=self.client_user)
        response = self.client.post(reverse("rating-create"), {
            "order": order.id, "stars": 5, "review": "Great work!",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        notif = Notification.objects.get(user=self.worker_user)
        self.assertEqual(notif.translation_key, "rating_received")
        self.assertEqual(
            notif.translation_params,
            {"stars": 5, "client": self.client_user.username, "review": "Great work!"},
        )

        factory = APIRequestFactory()

        self.worker_user.language = "en"
        self.worker_user.save(update_fields=["language"])
        request_en = factory.get(reverse("notification-list"))
        request_en.user = self.worker_user
        data_en = NotificationSerializer(
            notif, context={"request": request_en},
        ).data
        self.assertEqual(data_en["title"], "5-star rating from cliff")
        self.assertEqual(data_en["message"], "Great work!")

        # Same row re-translates on language change.
        self.worker_user.language = "ar"
        self.worker_user.save(update_fields=["language"])
        request_ar = factory.get(reverse("notification-list"))
        request_ar.user = self.worker_user
        data_ar = NotificationSerializer(
            notif, context={"request": request_ar},
        ).data
        self.assertEqual(data_ar["title"], "تقييم 5 نجوم من cliff")
        # The client's own words ride through untouched either way.
        self.assertEqual(data_ar["message"], "Great work!")
