import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:mongez/features/client/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';

part 'unread_counts_state.dart';

/// Single source of truth for the bottom-nav badges.
///
/// It owns no timer and never hits the network: it derives the badge numbers
/// from cubits that already exist (notifications every 5 s, order list every
/// 15 s, favorites on every add/remove) and simply recomputes whenever one of
/// them emits — including after a read/mark-all-read or a push message.
///
/// Badges stay at zero until [start] is called with a real role, so guests
/// and the signed-out screens never show another user's leftovers.
class UnreadCountsCubit extends Cubit<UnreadCountsState> {
  final NotificationCubit notificationCubit;
  final TechnicianOrdersCubit technicianOrdersCubit;
  final ProfileCubit profileCubit;
  final FavoritesCubit favoritesCubit;

  StreamSubscription<NotificationState>? _notificationsSub;
  StreamSubscription<TechnicianOrdersState>? _ordersSub;
  StreamSubscription<ProfileState>? _profileSub;
  StreamSubscription<FavoritesState>? _favoritesSub;

  bool _active = false;
  String _role = 'client';

  UnreadCountsCubit({
    required this.notificationCubit,
    required this.technicianOrdersCubit,
    required this.profileCubit,
    required this.favoritesCubit,
  }) : super(const UnreadCountsState());

  @override
  Future<void> close() {
    _notificationsSub?.cancel();
    _ordersSub?.cancel();
    _profileSub?.cancel();
    _favoritesSub?.cancel();
    return super.close();
  }

  /// Binds the badges to the signed-in [role] (`client` | `worker`).
  /// Called once per MainScreen mount (never for guests).
  void start({required String role}) {
    _role = role;
    _active = true;
    _notificationsSub ??= notificationCubit.stream.listen((_) => _recompute());
    _ordersSub ??= technicianOrdersCubit.stream.listen((_) => _recompute());
    _profileSub ??= profileCubit.stream.listen((_) => _recompute());
    _favoritesSub ??= favoritesCubit.stream.listen((_) => _recompute());
    _recompute();
  }

  /// Clears the badges and stops the recompute loop for the current user —
  /// called on logout/user switch so the next account starts from zero.
  void reset() {
    _active = false;
    _role = 'client';
    emit(const UnreadCountsState());
  }

  bool get _isClient => _role == 'client';

  void _recompute() {
    if (!_active) return;

    final notifications = notificationCubit.unreadCount;
    final requests = _isClient ? notifications : _pendingAssignedRequests();
    final favorites = _savedFavoritesCount();

    if (requests == state.requests &&
        notifications == state.notifications &&
        favorites == state.favorites) {
      return;
    }
    emit(UnreadCountsState(
      notifications: notifications,
      requests: requests,
      favorites: favorites,
    ));
  }

  /// Mirrors the worker's incoming-inbox widget: PENDING orders assigned to
  /// the signed-in worker. Rated/cancelled/accepted rows never count.
  int _pendingAssignedRequests() {
    final ordersState = technicianOrdersCubit.state;
    if (ordersState is! TechnicianOrdersSuccess) return 0;
    final profileState = profileCubit.state;
    if (profileState is! ProfileSuccess) return 0;

    final workerId = profileState.profile.id;
    return ordersState.orders
        .where((o) => o.status == OrderStatus.pending && o.workerId == workerId)
        .length;
  }

  /// Total saved favorites — a plain length, never an "unread" notion. Until
  /// the favorites have been fetched there is nothing to show, so any state
  /// without a list counts as 0.
  int _savedFavoritesCount() {
    final favoritesState = favoritesCubit.state;
    if (favoritesState is! FavoritesSuccess) return 0;
    return favoritesState.favorites.length;
  }
}
