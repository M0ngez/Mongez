import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/shared/profile/data/models/profile_model.dart';
import 'package:mongez/features/shared/profile/domain/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;
  Timer? _pollTimer;

  ProfileCubit({required this.profileRepository})
      : super(ProfileInitial());

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  Future<void> getProfile() async {
    // Guests have no profile — never hit users/me/ (it would 401).
    if (GuestSession.isGuest) return;
    emit(ProfileLoading());
    final result = await profileRepository.getProfile();
    result.fold(
      (failure) => emit(ProfileFailure(failure.errorMessage)),
      (profile) => emit(ProfileSuccess(profile)),
    );
  }

  /// Quiet background refresh — does NOT emit ProfileLoading so the UI
  /// doesn't flash. Used by the polling tick and after a remote-side
  /// change (e.g. admin uploaded a new avatar from the dashboard) is
  /// likely. Only swaps state if the fetched profile actually differs.
  Future<void> refreshSilently() async {
    if (GuestSession.isGuest) return;
    final result = await profileRepository.getProfile();
    result.fold(
      (_) {/* swallow — keep current state on transient failures */},
      (profile) {
        final current = state;
        if (current is ProfileSuccess && current.profile == profile) return;
        emit(ProfileSuccess(profile));
      },
    );
  }

  /// Periodic poll so admin-side avatar / detail changes land on the
  /// current user's screen without an app restart. 10 s is a good
  /// balance — auth/users/me/ is a small, indexed lookup.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => refreshSilently(),
    );
  }

  void reset() => emit(ProfileInitial());

  Future<void> updateProfile({
    String? username,
    String? nameAr,
    String? email,
    String? phone,
    String? governorate,
    String? city,
    String? address,
    Uint8List? profileImageBytes,
  }) async {
    emit(ProfileLoading());
    final result = await profileRepository.updateProfile(
      username: username,
      nameAr: nameAr,
      email: email,
      phone: phone,
      governorate: governorate,
      city: city,
      address: address,
      profileImageBytes: profileImageBytes,
    );
    result.fold(
      (failure) => emit(ProfileFailure(failure.errorMessage)),
      (profile) => emit(ProfileSuccess(profile)),
    );
  }
}
