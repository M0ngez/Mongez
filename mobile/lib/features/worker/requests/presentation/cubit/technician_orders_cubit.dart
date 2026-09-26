import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';

part 'technician_orders_state.dart';

class TechnicianOrdersCubit extends Cubit<TechnicianOrdersState> {
  final OrderRepository orderRepository;
  static const int _pageSize = 50;

  List<OrderModel>? _cachedOrders;
  Timer? _pollTimer;

  /// Screens mount/unmount in either order (a new screen's initState runs
  /// before the old one's dispose), so only the last owner to leave stops
  /// the shared timer — otherwise a tab switch would kill the poll the
  /// newly opened screen just started (and freeze the nav badge with it).
  int _pollOwners = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _fetching = false;

  TechnicianOrdersCubit({required this.orderRepository})
      : super(TechnicianOrdersInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void reset() {
    // Session ended — drop the timer and any outstanding owner.
    _pollOwners = 0;
    _pollTimer?.cancel();
    _pollTimer = null;
    _cachedOrders = null;
    _currentPage = 1;
    _hasMore = true;
    emit(TechnicianOrdersInitial());
  }

  /// Full refresh (app start / pull-to-refresh).
  Future<void> getOrders() async {
    emit(TechnicianOrdersLoading());
    await _refreshSilently();
  }

  /// Background poll — every 15 s, page 1 (newest 50) only, merged into the
  /// existing list so a new PENDING assignment (or a CANCELLED flip from
  /// the dashboard) lands on the worker's screen without an unbounded
  /// fetch every tick.
  void startPolling() {
    _pollOwners++;
    if (_pollTimer != null) {
      // Another screen already polls — refresh immediately for this one.
      _refreshSilently();
      return;
    }
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSilently(),
    );
    _refreshSilently();
  }

  void stopPolling() {
    if (_pollOwners > 0) _pollOwners--;
    if (_pollOwners > 0) return;
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
        if (_cachedOrders == null) {
          emit(TechnicianOrdersFailure(failure.errorMessage));
        }
      },
      (page) {
        final isFirstPage = requestedPage == 1;
        _hasMore = page.length >= _pageSize;
        _cachedOrders = _mergePage(page, isFirstPage);
        if (_cachedOrders!.isEmpty) {
          emit(TechnicianOrdersEmpty());
        } else {
          emit(TechnicianOrdersSuccess(_cachedOrders!));
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

  Future<void> acceptOrder(int orderId) async {
    final result = await orderRepository.acceptOrder(orderId);
    if (result.isRight()) {
      await _refreshSilently();
    } else {
      _restoreState();
    }
  }

  Future<void> rejectOrder(int orderId) async {
    final result = await orderRepository.rejectOrder(orderId);
    if (result.isRight()) {
      await _refreshSilently();
    } else {
      _restoreState();
    }
  }

  Future<void> markAsFinished(int orderId) async {
    final result = await orderRepository.markAsFinished(orderId);
    if (result.isRight()) {
      await _refreshSilently();
    } else {
      _restoreState();
    }
  }

  void _restoreState() {
    if (_cachedOrders == null) {
      emit(TechnicianOrdersEmpty());
      return;
    }
    if (_cachedOrders!.isEmpty) {
      emit(TechnicianOrdersEmpty());
    } else {
      emit(TechnicianOrdersSuccess(_cachedOrders!));
    }
  }
}
