# Mongez Backend API Links

Base URL:

```text
http://localhost:8000/api/
```

Android emulator URL:

```text
http://10.0.2.2:8000/api/
```

Authentication header for protected endpoints:

```text
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Auth

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/register/` | No | Create a client or worker account |
| POST | `/api/auth/login/` | No | Login and receive JWT tokens |
| POST | `/api/auth/token/refresh/` | No | Create a new access token from a refresh token |

Register body:

```json
{
  "username": "ahmed",
  "phone": "01012345678",
  "address": "Cairo, Egypt",
  "password": "password123",
  "role": "client"
}
```

`role` can be `client` or `worker`.

Login body:

```json
{
  "username": "ahmed",
  "password": "password123"
}
```

Refresh body:

```json
{
  "refresh": "<refresh_token>"
}
```

## Profile

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/users/me/` | Yes | Get current user profile |
| PATCH | `/api/users/me/` | Yes | Update current user profile |

Patch body example:

```json
{
  "username": "ahmed_new",
  "phone": "01099999999",
  "address": "Alexandria, Egypt"
}
```

## Reference data

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/governorates/` | No | List Egypt's 27 governorates (single source of truth used by the mobile + dashboard dropdowns) |

Response shape (each row):

```json
{ "code": "cairo", "name_en": "Cairo", "name_ar": "القاهرة" }
```

## Categories

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/categories/` | No | List service categories |
| POST | `/api/categories/create/` | Yes, admin | Create a service category |

Create body:

```json
{
  "name": "Plumbing"
}
```

## Workers

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/workers/` | No | List available workers |
| POST | `/api/workers/create/` | Yes, worker | Create worker profile (accepts `category_id` + `description` OR raw `profession` + `bio`) |
| GET | `/api/workers/me/` | Yes, worker | Get my worker profile |
| PATCH | `/api/workers/me/` | Yes, worker | Update my worker profile (e.g. `{is_available: true}` for the availability toggle) |
| GET | `/api/workers/me/stats/` | Yes, worker | Performance summary — lifetime + this-month counts + last 5 ratings (powers the worker home dashboard card) |
| GET | `/api/workers/<id>/` | No | Get worker profile details |
| GET | `/api/workers/<id>/stats/` | No | Public order + rating stats for the worker detail page |

Worker list query parameters:

| Parameter | Example | Purpose |
| --- | --- | --- |
| `category` | `/api/workers/?category=1` | Filter by service category id |
| `search` | `/api/workers/?search=plumb` | Filter by profession text |
| `page` | `/api/workers/?page=2` | Pagination page |
| `page_size` | `/api/workers/?page_size=5` | Results per page, max 50 |

Create or update worker profile body — either shape works:

```json
{
  "category_id": 1,
  "description": "Plumbing fixes & water heaters.",
  "experience_years": 5,
  "is_available": true
}
```

or

```json
{
  "profession": "Plumbing",
  "bio": "Plumbing fixes & water heaters.",
  "experience_years": 5,
  "is_available": true
}
```

`/api/workers/me/stats/` response shape:

```json
{
  "profile":    { "id", "profession", "profession_ar",
                  "is_available", "is_verified", "average_rating" },
  "lifetime":   { "orders", "completed_jobs", "accepted_jobs",
                  "pending_requests", "rejected", "cancelled" },
  "this_month": { "orders", "completed_jobs" },
  "recent_ratings": [ {"stars","review","client_username","created_at"} ]
}
```

## Orders

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/orders/` | Yes | List my orders |
| POST | `/api/orders/` | Yes, client | Create order and authorize commission |
| GET | `/api/orders/<id>/` | Yes | Get order details |
| POST | `/api/orders/<id>/accept/` | Yes, worker | Accept pending order |
| POST | `/api/orders/<id>/reject/` | Yes, worker | Reject pending order |
| POST | `/api/orders/<id>/cancel/` | Yes, client | Cancel own order — always while `PENDING`, or `ACCEPTED` after 1 h. Sets `cancellation_reason` from that timing (`OTHER` / `WORKER_DELAY`) |
| POST | `/api/orders/<id>/complete/` | Yes, worker | Worker marks job finished → moves to `WAITING_CONFIRMATION` |
| POST | `/api/orders/<id>/confirm-completion/` | Yes, client | Client confirms job done → `COMPLETED`, bumps worker `completed_jobs` |

Create order body:

```json
{
  "service_category": 1,
  "worker_id": 2
}
```

`worker_id` is optional. The create response can include `payment_key` for Paymob payment UI.

Order statuses:

```text
PENDING, ACCEPTED, REJECTED, CANCELLED, COMPLETED
```

## Notifications

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/notifications/` | Yes | List my notifications |
| POST | `/api/notifications/read-all/` | Yes | Mark all notifications as read |
| POST | `/api/notifications/<id>/read/` | Yes | Mark one notification as read |

## Payments

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/payments/webhook/?hmac=<paymob_hmac>` | Paymob callback | Receive Paymob transaction updates |

The mobile app normally does not call this endpoint directly. Configure it in the Paymob dashboard as the transaction processed callback URL.

## Ratings

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/ratings/` | Yes, client | Rate a completed worker/order |

Rating body:

```json
{
  "order": 10,
  "stars": 5,
  "review": "Great work"
}
```

## Favorites

| Method | URL | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/api/favorites/` | Yes, client | List favorite workers |
| POST | `/api/favorites/` | Yes, client | Add worker to favorites |
| DELETE | `/api/favorites/<id>/` | Yes, client | Remove favorite item |

Add favorite body:

```json
{
  "worker_id": 2
}
```

## Admin (used by the React dashboard)

All admin routes require **admin role**; a non-admin token gets `403`.
The dashboard hydrates them via `usePolling` — see [`all.md` §8.1](all.md)
for cadence.

| Method | URL | Purpose |
| --- | --- | --- |
| GET    | `/api/admin/dashboard/` | Aggregate stats (counts by role, by status), revenue sum, last 10 orders. **Cached server-side for 5 s** so N admins polling at 10 s cost ≤1 DB query/tick. |
| GET    | `/api/admin/users/?search=&role=&page=&page_size=` | Paginated user list |
| POST   | `/api/admin/users/create/` | Create user via `RegisterSerializer` |
| GET/PATCH/DELETE | `/api/admin/users/<id>/` | Read, partial-update (whitelisted fields), delete |
| GET    | `/api/admin/workers/?search=&page=&status=complete\|incomplete` | Paginated worker list. Response **includes `complete_count` + `incomplete_count`** so the dashboard can render the onboarding banner without a second roundtrip. |
| GET    | `/api/admin/workers/<id>/` | Single worker profile detail |
| PATCH/DELETE | `/api/admin/categories/<id>/` | Edit / remove a `ServiceCategory` |
| PATCH  | `/api/admin/orders/<id>/status/` | Set order status. **Fans out** to client + assigned worker notifications (in-app rows + FCM push if configured). |
| GET    | `/api/admin/payments/` | Flat list of `CommissionPayment` rows |
| GET    | `/api/admin/ratings/` | **Enriched** rating list — each row includes `order_id`, `order_category`, `client_username`, `client_name`, `worker_username`, `worker_name`, `worker_profession` |

Status PATCH body:

```json
{ "status": "ACCEPTED" }
```

Workers status filter values: `complete` (has `WorkerProfile`) or
`incomplete` (registered as worker but never finished AddService).
