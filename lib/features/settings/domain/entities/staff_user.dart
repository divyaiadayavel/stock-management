class StaffUser {
  const StaffUser({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.password = '',
    this.isActive = true,
  });

  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String password;
  final bool isActive;

  Map<String, dynamic> toMap() {
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
}
