// lib/features/settings/service_management/data/models/service_provider_model.dart
import '../../domain/entities/service_provider.dart';
import 'provider_question_model.dart';

class ServiceProviderModel extends ServiceProviderEntity {
  ServiceProviderModel({
    super.id,
    super.categoryId,
    super.categoryName,
    required super.name,
    super.description,
    super.balance,
    super.lowBalanceThreshold,
    List<ProviderQuestionModel> super.questions = const [],
    super.status,
  });

  List<ProviderQuestionModel> get questionModels =>
      questions.cast<ProviderQuestionModel>();

  ServiceProviderModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    String? name,
    String? description,
    double? balance,
    double? lowBalanceThreshold,
    List<ProviderQuestionModel>? questions,
    String? status,
  }) {
    return ServiceProviderModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      questions: questions ?? questionModels,
      status: status ?? this.status,
    );
  }

  // ── API REQUEST MAPPING ──
  Map<String, dynamic> toMap({bool includeInitialLoad = false}) {
    return {
      if (id != null) 'id': id,
      'provider_name': name.trim(),
      if (categoryId != null) 'category_id': categoryId,
      'description': description.trim(),
      if (includeInitialLoad)
        'initial_load_amount': balance.toStringAsFixed(2),
      'low_balance_threshold': lowBalanceThreshold.toStringAsFixed(2),
      'status': status,
      'questions': questionModels.asMap().entries.map((e) {
        return e.value.copyWith(order: e.key).toMap();
      }).toList(),
    };
  }

  // ── API RESPONSE MAPPING ──
  factory ServiceProviderModel.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'];
    final questions = <ProviderQuestionModel>[];

    if (rawQuestions is List) {
      for (var i = 0; i < rawQuestions.length; i++) {
        final raw = rawQuestions[i];

        if (raw is Map) {
          questions.add(
            ProviderQuestionModel.fromMap(
              Map<String, dynamic>.from(raw),
              order: i,
            ),
          );
        }
      }
    }

    return ServiceProviderModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      categoryId: map['category_id'] != null
          ? int.tryParse(map['category_id'].toString())
          : null,
      categoryName: map['category_name']?.toString().trim() ?? '',
      name: map['provider_name']?.toString().trim() ??
          map['name']?.toString().trim() ??
          '',
      description: map['description']?.toString().trim() ?? '',
      balance: double.tryParse(map['balance']?.toString() ?? '0') ?? 0.0,
      lowBalanceThreshold:
          double.tryParse(map['low_balance_threshold']?.toString() ?? '500') ??
              500.0,
      questions: questions,
      status: map['status']?.toString().trim().isNotEmpty == true
          ? map['status'].toString().trim()
          : 'ACTIVE',
    );
  }
}
