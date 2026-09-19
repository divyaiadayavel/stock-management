// lib/features/settings/service_management/domain/entities/service_category.dart
import '../enums/service_category_type.dart';

class ServiceCategoryEntity {
  final int id;
  final String name;

  /// Which tab this category belongs to.
  final ServiceCategoryType type;

  /// Active services in this category (only meaningful for SERVICE).
  final int servicesCount;

  /// Active providers in this category (only meaningful for PROVIDER).
  final int providersCount;

  const ServiceCategoryEntity({
    required this.id,
    required this.name,
    this.type = ServiceCategoryType.service,
    this.servicesCount = 0,
    this.providersCount = 0,
  });

  /// The count that belongs on this category's tile — services for a
  /// Service category, providers for a Provider category.
  int get itemCount =>
      type.isProvider ? providersCount : servicesCount;

  /// "3 Services" / "1 Provider".
  String get itemCountLabel {
    final count = itemCount;
    final noun = count == 1 ? type.itemLabel : type.itemLabelPlural;

    return '$count $noun';
  }
}
