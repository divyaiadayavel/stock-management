import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/models/customer_model.dart';

// 1. Core HTTP
final customerHttpClientProvider = Provider<http.Client>((ref) => http.Client());

final customerRemoteSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSource(client: ref.watch(customerHttpClientProvider));
});

// 2. Search query
final customerSearchQueryProvider = StateProvider<String>((ref) => "");

// 3. Filtered list (used in UI)
final rawCustomersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final searchQuery = ref.watch(customerSearchQueryProvider);
  return await ref.watch(customerRemoteSourceProvider).getCustomersFromServer(search: searchQuery);
});

// 4. Unfiltered list (used for summary totals)
final allCustomersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  return await ref.watch(customerRemoteSourceProvider).getCustomersFromServer(search: '');
});

// 5. Dashboard summary – uses allCustomersProvider
final customerDashboardSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final customersAsync = ref.watch(allCustomersProvider);

  return customersAsync.maybeWhen(
    data: (list) {
      int count = list.length;
      double receivable = 0.0;
      for (var c in list) {
        receivable += c.currentBalance;
      }
      return {
        "isLoading": false,
        "list": list,
        "totalCount": count,
        "totalReceivable": receivable,
      };
    },
    orElse: () => {
      "isLoading": true,
      "list": <CustomerModel>[],
      "totalCount": 0,
      "totalReceivable": 0.00,
    },
  );
});

// 6. Operations – invalidate BOTH providers
class CustomerOperations extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  CustomerOperations(this.ref) : super(const AsyncValue.data(null));

  Future<bool> addCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      final newId = await ref.read(customerRemoteSourceProvider).addCustomerToServer(customer);
      if (newId > 0) {
        ref.invalidate(rawCustomersProvider);
        ref.invalidate(allCustomersProvider); // ✅ also invalidate unfiltered
        state = const AsyncValue.data(null);
        return true;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return false;
  }

  /// Same as [addCustomer], but returns the newly created customer
  /// (with its server-assigned id) instead of just a bool.
  ///
  /// Used by flows (e.g. Payment screen -> Add customer) that need to
  /// immediately select the customer that was just created, without
  /// requiring the caller to re-fetch and search the customer list.
  Future<CustomerModel?> addCustomerAndReturn(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      final newId = await ref.read(customerRemoteSourceProvider).addCustomerToServer(customer);
      if (newId > 0) {
        ref.invalidate(rawCustomersProvider);
        ref.invalidate(allCustomersProvider); // ✅ also invalidate unfiltered
        state = const AsyncValue.data(null);

        return CustomerModel(
          id: newId,
          customerCode: customer.customerCode,
          customerName: customer.customerName,
          phone: customer.phone,
          alternatePhone: customer.alternatePhone,
          email: customer.email,
          gstNumber: customer.gstNumber,
          address: customer.address,
          city: customer.city,
          state: customer.state,
          country: customer.country,
          postalCode: customer.postalCode,
          openingBalance: customer.openingBalance,
          currentBalance: customer.currentBalance,
          loyaltyPoints: customer.loyaltyPoints,
          notes: customer.notes,
          status: customer.status,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return null;
  }

  Future<bool> modifyCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    try {
      final success = await ref.read(customerRemoteSourceProvider).updateCustomerOnServer(customer);
      if (success) {
        ref.invalidate(rawCustomersProvider);
        ref.invalidate(allCustomersProvider); // ✅
        state = const AsyncValue.data(null);
        return true;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return false;
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final success = await ref.read(customerRemoteSourceProvider).deleteCustomerFromServer(id);
      if (success) {
        ref.invalidate(rawCustomersProvider);
        ref.invalidate(allCustomersProvider); // ✅
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final customerOperationsProvider = StateNotifierProvider<CustomerOperations, AsyncValue<void>>((ref) {
  return CustomerOperations(ref);
});