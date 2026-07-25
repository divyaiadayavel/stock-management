import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sale_model.dart';
import '../../domain/usecases/get_invoice.dart';

import 'sales_provider.dart';

final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier(
    getInvoice: ref.read(getInvoiceUseCaseProvider),
  );
});

class InvoiceState {
  final bool isLoading;
  final SaleModel? invoice;
  final String? error;

  const InvoiceState({
    this.isLoading = false,
    this.invoice,
    this.error,
  });

  InvoiceState copyWith({
    bool? isLoading,
    SaleModel? invoice,
    String? error,
  }) {
    return InvoiceState(
      isLoading: isLoading ?? this.isLoading,
      invoice: invoice ?? this.invoice,
      error: error,
    );
  }
}

class InvoiceNotifier extends StateNotifier<InvoiceState> {
  final GetInvoice getInvoice;

  InvoiceNotifier({
    required this.getInvoice,
  }) : super(const InvoiceState());

  Future<void> loadInvoice(int saleId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final invoice = await getInvoice(saleId);

      state = state.copyWith(
        isLoading: false,
        invoice: invoice,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearInvoice() {
    state = const InvoiceState();
  }
}