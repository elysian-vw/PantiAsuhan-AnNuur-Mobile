// lib/ui/screens/donation/donation_history_tab.dart

import 'package:flutter/material.dart';
import 'package:annuur_mobile/ui/screens/payment/open_payment.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';

class DonationHistoryTab extends StatefulWidget {
  const DonationHistoryTab({super.key});

  @override
  State<DonationHistoryTab> createState() => _DonationHistoryTabState();
}

class _DonationHistoryTabState extends State<DonationHistoryTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DonationProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationProvider>();
    final summary = donation.summary;
    final filteredList = donation.donations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Donasi Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Donasi Baru',
            onPressed: () => context.push('/home/donate'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            donation.loadSummary(),
            donation.loadDonations(refresh: true),
          ]);
        },
        color: AppColors.primary,
        child: Column(
          children: [
            // Summary Header Card
            if (summary != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Donasi Berhasil',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.totalNominalFormatted,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _StatBadge(
                          count: summary.countBerhasil,
                          label: 'Berhasil',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatBadge(
                          count: summary.countMenunggu,
                          label: 'Menunggu',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Berhasil', 'Menunggu'].map((f) {
                  final status = f == 'Semua'
                      ? null
                      : f == 'Menunggu'
                      ? 'Menunggu pembayaran'
                      : f;
                  final isSelected = donation.statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(f),
                      onSelected: (_) {
                        donation.setStatusFilter(status);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (donation.historyError != null)
              TextButton(
                onPressed: () =>
                    donation.loadDonations(refresh: filteredList.isEmpty),
                child: Text(
                  '${donation.historyError} Ketuk untuk mencoba lagi.',
                ),
              ),
            if (donation.donationsLoading) const LinearProgressIndicator(),
            if (donation.hasMore &&
                !donation.donationsLoading &&
                !donation.loadingMore)
              TextButton(
                onPressed: donation.loadMore,
                child: const Text('Muat berikutnya'),
              ),

            // Donations List
            Expanded(
              child: filteredList.isEmpty && !donation.donationsLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada donasi dengan filter ini',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount:
                          filteredList.length + (donation.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredList.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final d = filteredList[index];
                        final isSuccess = d.isSuccess;
                        final isPending = d.isPending;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/home/donation/${d.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        d.kode,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSuccess
                                              ? AppColors.success.withValues(
                                                  alpha: 0.1,
                                                )
                                              : isPending
                                              ? AppColors.warning.withValues(
                                                  alpha: 0.1,
                                                )
                                              : AppColors.error.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          Formatters.donationStatus(d.status),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: isSuccess
                                                    ? AppColors.success
                                                    : isPending
                                                    ? AppColors.warning
                                                    : AppColors.error,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        d.kategori?.nama ?? 'Umum',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        d.nominalFormatted,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.date(d.createdAt),
                                    style: AppTextStyles.caption,
                                  ),
                                  if (d.canPay) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => openDonationPayment(
                                            context,
                                            d.id,
                                          ),
                                          icon: const Icon(
                                            Icons.payment_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Bayar Sekarang via Midtrans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/donate'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.favorite_rounded, color: Colors.white),
        label: const Text('Donasi Baru', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
