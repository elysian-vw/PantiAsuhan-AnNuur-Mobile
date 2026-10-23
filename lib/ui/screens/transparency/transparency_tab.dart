// lib/ui/screens/transparency/transparency_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:annuur_mobile/core/config/app_config.dart';
import 'package:annuur_mobile/core/services/auth_storage.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/data/models/transparency_models.dart';
import 'package:annuur_mobile/providers/transparency_provider.dart';

class TransparencyTab extends StatelessWidget {
  const TransparencyTab({super.key});

  void _showProofDialog(BuildContext context, ExpenseModel expense) async {
    final token = await AuthStorage.getToken();
    final proofApiUrl =
        '${AppConfig.apiBaseUrl}/transparency/expenses/${expense.id}/proof';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Bukti Pengeluaran',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                expense.keterangan,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${Formatters.date(expense.tanggal)} • ${expense.nominalFormatted}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 340),
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: CachedNetworkImage(
                    imageUrl: proofApiUrl,
                    httpHeaders: {
                      if (token != null) 'Authorization': 'Bearer $token',
                      'Accept': 'image/*',
                    },
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.error,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Berkas bukti tidak dapat dimuat atau berformat non-gambar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transparency = context.watch<TransparencyProvider>();
    final cashflow = transparency.cashflow;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transparansi Kas Panti')),
      body: RefreshIndicator(
        onRefresh: () => transparency.loadForMonth(
          month: transparency.selectedMonth,
          year: transparency.selectedYear,
        ),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                      onPressed: () => transparency.prevMonth(),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.monthYear(
                            transparency.selectedMonth,
                            transparency.selectedYear,
                          ),
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                      ),
                      onPressed: () => transparency.nextMonth(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Financial Cards
              if (cashflow != null) ...[
                if (cashflow.isProvisional)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(cashflow.calculationNotice),
                  ),
                // Saldo Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Akhir Kas Panti',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cashflow.saldoFormatted,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ringkasan donasi masuk dan penggunaan dana panti pada bulan ini.',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Inflow vs Outflow Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text('Pemasukan', style: AppTextStyles.caption),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cashflow.totalPemasukanFormatted,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pengeluaran',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cashflow.totalPengeluaranFormatted,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Title Section Pengeluaran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Catatan pengeluaran', style: AppTextStyles.titleMedium),
                  Text(
                    '${transparency.expenses.length} Catatan',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (transparency.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (transparency.expenses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(
                    child: Text(
                      'Tidak ada pengeluaran pada bulan ini.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                )
              else
                ...transparency.expenses.map((exp) {
                  final hasProof = exp.isPublic && exp.buktiUrl != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.keterangan,
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${Formatters.date(exp.tanggal)}${exp.kategori != null ? " • ${exp.kategori}" : ""}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              exp.nominalFormatted,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (hasProof) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Nota/Kwitansi Terlampir',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showProofDialog(context, exp),
                                icon: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 14,
                                ),
                                label: const Text('Lihat Bukti'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
