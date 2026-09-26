import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongez/core/error/failure.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/utils/picked_attachment.dart';
import 'package:mongez/core/widgets/unread_badge.dart';
import 'package:mongez/features/client/favorites/data/models/favorite_model.dart';
import 'package:mongez/features/client/favorites/domain/favorites_repository.dart';
import 'package:mongez/features/client/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';
import 'package:mongez/features/shared/notifications/data/models/notification_model.dart';
import 'package:mongez/features/shared/notifications/domain/notification_repository.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/profile/data/models/profile_model.dart';
import 'package:mongez/features/shared/profile/domain/profile_repository.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/shared/unread/presentation/cubit/unread_counts_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';

void main() {
  setUp(GuestSession.exit);

  group('favorites badge — total saved favorites', () {
    test('1 favorite → 1', () async {
      final app = await _signIn(favorites: _favorites(1));

      expect(app.badges.state.favorites, 1);
      expect(UnreadBadge.format(app.badges.state.favorites), '1');
    });

    test('multiple favorites → correct count', () async {
      final app = await _signIn(favorites: _favorites(4));

      expect(app.badges.state.favorites, 4);
      expect(UnreadBadge.format(app.badges.state.favorites), '4');
    });

    test('100+ favorites → 99+', () async {
      final app = await _signIn(favorites: _favorites(100));

      expect(app.badges.state.favorites, 100);
      expect(UnreadBadge.format(app.badges.state.favorites), '99+');
    });

    test('adding a favorite updates the badge', () async {
      final app = await _signIn(favorites: _favorites(2));
      expect(app.badges.state.favorites, 2);

      await app.favoritesCubit.toggleFavorite(99);
      await pumpEventQueue();

      expect(app.favoritesRepo.favorites.length, 3);
      expect(app.badges.state.favorites, 3);
    });

    test('removing a favorite updates the badge', () async {
      final app = await _signIn(favorites: _favorites(3));
      expect(app.badges.state.favorites, 3);

      // workerId of the first saved favorite.
      await app.favoritesCubit.toggleFavorite(1);
      await pumpEventQueue();

      expect(app.favoritesRepo.favorites.length, 2);
      expect(app.badges.state.favorites, 2);
    });

    test('logout resets the count to 0', () async {
      final app = await _signIn(favorites: _favorites(5));
      expect(app.badges.state.favorites, 5);

      app.badges.reset();

      expect(app.badges.state.favorites, 0);
      expect(app.badges.state.notifications, 0);
      expect(app.badges.state.requests, 0);
    });

    test('the next user gets their own favorites count', () async {
      final app = await _signIn(favorites: _favorites(5));
      expect(app.badges.state.favorites, 5);

      // Logout wipes the badges, then the new account's favorites load
      // before MainScreen binds the badges again (reset → fetch → start).
      app.badges.reset();
      expect(app.badges.state.favorites, 0);

      app.favoritesRepo.favorites = _favorites(2);
      await app.favoritesCubit.getFavorites();
      app.badges.start(role: 'client');

      expect(app.badges.state.favorites, 2);
    });

    test('a favorites state without a list counts as 0', () async {
      final app = await _signIn(favorites: _favorites(3));
      expect(app.badges.state.favorites, 3);

      // FavoritesCubit.reset() puts the cubit back to Initial (no list) —
      // the badge must not keep a stale number.
      app.favoritesCubit.reset();
      await pumpEventQueue();

      expect(app.badges.state.favorites, 0);
    });

    testWidgets('renders the favorites count on the badge', (tester) async {
      final app = await _favoritesOnly(favorites: _favorites(3));

      await tester.pumpWidget(_badgeHost(app.badges.state.favorites));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders no badge when there are no favorites', (tester) async {
      final app = await _favoritesOnly();

      await tester.pumpWidget(_badgeHost(app.badges.state.favorites));

      expect(app.badges.state.favorites, 0);
      expect(find.text('0'), findsNothing);
    });
  });

  group('existing badges are untouched', () {
    test('notifications badge keeps following the unread count', () async {
      final app = await _signIn(unreadNotifications: 2);
      expect(app.badges.state.notifications, 2);

      // Server side changes → the existing 5 s poll picks it up.
      app.notificationRepo.unread = 5;
      app.notificationCubit.startPolling();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      app.notificationCubit.stopPolling();

      expect(app.badges.state.notifications, 5);
      expect(app.badges.state.favorites, 0);
    });

    test('client requests badge mirrors the unread notifications', () async {
      final app = await _signIn(
        unreadNotifications: 3,
        favorites: _favorites(7),
        orders: [
          const OrderModel(id: 1, workerId: 5, status: OrderStatus.pending),
        ],
      );

      expect(app.badges.state.requests, 3);
      expect(app.badges.state.notifications, 3);
      expect(app.badges.state.favorites, 7);
    });

    test('worker requests badge counts only own pending orders', () async {
      final app = await _signIn(
        role: 'worker',
        profileId: 5,
        favorites: _favorites(4),
        orders: [
          const OrderModel(id: 1, workerId: 5, status: OrderStatus.pending),
          const OrderModel(id: 2, workerId: 5, status: OrderStatus.pending),
          const OrderModel(id: 3, workerId: 9, status: OrderStatus.pending),
          const OrderModel(id: 4, workerId: 5, status: OrderStatus.accepted),
        ],
      );

      expect(app.badges.state.requests, 2);
      expect(app.badges.state.notifications, 0);
      expect(app.badges.state.favorites, 4);
    });
  });
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

List<FavoriteModel> _favorites(int count) => List.generate(
      count,
      (i) => FavoriteModel(id: i + 1, workerId: i + 1),
    );

Widget _badgeHost(int count) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(body: Center(child: UnreadBadge(count: count))),
    ),
  );
}

