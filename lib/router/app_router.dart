// lib/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/ui/screens/splash_screen.dart';
import 'package:annuur_mobile/ui/screens/auth/login_screen.dart';
import 'package:annuur_mobile/ui/screens/auth/register_screen.dart';
import 'package:annuur_mobile/ui/screens/home/main_scaffold.dart';
import 'package:annuur_mobile/ui/screens/donation/create_donation_screen.dart';
import 'package:annuur_mobile/ui/screens/donation/donation_detail_screen.dart';
import 'package:annuur_mobile/ui/screens/payment/payment_webview_screen.dart';
import 'package:annuur_mobile/ui/screens/profile/edit_profile_screen.dart';
import 'package:annuur_mobile/ui/screens/profile/change_password_screen.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootKey,
      refreshListenable: authProvider,
      initialLocation: '/',
      redirect: (context, state) {
        final status = authProvider.status;
        final isAtSplash = state.matchedLocation == '/';
        final isAtLogin = state.matchedLocation == '/login';
        final isAtRegister = state.matchedLocation == '/register';

        if (status == AuthStatus.initial) {
          return isAtSplash ? null : '/';
        }
        if (status == AuthStatus.unauthenticated) {
          return (isAtLogin || isAtRegister) ? null : '/login';
        }
        if (status == AuthStatus.authenticated) {
          if (isAtSplash || isAtLogin || isAtRegister) return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainScaffold(),
          routes: [
            GoRoute(
              path: 'donate',
              builder: (context, state) => const CreateDonationScreen(),
            ),
            GoRoute(
              path: 'donation/:id',
              builder: (context, state) => DonationDetailScreen(
                donationId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: 'pay',
              builder: (context, state) {
                final extra = state.extra as Map<String, String>;
                return PaymentWebviewScreen(
                  paymentUrl: extra['url']!,
                  donationId: int.parse(extra['donationId']!),
                );
              },
            ),
            GoRoute(
              path: 'edit-profile',
              builder: (context, state) => const EditProfileScreen(),
            ),
            GoRoute(
              path: 'change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
