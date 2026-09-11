import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int id;
  final String supplierCode;
  final String? image;
  final String supplierName;
  final String? companyName;
  final String? contactPerson;
  final String? phone;
  final String? alternatePhone;
  final String? email;
  final String? gstNumber;
  final String? panNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double openingBalance;
  final double currentBalance;
  final double creditLimit;
  final String? notes;
  final String status;

  // Supplier category IDs from product_categories.
  final List<int> categoryIds;

  const Supplier({
    required this.id,
    required this.supplierCode,
    this.image,
    required this.supplierName,
    this.companyName,
    this.contactPerson,
    this.phone,
    this.alternatePhone,
    this.email,
    this.gstNumber,
    this.panNumber,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    required this.openingBalance,
    required this.currentBalance,
    required this.creditLimit,
    this.notes,
    required this.status,
    this.categoryIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        supplierCode,
        image,
        supplierName,
        companyName,
        contactPerson,
        phone,
        alternatePhone,
        email,
        gstNumber,
        panNumber,
        address,
        city,
        state,
        country,
        postalCode,
        openingBalance,
        currentBalance,
        creditLimit,
        notes,
        status,
        categoryIds,
      ];
}