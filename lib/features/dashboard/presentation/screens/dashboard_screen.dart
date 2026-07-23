// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_management/features/reports/presentation/screens/reports_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/dashboard_provider.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
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
  // ── Currency formatter ──
String _formatIndianCurrency(double amount) {
  final value = amount.toStringAsFixed(2);

  final parts = value.split('.');
  final integer = parts[0];
  final decimal = parts[1];

  if (integer.length <= 3) {
    return "₹$integer.$decimal";
  }

  String result = integer.substring(integer.length - 3);
  String prefix = integer.substring(0, integer.length - 3);

  while (prefix.length > 2) {
    result = "${prefix.substring(prefix.length - 2)},$result";
    prefix = prefix.substring(0, prefix.length - 2);
  }

  if (prefix.isNotEmpty) {
    result = "$prefix,$result";
  }

  return "₹$result.$decimal";
}

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);
    final hPad = R.hPad(context, base: AppSpacing.lg);

    // ── Loading ──
    if (dashboard.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error ──
    if (dashboard.error != null) {
      return Scaffold(
        body: Center(
          child: Text(dashboard.error!),
        ),
      );
    }

    // ── Success ──
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
              // =====================================================
              // 🔹 INLINE HEADER
              // =====================================================
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

              // =====================================================
              // 🔹 HERO INVENTORY CARD
              // =====================================================
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
                            color: Colors.white60,
                            letterSpacing: 1.2,
                            fontSize: R.fs(context, 11),
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.sm)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
_formatIndianCurrency(
  dashboard.todaySales,
),
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
  "${dashboard.productsSoldToday} Products Sold Today",
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

// =====================================================
// 🔹 NEEDS ATTENTION
// =====================================================
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Needs attention",
    style: AppTextStyles.sectionTitle,
  ),
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
                      count: "${dashboard.totalProducts}",
                      countColor: AppColors.cyan,
                      label: "Total Products",
                      percentage: MetricHelper.calculatePercentage(
                        dashboard.totalProducts,
                        dashboard.pastProducts,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        dashboard.totalProducts,
                        dashboard.pastProducts,
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
                      count: "${dashboard.lowStock}",
                      countColor: AppColors.red,
                      label: "Low Stock Items",
                      percentage: MetricHelper.calculatePercentage(
                        dashboard.lowStock,
                        dashboard.pastLowStock,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        dashboard.lowStock,
                        dashboard.pastLowStock,
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
                      count: "${dashboard.totalSuppliers}",
                      countColor: AppColors.primary,
                      label: "Suppliers",
                      percentage: MetricHelper.calculatePercentage(
                        dashboard.totalSuppliers,
                        dashboard.pastSuppliers,
                      ).abs(),
                      isPositive: MetricHelper.checkIsPositive(
                        dashboard.totalSuppliers,
                        dashboard.pastSuppliers,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),

              // =====================================================
              // 🔹 DAILY SUMMARY CARDS
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
  context,
  "Sales Value",
  _formatIndianCurrency(dashboard.totalSalesAmount),
  icon: Icons.bar_chart_rounded,
  iconColor: AppColors.green,
),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.md)),
                  Expanded(
                    child: _summaryCard(
                      context,
                      "Receivables",
                      _formatIndianCurrency(dashboard.receivables),
                      icon: Icons.credit_card_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.sectionGap)),

              // =====================================================
              // 🔹 QUICK ACTIONS
              // =====================================================
              Text("Quick Actions", style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              Column(
                children: [
                  // ── FIRST ROW: 4 ITEMS ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
                    ],
                  ),

                  SizedBox(
                    height: R.sp(context, AppSpacing.lg),
                  ), // Vertical gap
                  // ── SECOND ROW: REMAINING 3 ITEMS ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
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
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
                      _quickActionCircle(
                        context: context,
                        icon: Icons.currency_rupee,
                        label: "New Sale",
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CurrentBillScreen(),
                            ),
                          );
                          ref.read(dashboardProvider.notifier).refresh();
                        },
                      ),
                      // Empty placeholder to align the 3 items neatly underneath the 4 items above
                      const SizedBox(width: 56),
                    ],
                  ),
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

// =====================================================
// 🔹 ATTENTION CARD (Streamlined UI)
// =====================================================
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

// =====================================================
// 🔹 SUMMARY CARD
// =====================================================
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

// =====================================================
// 🔹 METRIC HELPER
// =====================================================

// ── MetricHelper with null safety ──
class MetricHelper {
  static double calculatePercentage(num? current, num? previous) {
    if (previous == null || previous == 0) return 0.0;
    if (current == null) return 0.0;
    final change = ((current - previous) / previous) * 100;
    return double.parse(change.toStringAsFixed(1));
  }

  static bool checkIsPositive(num? current, num? previous) {
    if (current == null || previous == null) return false;
    return current >= previous;
  }
}