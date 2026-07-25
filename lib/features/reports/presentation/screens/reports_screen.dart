// lib/features/reports/presentation/screens/reports_screen.dart
//
// Simplified Reports Screen:
// - Top summary cards: total products, inventory value, today stock in/out.
// - Main list: each stock movement as a card, sorted latest first.
// - Clean, scrollable, all cards.
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/responsive_helper.dart';

// ---- Models ----
class DashboardData {
  final int totalProducts;
  final int totalUnits;
  final double inventoryValue;
  final double totalPurchases;
  final double totalSales;
  final double grossProfit;
  final int lowStock;

  DashboardData({
    required this.totalProducts,
    required this.totalUnits,
    required this.inventoryValue,
    required this.totalPurchases,
    required this.totalSales,
    required this.grossProfit,
    required this.lowStock,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalProducts: json['total_products'] ?? 0,
      totalUnits: json['total_units'] ?? 0,
      inventoryValue: (json['inventory_value'] ?? 0).toDouble(),
      totalPurchases: (json['total_purchases'] ?? 0).toDouble(),
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      grossProfit: (json['gross_profit'] ?? 0).toDouble(),
      lowStock: json['low_stock'] ?? 0,
    );
  }
}

class Movement {
  final int id;
  final int productId;
  final String productName;
  final String sku;
  final String movementType;
  final String referenceType;
  final int? referenceId;
  final double quantity;
  final double stockBefore;
  final double stockAfter;
  final double unitCost;
  final String remarks;
  final DateTime createdAt;

  Movement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.movementType,
    required this.referenceType,
    this.referenceId,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    required this.unitCost,
    required this.remarks,
    required this.createdAt,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      sku: json['sku'] ?? '',
      movementType: json['movement_type'] ?? '',
      referenceType: json['reference_type'] ?? '',
      referenceId: json['reference_id'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      stockBefore: (json['stock_before'] ?? 0).toDouble(),
      stockAfter: (json['stock_after'] ?? 0).toDouble(),
      unitCost: (json['unit_cost'] ?? 0).toDouble(),
      remarks: json['remarks'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ---- Providers ----
final reportsDashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final uri = Uri.parse('${ApiConfig.reports}?action=dashboard');
  final response = await http.get(uri, headers: ApiConfig.jsonHeaders);
  if (response.statusCode == 200) {
    final res = json.decode(response.body);
    if (res['success'] == true && res['data'] != null) {
      return DashboardData.fromJson(res['data']);
    }
  }
  throw Exception('Failed to load dashboard');
});

final movementsListProvider = FutureProvider.autoDispose<List<Movement>>((ref) async {
  final uri = Uri.parse('${ApiConfig.reports}?action=movements_list&limit=100');
  final response = await http.get(uri, headers: ApiConfig.jsonHeaders);
  if (response.statusCode == 200) {
    final res = json.decode(response.body);
    if (res['success'] == true && res['data'] != null) {
      final list = res['data'] as List<dynamic>;
      return list.map((item) => Movement.fromJson(item)).toList();
    }
  }
  throw Exception('Failed to load movements');
});

// ---- Main Screen ----
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(reportsDashboardProvider);
    final movementsAsync = ref.watch(movementsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text('Reports', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.refresh(reportsDashboardProvider);
              ref.refresh(movementsListProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(reportsDashboardProvider);
          ref.refresh(movementsListProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Column(
          children: [
            // Summary Cards (top)
            dashboardAsync.when(
              loading: () => _buildLoadingSummary(context),
              error: (e, _) => _buildErrorSummary(context, e.toString()),
              data: (data) => _buildSummaryCards(context, data),
            ),
            // Movements List
            Expanded(
              child: movementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading movements: $e',
                    style: AppTextStyles.small.copyWith(color: AppColors.red)),
                ),
                data: (movements) => _buildMovementsList(context, movements),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Helper: Loading Summary ----
  Widget _buildLoadingSummary(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      height: R.sp(context, 110),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ---- Helper: Error Summary ----
  Widget _buildErrorSummary(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      height: R.sp(context, 110),
      child: Center(
        child: Text('Error: $error',
          style: AppTextStyles.small.copyWith(color: AppColors.red)),
      ),
    );
  }

  // ---- Helper: Summary Cards ----
  Widget _buildSummaryCards(BuildContext context, DashboardData data) {
    final items = [
      _SummaryItem(
        label: 'Products',
        value: '${data.totalProducts}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _SummaryItem(
        label: 'Stock Value',
        value: '₹${NumberFormat('#,##0').format(data.inventoryValue)}',
        icon: Icons.pie_chart,
        color: AppColors.green,
      ),
      _SummaryItem(
        label: 'Low Stock',
        value: '${data.lowStock}',
        icon: Icons.warning_amber_outlined,
        color: AppColors.red,
      ),
      _SummaryItem(
        label: 'Sales',
        value: '₹${NumberFormat('#,##0').format(data.totalSales)}',
        icon: Icons.arrow_upward_outlined,
        color: Colors.blue,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: R.sp(context, 2)),
              padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.sm)),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.cardRadius)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: item.color, size: R.icon(context, 20)),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                    item.value,
                    style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 14)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.label,
                    style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 10)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- Helper: Movements List ----
  Widget _buildMovementsList(BuildContext context, List<Movement> movements) {
    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: R.sp(context, AppSpacing.sm)),
            Text('No movements found', style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 13))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      itemCount: movements.length,
      itemBuilder: (ctx, index) {
        final m = movements[index];
        return _MovementCard(movement: m);
      },
    );
  }
}

