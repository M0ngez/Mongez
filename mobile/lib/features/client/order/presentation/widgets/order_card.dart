import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/client/order/presentation/screens/rate_order_screen.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_card_actions.dart';
import 'package:mongez/features/client/order/presentation/widgets/status_badge.dart';
import 'package:mongez/generated/l10n.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isCustomer;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.isCustomer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.categoryName ?? 'Order #${order.id}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(
                  status: order.status,
                  isCustomer: isCustomer,
                  cancellationReason: order.cancellationReason,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(order.description, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCustomer
                        ? '${lang.serviceProvider}: ${order.workerName ?? ""}'
                        : '${lang.customer}: ${order.clientName ?? ""}',
                    style: textTheme.bodySmall,
                  ),
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            OrderCardActions(order: order, isCustomer: isCustomer),
            if (isCustomer && order.status == OrderStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: order.isRated
                    ? _buildRatedBanner(context)
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToRateOrder(context),
                          icon: const Icon(Icons.star_half, size: 18),
                          label: Text(S.of(context).rateOrder),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).ratingSubmitted,
              style: TextStyle(color: Colors.green.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRateOrder(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateOrderScreen(order: order),
      ),
    );
    if (!context.mounted) return;
    if (result == true) {
      context.read<CustomerOrdersCubit>().getOrders();
    }
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
}
