import 'package:flutter/material.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/generated/l10n.dart';

String formatCountdown(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '$h:$m:$s';
  return '$m:$s';
}

/// Renders the role- and status-aware action area for an order.
///
/// Side effects (dialogs, cubit calls, navigation) are delegated to callbacks
/// so the widget stays presentation-only and testable.
class OrderStatusActions extends StatelessWidget {
  final OrderModel order;
  final bool isCustomer;
  final Duration remaining;
  final bool lateCancelReady;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMarkFinished;

  const OrderStatusActions({
    super.key,
    required this.order,
    required this.isCustomer,
    required this.remaining,
    required this.lateCancelReady,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    if (isCustomer) {
      if (order.status == OrderStatus.pending) {
        return _dangerButton(context, lang.cancel, onCancel);
      }
      if (order.status == OrderStatus.accepted) {
        if (lateCancelReady) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _banner(
                color: Colors.red,
                icon: Icons.warning_amber_rounded,
                text: lang.workerLateCancel,
              ),
              const SizedBox(height: 12),
              _dangerButton(context, lang.cancel, onCancel),
            ],
          );
        }
        return _banner(
          color: Colors.green,
          icon: Icons.check_circle,
          text:
              '${order.workerName ?? lang.serviceProvider} accepted — ${lang.cancelIn(formatCountdown(remaining))}',
        );
      }
      if (order.status == OrderStatus.waitingConfirmation) {
        return _banner(
          color: Colors.purple,
          icon: Icons.check_circle,
          text: lang.workerMarkedFinished,
        );
      }
      if (order.status == OrderStatus.completed) {
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              lang.completed,
              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
            ),
          ],
        );
      }
      if (order.status == OrderStatus.rejected) {
        return _banner(
          color: Colors.red,
          icon: Icons.cancel,
          text: lang.rejectedByWorker,
        );
      }
      if (order.status == OrderStatus.cancelled) {
        return _cancelledBanner(lang);
      }
    } else {
      if (order.status == OrderStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.accept),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.cancel),
              ),
            ),
          ],
        );
      }
      if (order.status == OrderStatus.accepted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _banner(
              color: Colors.blue,
              icon: Icons.build,
              text: lang.serviceInProgress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMarkFinished,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(lang.markAsFinished),
              ),
            ),
          ],
        );
      }
      if (order.status == OrderStatus.waitingConfirmation) {
        return _banner(
          color: Colors.purple,
          icon: Icons.hourglass_top,
          text: lang.waitingConfirmation,
        );
      }
      if (order.status == OrderStatus.cancelled) {
        return _cancelledBanner(lang);
      }
      if (order.status == OrderStatus.rejected) {
        return _banner(
          color: Colors.red,
          icon: Icons.cancel,
          text: lang.rejectedByYou,
        );
      }
      if (order.status == OrderStatus.completed) {
        return _banner(
          color: Colors.green,
          icon: Icons.check_circle,
          text: lang.completed,
        );
      }
    }

    return const SizedBox();
  }

  /// A cancelled order reads differently depending on *why* it was
  /// cancelled: grey when the client backed out before anyone took the
  /// job, red when the cancellation was charged to this worker for being
  /// late. The role decides who the red text is addressed to.
  Widget _cancelledBanner(S lang) {
    final chargedToWorker =
        order.cancellationReason == kCancellationReasonWorkerDelay;
    if (chargedToWorker) {
      return _banner(
        color: Colors.red,
        icon: Icons.warning_amber_rounded,
        text: isCustomer ? lang.cancelledWorkerLate : lang.cancelledYouWereLate,
      );
    }
    return _banner(
      color: Colors.grey,
      icon: Icons.cancel,
      text: isCustomer ? lang.cancelledByYou : lang.cancelledByCustomer,
    );
  }

  Widget _banner({
    required MaterialColor color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerButton(BuildContext context, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
