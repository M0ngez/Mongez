import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/widgets/guest_empty_state.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/client/order/presentation/screens/order_details_screen.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_card.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/core/widgets/skeletons/skeleton_order_card.dart';

class RequistesScreen extends StatefulWidget {
  const RequistesScreen({super.key});

  @override
  State<RequistesScreen> createState() => _RequistesScreenState();
}

class _RequistesScreenState extends State<RequistesScreen> {
  // Cached cubit reference so dispose() doesn't have to touch `context`
  // (which can be torn down in a logout/back-pop race and used to crash).
  CustomerOrdersCubit? _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit?.loadMore();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit ??= context.read<CustomerOrdersCubit>();
    // Start a 15 s background poll so a dashboard or worker status flip
    // shows up here without a manual pull-to-refresh.
    _cubit!.startPolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit?.stopPolling();
    _cubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.myRequests, showBackButton: false),
      body: GuestSession.isGuest
          ? GuestEmptyState(
              icon: Icons.inbox_rounded,
              message: lang.signInToViewData,
              onLogin: () => NavigationService.requireLogin(
                context,
                mainTabIndex: 2,
              ),
            )
          : BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
        builder: (context, state) {
          if (state is CustomerOrdersInitial || state is CustomerOrdersLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const SkeletonOrderCard(),
            );
          }
          if (state is CustomerOrdersEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(lang.noRequests),
                ],
              ),
            );
          }
          if (state is CustomerOrdersFailure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is CustomerOrdersSuccess) {
            final orders = state.orders;
            return RefreshIndicator(
              onRefresh: () => context.read<CustomerOrdersCubit>().getOrders(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    order: order,
                    isCustomer: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            isCustomer: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
