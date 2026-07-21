import 'dart:io';
import '../repositories/supplier_repository.dart';

class UploadSupplierImage {
  final SupplierRepository repository;

  UploadSupplierImage(this.repository);

  Future<String> call(int supplierId, File imageFile) async {
    return await repository.uploadSupplierImage(supplierId, imageFile);
  }
}