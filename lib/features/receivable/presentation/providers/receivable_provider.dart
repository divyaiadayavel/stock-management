import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/receivable_remote_datasource.dart';
import '../../data/repositories/receivable_repository_impl.dart';
import '../../domain/entities/customer_detail.dart';
import '../../domain/repositories/receivable_repository.dart';

// ── Dependency Injection ─────────────────────────────────────────────────
final receivableRemoteDataSourceProvider = Provider<ReceivableRemoteDataSource>((ref) {
  return ReceivableRemoteDataSourceImpl(client: Dio());
});

final receivableRepositoryProvider = Provider<ReceivableRepository>((ref) {
  final remoteDataSource = ref.watch(receivableRemoteDataSourceProvider);
  return ReceivableRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ── Single customer detail (Receivable Details screen) ──────────────────
// The customer LIST itself is intentionally read from the Customers
// feature (`allCustomersProvider`) — see receivable_screen.dart for why.
// This provider only supplies the bill breakdown, which is unique to
// reports.php's `customer_detail` action.
final customerDetailProvider = FutureProvider.family<CustomerDetail, String>((
  ref,
  customerId,
) async {
  final repo = ref.watch(receivableRepositoryProvider);
  return await repo.getCustomerDetail(customerId);
});
