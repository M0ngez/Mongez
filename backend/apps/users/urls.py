from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Auth
    path("auth/google/",              views.GoogleSignInView.as_view(),            name="google-sign-in"),
    path("auth/login/",               views.AdminLoginView.as_view(),             name="admin-login"),
    path("auth/complete-profile/",    views.CompleteProfileView.as_view(),         name="complete-profile"),
    path("auth/delete-incomplete/",   views.DeleteIncompleteProfileView.as_view(), name="delete-incomplete"),
    path("auth/deletion-token/",      views.DeletionTokenView.as_view(), name="deletion-token"),
    path("auth/delete-account/",      views.DeleteAccountView.as_view(), name="delete-account"),
    path("auth/logout/",              views.LogoutView.as_view(),                 name="logout"),
    path("auth/token/refresh/",       TokenRefreshView.as_view(),                 name="token-refresh"),
    # User profile
    path("users/me/",                 views.MyProfileView.as_view(),              name="my-profile"),
    # Reference data
    path("governorates/",             views.GovernoratesView.as_view(),           name="governorates"),
    # Addresses
    path("addresses/",                views.AddressListCreateView.as_view(),       name="address-list-create"),
    path("addresses/<int:pk>/",       views.AddressDetailView.as_view(),           name="address-detail"),
]
