import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/payable_remote_datasource.dart';
import '../../data/repositories/payable_repository_impl.dart';
import '../../domain/entities/supplier_detail.dart';
import '../../domain/repositories/payable_repository.dart';

// ── Dependency Injection ─────────────────────────────────────────────────
final payableRemoteDataSourceProvider = Provider<PayableRemoteDataSource>((ref) {
  return PayableRemoteDataSourceImpl(client: Dio());
});

final payableRepositoryProvider = Provider<PayableRepository>((ref) {
  final remoteDataSource = ref.watch(payableRemoteDataSourceProvider);
  return PayableRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ── Single supplier detail (Payable Details screen) ──────────────────────
// The supplier LIST itself is intentionally read from the Suppliers
// feature (`suppliersNotifierProvider`) — see payable_screen.dart for why.
// This provider only supplies the purchase-order breakdown, which is
// unique to reports.php's `supplier_detail` action.
final supplierDetailProvider = FutureProvider.family<SupplierDetail, String>((
  ref,
  supplierId,
) async {
  final repo = ref.watch(payableRepositoryProvider);
  return await repo.getSupplierDetail(supplierId);
});