// ---- Movement Card Widget ----
class _MovementCard extends StatelessWidget {
  final Movement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.movementType == 'STOCK_IN';
    final isOut = movement.movementType == 'STOCK_OUT';
    final isSale = movement.movementType == 'SALE';
    final isOpening = movement.movementType == 'OPENING_STOCK';

    String typeLabel;
    Color chipColor;
    if (isIn) { typeLabel = 'Stock In'; chipColor = AppColors.green; }
    else if (isOut) { typeLabel = 'Stock Out'; chipColor = AppColors.red; }
    else if (isSale) { typeLabel = 'Sale'; chipColor = Colors.blue; }
    else if (isOpening) { typeLabel = 'Opening Stock'; chipColor = Colors.grey; }
    else { typeLabel = movement.movementType; chipColor = Colors.orange; }

    final quantity = movement.quantity;
    final isPositive = quantity > 0;

    // Reference
    String reference = '';
    if (movement.referenceType == 'PURCHASE' && movement.referenceId != null) {
      reference = 'PO #${movement.referenceId}';
    } else if (movement.referenceType == 'INVOICE' && movement.referenceId != null) {
      reference = 'Invoice #${movement.referenceId}';
    } else if (movement.referenceType == 'MANUAL') {
      reference = 'Manual';
    }

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.cardRadius)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product name + SKU
          Row(
            children: [
              Expanded(
                child: Text(
                  movement.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: R.fs(context, 15),
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (movement.sku.isNotEmpty)
                Text(
                  'SKU: ${movement.sku}',
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                ),
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.xs)),
          // Row 2: Type chip + Date + Reference
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: R.sp(context, 8), vertical: R.sp(context, 3)),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: R.fs(context, 11),
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(movement.createdAt),
                style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
              ),
              if (reference.isNotEmpty) ...[
                const Spacer(),
                Text(
                  reference,
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                ),
              ],
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          // Row 3: Quantity + Unit Cost
          Row(
            children: [
              Text(
                'Qty: ',
                style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
              ),
              Text(
                '${isPositive ? '+' : ''}${quantity.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(context, 14),
                  color: isPositive ? AppColors.green : AppColors.red,
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.md)),
              if (movement.unitCost > 0) ...[
                Text(
                  'Unit Cost: ₹${movement.unitCost.toStringAsFixed(2)}',
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                ),
              ],
              if (isOpening) ...[
                const Spacer(),
                Text(
                  'Before: ${movement.stockBefore.toStringAsFixed(0)} → After: ${movement.stockAfter.toStringAsFixed(0)}',
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                ),
              ],
            ],
          ),
          // Row 4: Remarks (if any)
          if (movement.remarks.isNotEmpty) ...[
            SizedBox(height: R.sp(context, 4)),
            Text(
              movement.remarks,
              style: AppTextStyles.small.copyWith(
                fontSize: R.fs(context, 11),
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Row 5: Stock before/after for non-opening? Optional, show if helpful.
          if (!isOpening) ...[
            SizedBox(height: R.sp(context, 2)),
            Row(
              children: [
                Text(
                  'Stock: ${movement.stockBefore.toStringAsFixed(0)} → ${movement.stockAfter.toStringAsFixed(0)}',
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 10), color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---- Helper Summary Item ----
class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _SummaryItem({required this.label, required this.value, required this.icon, required this.color});
}