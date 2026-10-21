// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp\u00A0',
    decimalDigits: 0,
  );

  static final _dateFormatter = DateFormat('d MMMM yyyy', 'id');
  static final _dateShortFormatter = DateFormat('d MMM yyyy', 'id');
  static final _monthYearFormatter = DateFormat('MMMM yyyy', 'id');

  /// Format a numeric value as Indonesian Rupiah, e.g. "Rp 150.000"
  static String currency(dynamic value) {
    final num parsed = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return _currencyFormatter.format(parsed);
  }

  /// Parse a decimal-string from API into a double
  static double parseAmount(String? value) => double.tryParse(value ?? '0') ?? 0.0;

  /// Format an ISO 8601 date string (or null) into human-readable Indonesian
  static String date(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return _dateFormatter.format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  /// Short date format, e.g. "5 Okt 2026"
  static String dateShort(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return _dateShortFormatter.format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  /// Month + year, e.g. "Oktober 2026"
  static String monthYear(int month, int year) {
    return _monthYearFormatter.format(DateTime(year, month));
  }

  /// Indonesian status labels for donation status strings from backend
  static String donationStatus(String? status) {
    return switch (status) {
      'Berhasil' => 'Berhasil',
      'Menunggu pembayaran' => 'Menunggu Pembayaran',
      'Gagal' => 'Gagal',
      'Kedaluwarsa' => 'Kedaluwarsa',
      'Dibatalkan' => 'Dibatalkan',
      _ => status ?? '-',
    };
  }
}
