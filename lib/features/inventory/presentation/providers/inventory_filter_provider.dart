// ===========================================================
// lib/features/inventory/presentation/providers/inventory_filter_provider.dart
// ===========================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';


/// ===========================================================
/// Inventory Filter
///
/// Supported filters:
/// all
/// low
/// out
/// expiring
/// expired
///
/// Backend mapping:
///
/// all      → all active products
/// low      → current_stock > 0 AND current_stock <= reorder_level
/// out      → current_stock = 0
/// expiring → expiry_date >= today
///             AND expiry_date <= today + 30 days
/// expired  → expiry_date < today
/// ===========================================================

final inventoryFilterProvider =
    StateProvider<String>((ref) => 'all');


/// ===========================================================
/// Search Query
/// ===========================================================

final inventorySearchProvider =
    StateProvider<String>((ref) => '');


/// ===========================================================
/// Sort Option
///
/// Supported values:
///
/// name_asc
/// name_desc
/// stock_asc
/// stock_desc
/// value_desc
/// value_asc
/// ===========================================================

final inventorySortProvider =
    StateProvider<String>((ref) => 'name_asc');


/// ===========================================================
/// Pagination
/// ===========================================================

final inventoryPageProvider =
    StateProvider<int>((ref) => 1);

final inventoryLimitProvider =
    StateProvider<int>((ref) => 20);


/// ===========================================================
/// Refresh Trigger
///
/// Increment this value to refresh all inventory providers.
///
/// Example:
///
/// ref.read(inventoryRefreshProvider.notifier).state++;
/// ===========================================================

final inventoryRefreshProvider =
    StateProvider<int>((ref) => 0);


/// ===========================================================
/// Selected Product
///
/// Used in:
/// - Product Detail
/// - Stock In
/// - Stock Out
/// ===========================================================

final selectedProductIdProvider =
    StateProvider<int?>((ref) => null);


/// ===========================================================
/// Selected Purchase Order
///
/// Used in:
/// - Receive Order
/// - PO Detail
/// ===========================================================

final selectedPurchaseOrderProvider =
    StateProvider<int?>((ref) => null);