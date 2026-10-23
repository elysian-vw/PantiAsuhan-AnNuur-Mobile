// lib/core/services/auth_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:annuur_mobile/core/config/app_config.dart';

/// Manages secure storage for the Sanctum Bearer token.
class AuthStorage {
  AuthStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConfig.tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: 'donor_owner_id');
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> readPendingDonations() =>
      _storage.read(key: 'pending_donation_requests');
  static Future<String?> getOwnerId() => _storage.read(key: 'donor_owner_id');
  static Future<void> saveOwnerId(int id) =>
      _storage.write(key: 'donor_owner_id', value: id.toString());
  static Future<void> writePendingDonations(String value) =>
      _storage.write(key: 'pending_donation_requests', value: value);
}
