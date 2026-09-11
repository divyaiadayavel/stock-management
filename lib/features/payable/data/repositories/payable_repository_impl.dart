import '../../domain/entities/payable_supplier.dart';
import '../../domain/entities/supplier_detail.dart';
import '../../domain/repositories/payable_repository.dart';
import '../datasources/payable_remote_datasource.dart';

class PayableRepositoryImpl implements PayableRepository {
  final PayableRemoteDataSource remoteDataSource;

  PayableRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PayableSupplier>> getPayableSuppliers() async {
    return await remoteDataSource.getPayableSuppliers();
  }

  @override
  Future<SupplierDetail> getSupplierDetail(
    String supplierId, {
    String period = 'all',
  }) async {
    return await remoteDataSource.getSupplierDetail(supplierId, period: period);
  }
}
