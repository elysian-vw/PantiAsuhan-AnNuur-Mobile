// lib/ui/screens/profile/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun donatur tetap ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showPantiInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panti Asuhan NU An-Nuur 2', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Alamat: Jl. KH. Hasyim Asy\'ari No. 42, Kota Kediri, Jawa Timur\nTelepon: (0354) 771234 / 0812-3456-7890\nRekening Donasi: Bank Syariah Indonesia (BSI)\nNo. Rekening: 7123456789 a.n. Panti Asuhan NU An-Nuur',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            ),
            const SizedBox(height: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final donor = auth.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akun Donatur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Donor Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (donor?.nama ?? user?.name ?? 'D')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    donor?.nama ?? user?.name ?? '-',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '-',
                    style: AppTextStyles.caption.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donor?.whatsapp ?? '-',
                    style: AppTextStyles.caption.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Donatur Tetap Terverifikasi',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Menu
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Ubah Profil'),
                    subtitle: const Text('Nama & Nomor WhatsApp'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/home/edit-profile'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Ganti Kata Sandi'),
                    subtitle: const Text('Perbarui keamanan akun'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/home/change-password'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Informasi Panti Asuhan'),
                    subtitle: const Text('Alamat & rekening resmi'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showPantiInfo(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
