import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';

part 'customer_orders_state.dart';

class CustomerOrdersCubit extends Cubit<CustomerOrdersState> {
  final OrderRepository orderRepository;
  static const int _pageSize = 50;

  List<OrderModel>? _cachedOrders;
  Timer? _pollTimer;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _fetching = false;

  CustomerOrdersCubit({required this.orderRepository})
      : super(CustomerOrdersInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() {
    stopPolling();
    _cachedOrders = null;
    _currentPage = 1;
    _hasMore = true;
    emit(CustomerOrdersInitial());
  }

  /// Full refresh (app start / pull-to-refresh).
  Future<void> getOrders() async {
    if (GuestSession.isGuest) return;
    emit(CustomerOrdersLoading());
    await _refreshSilently();
  }

  /// Background poll — every 15 s, page 1 (newest 50) only, merged into the
  /// existing list so already-loaded pages survive. Cheaper than the old
  /// unbounded 5 s fetch.
  void startPolling() {
    if (GuestSession.isGuest) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSilently(),
    );
    _refreshSilently();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshSilently() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadPage();
  }

  void loadMore() {
    if (!_hasMore || _fetching || _cachedOrders == null) return;
    _currentPage++;
    _loadPage();
  }

  Future<void> _loadPage() async {
    if (_fetching) return;
    _fetching = true;
    final requestedPage = _currentPage;
    final result = await orderRepository.getOrders(
      page: requestedPage,
      pageSize: _pageSize,
    );
    _fetching = false;
    result.fold(
      (failure) {
        // Poll failure — keep showing the cached list if we have one so
        // the UI doesn't flash an error every time the network blips.
        if (_cachedOrders == null) {
          emit(CustomerOrdersFailure(failure.errorMessage));
        }
      },
      (page) {
        final isFirstPage = requestedPage == 1;
        _hasMore = page.length >= _pageSize;
        _cachedOrders = _mergePage(page, isFirstPage);
        if (_cachedOrders!.isEmpty) {
          emit(CustomerOrdersEmpty());
        } else {
          emit(CustomerOrdersSuccess(_cachedOrders!));
        }
      },
    );
  }

  /// Page 1 refreshes prepend new items on top; later pages append at the
  /// bottom. Items already held are kept (dedup by id) so scrolled pages
  /// survive a poll.
  List<OrderModel> _mergePage(List<OrderModel> page, bool isFirstPage) {
    final existing = _cachedOrders ?? const <OrderModel>[];
    final seen = <int>{};
    final merged = <OrderModel>[];
    if (isFirstPage) {
      for (final o in page) {
        if (seen.add(o.id)) merged.add(o);
      }
      for (final o in existing) {
        if (seen.add(o.id)) merged.add(o);
      }
    } else {
      for (final o in existing) {
        if (seen.add(o.id)) merged.add(o);
      }
      for (final o in page) {
        if (seen.add(o.id)) merged.add(o);
      }
    }
    return merged;
  }

  Future<void> confirmCompletion(int orderId) async {
    final result = await orderRepository.confirmCompletion(orderId);
    if (result.isRight()) {
      await _refreshSilently();
    } else {
      _restoreState();
    }
  }

  Future<void> cancelOrder(int orderId) async {
    final result = await orderRepository.cancelOrder(orderId);
    if (result.isRight()) {
      await _refreshSilently();
    } else {
      _restoreState();
    }
  }

  void _restoreState() {
    if (_cachedOrders == null) {
      emit(CustomerOrdersEmpty());
      return;
    }
    if (_cachedOrders!.isEmpty) {
      emit(CustomerOrdersEmpty());
    } else {
      emit(CustomerOrdersSuccess(_cachedOrders!));
    }
  }
}
