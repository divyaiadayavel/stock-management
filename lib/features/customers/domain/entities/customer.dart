class CustomerEntity {
  final int? id;
  final String customerCode;
  final String customerName;
  final String phone;
  final String alternatePhone;
  final String email;
  final String gstNumber;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double openingBalance;
  final double currentBalance;
  final int loyaltyPoints;
  final String notes;
  final String status;

  const CustomerEntity({
    this.id,
    required this.customerCode,
    required this.customerName,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.gstNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.openingBalance,
    required this.currentBalance,
    required this.loyaltyPoints,
    required this.notes,
    required this.status,
  });

  /// Helper copyWith method for pure domain state immutability transformations
  CustomerEntity copyWith({
    int? id,
    String? customerCode,
    String? customerName,
    String? phone,
    String? alternatePhone,
    String? email,
    String? gstNumber,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? openingBalance,
    double? currentBalance,
    int? loyaltyPoints,
    String? notes,
    String? status,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}