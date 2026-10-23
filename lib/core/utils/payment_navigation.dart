import 'package:annuur_mobile/core/config/app_config.dart';

bool isPaymentReturn(
  String url, {
  String baseUrl = AppConfig.apiBaseUrl,
  String? expectedReturnUrl,
}) {
  final uri = Uri.tryParse(url);
  final base = Uri.parse(
    expectedReturnUrl?.isNotEmpty == true ? expectedReturnUrl! : baseUrl,
  );
  if (uri == null ||
      uri.scheme != base.scheme ||
      uri.host != base.host ||
      uri.port != base.port ||
      uri.userInfo.isNotEmpty) {
    return false;
  }
  final prefix = base.path.replaceFirst(
    RegExp(r'/(api/v1/?|pembayaran/mobile/kembali)$'),
    '',
  );
  return uri.path == '$prefix/pembayaran/mobile/kembali' ||
      RegExp('^${RegExp.escape(prefix)}/riwayat/donasi/[a-zA-Z0-9]{64}\$')
          .hasMatch(uri.path);
}
