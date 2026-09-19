// lib/features/settings/service_management/domain/enums/provider_field_type.dart

/// Field types available to a recharge PROVIDER form.
///
/// Kept separate from [QuestionType] on purpose: the provider flow needs
/// money-aware field types (`amount`) the existing service forms do not
/// have, and changing the existing enum would alter services already live.
enum ProviderFieldType {
  shortText,
  paragraph,
  number,
  amount,
  choice,
  date,
}

extension ProviderFieldTypeX on ProviderFieldType {
  /// Value stored / sent to the PHP backend.
  String get apiValue {
    switch (this) {
      case ProviderFieldType.shortText:
        return 'short_text';
      case ProviderFieldType.paragraph:
        return 'paragraph';
      case ProviderFieldType.number:
        return 'number';
      case ProviderFieldType.amount:
        return 'amount';
      case ProviderFieldType.choice:
        return 'choice';
      case ProviderFieldType.date:
        return 'date';
    }
  }

  String get label {
    switch (this) {
      case ProviderFieldType.shortText:
        return 'Short text';
      case ProviderFieldType.paragraph:
        return 'Paragraph';
      case ProviderFieldType.number:
        return 'Number';
      case ProviderFieldType.amount:
        return 'Amount';
      case ProviderFieldType.choice:
        return 'Choice';
      case ProviderFieldType.date:
        return 'Date';
    }
  }

  bool get hasOptions => this == ProviderFieldType.choice;

  static ProviderFieldType fromApiValue(String? value) {
    switch (value) {
      case 'paragraph':
        return ProviderFieldType.paragraph;
      case 'number':
        return ProviderFieldType.number;
      case 'amount':
        return ProviderFieldType.amount;
      case 'choice':
        return ProviderFieldType.choice;
      case 'date':
        return ProviderFieldType.date;
      case 'short_text':
      default:
        return ProviderFieldType.shortText;
    }
  }
}

/// Well-known field keys. `amount` is the important one: its answer is
/// the value deducted from the provider balance.
class ProviderFieldKeys {
  static const String customerName = 'customer_name';
  static const String phone = 'phone';
  static const String planName = 'plan_name';
  static const String amount = 'amount';
  static const String paymentStatus = 'payment_status';
  static const String paymentMethod = 'payment_method';

  const ProviderFieldKeys._();
}
