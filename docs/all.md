# Mongez — Complete Project Reference (`all.md`)

> One document that explains the entire system: where data lives, how the
> backend is shaped, how the mobile app and the web dashboard talk to it,
> how Docker glues it all together, and what each piece is for. Read
> top-to-bottom for the full picture; jump to a section if you only need
> one part.

---

## 1. What Mongez actually is

Mongez is a **home-services marketplace** for Egypt. It has two kinds of
end users and one platform operator:

| Role | What they do in the app |
|---|---|
| **Client** | Browses workers by category, places a service order, pays the worker in cash on-site, then rates the worker. |
| **Worker** (technician) | Lists themselves under a profession (Plumbing, Electrical, etc.), receives incoming orders, accepts/rejects them, and marks them complete. |
| **Admin** | Signs into the React dashboard (`frontend/`) to manage categories, users, workers, orders, payments, and ratings. There is no Django admin — Django is a pure REST API. |

The platform itself earns a **flat commission per accepted order**
(`COMMISSION_AMOUNT`, default 20 EGP). Workers and clients still exchange
the actual job money in cash; **Paymob is only used to collect the
commission** — that's a defining design choice and the entire `payments`
app exists for it.

---

## 2. Top-level layout

```
Mongez/
├── core/                     ← Django project (settings, urls, shared utils)
│   ├── settings.py
│   ├── urls.py
│   ├── permissions.py        ← IsClient / IsWorker / IsAdmin / IsOrderParticipant
│   ├── throttling.py         ← Auth / OrderCreate / Rating scoped throttles
│   ├── wsgi.py · asgi.py
│   └── apps/                 ← Domain apps (each is a Django app)
│       ├── users/            · Auth, profiles, JWT
│       ├── workers/          · Worker profiles + ServiceCategory
│       ├── orders/           · Order lifecycle + attachments
│       ├── notifications/    · In-app rows + FCM device tokens
│       ├── payments/         · Paymob commission + webhook
│       ├── ratings/          · Post-job star ratings
│       ├── favorites/        · Saved workers per client
│       └── admin_api/        · REST endpoints consumed by the React dashboard
├── frontend/                    ← React + Vite web dashboard (landing + admin)
│   ├── index.html · vite.config.js (dev proxy → 127.0.0.1:8000)
│   ├── firebase.json         · Firebase Hosting config (dist/)
│   ├── package.json          · React 19, react-router 7, react-bootstrap, i18next, axios, framer-motion
│   └── src/
│       ├── main.jsx · App.jsx
│       ├── i18n.js · locales/{ar,en}/translation.json
│       ├── services/api.js          · axios client + JWT auto-refresh
│       ├── context/AuthContext.jsx  · session state + token storage
│       ├── routes/                  · AppRoutes, ProtectedRoute, PublicRoute
│       ├── pages/                   · LandingPage, Login, NotFound
│       │   └── admin/               · Dashboard, Users, Workers, Categories,
│       │                             Orders, Payments, Ratings
│       └── components/
│           ├── landing/             · Hero, Services, HowItWorks, WhyChoose,
│           │                          AppPromotion, EmergencySection, Chat
│           ├── admin/               · Sidebar, Topbar, StatsCards, Table, AdminLayout
│           ├── auth/LoginPage.jsx
│           ├── common/              · Button, Loader, ChatWidget
│           └── layout/              · Header, Footer, Layout
├── mobile/                   ← Flutter app (separate sub-project)
│   └── lib/
│       ├── main.dart                · App entry, MultiBlocProvider, startup auth check
│       ├── core/
│       │   ├── constants/api_constants.dart    · baseUrl
│       │   ├── constants/endpoints.dart        · every path string lives here
│       │   ├── app_themes.dart, app_colors.dart
│       │   └── bloc/                           · global cubits (theme, locale)
│       ├── services/
│       │   ├── api_client.dart                 · Dio + JWT interceptor + refresh
│       │   ├── api_service.dart                · thin GET/POST/PATCH/DELETE wrapper
│       │   ├── helper.dart                     · PrefHelper (SharedPreferences token store)
│       │   ├── services_locator.dart           · GetIt registrations
│       │   └── navigation_service.dart         · post-login routing + cubit resets
│       ├── widgets/                            · reusable UI
│       ├── errors/failure.dart                 · ServerFailure + Dio mapper
│       ├── generated/                          · flutter_intl output
│       └── features/                           · one folder per feature
│           ├── auth/        (models, repos, bloc, screens, onboarding)
│           ├── home/        (categories cubit, sliver app bar, service cards)
│           ├── workers/     (data/domain/presentation — list, detail, create profile)
│           ├── details/     (worker detail view + per-worker ratings)
│           ├── favorites/   (client-only)
│           ├── orders/      (data/domain/presentation — 4 cubits below)
│           ├── checkout/    (place-order flow: address, attachments, payment)
│           ├── requests/    (customer + technician request lists)
│           ├── job_history/ (completed orders for workers)
│           ├── notifications/ (cubit polls every 30 s)
│           ├── profile/     (users/me/ GET/PATCH)
│           ├── account/, search/, settings/, categories/, main/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── requirements.txt
├── .env.example
├── manage.py
├── README.md · INSTALL.md · API_links.md · CONTRIBUTING.md
└── RUNNING.md · TESTING.md · WINDOWS.md · all.md · docs/ARCHITECTURE.{md,puml}
```

The working mobile app is everything under `mobile/`. The working
dashboard is everything under `frontend/` (built artifacts in `frontend/dist/`
are produced by `npm run build` and deployable as a static SPA).

---

## 3. Where the data comes from

