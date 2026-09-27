"""
Scoped throttle classes for sensitive endpoints.

Rates are configured under REST_FRAMEWORK.DEFAULT_THROTTLE_RATES in settings.py
and are tunable via environment variables (THROTTLE_AUTH, THROTTLE_ORDER, etc.).
"""

from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class AuthRateThrottle(AnonRateThrottle):
    """Used on login/register to slow down brute force."""
    scope = "auth"


class OrderCreateThrottle(UserRateThrottle):
    """Prevents a single client from spamming new orders."""
    scope = "order_create"


class RatingThrottle(UserRateThrottle):
    """Slows rating spam by a single client."""
    scope = "rating"


class DeletionMintThrottle(UserRateThrottle):
    """Account-deletion link minting — authenticated, so per-user."""
    scope = "deletion_mint"


class DeletionConfirmThrottle(AnonRateThrottle):
    """Account-deletion confirm — anonymous browser tab, so per-IP."""
    scope = "deletion_confirm"
