// lib/data/repositories/transparency_repository.dart

import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';

class TransparencyRepository {
  TransparencyRepository._();

  static Future<Map<String, dynamic>> getSummary({int? year}) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    return ApiClient.get('/transparency/summary', auth: true, query: query);
  }

  static Future<CashflowSummaryModel> getMonthlyCashflow({
    required int month,
    required int year,
  }) async {
    final body = await ApiClient.get(
      '/transparency/summary',
      auth: true,
      query: {'month': month, 'year': year},
    );
    return CashflowSummaryModel.fromJson(body);
  }

  static Future<List<ExpenseModel>> getExpenses({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;
    final expenses = <ExpenseModel>[];
    int page = 1;
    int lastPage = 1;
    do {
      final body = await ApiClient.get(
        '/transparency/expenses',
        auth: true,
        query: {...query, 'page': page, 'per_page': 100},
      );
      expenses.addAll(
        (body['data'] as List).map(
          (e) => ExpenseModel.fromJson(e as Map<String, dynamic>),
        ),
      );
      lastPage = body['last_page'] as int;
      page++;
    } while (page <= lastPage);
    return expenses;
  }
}
