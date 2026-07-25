import '../repositories/supplier_repository.dart';

class DeleteSupplier {
  final SupplierRepository repository;

  DeleteSupplier(this.repository);

  Future<void> call(int id) async {
    return await repository.deleteSupplier(id);
  }
}