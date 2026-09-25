import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/theme/app_colors.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/widgets/guest_empty_state.dart';
import 'package:mongez/features/client/address/data/models/address_model.dart';
import 'package:mongez/features/client/address/presentation/widgets/address_card.dart';
import 'package:mongez/features/client/address/presentation/screens/add_address_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/core/widgets/custom_button.dart';
import 'package:mongez/features/client/address/data/repositories/address_repository.dart';
import 'package:mongez/core/widgets/skeletons/skeleton_address_card.dart';

class SavedAddressPage extends StatefulWidget {
  final int? initialSelectedId;

  /// Whether tapping Apply promotes the chosen address to be the
  /// user's server-side default. True for the My Addresses /
  /// management entries; false when checkout just picks a delivery
  /// address for one order — that choice must never silently move
  /// the user's default.
  final bool setsDefault;

  const SavedAddressPage({
    super.key,
    this.initialSelectedId,
    this.setsDefault = true,
  });

  @override
  State<SavedAddressPage> createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  List<AddressModel> _addresses = [];
  bool _loading = true;
  String? _error;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    if (!GuestSession.isGuest) _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<ApiService>();
      final data = await api.get(endPoint: Endpoints.addresses);
      final list = (data as List<dynamic>)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _loading = false;
        if (_selectedId == null && list.isNotEmpty) {
          _selectedId = list
              .firstWhere((a) => a.isDefault, orElse: () => list.first)
              .id;
        }
      });
    } catch (e) {
      debugPrint('[ADDRESS] Fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteAddress(int id) async {
    try {
      await getIt<ApiService>().delete(endPoint: Endpoints.addressById(id));
      if (_selectedId == id) _selectedId = null;
      getIt<AddressRepository>().invalidate();
      _fetchAddresses();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.response?.data is Map
              ? ((e.response!.data as Map)['error'] ?? e.toString())
              : e.toString())
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _applySelection() async {
    if (_selectedId == null) return;
    final selected = _addresses.firstWhere(
      (a) => a.id == _selectedId,
      orElse: () => _addresses.first,
    );
    // Only management mode moves the default; a one-off checkout
    // selection just returns the picked address untouched.
    if (widget.setsDefault && selected.id != null && !selected.isDefault) {
      try {
        await getIt<ApiService>().patch(
          endPoint: Endpoints.addressById(selected.id!),
          body: {'is_default': true},
        );
        getIt<AddressRepository>().invalidate();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).failedToSave),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = S.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: lang.addressesPageTitle),
      body: GuestSession.isGuest
          ? GuestEmptyState(
              icon: Icons.location_off_outlined,
              message: lang.signInToViewData,
              onLogin: () => NavigationService.requireLogin(
                context,
                mainTabIndex: 3,
                onLoggedIn: () => NavigationService.navigatorKey.currentState
                    ?.push(
                  MaterialPageRoute(builder: (_) => const SavedAddressPage()),
                ),
              ),
            )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                lang.deliveryAddress,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SkeletonAddressCard(),
                );
              }, childCount: 3),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.failedToLoad,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _fetchAddresses,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(lang.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_addresses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.noAddresses,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    // const SizedBox(height: 32),
                    // CustomButton(
                    //   text: lang.addNewAddress,
                    //   onPressed: () async {
                    //     final result = await Navigator.push<bool>(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const AddAddressScreen(),
                    //       ),
                    //     );
                    //     if (result == true) _fetchAddresses();
                    //   },
                    // ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _addresses[index];
                final bool isSelected = _selectedId == item.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SelectableCard(
                        title: item.label.isNotEmpty ? item.label : null,
                        subtitle: item.displayAddress,
                        isDefault: item.isDefault,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedId = item.id;
                          });
                        },
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.id != null)
                              GestureDetector(
                                onTap: () => _deleteAddress(item.id!),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.danger.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: _addresses.length),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                children: [
                  CustomButton(
                    text: lang.addNewAddress,
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAddressScreen(),
                        ),
                      );
                      if (result == true) {
                        getIt<AddressRepository>().invalidate();
                        _fetchAddresses();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedId != null)
                    CustomButton(
                      text: lang.apply,
                      onPressed: _applySelection,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.white,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
