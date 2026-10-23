import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:annuur_mobile/core/services/api_client.dart';
import 'package:annuur_mobile/data/repositories/donation_repository.dart';

final _openingPayments = <int>{};

Future<void> openDonationPayment(BuildContext context, int donationId) async {
  if (!_openingPayments.add(donationId)) return;
  try {
    final payment = await DonationRepository.preparePayment(donationId);
    final url = payment['payment_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException(
        statusCode: 503,
        message:
            'Pembayaran belum tersedia. Coba lagi nanti pada transaksi ini.',
      );
    }
    if (context.mounted) {
      await context.push(
        '/home/pay',
        extra: {
          'url': url,
          'donationId': donationId.toString(),
          'returnUrl': payment['return_url'] as String? ?? '',
        },
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Pembayaran belum dapat dibuka. Periksa koneksi dan coba lagi.',
          ),
        ),
      );
    }
  } finally {
    _openingPayments.remove(donationId);
  }
}
