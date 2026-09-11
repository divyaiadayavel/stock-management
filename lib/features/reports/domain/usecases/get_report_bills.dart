import '../entities/report_bill.dart';
import '../repositories/reports_repository.dart';

class GetReportBills {
  final ReportsRepository repository;

  GetReportBills(this.repository);

  Future<List<ReportBill>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getReportBills(startDate, endDate);
  }
}
