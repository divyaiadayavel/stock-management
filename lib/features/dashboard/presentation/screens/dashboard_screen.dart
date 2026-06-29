import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/utils/responsive_helper.dart';

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
    totalSales = sales;
    totalSuppliers = suppliers;
    lowStock = lowStocks;

    pastProducts = await DBHelper.getPastProductCount();
    pastSales = await DBHelper.getPastSalesCount();
    pastSuppliers = await DBHelper.getPastSupplierCount();
    pastLowStock = await DBHelper.getPastLowStockCount();

    todaySalesAmount = 290000;
    receivablesAmount = 48000;

    setState(() {});
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
    final gridCols = R.gridCols(context, phone: 2, tablet: 4, desktop: 4);
    final gridRatio = R.gridRatio(
      context,
      phone: 1.8,
      tablet: 2.0,
      desktop: 2.2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── NO APPBAR ────────────────────────────────────────
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
              // 🔹 INLINE HEADER  (replaces AppBar)
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good morning, Admin 👋",
                          style: AppTextStyles.heading,
                        ),
                        SizedBox(height: R.sp(context, AppSpacing.xs)),
                        Text(
                          "Here's what's happening today.",
                          style: AppTextStyles.subHeading,
                        ),
                      ],
                    ),
                  ),

                  // Avatar / initials
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      "A",
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.sp(context, AppSpacing.lg)),

              // =====================================================
              // 🔹 HERO INVENTORY CARD  (dark blue gradient)
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
                    // Top row: label + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SALES VALUE",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white60,
                            letterSpacing: 1.2,
                            fontSize: R.fs(context, 11),
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
                                Icons.trending_up,
                                color: AppColors.green,
                                size: R.icon(context, 12),
                              ),
                              SizedBox(width: R.sp(context, 4)),
                              Text(
                                "${MetricHelper.calculatePercentage(totalProducts, pastProducts).abs().toStringAsFixed(1)}%",
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

                    // Big value
                    Text(
                      _formatIndianCurrency(todaySalesAmount),
                      style: AppTextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: R.fs(context, 36),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: R.sp(context, AppSpacing.sm)),

                    // Sub stats row
                    Row(
                      children: [
                        Text(
                          "$totalProducts units · $totalSales SKUs",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white54,
                            fontSize: R.fs(context, 12),
                          ),
                        ),
                        const Spacer(),
                        // Mini bar chart visual
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
              // 🔹 NEEDS ATTENTION  (colored mini-cards)
              // =====================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Needs attention", style: AppTextStyles.sectionTitle),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "View all",
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
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
                      subLabel: "Products in inventory",
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
                  SizedBox(width: R.sp(context, AppSpacing.sm)),
                  Expanded(
                    child: _attentionCard(
                      context,
                      icon: Icons.warning,
                      iconColor: AppColors.red,
                      bgColor: AppColors.red.withOpacity(0.08),
                      count: "$lowStock",
                      countColor: AppColors.red,
                      label: "Low Stock Items",
                      subLabel: "Need restocking",
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
                  SizedBox(width: R.sp(context, AppSpacing.sm)),
                  Expanded(
                    child: _attentionCard(
                      context,
                      icon: Icons.people,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.primary.withOpacity(0.08),
                      count: "$totalSuppliers",
                      countColor: AppColors.primary,
                      label: "Suppliers",
                      subLabel: "Active suppliers",
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

              // =====================================================
              // 🔹 DAILY SUMMARY CARDS
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      context,
                      "Today's sales",
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

              // =====================================================
              // 🔹 QUICK ACTIONS  (icon circles like reference image)
              // =====================================================
              Text("Quick Actions", style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.lg)),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quickActionCircle(
                    context: context,
                    icon: Icons.currency_rupee,
                    label: "New Sale",
                    filled: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CurrentBillScreen()),
                    ),
                  ),
                  _quickActionCircle(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: "Stock In",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductScreen()),
                    ),
                  ),
                  _quickActionCircle(
                    context: context,
                    icon: Icons.outbox_outlined,
                    label: "Stock Out",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductScreen()),
                    ),
                  ),
                  _quickActionCircle(
                    context: context,
                    icon: Icons.add,
                    label: "Add Product",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddProductScreen(),
                      ),
                    ),
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
// 🔹 ATTENTION CARD  (colored pastel bg)
// =====================================================
Widget _attentionCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color bgColor,
  required String count,
  required Color countColor,
  required String label,
  required String subLabel,
  required double percentage,
  required bool isPositive,
}) {
  return Container(
    padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: iconColor.withOpacity(0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: AppSizes.iconMd),
        SizedBox(height: R.sp(context, AppSpacing.xs)),
        Text(
          count,
          style: AppTextStyles.cardValue.copyWith(
            color: countColor,
            fontSize: R.fs(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: R.fs(context, 11),
          ),
        ),
        Text(
          subLabel,
          style: AppTextStyles.small.copyWith(
            color: AppColors.textSecondary,
            fontSize: R.fs(context, 10),
          ),
        ),
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: R.icon(context, 10),
              color: isPositive ? AppColors.green : AppColors.red,
            ),
            SizedBox(width: R.sp(context, 4)),
            Flexible(
              child: Text(
                "${percentage.toStringAsFixed(1)}%",
                style: AppTextStyles.small.copyWith(
                  color: isPositive ? AppColors.green : AppColors.red,
                  fontSize: R.fs(context, 9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =====================================================
// 🔹 QUICK ACTION  (icon circle like reference image)
// =====================================================
Widget _quickActionCircle({
  required BuildContext context,
  required IconData icon,
  required String label,
  bool filled = false,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(filled ? 0.25 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : AppColors.primary,
            size: AppSizes.iconMd,
          ),
        ),
        SizedBox(height: R.sp(context, AppSpacing.xs)),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontSize: R.fs(context, 11),
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// =====================================================
// 🔹 SUMMARY CARD  (unchanged logic, added icon)
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
// 🔹 METRIC HELPER  (unchanged)
// =====================================================
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
