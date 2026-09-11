import '../../domain/entities/payable_supplier.dart';
import '../../domain/entities/receivable_customer.dart';
import '../../domain/entities/report_bill.dart';
import '../../domain/entities/report_extras.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, double>> getDashboardMetrics() async {
    return await remoteDataSource.getDashboardMetrics();
  }

  @override
  Future<List<Map<String, dynamic>>> getChartPoints(
    String filter, {
    String? from,
    String? to,
  }) async {
    return await remoteDataSource.getChartPoints(filter, from: from, to: to);
  }

  @override
  Future<List<PayableSupplier>> getPayableSuppliers() async {
    return await remoteDataSource.getPayableSuppliers();
  }

  @override
  Future<List<ReceivableCustomer>> getReceivableCustomers() async {
    return await remoteDataSource.getReceivableCustomers();
  }

  @override
  Future<List<ReportBill>> getReportBills(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await remoteDataSource.getReportBills(startDate, endDate);
  }

  @override
  Future<void> reprintBill(String billId) async {
    await remoteDataSource.reprintBill(billId);
  }

  @override
  Future<ReportOverviewSummary> getReportsOverview({
    String range = 'this_month',
  }) async {
    return await remoteDataSource.getReportsOverview(range: range);
  }

  @override
  Future<List<ReportBill>> getSalesReports({
    String filter = 'ALL',
    String query = '',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getSalesReports(
      filter: filter,
      query: query,
      period: period,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<InvoiceDetail> getInvoiceDetail(String invoiceId) async {
    return await remoteDataSource.getInvoiceDetail(invoiceId);
  }

  @override
  Future<List<ProductPerformance>> getProductPerformance({
    String segment = 'fast_selling',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getProductPerformance(
      segment: segment,
      period: period,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<SupplierSummary>> getSupplierSummaries({
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getSupplierSummaries(
      period: period,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<SupplierDetail> getSupplierDetail(
    String supplierId, {
    String period = 'all',
  }) async {
    return await remoteDataSource.getSupplierDetail(supplierId, period: period);
  }

  @override
  Future<CustomerDetail> getCustomerDetail(
    String customerId, {
    String period = 'all',
  }) async {
    return await remoteDataSource.getCustomerDetail(customerId, period: period);
  }

  @override
  Future<PurchaseOrderDetail> getPurchaseOrderDetail(String purchaseId) async {
    return await remoteDataSource.getPurchaseOrderDetail(purchaseId);
  }

  @override
  Future<List<PurchaseOrderSummary>> getPurchaseOrdersReport({
    String period = 'this_month',
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getPurchaseOrdersReport(
      period: period,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<ServiceJobSummary>> getServiceJobs({
    String category = 'all',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getServiceJobs(
      category: category,
      period: period,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ServiceJobDetail> getServiceJobDetail(String jobId) async {
    return await remoteDataSource.getServiceJobDetail(jobId);
  }

  @override
  Future<ProfitabilityReport> getProfitabilityReport({
    String range = 'this_month',
    String view = 'overview',
  }) async {
    return await remoteDataSource.getProfitabilityReport(
      range: range,
      view: view,
    );
  }

  @override
  Future<InventoryStockSummary> getInventoryStockSummary({
    String range = 'this_month',
  }) async {
    return await remoteDataSource.getInventoryStockSummary(range: range);
  }

  @override
  Future<List<StockMovement>> getStockMovements({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getStockMovements(
      range: range,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<ReceivedOrderRow>> getReceivedOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getReceivedOrders(
      range: range,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<PendingOrderRow>> getPendingOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getPendingOrders(
      range: range,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<LowStockAlertRow>> getLowStockAlerts({
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDataSource.getLowStockAlerts(page: page, limit: limit);
  }
}
