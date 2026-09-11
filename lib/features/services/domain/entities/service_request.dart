// lib/features/services/domain/entities/service_request.dart
import 'service_answer.dart';

class ServiceRequestEntity {
  final int? id;
  final int serviceId;
  final String serviceName;
  final String categoryName;
  final List<ServiceAnswerEntity> answers;

  /// e.g. "PENDING" / "SUBMITTED" / "COMPLETED" — set by the backend.
  final String status;
  final String? invoiceNumber;
  final DateTime? submittedAt;

  const ServiceRequestEntity({
    this.id,
    required this.serviceId,
    required this.serviceName,
    required this.categoryName,
    required this.answers,
    this.status = 'SUBMITTED',
    this.invoiceNumber,
    this.submittedAt,
  });
}
