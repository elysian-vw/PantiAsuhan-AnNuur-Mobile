// lib/data/repositories/donation_repository.dart

import 'dart:convert';
import 'dart:math';

import 'package:annuur_mobile/core/services/auth_storage.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/data/models/donation_models.dart';

class DonationRepository {
  DonationRepository._();

  static Future<List<DonationCategoryModel>> getCategories() async {
    final body = await ApiClient.get(
      '/references/donation-categories',
      auth: true,
    );
    final List data = body['data'] as List;
    return data
        .map((e) => DonationCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> createDonation({
    required int kategoriId,
    required int nominal,
    String? catatan,
  }) async {
    final payload = <String, dynamic>{
      'kategori_donasi_id': kategoriId,
      'nominal': nominal,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    };
    // Persist the key before sending. Retrying after a timeout or app restart
    // resolves the original order, even after the old 15-second window.
    final fingerprint = jsonEncode([
      await AuthStorage.getOwnerId() ?? await AuthStorage.getToken(),
      payload,
    ]);
    final pending = Map<String, dynamic>.from(
      jsonDecode(await AuthStorage.readPendingDonations() ?? '{}') as Map,
    );
    final random = Random.secure();
    final key =
        pending[fingerprint] as String? ??
        List.generate(
          32,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    pending[fingerprint] = key;
    await AuthStorage.writePendingDonations(jsonEncode(pending));
    final result = await ApiClient.post(
      '/donations',
      auth: true,
      body: {...payload, 'idempotency_key': key},
    );
    if (result['data'] is! Map || (result['data'] as Map)['id'] is! int) {
      throw const ApiException(
        statusCode: 502,
        message: 'Hasil donasi belum dapat dipastikan. Coba lagi untuk memeriksa transaksi yang sama.',
      );
    }
    pending.remove(fingerprint);
    await AuthStorage.writePendingDonations(jsonEncode(pending));
    return result;
  }

  static Future<PaginatedDonations> getDonations({
    int page = 1,
    String? status,
    int? year,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (status != null) query['status'] = status;
    if (year != null) query['year'] = year;

    final body = await ApiClient.get('/donations', auth: true, query: query);
    return PaginatedDonations.fromJson(body);
  }

  static Future<DonationModel> getDonation(int id) async {
    final body = await ApiClient.get('/donations/$id', auth: true);
    return DonationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  static Future<DonationSummaryModel> getSummary() async {
    final body = await ApiClient.get('/donations/summary', auth: true);
    return DonationSummaryModel.fromJson(body);
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int donationId) async {
    return ApiClient.get('/donations/$donationId/status', auth: true);
  }

  static Future<Map<String, dynamic>> preparePayment(int donationId) =>
      ApiClient.post('/donations/$donationId/pay', auth: true);

  static Future<DonationModel> cancelDonation(int donationId) async {
    final body = await ApiClient.post(
      '/donations/$donationId/cancel',
      auth: true,
    );
    return DonationModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
