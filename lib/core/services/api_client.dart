// lib/core/services/api_client.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:annuur_mobile/core/config/app_config.dart';
import 'package:annuur_mobile/core/services/auth_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Returns the first error message from Laravel validation errors
  String? firstError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    return null;
  }

  /// Returns all error messages concatenated
  String get allErrors {
    if (errors == null || errors!.isEmpty) return message;
    final List<String> msgs = [];
    errors!.forEach((_, v) {
      if (v is List) {
        for (final e in v) {
          msgs.add(e.toString());
        }
      }
    });
    return msgs.join('\n');
  }
}

class ApiClient {
  ApiClient._();

  static http.Client _client = http.Client();

  @visibleForTesting
  static void setClient(http.Client client) {
    _client.close();
    _client = client;
  }

  static const Duration _timeout = Duration(seconds: AppConfig.requestTimeout);

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await AuthStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final uri = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path:
          base.path.replaceFirst(RegExp(r'/+$'), '') +
          (path.startsWith('/') ? path : '/$path'),
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
    return uri;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    late final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      body = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message:
          body['message'] as String? ??
          (response.statusCode == 401
              ? 'Sesi tidak valid. Silakan masuk kembali.'
              : response.statusCode == 403
              ? 'Akses ditolak.'
              : response.statusCode == 404
              ? 'Data tidak ditemukan.'
              : response.statusCode == 422
              ? (body['message'] as String? ?? 'Data tidak valid.')
              : response.statusCode == 429
              ? 'Terlalu banyak permintaan. Coba lagi sebentar lagi.'
              : 'Terjadi kesalahan pada server.'),
      errors: body['errors'] as Map<String, dynamic>?,
    );
  }

  // ---- HTTP Verbs ----

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
  }) async {
    final response = await _client
        .get(_uri(path, query), headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await _client
        .put(
          _uri(path),
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  static Future<http.Response> getRaw(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
  }) async {
    return _client
        .get(_uri(path, query), headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: AppConfig.uploadTimeout));
  }
}
