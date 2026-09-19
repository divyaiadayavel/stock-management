// lib/features/settings/service_management/domain/entities/provider_question.dart
import '../enums/provider_field_type.dart';

class ProviderQuestionEntity {
  /// Local id used for editing/reordering before the provider is saved.
  final String localId;
  final int? id;
  final String label;
  final ProviderFieldType type;
  final bool required;
  final List<String> options;

  /// One of [ProviderFieldKeys], or null for a custom question.
  final String? fieldKey;

  final int order;

  const ProviderQuestionEntity({
    required this.localId,
    this.id,
    required this.label,
    required this.type,
    this.required = true,
    this.options = const [],
    this.fieldKey,
    this.order = 0,
  });

  bool get isAmountField => fieldKey == ProviderFieldKeys.amount;

  ProviderQuestionEntity copyWith({
    int? id,
    String? label,
    ProviderFieldType? type,
    bool? required,
    List<String>? options,
    String? fieldKey,
    int? order,
  }) {
    return ProviderQuestionEntity(
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
}
