// lib/features/settings/service_management/data/models/service_category_model.dart
import '../../domain/entities/service_category.dart';

class ServiceCategoryModel extends ServiceCategoryEntity {
  final String? description;

  ServiceCategoryModel({
    super.id = 0,
    required super.name,
    this.description,
    super.servicesCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      if (description != null && description!.isNotEmpty)
        'description': description!.trim(),
    };
  }

  factory ServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return ServiceCategoryModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      name:
          map['name']?.toString().trim() ??
          map['category_name']?.toString().trim() ??
          '',
      description:
          map['description']?.toString().trim() ??
          map['note']?.toString().trim(),
      servicesCount:
          int.tryParse(map['services_count']?.toString() ?? '0') ?? 0,
    );
  }
}