**Single source of truth:** the SQLite database file the Django backend
owns.

| Where the file lives | When |
|---|---|
| `db.sqlite3` at the repo root | Local non-Docker `runserver` |
| `/app/data/db.sqlite3` inside the container, persisted to the **`sqlite_data` named volume** | Docker Compose (`SQLITE_PATH` env var, set in `docker-compose.yml`) |

Uploaded files (avatars, order attachments) go to `MEDIA_ROOT` → in
Docker that maps to `/app/media`, persisted to the **`media_data` named
volume**. Both volumes survive `docker compose -f deployment/docker/docker-compose.yml -p mongez down` and only get wiped
on `docker compose -f deployment/docker/docker-compose.yml -p mongez down -v`.

There is **no external service the mobile app fetches data from
directly** other than this Django API. Paymob and (optionally) FCM are
called server-side. The mobile app only talks to the backend.

Data flow at a glance:

```
   ┌──────────────────────┐   ┌────────────────────────────┐
   │   Flutter mobile     │   │  React dashboard (frontend/)  │
   │   (Dio + JWT)        │   │  (axios + JWT, react-router│
   │   clients & workers  │   │  admin/landing routes)     │
   └──────────────────────┘   └────────────────────────────┘
              │ HTTPS/HTTP JSON         │ HTTPS/HTTP JSON
              └─────────────┬───────────┘
                            ▼
                   ┌──────────────────────────────────────────┐
                   │  Django REST API   /api/...              │
                   │  Gunicorn (2 workers) inside Docker      │
                   │  apps/users · workers · orders · ratings │
                   │  payments · notifications · favorites    │
                   │  admin_api    ← powers the dashboard     │
                   └──────────────────────────────────────────┘
                              │            │
                  ┌───────────┘            └──────────────┐
                  ▼                                       ▼
        ┌──────────────────┐                ┌───────────────────────┐
        │   SQLite file    │                │  External services    │
        │  (sqlite_data    │                │  • Paymob (commission)│
        │   named volume)  │                │  • FCM   (push, opt.) │
        └──────────────────┘                └───────────────────────┘
```

---

## 4. Backend — Django REST API

### 4.1 Project shell (`core/`)

`backend/config/settings.py` is the centerpiece. Highlights:

- `AUTH_USER_MODEL = "users.User"` — custom user with phone, governorate,
  role.
- All env reads go through `env_bool` / `env_list` helpers so dev defaults
  stay safe when a variable is missing.
- DRF defaults: JWT auth, `IsAuthenticated`, page size 20, throttles
  configurable via `THROTTLE_*` env vars.
- `SIMPLE_JWT` lifetimes come from `JWT_ACCESS_MINUTES` and
  `JWT_REFRESH_DAYS`; refresh tokens rotate on use.
- `WhiteNoise` serves `/static/` so the DRF browsable API still looks
  right with `DEBUG=false`.
- Paymob settings (`PAYMOB_API_KEY`, `PAYMOB_INTEGRATION_ID`,
  `PAYMOB_HMAC_SECRET`, `COMMISSION_AMOUNT`) and `FCM_SERVER_KEY` are read
  from env; missing values disable the integration cleanly.

`backend/config/urls.py` mounts every domain app under `/api/`:

```
GET  /api/health/            → {"status":"ok"}     ← used by Docker HEALTHCHECK
     /api/auth/...           → apps.users.urls
     /api/users/me/          → apps.users.urls
     /api/categories/...     → apps.workers.urls
     /api/workers/...        → apps.workers.urls
     /api/orders/...         → apps.orders.urls
     /api/notifications/...  → apps.notifications.urls
     /api/payments/webhook/  → apps.payments.urls
     /api/ratings/...        → apps.ratings.urls
     /api/favorites/...      → apps.favorites.urls
     /api/admin/...          → apps.admin_api.urls   (REST, dashboard-only)
```

There is **no Django admin URL** — Django is a pure REST backend. All
management UI lives in the React dashboard (`frontend/`); the
`apps.admin_api` REST app provides the endpoints it consumes (§4.9).

`backend/config/permissions.py` defines `IsClient`, `IsWorker`, `IsAdmin`,
`IsClientOrWorker`, `IsOrderParticipant` — these replace inline `if
request.user.role != X` checks across views.

`backend/config/throttling.py` defines `AuthRateThrottle`, `OrderCreateThrottle`,
`RatingThrottle` — DRF scoped throttles whose rates are read from env.

### 4.2 `apps/users` — accounts and JWT

- **Model `User`** (extends `AbstractUser`): adds `phone` (unique, regex
  validated), `name_ar`, `address`, `governorate` (27 Egyptian
  governorates as TextChoices), `city`, `avatar` ImageField, `role`
  (`client` / `worker` / `admin`).
- **Endpoints**:
  - `POST /api/auth/register/` — anyone. Returns `{user, tokens:{access,refresh}}`.
  - `POST /api/auth/login/` — anyone. Same shape as register.
  - `POST /api/auth/logout/` — blacklists a refresh token (best-effort).
  - `PUT  /api/auth/password/` — change password (returns fresh tokens).
  - `POST /api/auth/token/refresh/` — DRF SimpleJWT default.
  - `GET/PATCH /api/users/me/` — read or update own profile (multipart for
    avatar).
- **Throttling**: register/login/password go through `AuthRateThrottle`
  (default 10/min).
- Cannot register as `admin` (validator in `RegisterSerializer`).

### 4.3 `apps/workers` — worker profiles + categories

Two models:

- **`ServiceCategory`** — name, name_ar, icon, description (en/ar). The
  mobile home screen reads this from `GET /api/categories/`.
