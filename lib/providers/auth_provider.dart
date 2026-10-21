// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:annuur_mobile/core/services/auth_storage.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/data/models/auth_models.dart';
import 'package:annuur_mobile/data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  DonaturModel? _donor;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  DonaturModel? get donor => _donor;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Called once on app start to restore session
  Future<void> initialize() async {
    final hasToken = await AuthStorage.hasToken();
    if (hasToken) {
      try {
        final body = await AuthRepository.getProfile();
        final data = body;
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _donor = data['donor'] != null
            ? DonaturModel.fromJson(data['donor'] as Map<String, dynamic>)
            : null;
        _status = AuthStatus.authenticated;
      } catch (_) {
        await AuthStorage.deleteToken();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await AuthRepository.login(
        email: email,
        password: password,
      );
      _user = response.user;
      _donor = response.donor;
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _error = e.statusCode == 404
          ? 'Layanan login tidak ditemukan. Periksa alamat API dan koneksi ke server.'
          : e.message;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await AuthRepository.logout();
    _user = null;
    _donor = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  Future<bool> updateProfile({
    required String name,
    required String whatsapp,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final body = await AuthRepository.updateProfile(
        name: name,
        whatsapp: whatsapp,
      );
      final data = body;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _donor = data['donor'] != null
          ? DonaturModel.fromJson(data['donor'] as Map<String, dynamic>)
          : null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
