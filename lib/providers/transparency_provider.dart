// lib/providers/transparency_provider.dart

import 'package:flutter/material.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';
import 'package:annuur_mobile/data/repositories/transparency_repository.dart';

class TransparencyProvider extends ChangeNotifier {
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  CashflowSummaryModel? _cashflow;
  List<ExpenseModel> _expenses = [];
  bool _loading = false;
  String? _error;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  CashflowSummaryModel? get cashflow => _cashflow;
  List<ExpenseModel> get expenses => _expenses;
  bool get loading => _loading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  Future<void> loadForMonth({required int month, required int year}) async {
    _selectedMonth = month;
    _selectedYear = year;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        TransparencyRepository.getMonthlyCashflow(month: month, year: year),
        TransparencyRepository.getExpenses(month: month, year: year),
      ]);
      _cashflow = results[0] as CashflowSummaryModel;
      _expenses = results[1] as List<ExpenseModel>;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  void nextMonth() {
    int m = _selectedMonth + 1;
    int y = _selectedYear;
    if (m > 12) {
      m = 1;
      y++;
    }
    loadForMonth(month: m, year: y);
  }

  void prevMonth() {
    int m = _selectedMonth - 1;
    int y = _selectedYear;
    if (m < 1) {
      m = 12;
      y--;
    }
    loadForMonth(month: m, year: y);
  }
}
