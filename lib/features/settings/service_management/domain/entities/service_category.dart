// lib/features/settings/service_management/domain/entities/service_category.dart

class ServiceCategoryEntity {
  final int id;
  final String name;
  final int servicesCount;

  const ServiceCategoryEntity({
    required this.id,
    required this.name,
    this.servicesCount = 0,
  });
}
