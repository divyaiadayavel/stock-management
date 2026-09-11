// lib/features/settings/service_management/data/models/service_question_model.dart
import '../../domain/entities/service_question.dart';
import '../../domain/enums/question_type.dart';

class ServiceQuestionModel extends ServiceQuestionEntity {
  ServiceQuestionModel({
    required super.localId,
    super.id,
    required super.label,
    required super.type,
    super.required,
    super.options,
    super.order,
  });

  @override
  ServiceQuestionModel copyWith({
    int? id,
    String? label,
    QuestionType? type,
    bool? required,
    List<String>? options,
    int? order,
  }) {
    return ServiceQuestionModel(
      localId: localId,
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      order: order ?? this.order,
    );
  }

  // ── API REQUEST MAPPING ──
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'label': label.trim(),
      'type': type.apiValue,
      'is_required': required ? 1 : 0,
      'options': options,
      'sort_order': order,
    };
  }

  // ── API RESPONSE MAPPING ──
  factory ServiceQuestionModel.fromMap(Map<String, dynamic> map, {int order = 0}) {
    final rawOptions = map['options'];
    final options = <String>[];
    if (rawOptions is List) {
      options.addAll(rawOptions.map((e) => e.toString()));
    } else if (rawOptions is String && rawOptions.trim().isNotEmpty) {
      // Backend may return options as a JSON-encoded string; the
      // datasource decodes JSON before this factory runs, but this
      // fallback keeps the model resilient to a plain comma list too.
      options.addAll(rawOptions.split(',').map((e) => e.trim()));
    }

    return ServiceQuestionModel(
      localId: 'srv_${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      label: map['label']?.toString().trim() ?? '',
      type: QuestionTypeX.fromApiValue(map['type']?.toString()),
      required: map['is_required'].toString() == '1' ||
          map['is_required'].toString().toLowerCase() == 'true',
      options: options,
      order: int.tryParse(map['sort_order']?.toString() ?? '') ?? order,
    );
  }
}
