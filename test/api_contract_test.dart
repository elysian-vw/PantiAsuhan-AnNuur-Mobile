import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/data/repositories/auth_repository.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';
import 'package:annuur_mobile/data/repositories/transparency_repository.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const user = {
    'id': 1,
    'name': 'Donatur',
    'email': 'donor@example.test',
    'role': 'donatur',
    'account_status': 'aktif',
  };
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('login reports a missing API endpoint without exception text', () async {
    ApiClient.setClient(
      MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        return http.Response('<html>Not Found</html>', 404);
      }),
    );
    final provider = AuthProvider();
    await provider.login(email: 'donor@example.test', password: 'password');
    expect(provider.isAuthenticated, false);
    expect(provider.error, contains('Layanan login tidak ditemukan'));
    expect(provider.error, isNot(contains('ApiException')));
    expect(provider.isLoading, false);
    provider.dispose();
  });

  test('login preserves backend credential validation messages', () async {
    ApiClient.setClient(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Email, password, atau akses akun tidak sesuai.',
          }),
          422,
        );
      }),
    );
    final provider = AuthProvider();
    await provider.login(email: 'donor@example.test', password: 'wrong');
    expect(provider.error, 'Email, password, atau akses akun tidak sesuai.');
    expect(provider.isAuthenticated, false);
    provider.dispose();
  });

  test(
    'Laravel root login/profile responses preserve login and update profile',
    () async {
      ApiClient.setClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return http.Response(
              jsonEncode({
                'token': 'test-token',
                'token_type': 'Bearer',
                'user': user,
                'donor': null,
              }),
              200,
            );
          }
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.path, endsWith('/profile'));
          if (request.method == 'PUT') {
            expect(jsonDecode(request.body)['nama'], 'Nama Baru');
          }
          return http.Response(jsonEncode({'user': user, 'donor': null}), 200);
        }),
      );
      final login = await AuthRepository.login(
        email: 'donor@example.test',
        password: 'password',
      );
      expect(login.token, 'test-token');
      final provider = AuthProvider();
      await provider.initialize();
      expect(provider.isAuthenticated, true);
      expect(
        await provider.updateProfile(
          name: 'Nama Baru',
          whatsapp: '081234567890',
        ),
        true,
      );
      provider.dispose();
    },
  );

  test('donation routes and root paginator/summary match Laravel', () async {
    ApiClient.setClient(
      MockClient((request) async {
        final path = request.url.path;
        Object body;
        if (path.endsWith('/references/donation-categories')) {
          body = {
            'data': [
              {'id': 1, 'nama': 'Umum'},
            ],
          };
        } else if (path.endsWith('/donations/summary')) {
          body = {
            'total_nominal_berhasil': '0.00',
            'total_nominal_formatted': 'Rp 0',
            'count_berhasil': 0,
            'count_menunggu': 0,
            'count_total': 0,
          };
        } else if (path.endsWith('/donations/17/status')) {
          body = {'donation_id': 17, 'status': 'Menunggu pembayaran'};
        } else if (path.endsWith('/donations/17/cancel')) {
          body = {
            'message': 'Pembayaran donasi berhasil dibatalkan.',
            'data': {
              'id': 17,
              'kode': 'DON-17',
              'nominal': '50000.00',
              'nominal_formatted': 'Rp 50.000',
              'status': 'Dibatalkan',
            },
          };
        } else {
          expect(path, endsWith('/donations'));
          body = {'data': [], 'current_page': 1, 'last_page': 1, 'total': 0};
        }
        return http.Response(jsonEncode(body), 200);
      }),
    );
    expect((await DonationRepository.getCategories()).single.nama, 'Umum');
    expect((await DonationRepository.getDonations()).total, 0);
    expect((await DonationRepository.getSummary()).countTotal, 0);
    expect(
      (await DonationRepository.getPaymentStatus(17))['status'],
      'Menunggu pembayaran',
    );
    final cancelled = await DonationRepository.cancelDonation(17);
    expect(cancelled.status, 'Dibatalkan');
    expect(cancelled.isCancelled, isTrue);
  });

  test(
    'monthly summary and all expense pages use Laravel field names',
    () async {
      ApiClient.setClient(
        MockClient((request) async {
          expect(request.url.queryParameters['month'], '10');
          expect(request.url.queryParameters['year'], '2026');
          if (request.url.path.endsWith('/transparency/summary')) {
            return http.Response(
              jsonEncode({
                'periode': {'bulan': 10, 'tahun': 2026},
                'total_penerimaan': '98000.00',
                'total_pengeluaran': '1000.00',
                'saldo_akhir': '97000.00',
                'total_penerimaan_formatted': 'Rp 98.000',
                'total_pengeluaran_formatted': 'Rp 1.000',
                'saldo_akhir_formatted': 'Rp 97.000',
              }),
              200,
            );
          }
          expect(request.url.path, endsWith('/transparency/expenses'));
          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'last_page': 2,
              'data': [
                {
                  'id': page,
                  'tanggal': '2026-10-20',
                  'nominal': '500.00',
                  'nominal_formatted': 'Rp 500',
                  'keperluan': 'Beras',
                  'keterangan': null,
                  'has_public_proof': false,
                  'bukti_url': null,
                  'kategori': {'id': 1, 'nama': 'Pangan'},
                },
              ],
            }),
            200,
          );
        }),
      );
      final summary = await TransparencyRepository.getMonthlyCashflow(
        month: 10,
        year: 2026,
      );
      expect(summary.saldo, '97000.00');
      final expenses = await TransparencyRepository.getExpenses(
        month: 10,
        year: 2026,
      );
      expect(expenses.length, 2);
      expect(expenses.first.kategori, 'Pangan');
      expect(expenses.first.keterangan, 'Beras');
      expect(expenses.first.isPublic, false);
    },
  );
}
