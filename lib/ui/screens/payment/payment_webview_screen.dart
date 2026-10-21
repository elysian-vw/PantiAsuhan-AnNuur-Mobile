// lib/ui/screens/payment/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final int donationId;

  const PaymentWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.donationId,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
            _checkCallbackUrl(url);
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _checkCallbackUrl(url);
          },
          onNavigationRequest: (request) {
            _checkCallbackUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkCallbackUrl(String url) {
    final lower = url.toLowerCase();
    // Midtrans redirect keywords indicating completion
    if (lower.contains('status_code=200') ||
        lower.contains('transaction_status=settlement') ||
        lower.contains('finish') ||
        lower.contains('order_id=')) {
      _handlePaymentFinished();
    }
  }

  Future<void> _handlePaymentFinished() async {
    if (_checkingStatus || !mounted) return;
    _checkingStatus = true;
    String status = 'Status belum dapat diperiksa';
    try {
      final response = await DonationRepository.getPaymentStatus(
        widget.donationId,
      );
      status = response['status'] as String;
      if (mounted) {
        context.read<DonationProvider>().loadSummary();
        context.read<DonationProvider>().loadDonations(refresh: true);
      }
    } catch (_) {
      // A redirect alone never confirms a payment.
    }
    final success = status == 'Berhasil';

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline,
              color: success ? AppColors.success : AppColors.primary,
            ),
            SizedBox(width: 8),
            Text(success ? 'Pembayaran Berhasil' : 'Status Pembayaran'),
          ],
        ),
        content: Text(
          success
              ? 'Terima kasih! Pembayaran Anda telah dikonfirmasi oleh sistem.'
              : '$status. Periksa kembali melalui Riwayat Donasi.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
    _checkingStatus = false;
  }

  Future<bool> _onWillPop() async {
    final canGoBack = await _controller.canGoBack();
    if (canGoBack) {
      _controller.goBack();
      return false;
    }

    if (!mounted) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Halaman Pembayaran?'),
        content: const Text(
          'Jika Anda belum menyelesaikan pembayaran, Anda dapat melanjutkannya nanti melalui Riwayat Donasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjutkan Bayar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await _onWillPop();
        if (exit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Midtrans'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress / 100.0,
                color: AppColors.primary,
                backgroundColor: AppColors.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
