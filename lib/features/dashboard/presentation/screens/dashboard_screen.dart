import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_management/features/reports/presentation/screens/reports_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../customers/presentation/screens/customer_screen.dart';
import 'package:stock_management/features/settings/presentation/screens/operations/printers_hardware/printer_management/printers_hardware_screen.dart';
import '../../../inventory/presentation/screens/new_purchase_order_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int totalProducts = 0;
  int totalSales = 0;
  int totalSuppliers = 0;
  int lowStock = 0;

  int pastProducts = 0;
  int pastSales = 0;
  int pastSuppliers = 0;
  int pastLowStock = 0;

  double todaySalesAmount = 0.0;
  double receivablesAmount = 0.0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final products = await DBHelper.getProductCount();
    final sales = await DBHelper.getSalesCount();
    final suppliers = await DBHelper.getSupplierCount();
    final lowStocks = await DBHelper.getLowStockCount();

    totalProducts = products;

    // Hero card trend calculates based on today's sales transactions if needed
    totalSales = sales;

    // ── FIXED: Assigned the db result to the correct state variable totalSuppliers ──
    totalSuppliers = suppliers;
    lowStock = lowStocks;

    pastProducts = await DBHelper.getPastProductCount();
    pastSales = await DBHelper.getPastSalesCount();
    pastSuppliers = await DBHelper.getPastSupplierCount();
    pastLowStock = await DBHelper.getPastLowStockCount();

    // Swapped database values here
    // 1. Hero Card gets Today's Sales Amount (converted to int for UI parsing)
    final todaySalesRaw = await DBHelper.getTodaySales();
    // 2. Today's Sales Card gets the total historical Sales Value count
    final totalSalesCountRaw = await DBHelper.getSalesCount();

    todaySalesAmount = totalSalesCountRaw.toDouble();
    // We repurpose totalSales to act as the Hero Card's value directly
    totalSales = todaySalesRaw.toInt();

    receivablesAmount = await DBHelper.getReceivablesAmount();

    if (mounted) {
      setState(() {});
    }
  }

  String _formatIndianCurrency(double amount) {
    if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k";
    } else {
      return "₹${amount.toStringAsFixed(0)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: AppSpacing.lg);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: hPad.copyWith(
            top: R.sp(context, AppSpacing.lg),
            bottom: R.sp(context, AppSpacing.xxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome, Admin 👋", style: AppTextStyles.heading),
                        SizedBox(height: R.sp(context, AppSpacing.xs)),
                        Text(
                          "Here's what's happening today.",
                          style: AppTextStyles.subHeading,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: R.icon(context, 20),
                      ),
                    ),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.sm)),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    child: Center(
                      child: Text(
                        "A",
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.lg)),

              // Hero Card (Now rendering Today's Sales Value)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(R.sp(context, AppSpacing.xl)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A3A6B), Color(0xFF0A1628)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TODAY'S SALES",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.2,
                            fontSize: R.fs(context, 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                MetricHelper.checkIsPositive(
                                      totalSales,
                                      pastSales,
                                    )
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color:
                                    MetricHelper.checkIsPositive(
                                      totalSales,
                                      pastSales,
                                    )
                                    ? AppColors.green
                                    : AppColors.red,
                                size: R.icon(context, 12),
                              ),
                              SizedBox(width: R.sp(context, 4)),
                              Text(
                                "${MetricHelper.calculatePercentage(totalSales, pastSales).abs().toStringAsFixed(1)}%",
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: R.fs(context, 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.sm)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatIndianCurrency(totalSales.toDouble()),
                        style: AppTextStyles.heading.copyWith(
                          color: Colors.white,
                          fontSize: R.fs(context, 36),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.sm)),
                    Row(
                      children: [
                        Text(
                          "$totalProducts products",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white54,
                            fontSize: R.fs(context, 12),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(5, (i) {
                            final heights = [12.0, 18.0, 14.0, 22.0, 16.0];
                            return Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Container(
                                width: 6,
                                height: heights[i],
                                decoration: BoxDecoration(
                                  color: i == 3
                                      ? AppColors.cyan
                                      : Colors.white.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),

              // Attention Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Needs attention", style: AppTextStyles.sectionTitle),
                ],
              ),
              SizedBox(height: R.sp(context, AppSpacing.sm)),
              Row(
                children: [
                  Expanded(
                    child: _attentionCard(
                      context,
                      icon: Icons.inventory,
                      iconColor: AppColors.cyan,
                      bgColor: AppColors.cyan.withOpacity(0.08),
                      count: "$totalProducts",
                      countColor: AppColors.cyan,
                      label: "Total Products",
                      percentage: MetricHelper.calculatePercentage(
                        totalProducts,
                        pastProducts,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        totalProducts,
                        pastProducts,
                      ),
                    ),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  Expanded(
                    child: _attentionCard(
                      context,
                      icon: Icons.warning,
                      iconColor: AppColors.red,
                      bgColor: AppColors.red.withOpacity(0.08),
                      count: "$lowStock",
                      countColor: AppColors.red,
                      label: "Low Stock Items",
                      percentage: MetricHelper.calculatePercentage(
                        lowStock,
                        pastLowStock,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        lowStock,
                        pastLowStock,
                      ),
                    ),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  Expanded(
                    child: _attentionCard(
                      context,
                      icon: Icons.people,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.primary.withOpacity(0.08),
                      count: "$totalSuppliers",
                      countColor: AppColors.primary,
                      label: "Suppliers",
                      percentage: MetricHelper.calculatePercentage(
                        totalSuppliers,
                        pastSuppliers,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        totalSuppliers,
                        pastSuppliers,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),

              // Daily Summary Row
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      context,
                      "Sales Value",
                      _formatIndianCurrency(todaySalesAmount),
                      icon: Icons.attach_money_rounded,
                      iconColor: AppColors.green,
                    ),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.md)),
                  Expanded(
                    child: _summaryCard(
                      context,
                      "Receivables",
                      _formatIndianCurrency(receivablesAmount),
                      icon: Icons.credit_card_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),

              // Quick Actions Section
              Text("Quick Actions", style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              GridView.count(
                crossAxisCount: 4, // 4 columns per row
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: R.sp(
                  context,
                  AppSpacing.xs,
                ), // ⬇️ DECREASED: Tightens the space between Row 1 and Row 2
                crossAxisSpacing: 0,
                childAspectRatio: 0.88,
                children: [
                  // 1
                  _quickActionCircle(
                    context: context,
                    icon: Icons.people_outline,
                    label: "Customers",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomersScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 2
                  _quickActionCircle(
                    context: context,
                    icon: Icons.local_shipping_outlined,
                    label: "Suppliers",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuppliersScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 3
                  _quickActionCircle(
                    context: context,
                    icon: Icons.print_outlined,
                    label: "Printer",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrintersHardwareScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 4
                  _quickActionCircle(
                    context: context,
                    icon: Icons.add_box_outlined,
                    label: "Add Product",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 5
                  _quickActionCircle(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: "Purchase Order",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewPurchaseOrderScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 6
                  _quickActionCircle(
                    context: context,
                    icon: Icons.bar_chart_outlined,
                    label: "Reports",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportsScreen(),
                        ),
                      );
                      loadDashboardData();
                    },
                  ),
                  // 7
                  _quickActionCircle(
                    context: context,
                    icon: Icons.currency_rupee,
                    label: "New Sale",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CurrentBillScreen()),
                      );
                      loadDashboardData();
                    },
                  ),
                  // Empty space placeholder
                  const SizedBox.shrink(),
                ],
              ),
              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _attentionCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color bgColor,
  required String count,
  required Color countColor,
  required String label,
  required double percentage,
  required bool isPositive,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: R.sp(context, AppSpacing.sm),
      vertical: R.sp(context, AppSpacing.md),
    ),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: iconColor.withOpacity(0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: R.icon(context, 18)),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: R.icon(context, 10),
                  color: isPositive ? AppColors.green : AppColors.red,
                ),
                SizedBox(width: R.sp(context, 2)),
                Text(
                  "${percentage.toStringAsFixed(0)}%",
                  style: AppTextStyles.small.copyWith(
                    color: isPositive ? AppColors.green : AppColors.red,
                    fontSize: R.fs(context, 9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: R.sp(context, AppSpacing.sm)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count,
            style: AppTextStyles.cardValue.copyWith(
              color: countColor,
              fontSize: R.fs(context, 22),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: R.sp(context, 2)),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: R.fs(context, 10),
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _quickActionCircle({
  required BuildContext context,
  required IconData icon,
  required String label,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
        ),
        SizedBox(height: R.sp(context, AppSpacing.xs)),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 11),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _summaryCard(
  BuildContext context,
  String title,
  String value, {
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
        ),
        SizedBox(width: R.sp(context, AppSpacing.sm)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: R.fs(context, 12),
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: R.sp(context, AppSpacing.xs)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 18),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MetricHelper {
  static double calculatePercentage(num current, num previous) {
    if (previous == 0) return 0.0;
    double change = ((current - previous) / previous) * 100;
    return double.parse(change.toStringAsFixed(1));
  }

  static bool checkIsPositive(num current, num previous) {
    return current >= previous;
  }
}
