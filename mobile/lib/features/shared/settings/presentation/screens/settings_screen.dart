import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/locale/localization_cubit.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/theme/theme_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<ThemeCubit>().state.themeMode == ThemeMode.dark;
    final currentLocale = context
        .watch<LocalizationCubit>()
        .state
        .locale
        .languageCode;

    final lang = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.darkMode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setTheme(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  DropdownButton<String>(
                    value: currentLocale,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'ar', child: Text(lang.arabic)),
                      DropdownMenuItem(value: 'en', child: Text(lang.english)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<LocalizationCubit>().changeLanguage(value);
                        _syncLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://mongez-psi.vercel.app/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.privacyPolicy,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            // Destructive, and meaningless for a guest session — last row,
            // below the informational links.
            if (!GuestSession.isGuest) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _openDeletionPage(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang.deleteAccount,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mint a single-use deletion link and hand it to the browser.
///
/// The website has no client login, so the confirmation step (the list of
/// what is removed plus the "this is permanent" checkbox) happens there —
/// this just opens it. A 409 means the account still has work in flight,
/// which the user needs as a count rather than a generic failure.
Future<void> _openDeletionPage(BuildContext context) async {
  final lang = S.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    final data = await getIt.get<ApiService>().post(
          endPoint: 'auth/deletion-token/',
          body: const <String, dynamic>{},
        );

    final url = data['url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('deletion token response has no url');
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } on DioException catch (e) {
    final body = e.response?.data;
    final active = body is Map ? body['active_orders'] : null;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          active is int
              ? lang.deleteAccountActiveOrders(active)
              : lang.deleteAccountFailed,
        ),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(lang.deleteAccountFailed)),
    );
  }
}

void _syncLanguage(String langCode) {
  if (GuestSession.isGuest) return;
  try {
    getIt.get<ApiService>().patch(
      endPoint: 'users/me/',
      body: {'language': langCode},
    ).catchError((Object e) {
      developer.log('Sync language failed: $e', name: 'Settings');
      return <String, dynamic>{};
    });
  } catch (e) {
    developer.log('Sync language failed: $e', name: 'Settings');
  }
}
