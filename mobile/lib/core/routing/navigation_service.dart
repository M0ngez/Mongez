import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/features/auth/bloc/auth_cubit.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/screens/google_sign_in_screen.dart';
import 'package:mongez/features/client/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/client/home/presentation/cubit/categories_cubit.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';
import 'package:mongez/features/client/order/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/shared/main/presentation/screens/main_screen.dart';
import 'package:mongez/features/client/order/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/job_history_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/notifications/presentation/screens/notification_screen.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/shared/unread/presentation/cubit/unread_counts_cubit.dart';
import 'package:mongez/features/worker/profile_setup/presentation/cubit/create_worker_profile_cubit.dart';
import 'package:mongez/features/worker/home/presentation/cubit/worker_stats_cubit.dart';
import 'package:mongez/features/client/home/presentation/cubit/workers_cubit.dart';
import 'package:mongez/core/utils/pref_helper.dart';

import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/auth/models/tokens.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/generated/l10n.dart';

class NavigationService {
  /// Root navigator for navigation from non-widget contexts — FCM banner
  /// taps and background/terminated push opens route through this key.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Synthetic session handed to MainScreen while browsing as a guest.
  /// Client role keeps the customer tabs; id -1 never matches real data.
  static const Auth guestAuth = Auth(
    message: 'guest',
    user: User(
      id: -1,
      username: 'guest',
      role: 'client',
      profileCompleted: true,
      verificationStatus: 'verified',
    ),
    tokens: Tokens(access: ''),
    profileCompleted: true,
    verificationStatus: 'verified',
  );

  /// Opens the notifications screen (used as the fallback when a push tap
  /// carries no order id).
  static void openNotifications() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  /// Deep-links a push tap to the linked order. Mirrors the tap logic of the
  /// notifications screen; falls back to the notifications screen on any
  /// failure.
  static Future<void> openOrderByNotification(int orderId) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    final result = await getIt.get<OrderRepository>().getOrderById(orderId);
    result.fold(
      (_) => openNotifications(),
      (order) {
        final context = navigatorKey.currentContext;
        if (context == null) return;
        final profileState = context.read<ProfileCubit>().state;
        final currentUserId = profileState is ProfileSuccess
            ? profileState.profile.id
            : -1;
        final isCustomer = order.clientId == currentUserId;
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                OrderDetailsScreen(order: order, isCustomer: isCustomer),
          ),
        );
      },
    );
  }
  static Future<void> toMainScreen(
    BuildContext context,
    Auth auth, {
    int initialIndex = 0,
  }) async {
    // A real session always ends guest mode (login from the guest flow).
    GuestSession.exit();
    _clearImageCache();
    _resetAllCubits(context);
    _fetchFreshData(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(auth: auth, initialIndex: initialIndex),
      ),
      (route) => false,
    );
  }

  /// Enters the app as a guest: no token, no persisted session — only the
  /// in-memory GuestSession flag, so a cold start always shows Get Started
  /// again. Only public data (workers, categories) is fetched.
  static Future<void> toGuestMain(BuildContext context) async {
    GuestSession.enter();
    _clearImageCache();
    _resetAllCubits(context);
    context.read<WorkersCubit>().refresh();
    context.read<CategoriesCubit>().fetchCategories();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(auth: guestAuth)),
      (route) => false,
    );
  }

  /// Gate for actions that require a real account (checkout, favorites,
  /// personal screens…). Logged-in users run [onLoggedIn] immediately;
  /// guests get a "sign in first" dialog whose Login button opens the
  /// sign-in screen and replays [onLoggedIn] after a successful login.
  ///
  /// [mainTabIndex] is the MainScreen tab to land on after login so the
  /// user returns to where they started (profile=3, favorites=1…).
  static void requireLogin(
    BuildContext context, {
    String? message,
    int mainTabIndex = 0,
    VoidCallback? onLoggedIn,
  }) {
    if (!GuestSession.isGuest) {
      onLoggedIn?.call();
      return;
    }

    final lang = S.of(context);
    final navigator = Navigator.of(context);
    final authCubit = context.read<AuthCubit>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(lang.loginRequiredTitle),
        content: Text(message ?? lang.loginRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(lang.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: authCubit,
                    child: GoogleSignInScreen(
                      mainTabIndex: mainTabIndex,
                      onLoggedIn: onLoggedIn,
                    ),
                  ),
                ),
              );
            },
            child: Text(lang.login),
          ),
        ],
      ),
    );
  }

  static Future<void> logout(BuildContext context) async {
    _clearImageCache();
    _resetAllCubits(context);
    final navigator = Navigator.of(context);

    // Sign out from Google
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('[LOGOUT] Google signOut failed: $e');
    }

    await PrefHelper.clearAll();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const GoogleSignInScreen(),
        ),
      ),
      (route) => false,
    );
  }

  static void _clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static void _resetAllCubits(BuildContext context) {
    context.read<ProfileCubit>().reset();
    context.read<FavoritesCubit>().reset();
    context.read<CustomerOrdersCubit>().reset();
    context.read<TechnicianOrdersCubit>().reset();
    context.read<JobHistoryCubit>().reset();
    context.read<WorkersCubit>().reset();
    context.read<CategoriesCubit>().reset();
    context.read<AuthCubit>().reset();
    context.read<CheckoutCubit>().reset();
    context.read<CreateWorkerProfileCubit>().reset();
    context.read<WorkerStatsCubit>().reset();
    // Notification polling stops with the session and the nav badges drop
    // to zero, so the next account never inherits them.
    context.read<NotificationCubit>().reset();
    context.read<UnreadCountsCubit>().reset();
  }

  static void _fetchFreshData(BuildContext context) {
    context.read<ProfileCubit>().getProfile();
    context.read<FavoritesCubit>().getFavorites();
    context.read<CustomerOrdersCubit>().getOrders();
    context.read<TechnicianOrdersCubit>().getOrders();
    context.read<JobHistoryCubit>().getJobHistory();
    context.read<WorkersCubit>().refresh();
    context.read<CategoriesCubit>().fetchCategories();
  }
}