- **`WorkerProfile`** — `OneToOne` to a `User` with `role=worker`. Stores
  profession, bio (en/ar), experience, hourly rate, minimum charge,
  specialties (CSV — kept portable for SQLite), languages, response time,
  completion/accept rate, working hours, geo + service radius, verified
  flag, featured flag, computed `average_rating` and `completed_jobs`.
- **Score formula** (used to rank the worker list):
  `(average_rating × 0.6) + (completed_jobs × 0.4)`
  Annotated at the DB level so paginated ordering stays consistent.

Endpoints:

| Method | Path | Who | Behavior |
|---|---|---|---|
| GET | `/api/categories/` | public | List all categories |
| POST | `/api/categories/create/` | admin | Create category |
| GET | `/api/workers/` | public | Paginated list (filters: `category`, `search`, `min_rating`, `available`, `ordering`, `page`, `page_size`) |
| GET | `/api/workers/<id>/` | public | Worker detail |
| GET | `/api/workers/<id>/stats/` | public | Aggregated order + rating analytics for the worker |
| POST | `/api/workers/create/` | worker | Create my worker profile |
| GET/PATCH | `/api/workers/me/` | worker | My own profile |

`WorkerProfileSerializer.service_category` does a case-insensitive lookup
of `ServiceCategory` whose `name` matches the worker's `profession`, with
per-request in-memory caching to avoid N+1 queries.

### 4.4 `apps/orders` — the order lifecycle

This is the heart of the app. State machine:

```
            POST /orders/                 POST /accept/             POST /complete/
client ────────────────► PENDING ──worker────► ACCEPTED ──worker────► COMPLETED
                          │  │                                                 │
                          │  └──worker /reject/──► REJECTED                    ▼
                          └─────client /cancel/──► CANCELLED            client rates
```

`Order` model:

- FK `client` (User), FK `worker` (User, nullable until assigned), FK
  `service_category`.
- `description`, `address_text`, `latitude`/`longitude`, `urgency`
  (LOW/NORMAL/HIGH), `scheduled_for`.
- `commission` (decimal, recorded on accept), `status`, timestamps for
  `created_at`/`accepted_at`/`completed_at`/`cancelled_at`.
- DB indexes on `(status, -created_at)`, `(client, -created_at)`,
  `(worker, -created_at)`.

`OrderAttachment` — image/audio/video uploaded with the order. Max **15
MB per file**, kind inferred from extension, stored under
`media/order_attachments/YYYY/MM/`.

Views (all under `IsAuthenticated`, with role checks inside):

| Path | Action |
|---|---|
| `GET /api/orders/?status=...` | List my orders (client sees own, worker sees assigned) |
| `POST /api/orders/` | **Client only**. Creates the order, attachments, calls Paymob to authorize commission, fans out push notifications to every matching available worker. Throttled by `OrderCreateThrottle` (default 20/hour). |
| `GET /api/orders/<id>/` | Detail, scoped so a client cannot read someone else's order |
| `POST /api/orders/<id>/attachments/` | Add more files after creation |
| `POST /api/orders/<id>/accept/` | Worker accepts → captures commission, sets commission amount, notifies client |
| `POST /api/orders/<id>/reject/` | Worker rejects → voids commission, notifies client |
| `POST /api/orders/<id>/cancel/` | Client cancels → voids commission, notifies worker. `cancellation_reason` is derived from timing: `PENDING` → `OTHER`, `ACCEPTED` (only reachable after 1 h) → `WORKER_DELAY`, which also notifies every admin |
| `POST /api/orders/<id>/complete/` | Worker marks finished → moves to `WAITING_CONFIRMATION`, pings client |
| `POST /api/orders/<id>/confirm-completion/` | Client confirms done → `COMPLETED`, bumps `completed_jobs`, prompts to rate |

Important rules (enforced in views):

- A worker can only complete an order **they were assigned to**.
- A client can only cancel **their own** order — always while `PENDING`,
  or once `ACCEPTED` and the 1-hour window has elapsed. Which of those two
  applied is what `cancellation_reason` records (`OTHER` vs
  `WORKER_DELAY`); it is computed server-side and the request body's
  `reason` never overrides it.
- Status transitions are guarded — you cannot accept an `ACCEPTED` order,
  cancel a `COMPLETED` one, etc.

### 4.5 `apps/payments` — Paymob commission

This app exists only to charge the platform fee. The flow is **auth →
capture / void**, not a normal charge.

- **`CommissionPayment`** (OneToOne to `Order`): `amount`,
  `paymob_order_id`, `paymob_transaction_id`, `payment_key`,
  `payment_status` ∈ {`AUTHORIZED`, `CAPTURED`, `VOIDED`, `FAILED`}.
- `apps/payments/paymob.py` is the **only file allowed to talk to
  Paymob's REST API**. It exposes:
  - `authorize_commission(order)` → 3-step flow (get auth token → create
    Paymob order → get payment_key). Called from order create.
  - `capture_commission(transaction_id, amount)` → called on worker
    accept.
  - `void_commission(transaction_id)` → called on worker reject or client
    cancel.
- `apps/payments/views.py` has only one view — `PaymobWebhookView`
  (`POST /api/payments/webhook/?hmac=...`). It:
  1. Verifies HMAC-SHA512 against `PAYMOB_HMAC_SECRET`. Rejects on
     mismatch.
  2. Looks up the `CommissionPayment` by `paymob_order_id`.
  3. Saves the `paymob_transaction_id` (needed later for capture/void).
  4. Updates `payment_status` based on `is_voided`/`is_capture`/`success`.
- Mobile **never** calls this endpoint — Paymob calls it from their side.

