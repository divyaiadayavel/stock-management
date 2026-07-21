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

  void selectCustomer({
    required int id,
    required String name,
  }) {
    state = state.copyWith(
      selectedCustomerId: id,
      selectedCustomerName: name,
    );
  }

  void reset() {
    state = const PaymentState();
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);