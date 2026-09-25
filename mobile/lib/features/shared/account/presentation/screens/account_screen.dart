import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/features/client/address/data/repositories/address_repository.dart';
import 'package:mongez/features/client/address/presentation/screens/addresses_screen.dart';
import 'package:mongez/features/shared/account/presentation/widgets/account_profile_card.dart';
import 'package:mongez/features/shared/account/presentation/widgets/account_stat_tile.dart';
import 'package:mongez/features/shared/account/presentation/widgets/account_tile.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/shared/profile/presentation/screens/edit_profile_screen.dart';
import 'package:mongez/features/shared/settings/presentation/screens/settings_screen.dart';
import 'package:mongez/features/worker/profile_setup/presentation/screens/add_service_screen.dart';
import 'package:mongez/features/worker/home/presentation/screens/worker_reviews_screen.dart';
import 'package:mongez/generated/l10n.dart';

class AccountScreen extends StatefulWidget {
  final bool isCustomer;

  const AccountScreen({super.key, required this.isCustomer});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AddressRepository _addressRepo;

  @override
  void initState() {
    super.initState();
    _addressRepo = getIt<AddressRepository>();
    _addressRepo.load();
  }

  Future<void> _openAddresses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressPage()),
    );
    _addressRepo.invalidate();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.account, showBackButton: false),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: _addressRepo,
        builder: (context, _) {
          final defaultAddress = _addressRepo.defaultAddress;
          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final profile = state is ProfileSuccess ? state.profile : null;
              final profileAddress = [
                if ((profile?.governorateLabel ?? '').isNotEmpty)
                  profile!.governorateLabel!,
                if ((profile?.city ?? '').isNotEmpty) profile!.city!,
                if ((profile?.address ?? '').isNotEmpty) profile!.address,
              ].join(' · ');
              final address = defaultAddress != null &&
                      defaultAddress.displayAddress.isNotEmpty
                  ? defaultAddress.displayAddress
                  : profileAddress;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GestureDetector(
                    onTap: profile == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(profile: profile),
                              ),
                            ),
                    child: AccountProfileCard(
                      username:
                          profile?.displayName ?? profile?.username ?? '...',
                      phone: profile?.phone ?? '',
                      address: address,
                      imageUrl: profile?.profileImage,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!widget.isCustomer) ...[
                    AccountStatTile(
                      rating: profile?.averageRating ?? 0,
                      jobs: profile?.completedJobs ?? 0,
                      label: lang.ratings,
                      onTap: profile == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerReviewsScreen(
                                    workerId: profile.id,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: 12),
                    AccountTile(
                      icon: Icons.edit_note_rounded,
                      title: lang.editService,
                      subtitle: lang.editServiceDesc,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddServiceScreen(isEditMode: true),
                        ),
                      ),
                    ),
                  ],
                  AccountTile(
                    icon: Icons.location_on_outlined,
                    title: lang.addresses,
                    subtitle: lang.addressesDesc,
                    onTap: _openAddresses,
                  ),
                  AccountTile(
                    icon: Icons.settings_outlined,
                    title: lang.settings,
                    subtitle: lang.settingsDesc,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, lang, cs, tt),
                    icon: Icon(Icons.logout_rounded, color: cs.error),
                    label: Text(
                      lang.logout,
                      style: tt.titleMedium?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: cs.error.withValues(alpha: 0.4), width: 1.2),
                      backgroundColor: cs.error.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, S lang, ColorScheme cs, TextTheme tt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.logout),
        content: Text(lang.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              NavigationService.logout(context);
            },
            child: Text(
              lang.logout,
              style: tt.labelLarge?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
