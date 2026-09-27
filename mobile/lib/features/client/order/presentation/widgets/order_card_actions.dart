import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_status_actions.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/generated/l10n.dart';

class OrderCardActions extends StatefulWidget {
  final OrderModel order;
  final bool isCustomer;

  const OrderCardActions({
    super.key,
    required this.order,
    required this.isCustomer,
  });

  @override
  State<OrderCardActions> createState() => _OrderCardActionsState();
}

class _OrderCardActionsState extends State<OrderCardActions> {
  bool _isAccepting = false;
  bool _isRejecting = false;
  bool _isMarkingFinished = false;
  bool _isCancelling = false;
  bool _isConfirming = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _lateCancelReady = false;

  @override
  void initState() {
    super.initState();
    _startCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(OrderCardActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status) {
      _countdownTimer?.cancel();
      _startCountdownIfNeeded();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    if (!widget.isCustomer ||
        widget.order.status != OrderStatus.accepted ||
        widget.order.acceptedAt == null) {
      return;
    }
    final acceptedAt = DateTime.tryParse(widget.order.acceptedAt!);
    if (acceptedAt == null) return;
    final deadline = acceptedAt.toUtc().add(const Duration(hours: 1));

    void tick() {
      final now = DateTime.now().toUtc();
      final diff = deadline.difference(now);
      if (!mounted) return;
      if (diff.isNegative) {
        _countdownTimer?.cancel();
        setState(() {
          _remaining = Duration.zero;
          _lateCancelReady = true;
        });
      } else {
        setState(() {
          _remaining = diff;
          _lateCancelReady = false;
        });
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    if (widget.isCustomer) {
      if (widget.order.status == OrderStatus.pending) {
        return Row(
          children: [
            Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Text(lang.pending, style: TextStyle(color: Colors.orange, fontSize: 13)),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _isCancelling ? null : () => _showCancelDialog(context),
              child: _spinnerOr(_isCancelling, lang.cancel, color: Colors.white),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.accepted) {
        if (_lateCancelReady) {
          return Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lang.workerLateCancel,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: _isCancelling ? null : () => _showCancelDialog(context),
                child: _spinnerOr(_isCancelling, lang.cancel, color: Colors.white),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.order.workerName ?? lang.serviceProvider} accepted — ${lang.cancelIn(formatCountdown(_remaining))}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.waitingConfirmation) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(lang.workerMarkedFinished, style: TextStyle(color: Colors.purple.shade700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : () => _doConfirmCompletion(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _spinnerOr(_isConfirming, lang.confirmCompletion, color: Colors.white),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.completed) {
        return _statusLine(Icons.check_circle, Colors.green, lang.completed);
      }
      if (widget.order.status == OrderStatus.rejected) {
        return _statusLine(Icons.cancel, Colors.red, lang.rejectedByWorker);
      }
      if (widget.order.status == OrderStatus.cancelled) {
        return _cancelledLine(lang);
      }
    } else {
      if (widget.order.status == OrderStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAccepting ? null : () => _doAccept(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _spinnerOr(_isAccepting, lang.accept, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isRejecting ? null : () => _doReject(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _spinnerOr(_isRejecting, lang.cancel, color: Colors.white),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.accepted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(lang.inProgress, style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMarkingFinished ? null : () => _doMarkFinished(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _spinnerOr(_isMarkingFinished, lang.markAsFinished, color: Colors.white),
              ),
            ),
          ],
        );
      }
      if (widget.order.status == OrderStatus.waitingConfirmation) {
        return _statusLine(Icons.hourglass_top, Colors.purple, lang.waitingConfirmation);
      }
      if (widget.order.status == OrderStatus.completed) {
        return _statusLine(Icons.check_circle, Colors.green, lang.completed);
      }
      if (widget.order.status == OrderStatus.rejected) {
        return _statusLine(Icons.cancel, Colors.red, lang.rejectedByYou);
      }
      if (widget.order.status == OrderStatus.cancelled) {
        return _cancelledLine(lang);
      }
    }

    return const SizedBox();
  }

  Widget _spinnerOr(bool isLoading, String label, {Color color = Colors.white}) {
    if (!isLoading) return Text(label);
    return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
  }

  Widget _statusLine(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }

  /// Red when the cancellation was charged to this worker for being late,
  /// grey when the client backed out before anyone took the job — the same
  /// distinction the badge next to it draws.
  Widget _cancelledLine(S lang) {
    final chargedToWorker =
        widget.order.cancellationReason == kCancellationReasonWorkerDelay;
    if (chargedToWorker) {
      return _statusLine(
        Icons.warning_amber_rounded,
        Colors.red,
        widget.isCustomer ? lang.cancelledWorkerLate : lang.cancelledYouWereLate,
      );
    }
    return _statusLine(
      Icons.cancel,
      Colors.grey,
      widget.isCustomer ? lang.cancelledByYou : lang.cancelledByCustomer,
    );
  }

  Future<void> _doAccept(BuildContext context) async {
    setState(() => _isAccepting = true);
    await context.read<TechnicianOrdersCubit>().acceptOrder(widget.order.id);
  }

  Future<void> _doReject(BuildContext context) async {
    setState(() => _isRejecting = true);
    await context.read<TechnicianOrdersCubit>().rejectOrder(widget.order.id);
  }

  Future<void> _doMarkFinished(BuildContext context) async {
    setState(() => _isMarkingFinished = true);
    await context.read<TechnicianOrdersCubit>().markAsFinished(widget.order.id);
  }

  Future<void> _doConfirmCompletion(BuildContext context) async {
    setState(() => _isConfirming = true);
    await context.read<CustomerOrdersCubit>().confirmCompletion(widget.order.id);
  }

  void _showCancelDialog(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.cancelRequest),
        content: Text(lang.cancelRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isCancelling = true);
              context.read<CustomerOrdersCubit>().cancelOrder(widget.order.id);
            },
            child: Text(lang.yes, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
