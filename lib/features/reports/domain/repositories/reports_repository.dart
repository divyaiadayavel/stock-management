import '../entities/payable_supplier.dart';
import '../entities/receivable_customer.dart';
import '../entities/report_bill.dart';
import '../entities/report_extras.dart';

abstract class ReportsRepository {
  Future<Map<String, double>> getDashboardMetrics();
  Future<List<Map<String, dynamic>>> getChartPoints(
    String filter, {
    String? from,
    String? to,
  });
  Future<List<PayableSupplier>> getPayableSuppliers();
  Future<List<ReceivableCustomer>> getReceivableCustomers();
  Future<List<ReportBill>> getReportBills(DateTime startDate, DateTime endDate);
  Future<void> reprintBill(String billId);

  Future<ReportOverviewSummary> getReportsOverview({
    String range = 'this_month',
  });
  Future<List<ReportBill>> getSalesReports({
    String filter = 'ALL',
    String query = '',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<InvoiceDetail> getInvoiceDetail(String invoiceId);
  Future<List<ProductPerformance>> getProductPerformance({
    String segment = 'fast_selling',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<SupplierSummary>> getSupplierSummaries({
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
 Future<SupplierDetail> getSupplierDetail(
  String supplierId, {
  String period = 'all',
});
  Future<CustomerDetail> getCustomerDetail(
    String customerId, {
    String period = 'all',
  });
  Future<PurchaseOrderDetail> getPurchaseOrderDetail(String purchaseId);
  Future<List<PurchaseOrderSummary>> getPurchaseOrdersReport({
    String period = 'this_month',
    String search = '',
    int page = 1,
    int limit = 100,
  });
  Future<List<ServiceJobSummary>> getServiceJobs({
    String category = 'all',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<ServiceJobDetail> getServiceJobDetail(String jobId);
  Future<ProfitabilityReport> getProfitabilityReport({
    String range = 'this_month',
    String view = 'overview',
  });
  Future<InventoryStockSummary> getInventoryStockSummary({
    String range = 'this_month',
  });
  Future<List<StockMovement>> getStockMovements({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<ReceivedOrderRow>> getReceivedOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<PendingOrderRow>> getPendingOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<LowStockAlertRow>> getLowStockAlerts({
    int page = 1,
    int limit = 100,
  });
}
