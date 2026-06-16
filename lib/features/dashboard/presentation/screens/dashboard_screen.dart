import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Global Core Constants (4 levels up)
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../sales/presentation/screens/add_product_bill_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/utils/responsive_helper.dart'; // ← add this import

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<String> filters = ["Day", "Week", "Month", "Year"];

  List<double> salesData = List.filled(7, 0);
  List<String> chartLabels = [];
  int totalProducts = 0;
  int totalSales = 0;
  int totalSuppliers = 0;
  int lowStock = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // =====================================================
  // 🔹 LOAD DASHBOARD DATA
  // =====================================================
  Future<void> loadDashboardData() async {
    final selectedFilter = ref.read(dashboardFilterProvider);
    final products = await DBHelper.getProductCount();
    final sales = await DBHelper.getSalesCount();
    final suppliers = await DBHelper.getSupplierCount();
    final lowStocks = await DBHelper.getLowStockCount();
    final graphVisible = await DBHelper.getGraphVisibility();

    List<double> chartData = [];
    List<String> labels = [];

    if (selectedFilter == "Day") {
      chartData = await DBHelper.getLast7DaysSales();
      labels = getLast7Days();
    } else if (selectedFilter == "Week") {
      chartData = await DBHelper.getLast7WeeksSales();
      labels = getLast7Weeks();
    } else if (selectedFilter == "Month") {
      chartData = await DBHelper.getLast7MonthsSales();
      labels = getLast7Months();
    } else if (selectedFilter == "Year") {
      chartData = await DBHelper.getLast7YearsSales();
      labels = getLast7Years();
    }

    totalProducts = products;
    totalSales = sales;
    totalSuppliers = suppliers;
    lowStock = lowStocks;
    salesData = chartData;
    chartLabels = labels;

    ref.read(graphVisibilityProvider.notifier).state = graphVisible;
    setState(() {});
  }

  List<String> getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return "${_getMonthShort(date.month)} ${date.day}";
    });
  }

  List<String> getLast7Weeks() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      // Go back (6 - index) weeks from today to get each week's Monday
      final weekStart = now.subtract(Duration(days: (6 - index) * 7));
      // Week number within the month: ceil(day / 7)
      final weekOfMonth = ((weekStart.day - 1) ~/ 7) + 1;
      return "${_getMonthShort(weekStart.month)} W$weekOfMonth";
    });
  }

  List<String> getLast7Months() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = DateTime(now.year, now.month - (6 - index));
      return _getMonthShort(date.month);
    });
  }

  List<String> getLast7Years() {
    final now = DateTime.now();
    return List.generate(7, (index) => "${now.year - (6 - index)}");
  }

  String _getMonthShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(dashboardFilterProvider);
    final showGraph = ref.watch(graphVisibilityProvider);

    // ── responsive values ──────────────────────────────────────
    final hPad = R.hPad(context, base: AppSpacing.md);
    final gridCols = R.gridCols(context, phone: 2, tablet: 4, desktop: 4);
    final gridRatio = R.gridRatio(
      context,
      phone: 1.8,
      tablet: 2.0,
      desktop: 2.2,
    );
    final sectionFs = R.fs(context, 18);
    final chartH = R.fluid(context, 220, 320);

    return Scaffold(
      backgroundColor: AppColors.background,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: R.fs(context, 18),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(R.sp(context, 12)),
            child: Icon(
              Icons.notifications,
              color: Colors.white,
              size: R.icon(context, 24),
            ),
          ),
        ],
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              padding: hPad.copyWith(
                top: R.sp(context, AppSpacing.md),
                bottom: R.sp(context, AppSpacing.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: R.sp(context, 20)),

                  // =====================================================
                  // 🔹 HEADER
                  // =====================================================
                  Text(
                    "Welcome, Admin 👋",
                    style: AppTextStyles.heading.copyWith(
                      fontSize: R.fs(
                        context,
                        AppTextStyles.heading.fontSize ?? 22,
                      ),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 4)),

                  Text(
                    "Here's what's happening today.",
                    style: AppTextStyles.subHeading.copyWith(
                      fontSize: R.fs(
                        context,
                        AppTextStyles.subHeading.fontSize ?? 14,
                      ),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 20)),

                  // =====================================================
                  // 🔹 TOP 4 CARDS
                  // =====================================================
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: gridCols,
                    crossAxisSpacing: R.sp(context, 12),
                    mainAxisSpacing: R.sp(context, 12),
                    childAspectRatio: gridRatio,
                    children: [
                      _topCard(
                        context,
                        "Total Products",
                        "$totalProducts",
                        Icons.inventory,
                        Colors.blue,
                      ),
                      _topCard(
                        context,
                        "Low Stock Items",
                        "$lowStock",
                        Icons.warning,
                        Colors.red,
                      ),
                      _topCard(
                        context,
                        "Total Sales",
                        "₹ $totalSales",
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                      _topCard(
                        context,
                        "Suppliers",
                        "$totalSuppliers",
                        Icons.people,
                        Colors.purple,
                      ),
                    ],
                  ),

                  SizedBox(height: R.sp(context, 24)),

                  // =====================================================
                  // 🔹 QUICK ACTIONS
                  // =====================================================
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: sectionFs,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  Row(
                    children: [
                      Expanded(
                        child: _quickActionCard(
                          context: context,
                          icon: Icons.shopping_cart_outlined,
                          title: "Add Bill",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CurrentBillScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(width: R.sp(context, 12)),

                      Expanded(
                        child: _quickActionCard(
                          context: context,
                          icon: Icons.add,
                          title: "Add Product",
                          color: Colors.black54,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddProductScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(width: R.sp(context, 12)),

                      Expanded(
                        child: _quickActionCard(
                          context: context,
                          icon: Icons.inventory_2_outlined,
                          title: "Stock In",
                          color: Colors.black54,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: R.sp(context, 24)),

                  // =====================================================
                  // 🔹 SALES OVERVIEW GRAPH
                  // =====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sales Overview",
                        style: TextStyle(
                          fontSize: sectionFs,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          Text(
                            "Show Graph",
                            style: TextStyle(fontSize: R.fs(context, 12)),
                          ),
                          Switch(
                            value: showGraph,
                            onChanged: (value) async {
                              ref.read(graphVisibilityProvider.notifier).state =
                                  value;
                              await DBHelper.saveGraphVisibility(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: R.sp(context, 12)),

                  // ✅ GRAPH VISIBLE ONLY WHEN SWITCH IS ON
                  if (showGraph)
                    Container(
                      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.cardRadius),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DropdownButton<String>(
                                value: selectedFilter,
                                underline: const SizedBox(),
                                style: TextStyle(
                                  fontSize: R.fs(context, 14),
                                  color: Colors.black,
                                ),
                                items: filters
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) async {
                                  ref
                                          .read(
                                            dashboardFilterProvider.notifier,
                                          )
                                          .state =
                                      val!;
                                  await loadDashboardData();
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: R.sp(context, 20)),

                          SizedBox(
                            height: chartH,
                            child: Builder(
                              builder: (context) {
                                double highestSale = salesData.isEmpty
                                    ? 0
                                    : salesData.reduce((a, b) => a > b ? a : b);
                                double maxValue = highestSale < 500000
                                    ? 500000
                                    : highestSale + 100000;
                                double interval = 100000;

                                return LineChart(
                                  LineChartData(
                                    minY: 0,
                                    maxY: maxValue,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        left: BorderSide(color: Colors.black12),
                                        bottom: BorderSide(
                                          color: Colors.black12,
                                        ),
                                        top: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                        right: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: R.fluid(
                                            context,
                                            40,
                                            56,
                                          ),
                                          interval: interval,
                                          getTitlesWidget: (value, _) {
                                            final labelFs = R.fs(context, 10);
                                            if (value == 0) {
                                              return Text(
                                                "0",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            if (value == 100000) {
                                              return Text(
                                                "1L",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            if (value == 200000) {
                                              return Text(
                                                "2L",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            if (value == 300000) {
                                              return Text(
                                                "3L",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            if (value == 400000) {
                                              return Text(
                                                "4L",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            if (value == 500000) {
                                              return Text(
                                                "5L",
                                                style: TextStyle(
                                                  fontSize: labelFs,
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, _) {
                                            int i = value.toInt();
                                            if (i < 0 ||
                                                i >= chartLabels.length) {
                                              return const SizedBox();
                                            }
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                top: R.sp(context, 8),
                                              ),
                                              child: Text(
                                                chartLabels[i],
                                                style: TextStyle(
                                                  fontSize: R.fs(context, 10),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          salesData.length,
                                          (i) => FlSpot(
                                            i.toDouble(),
                                            salesData[i],
                                          ),
                                        ),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        barWidth: 4,
                                        color: Colors.blue,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: R.fluid(
                                                    context,
                                                    4,
                                                    6,
                                                  ),
                                                  color: Colors.white,
                                                  strokeWidth: 3,
                                                  strokeColor: Colors.blue,
                                                );
                                              },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.blue.withOpacity(0.12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// 🔹 TOP CARD  (now context-aware)
// =====================================================
Widget _topCard(
  BuildContext context,
  String title,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    padding: EdgeInsets.all(R.sp(context, 12)),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(R.radius(context, 16)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: R.fluid(context, 20, 28),
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: R.icon(context, 22)),
        ),
        SizedBox(width: R.sp(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: R.fs(context, 11)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: R.sp(context, 4)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: R.fs(context, 14),
                  ),
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
// 🔹 QUICK ACTION CARD  (now context-aware)
// =====================================================
Widget _quickActionCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Color color,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 18)),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(R.radius(context, 16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: R.icon(context, 26)),
          SizedBox(height: R.sp(context, 10)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
