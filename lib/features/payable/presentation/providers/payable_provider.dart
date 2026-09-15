import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/domain/entities/report_extras.dart';
import '../../../reports/presentation/providers/reports_provider.dart';

/// Every purchase order raised with [supplierName].
///
/// Why this instead of reports.php's `supplier_detail` action: that
/// action is keyed by the supplier's numeric id, and reports.php's
/// internal purchase records don't reliably line up with the real
/// `suppliers` table id (we saw phantom entries like "Test Supplier
/// Corp" appear in the id-based aggregation that don't exist in the
/// real Suppliers list — a clear sign of an id mismatch between the two
/// systems). `getPurchaseOrdersReport` is the exact same action your
/// already-working Purchases/Reports screens use
/// (`reports.php?action=purchases&view=orders`), searched by supplier
/// NAME instead of id — names are consistent across both systems, so
/// this reliably returns every PO for this supplier.
final supplierPurchaseOrdersProvider = FutureProvider.family<List<PurchaseOrderSummary>, String>((
  ref,
  supplierName,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final results = await repo.getPurchaseOrdersReport(
    period: 'all',
    search: supplierName,
    limit: 100,
  );
  // Defensive: `search` may fuzzy-match on the backend, so keep only
  // rows that are actually this supplier.
  final needle = supplierName.trim().toLowerCase();
  if (needle.isEmpty) return results;
  return results.where((o) => o.supplierName.trim().toLowerCase() == needle).toList();
});
