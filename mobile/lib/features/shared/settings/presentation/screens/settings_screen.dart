import 'dart:developer' as developer;
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
          ],
        ),
      ),
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
