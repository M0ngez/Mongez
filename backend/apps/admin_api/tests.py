"""Smoke tests for the admin_api app.

Confirms the dashboard endpoints are wired (routable) and that the
role-based gate works: a non-admin token gets 403, an admin token gets
200 with the expected aggregate shape.
"""
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.users.models import User
from apps.orders.models import Order


class AdminApiAccessControlTests(TestCase):
    """Ensure admin_api endpoints are gated to role == ADMIN."""

    def setUp(self):
        # DRF's throttles and our 5 s admin-dashboard cache both live in
        # Django's default cache, which is LocMem and persists across
        # test methods. Clear so we don't trip the AuthRateThrottle when
        # the suite runs in a different order or alongside users.tests.
        cache.clear()
        self.admin = User.objects.create_user(
            username="admin_test",
            phone="01000000099",
            password="AdminPass123",
            role=User.Role.ADMIN,
        )
        self.client_user = User.objects.create_user(
            username="client_test",
            phone="01000000088",
            password="ClientPass123",
            role=User.Role.CLIENT,
        )
        self.api = APIClient()

    def _auth_as(self, user):
        """Login via the same /api/auth/login/ the dashboard uses."""
        password = "AdminPass123" if user.role == User.Role.ADMIN else "ClientPass123"
        response = self.api.post(
            "/api/auth/login/",
            {"username": user.username, "password": password},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.content)
        token = response.data["tokens"]["access"]
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_dashboard_requires_authentication(self):
        url = reverse("admin-dashboard")
        response = self.api.get(url)
        self.assertEqual(response.status_code, 401)

    def test_dashboard_rejects_non_admin(self):
        self._auth_as(self.client_user)
        response = self.api.get(reverse("admin-dashboard"))
        self.assertEqual(response.status_code, 403)
        self.assertIn("Admin access required", response.data["error"])

    def test_dashboard_allows_admin_and_returns_stats(self):
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-dashboard"))
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()
        self.assertIn("stats", body)
        self.assertIn("recent_orders", body)
        for key in (
            "total_users", "total_clients", "total_workers",
            "total_categories", "total_orders", "total_payments",
            "total_revenue", "orders_by_status",
        ):
            self.assertIn(key, body["stats"], f"missing stat key: {key}")
        # Two users created in setUp, both counted.
        self.assertEqual(body["stats"]["total_users"], 2)
        self.assertEqual(body["stats"]["total_clients"], 1)

    def test_user_list_paginates_and_filters_by_role(self):
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-user-list") + "?role=client")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["count"], 1)
        self.assertEqual(body["results"][0]["role"], "client")

    def test_worker_list_handles_users_without_profile(self):
        """Regression: AdminWorkerListView used to reference
        WorkerProfile.category / .description which don't exist on the
        current model, 500ing on the first worker without a profile."""
        # Add one worker without a WorkerProfile — this is the case that
        # used to trigger the 500.
        User.objects.create_user(
            username="bare_worker",
            phone="01000000077",
            password="WorkerPass123",
            role=User.Role.WORKER,
        )
        self._auth_as(self.admin)
        response = self.api.get(reverse("admin-worker-list"))
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()
        self.assertGreaterEqual(body["count"], 1)
        # Required fields the dashboard reads — would KeyError otherwise.
        row = body["results"][0]
        # A worker without a profile only has id=None, user, has_profile=False.
        self.assertFalse(row["has_profile"])
        self.assertIsNone(row["id"])
        self.assertIn("user", row)
        self.assertIn("has_profile", row)

    def test_worker_list_reports_worker_delay_cancellations(self):
        """Every worker list row must carry delay_cancellations so the
        admin Workers table can flag repeated no-show/delay incidents."""
        from datetime import timedelta
        from django.utils import timezone
        from apps.workers.models import ServiceCategory

        now = timezone.now()
        # Worker A: two cancellations caused by worker delay.
        worker_a = User.objects.create_user(
            username="delay_a", phone="01000000061",
            password="WorkerPass123", role=User.Role.WORKER,
        )
        # Worker B: no delay cancellations.
        worker_b = User.objects.create_user(
            username="delay_b", phone="01000000062",
            password="WorkerPass123", role=User.Role.WORKER,
        )
        cat = ServiceCategory.objects.create(name="Delay test")
        for i in range(2):
            Order.objects.create(
                client=self.client_user,
                worker=worker_a,
                service_category=cat,
                status=Order.CANCELLED,
                cancellation_reason=Order.WORKER_DELAY,
                created_at=now - timedelta(days=3 + i),
            )
        Order.objects.create(
            client=self.client_user,
            worker=worker_b,
            service_category=cat,
            status=Order.CANCELLED,
            cancellation_reason=Order.CANCELLATION_OTHER,
            created_at=now - timedelta(days=1),
        )

        self._auth_as(self.admin)
        r = self.api.get(reverse("admin-worker-list"))
        self.assertEqual(r.status_code, 200, r.content)
        by_username = {row["user"]["username"]: row for row in r.json()["results"]}
        self.assertIn(worker_a.username, by_username)
        self.assertIn(worker_b.username, by_username)
        self.assertEqual(by_username[worker_a.username]["delay_cancellations"], 2)
        self.assertEqual(by_username[worker_b.username]["delay_cancellations"], 0)

    def test_admin_orders_list_endpoint(self):
        """The admin Orders page must list orders through a dedicated
        /api/admin/orders/ endpoint. The public /api/orders/ endpoint
        carries IsProfileCompleted, which rejects real admins (their
        profile_completed is False) — that is why the dashboard page
        showed an empty table instead of the orders."""
        from apps.workers.models import ServiceCategory
        cat = ServiceCategory.objects.create(name="Orders test")
        Order.objects.create(
            client=self.client_user, service_category=cat, status=Order.PENDING,
        )
        resolved = Order.objects.create(
            client=self.client_user, service_category=cat, status=Order.COMPLETED,
        )
        # self.admin has profile_completed=False — exactly like production
        # admins. The endpoint must still list all orders.
        self._auth_as(self.admin)
        r = self.api.get(reverse("admin-order-list"))
        self.assertEqual(r.status_code, 200, r.content)
        body = r.json()
        self.assertEqual(body["count"], 2)
        self.assertEqual(body["results"][0]["service_category"]["name"], "Orders test")
        # Status filter.
        r = self.api.get(reverse("admin-order-list"), {"status": "COMPLETED"})
        self.assertEqual(r.json()["count"], 1)
        self.assertEqual(r.json()["results"][0]["id"], resolved.id)
        # Non-admins are rejected.
        r = self.api.post(
            "/api/auth/login/",
            {"username": self.client_user.username, "password": "ClientPass123"},
            format="json",
        )
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['tokens']['access']}")
        r = self.api.get(reverse("admin-order-list"))
        self.assertEqual(r.status_code, 403)

    def test_admin_orders_list_filters_by_cancellation_reason(self):
        """The Orders page needs to isolate worker-delay cancellations —
        that is the list a manager reviews when holding a worker to
        account. An unknown reason is a 400, like the status filter."""
        from apps.workers.models import ServiceCategory
        cat = ServiceCategory.objects.create(name="Delay filter test")
        late = Order.objects.create(
            client=self.client_user, service_category=cat,
            status=Order.CANCELLED, cancellation_reason=Order.WORKER_DELAY,
        )
        Order.objects.create(
            client=self.client_user, service_category=cat,
            status=Order.CANCELLED, cancellation_reason=Order.CANCELLATION_OTHER,
        )
        Order.objects.create(
            client=self.client_user, service_category=cat, status=Order.PENDING,
        )

        self._auth_as(self.admin)

        r = self.api.get(
            reverse("admin-order-list"),
            {"cancellation_reason": "WORKER_DELAY"},
        )
        self.assertEqual(r.status_code, 200, r.content)
        body = r.json()
        self.assertEqual(body["count"], 1)
        self.assertEqual(body["results"][0]["id"], late.id)
        self.assertEqual(body["results"][0]["cancellation_reason"], Order.WORKER_DELAY)

        r = self.api.get(
            reverse("admin-order-list"),
            {"cancellation_reason": "MAYBE_DELAY"},
        )
        self.assertEqual(r.status_code, 400)
        self.assertIn("cancellation_reason", r.json()["error"])


