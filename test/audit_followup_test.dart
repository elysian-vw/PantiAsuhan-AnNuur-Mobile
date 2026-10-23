import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/core/services/auth_storage.dart';
import 'package:annuur_mobile/core/utils/payment_navigation.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';
import 'package:annuur_mobile/main.dart';

http.Response page(int current, int last, {String status = 'Berhasil'}) =>
    http.Response(
      jsonEncode({
        'current_page': current,
        'last_page': last,
        'total': last,
        'data': [
          {
            'id': current,
            'kode': 'DON-$current',
            'nominal': '5000.00',
            'nominal_formatted': 'Rp 5.000',
            'status': status,
          },
        ],
      }),
      200,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.onUnauthorized = null;
  });

  test(
    'login network failures show helpful messages without internal details',
    () async {
      final auth = AuthProvider();
      for (final failure in [
        http.ClientException('ClientConnection closed at http://internal/api'),
        TimeoutException('private request details'),
        const FormatException('private response'),
      ]) {
        ApiClient.setClient(MockClient((_) async => throw failure));
        await auth.login(
          email: 'test@example.invalid',
          password: 'test-password',
        );
        expect(auth.status, AuthStatus.unauthenticated);
        expect(auth.isLoading, isFalse);
        expect(auth.error, isNotEmpty);
        expect(auth.error, isNot(contains('private')));
        expect(auth.error, isNot(contains('http://')));
        expect(auth.error, isNot(contains('ClientConnection')));
      }
      auth.dispose();
    },
  );

  for (final last in [1, 2, 3]) {
    test('history loads all $last pages exactly once', () async {
      final requests = <int>[];
      ApiClient.setClient(
        MockClient((r) async {
          final current = int.parse(r.url.queryParameters['page']!);
          requests.add(current);
          return page(current, last);
        }),
      );
      final provider = DonationProvider();
      await provider.loadDonations(refresh: true);
      while (provider.hasMore) {
        await provider.loadMore();
      }
      await provider.loadMore();
      expect(requests, List.generate(last, (i) => i + 1));
      expect(provider.donations.length, last);
      provider.dispose();
    });
  }

  test(
    'failed page retries the same page and clears error after recovery',
    () async {
      final requests = <int>[];
      ApiClient.setClient(
        MockClient((r) async {
          final current = int.parse(r.url.queryParameters['page']!);
          requests.add(current);
          if (requests.length == 2) return http.Response('{}', 503);
          return page(current, 2);
        }),
      );
      final provider = DonationProvider();
      await provider.loadDonations(refresh: true);
      await provider.loadMore();
      expect(provider.historyError, isNotNull);
      await provider.loadMore();
      expect(requests, [1, 2, 2]);
      expect(provider.historyError, isNull);
      expect(provider.donations.length, 2);
      provider.dispose();
    },
  );

  test('filter requests server and ignores an older response', () async {
    final old = Completer<http.Response>();
    ApiClient.setClient(
      MockClient((r) async {
        if (r.url.queryParameters['status'] == null) return old.future;
        expect(r.url.queryParameters['page'], '1');
        expect(r.url.queryParameters['status'], 'Menunggu pembayaran');
        return page(1, 1, status: 'Menunggu pembayaran');
      }),
    );
    final provider = DonationProvider();
    final initial = provider.loadDonations(refresh: true);
    await Future<void>.delayed(Duration.zero);
    await provider.setStatusFilter('Menunggu pembayaran');
    old.complete(page(1, 3));
    await initial;
    expect(provider.donations.single.status, 'Menunggu pembayaran');
    expect(provider.hasMore, isFalse);
    provider.dispose();
  });

  test(
    'server failure preserves token and retry can recover the session',
    () async {
      await AuthStorage.saveToken('saved-token');
      ApiClient.setClient(MockClient((r) async => http.Response('{}', 503)));
      final auth = AuthProvider();
      await auth.initialize();
      expect(auth.status, AuthStatus.unavailable);
      expect(await AuthStorage.getToken(), 'saved-token');
      ApiClient.setClient(
        MockClient(
          (r) async => http.Response(
            jsonEncode({
              'user': {
                'id': 1,
                'name': 'Donor',
                'email': 'donor@example.test',
                'role': 'donatur',
                'account_status': 'aktif',
              },
              'donor': null,
            }),
            200,
          ),
        ),
      );
      await auth.initialize();
      expect(auth.isAuthenticated, isTrue);
      auth.dispose();
    },
  );

  test(
    '401 expires session but a stale 401 cannot erase a new login',
    () async {
      await AuthStorage.saveToken('token');
      final auth = AuthProvider();
      ApiClient.setClient(MockClient((r) async => http.Response('{}', 401)));
      await expectLater(
        ApiClient.get('/donations', auth: true),
        throwsA(isA<ApiException>()),
      );
      expect(auth.status, AuthStatus.unauthenticated);
      expect(await AuthStorage.getToken(), isNull);
      await AuthStorage.saveToken('old');
      final pending = Completer<http.Response>();
      ApiClient.setClient(MockClient((r) => pending.future));
      final request = ApiClient.get('/donations', auth: true);
      await Future<void>.delayed(Duration.zero);
      await AuthStorage.saveToken('new');
      pending.complete(http.Response('{}', 401));
      await expectLater(request, throwsA(isA<ApiException>()));
      expect(await AuthStorage.getToken(), 'new');
      auth.dispose();
    },
  );

  test(
    'request key survives a failed submission and rotates after success',
    () async {
      await AuthStorage.saveToken('owner-token');
      final keys = <String>[];
      ApiClient.setClient(
        MockClient((r) async {
          final body = jsonDecode(r.body) as Map;
          keys.add(body['idempotency_key'] as String);
          if (keys.length == 1) throw http.ClientException('connection lost');
          return http.Response('{"data":{"id":1}}', 201);
        }),
      );
      await expectLater(
        DonationRepository.createDonation(kategoriId: 1, nominal: 5000),
        throwsA(isA<http.ClientException>()),
      );
      await DonationRepository.createDonation(kategoriId: 1, nominal: 5000);
      await DonationRepository.createDonation(kategoriId: 1, nominal: 5000);
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[1]));
    },
  );

  test('payment return requires exact origin and recognized path', () {
    const base = 'https://panti.example/api/v1';
    expect(
      isPaymentReturn(
        'https://panti.example/pembayaran/mobile/kembali?order_id=1',
        baseUrl: base,
      ),
      isTrue,
    );
    expect(
      isPaymentReturn(
        'https://panti.example/riwayat/donasi/${'a' * 64}',
        baseUrl: base,
      ),
      isTrue,
    );
    for (final url in [
      'https://evil.example/pembayaran/mobile/kembali',
      'https://panti.example/other?finish=1&order_id=2',
      'http://panti.example/pembayaran/mobile/kembali',
      'https://panti.example.evil.example/pembayaran/mobile/kembali',
    ]) {
      expect(isPaymentReturn(url, baseUrl: base), isFalse);
    }
  });

  testWidgets('startup renders before network completes and offers retry', (
    tester,
  ) async {
    await AuthStorage.saveToken('saved-token');
    final pending = Completer<http.Response>();
    ApiClient.setClient(MockClient((r) => pending.future));
    final auth = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: auth, child: const AnNuurApp()),
    );
    await tester.pump();
    expect(find.text('An-Nuur 2'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(http.Response('{}', 503));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(await AuthStorage.getToken(), 'saved-token');
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
