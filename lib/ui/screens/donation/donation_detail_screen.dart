// lib/ui/screens/donation/donation_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:annuur_mobile/ui/screens/payment/open_payment.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/data/models/donation_models.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';

class DonationDetailScreen extends StatefulWidget {
  final int donationId;

  const DonationDetailScreen({super.key, required this.donationId});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  DonationModel? _donation;
  bool _loading = true;
  String? _error;
  bool _checkingStatus = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DonationRepository.getDonation(widget.donationId);
      setState(() {
        _donation = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_donation?.payment?.orderId == null) return;
    setState(() {
      _checkingStatus = true;
    });
    try {
      await DonationRepository.getPaymentStatus(_donation!.id);
      await _fetchDetail();
      if (mounted) {
        context.read<DonationProvider>().loadSummary();
        context.read<DonationProvider>().loadDonations(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status pembayaran berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingStatus = false;
        });
      }
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Batalkan Pembayaran?'),
          ],
        ),
        content: const Text(
          'Transaksi donasi yang dibatalkan tidak dapat dilanjutkan kembali. Apakah Anda yakin ingin membatalkan transaksi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cancelDonation();
    }
  }

  Future<void> _cancelDonation() async {
    if (_donation == null) return;
    setState(() => _cancelling = true);
    try {
      final updated = await DonationRepository.cancelDonation(_donation!.id);
      if (mounted) {
        setState(() {
          _donation = updated;
          _cancelling = false;
        });
        context.read<DonationProvider>().loadSummary();
        context.read<DonationProvider>().loadDonations(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran donasi berhasil dibatalkan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        final msg = e is ApiException
            ? e.message
            : 'Gagal membatalkan donasi: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Donasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _fetchDetail,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDetail,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _donation!;
    final isSuccess = d.isSuccess;
    final isPending = d.isPending;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Status & Nominal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isPending
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : isPending
                        ? Icons.hourglass_top_rounded
                        : Icons.cancel_rounded,
                    color: isSuccess
                        ? AppColors.success
                        : isPending
                        ? AppColors.warning
                        : AppColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  d.nominalFormatted,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isPending
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    Formatters.donationStatus(d.status),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSuccess
                          ? AppColors.success
                          : isPending
                          ? AppColors.warning
                          : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isSuccess) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Jazakumullah khairan katsiran atas donasi Anda. Dana telah dialokasikan untuk operasional anak asuh.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Info Table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildInfoRow('Kode Donasi', d.kode),
                const Divider(),
                _buildInfoRow('Kategori', d.kategori?.nama ?? 'Umum'),
                const Divider(),
                _buildInfoRow('Tanggal Dibuat', Formatters.date(d.createdAt)),
                if (d.dibayarPada != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Tanggal Lunas',
                    Formatters.date(d.dibayarPada),
                  ),
                ],
                if (d.payment?.orderId != null) ...[
                  const Divider(),
                  _buildInfoRow('Order ID Midtrans', d.payment!.orderId),
                ],
                if (d.biayaFormatted != null) ...[
                  const Divider(),
                  _buildInfoRow('Biaya Transaksi', d.biayaFormatted!),
                ],
                if (d.sumberBiaya != null) ...[
                  const Divider(),
                  _buildInfoRow('Tanggungan Biaya', d.sumberBiaya!),
                ],
                if (d.catatan != null && d.catatan!.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow('Doa / Catatan', d.catatan!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons if Pending
          if (d.isPending) ...[
            if (d.canPay) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openDonationPayment(context, d.id),
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: const Text('Lanjutkan Pembayaran via Midtrans'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_checkingStatus || _cancelling)
                    ? null
                    : _checkPaymentStatus,
                icon: _checkingStatus
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Periksa Status Pembayaran Terkini'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: (_checkingStatus || _cancelling)
                    ? null
                    : _confirmCancel,
                icon: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.close_rounded, color: AppColors.error),
                label: const Text('Batalkan Pembayaran'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