class AdminOrderStatusFanoutTests(TestCase):
    """The dashboard's admin status change is the load-bearing mutation
    the mobile sees from the dashboard. Confirm both clients (and the
    assigned worker) get a Notification row so the mobile's
    NotificationCubit picks it up via its 30 s poll, not just the slower
    order-list poll."""

    def setUp(self):
        from apps.workers.models import ServiceCategory
        from apps.orders.models import Order
        from apps.notifications.models import Notification

        cache.clear()
        self.Notification = Notification
        self.admin = User.objects.create_user(
            username="admin_fan",
            phone="01000000299",
            password="AdminPass123",
            role=User.Role.ADMIN,
        )
        self.client_user = User.objects.create_user(
            username="client_fan",
            phone="01000000288",
            password="ClientPass123",
            role=User.Role.CLIENT,
        )
        self.worker = User.objects.create_user(
            username="worker_fan",
            phone="01000000277",
            password="WorkerPass123",
            role=User.Role.WORKER,
        )
        self.category = ServiceCategory.objects.create(name="Test")
        self.order = Order.objects.create(
            client=self.client_user,
            worker=self.worker,
            service_category=self.category,
            description="test fan-out",
            status=Order.PENDING,
        )
        self.api = APIClient()

    def _login_admin(self):
        r = self.api.post(
            "/api/auth/login/",
            {"username": self.admin.username, "password": "AdminPass123"},
            format="json",
        )
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['tokens']['access']}")

    def test_admin_status_change_notifies_client_and_worker(self):
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})

        # PENDING → ACCEPTED
        r = self.api.patch(url, {"status": "ACCEPTED"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)

        client_notes = self.Notification.objects.filter(user=self.client_user)
        worker_notes = self.Notification.objects.filter(user=self.worker)
        self.assertEqual(client_notes.count(), 1, "client should get one notification")
        self.assertEqual(worker_notes.count(), 1, "assigned worker should get one notification")

        # Payload carries enough for the mobile UI to deep-link.
        payload = client_notes.first().data
        self.assertEqual(payload["order_id"], self.order.id)
        self.assertEqual(payload["status"], "ACCEPTED")
        self.assertEqual(payload["changed_by"], "admin")

    def test_admin_no_op_status_change_does_not_spam(self):
        """A PATCH that doesn't change the status shouldn't fan out."""
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})
        # Order is PENDING; PATCH PENDING again.
        r = self.api.patch(url, {"status": "PENDING"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(self.Notification.objects.count(), 0)

    def test_admin_cancel_records_a_reason(self):
        """An admin-forced cancel must never leave a blank reason — the UI
        renders null as "—", which is exactly the ambiguity this flow
        exists to remove. An admin override carries no evidence the worker
        was late, so it lands on OTHER rather than WORKER_DELAY."""
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})

        r = self.api.patch(url, {"status": "CANCELLED"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)

        self.order.refresh_from_db()
        self.assertIsNotNone(self.order.cancelled_at)
        self.assertEqual(self.order.cancellation_reason, Order.CANCELLATION_OTHER)

    def test_admin_cancel_does_not_overwrite_a_stated_reason(self):
        """Re-stamping the reason is guarded so a later status flip can't
        silently rewrite why an order was cancelled."""
        self._login_admin()
        url = reverse("admin-order-status", kwargs={"pk": self.order.id})
        Order.objects.filter(pk=self.order.pk).update(
            cancellation_reason=Order.WORKER_DELAY,
        )

        r = self.api.patch(url, {"status": "CANCELLED"}, format="json")
        self.assertEqual(r.status_code, 200, r.content)

        self.order.refresh_from_db()
        self.assertEqual(self.order.cancellation_reason, Order.WORKER_DELAY)


class AdminProfileEndpointTests(TestCase):
    """The /admin/workers/<pk>/profile/ and /admin/users/<pk>/profile/
    endpoints feed the new WorkerProfile / UserProfile admin pages.
    They must return real data only (profile + orders + ratings), gate
    non-admins, and compute the user behavior summary server-side."""

    def setUp(self):
        from datetime import timedelta
        from django.utils import timezone
        from apps.workers.models import ServiceCategory, WorkerProfile
        from apps.ratings.models import Rating

        cache.clear()
        now = timezone.now()
        self.admin = User.objects.create_user(
            username="admin_prof",
            phone="01000000399",
            password="AdminPass123",
            role=User.Role.ADMIN,
        )
        self.client_user = User.objects.create_user(
            username="client_prof",
            phone="01000000388",
            password="ClientPass123",
            role=User.Role.CLIENT,
            name_ar="Test Client",
        )
        self.worker = User.objects.create_user(
            username="worker_prof",
            phone="01000000377",
            password="WorkerPass123",
            role=User.Role.WORKER,
            name_ar="Test Worker",
        )
        self.category = ServiceCategory.objects.create(name="Plumbing")
        self.profile = WorkerProfile.objects.create(
            user=self.worker,
            profession="Plumbing",
            experience_years=5,
            hourly_rate="150.00",
            specialties="plumbing,leaks",
            is_verified=True,
        )
        # Worker orders: one completed, one cancelled (client, other reason),
        # one cancelled due to worker delay.
        self.completed = Order.objects.create(
            client=self.client_user, worker=self.worker,
            service_category=self.category, status=Order.COMPLETED,
            completed_at=now - timedelta(days=10),
            created_at=now - timedelta(days=12),
        )
        self.cancelled_other = Order.objects.create(
            client=self.client_user, worker=self.worker,
            service_category=self.category, status=Order.CANCELLED,
            cancellation_reason=Order.CANCELLATION_OTHER,
            cancelled_at=now - timedelta(days=3),
            created_at=now - timedelta(days=5),
        )
        self.delayed = Order.objects.create(
            client=self.client_user, worker=self.worker,
            service_category=self.category, status=Order.CANCELLED,
            cancellation_reason=Order.WORKER_DELAY,
            cancelled_at=now - timedelta(days=1),
            created_at=now - timedelta(days=2),
        )
        # One rating on the completed order.
        Rating.objects.create(
            order=self.completed, client=self.client_user,
            worker=self.worker, stars=5, review="Great job",
            created_at=now - timedelta(days=9),
        )
        self.api = APIClient()

    def _login_admin(self):
        r = self.api.post(
            "/api/auth/login/",
            {"username": self.admin.username, "password": "AdminPass123"},
            format="json",
        )
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['tokens']['access']}")

    def test_worker_profile_requires_admin(self):
        r = self.api.get(reverse("admin-worker-profile", kwargs={"pk": self.worker.id}))
        self.assertEqual(r.status_code, 401)

        r = self.api.post(
            "/api/auth/login/",
            {"username": self.client_user.username, "password": "ClientPass123"},
            format="json",
        )
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['tokens']['access']}")
        r = self.api.get(reverse("admin-worker-profile", kwargs={"pk": self.worker.id}))
        self.assertEqual(r.status_code, 403)

    def test_worker_profile_returns_profile_orders_and_ratings(self):
        self._login_admin()
        r = self.api.get(reverse("admin-worker-profile", kwargs={"pk": self.worker.id}))
        self.assertEqual(r.status_code, 200, r.content)
        body = r.json()

        self.assertEqual(body["profile"]["id"], self.profile.id)
        self.assertEqual(body["profile"]["profession"], "Plumbing")
        self.assertTrue(body["profile"]["is_verified"])
        # Real user data from the database.
        self.assertEqual(body["profile"]["user"]["username"], "worker_prof")

        self.assertEqual(body["orders"]["count"], 3)
        statuses = {o["status"] for o in body["orders"]["results"]}
        self.assertEqual(statuses, {Order.COMPLETED, Order.CANCELLED})
        # The delay cancellation carries its reason.
        delayed = next(o for o in body["orders"]["results"] if o["id"] == self.delayed.id)
        self.assertEqual(delayed["cancellation_reason"], Order.WORKER_DELAY)

        self.assertEqual(body["ratings"]["count"], 1)
        self.assertEqual(body["ratings"]["average"], 5.0)
        self.assertEqual(body["ratings"]["results"][0]["review"], "Great job")

        # Performance summary for the worker page (cancelled / delay counts).
        self.assertEqual(body["summary"]["total_orders"], 3)
        self.assertEqual(body["summary"]["cancelled_orders"], 2)
        self.assertEqual(body["summary"]["cancelled_due_to_worker_delay"], 1)
        # The split always adds back up to cancelled_orders, so the cards
        # can show "N by client · M worker delay" without a gap.
        self.assertEqual(body["summary"]["cancelled_by_client"], 1)
        self.assertEqual(
            body["summary"]["cancelled_by_client"]
            + body["summary"]["cancelled_due_to_worker_delay"],
            body["summary"]["cancelled_orders"],
        )

    def test_user_profile_returns_behavior_and_orders(self):
        self._login_admin()
        r = self.api.get(reverse("admin-user-profile", kwargs={"pk": self.client_user.id}))
        self.assertEqual(r.status_code, 200, r.content)
        body = r.json()

        self.assertEqual(body["user"]["username"], "client_prof")
        self.assertEqual(body["user"]["is_active"], True)
        self.assertEqual(body["orders"]["count"], 3)

        behavior = body["behavior"]
        self.assertEqual(behavior["total_orders"], 3)
        self.assertEqual(behavior["completed_orders"], 1)
        self.assertEqual(behavior["cancelled_orders"], 2)
        # One of those two cancellations was the worker's delay — not a
        # client behavior signal.
        self.assertEqual(behavior["cancelled_due_to_worker_delay"], 1)
        self.assertEqual(behavior["cancelled_by_client"], 1)
        self.assertEqual(behavior["recent_cancellations_30d"], 2)
        self.assertIsInstance(behavior["cancellation_rate"], float)
