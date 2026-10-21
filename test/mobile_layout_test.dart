import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';
import 'package:annuur_mobile/providers/transparency_provider.dart';
import 'package:annuur_mobile/ui/screens/home/home_tab.dart';
import 'package:annuur_mobile/ui/screens/auth/login_screen.dart';
import 'package:annuur_mobile/ui/screens/donation/create_donation_screen.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';

class _Donations extends DonationProvider {
  @override
  Future<void> loadSummary() async {}
  @override
  Future<void> loadCategories() async {}
  @override
  Future<void> loadDonations({bool refresh = false}) async {}
}

class _Transparency extends TransparencyProvider {
  @override
  Future<void> loadForMonth({required int month, required int year}) async {}
  @override
  CashflowSummaryModel get cashflow => const CashflowSummaryModel(
    month: 10,
    year: 2026,
    totalPemasukan: '120000000',
    totalPengeluaran: '80000000',
    saldo: '40000000',
    totalPemasukanFormatted: 'Rp 120.000.000',
    totalPengeluaranFormatted: 'Rp 80.000.000',
    saldoFormatted: 'Rp 40.000.000',
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('id'));
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Mobile layout at $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AuthProvider();
        final donations = _Donations();
        final transparency = _Transparency();
        addTearDown(auth.dispose);
        addTearDown(donations.dispose);
        addTearDown(transparency.dispose);
        var openedReport = false;
        final screens = <Widget>[
          const LoginScreen(),
          HomeTab(
            onNavigateToTransparency: () => openedReport = true,
            onNavigateToHistory: () {},
          ),
          const CreateDonationScreen(),
        ];
        for (final screen in screens) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthProvider>.value(value: auth),
                ChangeNotifierProvider<DonationProvider>.value(
                  value: donations,
                ),
                ChangeNotifierProvider<TransparencyProvider>.value(
                  value: transparency,
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: screen,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen is HomeTab) {
            await tester.ensureVisible(find.text('Lihat laporan'));
            await tester.tap(find.text('Lihat laporan'));
            expect(openedReport, isTrue);
          }
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1400),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