/// Full entry flow: favorites + profile + orders fetched and the notification
/// unread count polled, exactly like NavigationService does on sign-in.
Future<_App> _signIn({
  List<FavoriteModel> favorites = const [],
  int unreadNotifications = 0,
  List<OrderModel> orders = const [],
  int profileId = 5,
  String role = 'client',
}) async {
  final app = await _boot(favorites: favorites, orders: orders, profileId: profileId);

  app.notificationRepo.unread = unreadNotifications;
  app.notificationCubit.startPolling();
  await Future<void>.delayed(const Duration(milliseconds: 30));
  app.notificationCubit.stopPolling();

  return _start(app, role: role);
}

/// Widget-test friendly variant: no polling timer, everything resolves
/// through microtasks (the unread count stays at its initial 0).
Future<_App> _favoritesOnly({
  List<FavoriteModel> favorites = const [],
}) async {
  final app = await _boot(favorites: favorites);
  return _start(app, role: 'client');
}

Future<_App> _boot({
  List<FavoriteModel> favorites = const [],
  List<OrderModel> orders = const [],
  int profileId = 5,
}) async {
  final favoritesRepo = _FakeFavoritesRepository(favorites);
  final favoritesCubit = FavoritesCubit(favoritesRepository: favoritesRepo);
  final notificationRepo = _FakeNotificationRepository();
  final notificationCubit =
      NotificationCubit(notificationRepository: notificationRepo);
  final ordersCubit =
      TechnicianOrdersCubit(orderRepository: _FakeOrderRepository(orders));
  final profileCubit =
      ProfileCubit(profileRepository: _FakeProfileRepository(profileId));

  // Mirrors NavigationService._fetchFreshData on entering the app.
  await favoritesCubit.getFavorites();
  await profileCubit.getProfile();
  await ordersCubit.getOrders();

  return _App(
    favoritesCubit: favoritesCubit,
    favoritesRepo: favoritesRepo,
    notificationCubit: notificationCubit,
    notificationRepo: notificationRepo,
    ordersCubit: ordersCubit,
    profileCubit: profileCubit,
    badges: UnreadCountsCubit(
      notificationCubit: notificationCubit,
      technicianOrdersCubit: ordersCubit,
      profileCubit: profileCubit,
      favoritesCubit: favoritesCubit,
    ),
  );
}

_App _start(_App app, {required String role}) {
  app.badges.start(role: role);
  return app;
}

class _App {
  const _App({
    required this.badges,
    required this.favoritesCubit,
    required this.favoritesRepo,
    required this.notificationCubit,
    required this.notificationRepo,
    required this.ordersCubit,
    required this.profileCubit,
  });

  final UnreadCountsCubit badges;
  final FavoritesCubit favoritesCubit;
  final _FakeFavoritesRepository favoritesRepo;
  final NotificationCubit notificationCubit;
  final _FakeNotificationRepository notificationRepo;
  final TechnicianOrdersCubit ordersCubit;
  final ProfileCubit profileCubit;
}

// ---------------------------------------------------------------------------
// Fake repositories — the production code stays the source of truth, only the
// transport layer is replaced.
// ---------------------------------------------------------------------------

class _FakeFavoritesRepository implements FavoritesRepository {
  _FakeFavoritesRepository(List<FavoriteModel> favorites)
      : favorites = List.of(favorites);

  List<FavoriteModel> favorites;

  @override
  Future<Either<Failure, List<FavoriteModel>>> getFavorites() async =>
      right(favorites);

  @override
  Future<Either<Failure, FavoriteModel>> addFavorite(int workerId) async {
    final favorite = FavoriteModel(
      id: 1000 + favorites.length,
      workerId: workerId,
    );
    favorites = [...favorites, favorite];
    return right(favorite);
  }

  @override
  Future<Either<Failure, void>> removeFavorite(int id) async {
    favorites = favorites.where((f) => f.id != id).toList();
    return right(null);
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  int unread = 0;

  @override
  Future<Either<Failure, int>> getUnreadCount() async => right(unread);

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    int page = 1,
    int? pageSize,
  }) async =>
      right(<NotificationModel>[]);

  @override
  Future<Either<Failure, void>> markAsRead(int id) async => right(null);

  @override
  Future<Either<Failure, void>> markAllAsRead() async => right(null);
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this.orders);

  final List<OrderModel> orders;

  @override
  Future<Either<Failure, List<OrderModel>>> getOrders({
    int page = 1,
    int? pageSize,
  }) async =>
      right(orders);

  @override
  Future<Either<Failure, OrderModel>> getOrderById(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderModel>> createOrder({
    required int serviceCategory,
    required int workerId,
    required String description,
    String? address,
    int? addressId,
    String? phone,
    String? urgency,
    double? latitude,
    double? longitude,
    List<PickedAttachment> photos = const [],
    String? audioPath,
    int? audioDurationSeconds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderModel>> acceptOrder(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderModel>> rejectOrder(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> cancelOrder(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderModel>> markAsFinished(int id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, OrderModel>> confirmCompletion(int id) async =>
      throw UnimplementedError();
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profileId);

  final int profileId;

  @override
  Future<Either<Failure, ProfileModel>> getProfile() async =>
      right(ProfileModel(id: profileId, username: 'user', phone: ''));

  @override
  Future<Either<Failure, ProfileModel>> updateProfile({
    String? username,
    String? nameAr,
    String? email,
    String? phone,
    String? governorate,
    String? city,
    String? address,
    Uint8List? profileImageBytes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> updateWorkerProfile({
    int? categoryId,
    int? experienceYears,
    bool? isAvailable,
  }) async =>
      throw UnimplementedError();
}
