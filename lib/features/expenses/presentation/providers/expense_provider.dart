// lib/features/expenses/presentation/providers/expense_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_management/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:stock_management/features/expenses/data/models/expense_model.dart';


// ============================================================
// EXPENSE STATE
// ============================================================

class ExpenseState {
  final List<ExpenseModel> expenses;

  final PaymentMethod? paymentMethodFilter;

  final DateTimeRange? dateRange;

  final String searchQuery;

  final bool isLoading;

  final String? error;

  const ExpenseState({
    this.expenses = const [],
    this.paymentMethodFilter,
    this.dateRange,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    PaymentMethod? paymentMethodFilter,
    DateTimeRange? dateRange,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      paymentMethodFilter:
          paymentMethodFilter ?? this.paymentMethodFilter,
      dateRange: dateRange ?? this.dateRange,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // ==========================================================
  // FILTERS
  // ==========================================================

  ExpenseState withFilters({
    PaymentMethod? paymentMethod,
    bool resetPaymentMethod = false,
    DateTimeRange? dateRange,
    bool resetDateRange = false,
  }) {
    return ExpenseState(
      expenses: expenses,

      paymentMethodFilter: resetPaymentMethod
          ? null
          : (paymentMethod ?? paymentMethodFilter),

      dateRange: resetDateRange
          ? null
          : (dateRange ?? this.dateRange),

      searchQuery: searchQuery,

      isLoading: isLoading,

      error: error,
    );
  }

  // ==========================================================
  // FILTERED EXPENSES
  // ==========================================================

  List<ExpenseModel> get filteredExpenses {
    Iterable<ExpenseModel> list = expenses;

    // --------------------------------------------------------
    // Date range
    // --------------------------------------------------------

    if (dateRange != null) {
      final start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );

      final end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
        999,
      );

      list = list.where(
        (expense) =>
            !expense.date.isBefore(start) &&
            !expense.date.isAfter(end),
      );
    }

    // --------------------------------------------------------
    // Payment method
    // --------------------------------------------------------

    if (paymentMethodFilter != null) {
      list = list.where(
        (expense) =>
            expense.paymentMethod == paymentMethodFilter,
      );
    }

    // --------------------------------------------------------
    // Search
    // --------------------------------------------------------

    if (searchQuery.trim().isNotEmpty) {
      final query =
          searchQuery.trim().toLowerCase();

      list = list.where(
        (expense) =>
            expense.name
                .toLowerCase()
                .contains(query) ||
            (expense.notes ?? '')
                .toLowerCase()
                .contains(query),
      );
    }

    // --------------------------------------------------------
    // Newest first
    // --------------------------------------------------------

    final result = list.toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    return result;
  }

  // ==========================================================
  // TOTAL
  // ==========================================================

  double get totalForFilter {
    return filteredExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  // ==========================================================
  // COUNT
  // ==========================================================

  int get countForFilter {
    return filteredExpenses.length;
  }

  // ==========================================================
  // GROUP BY DATE
  // ==========================================================

  Map<String, List<ExpenseModel>> get groupedByDate {
    final Map<String, List<ExpenseModel>> grouped = {};

    for (final expense in filteredExpenses) {
      final key = _dateKey(expense.date);

      grouped
          .putIfAbsent(
            key,
            () => [],
          )
          .add(expense);
    }

    return grouped;
  }

  // ==========================================================
  // TOTAL FOR GROUP
  // ==========================================================

  double totalFor(
    List<ExpenseModel> items,
  ) {
    return items.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  // ==========================================================
  // DATE KEY
  // ==========================================================

  static String _dateKey(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final current = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (current == today) {
      return 'Today';
    }

    if (current == yesterday) {
      return 'Yesterday';
    }

    return '${current.day.toString().padLeft(2, '0')}/'
        '${current.month.toString().padLeft(2, '0')}/'
        '${current.year}';
  }
}


// ============================================================
// EXPENSE NOTIFIER
// ============================================================

class ExpenseNotifier
    extends StateNotifier<ExpenseState> {
  ExpenseNotifier()
      : super(const ExpenseState()) {
    loadExpenses();
  }

  // ==========================================================
  // LOAD EXPENSES
  // ==========================================================

  Future<void> loadExpenses() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final expenses =
          await ExpenseRemoteDataSource.getExpenses();

      state = state.copyWith(
        expenses: expenses,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );
    }
  }

  // ==========================================================
  // PAYMENT METHOD FILTER
  // ==========================================================

  void setPaymentMethodFilter(
    PaymentMethod? method,
  ) {
    state = state.withFilters(
      paymentMethod: method,
      resetPaymentMethod: method == null,
    );
  }

  // ==========================================================
  // DATE RANGE FILTER
  // ==========================================================

  void setDateRange(
    DateTimeRange? range,
  ) {
    state = state.withFilters(
      dateRange: range,
      resetDateRange: range == null,
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void setSearchQuery(
    String query,
  ) {
    state = state.copyWith(
      searchQuery: query,
    );
  }

  // ==========================================================
  // ADD EXPENSE
  // ==========================================================

  Future<bool> addExpense(
    ExpenseModel expense,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      /*
       * The backend creates the actual database record.
       *
       * Therefore the local object is NOT inserted until
       * the server returns HTTP 201 + success:true.
       */
      final savedExpense =
          await ExpenseRemoteDataSource.addExpense(
        expense,
      );

      state = state.copyWith(
        expenses: [
          ...state.expenses,
          savedExpense,
        ],
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ==========================================================
  // UPDATE EXPENSE
  // ==========================================================

  Future<bool> updateExpense(
    ExpenseModel expense,
  ) async {
    final previousExpenses = state.expenses;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      /*
       * First update the server/database.
       */
      final updatedExpense =
          await ExpenseRemoteDataSource.updateExpense(
        expense,
      );

      /*
       * Only update local Riverpod state after the
       * backend confirms successful persistence.
       */
      final updatedList =
          previousExpenses.map(
        (existing) {
          if (existing.id == updatedExpense.id) {
            return updatedExpense;
          }

          return existing;
        },
      ).toList();

      state = state.copyWith(
        expenses: updatedList,
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      /*
       * Database update failed.
       *
       * Keep the previous local state.
       */
      state = state.copyWith(
        expenses: previousExpenses,
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ==========================================================
  // DELETE EXPENSE
  // ==========================================================

  Future<bool> deleteExpense(
    String id,
  ) async {
    final previousExpenses = state.expenses;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      /*
       * Backend performs the soft delete.
       */
      await ExpenseRemoteDataSource.deleteExpense(id);

      /*
       * Remove only after backend confirms success.
       */
      final updatedList = previousExpenses
          .where(
            (expense) => expense.id != id,
          )
          .toList();

      state = state.copyWith(
        expenses: updatedList,
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      /*
       * Keep the record visible when deletion fails.
       */
      state = state.copyWith(
        expenses: previousExpenses,
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    state = state.copyWith(
      error: null,
    );
  }

  // ==========================================================
  // ERROR CLEANUP
  // ==========================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}


// ============================================================
// EXPENSE PROVIDER
// ============================================================

final expenseProvider =
    StateNotifierProvider<
        ExpenseNotifier,
        ExpenseState>(
  (ref) {
    return ExpenseNotifier();
  },
);