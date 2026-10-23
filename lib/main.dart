// lib/main.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const AnNuurApp(),
    ),
  );
}

class AnNuurApp extends StatefulWidget {
  const AnNuurApp({super.key});

  @override
  State<AnNuurApp> createState() => _AnNuurAppState();
}

class _AnNuurAppState extends State<AnNuurApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = AppRouter.createRouter(auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.initialize();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = context.watch<AuthProvider>().user?.id;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
      builder: (_, child) => MultiProvider(
        key: ValueKey(ownerId),
        providers: [
          ChangeNotifierProvider(create: (_) => DonationProvider()),
          ChangeNotifierProvider(create: (_) => TransparencyProvider()),
        ],
        child: child!,
      ),
    );
  }
}
