// lib/features/settings/service_management/data/repositories/service_provider_repository_impl.dart
import '../../domain/repositories/service_provider_repository.dart';
import '../datasources/service_provider_remote_datasource.dart';
import '../models/service_provider_model.dart';

class ServiceProviderRepositoryImpl implements ServiceProviderRepository {
  final ServiceProviderRemoteDataSource remote;

  ServiceProviderRepositoryImpl(this.remote);

  @override
  Future<List<ServiceProviderModel>> getProviders({int? categoryId}) =>
      remote.getProviders(categoryId: categoryId);

  @override
  Future<ServiceProviderModel> getProviderDetail(int id) =>
      remote.getProviderDetail(id);

  @override
  Future<ServiceProviderModel> createProvider(ServiceProviderModel provider) =>
      remote.createProvider(provider);

  @override
  Future<ServiceProviderModel> updateProvider(ServiceProviderModel provider) =>
      remote.updateProvider(provider);

  @override
  Future<bool> deleteProvider(int id) => remote.deleteProvider(id);

  @override
  Future<ServiceProviderModel> reloadBalance(
    int id,
    double amount, {
    String? note,
  }) =>
      remote.reloadBalance(id, amount, note: note);
}
