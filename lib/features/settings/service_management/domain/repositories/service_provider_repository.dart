// lib/features/settings/service_management/domain/repositories/service_provider_repository.dart
import '../../data/models/service_provider_model.dart';

abstract class ServiceProviderRepository {
  Future<List<ServiceProviderModel>> getProviders({int? categoryId});
  Future<ServiceProviderModel> getProviderDetail(int id);
  Future<ServiceProviderModel> createProvider(ServiceProviderModel provider);
  Future<ServiceProviderModel> updateProvider(ServiceProviderModel provider);
  Future<bool> deleteProvider(int id);
  Future<ServiceProviderModel> reloadBalance(int id, double amount, {String? note});
}
