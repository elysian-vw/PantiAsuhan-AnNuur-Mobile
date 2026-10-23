import 'package:flutter_test/flutter_test.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';

void main() {
  test(
    'cashflow preserves provisional status and explains excluded receipts',
    () {
      final payload = <String, dynamic>{
        'periode': {'bulan': 10, 'tahun': 2026},
        'total_penerimaan': '248000.00',
        'total_pengeluaran': '0.00',
        'saldo_akhir': '248000.00',
        'total_penerimaan_formatted': 'Rp 248.000',
        'total_pengeluaran_formatted': 'Rp 0',
        'saldo_akhir_formatted': 'Rp 248.000',
        'is_provisional': true,
        'unknown_fee_count': 2,
      };
      final summary = CashflowSummaryModel.fromJson(payload);
      expect(summary.isProvisional, isTrue);
      expect(summary.unknownFeeCount, 2);
      expect(summary.calculationNotice, contains('2 donasi online'));
      expect(summary.calculationNotice, contains('belum masuk'));
      expect(summary.saldo, '248000.00');
      payload.remove('is_provisional');
      payload.remove('unknown_fee_count');
      expect(CashflowSummaryModel.fromJson(payload).isProvisional, isFalse);
    },
  );
}
