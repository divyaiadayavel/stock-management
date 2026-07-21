import '../../domain/entities/customer.dart';

class CustomerModel extends CustomerEntity {
  CustomerModel({
    super.id,
    required super.customerCode,
    required super.customerName,
    required super.phone,
    required super.alternatePhone,
    required super.email,
    required super.gstNumber,
    required super.address,
    required super.city,
    required super.state,
    required super.country,
    required super.postalCode,
    required super.openingBalance,
    required super.currentBalance,
    required super.loyaltyPoints,
    required super.notes,
    required super.status,
  });

  // Convert model instance properties into map parameters matching the backend API keys
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_code': customerCode,
      'customer_name': customerName,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'gst_number': gstNumber,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'loyalty_points': loyaltyPoints,
      'notes': notes,
      'status': status,
    };
  }

  // Parse incoming Map rows safely into concrete, type-safe data model structures
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      customerCode: map['customer_code']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      alternatePhone: map['alternate_phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      gstNumber: map['gst_number']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      postalCode: map['postal_code']?.toString() ?? '',
      openingBalance: double.tryParse(map['opening_balance']?.toString() ?? '0.0') ?? 0.0,
      currentBalance: double.tryParse(map['current_balance']?.toString() ?? '0.0') ?? 0.0,
      loyaltyPoints: int.tryParse(map['loyalty_points'].toString()) ?? 0,
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}