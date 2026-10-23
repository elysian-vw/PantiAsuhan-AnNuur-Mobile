// lib/ui/screens/home/home_tab.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';
import 'package:annuur_mobile/providers/transparency_provider.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToTransparency;
  final VoidCallback onNavigateToHistory;

  const HomeTab({
    super.key,
    required this.onNavigateToTransparency,
    required this.onNavigateToHistory,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    await Future.wait([
      context.read<DonationProvider>().loadSummary(),
      context.read<DonationProvider>().loadDonations(refresh: true),
      context.read<DonationProvider>().loadCategories(),
      context.read<TransparencyProvider>().loadForMonth(
        month: now.month,
        year: now.year,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final donation = context.watch<DonationProvider>();
    final transparency = context.watch<TransparencyProvider>();
    final donorName = auth.donor?.nama ?? auth.user?.name ?? 'Donatur';
    final cashflow = transparency.cashflow;

    return Scaffold(
      appBar: AppBar(
        title: Text('An-Nuur 2', style: AppTextStyles.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'KOTA KEDIRI',
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.5),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalamu’alaikum,', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(donorName, style: AppTextStyles.displayLarge),
              const SizedBox(height: 10),
              Text(
                'Terima kasih telah menjadi bagian dari keluarga An-Nuur.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donasi yang telah tersalurkan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      donation.summary?.totalNominalFormatted ?? '—',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      donation.summaryLoading
                          ? 'Memuat ringkasan…'
                          : donation.summary == null
                          ? 'Ringkasan belum tersedia'
                          : '${donation.summary!.countBerhasil} donasi berhasil',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/home/donate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Salurkan donasi')),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeading(
                title: 'Kas panti',
                action: 'Lihat laporan',
                onTap: widget.onNavigateToTransparency,
              ),
              Text(
                Formatters.monthYear(
                  transparency.selectedMonth,
                  transparency.selectedYear,
                ),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 18),
              if (cashflow != null) ...[
                if (cashflow.isProvisional)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(cashflow.calculationNotice),
                  ),
                Text('Saldo berjalan', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  cashflow.saldoFormatted,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final values = [
                      _CashValue(
                        label: 'Pemasukan',
                        value: cashflow.totalPemasukanFormatted,
                        icon: Icons.south_west,
                        color: AppColors.primary,
                      ),
                      _CashValue(
                        label: 'Pengeluaran',
                        value: cashflow.totalPengeluaranFormatted,
                        icon: Icons.north_east,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ];
                    if (constraints.maxWidth < 340 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          values[0],
                          const SizedBox(height: 16),
                          values[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: values[0]),
                        const SizedBox(width: 16),
                        Expanded(child: values[1]),
                      ],
                    );
                  },
                ),
              ] else if (transparency.loading)
                const LinearProgressIndicator(minHeight: 2)
              else
                Text(
                  'Laporan belum dapat ditampilkan. Tarik ke bawah untuk memuat ulang.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _SectionHeading(
                title: 'Donasi terakhir',
                action: 'Lihat semua',
                onTap: widget.onNavigateToHistory,
              ),
              const SizedBox(height: 8),
              if (donation.donationsLoading)
                const LinearProgressIndicator(minHeight: 2)
              else if (donation.donations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum ada donasi yang ditampilkan',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat dan status pembayaran Anda akan muncul di sini.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...donation.donations.take(4).map((d) {
                  final color = d.isSuccess
                      ? AppColors.success
                      : d.isPending
                      ? AppColors.warning
                      : AppColors.error;
                  return InkWell(
                    onTap: () => context.push('/home/donation/${d.id}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.nominalFormatted,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                '${d.kategori?.nama ?? "Umum"} · ${Formatters.dateShort(d.createdAt)}',
                                style: AppTextStyles.caption,
                              ),
                              Text(
                                Formatters.donationStatus(d.status),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _CashValue extends StatelessWidget {
  const _CashValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: AppTextStyles.caption)),
        ],
      ),
      const SizedBox(height: 6),
      Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
    ],
  );
}
