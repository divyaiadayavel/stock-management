// lib/features/services/data/models/service_request_model.dart

import '../../domain/entities/service_request.dart';
import 'service_answer_model.dart';

class ServiceRequestModel extends ServiceRequestEntity {
  final int userId;
  final double amount;
  final bool chargeEnabled;

  ServiceRequestModel({
    super.id,
    required this.userId,
    required super.serviceId,
    required super.serviceName,
    required super.categoryName,
    required List<ServiceAnswerModel> super.answers,
    super.status,
    super.invoiceNumber,
    super.submittedAt,
    this.amount = 0.0,
    this.chargeEnabled = false,
  });

  List<ServiceAnswerModel> get answerModels =>
      answers.cast<ServiceAnswerModel>();

  // ── API REQUEST MAPPING ──────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'service_id': serviceId,
      'amount': amount.toStringAsFixed(2),
      'answers': answerModels.map((a) => a.toMap()).toList(),
    };
  }

  // ── API RESPONSE MAPPING ─────────────────────────────────
  factory ServiceRequestModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawAnswers = map['answers'];
    final answers = <ServiceAnswerModel>[];

    if (rawAnswers is List) {
      for (final answer in rawAnswers) {
        if (answer is Map) {
          answers.add(
            ServiceAnswerModel.fromMap(
              Map<String, dynamic>.from(answer),
            ),
          );
        }
      }
    }

    final parsedUserId =
        int.tryParse(
          map['user_id']?.toString() ?? '',
        ) ??
        0;

    final parsedAmount =
        double.tryParse(
          map['amount']?.toString() ?? '0',
        ) ??
        0.0;

    final rawChargeEnabled =
        map['charge_enabled'];

    final parsedChargeEnabled =
        rawChargeEnabled == 1 ||
        rawChargeEnabled == '1' ||
        rawChargeEnabled == true ||
        rawChargeEnabled
                .toString()
                .toLowerCase() ==
            'true';

    return ServiceRequestModel(
      id: map['id'] != null
          ? int.tryParse(
              map['id'].toString(),
            )
          : null,

      userId: parsedUserId,

      serviceId:
          int.tryParse(
            map['service_id']?.toString() ?? '',
          ) ??
          0,

      serviceName:
          map['service_name']?.toString() ?? '',

      categoryName:
          map['category_name']?.toString() ?? '',

      answers: answers,

      status:
          map['status']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? map['status']
                  .toString()
                  .trim()
              : 'SUBMITTED',

      invoiceNumber:
          map['invoice_number']?.toString(),

      submittedAt:
          map['submitted_at'] != null
              ? DateTime.tryParse(
                  map['submitted_at'].toString(),
                )
              : null,

      amount: parsedAmount,

      chargeEnabled:
          parsedChargeEnabled,
    );
  }
}