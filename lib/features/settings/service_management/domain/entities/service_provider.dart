// lib/features/settings/service_management/domain/entities/service_provider.dart
import 'provider_question.dart';

class ServiceProviderEntity {
  final int? id;
  final int? categoryId;
  final String categoryName;
  final String name;
  final String description;

  /// Live float balance held with this provider.
  final double balance;

  /// Below (or equal to) this, the provider is flagged as LOW.
  final double lowBalanceThreshold;

  final List<ProviderQuestionEntity> questions;

  /// ACTIVE / INACTIVE — same convention as services.
  final String status;

  const ServiceProviderEntity({
    this.id,
    this.categoryId,
    this.categoryName = '',
    required this.name,
    this.description = '',
    this.balance = 0.0,
    this.lowBalanceThreshold = 500.0,
    this.questions = const [],
    this.status = 'ACTIVE',
  });

  bool get isLowBalance => balance <= lowBalanceThreshold;

  String get healthLabel => isLowBalance ? 'Low' : 'Healthy';
}
