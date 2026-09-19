// lib/features/services/data/models/provider_recharge_answer_model.dart
import '../../domain/entities/provider_recharge.dart';

class ProviderRechargeAnswerModel extends ProviderRechargeAnswerEntity {
  ProviderRechargeAnswerModel({
    required super.questionId,
    required super.label,
    required super.value,
  });

  Map<String, dynamic> toMap() => {
        'question_id': questionId,
        'label': label,
        'value': value,
      };

  factory ProviderRechargeAnswerModel.fromMap(Map<String, dynamic> map) {
    return ProviderRechargeAnswerModel(
      questionId: int.tryParse(map['question_id']?.toString() ?? '') ?? 0,
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}