Failure handling: if Paymob is unavailable, the **order still gets
created** (commission row is marked `FAILED` and logged). Same for
capture/void — payment failures are logged but never block business
logic.

### 4.6 `apps/notifications` — in-app + push

- **`Notification`**: `user`, `title`, `message`, `type`
  (`push`/`in_app`/`email`), `is_read`, `data` (JSON for deep links).
- **`DeviceToken`**: an FCM/APNs token the mobile app registered, scoped
  to a user.
- `services.py` exposes a single `notify(user, title, message,
  notif_type, data)` that always writes the in-app row and, when type is
  `PUSH` and `FCM_SERVER_KEY` is set, fans the payload out to every
  active device token via FCM HTTP. **Push delivery is best-effort and
  never raises.**

Endpoints:

| Method | Path |
|---|---|
| GET | `/api/notifications/` (filter `?unread=1`) |
| GET | `/api/notifications/unread-count/` |
| POST | `/api/notifications/<id>/read/` |
| POST | `/api/notifications/read-all/` |
| POST/DELETE | `/api/notifications/devices/` — register/deregister a device token |

The mobile `NotificationCubit` **polls `GET /notifications/` every 30
seconds** while the main screen is mounted, which is the live-update
mechanism today (no websockets).

### 4.7 `apps/ratings` — post-job stars

- **`Rating`**: OneToOne to `Order`, FK client/worker, `stars` (1–5),
  `review` text. Indexed by `(worker, -created_at)`.
- `POST /api/ratings/` — client only, throttled by `RatingThrottle`
  (default 30/hour). Updates the worker's `average_rating` aggregate.
- `GET /api/ratings/worker/<id>/` — public, last 50 reviews.

### 4.8 `apps/favorites` — saved workers

- **`Favorite`**: FK client + FK worker, `unique_together` on the pair.
- `GET/POST /api/favorites/` (client only).
- `DELETE /api/favorites/<id>/` or `DELETE /api/favorites/worker/<worker_id>/`
  for a toggle-by-worker-id shortcut.

### 4.9 `apps/admin_api` — REST endpoints for the dashboard

