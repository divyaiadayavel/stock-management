import '../repositories/supplier_repository.dart';

class GetSuppliersPaginated {
  final SupplierRepository repository;
  GetSuppliersPaginated(this.repository);

  Future<Map<String, dynamic>> call({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) {
    return repository.getSuppliersPaginated(
      page: page,
      limit: limit,
      search: search,
      status: status,
      sort: sort,
      order: order,
    );
  }
}