// lib/features/reports/presentation/providers/provider_reports_data_provider.dart
//
// Feeds the Provider Reports screen.
//
// IMPORTANT:
// Provider filtering is intentionally NOT done in this provider.
// The Provider Reports screen filters the already date-filtered list locally,
// exactly like Sales Reports does. This keeps ALL provider filter chips visible
// after selecting one provider.
//
// The report key is still kept as:
//   "<providerFilter>|<period>"
// or
//   "<providerFilter>|custom:from:to"
// so the existing Provider Reports screen/cache structure continues to work.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/presentation/providers/provider_recharge_provider.dart';
import '../../../services/data/models/provider_recharge_model.dart';
import '../../../settings/service_management/data/models/provider_reload_log_model.dart';
import '../../../settings/service_management/presentation/providers/provider_reload_log_provider.dart';

class _ParsedReportKey {
  final String providerFilter; // Kept for cache/key compatibility.
  final DateTime start;
  final DateTime end;

  const _ParsedReportKey(this.providerFilter, this.start, this.end);
}

_ParsedReportKey _parseKey(String key) {
  final parts = key.split('|');

  // The provider filter is deliberately parsed but NOT applied here.
  // Provider filtering must happen in ProviderReportsScreen so the complete
  // filter list remains visible when a chip is selected.
  final providerFilter = parts.isNotEmpty ? parts[0] : 'all';
  final periodPart = parts.length > 1 ? parts[1] : 'this_month';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (periodPart.startsWith('custom:')) {
    final segments = periodPart.split(':');

    if (segments.length == 3) {
      final startDate = DateTime.tryParse(segments[1]);
      final endDate = DateTime.tryParse(segments[2]);

      if (startDate != null && endDate != null) {
        return _ParsedReportKey(
          providerFilter,
          DateTime(startDate.year, startDate.month, startDate.day),
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        );
      }
    }
  }

  switch (periodPart) {
    case 'today':
      return _ParsedReportKey(
        providerFilter,
        today,
        DateTime(today.year, today.month, today.day, 23, 59, 59),
      );

    case 'this_week':
      final monday = today.subtract(Duration(days: today.weekday - 1));

      return _ParsedReportKey(providerFilter, monday, now);

    case 'this_year':
      return _ParsedReportKey(providerFilter, DateTime(now.year, 1, 1), now);

    case 'this_month':
    default:
      return _ParsedReportKey(
        providerFilter,
        DateTime(now.year, now.month, 1),
        now,
      );
  }
}

bool _inRange(DateTime? date, DateTime start, DateTime end) {
  if (date == null) return false;

  return !date.isBefore(start) && !date.isAfter(end);
}

/// Invoices tab.
///
/// IMPORTANT:
/// Only the date range is applied here.
/// The provider filter is applied locally by ProviderReportsScreen.
///
/// This is required so the screen always receives every provider for the
/// selected period and can therefore keep:
///
/// All (10) | Provider A | Provider B | Provider C
///
/// visible even after Provider B is selected.
final providerInvoiceReportsProvider =
    FutureProvider.family<List<ProviderRechargeModel>, String>((
      ref,
      key,
    ) async {
      final parsed = _parseKey(key);

      final all = await ref.watch(providerRechargeHistoryProvider(null).future);

      final filtered = all.where((r) {
        return _inRange(r.submittedAt, parsed.start, parsed.end);
      }).toList();

      filtered.sort(
        (a, b) => (b.submittedAt ?? DateTime(0)).compareTo(
          a.submittedAt ?? DateTime(0),
        ),
      );

      return filtered;
    });

/// Reload Amount tab.
///
/// IMPORTANT:
/// Only the date range is applied here.
/// The provider filter is applied locally by ProviderReportsScreen.
///
/// This keeps all provider names available to the UI while the selected
/// provider controls only the records displayed underneath the chips.
final providerReloadReportsProvider =
    FutureProvider.family<List<ProviderReloadLogModel>, String>((
      ref,
      key,
    ) async {
      final parsed = _parseKey(key);

      final all = await ref.watch(
        providerReloadLogHistoryProvider(null).future,
      );

      final filtered = all.where((r) {
        return _inRange(r.reloadedAt, parsed.start, parsed.end);
      }).toList();

      filtered.sort(
        (a, b) => (b.reloadedAt ?? DateTime(0)).compareTo(
          a.reloadedAt ?? DateTime(0),
        ),
      );

      return filtered;
    });
