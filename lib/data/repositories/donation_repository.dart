// lib/data/repositories/donation_repository.dart

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
    return ApiClient.post(
      '/donations',
      auth: true,
      body: {
        'kategori_donasi_id': kategoriId,
        'nominal': nominal,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
    );
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

  static Future<DonationModel> cancelDonation(int donationId) async {
    final body = await ApiClient.post(
      '/donations/$donationId/cancel',
      auth: true,
    );
    return DonationModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
