import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_management/features/expenses/data/models/expense_model.dart';

/// Holds the non-text-field state of the Add/Edit Expense form
/// (payment method + date). Name/Amount/Notes stay as
/// TextEditingControllers inside the screen, matching how your
/// AddProductScreen keeps controllers local.
class AddExpenseState {
  final PaymentMethod paymentMethod;
  final DateTime date;

  const AddExpenseState({
    this.paymentMethod = PaymentMethod.cash,
    required this.date,
  });

  AddExpenseState copyWith({PaymentMethod? paymentMethod, DateTime? date}) {
    return AddExpenseState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
    );
  }
}

class AddExpenseNotifier extends StateNotifier<AddExpenseState> {
  AddExpenseNotifier() : super(AddExpenseState(date: DateTime.now()));

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void loadFromExpense(ExpenseModel expense) {
    state = AddExpenseState(
      paymentMethod: expense.paymentMethod,
      date: expense.date,
    );
  }

  void reset() {
    state = AddExpenseState(date: DateTime.now());
  }
}

final addExpenseProvider =
    StateNotifierProvider.autoDispose<AddExpenseNotifier, AddExpenseState>(
        (ref) {
  return AddExpenseNotifier();
});
