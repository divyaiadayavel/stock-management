// lib/features/services/domain/entities/service_answer.dart

/// One answered question inside a submitted [ServiceRequestEntity].
/// `value` is stored as a String for short/paragraph/dropdown/date/time/
/// file-path answers, and as a comma-joined String for checkboxes —
/// the exact same shape the PHP backend will persist and echo back for
/// the Review & Receipt screens.
class ServiceAnswerEntity {
  final int questionId;
  final String label;
  final String value;

  const ServiceAnswerEntity({
    required this.questionId,
    required this.label,
    required this.value,
  });
}
