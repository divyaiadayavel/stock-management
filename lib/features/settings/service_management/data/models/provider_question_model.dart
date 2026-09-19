// lib/features/settings/service_management/data/models/provider_question_model.dart
import '../../domain/entities/provider_question.dart';
import '../../domain/enums/provider_field_type.dart';

class ProviderQuestionModel extends ProviderQuestionEntity {
  ProviderQuestionModel({
    required super.localId,
    super.id,
    required super.label,
    required super.type,
    super.required,
    super.options,
    super.fieldKey,
    super.order,
  });

  @override
  ProviderQuestionModel copyWith({
    int? id,
    String? label,
    ProviderFieldType? type,
    bool? required,
    List<String>? options,
    String? fieldKey,
    int? order,
  }) {
    return ProviderQuestionModel(
      localId: localId,
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      fieldKey: fieldKey ?? this.fieldKey,
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
      if (fieldKey != null && fieldKey!.isNotEmpty) 'field_key': fieldKey,
      'sort_order': order,
    };
  }

  // ── API RESPONSE MAPPING ──
  factory ProviderQuestionModel.fromMap(
    Map<String, dynamic> map, {
    int order = 0,
  }) {
    final rawOptions = map['options'];
    final options = <String>[];

    if (rawOptions is List) {
      options.addAll(rawOptions.map((e) => e.toString()));
    } else if (rawOptions is String && rawOptions.trim().isNotEmpty) {
      options.addAll(rawOptions.split(',').map((e) => e.trim()));
    }

    final rawKey = map['field_key']?.toString().trim();

    return ProviderQuestionModel(
      localId: 'pq_${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      label: map['label']?.toString().trim() ?? '',
      type: ProviderFieldTypeX.fromApiValue(map['type']?.toString()),
      required: map['is_required'].toString() == '1' ||
          map['is_required'].toString().toLowerCase() == 'true',
      options: options,
      fieldKey: (rawKey == null || rawKey.isEmpty) ? null : rawKey,
      order: int.tryParse(map['sort_order']?.toString() ?? '') ?? order,
    );
  }

  /// The question set every new provider starts with — exactly the rows
  /// shown on the "Recharge questions" screen.
  static List<ProviderQuestionModel> defaults() {
    int seed = DateTime.now().microsecondsSinceEpoch;

    ProviderQuestionModel make({
      required String label,
      required ProviderFieldType type,
      required String fieldKey,
      required int order,
      List<String> options = const [],
    }) {
      return ProviderQuestionModel(
        localId: 'seed_${seed++}',
        label: label,
        type: type,
        required: true,
        options: options,
        fieldKey: fieldKey,
        order: order,
      );
    }

    return [
      make(
        label: 'Customer name',
        type: ProviderFieldType.shortText,
        fieldKey: ProviderFieldKeys.customerName,
        order: 0,
      ),
      make(
        label: 'Phone number',
        type: ProviderFieldType.number,
        fieldKey: ProviderFieldKeys.phone,
        order: 1,
      ),
      make(
        label: 'Plan name',
        type: ProviderFieldType.shortText,
        fieldKey: ProviderFieldKeys.planName,
        order: 2,
      ),
      make(
        label: 'Plan amount',
        type: ProviderFieldType.amount,
        fieldKey: ProviderFieldKeys.amount,
        order: 3,
      ),
      make(
        label: 'Payment status',
        type: ProviderFieldType.choice,
        fieldKey: ProviderFieldKeys.paymentStatus,
        order: 4,
        options: const ['Paid now', 'Partial', 'Pending'],
      ),
      make(
        label: 'Payment method',
        type: ProviderFieldType.choice,
        fieldKey: ProviderFieldKeys.paymentMethod,
        order: 5,
        options: const ['Cash', 'UPI'],
      ),
    ];
  }
}
