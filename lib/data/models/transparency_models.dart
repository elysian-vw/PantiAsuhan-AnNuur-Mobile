// lib/data/models/transparency_models.dart

class CashflowSummaryModel {
  final int month;
  final int year;
  final String totalPemasukan;
  final String totalPengeluaran;
  final String saldo;
  final String totalPemasukanFormatted;
  final String totalPengeluaranFormatted;
  final String saldoFormatted;

  const CashflowSummaryModel({
    required this.month,
    required this.year,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.saldo,
    required this.totalPemasukanFormatted,
    required this.totalPengeluaranFormatted,
    required this.saldoFormatted,
  });

  factory CashflowSummaryModel.fromJson(Map<String, dynamic> json) =>
      CashflowSummaryModel(
        month: (json['periode'] as Map<String, dynamic>)['bulan'] as int,
        year: (json['periode'] as Map<String, dynamic>)['tahun'] as int,
        totalPemasukan: json['total_penerimaan'] as String,
        totalPengeluaran: json['total_pengeluaran'] as String,
        saldo: json['saldo_akhir'] as String,
        totalPemasukanFormatted: json['total_penerimaan_formatted'] as String,
        totalPengeluaranFormatted:
            json['total_pengeluaran_formatted'] as String,
        saldoFormatted: json['saldo_akhir_formatted'] as String,
      );
}

class ExpenseModel {
  final int id;
  final String tanggal;
  final String nominal;
  final String nominalFormatted;
  final String keterangan;
  final bool isPublic;
  final String? buktiUrl;
  final String? kategori;
  final String? createdBy;

  const ExpenseModel({
    required this.id,
    required this.tanggal,
    required this.nominal,
    required this.nominalFormatted,
    required this.keterangan,
    required this.isPublic,
    this.buktiUrl,
    this.kategori,
    this.createdBy,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'] as int,
    tanggal: json['tanggal'] as String,
    nominal: json['nominal'] as String,
    nominalFormatted: json['nominal_formatted'] as String,
    keterangan: json['keperluan'] as String,
    isPublic: json['has_public_proof'] as bool,
    buktiUrl: json['bukti_url'] as String?,
    kategori: (json['kategori'] as Map<String, dynamic>?)?['nama'] as String?,
    createdBy: json['created_by'] as String?,
  );
}
