import 'package:flutter/material.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/generated/l10n.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCustomer;

  /// See [OrderModel.cancellationReason]; ignored unless [status] is
  /// [OrderStatus.cancelled].
  final String? cancellationReason;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCustomer = true,
    this.cancellationReason,
  });

  bool get _cancelledForWorkerDelay =>
      status == OrderStatus.cancelled &&
      cancellationReason == kCancellationReasonWorkerDelay;

  Color _color() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.waitingConfirmation:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.cancelled:
        // A cancellation charged to the worker is a different event than
        // one the client walked away from — it must not wear the same
        // grey, or there is nothing to hold the worker to account for.
        return _cancelledForWorkerDelay ? Colors.red : Colors.grey;
    }
  }

  String _label(S lang) {
    switch (status) {
      case OrderStatus.pending:
        return lang.pending;
      case OrderStatus.accepted:
        return lang.confirmed;
      case OrderStatus.inProgress:
        return lang.inProgress;
      case OrderStatus.waitingConfirmation:
        return lang.waitingConfirmation;
      case OrderStatus.completed:
        return lang.completed;
      case OrderStatus.rejected:
        return isCustomer ? lang.rejectedByWorker : lang.rejected;
      case OrderStatus.cancelled:
        if (_cancelledForWorkerDelay) return lang.cancelledWorkerLate;
        return isCustomer ? lang.cancelledByYou : lang.cancelledByCustomer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(lang),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
