// lib/features/settings/service_management/data/models/provider_reload_log_model.dart
//
// NEW FILE — additive only.

import '../../domain/entities/provider_reload_log.dart';

class ProviderReloadLogModel extends ProviderReloadLogEntity {
  ProviderReloadLogModel({
    super.id,
    required super.providerId,
    super.providerName,
    super.categoryName,
    super.amount,
    super.balanceBefore,
    super.balanceAfter,
    super.type,
    super.note,
    super.reloadedAt,
  });

  // ── API RESPONSE MAPPING ──
  // Expected shape of each item returned by the backend:
  // {
  //   "id": 12,
  //   "provider_id": 4,
  //   "provider_name": "Airtel Recharge",
  //   "category_name": "Mobile Recharge",
  //   "amount": "500.00",
  //   "balance_before": "0.00",
  //   "balance_after": "500.00",
  //   "type": "INITIAL",           // or "RELOAD" / "RECHARGE"
  //   "note": "Initial load",
  //   "reloaded_at": "2026-09-18 10:15:00"
  // }
  factory ProviderReloadLogModel.fromMap(Map<String, dynamic> map) {
    return ProviderReloadLogModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      providerId: int.tryParse(map['provider_id']?.toString() ?? '') ?? 0,
      providerName: map['provider_name']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      // Added fallback parsing for different amount key names if your API alternates
      amount:
          double.tryParse(
            (map['amount'] ??
                    map['reload_amount'] ??
                    map['loaded_amount'] ??
                    '0')
                .toString(),
          ) ??
          0.0,
      balanceBefore:
          double.tryParse(map['balance_before']?.toString() ?? '0') ?? 0.0,
      balanceAfter:
          double.tryParse(map['balance_after']?.toString() ?? '0') ?? 0.0,
      type: map['type']?.toString().trim().isNotEmpty == true
          ? map['type'].toString().trim().toUpperCase()
          : 'RELOAD',
      note: map['note']?.toString() ?? '',
      // Supporting both 'reloaded_at' and standard 'created_at' timestamps from backend logs
      reloadedAt: (map['reloaded_at'] ?? map['created_at']) != null
          ? DateTime.tryParse(
              (map['reloaded_at'] ?? map['created_at']).toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider_id': providerId,
      'provider_name': providerName,
      'category_name': categoryName,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'type': type,
      'note': note,
      'reloaded_at': reloadedAt?.toIso8601String(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────
// BACKEND CONTRACT REMINDER:
// Ensure your backend endpoint handles action=reload_history and joins 
// the provider & category tables so that `provider_name`, `category_name`, 
// `note`, and `reloaded_at` (or `created_at`) are successfully returned.
// ─────────────────────────────────────────────────────────────────────────