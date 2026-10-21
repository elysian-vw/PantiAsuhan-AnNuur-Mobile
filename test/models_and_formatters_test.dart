// test/models_and_formatters_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/data/models/auth_models.dart';
import 'package:annuur_mobile/data/models/donation_models.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';

void main() {
  group('Formatters Tests', () {
    test('Formatters.currency formats numbers to IDR correctly', () {
      expect(Formatters.currency(50000), contains('50.000'));
      expect(Formatters.currency(1500000), contains('1.500.000'));
      expect(Formatters.currency('25000'), contains('25.000'));
    });

    test('Formatters.donationStatus translates status strings accurately', () {
      expect(Formatters.donationStatus('Berhasil'), 'Berhasil');
      expect(
        Formatters.donationStatus('Menunggu pembayaran'),
        'Menunggu Pembayaran',
      );
      expect(Formatters.donationStatus('Gagal'), 'Gagal');
      expect(Formatters.donationStatus('Kedaluwarsa'), 'Kedaluwarsa');
      expect(Formatters.donationStatus('Dibatalkan'), 'Dibatalkan');
    });
  });

  group('Auth Models Tests', () {
    test('UserModel and DonaturModel parse correctly from JSON', () {
      final userJson = {
        'id': 10,
        'name': 'Haji Ahmad',
        'email': 'ahmad@example.com',
        'role': 'donatur',
        'account_status': 'aktif',
        'email_verified_at': '2026-10-20T10:00:00.000000Z',
      };
      final user = UserModel.fromJson(userJson);
      expect(user.id, 10);
      expect(user.name, 'Haji Ahmad');
      expect(user.role, 'donatur');
      expect(user.accountStatus, 'aktif');

      final donorJson = {
        'id': 5,
        'nama': 'Haji Ahmad',
        'whatsapp': '081234567890',
        'email': 'ahmad@example.com',
        'jenis': 'tetap',
      };
      final donor = DonaturModel.fromJson(donorJson);
      expect(donor.id, 5);
      expect(donor.jenis, 'tetap');
    });
  });

  group('Donation Models Tests', () {
    test('DonationModel parses full payload including payment info', () {
      final donationJson = {
        'id': 101,
        'kode': 'DON-20261020-001',
        'nominal': '150000',
        'nominal_formatted': 'Rp 150.000',
        'biaya': '4000',
        'biaya_formatted': 'Rp 4.000',
        'sumber_biaya': 'Diserap Panti',
        'status': 'Menunggu pembayaran',
        'dibayar_pada': null,
        'created_at': '2026-10-20T12:00:00.000000Z',
        'catatan': 'Semoga barakah',
        'kategori': {
          'id': 1,
          'nama': 'Pendidikan Anak Asuh',
          'deskripsi': 'Bantuan SPP & buku sekolah',
        },
        'payment': {
          'order_id': 'DON-ORDER-101',
          'status': 'pending',
          'metode': null,
          'snap_token': 'snap-sample-token-123',
          'payment_url':
              'https://app.sandbox.midtrans.com/snap/v2/vtweb/test123',
        },
      };

      final donation = DonationModel.fromJson(donationJson);
      expect(donation.id, 101);
      expect(donation.kode, 'DON-20261020-001');
      expect(donation.isPending, true);
      expect(donation.isSuccess, false);
      expect(donation.canPay, true);
      expect(donation.payment?.snapToken, 'snap-sample-token-123');
      expect(donation.kategori?.nama, 'Pendidikan Anak Asuh');
    });
  });

  group('Transparency Models Tests', () {
    test('CashflowSummaryModel and ExpenseModel parse correctly', () {
      final cashflowJson = {
        'periode': {'bulan': 10, 'tahun': 2026},
        'total_penerimaan': '25000000',
        'total_pengeluaran': '12500000',
        'saldo_akhir': '12500000',
        'total_penerimaan_formatted': 'Rp 25.000.000',
        'total_pengeluaran_formatted': 'Rp 12.500.000',
        'saldo_akhir_formatted': 'Rp 12.500.000',
      };
      final cashflow = CashflowSummaryModel.fromJson(cashflowJson);
      expect(cashflow.month, 10);
      expect(cashflow.saldoFormatted, 'Rp 12.500.000');

      final expenseJson = {
        'id': 88,
        'tanggal': '2026-10-15',
        'nominal': '750000',
        'nominal_formatted': 'Rp 750.000',
        'keperluan': 'Beras & sembako 5 karung',
        'has_public_proof': true,
        'bukti_url': '/storage/expenses/nota-beras.jpg',
        'kategori': {'id': 1, 'nama': 'Operasional Harian'},
        'created_by': 'Bendahara Panti',
      };
      final expense = ExpenseModel.fromJson(expenseJson);
      expect(expense.id, 88);
      expect(expense.isPublic, true);
      expect(expense.kategori, 'Operasional Harian');
    });
  });
}
