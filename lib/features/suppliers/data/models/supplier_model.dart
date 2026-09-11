import 'dart:convert';

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
    super.categoryIds = const [],
  });

  static List<int> _readCategoryIds(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return _toCategoryIds(value);
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return [];
      }

      try {
        final decoded = jsonDecode(text);

        if (decoded is List) {
          return _toCategoryIds(decoded);
        }
      } catch (_) {
        // Fall back to comma-separated IDs below.
      }

      return _toCategoryIds(text.split(','));
    }

    return _toCategoryIds([value]);
  }

  static List<int> _toCategoryIds(Iterable<dynamic> values) {
    final ids = <int>{};

    for (final value in values) {
      final id = int.tryParse(value.toString().trim());

      if (id != null && id > 0) {
        ids.add(id);
      }
    }

    return ids.toList();
  }

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final categoryIds = _readCategoryIds(json['category_ids']);

    return SupplierModel(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0),

      supplierCode: json['supplier_code']?.toString() ?? '',

      image: json['image']?.toString(),

      supplierName: json['supplier_name']?.toString() ?? '',

      companyName: json['company_name']?.toString(),

      contactPerson: json['contact_person']?.toString(),

      phone: json['phone']?.toString(),

      alternatePhone: json['alternate_phone']?.toString(),

      email: json['email']?.toString(),

      gstNumber: json['gst_number']?.toString(),

      panNumber: json['pan_number']?.toString(),

      address: json['address']?.toString(),

      city: json['city']?.toString(),

      state: json['state']?.toString(),

      country: json['country']?.toString() ?? 'India',

      postalCode: json['postal_code']?.toString(),

      openingBalance: double.tryParse(
            json['opening_balance']?.toString() ?? '0',
          ) ??
          0.0,

      currentBalance: double.tryParse(
            json['current_balance']?.toString() ?? '0',
          ) ??
          0.0,

      creditLimit: double.tryParse(
            json['credit_limit']?.toString() ?? '0',
          ) ??
          0.0,

      notes: json['notes']?.toString(),

      status: json['status']?.toString() ?? 'ACTIVE',

      categoryIds: categoryIds,
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

      // Supplier ↔ product_categories relationship.
      'category_ids': categoryIds,
    };
  }
}
