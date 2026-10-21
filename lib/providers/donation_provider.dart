// lib/providers/donation_provider.dart

import 'package:flutter/material.dart';
import 'package:annuur_mobile/data/models/donation_models.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';

class DonationProvider extends ChangeNotifier {
  // Categories
  List<DonationCategoryModel> _categories = [];
  bool _categoriesLoading = false;

  // Donation history
  List<DonationModel> _donations = [];
  bool _donationsLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  // Summary
  DonationSummaryModel? _summary;
  bool _summaryLoading = false;

  // Create donation
  bool _creating = false;
  String? _createError;

  // Getters
  List<DonationCategoryModel> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;
  List<DonationModel> get donations => _donations;
  bool get donationsLoading => _donationsLoading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _currentPage < _lastPage;
  DonationSummaryModel? get summary => _summary;
  bool get summaryLoading => _summaryLoading;
  bool get creating => _creating;
  String? get createError => _createError;

  Future<void> loadCategories() async {
    _categoriesLoading = true;
    notifyListeners();
    try {
      _categories = await DonationRepository.getCategories();
    } catch (_) {}
    _categoriesLoading = false;
    notifyListeners();
  }

  Future<void> loadSummary() async {
    _summaryLoading = true;
    notifyListeners();
    try {
      _summary = await DonationRepository.getSummary();
    } catch (_) {}
    _summaryLoading = false;
    notifyListeners();
  }

  Future<void> loadDonations({bool refresh = false}) async {
    if (_donationsLoading) return;
    if (refresh) {
      _currentPage = 1;
      _donations = [];
    }
    _donationsLoading = refresh;
    if (!refresh) _loadingMore = true;
    notifyListeners();

    try {
      final result = await DonationRepository.getDonations(page: _currentPage);
      if (refresh) {
        _donations = result.data;
      } else {
        _donations.addAll(result.data);
      }
      _currentPage = result.currentPage + 1;
      _lastPage = result.lastPage;
    } catch (_) {}

    _donationsLoading = false;
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    await loadDonations();
  }

  Future<Map<String, dynamic>?> createDonation({
    required int kategoriId,
    required int nominal,
    String? catatan,
  }) async {
    _creating = true;
    _createError = null;
    notifyListeners();
    try {
      final result = await DonationRepository.createDonation(
        kategoriId: kategoriId,
        nominal: nominal,
        catatan: catatan,
      );
      // Refresh summary and list
      loadSummary();
      loadDonations(refresh: true);
      return result;
    } catch (e) {
      _createError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }
}
