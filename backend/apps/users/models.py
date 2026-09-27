from django.contrib.auth.models import AbstractUser
from django.core.validators import RegexValidator
from django.db import models


phone_validator = RegexValidator(
    regex=r"^\+?[0-9 ()-]{7,20}$",
    message="Enter a valid phone number (digits, optional +, spaces, dashes).",
)

eg_phone_validator = RegexValidator(
    regex=r"^(\+?20)?1[0125]\d{8}$",
    message="Enter a valid Egyptian mobile (e.g. +201012345678 or 01012345678).",
)


class Governorate(models.TextChoices):
    CAIRO = "cairo", "Cairo"
    GIZA = "giza", "Giza"
    ALEXANDRIA = "alexandria", "Alexandria"
    BENI_SUEF = "beni_suef", "Beni Suef"
    QALYUBIA = "qalyubia", "Qalyubia"
    SHARQIA = "sharqia", "Sharqia"
    DAKAHLIA = "dakahlia", "Dakahlia"
    MINYA = "minya", "Minya"
    FAYOUM = "fayoum", "Fayoum"
    ASYUT = "asyut", "Asyut"
    SOHAG = "sohag", "Sohag"
    LUXOR = "luxor", "Luxor"
    ASWAN = "aswan", "Aswan"
    PORT_SAID = "port_said", "Port Said"
    SUEZ = "suez", "Suez"
    ISMAILIA = "ismailia", "Ismailia"
    DAMIETTA = "damietta", "Damietta"
    KAFR_SHEIKH = "kafr_sheikh", "Kafr El-Sheikh"
    GHARBIA = "gharbia", "Gharbia"
    MENOFIA = "menofia", "Menofia"
    BEHEIRA = "beheira", "Beheira"
    QENA = "qena", "Qena"
    RED_SEA = "red_sea", "Red Sea"
    NEW_VALLEY = "new_valley", "New Valley"
    MATROUH = "matrouh", "Matrouh"
    NORTH_SINAI = "north_sinai", "North Sinai"
    SOUTH_SINAI = "south_sinai", "South Sinai"


class User(AbstractUser):

    class Role(models.TextChoices):
        CLIENT = "client", "Client"
        WORKER = "worker", "Worker"
        ADMIN = "admin", "Admin"

    class VerificationStatus(models.TextChoices):
        PENDING = "pending", "Pending Verification"
        VERIFIED = "verified", "Verified"
        REJECTED = "rejected", "Rejected"

    google_id = models.CharField(
        max_length=255,
        unique=True,
        null=True,
        blank=True,
        db_index=True,
        help_text="Google OAuth sub (unique identifier).",
    )
    profile_completed = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Whether the user has completed the required profile fields.",
    )

    phone = models.CharField(
        max_length=20,
        unique=False,
        blank=True,
        default="",
        validators=[phone_validator],
    )
    name_ar = models.CharField(
        max_length=120, blank=True,
        help_text="Arabic display name (الاسم بالعربية).",
    )
    address = models.CharField(max_length=255, blank=True)
    governorate = models.CharField(
        max_length=20,
        choices=Governorate.choices,
        blank=True,
        db_index=True,
    )
    city = models.CharField(max_length=80, blank=True, db_index=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.CLIENT,
    )

    # ── Worker verification ──
    verification_status = models.CharField(
        max_length=12,
        choices=VerificationStatus.choices,
        default=VerificationStatus.VERIFIED,
        db_index=True,
        help_text="Only workers need verification; clients are auto-verified.",
    )
    id_card_image = models.ImageField(
        upload_to="id_cards/", blank=True, null=True,
        help_text="National ID card photo uploaded by the worker during registration.",
    )
    verified_at = models.DateTimeField(
        null=True, blank=True,
        help_text="When the admin verified the worker account.",
    )
    verified_by = models.ForeignKey(
        "self", null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name="verified_workers",
        help_text="Admin who verified this worker.",
    )
    rejection_reason = models.TextField(
        blank=True, default="",
        help_text="Reason provided by admin when rejecting a worker.",
    )
    language = models.CharField(
        max_length=5,
        choices=[("ar", "Arabic"), ("en", "English")],
        default="en",
        help_text="Preferred language for notifications.",
    )
    google_picture_url = models.URLField(
        max_length=500,
        blank=True,
        default="",
        help_text="Google profile picture URL (not stored locally).",
    )
    deletion_nonce = models.CharField(
        max_length=64,
        blank=True,
        default="",
        db_index=True,
        help_text=(
            "Makes the account-deletion token single use: it is set when the "
            "token is minted and cleared once the deletion is applied."
        ),
    )

    REQUIRED_FIELDS = ["email"]

    def __str__(self):
        return f"{self.username} ({self.role})"

    @property
    def display_name(self):
        return self.name_ar or self.get_full_name() or self.username

    class Meta:
        verbose_name = "user"
        verbose_name_plural = "users"
        ordering = ["-date_joined"]
        indexes = [
            models.Index(fields=["role"]),
            models.Index(fields=["phone"]),
            models.Index(fields=["governorate", "city"]),
            models.Index(fields=["google_id"]),
            models.Index(fields=["profile_completed"]),
            models.Index(fields=["verification_status"]),
        ]


class Address(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="addresses",
    )
    label = models.CharField(max_length=100, blank=True, help_text="e.g. Home, Office")
    address = models.CharField(max_length=255)
    governorate = models.CharField(
        max_length=20,
        choices=Governorate.choices,
        blank=True,
    )
    city = models.CharField(max_length=80, blank=True)
    is_default = models.BooleanField(default=False)

    class Meta:
        verbose_name_plural = "addresses"
        ordering = ["-is_default", "id"]

    def __str__(self):
        return f"{self.label or 'Address'} – {self.address}"