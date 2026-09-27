import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mongez/core/constants/api_constants.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/error/failure.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/utils/pref_helper.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository(this.apiService);

  Future<Either<Failure, Auth>> signInWithGoogle({
    required String idToken,
  }) async {
    try {
      // Use a plain Dio without auth interceptor to avoid stale-token 401s.
      final plainDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.sendTimeout,
        ),
      );
      final response = await plainDio.post(
        Endpoints.googleSignIn,
        data: {"id_token": idToken},
      );
      final data = response.data as Map<String, dynamic>;

      final auth = Auth.fromJson(data);

      if (auth.tokens?.access != null) {
        await PrefHelper.saveToken(auth.tokens!.access!);
      }
      if (auth.tokens?.refresh != null) {
        await PrefHelper.saveRefreshToken(auth.tokens!.refresh!);
      }

      return right(auth);
    } catch (e) {
      debugPrint('[AUTH ERROR] signInWithGoogle: $e');
      if (e is DioException) {
        if (kDebugMode) {
          debugPrint('[AUTH ERROR] Response data: ${e.response?.data}');
        }
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  Future<Either<Failure, Auth>> completeProfile({
    required String nameAr,
    required String phone,
    required String role,
    required String governorate,
    String city = "",
    String address = "",
    bool makeDefault = true,
    String email = "",
    Uint8List? profileImageBytes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "name_ar": nameAr,
        "phone": phone,
        "role": role,
        "governorate": governorate,
      };
      if (city.isNotEmpty) body["city"] = city;
      if (address.isNotEmpty) body["address"] = address;
      if (email.isNotEmpty) body["email"] = email;
      body["is_default"] = makeDefault;

      late Map<String, dynamic> data;

      if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
        final file = MultipartFile.fromBytes(
          profileImageBytes,
          filename: 'profile_image.jpg',
        );
        data = await apiService.patchMultipart(
          endPoint: Endpoints.completeProfile,
          fields: body,
          file: file,
          fileField: "avatar",
        );
      } else {
        data = await apiService.patch(
          endPoint: Endpoints.completeProfile,
          body: body,
        );
      }

      final auth = Auth.fromJson(data);
      return right(auth);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteIncompleteProfile() async {
    try {
      await apiService.delete(endPoint: Endpoints.deleteIncompleteProfile);
      return right(null);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
