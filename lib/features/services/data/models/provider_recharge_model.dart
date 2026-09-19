// lib/features/services/data/models/provider_recharge_model.dart
import '../../domain/entities/provider_recharge.dart';
import 'provider_recharge_answer_model.dart';

class ProviderRechargeModel extends ProviderRechargeEntity {
  ProviderRechargeModel({
    super.id,
    required super.providerId,
    super.categoryId,
    super.providerName,
    super.categoryName,
    super.userId,
    super.amount,
    super.balanceBefore,
    super.balanceAfter,
    super.paidAmount,
    super.balanceAmount,
    super.paymentStatus,
    super.paymentMethod,
    List<ProviderRechargeAnswerModel> super.answers = const [],
    super.status,
    super.invoiceNumber,
    super.submittedAt,
  });

  List<ProviderRechargeAnswerModel> get answerModels =>
      answers.cast<ProviderRechargeAnswerModel>();

  /// PAID / PARTIAL / PENDING — normalizes both new clean values and the
  /// older free-text values ('Paid now', 'Partial') that were typed
  /// through a dynamic form question before this flow existed.
  static String normalizeStatus(String raw, {double? amount, double? paid}) {
    final v = raw.trim().toUpperCase();

    if (v == 'PAID' || v.startsWith('PAID')) return 'PAID';
    if (v == 'PARTIAL') return 'PARTIAL';
    if (v == 'PENDING') return 'PENDING';

    // Nothing usable came back from the server — fall back to deriving
    // it from the amounts, same rule Sales uses.
    if (amount != null && paid != null) {
      if (paid <= 0.001) return 'PENDING';
      if (paid < amount - 0.001) return 'PARTIAL';
      return 'PAID';
    }

    return 'PAID';
  }

  // ── API REQUEST MAPPING ──
  Map<String, dynamic> toMap() {
    return {
      'provider_id': providerId,
      if (categoryId != null) 'category_id': categoryId,
      if (userId > 0) 'user_id': userId,
      'amount': amount.toStringAsFixed(2),
      'paid_amount': paidAmount.toStringAsFixed(2),
      'balance_amount': balanceAmount.toStringAsFixed(2),
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'answers': answerModels.map((a) => a.toMap()).toList(),
    };
  }

  // ── API RESPONSE MAPPING ──
  factory ProviderRechargeModel.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final answers = <ProviderRechargeAnswerModel>[];

    if (rawAnswers is List) {
      for (final answer in rawAnswers) {
        if (answer is Map) {
          answers.add(
            ProviderRechargeAnswerModel.fromMap(
              Map<String, dynamic>.from(answer),
            ),
          );
        }
      }
    }

    final amount = double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0;

    // `paid_amount` / `balance_amount` may not exist yet on older backend
    // rows/deployments — treat a missing paid_amount as "fully paid" so
    // recharges submitted before this feature still show PAID, not a
    // false balance.
    final hasPaidAmount = map['paid_amount'] != null;
    final paidAmount = hasPaidAmount
        ? (double.tryParse(map['paid_amount'].toString()) ?? amount)
        : amount;

    final hasBalanceAmount = map['balance_amount'] != null;
    final balanceAmount = hasBalanceAmount
        ? (double.tryParse(map['balance_amount'].toString()) ?? 0.0)
        : (amount - paidAmount).clamp(0.0, double.infinity);

    final paymentStatus = normalizeStatus(
      map['payment_status']?.toString() ?? '',
      amount: amount,
      paid: paidAmount,
    );

    return ProviderRechargeModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      providerId: int.tryParse(map['provider_id']?.toString() ?? '') ?? 0,
      categoryId: map['category_id'] != null
          ? int.tryParse(map['category_id'].toString())
          : null,
      providerName: map['provider_name']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      userId: int.tryParse(map['user_id']?.toString() ?? '') ?? 0,
      amount: amount,
      balanceBefore:
          double.tryParse(map['balance_before']?.toString() ?? '0') ?? 0.0,
      balanceAfter:
          double.tryParse(map['balance_after']?.toString() ?? '0') ?? 0.0,
      paidAmount: paidAmount,
      balanceAmount: balanceAmount,
      paymentStatus: paymentStatus,
      paymentMethod: map['payment_method']?.toString() ?? '',
      answers: answers,
      status: map['status']?.toString().trim().isNotEmpty == true
          ? map['status'].toString().trim()
          : 'COMPLETED',
      invoiceNumber: map['invoice_number']?.toString(),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'].toString())
          : null,
    );
  }

  ProviderRechargeModel copyWith({
    double? paidAmount,
    double? balanceAmount,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return ProviderRechargeModel(
      id: id,
      providerId: providerId,
      categoryId: categoryId,
      providerName: providerName,
      categoryName: categoryName,
      userId: userId,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      answers: answerModels,
      status: status,
      invoiceNumber: invoiceNumber,
      submittedAt: submittedAt,
    );
  }
}
