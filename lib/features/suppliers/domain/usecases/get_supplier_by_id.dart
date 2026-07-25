import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSupplierById {
  final SupplierRepository repository;

  GetSupplierById(this.repository);

  Future<Supplier> call(int id) async {
    return await repository.getSupplierById(id);
  }
}