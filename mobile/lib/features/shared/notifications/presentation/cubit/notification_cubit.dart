import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/shared/notifications/data/models/notification_model.dart';
import 'package:mongez/features/shared/notifications/domain/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  static const int _pageSize = 30;

  List<NotificationModel>? _cached;
  Timer? _pollTimer;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _fetching = false;

  NotificationCubit({required this.notificationRepository})
      : super(NotificationInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() {
    stopPolling();
    _cached = null;
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    emit(NotificationInitial());
  }

  /// Polls only the cheap unread-count endpoint so the bell badge stays
  /// live. The full list is fetched on demand when the notifications
  /// screen is opened.
  void startPolling() {
    if (GuestSession.isGuest) return;
    _pollTimer?.cancel();
    // 5 s — dashboard moderation actions push notifications, and the
    // badge must reflect them almost instantly. A COUNT query is a few
    // bytes, unlike the old full-list fetch every tick.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchCount());
    _fetchCount();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchCount() async {
    if (GuestSession.isGuest) return;
    final result = await notificationRepository.getUnreadCount();
    result.fold((_) {}, (count) {
      if (count == _unreadCount) return;
      _unreadCount = count;
      if (_cached != null) {
        emit(NotificationSuccess(_cached!, _unreadCount));
      } else {
        emit(NotificationCountChanged(_unreadCount));
      }
    });
  }

  int get unreadCount => _unreadCount;

  /// Applies a live FCM foreground message instantly (no waiting for the
  /// poll): bump the badge, prepend the item to the cached list, and emit
  /// so the UI updates immediately.
  void applyIncomingNotification(NotificationModel notif) {
    _unreadCount++;
    if (_cached != null) {
      _cached = [notif, ..._cached!.where((n) => n.id != notif.id)];
      emit(NotificationSuccess(_cached!, _unreadCount));
    } else {
      emit(NotificationCountChanged(_unreadCount));
    }
  }

  /// Full list reload — first page. Called when the screen opens.
  Future<void> refresh() async {
    if (GuestSession.isGuest) return;
    _currentPage = 1;
    _hasMore = true;
    emit(NotificationLoading());
    await _loadPage();
  }

  void loadMore() {
    if (!_hasMore || _fetching || _cached == null) return;
    _currentPage++;
    _loadPage();
  }

  Future<void> _loadPage() async {
    if (_fetching) return;
    _fetching = true;
    final requestedPage = _currentPage;
    final result = await notificationRepository.getNotifications(
      page: requestedPage,
      pageSize: _pageSize,
    );
    _fetching = false;
    result.fold(
      (failure) {
        if (_cached != null) {
          emit(NotificationSuccess(_cached!, _unreadCount));
        }
      },
      (page) {
        final isFirstPage = requestedPage == 1;
        _hasMore = page.length >= _pageSize;
        _cached = _mergePage(page, isFirstPage);
        emit(NotificationSuccess(_cached!, _unreadCount));
      },
    );
  }

  /// Page 1 refreshes prepend new items on top; later pages append at the
  /// bottom. Items already held are kept (dedup by id). Pre-push placeholders
  /// (negative ids) are dropped on a first-page refresh — the server snapshot
  /// now carries the authoritative row with a real id.
  List<NotificationModel> _mergePage(List<NotificationModel> page, bool isFirstPage) {
    final existing = _cached ?? const <NotificationModel>[];
    final seen = <int>{};
    final merged = <NotificationModel>[];
    if (isFirstPage) {
      for (final n in page) {
        if (seen.add(n.id)) merged.add(n);
      }
      for (final n in existing) {
        if (n.id < 0) continue;
        if (seen.add(n.id)) merged.add(n);
      }
    } else {
      for (final n in existing) {
        if (seen.add(n.id)) merged.add(n);
      }
      for (final n in page) {
        if (seen.add(n.id)) merged.add(n);
      }
    }
    return merged;
  }

  Future<void> markAsRead(int id) async {
    final result = await notificationRepository.markAsRead(id);
    result.fold(
      (_) {},
      (_) {
        if (_cached != null) {
          final target = _cached!.firstWhere((n) => n.id == id);
          if (!target.isRead && _unreadCount > 0) _unreadCount--;
          _cached = _cached!.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
          emit(NotificationSuccess(_cached!, _unreadCount));
        }
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await notificationRepository.markAllAsRead();
    result.fold(
      (_) {},
      (_) {
        if (_cached != null) {
          _unreadCount = 0;
          _cached = _cached!.map((n) => n.copyWith(isRead: true)).toList();
          emit(NotificationSuccess(_cached!, _unreadCount));
        }
      },
    );
  }
}
