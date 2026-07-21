import '../../domain/entities/supplier.dart';

class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.supplierCode,
    super.image,
    required super.supplierName,
    super.companyName,
    super.contactPerson,
    super.phone,
    super.alternatePhone,
    super.email,
    super.gstNumber,
    super.panNumber,
    super.address,
    super.city,
    super.state,
    super.country,
    super.postalCode,
    required super.openingBalance,
    required super.currentBalance,
    required super.creditLimit,
    super.notes,
    required super.status,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      supplierCode: json['supplier_code'] ?? '',
      image: json['image'],
      supplierName: json['supplier_name'] ?? '',
      companyName: json['company_name'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      alternatePhone: json['alternate_phone'],
      email: json['email'],
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      postalCode: json['postal_code'],
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0.0,
      notes: json['notes'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'supplier_code': supplierCode,
      'image': image,
      'supplier_name': supplierName,
      'company_name': companyName,
      'contact_person': contactPerson,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'credit_limit': creditLimit,
      'notes': notes,
      'status': status,
    };
  }
}