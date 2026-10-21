// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:annuur_mobile/core/config/app_config.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';
import 'package:annuur_mobile/providers/transparency_provider.dart';
import 'package:annuur_mobile/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DonationProvider>(
          create: (_) => DonationProvider(),
        ),
        ChangeNotifierProvider<TransparencyProvider>(
          create: (_) => TransparencyProvider(),
        ),
      ],
      child: const AnNuurApp(),
    ),
  );
}

class AnNuurApp extends StatelessWidget {
  const AnNuurApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
