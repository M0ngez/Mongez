import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/features/auth/bloc/auth_cubit.dart';
import 'package:mongez/features/auth/screens/google_sign_in_screen.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/custom_button.dart';
import 'package:mongez/core/widgets/logo.dart';

/// Shown on every cold start without a saved session: sign in, or keep
/// browsing as a guest for this run only (the guest flag lives in
/// memory, so closing the app brings this chooser back).
class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with SingleTickerProviderStateMixin {
  bool startAnimation = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        startAnimation = true;
      });
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const GoogleSignInScreen(),
        ),
      ),
    );
  }

  void _continueAsGuest() {
    NavigationService.toGuestMain(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              AnimatedSlide(
                offset: startAnimation ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: startAnimation ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: const Logo(),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  lang.getStartedSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1200),
                child: Text(
                  lang.getStartedDescription,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedScale(
                scale: startAnimation ? 1 : 0.8,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                child: CustomButton(
                  text: lang.login,
                  onPressed: _goToLogin,
                  textColor: colorScheme.onPrimary,
                  backgroundColor: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1000),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.travel_explore_rounded, size: 22),
                    label: Text(
                      lang.continueAsGuest,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: startAnimation ? 1 : 0,
                duration: const Duration(milliseconds: 1400),
                child: Text(
                  lang.getStartedFooter,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
