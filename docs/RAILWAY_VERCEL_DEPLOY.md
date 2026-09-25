# دليل النشر على Railway + Vercel

> دليل شامل لرفع المشروع على:
> - **Backend (Django API)** ← Railway
> - **Database (PostgreSQL)** ← Railway
> - **Frontend (React dashboard)** ← Vercel

---

## المعمارية النهائية

```
Vercel (Frontend)              Railway (Backend + DB)
https://mongez-psi.vercel.app       https://mongez-api-production-1a85.up.railway.app
      │                                   │
      └── VITE_API_URL ──────────────────▶│
                  (build time)            │
                                          │
                              DATABASE_URL │ Postgres plugin
                                          ▼
                                      PostgreSQL
```

---

## الخطوة 0: المحتاج المسبق

| # | الحساب | الرابط |
|---|---|---|
| 1 | **Railway** | [railway.app](https://railway.app) — مجاني لـ التجربة، محتاج card بيعتمد |
| 2 | **Vercel** | [vercel.com](https://vercel.com) — مجاني |
| 3 | **Cloudinary** | [cloudinary.com](https://cloudinary.com) — لتخزين الملفات |
| 4 | **GitHub** | [github.com](https://github.com) — منصة الكود |

---

## الخطوة 1: رفع الـ Backend على Railway

### 1.1 اعمل مشروع جديد على Railway

1. ادخل [railway.app](https://railway.app)
2. اعمل **New Project** → **Deploy from GitHub repo**
3. اختار `A7MADTANTAWY/Mongez-Cross-Platform`

### 1.2 أضف PostgreSQL

1. في المشروع، اضغط **New** → **Database** → **PostgreSQL**
2. Railway هيعمل instance ويزود **`DATABASE_URL`** تلقائياً
3. ربط الـ Database بالـ Service: من إعدادات الـ GraphQL/Service → Variables → أضف `DATABASE_URL` reference للمتغير اللي PostgreSQL بيوفره

### 1.3 شغّل الـ Backend Service

لما تضيف الـ service من الـ repo، حط الإعدادات دي:

| الإعداد | القيمة |
|---|---|
| **Root Directory** | `backend` |
| **Build Provider** | Nixpacks (افتراضي) |
| **Start Command** | (من `nixpacks.toml`) ✅ |

> ⚠️ ممكن يطلب منك تحدد root directory كـ `backend/` لأن فيه `nixpacks.toml` هناك — من إعدادات الـ Service → **Settings** → **Root Directory** = `backend`

### 1.4 متغيرات البيئة في Railway

من **Settings** الخاصة بالـ backend service → **Variables**:

| Variable | القيمة |
|---|---|
| `DATABASE_URL` | (auto من PostgreSQL plugin) |
| `DJANGO_SECRET_KEY` | «اجيب لونغ random key» (مثال: `django-insecure-...` أو `openssl rand -hex 40`) |
| `DJANGO_DEBUG` | `false` |
| `DJANGO_ENV` | `production` |
| `FRONTEND_URL` | `https://<your-app>.vercel.app` (رابط الـ Vercel بعد ما تعمله) |
| `DJANGO_SECURE_SSL_REDIRECT` | `false` (مهم على Railway لأن الـ proxy بيعمل HTTPS) |
| `DJANGO_SECURE_PROXY_SSL_HEADER` | `true` |
| `CLOUDINARY_CLOUD_NAME` | (من حسابك) |
| `CLOUDINARY_API_KEY` | (من حسابك) |
| `CLOUDINARY_API_SECRET` | (من حسابك) |

> ⚠️ **مهم:** `DJANGO_SECURE_SSL_REDIRECT` لازم يكون `false` على Railway. لو `true`، هيحاول يحوّل كل طلب لـ HTTPS وفي المشكلة متدورة بسبب الـ proxy. Railway بيخدم الـ HTTPS بنفسه.

### 1.5 اعمل Deploy

بعد ما تظبط كل حاجة، اضغط **Deploy**. Railway هيبني الـ backend تلقائياً مع migrations من `nixpacks.toml`.

---

## الخطوة 2: رفع الـ Frontend على Vercel

### 2.1 اربط الـ Repo

1. ادخل [vercel.com](https://vercel.com)
2. اضغط **New Project**
3. استورد الـ repo بتاعك `A7MADTANTAWY/Mongez-Cross-Platform`
4. Vercel هيكتشف الـ Vite project تلقائياً

### 2.2 الإعدادات

| الإعداد | القيمة |
|---|---|
| **Root Directory** | `frontend` |
| **Framework** | Vite |
| **Build Command** | `npm run build` |
| **Output Directory** | `dist` |

### 2.3 متغيرات البيئة

من **Settings** → **Environment Variables** (أو من شاشة الـ import):

| Variable | القيمة |
|---|---|
| `VITE_API_URL` | `https://<your-backend>.up.railway.app/api` |

> ⚠️ **مهم:** `VITE_API_URL` لازم يشمل `/api` في الآخر لأن الـ axios باستخدامه كـ baseURL. في الـ Render كان `...onrender.com/api`. هنا دلوقتي `...up.railway.app/api`.

> ⚠️ لازم الـ env var يتظبط **قبل الـ build** — Vite بيحشو الـ vars في وقت البناء.

### 2.4 اعمل Deploy

اضغط **Deploy**. Vercel هيبني الـ React ويخدمه على `https://<your-project>.vercel.app`.

---

## الخطوة 3: الوصل بين الـ Frontend والـ Backend

1. بعد ما الـ frontend يبقى على Vercel، خد الـ **URL** بتاعه (مثلاً `https://mongez-psi.vercel.app`)
2. روح للـ Railway backend service → Variables
3. غيّر `FRONTEND_URL` = `https://mongez-psi.vercel.app` (بدون slash في النهاية)
4. حدّث إعدادات الـ Vercel `VITE_API_URL` = `https://mongez-api-production-1a85.up.railway.app/api`
5. أعد deploy الـ frontend (لو غيّرت الـ API_URL)

---

## الخطوة 4: التحقق

### الـ Backend
```
https://mongez-api-production-1a85.up.railway.app/api/health/
```
**متوقع:**
```json
{"status": "ok"}
```

### الـ Frontend
افتح `https://mongez-psi.vercel.app/` → لازم تشوف الـ Login.

### جرّب:
- [ ] Login
- [ ] API requests
- [ ] رفع صورة (تأكد إن Cloudinary شغال)
- [ ] React Router (التنقل والـ refresh)

---

## ملاحظات مهمة

### 1. مخطط التكلفة

| المنصة | الخدمة | التكلفة |
|---|---|---|
| Railway | Backend + Postgres | يبدأ بـ $0 تجريبي، بيطلب card. بعد الـ trial بيبدأ يخصم (بسيط) |
| Vercel | Frontend (static) | **مجاني** (Hobby) |
| Cloudinary | Media | **مجاني** (10 GB) |

> ⚠️ **Railway مش ببلاش زي Render.** فيه trial credit محدود، وبعدها بيبقى بالميتر (حسب الـ usage). لو عايز تفضل مجاني خالص، استخدم Render للـ backend + Vercel للـ frontend بدل Railway.

### 2. المشكلة اللي فشلت مع Render

الخطأ كان:
```
pre-deploy command is not supported for free tier services
```
- ده **فقط** على Render Free plan. 
- على Railway، مشكلة الـ build/deploy دي **مش موجودة** — بنستخدم `nixpacks.toml` والـ migrate في الـ start command، وده شغال على أي plan.

### 3. الـ `.env` المحلي

الـ `backend/.env` ده **للتطوير المحلي فقط**. على Railway/إنتاج، المتغيرات بتبقى من الـ dashboard. مش بيتم رفع الـ `.env` على GitHub (it's gitignored).

### 4. Media / Static files

- **الـ media** (الصور) → Cloudinary (مش على الـ disk)
- **الـ static** (CSS/JS بتاع الـ browsable API) → `collectstatic` بيشتغل في الـ start command

---

## مشاكل شائعة وحلولها

| المشكلة | الحل |
|---|---|
| `DisallowedHost` error | تأكد إن `RAILWAY_PUBLIC_DOMAIN` موجود تلقائياً (settings.py بتضيفه). لو لسه، أضفه يدوياً في Variables. |
| `DATABASE_URL` connection refused | تأكد إن الـ Postgres و الـ backend في نفس الـ project/region. |
| الـ migration فشل | Railway بيشغّل migrate في كل start. لو فشل أول مرة، أعد الـ Deploy. |
| CORS error في Vercel | تأكد إن `FRONTEND_URL` في Railway = رابط الـ Vercel بالظبط |
| 404 in React Router | `vercel.json` فيه rewrite rules — تأكد إنه موجود في `frontend/` |
| `VITE_API_URL` مش بيشتغل | لازم تعيد build بعد تغييره (env var بتتحط وقت البناء) |
| .up.railway.app مش بيتقبل | أضف `RAILWAY_PUBLIC_DOMAIN` يدوياً لو مش موجود |

---

## التوثيق الإضافي

| الملف | المحتوى |
|---|---|
| `backend/nixpacks.toml` | إعدادات Railway build/start |
| `frontend/vercel.json` | إعدادات Vercel (build + rewrites) |
| `docs/RENDER.md` | توثيق Render (اختياري) |
| `docs/DEPLOYMENT.md` | ملخص نشر عام |
