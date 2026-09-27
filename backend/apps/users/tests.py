from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient, APITestCase

from apps.notifications.models import DeviceToken, Notification
from apps.orders.models import Order, OrderAttachment
from apps.ratings.models import Rating
from apps.workers.models import ServiceCategory, WorkerProfile

from .models import Address, User
from .views import get_tokens


class AuthFlowTests(APITestCase):
    def test_login_returns_tokens(self):
        User.objects.create_user(
            username="carol", phone="+201000000001", password="Sup3r-Secret!",
        )
        response = self.client.post(reverse("admin-login"), {
            "username": "carol", "password": "Sup3r-Secret!",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data["tokens"])

    def test_login_with_bad_password_fails(self):
        User.objects.create_user(
            username="dave", phone="+201000000002", password="Sup3r-Secret!",
        )
        response = self.client.post(reverse("admin-login"), {
            "username": "dave", "password": "wrong",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class CompleteProfileTests(APITestCase):
    """Test the actual auth flow: Google sign-in creates user →
    PATCH /api/auth/complete-profile/ sets profile fields."""

    def setUp(self):
        self.user = User.objects.create_user(
            username="new_user", phone="+201111111111",
            password="Sup3r-Secret!", profile_completed=False,
        )
        self.client.force_authenticate(user=self.user)

    def test_complete_profile_with_required_fields(self):
        response = self.client.patch(reverse("complete-profile"), {
            "phone": "+201112223344",
            "governorate": "cairo",
            "role": "worker",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.user.refresh_from_db()
        self.assertTrue(self.user.profile_completed)
        self.assertEqual(self.user.governorate, "cairo")

    def test_complete_profile_with_name_ar(self):
        response = self.client.patch(reverse("complete-profile"), {
            "phone": "+201112223355",
            "name_ar": "أحمد حسن",
            "governorate": "cairo",
            "city": "Nasr City",
            "role": "worker",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name_ar, "أحمد حسن")
        self.assertEqual(self.user.city, "Nasr City")

    def test_complete_profile_rejects_unknown_governorate(self):
        response = self.client.patch(reverse("complete-profile"), {
            "phone": "+201112223388",
            "governorate": "atlantis",
            "role": "client",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("governorate", response.data)


class GovernoratesEndpointTests(APITestCase):
    """Endpoint that the mobile + dashboard hydrate their governorate
    dropdowns from."""

    def test_governorates_endpoint_returns_27_entries_with_arabic_names(self):
        response = self.client.get(reverse("governorates"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.data
        self.assertEqual(len(body), 27)
        cairo = next((g for g in body if g["code"] == "cairo"), None)
        self.assertIsNotNone(cairo)
        self.assertEqual(cairo["name_en"], "Cairo")
        self.assertEqual(cairo["name_ar"], "القاهرة")
        # Each row has all three fields.
        for g in body:
            self.assertIn("code", g)
            self.assertIn("name_en", g)
            self.assertIn("name_ar", g)


class DefaultAddressSyncTests(APITestCase):
    """Changing the user's default address must propagate to the User's
    public location fields — the source of what customers see on the
    worker card / details."""

    def setUp(self):
        self.user = User.objects.create_user(
            username="tech1",
            phone="+201000000011",
            password="Sup3r-Secret!",
            profile_completed=True,
            governorate="cairo",
            city="Nasr City",
            address="12 Old Cairo St",
        )
        # Mirror the app's complete-profile flow: the first saved address
        # reflects the user fields and is the default.
        Address.objects.create(
            user=self.user,
            label="Nasr City",
            address="12 Old Cairo St",
            governorate="cairo",
            city="Nasr City",
            is_default=True,
        )
        self.client.force_authenticate(self.user)

    def test_patching_default_address_updates_user_location(self):
        Address.objects.create(
            user=self.user,
            label="Office",
            address="5 Maadi St",
            governorate="giza",
            city="Maadi",
            is_default=False,
        )
        target = Address.objects.get(label="Office")
        url = reverse("address-detail", args=[target.pk])
        response = self.client.patch(url, {"is_default": True}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.address, "5 Maadi St")
        self.assertEqual(self.user.city, "Maadi")
        self.assertEqual(self.user.governorate, "giza")

    def test_post_default_address_updates_user_location(self):
        url = reverse("address-list-create")
        response = self.client.post(url, {
            "label": "Work",
            "address": "3 Dokki St",
            "governorate": "giza",
            "city": "Dokki",
            "is_default": True,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.address, "3 Dokki St")
        self.assertEqual(self.user.city, "Dokki")
        self.assertEqual(self.user.governorate, "giza")

    def test_deleting_default_promotes_and_syncs(self):
        Address.objects.create(
            user=self.user,
            label="Office",
            address="5 Maadi St",
            governorate="giza",
            city="Maadi",
            is_default=False,
        )
        default = Address.objects.get(is_default=True)
        url = reverse("address-detail", args=[default.pk])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT, response.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.address, "5 Maadi St")
        self.assertEqual(self.user.city, "Maadi")
        self.assertEqual(self.user.governorate, "giza")

    def test_non_default_change_keeps_user_location(self):
        url = reverse("address-list-create")
        response = self.client.post(url, {
            "label": "Office",
            "address": "5 Maadi St",
            "governorate": "giza",
            "city": "Maadi",
            "is_default": False,
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.city, "Nasr City")
        self.assertEqual(self.user.governorate, "cairo")


class AccountDeletionTests(APITestCase):
    """POST /api/auth/deletion-token/ + /api/auth/delete-account/.

    The contract: strip PII in place, never delete the row (which would
    CASCADE through Order/CommissionPayment/Rating and take a
    technician's history with it), and refuse while work is in flight.
    """

    def setUp(self):
        # DRF's throttles live in the LocMem cache, which persists across
        # test methods — see apps/admin_api/tests.py.
        cache.clear()

        self.category = ServiceCategory.objects.create(name="Plumbing")
        self.worker = User.objects.create_user(
            username="honest_worker", phone="+201055550002",
            password="Sup3r-Secret!", role=User.Role.WORKER,
            profile_completed=True,
        )
        WorkerProfile.objects.create(
            user=self.worker, profession="Plumbing", experience_years=4,
        )

        self.user = User.objects.create_user(
            username="google_sub_123456", phone="+201055550001",
            password="Sup3r-Secret!", role=User.Role.CLIENT,
            profile_completed=True, email="deleteme@example.com",
            name_ar="Ahmed Ali", first_name="Ahmed", last_name="Ali",
            google_id="google-sub-123456",
            address="12 Test St", governorate="cairo", city="Nasr City",
        )
        Address.objects.create(
            user=self.user, label="Home", address="12 Test St",
            governorate="cairo", city="Nasr City", is_default=True,
        )
        Notification.objects.create(
            user=self.user, title="Hello", message="World",
        )
        DeviceToken.objects.create(
            user=self.user, token="fcm-token-1", platform="android",
        )
        self.client.force_authenticate(user=self.user)

    # ── minting ────────────────────────────────────────────────────────

    def _mint(self):
        return self.client.post(reverse("deletion-token"), {}, format="json")

    def test_mint_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self._mint()
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_mint_returns_url_carrying_the_token(self):
        response = self._mint()
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertIn("token", response.data)
        self.assertIn(f"token={response.data['token']}", response.data["url"])
        self.assertIn("/delete-account", response.data["url"])
        self.assertEqual(response.data["expires_in"], 15 * 60)

    def test_mint_refused_for_admin_accounts(self):
        admin = User.objects.create_user(
            username="root_admin", phone="+201055550003",
            password="Sup3r-Secret!", role=User.Role.ADMIN,
        )
        self.client.force_authenticate(user=admin)
        response = self._mint()
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_mint_refused_while_order_is_in_flight(self):
        Order.objects.create(client=self.user, service_category=self.category)
        response = self._mint()
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(response.data["code"], "active_orders")
        self.assertEqual(response.data["active_orders"], 1)

    # ── confirming ─────────────────────────────────────────────────────

    def _confirm(self, token):
        return self.client.post(
            reverse("delete-account"), {"token": token}, format="json",
        )

    def test_confirm_without_token_is_rejected(self):
        response = self.client.post(reverse("delete-account"), {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_confirm_with_tampered_token_is_rejected(self):
        token = self._mint().data["token"]
        body, sig = token.split(".", 1)
        response = self._confirm(f"{body}deadbeef{sig[7:]}")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)

    def test_confirm_anonymizes_every_pii_field(self):
        response = self._confirm(self._mint().data["token"])
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertTrue(response.data["deleted"])

        self.user.refresh_from_db()
        for field in ("phone", "email", "name_ar", "first_name", "last_name",
                      "address", "governorate", "city", "google_picture_url",
                      "deletion_nonce"):
            self.assertEqual(getattr(self.user, field), "", f"{field} survived")
        self.assertIsNone(self.user.google_id)
        # Django wraps a NULL FileField as `<ImageFieldFile: None>`; truth
        # is what _collect_files() keys off, so assert emptiness.
        self.assertFalse(self.user.avatar)
        self.assertFalse(self.user.id_card_image)
        self.assertTrue(self.user.username.startswith("deleted_"))
        self.assertNotEqual(self.user.username, "google_sub_123456")
        self.assertFalse(self.user.is_active)
        self.assertFalse(self.user.has_usable_password())

    def test_confirm_wipes_related_pii_but_keeps_the_user_row(self):
        self._confirm(self._mint().data["token"])

        self.assertEqual(Address.objects.filter(user=self.user).count(), 0)
        self.assertEqual(Notification.objects.filter(user=self.user).count(), 0)
        self.assertEqual(DeviceToken.objects.filter(user=self.user).count(), 0)
        # The row itself must outlive every FK pointing at it.
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())

    def test_confirm_removes_the_worker_profile(self):
        self.client.force_authenticate(user=self.worker)
        token = self._mint().data["token"]
        response = self._confirm(token)
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertEqual(
            WorkerProfile.objects.filter(user=self.worker).count(), 0,
        )

    def test_confirm_keeps_orders_and_ratings(self):
        order = Order.objects.create(
            client=self.user, worker=self.worker,
            service_category=self.category, status=Order.COMPLETED,
        )
        OrderAttachment.objects.create(order=order, kind="image", file="x.jpg")
        Rating.objects.create(order=order, client=self.user, worker=self.worker, stars=5)

        response = self._confirm(self._mint().data["token"])
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)

        self.assertTrue(Order.objects.filter(pk=order.pk).exists())
        self.assertTrue(Rating.objects.filter(pk=order.rating.pk).exists())
        # The technician's side of the record still resolves.
        order.refresh_from_db()
        self.assertEqual(order.client_id, self.user.pk)
        self.assertEqual(order.rating.stars, 5)

    def test_confirm_is_single_use(self):
        token = self._mint().data["token"]
        self.assertEqual(self._confirm(token).status_code, status.HTTP_200_OK)

        # The nonce was cleared, so the same URL must not work again.
        second = self._confirm(token)
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_confirm_blocked_if_orders_became_active_after_minting(self):
        token = self._mint().data["token"]
        Order.objects.create(client=self.user, service_category=self.category)
        response = self._confirm(token)
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)

    def test_stale_access_token_is_rejected_after_deletion(self):
        tokens = get_tokens(self.user)
        self._confirm(self._mint().data["token"])

        # Fresh client so no force_authenticate short-circuit — this has to
        # go through the real JWT authenticator.
        api = APIClient()
        response = api.get(
            reverse("my-profile"),
            HTTP_AUTHORIZATION=f"Bearer {tokens['access']}",
        )
        self.assertIn(
            response.status_code,
            (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN),
        )

    def test_google_signin_starts_a_fresh_account_after_deletion(self):
        """google_id is wiped, so get_or_create must mint a new user.

        Otherwise a deleted account would be resurrected on next sign-in.
        """
        self._confirm(self._mint().data["token"])
        user, created = User.objects.get_or_create(google_id="google-sub-123456")
        self.assertTrue(created)
        self.assertNotEqual(user.pk, self.user.pk)
