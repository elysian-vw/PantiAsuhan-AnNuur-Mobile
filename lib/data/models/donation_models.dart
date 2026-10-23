// lib/data/models/donation_models.dart

class DonationCategoryModel {
  final int id;
  final String nama;
  final String? deskripsi;

  const DonationCategoryModel({
    required this.id,
    required this.nama,
    this.deskripsi,
  });

  factory DonationCategoryModel.fromJson(Map<String, dynamic> json) =>
      DonationCategoryModel(
        id: json['id'] as int,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String?,
      );
}

class PaymentInfo {
  final String orderId;
  final String status;
  final String? metode;
  final String? snapToken;
  final String? paymentUrl;

  const PaymentInfo({
    required this.orderId,
    required this.status,
    this.metode,
    this.snapToken,
    this.paymentUrl,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
    orderId: json['order_id'] as String,
    status: json['status'] as String? ?? 'pending',
    metode: json['metode'] as String?,
    snapToken: json['snap_token'] as String?,
    paymentUrl: json['payment_url'] as String?,
  );
}

class DonationModel {
  final int id;
  final String kode;
  final String nominal;
  final String nominalFormatted;
  final String? biaya;
  final String? biayaFormatted;
  final String? sumberBiaya;
  final String status;
  final String? dibayarPada;
  final String? createdAt;
  final String? catatan;
  final DonationCategoryModel? kategori;
  final PaymentInfo? payment;

  const DonationModel({
    required this.id,
    required this.kode,
    required this.nominal,
    required this.nominalFormatted,
    this.biaya,
    this.biayaFormatted,
    this.sumberBiaya,
    required this.status,
    this.dibayarPada,
    this.createdAt,
    this.catatan,
    this.kategori,
    this.payment,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) => DonationModel(
    id: json['id'] as int,
    kode: json['kode'] as String,
    nominal: json['nominal'] as String,
    nominalFormatted: json['nominal_formatted'] as String,
    biaya: json['biaya'] as String?,
    biayaFormatted: json['biaya_formatted'] as String?,
    sumberBiaya: json['sumber_biaya'] as String?,
    status: json['status'] as String,
    dibayarPada: json['dibayar_pada'] as String?,
    createdAt: json['created_at'] as String?,
    catatan: json['catatan'] as String?,
    kategori: json['kategori'] != null
        ? DonationCategoryModel.fromJson(
            json['kategori'] as Map<String, dynamic>,
          )
        : null,
    payment: json['payment'] != null
        ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>)
        : null,
  );

  bool get isSuccess => status == 'Berhasil';
  bool get isPending => status == 'Menunggu pembayaran';
  bool get isFailed => status == 'Gagal' || status == 'Kedaluwarsa';
  bool get isCancelled => status == 'Dibatalkan';
  bool get canPay => isPending && payment != null;
  bool get canCancel => isPending;
}

class DonationSummaryModel {
  final String totalNominalBerhasil;
  final String totalNominalFormatted;
  final int countBerhasil;
  final int countMenunggu;
  final int countTotal;

  const DonationSummaryModel({
    required this.totalNominalBerhasil,
    required this.totalNominalFormatted,
    required this.countBerhasil,
    required this.countMenunggu,
    required this.countTotal,
  });

  factory DonationSummaryModel.fromJson(Map<String, dynamic> json) =>
      DonationSummaryModel(
        totalNominalBerhasil: json['total_nominal_berhasil'] as String,
        totalNominalFormatted: json['total_nominal_formatted'] as String,
        countBerhasil: json['count_berhasil'] as int,
        countMenunggu: json['count_menunggu'] as int,
        countTotal: json['count_total'] as int,
      );
}

class PaginatedDonations {
  final List<DonationModel> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedDonations({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedDonations.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>;
    return PaginatedDonations(
      data: rawData
          .map((e) => DonationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      total: json['total'] as int,
    );
  }

  bool get hasMore => currentPage < lastPage;
}
