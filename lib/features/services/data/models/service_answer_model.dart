// lib/features/services/data/models/service_answer_model.dart
import '../../domain/entities/service_answer.dart';

class ServiceAnswerModel extends ServiceAnswerEntity {
  ServiceAnswerModel({
    required super.questionId,
    required super.label,
    required super.value,
  });

  Map<String, dynamic> toMap() => {'question_id': questionId, 'label': label, 'value': value};

  factory ServiceAnswerModel.fromMap(Map<String, dynamic> map) {
    return ServiceAnswerModel(
      questionId: int.tryParse(map['question_id']?.toString() ?? '') ?? 0,
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}
