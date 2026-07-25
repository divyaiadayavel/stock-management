import '../../domain/entities/staff_user.dart';

class StaffUserModel extends StaffUser {
  const StaffUserModel({
    super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.password,
    super.isActive,
  });

  factory StaffUserModel.fromEntity(StaffUser user) {
    return StaffUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      password: user.password,
      isActive: user.isActive,
    );
  }

  factory StaffUserModel.fromJson(Map<String, dynamic> json) {
    return StaffUserModel(
      id: _readInt(json['id']),
      name: _readString(json, 'name'),
      email: _readString(json, 'email'),
      phone: _readString(json, 'phone', alternateKey: 'phone_number'),
      role: _readString(json, 'role', fallback: 'Staff'),
      isActive: _readBool(json['isActive'] ?? json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      if (password.isNotEmpty) 'password': password,
      'isActive': isActive,
    };
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _readBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    String? alternateKey,
    String? fallback,
  }) {
    final value = json[key] ?? json[alternateKey];
    if (value == null) return fallback ?? '';
    return value.toString();
  }
}