Plain `APIView` classes, all gated by `IsAuthenticated` + a runtime
`request.user.role != User.Role.ADMIN` check (so a leaked client token
can't reach them). No models of its own — it reads/writes through the
other apps' models and serializers.

| Method | Path | Purpose |
|---|---|---|
| GET    | `/api/admin/dashboard/`              | Aggregate stats (counts by role, by status), revenue sum, last 10 orders |
| GET    | `/api/admin/users/?search=&role=&page=&page_size=` | Paginated user list (Q over username/phone/email) |
| POST   | `/api/admin/users/create/`           | Create user via `RegisterSerializer` |
| GET/PATCH/DELETE | `/api/admin/users/<pk>/`   | Read, partial-update (whitelisted fields), delete |
| PATCH/DELETE | `/api/admin/categories/<pk>/`   | Edit / remove a `ServiceCategory` |
| GET    | `/api/admin/payments/`               | Flat list of `CommissionPayment` rows |
| PATCH  | `/api/admin/orders/<pk>/status/`     | Set order status (validates against `Order.STATUS_CHOICES`; auto-stamps `accepted_at` / `completed_at` / `cancelled_at`; bumps `worker.completed_jobs` on completion) |
| GET    | `/api/admin/workers/?search=&page=&page_size=` | Paginated worker list with profile join + computed score |
| GET    | `/api/admin/workers/<pk>/`           | Single worker profile detail |
| GET    | `/api/admin/ratings/`                | All ratings (most recent first) |

These power every screen under `frontend/src/pages/admin/`. They're plain
JSON over the same `/api/` mount and the same JWT auth — the dashboard
re-uses the regular login endpoints.

The Django backend is **REST-only**: `django.contrib.admin` and
`django.contrib.messages` are no longer in `INSTALLED_APPS`, no
`admin.py` files exist, no `/admin/` URL is mounted. Operational
management runs through the React dashboard via `apps.admin_api`. If
you ever need direct DB access, use `python manage.py shell` (or DB
introspection tools), not a browser admin.

---

## 5. Mobile — Flutter app

### 5.1 Architecture

The app follows **Clean Architecture-ish layering per feature**:

```
features/<name>/
├── domain/        ← repository interface
├── data/
│   ├── models/    ← fromJson/toJson
│   └── repositories/  ← implements domain, calls ApiService
└── presentation/
    ├── cubit/     ← BLoC/Cubit state machine
    └── screens/   ← Material widgets (some features keep screens at feature root)
```

State management is **`flutter_bloc` + cubits**. All cubits are registered
once at app startup in `main.dart` via a `MultiBlocProvider` so any
screen can `context.read<...Cubit>()` without re-instantiation.

Repositories are wired via **`get_it` (`services/services_locator.dart`)**
and use `dartz`'s `Either<Failure, T>` for error handling — every repo
method returns `right(data)` on success or `left(ServerFailure)` on
failure (DioException converted in `errors/failure.dart`).

### 5.2 Networking

`services/api_client.dart` (`DioClient`):

- Base URL: `ApiConstants.baseUrl = 'http://127.0.0.1:8000/api/'` (change
  for emulator/device — see §7).
- Adds `Authorization: Bearer <access>` to every request from
  `PrefHelper.getToken()`.
- **Auto-refresh on 401**: when a request comes back 401, the
  interceptor calls `auth/token/refresh/` with the refresh token, saves
  the new access token, and replays the original request. If refresh
  fails, it clears tokens and invokes the optional `onUnauthorized`
  callback (used to bounce back to the auth flow).

`services/api_service.dart` is a thin wrapper exposing `get / post / put
/ patch / delete / postMultipart / patchMultipart` on top of Dio.

`services/helper.dart` (`PrefHelper`) persists `auth_token` and
`refresh_token` into `SharedPreferences`. There is no encrypted secure
storage today.

`core/constants/endpoints.dart` is the single place every API path is
written. Repositories never hand-type a URL.

### 5.3 App startup (`main.dart`)

1. `setup()` registers GetIt singletons.
2. `AppPrefs.init()` warms up shared prefs.
3. `MultiBlocProvider` builds all cubits (theme, locale, login,
   register, categories, workers, profile, customer/technician orders,
   job history, checkout, favorites, create worker profile,
   notifications).
4. `AppStartupScreen` checks: token in prefs? → call
   `getProfile()` → on success go to `MainScreen`, on failure try
   `/auth/token/refresh/`, on failure again drop to the
   `GetStartedScreen`. This is what makes the app "remember you're
   logged in."

### 5.4 Main navigation (`MainScreen`)

A `BottomNavigationBar` with 4 tabs. The labels differ by role:

| Index | Client | Worker |
|---|---|---|
| 0 | Home (categories + workers) | Home (own profile + orders to action) |
| 1 | Favorites | Job History |
| 2 | Requests (my placed orders) | Requests (incoming orders) |
| 3 | Account | Account |

On entering `MainScreen` the `NotificationCubit.startPolling()` fires
and `_fetch()` runs every 30 s.

### 5.5 How the mobile maps to the API

| Mobile feature | Repository | Endpoints used |
|---|---|---|
| `auth` | `AuthRepoImplementation` | `auth/login/`, `auth/register/`, `auth/token/refresh/` |
| `profile` | `ProfileRepositoryImpl` | `users/me/` (GET + PATCH, multipart for avatar) |
| `home` (categories) | `HomeRepoImplementation` | `categories/` |
| `workers` | `WorkerRepositoryImpl` | `workers/`, `workers/<id>/`, `workers/create/` |
| `details` (worker detail + reviews) | (inline) | `workers/<id>/`, `ratings/worker/<id>/`, `workers/<id>/stats/` |
| `favorites` | `FavoritesRepositoryImpl` | `favorites/`, `favorites/<id>/` |
| `orders` | `OrderRepositoryImpl` | `orders/` (GET + POST multipart with photos/audio), `orders/<id>/`, `accept`, `reject`, `cancel`, `complete` |
| `checkout` | reuses `OrderRepository` | `orders/` POST (with attachments and worker selection) |
| `notifications` | `NotificationRepositoryImpl` | `notifications/`, `notifications/<id>/read/`, `notifications/read-all/` |

### 5.6 Order create — end-to-end

The single most involved flow. Tracing a client tapping **"Book Now"**:

1. **Mobile (`CheckoutCubit`)** collects: category id, optional worker
   id, description, address, urgency, optional GPS lat/lng, optional
   photos[] from `image_picker`, optional audio recorded with `record`.
2. Calls `OrderRepositoryImpl.createOrder(...)`. If files are present it
   builds a `FormData` (`multipart/form-data`) with field names matching
   what the backend expects: `service_category`, `worker_id`,
   `description`, `address_text`, `urgency`, `latitude`, `longitude`,
   `duration_seconds`, files under `photos` and `audio`. Without files it
   sends plain JSON.
3. **Backend (`OrderListCreateView.post`)**:
   - Verifies `request.user.role == CLIENT` (throws 403 otherwise).
   - `OrderCreateSerializer` validates: category exists; if `worker_id`
     given, worker has a profile, is available, and their profession
     matches the category name.
   - Inside one `@transaction.atomic`:
     - Creates the `Order` (status `PENDING`).
     - Walks `request.FILES` and creates `OrderAttachment` rows, skipping
       anything over 15 MB.
     - Calls `paymob.authorize_commission(order)` → 3 API hits to
       Paymob, creates `CommissionPayment` row with status `AUTHORIZED`
       and stores the `payment_key`. On failure a `FAILED` row is logged
       and `payment_key` returned as `None` — the order still exists.
   - Notifies every matching available worker via `notify(...,
     notif_type=PUSH)` so they get a Notification row + (if FCM
     configured) a push.
   - Returns `OrderSerializer(order).data` plus the `payment_key` for
     the mobile to optionally render Paymob's iframe.
4. **Worker side**: their `NotificationCubit` polls every 30 s and shows
   the new entry. They open `TechnicianRequestsScreen`, tap **Accept** →
   `POST /orders/<id>/accept/`. Backend updates status, calls
   `paymob.capture_commission(...)`, sets `commission` on the order, and
   notifies the client.
5. When the job is done in real life, the worker taps **Complete** →
   `POST /orders/<id>/complete/`. Backend bumps the worker's
   `completed_jobs` counter and notifies the client to rate.
6. The client opens the order, taps **Rate** → `POST /ratings/`.

---

## 6. Dashboard — React + Vite web app (`frontend/`)

The dashboard is two products sharing a single SPA:

1. **Public landing page** — marketing site (Hero, Services, How it works,
   Why-choose, AppPromotion, Emergency, Chat widget). Bilingual via
   `i18next` with `ar` and `en` JSON dictionaries in `src/locales/`.
2. **Admin console** — gated routes under `/admin/*` that hit
   `apps.admin_api` endpoints.

### 6.1 Stack

| Concern | Choice |
|---|---|
| Build | Vite 7 (`npm run dev` / `npm run build`) |
| UI | React 19, react-bootstrap, framer-motion, bootstrap-icons |
| Routing | react-router-dom 7 (`AppRoutes`, `ProtectedRoute`, `PublicRoute`) |
| Data | axios via `src/services/api.js` with JWT auto-refresh |
| Session | `src/context/AuthContext.jsx` → access/refresh in `localStorage` |
| i18n | `react-i18next` + `src/i18n.js` |
| Hosting | Firebase Hosting (`firebase.json` rewrites everything to `index.html`) |

### 6.2 Layout

```
frontend/src/
├── main.jsx · App.jsx · i18n.js
├── services/api.js        ← axios instance, baseURL='/api'
│                            request interceptor injects Bearer token,
│                            response interceptor refreshes on 401 then retries
├── context/AuthContext    ← {user, login, logout, isAuthenticated, isAdmin}
├── routes/
│   ├── AppRoutes.jsx      ← <Routes> tree
│   ├── ProtectedRoute.jsx ← redirects to /login if no token
│   └── PublicRoute.jsx    ← redirects authed admins to /admin
├── pages/
│   ├── LandingPage.jsx + Landing.css    ← marketing site
│   ├── Login.jsx · NotFound.jsx
│   ├── AdminDashboard.jsx               ← stats home
│   └── admin/
│       ├── Dashboard.jsx · Users.jsx · Workers.jsx
│       ├── Categories.jsx · Orders.jsx · Payments.jsx · Ratings.jsx
├── components/
│   ├── landing/   (Hero, Services, HowItWorks, WhyChoose, AppPromotion,
│   │              EmergencySection, Chat)
│   ├── admin/     (AdminLayout, Sidebar, Topbar, StatsCards, Table)
│   ├── auth/LoginPage.jsx
│   ├── common/    (Button, Loader, ChatWidget)
│   └── layout/    (Header, Footer, Layout)
├── styles/        (admin.css, global.css)
└── locales/{ar,en}/translation.json
```

### 6.3 Dev workflow

```bash
cd front
cp .env.example .env       # VITE_ADMIN_URL, VITE_OPENROUTER_KEY
npm install
npm run dev                # http://localhost:5173 with HMR
```

The Vite dev server proxies `/api` and `/media` to the Django backend at
`http://127.0.0.1:8000`, so the browser only talks to `localhost:5173`
during development — no CORS dance.

### 6.4 Production build & deploy

```bash
npm run build              # writes frontend/dist/
firebase deploy --only hosting     # (firebase.json points at dist/)
```

`dist/index.html` references hashed JS/CSS bundles. The `firebase.json`
rewrites every unknown path to `index.html` so the SPA router takes
over.

### 6.5 How the dashboard talks to the backend

- Login → `POST /api/auth/login/` (same endpoint the mobile app uses)
- After login the SPA stores the JWT pair and pings `GET /api/users/me/`
  to verify the role is `admin`. If not, it logs out and shows an
  error.
- All admin screens consume `apps.admin_api` endpoints listed in §4.9.
- Media (e.g. user avatars in tables) is served from the Django
  `/media/` mount.

### 6.6 No Django admin

There is no `/admin/` page. The legacy `django.contrib.admin` was
removed in favor of a pure REST surface — the React dashboard is the
sole management UI, talking to `apps.admin_api` over JSON. If a
collaborator looks for the old `/admin/` URL they will get a 404; that
is intentional.

---

## 7. Docker — what the box actually does

### 7.1 `Dockerfile`

- Base: `python:3.12-slim`.
- Installs `libjpeg62-turbo zlib1g` (Pillow), `curl` (for the
  HEALTHCHECK), `gosu` (drop privileges in the entrypoint).
- Creates an unprivileged `app` user (uid 1000).
- `pip install -r requirements.txt` in a separate layer from source
  copy, so editing code doesn't rebuild Python deps.
- Runs `collectstatic` at build time so the admin/DRF browsable API have
  their CSS available without runtime work.
- Sets `chmod +x entrypoint.sh`, creates `/app/data` and `/app/media`,
  chowns to `app`.
- `EXPOSE 8000`.
- `HEALTHCHECK` hits `GET /api/health/` every 30 s, with a 20 s start
  grace.
- `ENTRYPOINT ["/app/entrypoint.sh"]`.

### 7.2 `entrypoint.sh`

Runs briefly as root, then drops to `app` via `gosu`:

1. `mkdir -p /app/data /app/media` and `chown` them so the named volumes
   become writable.
2. `gosu app python manage.py migrate --noinput` — applies any pending
   migrations on every boot.
3. `exec gosu app gunicorn core.wsgi:application --bind 0.0.0.0:8000
   --workers 2 --timeout 120 --access-logfile - --error-logfile -`.

`exec` matters: Gunicorn replaces the shell so it becomes PID 1's
direct child and receives `SIGTERM` cleanly on `docker stop`.

### 7.3 `docker-compose.yml`

```yaml
services:
  web:
    build: .
    image: mongez-backend:latest
    container_name: mongez-backend
    ports: ["8000:8000"]
    env_file: [.env]
    environment:
      SQLITE_PATH: /app/data/db.sqlite3
    volumes:
      - sqlite_data:/app/data         ← database persistence
      - media_data:/app/media         ← uploaded files persistence
    healthcheck: hits /api/health/ every 30 s
    restart: unless-stopped
volumes:
  sqlite_data:
  media_data:
```

Two named volumes intentionally separate from the source tree. `docker
compose down` keeps them. `docker compose -f deployment/docker/docker-compose.yml -p mongez down -v` wipes them.

### 7.4 `.dockerignore`

Trims the build context: drops `venv/`, `__pycache__/`, `.git/`,
`.env`, the existing `db.sqlite3`, `media/`, `staticfiles/`, **the
entire `mobile/` directory**, docs, and IDE/OS files. The image only
contains what's needed to serve the API.

### 7.5 `.env`

`.env.example` lists every supported variable. Required for production:
`DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS`.
Paymob and FCM keys can stay blank in dev — both integrations are no-ops
when their secrets are missing.

### 7.6 Operational commands

```bash
docker compose -f deployment/docker/docker-compose.yml -p mongez up -d --build        # build + start in background
docker compose -f deployment/docker/docker-compose.yml -p mongez ps                   # check status / healthcheck
docker compose -f deployment/docker/docker-compose.yml -p mongez logs -f web          # follow logs
docker compose -f deployment/docker/docker-compose.yml -p mongez exec web python manage.py createsuperuser
docker compose -f deployment/docker/docker-compose.yml -p mongez exec web python manage.py shell
docker compose -f deployment/docker/docker-compose.yml -p mongez exec web python manage.py test apps
docker compose -f deployment/docker/docker-compose.yml -p mongez down                 # stop, keep volumes
docker compose -f deployment/docker/docker-compose.yml -p mongez down -v              # stop, wipe DB + media
```

Health verification:

```bash
curl http://localhost:8000/api/health/        # {"status":"ok"}
curl http://localhost:8000/api/workers/       # paginated empty list
```

---

## 8. Where backend, mobile, and dashboard actually connect

There's no shared code — the contract is the JSON over HTTP:

1. **Mobile sends** `Authorization: Bearer <access>` on every request
   except register/login/refresh.
2. **Mobile knows the base URL** from
   `mobile/lib/core/constants/api_constants.dart` →
   `ApiConstants.baseUrl`. **Change this per target**:

   | Target | Value |
   |---|---|
   | Linux desktop, iOS sim, web | `http://127.0.0.1:8000/api/` |
   | Android emulator | `http://10.0.2.2:8000/api/` |
   | Physical device on Wi-Fi | `http://<your-machine-LAN-IP>:8000/api/` |

3. **For a physical device**: also bind the backend to all interfaces
   (`docker-compose.yml` → `ports: ["0.0.0.0:8000:8000"]`) and add your
   machine's IP (and the emulator host `10.0.2.2`) to
   `DJANGO_ALLOWED_HOSTS`.
4. **Token storage**: mobile keeps access + refresh in
   `SharedPreferences` (plain). On 401 the Dio interceptor swaps to
   refresh, retries, and on failure logs the user out.
5. **Push & live updates**: notifications are **polled** (30 s interval
   while `MainScreen` is mounted). FCM is server-side only and silent
   in dev unless `FCM_SERVER_KEY` is set.
6. **File uploads** use `multipart/form-data`: avatars during register,
   order photos (`photos`) and audio (`audio`).
7. **Dashboard sends** the same `Authorization: Bearer <access>` header.
   In dev, requests go through Vite's proxy
   (`frontend/vite.config.js` → `/api → http://127.0.0.1:8000`) so the
   browser only ever sees `localhost:5173`. In production, serve the
   built `frontend/dist/` from the same origin as the API (or set
   `CORS_ALLOWED_ORIGINS` and host them separately).
8. **Admin gating** is double-checked: `apps.admin_api` views require
   `IsAuthenticated` **and** `request.user.role == User.Role.ADMIN`.
   A non-admin token gets `403 Admin access required.` so dashboard
   `ProtectedRoute` + `AuthContext.isAdmin` only matters for UX, not
   security.

### 8.1 Live data sync — there's no WebSocket layer

Both surfaces poll the same REST API. The dashboard uses a tiny
`usePolling` hook (`frontend/src/hooks/usePolling.js`); the mobile uses
`Timer.periodic` inside the relevant cubits. Both gate fetches on
visibility (browser tab) / cubit-screen lifecycle (mobile) so an idle
client doesn't keep hammering the API.

**Dashboard → backend (per-page intervals):**

| Page | Interval | Why |
|---|---|---|
| Dashboard | 10 s | primary "is the system breathing" surface |
| Orders | 10 s | most dynamic — mobile-placed orders land fast |
| Payments | 15 s | Paymob webhooks land out-of-band |
| Workers / Users / Ratings | 30 s | profile and review data is slow |
| Categories | 60 s | basically static; parallel-admin safety net |

* Each page shows an **"Updated X s ago"** badge with a manual refresh
  button; the badge ticks each second via `useTimeAgo`.
* `/admin/orders` does an **optimistic** local update on status PATCH
  so the admin doesn't wait a poll cycle to see their click land.
* `apps.admin_api.AdminDashboardView` caches its `Sum/Count` aggregate
  in Django's cache for **5 s** so N admins polling at 10 s cost at
  most one DB query every other tick. Recent-orders stays uncached
  (per-request serializer URL context).

**Mobile → backend (cubits):**

| Cubit | When it polls | Endpoint | Interval |
|---|---|---|---|
| `NotificationCubit` | from login until app close | `/api/notifications/` | 30 s |
| `CustomerOrdersCubit` | while "My requests" is mounted | `/api/orders/` | 30 s |
| `TechnicianOrdersCubit` | while "Requests" is mounted | `/api/orders/` | 30 s |

A failed poll keeps the cached state on screen instead of flashing an
error.

**Backend → mobile (when the admin acts):**

`apps.admin_api.AdminOrderStatusView.patch` fans out on any status
change (no-op PATCHes don't fan out):

* `notify(order.client, …)` → in-app row + FCM push (best-effort)
* `notify(order.worker, …)` → in-app row + FCM push, if assigned

So a dashboard click lands in the mobile through **two independent
channels** (orders cubit and notifications cubit) within ~30 s — plus
instant FCM if `FCM_SERVER_KEY` is set.

---

## 9. Branch layout (matters for collaborators)

- `main` — production-ready snapshot of backend + mobile + dashboard +
  fixes (current branch).
- `backend` — historical: backend-only.
- `mobile` — historical: mobile-only.
- `test` — integration testing branch that merges backend + mobile.

The memory note from previous sessions says **don't push directly to
`main`** — open PRs and merge through `test` first.

---

## 10. Quick reference — every endpoint

```
Auth
  POST  /api/auth/register/                         public
  POST  /api/auth/login/                            public
  POST  /api/auth/logout/                           auth
  PUT   /api/auth/password/                         auth
  POST  /api/auth/token/refresh/                    public

Profile
  GET   /api/users/me/                              auth
  PATCH /api/users/me/                              auth (multipart for avatar)

Reference data
  GET   /api/governorates/                          public (27 Egyptian governorates: code/name_en/name_ar)

Categories
  GET   /api/categories/                            public
  POST  /api/categories/create/                     admin

Workers
  GET   /api/workers/                               public  (category, search, min_rating, available, ordering, page, page_size)
  GET   /api/workers/<id>/                          public
  GET   /api/workers/<id>/stats/                    public
  POST  /api/workers/create/                        worker  (accepts category_id+description OR profession+bio)
  GET   /api/workers/me/                            worker
  PATCH /api/workers/me/                            worker
  GET   /api/workers/me/stats/                      worker  (lifetime + this-month + recent ratings)

Orders
  GET   /api/orders/                                auth (status filter)
  POST  /api/orders/                                client (multipart with photos/audio)
  GET   /api/orders/<id>/                           auth (scoped)
  POST  /api/orders/<id>/attachments/               client
  POST  /api/orders/<id>/accept/                    worker
  POST  /api/orders/<id>/reject/                    worker
  POST  /api/orders/<id>/cancel/                    client
  POST  /api/orders/<id>/complete/                  worker

Notifications
  GET   /api/notifications/                         auth (?unread=1)
  GET   /api/notifications/unread-count/            auth
  POST  /api/notifications/<id>/read/               auth
  POST  /api/notifications/read-all/                auth
  POST  /api/notifications/devices/                 auth (register FCM token)
  DELETE/api/notifications/devices/                 auth

Payments
  POST  /api/payments/webhook/?hmac=...             Paymob only (HMAC-verified)

Ratings
  POST  /api/ratings/                               client (throttled)
  GET   /api/ratings/worker/<id>/                   public

Favorites
  GET   /api/favorites/                             client
  POST  /api/favorites/                             client
  DELETE/api/favorites/<id>/                        client
  DELETE/api/favorites/worker/<worker_id>/          client

Admin (used by the React dashboard — admin role only)
  GET    /api/admin/dashboard/                                  admin   (5 s cache on aggregate)
  GET    /api/admin/users/?search=&role=&page=&page_size=       admin
  POST   /api/admin/users/create/                               admin
  GET    /api/admin/users/<id>/                                 admin
  PATCH  /api/admin/users/<id>/                                 admin
  DELETE /api/admin/users/<id>/                                 admin
  PATCH  /api/admin/categories/<id>/                            admin
  DELETE /api/admin/categories/<id>/                            admin
  GET    /api/admin/payments/                                   admin
  PATCH  /api/admin/orders/<id>/status/                         admin   (fans out → client + worker notifications)
  GET    /api/admin/workers/?search=&page=&status=complete|incomplete  admin
                                                                       (response includes complete_count + incomplete_count)
  GET    /api/admin/workers/<id>/                               admin
  GET    /api/admin/ratings/                                    admin   (enriched: client_name, worker_name, worker_profession, order_category)

Misc
  GET   /api/health/                                public (used by HEALTHCHECK)
```

> Django is REST-only — there is no `/admin/` page. All operational
> management goes through the React dashboard at <http://localhost:5173/>.

---

## 11. TL;DR

- **Backend** is a Django REST API split into 8 apps under `backend/apps/`
  (users, workers, orders, notifications, payments, ratings, favorites,
  admin_api), authenticated with JWT, throttled per-endpoint, served by
  Gunicorn inside a Docker container that auto-applies migrations on
  boot.
- **Mobile** is a Flutter app under `mobile/` that talks to that API via
  a Dio client with a JWT interceptor; state lives in feature-scoped
  cubits registered globally; repositories return `Either<Failure, T>`.
- **Dashboard** is a React 19 + Vite SPA under `frontend/` (landing page +
  admin console). It calls the same `/api/` mount the mobile uses, plus
  the new `/api/admin/*` endpoints in `apps.admin_api`. Deployable as a
  static bundle via Firebase Hosting (`firebase.json`).
- **No Django admin.** `django.contrib.admin` is not in
  `INSTALLED_APPS`; no `admin.py` files; no `/admin/` URL. The React
  dashboard is the sole management UI, calling `apps.admin_api`.
- **Data** is SQLite plus an uploads directory, both kept on named
  Docker volumes so they survive rebuilds.
- **Paymob** is the only external dependency in the order flow, and only
  for the platform commission. Authorize on create, capture on accept,
  void on reject/cancel. Webhook updates statuses.
- **Push** is via FCM if `FCM_SERVER_KEY` is set; otherwise in-app rows
  only, polled by the mobile every 30 s.
- **Connection points** are all REST/JSON: mobile uses
  `ApiConstants.baseUrl`; dashboard uses Vite's dev proxy (`/api`) or
  same-origin when deployed behind the same host. Same JWT contract
  everywhere.
