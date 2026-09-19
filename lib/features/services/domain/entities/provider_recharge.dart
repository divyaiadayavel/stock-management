// lib/features/services/domain/entities/provider_recharge.dart

/// One answered field of a submitted recharge.
class ProviderRechargeAnswerEntity {
  final int questionId;
  final String label;
  final String value;

  const ProviderRechargeAnswerEntity({
    required this.questionId,
    required this.label,
    required this.value,
  });
}

/// A completed recharge against a provider's float balance.
class ProviderRechargeEntity {
  final int? id;
  final int providerId;
  final int? categoryId;
  final String providerName;
  final String categoryName;
  final int userId;

  final double amount;
  final double balanceBefore;
  final double balanceAfter;

  /// How much of [amount] the customer has actually paid the shop.
  /// Equal to [amount] when PAID, 0 when PENDING, something in between
  /// when PARTIAL.
  final double paidAmount;

  /// [amount] - [paidAmount]. Still owed by the customer.
  final double balanceAmount;

  /// PAID / PARTIAL / PENDING — same three values Sales uses.
  final String paymentStatus;
  final String paymentMethod;

  final List<ProviderRechargeAnswerEntity> answers;

  final String status;
  final String? invoiceNumber;
  final DateTime? submittedAt;

  const ProviderRechargeEntity({
    this.id,
    required this.providerId,
    this.categoryId,
    this.providerName = '',
    this.categoryName = '',
    this.userId = 0,
    this.amount = 0.0,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.paymentStatus = '',
    this.paymentMethod = '',
    this.answers = const [],
    this.status = 'COMPLETED',
    this.invoiceNumber,
    this.submittedAt,
  });
}
