// lib/data/repositories/auth_repository.dart

import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/core/services/auth_storage.dart';
import 'package:annuur_mobile/data/models/auth_models.dart';

class AuthRepository {
  AuthRepository._();

  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final body = await ApiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': 'android'},
    );
    final response = LoginResponse.fromJson(body);
    await AuthStorage.saveToken(response.token);
    return response;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', auth: true);
    } catch (_) {
      // Best-effort: always clear local token
    }
    await AuthStorage.deleteToken();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return ApiClient.get('/profile', auth: true);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String whatsapp,
  }) async {
    return ApiClient.put(
      '/profile',
      auth: true,
      body: {'nama': name, 'whatsapp': whatsapp},
    );
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return ApiClient.put(
      '/profile/password',
      auth: true,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );
  }
}
