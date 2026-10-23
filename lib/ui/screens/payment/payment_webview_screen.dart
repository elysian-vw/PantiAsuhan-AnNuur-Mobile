// lib/ui/screens/payment/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:annuur_mobile/core/utils/payment_navigation.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final int donationId;
  final String? returnUrl;

  const PaymentWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.donationId,
    this.returnUrl,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;
  bool _checkingStatus = false;
  bool _loadFailed = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _loadFailed = false;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            if (isPaymentReturn(
              request.url,
              expectedReturnUrl: widget.returnUrl,
            )) {
              _handlePaymentFinished();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _loadFailed = true;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
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
            Expanded(
              child: Text(
                success ? 'Pembayaran Berhasil' : 'Status Pembayaran',
              ),
            ),
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
            child: const Text('Selesai'),
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
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await _onWillPop();
        if (exit && context.mounted) {
          setState(() => _allowExit = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Midtrans'),
          actions: [
            IconButton(
              tooltip: 'Periksa status',
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: _handlePaymentFinished,
            ),
            IconButton(
              tooltip: 'Buka di browser',
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                try {
                  final opened = await launchUrl(
                    Uri.parse(widget.paymentUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && mounted) setState(() => _loadFailed = true);
                } catch (_) {
                  if (mounted) setState(() => _loadFailed = true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loadFailed)
              Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Halaman pembayaran belum dapat dimuat. Periksa koneksi atau buka di browser.',
                        ),
                        TextButton(
                          onPressed: () => _controller.reload(),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
