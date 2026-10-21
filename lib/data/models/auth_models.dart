// lib/data/models/auth_models.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String accountStatus;
  final String? emailVerifiedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.emailVerifiedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    accountStatus: json['account_status'] as String,
    emailVerifiedAt: json['email_verified_at'] as String?,
  );
}

class DonaturModel {
  final int id;
  final String nama;
  final String whatsapp;
  final String? email;
  final String jenis;

  const DonaturModel({
    required this.id,
    required this.nama,
    required this.whatsapp,
    this.email,
    required this.jenis,
  });

  factory DonaturModel.fromJson(Map<String, dynamic> json) => DonaturModel(
    id: json['id'] as int,
    nama: json['nama'] as String,
    whatsapp: json['whatsapp'] as String,
    email: json['email'] as String?,
    jenis: json['jenis'] as String,
  );
}

class LoginResponse {
  final String token;
  final String tokenType;
  final UserModel user;
  final DonaturModel? donor;

  const LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
    this.donor,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] as String,
    tokenType: json['token_type'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    donor: json['donor'] != null
        ? DonaturModel.fromJson(json['donor'] as Map<String, dynamic>)
        : null,
  );
}
