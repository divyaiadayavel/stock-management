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

  StaffUser copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? password,
    bool? isActive,
  }) {
    return StaffUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
    );
  }

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
