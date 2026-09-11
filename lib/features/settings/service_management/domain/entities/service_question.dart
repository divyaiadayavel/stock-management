// lib/features/settings/service_management/domain/entities/service_question.dart
import '../enums/question_type.dart';

class ServiceQuestionEntity {
  /// Local id used only for reordering/editing in the builder UI before
  /// the service is saved. The server assigns its own numeric id on save.
  final String localId;
  final int? id;
  final String label;
  final QuestionType type;
  final bool required;

  /// Choices for multipleChoice / checkboxes / dropdown. Empty otherwise.
  final List<String> options;

  final int order;

  const ServiceQuestionEntity({
    required this.localId,
    this.id,
    required this.label,
    required this.type,
    this.required = true,
    this.options = const [],
    this.order = 0,
  });

  ServiceQuestionEntity copyWith({
    int? id,
    String? label,
    QuestionType? type,
    bool? required,
    List<String>? options,
    int? order,
  }) {
    return ServiceQuestionEntity(
      localId: localId,
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      order: order ?? this.order,
    );
  }
}
