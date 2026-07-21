import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class UpdateSupplier {
  final SupplierRepository repository;

  UpdateSupplier(this.repository);

  Future<void> call(Supplier supplier) async {
    return await repository.updateSupplier(supplier);
  }
}