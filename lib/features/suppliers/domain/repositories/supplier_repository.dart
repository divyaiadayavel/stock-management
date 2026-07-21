import 'dart:io';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<Map<String, dynamic>> getSuppliersPaginated({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? sort,
    String? order,
  });
  Future<Supplier> getSupplierById(int id);
  Future<int> createSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(int id);
  Future<String> uploadSupplierImage(int supplierId, File imageFile);
}