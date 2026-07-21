import 'dart:io';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_remote_datasource.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDatasource remoteDataSource;
  SupplierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getSuppliersPaginated({
    required int page, required int limit, String? search, String? status, String? sort, String? order,
  }) async {
    return await remoteDataSource.fetchSuppliers(
      page: page, limit: limit, search: search, status: status, sort: sort, order: order,
    );
  }

  @override
  Future<Supplier> getSupplierById(int id) async => await remoteDataSource.fetchSupplierById(id);

  @override
  Future<int> createSupplier(Supplier supplier) async => await remoteDataSource.addSupplier(_toModel(supplier));

  @override
  Future<void> updateSupplier(Supplier supplier) async => await remoteDataSource.editSupplier(_toModel(supplier));

  @override
  Future<void> deleteSupplier(int id) async => await remoteDataSource.removeSupplier(id);

  @override
  Future<String> uploadSupplierImage(int supplierId, File imageFile) async => await remoteDataSource.uploadImage(supplierId, imageFile);

  SupplierModel _toModel(Supplier s) => SupplierModel(
        id: s.id, supplierCode: s.supplierCode, image: s.image, supplierName: s.supplierName,
        companyName: s.companyName, contactPerson: s.contactPerson, phone: s.phone,
        alternatePhone: s.alternatePhone, email: s.email, gstNumber: s.gstNumber, panNumber: s.panNumber,
        address: s.address, city: s.city, state: s.state, country: s.country, postalCode: s.postalCode,
        openingBalance: s.openingBalance, currentBalance: s.currentBalance, creditLimit: s.creditLimit,
        notes: s.notes, status: s.status,
      );
}