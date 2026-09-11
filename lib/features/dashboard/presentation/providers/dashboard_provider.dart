import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_remote_datasource.dart';

/// ===========================================================
/// UI State
/// ===========================================================

final dashboardFilterProvider = StateProvider<String>((ref) => "Day");
final graphVisibilityProvider = StateProvider<bool>((ref) => true);

/// ===========================================================
/// Dashboard State Model
/// ===========================================================

class DashboardState {
  final bool isLoading;
  final String? error;

  final int totalProducts;
  final int totalSuppliers;
  final int totalSales;
  final int lowStock;

  final int pastProducts;
  final int pastSuppliers;
  final int pastSales;
  final int pastLowStock;

  final double totalSalesAmount;
  final double todaySales;
  final double receivables;
  final int productsSoldToday;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.totalProducts = 0,
    this.totalSuppliers = 0,
    this.totalSales = 0,
    this.lowStock = 0,
    this.pastProducts = 0,
    this.pastSuppliers = 0,
    this.pastSales = 0,
    this.pastLowStock = 0,
    this.totalSalesAmount = 0,
    this.todaySales = 0,
    this.receivables = 0,
    this.productsSoldToday = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    int? totalProducts,
    int? totalSuppliers,
    int? totalSales,
    int? lowStock,
    int? pastProducts,
    int? pastSuppliers,
    int? pastSales,
    int? pastLowStock,
    int? productsSoldToday,
    double? totalSalesAmount,
    double? todaySales,
    double? receivables,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      totalSales: totalSales ?? this.totalSales,
      lowStock: lowStock ?? this.lowStock,
      pastProducts: pastProducts ?? this.pastProducts,
      pastSuppliers: pastSuppliers ?? this.pastSuppliers,
      pastSales: pastSales ?? this.pastSales,
      pastLowStock: pastLowStock ?? this.pastLowStock,
      totalSalesAmount: totalSalesAmount ?? this.totalSalesAmount,
      todaySales: todaySales ?? this.todaySales,
      receivables: receivables ?? this.receivables,
      productsSoldToday: productsSoldToday ?? this.productsSoldToday,
    );
  }

  // 🔴 CRITICAL: Value Equality Overrides so Riverpod knows data actually changed
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DashboardState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.totalProducts == totalProducts &&
        other.totalSuppliers == totalSuppliers &&
        other.totalSales == totalSales &&
        other.lowStock == lowStock &&
        other.pastProducts == pastProducts &&
        other.pastSuppliers == pastSuppliers &&
        other.pastSales == pastSales &&
        other.pastLowStock == pastLowStock &&
        other.totalSalesAmount == totalSalesAmount &&
        other.todaySales == todaySales &&
        other.receivables == receivables &&
        other.productsSoldToday == productsSoldToday;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      error,
      totalProducts,
      totalSuppliers,
      totalSales,
      lowStock,
      pastProducts,
      pastSuppliers,
      pastSales,
      pastLowStock,
      totalSalesAmount,
      todaySales,
      receivables,
      productsSoldToday,
    );
  }
}

/// ===========================================================
/// Provider
/// ===========================================================

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(ref),
);

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardNotifier(this.ref) : super(const DashboardState()) {
    loadDashboard(showLoading: true);
  }

  final DashboardRemoteDataSource _remote = DashboardRemoteDataSource();

  @override
  bool updateShouldNotify(DashboardState old, DashboardState current) {
    return old != current;
  }

  Future<void> loadDashboard({bool showLoading = true}) async {
    try {
      if (showLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final data = await _remote.getDashboard();

      state = state.copyWith(
        isLoading: false,
        error: null,
        totalProducts: _toInt(data['total_products']),
        totalSuppliers: _toInt(data['total_suppliers']),
        totalSales: _toInt(data['total_sales']),
        lowStock: _toInt(data['low_stock']),
        pastProducts: _toInt(data['past_products']),
        pastSuppliers: _toInt(data['past_suppliers']),
        pastSales: _toInt(data['past_sales']),
        pastLowStock: _toInt(data['past_low_stock']),
        totalSalesAmount: _toDouble(data['total_sales_amount']),
        todaySales: _toDouble(data['today_sales']),
        receivables: _toDouble(data['receivables']),
        productsSoldToday: _toInt(data['products_sold_today']),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "NETWORK_ERROR",
      );
    }
  }

  /// Triggers quiet background refresh without disturbing the user with a full-screen loader
  Future<void> refresh() async {
    await loadDashboard(showLoading: false);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? (double.tryParse(value)?.toInt() ?? 0);
    }
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}