import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/usecases/create_sale.dart';
import '../../domain/usecases/get_invoice.dart';

final salesHttpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final salesRemoteDataSourceProvider = Provider<SalesRemoteDataSource>((ref) {
  return SalesRemoteDataSource(
    client: ref.read(salesHttpClientProvider),
  );
});

final salesRepositoryProvider = Provider<SalesRepositoryImpl>((ref) {
  return SalesRepositoryImpl(
    remoteDataSource: ref.read(salesRemoteDataSourceProvider),
  );
});

final createSaleUseCaseProvider = Provider<CreateSale>((ref) {
  return CreateSale(
    ref.read(salesRepositoryProvider),
  );
});

final getInvoiceUseCaseProvider = Provider<GetInvoice>((ref) {
  return GetInvoice(
    ref.read(salesRepositoryProvider),
  );
});