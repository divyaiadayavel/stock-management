/// Payment method for an expense. GPay was replaced with a generic
/// UPI option per the updated Add Expense flow.
enum PaymentMethod { cash, upi }

extension PaymentMethodX on PaymentMethod {
  String get label => this == PaymentMethod.cash ? 'Cash' : 'UPI';

  static PaymentMethod fromLabel(String? label) {
    return (label ?? '').toLowerCase() == 'upi'
        ? PaymentMethod.upi
        : PaymentMethod.cash;
  }
}

class ExpenseModel {
  final String id;
  final String name;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? notes;

  const ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.notes,
  });

  ExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? notes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  // NOTE: Keys are guessed to match common PHP/MySQL naming
  // (snake_case). Line these up with your actual API response once
  // the backend endpoints exist.
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentMethod: PaymentMethodX.fromLabel(json['payment_method']?.toString()),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'payment_method': paymentMethod.label,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
