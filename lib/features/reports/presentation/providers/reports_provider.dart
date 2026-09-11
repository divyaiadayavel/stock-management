import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/payable_supplier.dart';
import '../../domain/entities/receivable_customer.dart';
import '../../domain/entities/report_bill.dart';
import '../../domain/entities/report_extras.dart';
import '../../domain/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    remoteDataSource: ReportsRemoteDataSourceImpl(client: Dio()),
  );
});

enum ReportDateFilter { today, thisWeek, thisMonth, thisYear, custom }

final rangeChartPointsProvider =
    FutureProvider.family<List<ReportChartPoint>, String>((ref, period) async {
      final repo = ref.watch(reportsRepositoryProvider);

      // 'period' mirrors reportsOverviewProvider's key: 'today' |
      // 'this_week' | 'this_month' | 'this_year' | 'custom:YYYY-MM-DD:YYYY-MM-DD'.
      // Using this stable String (rather than a freshly-constructed
      // DateTimeRange, which has no value equality and was rebuilt on every
      // frame) is what actually lets this FutureProvider.family cache and
      // resolve — that mismatch was why the Sales Analysis chart never
      // finished loading.
      String filter = period;
      String? from;
      String? to;
      if (period.startsWith('custom:')) {
        final parts = period.split(':');
        if (parts.length == 3) {
          filter = 'custom';
          from = parts[1];
          to = parts[2];
        }
      }

      try {
        final rawPoints = await repo.getChartPoints(filter, from: from, to: to);
        return rawPoints
            .map(
              (e) => ReportChartPoint(
                label: (e['date'] ?? e['label'] ?? '').toString(),
                amount:
                    double.tryParse(
                      (e['revenue'] ?? e['amount'] ?? '0').toString(),
                    ) ??
                    0.0,
              ),
            )
            .toList();
      } catch (_) {
        return [];
      }
    });

class ReportsState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, double> metrics;
  final List<ReportBill> bills;
  final List<PayableSupplier> payableSuppliers;
  final List<PayableSupplier> payables;
  final List<ReceivableCustomer> receivableCustomers;
  final List<ReceivableCustomer> receivables;
  final DateTimeRange selectedDateRange;
  final ReportDateFilter currentFilter;
  final String selectedPaymentStatus; // 'ALL', 'PAID', 'PARTIAL', 'PENDING'

  double get totalSales => metrics['total_sales'] ?? 0.0;
  double get totalPurchases => metrics['total_purchases'] ?? 0.0;
  double get totalReceivable => metrics['total_receivable'] ?? 0.0;
  double get totalPayable => metrics['total_payable'] ?? 0.0;

  // Filtered bills based on the selected payment status tab
  List<ReportBill> get filteredBills {
    final status = selectedPaymentStatus.toUpperCase();
    if (status == 'PAID') {
      return bills
          .where(
            (b) =>
                b.paymentStatus.toUpperCase() == 'PAID' || b.balanceAmount <= 0,
          )
          .toList();
    } else if (status == 'PARTIAL') {
      return bills
          .where(
            (b) =>
                b.paymentStatus.toUpperCase() == 'PARTIAL' ||
                (b.paidAmount > 0 && b.balanceAmount > 0),
          )
          .toList();
    } else if (status == 'PENDING') {
      return bills
          .where(
            (b) =>
                b.paymentStatus.toUpperCase() == 'PENDING' ||
                (b.paidAmount == 0 && b.balanceAmount > 0),
          )
          .toList();
    }
    return bills; // 'ALL'
  }

  ReportsState({
    this.isLoading = false,
    this.errorMessage,
    this.metrics = const {
      'total_sales': 0.0,
      'total_purchases': 0.0,
      'total_receivable': 0.0,
      'total_payable': 0.0,
    },
    this.bills = const [],
    this.payableSuppliers = const [],
    this.payables = const [],
    this.receivableCustomers = const [],
    this.receivables = const [],
    DateTimeRange? selectedDateRange,
    this.currentFilter = ReportDateFilter.thisMonth,
    this.selectedPaymentStatus = 'ALL',
  }) : selectedDateRange =
           selectedDateRange ??
           _calculateDateRangeForFilter(ReportDateFilter.thisMonth);

  static DateTimeRange _calculateDateRangeForFilter(ReportDateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case ReportDateFilter.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportDateFilter.thisWeek:
        final weekDay = now.weekday;
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekDay - 1));
        return DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportDateFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportDateFilter.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case ReportDateFilter.custom:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  ReportsState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, double>? metrics,
    List<ReportBill>? bills,
    List<PayableSupplier>? payableSuppliers,
    List<PayableSupplier>? payables,
    List<ReceivableCustomer>? receivableCustomers,
    List<ReceivableCustomer>? receivables,
    DateTimeRange? selectedDateRange,
    ReportDateFilter? currentFilter,
    String? selectedPaymentStatus,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      metrics: metrics ?? this.metrics,
      bills: bills ?? this.bills,
      payableSuppliers: payableSuppliers ?? this.payableSuppliers,
      payables: payables ?? this.payables,
      receivableCustomers: receivableCustomers ?? this.receivableCustomers,
      receivables: receivables ?? this.receivables,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      currentFilter: currentFilter ?? this.currentFilter,
      selectedPaymentStatus:
          selectedPaymentStatus ?? this.selectedPaymentStatus,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository repository;

  ReportsNotifier({required this.repository}) : super(ReportsState()) {
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await Future.wait([
        fetchDashboardMetrics(
          state.selectedDateRange.start,
          state.selectedDateRange.end,
        ),
        fetchReportBills(
          state.selectedDateRange.start,
          state.selectedDateRange.end,
        ),
        fetchPayableSuppliers(
          state.selectedDateRange.start,
          state.selectedDateRange.end,
        ),
        fetchReceivableCustomers(
          state.selectedDateRange.start,
          state.selectedDateRange.end,
        ),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeDateFilter(
    ReportDateFilter filter, {
    DateTimeRange? customRange,
  }) async {
    DateTimeRange newRange;
    if (filter == ReportDateFilter.custom && customRange != null) {
      newRange = customRange;
    } else {
      newRange = ReportsState._calculateDateRangeForFilter(filter);
    }

    state = state.copyWith(currentFilter: filter, selectedDateRange: newRange);

    await fetchReportData();
  }

  Future<void> updateDateRange(DateTimeRange range) async {
    state = state.copyWith(
      currentFilter: ReportDateFilter.custom,
      selectedDateRange: range,
    );
    await fetchReportData();
  }

  void setPaymentStatusFilter(String status) {
    state = state.copyWith(selectedPaymentStatus: status.toUpperCase());
  }

  Future<void> reprintBill(String billId) async {
    await repository.reprintBill(billId);
  }

  Future<void> fetchDashboardMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final metrics = await repository.getDashboardMetrics();
      state = state.copyWith(metrics: metrics);
    } catch (_) {}
  }

  Future<void> fetchReportBills(DateTime startDate, DateTime endDate) async {
    try {
      final bills = await repository.getReportBills(startDate, endDate);
      state = state.copyWith(bills: bills);
    } catch (_) {}
  }

  Future<void> fetchPayableSuppliers(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final suppliers = await repository.getPayableSuppliers();
      state = state.copyWith(payableSuppliers: suppliers, payables: suppliers);
    } catch (_) {}
  }

  Future<void> fetchReceivableCustomers(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final customers = await repository.getReceivableCustomers();
      state = state.copyWith(
        receivableCustomers: customers,
        receivables: customers,
      );
    } catch (_) {}
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  final repo = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repository: repo);
});
