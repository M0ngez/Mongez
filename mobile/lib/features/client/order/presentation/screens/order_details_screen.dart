import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/client/order/presentation/screens/rate_order_screen.dart';
import 'package:mongez/features/client/order/presentation/widgets/attachments_header.dart';
import 'package:mongez/features/client/order/presentation/widgets/audio_tile.dart';
import 'package:mongez/features/client/order/presentation/widgets/contact_card.dart';
import 'package:mongez/features/client/order/presentation/widgets/meta_pill.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_status_actions.dart';
import 'package:mongez/features/client/order/presentation/widgets/photo_gallery.dart';
import 'package:mongez/features/client/order/presentation/widgets/status_badge.dart';
import 'package:mongez/features/client/order/presentation/widgets/urgency_pill.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/generated/l10n.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final bool isCustomer;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.isCustomer,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _order;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _lateCancelReady = false;

  // Values accepted by the backend's Order.CANCELLATION_REASON_CHOICES.
  static const _reasonWorkerDelay = 'WORKER_DELAY';
  static const _reasonOther = 'OTHER';

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _startCountdownIfNeeded();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfNeeded() {
    if (!widget.isCustomer ||
        _order.status != OrderStatus.accepted ||
        _order.acceptedAt == null) {
      return;
    }
    final acceptedAt = DateTime.tryParse(_order.acceptedAt!);
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final photos = _order.attachments.where((a) => a.isImage).toList();
    final audios = _order.attachments.where((a) => a.isAudio).toList();

    return Scaffold(
      appBar: CustomAppBar(title: lang.requestDetails),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Main info card ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order.categoryName ?? 'Order #${_order.id}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '#${_order.id}',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: _order.status, isCustomer: widget.isCustomer),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      UrgencyPill(urgency: _order.urgency),
                      if (_order.scheduledFor != null)
                        MetaPill(
                          icon: Icons.schedule_outlined,
                          label: lang.scheduledDate(_formatDate(_order.scheduledFor)),
                          color: cs.primary,
                        ),
                    ],
                  ),
                  if (_order.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _order.description,
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _infoRow(Icons.calendar_today_outlined, _formatDate(_order.createdAt)),
                  if (_order.acceptedAt != null)
                    _infoRow(Icons.check_circle_outline,
                        lang.acceptedDate(_formatDate(_order.acceptedAt))),
                  if (_order.completedAt != null)
                    _infoRow(Icons.task_alt,
                        lang.completedDate(_formatDate(_order.completedAt))),
                  const SizedBox(height: 16),
                  ContactCard(
                    order: _order,
                    isCustomer: widget.isCustomer,
                    onCopy: (label, value) => _copyToClipboard(context, label, value),
                  ),
                  const SizedBox(height: 16),
                  OrderStatusActions(
                    order: _order,
                    isCustomer: widget.isCustomer,
                    remaining: _remaining,
                    lateCancelReady: _lateCancelReady,
                    onCancel: () => _showCancelDialog(context),
                    onAccept: () {
                      context.read<TechnicianOrdersCubit>().acceptOrder(_order.id);
                      Navigator.pop(context);
                    },
                    onReject: () {
                      context.read<TechnicianOrdersCubit>().rejectOrder(_order.id);
                      Navigator.pop(context);
                    },
                    onMarkFinished: () {
                      context.read<TechnicianOrdersCubit>().markAsFinished(_order.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // ─── Attachments: photos ───────────────────────────────────
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              AttachmentsHeader(
                icon: Icons.photo_library_outlined,
                title: lang.photosCount(photos.length),
              ),
              const SizedBox(height: 10),
              PhotoGallery(photos: photos),
            ],

            // ─── Attachments: voice notes ──────────────────────────────
            if (audios.isNotEmpty) ...[
              const SizedBox(height: 16),
              AttachmentsHeader(
                icon: Icons.mic_none_outlined,
                title: lang.voiceNotesCount(audios.length),
              ),
              const SizedBox(height: 10),
              ...audios.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AudioTile(attachment: a),
                  )),
            ],
            if (widget.isCustomer && _order.status == OrderStatus.waitingConfirmation) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            S.of(context).workerMarkedFinished,
                            style: TextStyle(color: Colors.purple.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _doConfirmCompletion(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(S.of(context).confirmCompletion),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.isCustomer && _order.status == OrderStatus.completed) ...[
              const SizedBox(height: 16),
              if (_order.isRated)
                _buildRatedBanner(context)
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToRateOrder(context),
                    icon: const Icon(Icons.star_half),
                    label: Text(S.of(context).rateOrder),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).copiedToClipboard(label)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final lang = S.of(context);
    final theme = Theme.of(context);

    // Only an accepted order already has a worker on the way, so the
    // worker-delay question is meaningless while the request is pending.
    String? reason;
    if (_order.status == OrderStatus.accepted) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(lang.cancelRequest),
          content: Text(lang.workerDelayQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, _reasonOther),
              child: Text(lang.otherReason),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _reasonWorkerDelay),
              child: Text(lang.workerWasLate),
            ),
          ],
        ),
      );
      // Dismissed (barrier tap / back) — don't fall through to the
      // confirmation dialog.
      if (choice == null) return;
      reason = choice;
    }

    if (!context.mounted) return;

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
              context
                  .read<CustomerOrdersCubit>()
                  .cancelOrder(_order.id, reason: reason);
              Navigator.pop(context);
            },
            child: Text(lang.yes, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).ratingSubmitted,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doConfirmCompletion(BuildContext context) async {
    await context.read<CustomerOrdersCubit>().confirmCompletion(_order.id);
    if (mounted) {
      setState(() => _order = _order.copyWith(status: OrderStatus.completed));
    }
  }

  Future<void> _navigateToRateOrder(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateOrderScreen(order: _order),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      setState(() => _order = _order.copyWith(isRated: true));
      context.read<CustomerOrdersCubit>().getOrders();
    }
  }
}
