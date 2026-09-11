// lib/features/settings/service_management/domain/entities/service_item.dart
import 'service_question.dart';

class ServiceEntity {
  final int? id;
  final String name;
  final int? categoryId;
  final String categoryName;
  final List<ServiceQuestionEntity> questions;

  /// ACTIVE / INACTIVE — mirrors the `status` convention used by
  /// products/customers elsewhere in the app.
  final String status;

  const ServiceEntity({
    this.id,
    required this.name,
    this.categoryId,
    required this.categoryName,
    this.questions = const [],
    this.status = 'ACTIVE',
  });

  ServiceEntity copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? categoryName,
    List<ServiceQuestionEntity>? questions,
    String? status,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      questions: questions ?? this.questions,
      status: status ?? this.status,
    );
  }
}
