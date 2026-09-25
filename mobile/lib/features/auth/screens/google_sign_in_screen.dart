import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mongez/core/constants/api_constants.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/features/auth/bloc/auth_cubit.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/worker/profile_setup/presentation/screens/complete_profile_screen.dart';
import 'package:mongez/features/worker/profile_setup/presentation/screens/pending_verification_screen.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/widgets/logo.dart';
import 'package:mongez/main.dart' show fcmService;

class GoogleSignInScreen extends StatefulWidget {
  /// Tab of MainScreen to land on after login — lets the guest flow
  /// return to the screen where the user tapped "sign in".
  final int mainTabIndex;

  /// Runs right after MainScreen is pushed on a successful login with a
  /// completed profile (replay checkout, reopen a screen, toggle a
  /// favorite…). Not run for the complete-profile / pending-verification
  /// branches, which take over the flow.
  final VoidCallback? onLoggedIn;

  const GoogleSignInScreen({
    super.key,
    this.mainTabIndex = 0,
    this.onLoggedIn,
  });

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    final webClientId = ApiConstants.googleClientId;
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? (webClientId.isNotEmpty ? webClientId : null) : null,
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          fcmService.attachNotificationCubit(context.read<NotificationCubit>());
          fcmService.initAfterLogin(getIt.get<ApiService>());
          final profileCompleted = state.auth.profileCompleted ?? false;
          final verificationStatus = state.auth.verificationStatus ?? 'verified';

          if (!profileCompleted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompleteProfileScreen(auth: state.auth),
              ),
            );
          } else if (verificationStatus == 'pending' || verificationStatus == 'rejected') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => PendingVerificationScreen(auth: state.auth),
              ),
              (route) => false,
            );
          } else {
            await NavigationService.toMainScreen(
              context,
              state.auth,
              initialIndex: widget.mainTabIndex,
            );
            final afterLogin = widget.onLoggedIn;
            if (afterLogin != null && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                afterLogin();
              });
            }
          }
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  const Logo(),
                  const SizedBox(height: 24),
                  Text(
                    lang.welcomeToMongez,
                    textAlign: TextAlign.center,
                    style: tt.displayMedium?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.signInToContinue,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  state is AuthLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleGoogleSignIn(),
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 28,
                              color: Colors.red,
                            ),
                            label: Text(
                              lang.signInWithGoogle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (!mounted) return;
      if (idToken != null) {
        context.read<AuthCubit>().signInWithGoogle(idToken: idToken);
      }
    } catch (error) {
      debugPrint('[AUTH] Google sign-in failed: $error');
      if (!mounted) return;
      final lang = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.googleSignInFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
