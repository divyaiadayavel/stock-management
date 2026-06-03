import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Global Core Constants (4 levels up)
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../sales/presentation/screens/billing_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<String> filters = ["Day", "Week", "Month", "Year"];

  List<double> salesData = List.filled(7, 0);

  // ✅ ADD THIS
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

    // =========================
    // 🔹 DAY DATA
    // =========================
    if (selectedFilter == "Day") {
      chartData = await DBHelper.getLast7DaysSales();
      labels = getLast7Days();
    }
    // =========================
    // 🔹 WEEK DATA
    // =========================
    else if (selectedFilter == "Week") {
      chartData = await DBHelper.getLast7WeeksSales();
      labels = getLast7Weeks();
    }
    // =========================
    // 🔹 MONTH DATA
    // =========================
    else if (selectedFilter == "Month") {
      chartData = await DBHelper.getLast7MonthsSales();
      labels = getLast7Months();
    }
    // =========================
    // 🔹 YEAR DATA
    // =========================
    else if (selectedFilter == "Year") {
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

  // =====================================================
  // 🔹 LAST 7 DAYS
  // =====================================================
  List<String> getLast7Days() {
    final now = DateTime.now();

    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return "${date.day}";
    });
  }

  // =====================================================
  // 🔹 LAST 7 WEEKS
  // =====================================================
  List<String> getLast7Weeks() {
    return List.generate(7, (index) {
      return "W${index + 1}";
    });
  }

  // =====================================================
  // 🔹 LAST 7 MONTHS
  // =====================================================
  List<String> getLast7Months() {
    final now = DateTime.now();

    return List.generate(7, (index) {
      final date = DateTime(now.year, now.month - (6 - index));

      return _getMonthShort(date.month);
    });
  }

  // =====================================================
  // 🔹 LAST 7 YEARS
  // =====================================================
  List<String> getLast7Years() {
    final now = DateTime.now();

    return List.generate(7, (index) {
      return "${now.year - (6 - index)}";
    });
  }

  // =====================================================
  // 🔹 MONTH SHORT NAME
  // =====================================================
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
    return Scaffold(
      backgroundColor: AppColors.background,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),

        actions: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            // =====================================================
            // 🔹 HEADER
            // =====================================================
            const Text("Welcome, Admin 👋", style: AppTextStyles.heading),

            const SizedBox(height: 4),

            const Text(
              "Here’s what’s happening today.",
              style: AppTextStyles.subHeading,
            ),

            const SizedBox(height: 20),

            // =====================================================
            // 🔹 TOP 4 CARDS
            // =====================================================
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,

              children: [
                _topCard(
                  "Total Products",
                  "$totalProducts",
                  Icons.inventory,
                  Colors.blue,
                ),

                _topCard(
                  "Low Stock Items",
                  "$lowStock",
                  Icons.warning,
                  Colors.red,
                ),

                _topCard(
                  "Total Sales",
                  "₹ $totalSales",
                  Icons.shopping_cart,
                  Colors.green,
                ),

                _topCard(
                  "Suppliers",
                  "$totalSuppliers",
                  Icons.people,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =====================================================
            // 🔹 QUICK ACTIONS
            // =====================================================
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.shopping_cart_outlined,
                    title: "New Bill",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BillingScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _quickActionCard(
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

                const SizedBox(width: 12),

                Expanded(
                  child: _quickActionCard(
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

            const SizedBox(height: 24),

            // =====================================================
            // 🔹 SALES OVERVIEW GRAPH
            // =====================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sales Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    const Text("Show Graph", style: TextStyle(fontSize: 12)),

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

            const SizedBox(height: 12),
            // ✅ GRAPH VISIBLE ONLY WHEN SWITCH IS ON
            if (showGraph)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
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

                          items: filters
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),

                          onChanged: (val) async {
                            ref.read(dashboardFilterProvider.notifier).state =
                                val!;

                            await loadDashboardData();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 220,

                      child: Builder(
                        builder: (context) {
                          double highestSale = salesData.isEmpty
                              ? 0
                              : salesData.reduce((a, b) => a > b ? a : b);

                          // Always show minimum 5 Lakhs scale
                          double maxValue = highestSale < 500000
                              ? 500000
                              : highestSale + 100000;

                          double interval = 100000;

                          return LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxValue,

                              // ✅ GRID
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                              ),

                              // ✅ BORDER
                              borderData: FlBorderData(
                                show: true,

                                border: const Border(
                                  left: BorderSide(color: Colors.black12),
                                  bottom: BorderSide(color: Colors.black12),
                                  top: BorderSide(color: Colors.transparent),
                                  right: BorderSide(color: Colors.transparent),
                                ),
                              ),

                              // ✅ TITLES
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),

                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),

                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: interval,
                                    getTitlesWidget: (value, _) {
                                      if (value == 0) {
                                        return const Text("0");
                                      }

                                      if (value == 100000) {
                                        return const Text("1L");
                                      }

                                      if (value == 200000) {
                                        return const Text("2L");
                                      }

                                      if (value == 300000) {
                                        return const Text("3L");
                                      }

                                      if (value == 400000) {
                                        return const Text("4L");
                                      }

                                      if (value == 500000) {
                                        return const Text("5L");
                                      }

                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                // ✅ BOTTOM TITLES
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,

                                    getTitlesWidget: (value, _) {
                                      int i = value.toInt();

                                      if (i < 0 || i >= chartLabels.length) {
                                        return const SizedBox();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          chartLabels[i],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // ✅ LINE DATA
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    salesData.length,
                                    (i) => FlSpot(i.toDouble(), salesData[i]),
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
                                            radius: 4,
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
    );
  }
}

// =====================================================
// 🔹 TOP CARD
// =====================================================
Widget _topCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),

    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
    ),

    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(title, style: const TextStyle(fontSize: 11)),

            const SizedBox(height: 4),

            Text(
              value,

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    ),
  );
}

// =====================================================
// 🔹 QUICK ACTION CARD
// =====================================================
Widget _quickActionCard({
  required IconData icon,
  required String title,
  required Color color,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,

    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 26),

          const SizedBox(height: 10),

          Text(
            title,

            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    ),
  );
}
