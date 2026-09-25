import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/widgets/guest_empty_state.dart';
import 'package:mongez/features/shared/notifications/data/models/notification_model.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';
import 'package:mongez/features/client/order/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/widgets/skeletons/skeleton_notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  NotificationCubit? _cubit;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The cubit only polls the cheap unread-count endpoint in the
    // background; the full list loads here when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit = context.read<NotificationCubit>();
      _cubit!.refresh();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit?.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(lang.notifications),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationSuccess &&
                  state.notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                  child: Text(lang.markAllRead),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: GuestSession.isGuest
          ? GuestEmptyState(
              icon: Icons.notifications_none_rounded,
              message: lang.signInToViewData,
              onLogin: () => NavigationService.requireLogin(
                context,
                mainTabIndex: 0,
                onLoggedIn: () => NavigationService.navigatorKey.currentState
                    ?.push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                ),
              ),
            )
          : BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationInitial ||
              state is NotificationLoading ||
              state is NotificationCountChanged) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonNotificationTile(),
            );
          }
          if (state is NotificationSuccess) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(lang.noNotifications, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().refresh(),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _NotificationTile(notif: notifications[index]),
              ),
            );
          }
          if (state is NotificationFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationCubit>().refresh(),
                    child: Text(lang.retry),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isUnread = !notif.isRead;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isUnread ? Icons.notifications : Icons.notifications_none,
          color: isUnread ? theme.colorScheme.primary : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        notif.title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notif.message,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (notif.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTime(notif.createdAt!, lang),
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            )
          : null,
      onTap: () {
        if (isUnread) {
          context.read<NotificationCubit>().markAsRead(notif.id);
        }
        if (notif.orderId != null) {
          _navigateToOrder(context, notif.orderId!);
        }
      },
    );
  }

  String _formatTime(String dateStr, S lang) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return lang.justNow;
      if (diff.inMinutes < 60) return lang.minutesAgo(diff.inMinutes);
      if (diff.inHours < 24) return lang.hoursAgo(diff.inHours);
      if (diff.inDays < 7) return lang.daysAgo(diff.inDays);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  void _navigateToOrder(BuildContext context, int orderId) async {
    final repo = getIt.get<OrderRepository>();
    final result = await repo.getOrderById(orderId);
    result.fold(
      (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorOccurred)),
        );
      },
      (order) {
        if (!context.mounted) return;
        final currentUserId = (context.read<ProfileCubit>().state is ProfileSuccess)
            ? (context.read<ProfileCubit>().state as ProfileSuccess).profile.id
            : -1;
        final isCustomer = order.clientId == currentUserId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order, isCustomer: isCustomer),
          ),
        );
      },
    );
  }
}
