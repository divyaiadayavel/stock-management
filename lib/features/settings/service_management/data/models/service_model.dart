// lib/features/settings/service_management/data/models/service_model.dart

import '../../domain/entities/service_item.dart';
import 'service_question_model.dart';

class ServiceModel extends ServiceEntity {
  final int? questionsCount;
  final bool chargeEnabled;
  

ServiceModel({
  super.id,
  required super.name,
  super.categoryId,
  required super.categoryName,
  List<ServiceQuestionModel> super.questions = const [],
  super.status,
  this.questionsCount,
  this.chargeEnabled = false,
});

  List<ServiceQuestionModel> get questionModels =>
      questions.cast<ServiceQuestionModel>();

  // Falls back to questionsCount if questions list is empty in summary API.
  int get totalQuestionsCount =>
      questions.isNotEmpty ? questions.length : (questionsCount ?? 0);

  // ── API REQUEST MAPPING ──
Map<String, dynamic> toMap() {
  return {
    if (id != null) 'id': id,
    'service_name': name.trim(),
    if (categoryId != null) 'category_id': categoryId,
    'status': status,

    // Admin controls only whether charge entry is enabled.
    'charge_enabled': chargeEnabled ? 1 : 0,

    'questions': questionModels.asMap().entries.map((e) {
      final q = e.value;

      return ServiceQuestionModel(
        localId: q.localId,
        id: q.id,
        label: q.label,
        type: q.type,
        required: q.required,
        options: q.options,
        order: e.key,
      ).toMap();
    }).toList(),
  };
}

  // ── API RESPONSE MAPPING ──
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'];
    final questions = <ServiceQuestionModel>[];

    if (rawQuestions is List) {
      for (var i = 0; i < rawQuestions.length; i++) {
        final rawQuestion = rawQuestions[i];

        if (rawQuestion is Map) {
          questions.add(
            ServiceQuestionModel.fromMap(
              Map<String, dynamic>.from(rawQuestion),
              order: i,
            ),
          );
        }
      }
    }

    final parsedCount =
        int.tryParse(map['questions_count']?.toString() ?? '') ??
        int.tryParse(map['questionsCount']?.toString() ?? '') ??
        int.tryParse(map['question_count']?.toString() ?? '') ??
        int.tryParse(map['total_questions']?.toString() ?? '') ??
        questions.length;

    final rawChargeEnabled = map['charge_enabled'];

    final parsedChargeEnabled =
        rawChargeEnabled == 1 ||
        rawChargeEnabled == '1' ||
        rawChargeEnabled == true ||
        rawChargeEnabled.toString().toLowerCase() == 'true';



    return ServiceModel(
      id: map['id'] != null
          ? int.tryParse(map['id'].toString())
          : null,
      name:
          map['service_name']?.toString().trim() ??
          map['name']?.toString().trim() ??
          '',
      categoryId: map['category_id'] != null
          ? int.tryParse(map['category_id'].toString())
          : null,
      categoryName:
          map['category_name']?.toString().trim() ?? '',
      questions: questions,
      questionsCount: parsedCount,
      status: map['status']?.toString().trim().isNotEmpty == true
          ? map['status'].toString().trim()
          : 'ACTIVE',
      chargeEnabled: parsedChargeEnabled,
      
    );
  }
}