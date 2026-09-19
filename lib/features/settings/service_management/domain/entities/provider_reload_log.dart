// lib/features/settings/service_management/domain/entities/provider_reload_log.dart
//
// NEW FILE — additive only. Does not modify any existing service_management
// file. One row = one balance-changing event for a recharge provider:
//   • the very first "initial load" entered on Add Provider, and
//   • every later "Reload balance" done from the Providers list screen.
//
// This mirrors the existing ProviderRechargeEntity pattern (services module)
// so Provider Reports can render both lists with the same shared widgets.

class ProviderReloadLogEntity {
  final int? id;
  final int providerId;
  final String providerName;
  final String categoryName;

  final double amount;
  final double balanceBefore;
  final double balanceAfter;

  /// 'INITIAL' for the opening load made on Add Provider,
  /// 'RELOAD' for every later top-up from the Providers list screen.
  final String type;

  final String note;
  final DateTime? reloadedAt;

  const ProviderReloadLogEntity({
    this.id,
    required this.providerId,
    this.providerName = '',
    this.categoryName = '',
    this.amount = 0.0,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
    this.type = 'RELOAD',
    this.note = '',
    this.reloadedAt,
  });
}
