import 'package:dartz/dartz.dart';
import 'package:mongez/core/error/failure.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/core/utils/picked_attachment.dart';

abstract class OrderRepository {
  /// Fetch orders (newest first). When [page] and [pageSize] are given the
  /// request is bounded; omitting both returns the full list.
  Future<Either<Failure, List<OrderModel>>> getOrders({
    int page = 1,
    int? pageSize,
  });
  Future<Either<Failure, OrderModel>> getOrderById(int id);
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
    List<PickedAttachment> photos,
    String? audioPath,
    int? audioDurationSeconds,
  });
  Future<Either<Failure, OrderModel>> acceptOrder(int id);
  Future<Either<Failure, OrderModel>> rejectOrder(int id);
  /// Optional legacy hint, still validated by the backend but no longer
  /// authoritative: the backend derives `cancellation_reason` from *when*
  /// the cancel was possible (before any accept → OTHER, after the
  /// one-hour window → WORKER_DELAY) so accountability never depends on
  /// the caller stating it. Prefer omitting it.
  Future<Either<Failure, void>> cancelOrder(int id, {String? reason});
  Future<Either<Failure, OrderModel>> markAsFinished(int id);
  Future<Either<Failure, OrderModel>> confirmCompletion(int id);
}
