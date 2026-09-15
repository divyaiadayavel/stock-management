import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final String paymentMethod;
  final int? selectedCustomerId;
  final String? selectedCustomerName;

  const PaymentState({
    this.paymentMethod = "Cash",
    this.selectedCustomerId,
    this.selectedCustomerName,
  });

  PaymentState copyWith({
    String? paymentMethod,
    int? selectedCustomerId,
    String? selectedCustomerName,
  }) {
    return PaymentState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      selectedCustomerName: selectedCustomerName ?? this.selectedCustomerName,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  void selectCustomer({required int id, required String name}) {
    state = state.copyWith(selectedCustomerId: id, selectedCustomerName: name);
  }

  /// Clears the selected/added customer, falling back to "Walk-in
  /// Customer". Deliberately does NOT use [copyWith] — its `??`
  /// pattern can't set a field back to null, so this rebuilds the
  /// state directly, keeping [paymentMethod] as-is.
  void clearCustomer() {
    state = PaymentState(
      paymentMethod: state.paymentMethod,
      selectedCustomerId: null,
      selectedCustomerName: null,
    );
  }

  void reset() {
    state = const PaymentState();
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);
