import 'package:bloc/bloc.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/client/favorites/data/models/favorite_model.dart';
import 'package:mongez/features/client/favorites/domain/favorites_repository.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository favoritesRepository;

  FavoritesCubit({required this.favoritesRepository})
      : super(FavoritesInitial());

  final Map<int, int> _favoriteIdByWorkerId = {};
  final Set<int> _togglingIds = {};

  bool isFavorite(int workerId) {
    final s = state;
    if (s is FavoritesLoading || s is FavoritesInitial) return false;
    if (s is FavoritesSuccess) {
      return s.favoriteWorkerIds.contains(workerId);
    }
    return false;
  }

  bool isToggling(int workerId) => _togglingIds.contains(workerId);

  void reset() {
    _favoriteIdByWorkerId.clear();
    _togglingIds.clear();
    emit(FavoritesInitial());
  }

  Set<int> _buildWorkerIds(List<FavoriteModel> favorites) {
    return favorites
        .map((f) => f.workerId)
        .where((id) => id != null)
        .cast<int>()
        .toSet();
  }

  void _updateMaps(List<FavoriteModel> favorites) {
    _favoriteIdByWorkerId.clear();
    for (final fav in favorites) {
      if (fav.workerId != null) {
        _favoriteIdByWorkerId[fav.workerId!] = fav.id;
      }
    }
  }

  Future<void> getFavorites() async {
    // No session as a guest — the screen shows a sign-in CTA instead.
    if (GuestSession.isGuest) return;
    emit(FavoritesLoading());
    await _refreshFavorites();
  }

  Future<void> _refreshFavorites() async {
    final result = await favoritesRepository.getFavorites();
    result.fold(
      (failure) {
        // Only show failure if we have no prior data; otherwise keep current
        // success state so the UI doesn't flash an error after a tap.
        if (state is! FavoritesSuccess) {
          emit(FavoritesFailure(failure.errorMessage));
        }
      },
      (favorites) {
        _updateMaps(favorites);
        final ids = _buildWorkerIds(favorites);
        emit(FavoritesSuccess(favorites, favoriteWorkerIds: ids));
      },
    );
  }

  Future<void> toggleFavorite(int workerId) async {
    if (GuestSession.isGuest) return;
    if (_togglingIds.contains(workerId)) return;

    // If we haven't loaded favorites yet (Initial/Loading/Failure), fetch first
    // so we know whether this worker is already favorited. Without this guard
    // the heart tap on Home was silently no-oping on cold launch.
    if (state is! FavoritesSuccess) {
      await _refreshFavorites();
      if (state is! FavoritesSuccess) {
        // Repository failed — fall back to a blank baseline so the tap still
        // produces a server-side change.
        emit(FavoritesSuccess(const [], favoriteWorkerIds: const {}));
      }
    }

    final s = state as FavoritesSuccess;
    final wasFavorited = s.favoriteWorkerIds.contains(workerId);
    final originalFavorites = List<FavoriteModel>.from(s.favorites);
    final originalIds = Set<int>.from(s.favoriteWorkerIds);
    final updatedIds = Set<int>.from(originalIds);
    _togglingIds.add(workerId);

    if (wasFavorited) {
      updatedIds.remove(workerId);
    } else {
      updatedIds.add(workerId);
    }
    emit(FavoritesSuccess(originalFavorites, favoriteWorkerIds: updatedIds, togglingIds: _togglingIds));

    if (wasFavorited) {
      final favId = _favoriteIdByWorkerId[workerId];
      if (favId == null) {
        _togglingIds.remove(workerId);
        emit(FavoritesSuccess(originalFavorites, favoriteWorkerIds: originalIds));
        return;
      }
      final result = await favoritesRepository.removeFavorite(favId);
      result.fold(
        (failure) {
          _togglingIds.remove(workerId);
          emit(FavoritesSuccess(originalFavorites, favoriteWorkerIds: originalIds));
        },
        (_) {
          _togglingIds.remove(workerId);
          _favoriteIdByWorkerId.remove(workerId);
          _refreshFavorites();
        },
      );
    } else {
      final result = await favoritesRepository.addFavorite(workerId);
      result.fold(
        (failure) {
          _togglingIds.remove(workerId);
          emit(FavoritesSuccess(originalFavorites, favoriteWorkerIds: originalIds));
        },
        (fav) {
          _togglingIds.remove(workerId);
          _favoriteIdByWorkerId[workerId] = fav.id;
          _refreshFavorites();
        },
      );
    }
  }

  Future<void> addFavorite(int workerId) async {
    final result = await favoritesRepository.addFavorite(workerId);
    result.fold(
      (failure) => null,
      (_) => _refreshFavorites(),
    );
  }

  Future<void> removeFavorite(int id) async {
    final result = await favoritesRepository.removeFavorite(id);
    result.fold(
      (failure) => null,
      (_) => _refreshFavorites(),
    );
  }
}
