import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';

/// Empty state shown on personal screens (profile, favorites,
/// notifications, orders, addresses) while browsing as a guest: grey
/// icon + message + a prominent Login button that runs [onLogin]
/// (usually NavigationService.requireLogin with a redirect-back).
class GuestEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onLogin;

  const GuestEmptyState({
    super.key,
    this.icon = Icons.person_outline_rounded,
    required this.message,
    this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final lang = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(lang.login),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
