import 'dart:async';

import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/error/failure.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/utils/pref_helper.dart';
import 'package:mongez/features/auth/bloc/auth_cubit.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/models/tokens.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/features/auth/screens/get_started_screen.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/profile/data/models/profile_model.dart';
import 'package:mongez/features/shared/profile/domain/profile_repository.dart';
import 'package:mongez/features/worker/profile_setup/presentation/screens/complete_profile_screen.dart';
import 'package:mongez/features/worker/profile_setup/presentation/screens/pending_verification_screen.dart';
import 'package:mongez/main.dart' show fcmService;

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Hard timeout: if _checkAuth doesn't finish in 8s, force-navigate.
    Timer(const Duration(seconds: 8), () {
      if (mounted) _goToAuthFlow();
    });

    String? token;
    try {
      token = await PrefHelper.getToken().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
    } catch (_) {
      token = null;
    }

    if (token == null || token.isEmpty) {
      _goToAuthFlow();
      return;
    }
    final savedToken = token;
    try {
      final profileRepo = getIt.get<ProfileRepository>();
      // Add a 5s timeout so the splash never hangs on a slow/bad token.
      final result = await profileRepo.getProfile().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              PrefHelper.clearAll();
              return dartz.Left(ServerFailure(errorMessage: 'timeout'));
            },
          );
      result.fold(
        (_) async {
          await PrefHelper.clearAll();
          _goToAuthFlow();
        },
        (profile) => _goToProfileOrMain(profile, savedToken),
      );
    } catch (_) {
      await PrefHelper.clearAll();
      _goToAuthFlow();
    }
  }

  void _goToProfileOrMain(ProfileModel profile, String token) {
    // Initialize FCM: request permission, get token, register with backend.
    fcmService.attachNotificationCubit(context.read<NotificationCubit>());
    fcmService.initAfterLogin(getIt.get<ApiService>());

    final user = User(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      nameAr: profile.nameAr,
      displayName: profile.displayName,
      phone: profile.phone,
      address: profile.address,
      governorate: profile.governorate,
      governorateLabel: profile.governorateLabel,
      city: profile.city,
      profileImage: profile.profileImage,
      role: profile.role,
      dateJoined: profile.dateJoined != null
          ? DateTime.tryParse(profile.dateJoined!)
          : null,
      profileCompleted: profile.profileCompleted,
      verificationStatus: profile.verificationStatus,
      rejectionReason: profile.rejectionReason,
    );
    final auth = Auth(
      message: '',
      user: user,
      tokens: Tokens(access: token),
      profileCompleted: profile.profileCompleted,
      verificationStatus: profile.verificationStatus,
    );

    final profileCompleted = profile.profileCompleted ?? false;
    final verificationStatus = profile.verificationStatus ?? 'verified';
    final role = profile.role;

    if (!profileCompleted) {
      _goToCompleteProfile(auth);
    } else if (role == 'worker' &&
        (verificationStatus == 'pending' || verificationStatus == 'rejected')) {
      _goToPendingVerification(auth);
    } else {
      _goToMainScreen(auth);
    }
  }

  Future<bool> _tryRefreshToken() async {
    final dioClient = getIt.get<ApiService>().dioClient;
    return dioClient.tryRefreshToken();
  }

  void _goToMainScreen(Auth auth) {
    if (!mounted) return;
    NavigationService.toMainScreen(context, auth);
  }

  void _goToCompleteProfile(Auth auth) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: CompleteProfileScreen(auth: auth),
        ),
      ),
      (route) => false,
    );
  }

  void _goToPendingVerification(Auth auth) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: PendingVerificationScreen(auth: auth),
        ),
      ),
      (route) => false,
    );
  }

  void _goToAuthFlow() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: const GetStartedScreen(),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
