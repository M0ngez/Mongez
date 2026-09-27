import 'package:equatable/equatable.dart';
import 'package:mongez/core/constants/api_constants.dart';
import 'package:mongez/features/client/order/data/models/order_attachment_model.dart';

String? _absoluteMediaUrl(String? raw) {
  if (raw == null || raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = ApiConstants.baseUrl;
  final hostEnd = base.endsWith('/api/') ? base.length - 'api/'.length : base.length;
  final host = base.substring(0, hostEnd).replaceAll(RegExp(r'/+$'), '');
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '$host$path';
}

/// Mirrors `Order.WORKER_DELAY` in `Order.CANCELLATION_REASON_CHOICES` on
/// the backend. The backend derives the value from timing rather than from
/// anything the client says: a cancel that only unlocked once the
/// one-hour post-accept window elapsed means the technician accepted and
/// never showed up on time.
const kCancellationReasonWorkerDelay = 'WORKER_DELAY';

enum OrderUrgency {  low, normal, high;

  String get apiValue {
    switch (this) {
      case OrderUrgency.low: return 'LOW';
      case OrderUrgency.normal: return 'NORMAL';
      case OrderUrgency.high: return 'HIGH';
    }
  }

  static OrderUrgency fromApi(String? value) {
    switch ((value ?? 'NORMAL').toUpperCase()) {
      case 'LOW': return OrderUrgency.low;
      case 'HIGH': return OrderUrgency.high;
      default: return OrderUrgency.normal;
    }
  }
}

enum OrderStatus {
  pending,
  accepted,
  inProgress,
  waitingConfirmation,
  rejected,
  cancelled,
  completed;

  String get apiValue => name;
  static OrderStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING': return OrderStatus.pending;
      case 'ACCEPTED': return OrderStatus.accepted;
      case 'IN_PROGRESS': return OrderStatus.inProgress;
      case 'WAITING_CONFIRMATION': return OrderStatus.waitingConfirmation;
      case 'REJECTED': return OrderStatus.rejected;
      case 'CANCELLED': return OrderStatus.cancelled;
      case 'COMPLETED': return OrderStatus.completed;
      default: return OrderStatus.pending;
    }
  }
}

class OrderModel extends Equatable {
  final int id;
  final int? clientId;
  final String? clientName;
  final String? clientPhone;
  final String? clientImage;
  final int? workerId;
  final String? workerName;
  final String? workerPhone;
  final String? workerImage;
  final int? categoryId;
  final String? categoryName;
  final String? categoryImage;
  final String description;
  final String address;
  final String phone;
  final OrderStatus status;
  final OrderUrgency urgency;
  final double? latitude;
  final double? longitude;
  final String? scheduledFor;

  /// Why the order was cancelled, from `Order.CANCELLATION_REASON_CHOICES`:
  /// `WORKER_DELAY` when the cancel only became possible once the one-hour
  /// post-accept window elapsed (the technician accepted and never showed
  /// up on time), `OTHER` when the order was cancelled before anyone was
  /// assigned. Null for orders that aren't cancelled.
  final String? cancellationReason;

  final List<OrderAttachmentModel> attachments;
  final bool isRated;
  final String? createdAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final String? rejectedAt;
  final String? cancelledAt;

  const OrderModel({
    required this.id,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.clientImage,
    this.workerId,
    this.workerName,
    this.workerPhone,
    this.workerImage,
    this.categoryId,
    this.categoryName,
    this.categoryImage,
    this.description = '',
    this.address = '',
    this.phone = '',
    this.status = OrderStatus.pending,
    this.urgency = OrderUrgency.normal,
    this.latitude,
    this.longitude,
    this.scheduledFor,
    this.cancellationReason,
    this.attachments = const [],
    this.isRated = false,
    this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.rejectedAt,
    this.cancelledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final worker = json['worker'] as Map<String, dynamic>?;
    final category = json['service_category'] as Map<String, dynamic>?;
    final attachments = (json['attachments'] as List<dynamic>?)
            ?.map((e) => OrderAttachmentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return OrderModel(
      id: json['id'] as int,
      clientId: client?['id'] as int?,
      clientName: (client?['display_name'] ?? client?['name_ar'] ?? client?['username']) as String?,
      clientPhone: client?['phone'] as String?,
      clientImage: _absoluteMediaUrl(
        (client?['avatar_url'] ?? client?['profile_image']) as String?,
      ),
      workerId: worker?['id'] as int?,
      workerName: (worker?['display_name'] ?? worker?['name_ar'] ?? worker?['username']) as String?,
      workerPhone: worker?['phone'] as String?,
      workerImage: _absoluteMediaUrl(
        (worker?['avatar_url'] ?? worker?['profile_image']) as String?,
      ),
      categoryId: category?['id'] as int?,
      categoryName: category?['name'] as String?,
      categoryImage: (category?['icon'] ?? category?['image']) as String?,
      description: json['description'] as String? ?? '',
      // Backend now sends `address_text`; keep `address` as a fallback for
      // older clients/cached payloads.
      address: (json['address_text'] ?? json['address'] ?? '') as String,
      phone: json['phone'] as String? ?? '',
      status: OrderStatus.fromApi(json['status'] as String? ?? 'PENDING'),
      urgency: OrderUrgency.fromApi(json['urgency'] as String?),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      scheduledFor: json['scheduled_for'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      attachments: attachments,
      isRated: json['is_rated'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      rejectedAt: json['rejected_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
    );
  }

  OrderModel copyWith({
    bool? isRated,
    OrderStatus? status,
    String? cancellationReason,
    List<OrderAttachmentModel>? attachments,
  }) {
    return OrderModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientImage: clientImage,
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      workerImage: workerImage,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryImage: categoryImage,
      description: description,
      address: address,
      phone: phone,
      status: status ?? this.status,
      urgency: urgency,
      latitude: latitude,
      longitude: longitude,
      scheduledFor: scheduledFor,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      attachments: attachments ?? this.attachments,
      isRated: isRated ?? this.isRated,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      rejectedAt: rejectedAt,
      cancelledAt: cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
    id, clientId, workerId, categoryId, description,
    address, phone, status, urgency, latitude, longitude,
    cancellationReason,
    attachments, isRated, createdAt,
  ];
}
