
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_bill.dart';
import '../../domain/entities/report_extras.dart';
import 'reports_provider.dart';

class SalesReportsQuery {
  final String filter;
  final String query;
  final String period;
  final int page;
  final int limit;

  const SalesReportsQuery({
    this.filter = 'ALL',
    this.query = '',
    this.period = 'this_month',
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesReportsQuery &&
          filter == other.filter &&
          query == other.query &&
          period == other.period &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(filter, query, period, page, limit);
}

final reportsOverviewProvider =
    FutureProvider.family<ReportOverviewSummary, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getReportsOverview(range: range);
    });

final salesReportsProvider =
    FutureProvider.family<List<ReportBill>, SalesReportsQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getSalesReports(
        filter: query.filter,
        query: query.query,
        period: query.period,
        page: query.page,
        limit: query.limit,
      );
    });

final invoiceDetailProvider = FutureProvider.family<InvoiceDetail, String>((
  ref,
  id,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getInvoiceDetail(id);
});

/// Query object for the Product Sales Ranking screen (Card 2).
///
/// [segment] drives the Sort By chips: fast_selling (Best Selling),
/// high_margin (Top Profit), low_performing (Low Performing).
///
/// [period] drives the Date Range filter: today, this_week, this_month
/// (default), this_year, or a custom range encoded as
/// 'custom:YYYY-MM-DD:YYYY-MM-DD'.
class ProductPerformanceQuery {
  final String segment;
  final String period;
  final int page;
  final int limit;

  const ProductPerformanceQuery({
    this.segment = 'fast_selling',
    this.period = 'this_month',
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductPerformanceQuery &&
          segment == other.segment &&
          period == other.period &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(segment, period, page, limit);
}

final productPerformanceProvider =
    FutureProvider.family<List<ProductPerformance>, ProductPerformanceQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getProductPerformance(
        segment: query.segment,
        period: query.period,
        page: query.page,
        limit: query.limit,
      );
    });

/// Query object for the Purchases & Suppliers screen (Card 3) — Suppliers
/// tab. [period] drives the Date Range filter: today, this_week, this_month
/// (default), this_year, or 'custom:YYYY-MM-DD:YYYY-MM-DD'.
class SupplierSummariesQuery {
  final String period;
  final int page;
  final int limit;

  const SupplierSummariesQuery({
    this.period = 'this_month',
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierSummariesQuery &&
          period == other.period &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(period, page, limit);
}

final supplierSummariesProvider =
    FutureProvider.family<List<SupplierSummary>, SupplierSummariesQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getSupplierSummaries(
        period: query.period,
        page: query.page,
        limit: query.limit,
      );
    });

/// Query object for the Purchases & Suppliers screen (Card 3) — Purchase
/// Orders tab. Pending/Completed status is filtered locally (like the
/// Sales Reports payment-status chips) so switching status doesn't refetch.
class PurchaseOrdersQuery {
  final String period;
  final String search;
  final int page;
  final int limit;

  const PurchaseOrdersQuery({
    this.period = 'this_month',
    this.search = '',
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrdersQuery &&
          period == other.period &&
          search == other.search &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(period, search, page, limit);
}

final purchaseOrdersReportProvider =
    FutureProvider.family<List<PurchaseOrderSummary>, PurchaseOrdersQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getPurchaseOrdersReport(
        period: query.period,
        search: query.search,
        page: query.page,
        limit: query.limit,
      );
    });

final supplierDetailProvider = FutureProvider.family<SupplierDetail, String>((
  ref,
  id,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getSupplierDetail(id);
});

final customerDetailProvider = FutureProvider.family<CustomerDetail, String>((
  ref,
  id,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getCustomerDetail(id);
});

final purchaseOrderDetailProvider =
    FutureProvider.family<PurchaseOrderDetail, String>((ref, id) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getPurchaseOrderDetail(id);
    });

/// Query object for the Services Reports screen.
///
/// [category] is the selected service category. Use 'all' for all categories.
///
/// [period] can be:
/// - today
/// - this_week
/// - this_month
/// - this_year
/// - custom:YYYY-MM-DD:YYYY-MM-DD
class ServiceJobsQuery {
  final String category;
  final String period;
  final int page;
  final int limit;

  const ServiceJobsQuery({
    this.category = 'all',
    this.period = 'this_month',
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceJobsQuery &&
          category == other.category &&
          period == other.period &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(category, period, page, limit);
}

/// Service jobs list provider used by ServicesReportsScreen.
///
/// The screen passes a compact key in this format:
/// 'category|period'
///
/// Example:
/// 'all|this_month'
/// 'all|custom:2026-08-01:2026-08-31'
final serviceJobsProvider =
    FutureProvider.family<List<ServiceJobSummary>, String>((ref, key) async {
      final repo = ref.watch(reportsRepositoryProvider);

      String category = 'all';
      String period = 'this_month';

      final separatorIndex = key.indexOf('|');

      if (separatorIndex >= 0) {
        category = key.substring(0, separatorIndex);
        period = key.substring(separatorIndex + 1);
      } else if (key.trim().isNotEmpty) {
        category = key.trim();
      }

      return await repo.getServiceJobs(
        category: category,
        period: period,
        page: 1,
        limit: 100,
      );
    });

final serviceJobDetailProvider =
    FutureProvider.family<ServiceJobDetail, String>((ref, id) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getServiceJobDetail(id);
    });

final profitabilityReportProvider =
    FutureProvider.family<ProfitabilityReport, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getProfitabilityReport(range: range);
    });

final inventoryStockSummaryProvider =
    FutureProvider.family<InventoryStockSummary, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getInventoryStockSummary(range: range);
    });

final stockMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getStockMovements(range: range);
    });

final receivedOrdersProvider =
    FutureProvider.family<List<ReceivedOrderRow>, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getReceivedOrders(range: range);
    });

final pendingOrdersProvider =
    FutureProvider.family<List<PendingOrderRow>, String>((ref, range) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return await repo.getPendingOrders(range: range);
    });

final lowStockAlertsProvider = FutureProvider<List<LowStockAlertRow>>((
  ref,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getLowStockAlerts();
});

