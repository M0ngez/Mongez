import os
from datetime import timedelta
from pathlib import Path
from urllib.parse import unquote, urlparse

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv

AUTH_USER_MODEL = "users.User"

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")


def env_bool(name, default=False):
    value = os.getenv(name)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "on"}


def env_list(name, default=""):
    value = os.getenv(name, default)
    return [item.strip() for item in value.split(",") if item.strip()]


def parse_database_url(url):
    """Parse a postgres://USER:PASS@HOST:PORT/NAME URL into Django DB kwargs."""
    parsed = urlparse(url)
    if parsed.scheme not in ("postgres", "postgresql"):
        raise ImproperlyConfigured(
            f"Unsupported DATABASE_URL scheme '{parsed.scheme}'. Use postgres://"
        )
    return {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": parsed.path.lstrip("/"),
        "USER": unquote(parsed.username or ""),
        "PASSWORD": unquote(parsed.password or ""),
        "HOST": parsed.hostname or "",
        "PORT": str(parsed.port) if parsed.port else "",
    }


# --- Render / Railway / environment detection ------------------------------
# Render injects RENDER=1 and RENDER_EXTERNAL_HOSTNAME for every service.
# Railway injects RAILWAY_PROJECT_ID / RAILWAY_SERVICE_NAME and, once a public
# domain is generated, RAILWAY_PUBLIC_DOMAIN. Both platforms are treated as
# production so DEBUG defaults to False and DJANGO_SECRET_KEY is required.
IS_RENDER = env_bool("RENDER", default=False)
IS_RAILWAY = bool(
    os.getenv("RAILWAY_PROJECT_ID")
    or os.getenv("RAILWAY_SERVICE_NAME")
    or os.getenv("RAILWAY_ENVIRONMENT")
    or os.getenv("RAILWAY_PUBLIC_DOMAIN")
)
DJANGO_ENV = os.getenv(
    "DJANGO_ENV",
    "production" if (IS_RENDER or IS_RAILWAY) else "development",
).lower()

# SECRET_KEY -- NEVER hardcode a real value in code. A dev-only fallback is
# allowed so `manage.py` works locally without a .env; in any production
# environment (Render/Hostinger) DJANGO_SECRET_KEY MUST be provided or Django
# fails to start rather than silently shipping a weak key.
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
if SECRET_KEY is None:
    if DJANGO_ENV == "production":
        raise ImproperlyConfigured(
            "DJANGO_SECRET_KEY must be set in production (set it on Render/Railway)."
        )
    SECRET_KEY = "django-insecure-local-dev-key-change-me"

# DEBUG is False by default in production; local dev keeps True unless overridden.
DEBUG = env_bool("DJANGO_DEBUG", default=(DJANGO_ENV != "production"))

# ALLOWED_HOSTS -- merged from the env list plus RENDER_EXTERNAL_HOSTNAME when
# running on Render. No '*' is ever used in production.
ALLOWED_HOSTS = env_list("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1,10.0.2.2,mongez.digital,10.179.240.131")
RENDER_EXTERNAL_HOSTNAME = os.getenv("RENDER_EXTERNAL_HOSTNAME", "").strip()
if RENDER_EXTERNAL_HOSTNAME and RENDER_EXTERNAL_HOSTNAME not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(RENDER_EXTERNAL_HOSTNAME)
# Railway injects RAILWAY_PUBLIC_DOMAIN (e.g. myapp.up.railway.app). Add it so
# the API is reachable at the Railway URL without a DisallowedHost error.
RAILWAY_PUBLIC_DOMAIN = os.getenv("RAILWAY_PUBLIC_DOMAIN", "").strip()
if RAILWAY_PUBLIC_DOMAIN and RAILWAY_PUBLIC_DOMAIN not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(RAILWAY_PUBLIC_DOMAIN)
# Railway healthcheck probes come from healthcheck.railway.app; Django must
# allow this hostname or the probe is rejected with DisallowedHost.
if IS_RAILWAY and "healthcheck.railway.app" not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append("healthcheck.railway.app")


INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'cloudinary_storage',
    'django.contrib.staticfiles',
    'cloudinary',
    "corsheaders",
    'rest_framework',
    'rest_framework_simplejwt',
    'apps.users',
    'apps.workers',
    'apps.site_config',
    'apps.notifications',
    'apps.payments',
    'apps.orders',
    'apps.ratings',
    'apps.favorites',
    'apps.admin_api',
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    'django.middleware.security.SecurityMiddleware',
    # WhiteNoise serves /static/ when DEBUG=False so the DRF browsable
    # API still loads its CSS without an external reverse proxy.
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# --- Database --------------------------------------------------------------
# Priority: DATABASE_URL (Production / Render) -> per-variable DB_* (Local /
# Docker / Hostinger). If DATABASE_URL is set it fully determines the DB and
# overrides DB_*; otherwise the individual DB_* variables are used unchanged,
# preserving the existing local, Docker and Hostinger behaviour.
DATABASE_URL = os.getenv("DATABASE_URL", "").strip()

if DATABASE_URL:
    DATABASES = {"default": parse_database_url(DATABASE_URL)}
else:
    DATABASES = {
        'default': {
            'ENGINE': os.getenv("DB_ENGINE", "django.db.backends.postgresql"),
            'NAME': os.getenv("DB_NAME", "mongez"),
            'USER': os.getenv("DB_USER", "mongez"),
            'PASSWORD': os.getenv("DB_PASSWORD", ""),
            'HOST': os.getenv("DB_HOST", "127.0.0.1"),
            'PORT': os.getenv("DB_PORT", "5432"),
        }
    }


AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


LANGUAGE_CODE = 'en-us'
TIME_ZONE = os.getenv("DJANGO_TIME_ZONE", "UTC")
USE_I18N = True
USE_TZ = True


STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

# Cloudinary — used for media file storage in production (Render).
# On Render, set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and
# CLOUDINARY_API_SECRET in the service environment. Locally, Django falls
# back to the local MEDIA_ROOT filesystem when the env vars are empty.
CLOUDINARY_STORAGE = {
    'CLOUD_NAME': os.getenv('CLOUDINARY_CLOUD_NAME', ''),
    'API_KEY': os.getenv('CLOUDINARY_API_KEY', ''),
    'API_SECRET': os.getenv('CLOUDINARY_API_SECRET', ''),
}
DEFAULT_FILE_STORAGE = (
    'cloudinary_storage.storage.MediaCloudinaryStorage'
    if os.getenv('CLOUDINARY_CLOUD_NAME')
    else 'django.core.files.storage.FileSystemStorage'
)

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": int(os.getenv("API_PAGE_SIZE", "20")),
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": os.getenv("THROTTLE_ANON", "30/min"),
        "user": os.getenv("THROTTLE_USER", "120/min"),
        "auth": os.getenv("THROTTLE_AUTH", "10/min"),       # login/register
        "order_create": os.getenv("THROTTLE_ORDER", "20/hour"),
        "rating": os.getenv("THROTTLE_RATING", "30/hour"),
        "deletion_mint": os.getenv("THROTTLE_DELETION_MINT", "10/min"),
        "deletion_confirm": os.getenv("THROTTLE_DELETION_CONFIRM", "5/min"),
    },
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=int(os.getenv("JWT_ACCESS_MINUTES", "60"))),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=int(os.getenv("JWT_REFRESH_DAYS", "7"))),
    "ROTATE_REFRESH_TOKENS": True,
}

CORS_ALLOW_ALL_ORIGINS = env_bool("CORS_ALLOW_ALL_ORIGINS", default=DEBUG)
CORS_ALLOWED_ORIGINS = env_list("CORS_ALLOWED_ORIGINS")
CSRF_TRUSTED_ORIGINS = env_list("CSRF_TRUSTED_ORIGINS")

# On Render, automatically trust the service's own origin for CORS + CSRF so
# the browsable API and any same-origin page work out of the box. The env vars
# (CORS_ALLOWED_ORIGINS / CSRF_TRUSTED_ORIGINS) remain the source of truth for
# cross-origin access (e.g. the frontend dashboard); this only appends the
# Render origin and never removes anything the operator configured.
if IS_RENDER and RENDER_EXTERNAL_HOSTNAME:
    render_origin = f"https://{RENDER_EXTERNAL_HOSTNAME}"
    if render_origin not in CORS_ALLOWED_ORIGINS:
        CORS_ALLOWED_ORIGINS.append(render_origin)
    if render_origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(render_origin)

# Same for Railway: once a public domain exists, trust it for CORS + CSRF so
# the browsable API and same-origin requests work without manual vars.
if IS_RAILWAY and RAILWAY_PUBLIC_DOMAIN:
    railway_origin = f"https://{RAILWAY_PUBLIC_DOMAIN}"
    if railway_origin not in CORS_ALLOWED_ORIGINS:
        CORS_ALLOWED_ORIGINS.append(railway_origin)
    if railway_origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(railway_origin)

# Allow the frontend Static Site (Render, e.g. the React dashboard). Set
# FRONTEND_URL in the Render service env to the https URL of the dashboard.
FRONTEND_URL = os.getenv("FRONTEND_URL", "").strip().rstrip("/")
if FRONTEND_URL:
    if FRONTEND_URL not in CORS_ALLOWED_ORIGINS:
        CORS_ALLOWED_ORIGINS.append(FRONTEND_URL)
    if FRONTEND_URL not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(FRONTEND_URL)


# --- Security / HTTPS ------------------------------------------------------
# Production hardening flags, all opt-in via env and OFF by default so local
# HTTP development and the existing Hostinger (Apache) setup keep working.
# On Render/Railway the secure-cookie / SSL and proxy header flags are on by
# default (both platforms terminate TLS at their edge proxy).
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https") if env_bool(
    "DJANGO_SECURE_PROXY_SSL_HEADER", default=(IS_RENDER or IS_RAILWAY)
) else None
SECURE_SSL_REDIRECT = env_bool("DJANGO_SECURE_SSL_REDIRECT", default=False)
SESSION_COOKIE_SECURE = env_bool("DJANGO_SESSION_COOKIE_SECURE", default=(IS_RENDER or IS_RAILWAY))
CSRF_COOKIE_SECURE = env_bool("DJANGO_CSRF_COOKIE_SECURE", default=(IS_RENDER or IS_RAILWAY))
SECURE_HSTS_SECONDS = int(os.getenv("DJANGO_SECURE_HSTS_SECONDS", "0"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = env_bool("DJANGO_SECURE_HSTS_INCLUDE_SUBDOMAINS", default=False)
SECURE_HSTS_PRELOAD = env_bool("DJANGO_SECURE_HSTS_PRELOAD", default=False)

PAYMOB_API_KEY = os.getenv("PAYMOB_API_KEY", "")
PAYMOB_INTEGRATION_ID = int(os.getenv("PAYMOB_INTEGRATION_ID", "0"))
PAYMOB_HMAC_SECRET = os.getenv("PAYMOB_HMAC_SECRET", "")
COMMISSION_AMOUNT = int(os.getenv("COMMISSION_AMOUNT", "20"))

# Firebase Cloud Messaging (HTTP v1 API)
FCM_PROJECT_ID = os.getenv("FCM_PROJECT_ID", "mongez-86fdf")

# Google OAuth — Web Client ID used to verify id_tokens from the mobile app.
GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_WEB_CLIENT_ID", "")
