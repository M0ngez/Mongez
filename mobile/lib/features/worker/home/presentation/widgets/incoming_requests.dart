import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/client/order/data/models/order_model.dart';
import 'package:mongez/features/client/order/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_card.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/skeletons/skeleton_order_card.dart';

class IncomingRequests extends StatelessWidget {
  const IncomingRequests({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final lang = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lang.incomingRequests,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
              builder: (ctx, state) {
                if (state is! TechnicianOrdersSuccess) return const SizedBox();
                final currentUserId = (ctx.read<ProfileCubit>().state is ProfileSuccess)
                    ? (ctx.read<ProfileCubit>().state as ProfileSuccess).profile.id
                    : -1;
                final pending = state.orders
                    .where((o) => o.status == OrderStatus.pending && o.workerId == currentUserId)
                    .length;
                if (pending == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lang.newCount(pending),
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<TechnicianOrdersCubit, TechnicianOrdersState>(
          builder: (ctx, state) {
            if (state is TechnicianOrdersInitial ||
                state is TechnicianOrdersLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    SkeletonOrderCard(),
                    SkeletonOrderCard(),
                  ],
                ),
              );
            }
            if (state is TechnicianOrdersFailure) {
              return _emptyState(
                context,
                icon: Icons.cloud_off_rounded,
                title: lang.couldNotLoadRequests,
                subtitle: state.errorMessage,
              );
            }
            if (state is TechnicianOrdersEmpty) {
              return _emptyState(
                context,
                icon: Icons.inbox_rounded,
                title: lang.noRequestsYet,
                subtitle:
                    lang.whenClientBooks,
              );
            }
            if (state is TechnicianOrdersSuccess) {
              final currentUserId = (context.read<ProfileCubit>().state is ProfileSuccess)
                  ? (context.read<ProfileCubit>().state as ProfileSuccess).profile.id
                  : -1;
              final orders = [...state.orders]
                  .where((o) => o.workerId == currentUserId)
                  .toList()
                ..sort((a, b) {
                  const pending = OrderStatus.pending;
                  if (a.status == pending && b.status != pending) return -1;
                  if (b.status == pending && a.status != pending) return 1;
                  return 0;
                });
              return Column(
                children: [
                  for (final OrderModel order in orders.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(
                        order: order,
                        isCustomer: false,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(
                              order: order,
                              isCustomer: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(title, style: tt.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
