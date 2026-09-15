import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/domain/entities/report_bill.dart';
import '../../../reports/presentation/providers/reports_provider.dart';

/// Every bill raised to [customerName].
///
/// Why this instead of reports.php's `customer_detail` action: that
/// action is keyed by the customer's numeric id, and reports.php's
/// internal sales records don't reliably line up with the real
/// `customers` table id (we saw the mirror-image bug on the payable
/// side — phantom entries that don't exist in the real Suppliers list —
/// a clear sign of an id mismatch between the two systems).
/// `getSalesReports` is the exact same action your already-working
/// Sales Reports screen uses (`reports.php?action=sales`), searched by
/// customer NAME instead of id — names are consistent across both
/// systems, so this reliably returns every bill for this customer.
final customerBillsProvider = FutureProvider.family<List<ReportBill>, String>((
  ref,
  customerName,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final results = await repo.getSalesReports(
    period: 'all',
    query: customerName,
    limit: 100,
  );
  // Defensive: `search` may fuzzy-match on the backend (it also matches
  // invoice numbers), so keep only rows that are actually this customer.
  final needle = customerName.trim().toLowerCase();
  if (needle.isEmpty) return results;
  return results.where((b) => b.customerName.trim().toLowerCase() == needle).toList();
});
