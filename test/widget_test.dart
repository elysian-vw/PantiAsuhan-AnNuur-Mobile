// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/ui/screens/splash_screen.dart';
import 'package:annuur_mobile/ui/screens/auth/login_screen.dart';

void main() {
  testWidgets('SplashScreen renders branding title and subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('An-Nuur 2'), findsOneWidget);
    expect(find.text('Panti Asuhan NU Kota Kediri'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LoginScreen renders form inputs and portal button', (
    tester,
  ) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(theme: AppTheme.theme, home: const LoginScreen()),
      ),
    );

    expect(find.text('Panti Asuhan NU An-Nuur 2'), findsOneWidget);
    expect(
      find.text(
        'Masuk untuk menyalurkan donasi dan melihat penggunaan dana panti.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email terdaftar'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
