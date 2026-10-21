// lib/core/config/app_config.dart

class AppConfig {
  /// USB development: forward port 8000 with `adb reverse tcp:8000 tcp:8000`.
  /// Override API_BASE_URL for an emulator, LAN, or deployed backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// App name
  static const String appName = 'An-Nuur 2';

  /// Organization full name
  static const String appFullName = 'Panti Asuhan NU An-Nuur 2 Kota Kediri';

  /// Max request timeout in seconds
  static const int requestTimeout = 30;

  /// Max upload/download timeout in seconds
  static const int uploadTimeout = 60;

  /// Sanctum token storage key
  static const String tokenKey = 'donor_api_token';

  /// Minimum donation amount (IDR)
  static const int minimumNominal = 10000;

  /// Preset donation amounts (IDR)
  static const List<int> nominalPresets = [
    25000,
    50000,
    100000,
    250000,
    500000,
    1000000,
  ];
}
