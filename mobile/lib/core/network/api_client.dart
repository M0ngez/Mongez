import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/api_constants.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/utils/pref_helper.dart';

class DioClient {
  late final Dio _dio;
  VoidCallback? _onUnauthorized;

  DioClient({VoidCallback? onUnauthorized}) {
    _onUnauthorized = onUnauthorized;
    // No global Content-Type override. Dio infers the right header per
    // request body: `application/json` for Maps, `multipart/form-data;
    // boundary=…` for FormData. Hard-coding `application/json` here
    // poisons multipart posts — Dio reuses our header instead of
    // generating the boundary, so the backend sees a JSON-typed body
    // it can't parse and silently drops `request.FILES`. That bug
    // killed every photo/audio/avatar upload from the app.
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Safety net: guests have no session, so authenticated calls are
          // cancelled here instead of travelling to the backend for a 401.
          // Screens gate these actions before they ever build a request.
          if (GuestSession.isGuest && _requiresAuth(options.path)) {
            return handler.reject(
              DioException.requestCancelled(
                requestOptions: options,
                reason: 'guest session cannot call authenticated endpoints',
              ),
            );
          }
          final token = await PrefHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await tryRefreshToken();
            if (refreshed) {
              final retryOptions = error.requestOptions;
              final token = await PrefHelper.getToken();
              retryOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              await PrefHelper.clearToken();
              await PrefHelper.clearRefreshToken();
              _onUnauthorized?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Path prefixes the backend guards with IsAuthenticated (see
  /// backend/config/permissions.py). Everything else (workers list,
  /// categories, worker details, public reviews…) stays open to guests.
  static const List<String> _authPathPrefixes = [
    'users/',
    'favorites',
    'orders/',
    'notifications/',
    'addresses/',
    'ratings/',
    'workers/me',
  ];

  static bool _requiresAuth(String rawPath) {
    var path = rawPath;
    final apiIdx = path.indexOf('/api/');
    if (apiIdx >= 0) path = path.substring(apiIdx + '/api/'.length);
    path = path.replaceFirst(RegExp(r'^/+'), '');
    // Public, AllowAny reviews list — kept readable for guests.
    if (path.startsWith('ratings/worker/')) return false;
    return _authPathPrefixes.any(path.startsWith);
  }

  Future<bool> tryRefreshToken() async {
    final refreshToken = await PrefHelper.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.sendTimeout,
        ),
      ).post(
        Endpoints.refreshToken,
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess != null) {
        await PrefHelper.saveToken(newAccess);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;
}
