// lib/ui/screens/donation/create_donation_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/config/app_config.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/core/utils/formatters.dart';
import 'package:annuur_mobile/data/models/donation_models.dart';
import 'package:annuur_mobile/providers/donation_provider.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();

  DonationCategoryModel? _selectedCategory;
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final donation = context.read<DonationProvider>();
      if (donation.categories.isEmpty) {
        donation.loadCategories().then((_) {
          if (mounted && donation.categories.isNotEmpty) {
            setState(() {
              _selectedCategory = donation.categories.first;
            });
          }
        });
      } else {
        setState(() {
          _selectedCategory = donation.categories.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _onSelectPreset(int nominal) {
    setState(() {
      _selectedPreset = nominal;
      _nominalController.text = nominal.toString();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori donasi terlebih dahulu')),
      );
      return;
    }

    final nominal =
        int.tryParse(
          _nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (nominal < AppConfig.minimumNominal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal donasi minimal ${Formatters.currency(AppConfig.minimumNominal)}',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final donationProvider = context.read<DonationProvider>();
    final result = await donationProvider.createDonation(
      kategoriId: _selectedCategory!.id,
      nominal: nominal,
      catatan: _catatanController.text.trim().isNotEmpty
          ? _catatanController.text.trim()
          : null,
    );

    if (result != null && mounted) {
      final data = result['data'] as Map<String, dynamic>;
      final payment = data['payment'] as Map<String, dynamic>;
      final paymentUrl = payment['payment_url'] as String?;
      final donationId = data['id'] as int;

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        context.pushReplacement(
          '/home/pay',
          extra: {'url': paymentUrl, 'donationId': donationId.toString()},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donasi berhasil dibuat.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = context.watch<DonationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Salurkan Donasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (donation.createError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          donation.createError!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Pilih Kategori Donasi
              Text('Pilih Peruntukan Donasi', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),

              if (donation.categoriesLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: donation.categories.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(cat.nama),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                        });
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
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // 2. Nominal Donasi
              Text('Pilih Nominal Donasi', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),

              // Preset Buttons Grid
              GridView.count(
                crossAxisCount:
                    MediaQuery.sizeOf(context).width < 360 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19
                    ? 2
                    : 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 64,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: AppConfig.nominalPresets.map((nominal) {
                  final isSelected = _selectedPreset == nominal;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _onSelectPreset(nominal),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          Formatters.currency(nominal),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Input Nominal Kustom
              Text(
                'Atau Masukkan Nominal Lainnya (Rp)',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp  ',
                  prefixStyle: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: '100000',
                ),
                onChanged: (_) {
                  setState(() {
                    _selectedPreset = null;
                  });
                },
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Nominal donasi wajib diisi';
                  }
                  final parsed = int.tryParse(
                    v.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  if (parsed == null || parsed < AppConfig.minimumNominal) {
                    return 'Minimal donasi ${Formatters.currency(AppConfig.minimumNominal)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Catatan / Doa Donatur
              Text('Doa / Catatan (Opsional)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan niat donasi, doa, atau pesan untuk anak-anak panti...',
                ),
              ),
              const SizedBox(height: 24),

              // Security & Midtrans Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pilih metode pembayaran pada langkah berikutnya. Pembayaran diproses melalui Midtrans.',
                        style: AppTextStyles.caption.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: donation.creating ? null : _handleSubmit,
                  child: donation.creating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lanjutkan Pembayaran'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
