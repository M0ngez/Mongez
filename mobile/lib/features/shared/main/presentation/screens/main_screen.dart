import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/shared/account/presentation/screens/account_screen.dart';
import 'package:mongez/features/client/favorites/presentation/screens/favorite_screen.dart';
import 'package:mongez/features/client/home/presentation/screens/home_screen.dart';
import 'package:mongez/features/worker/home/presentation/screens/worker_home_screen.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/unread/presentation/cubit/unread_counts_cubit.dart';
import 'package:mongez/features/client/order/presentation/screens/customer_requests_screen.dart';
import 'package:mongez/features/worker/requests/presentation/screens/job_history_screen.dart';
import 'package:mongez/features/worker/requests/presentation/screens/technician_requests_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/custom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final Auth auth;

  /// Tab to open on mount — the guest login redirect returns the user
  /// to the tab they started from instead of always the home tab.
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.auth,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = widget.initialIndex;
  NotificationCubit? _notifCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Guests have no notifications — skip the 401-spamming poll.
      if (GuestSession.isGuest) return;
      _notifCubit = context.read<NotificationCubit>();
      _notifCubit?.startPolling();
      // Bind the nav badges to this account's role and subscribe the cubit
      // to the sources it derives its numbers from. Reset happens in
      // NavigationService._resetAllCubits on logout/user switch.
      context
          .read<UnreadCountsCubit>()
          .start(role: widget.auth.user!.role ?? 'client');
    });
  }

  @override
  void dispose() {
    // Use the saved reference — context.read after deactivate throws.
    _notifCubit?.stopPolling();
    super.dispose();
  }

  late final List<Widget> _screensCustomer = [
    HomeScreen(isCustomer: true, user: widget.auth.user!),
    FavoiriteScreen(),
    const RequistesScreen(),
    const AccountScreen(isCustomer: true),
  ];

  late final List<Widget> _screensTechnician = [
    WorkerHomeScreen(user: widget.auth.user!),
    const JobHistoryScreen(),
    const RequestsScreen(),
    const AccountScreen(isCustomer: false),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final isCustomer = widget.auth.user!.role == 'client';

    return Scaffold(
      body: isCustomer
          ? _screensCustomer[_currentIndex]
          : _screensTechnician[_currentIndex],
      bottomNavigationBar: BlocBuilder<UnreadCountsCubit, UnreadCountsState>(
        builder: (context, unread) {
          return CustomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            elements: [
              NavItem(
                  label: lang.home, iconPath: 'assets/images/home icon.png'),
              NavItem(
                label: isCustomer ? lang.favorites : lang.jobHistory,
                iconPath: isCustomer
                    ? 'assets/images/saved icon.png'
                    : 'assets/images/Wallet-duotone.png',
                // Total saved favorites — the worker tab here is Job History,
                // which has no favorites to count.
                badgeCount: isCustomer ? unread.favorites : 0,
                badgeSemanticsLabel: lang.favoritesCount(unread.favorites),
              ),
              NavItem(
                label: lang.requests,
                iconPath: 'assets/images/shopping-cart.png',
                badgeCount: unread.requests,
                badgeSemanticsLabel: lang.unreadRequestsCount(unread.requests),
              ),
              NavItem(
                  label: lang.account,
                  iconPath: 'assets/images/user icon.png'),
            ],
          );
        },
      ),
    );
  }
}

