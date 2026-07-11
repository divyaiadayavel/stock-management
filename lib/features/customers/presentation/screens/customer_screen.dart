import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../customers/presentation/provider/customer_provider.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final data = await DBHelper.getCustomersWithSummary();
    final customerCount = await DBHelper.getCustomerCount();
    final receivable = await DBHelper.getTotalCustomerReceivable();

    ref.read(customersProvider.notifier).state = data;
    ref.read(totalCustomersProvider.notifier).state = customerCount;
    ref.read(totalReceivableProvider.notifier).state = receivable;
  }

  Future<void> _makeCall(String contactNumber) async {
    final cleaned = contactNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch dialer for $contactNumber"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return "${(amount / 100000).toStringAsFixed(1)}L";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}k";
    return amount.toStringAsFixed(0);
  }

  String _formatLastBill(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${d.day} ${months[d.month - 1]}";
    } catch (e) {
      return '';
    }
  }

  Widget _statCard(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 11),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: R.sp(context, 4)),
            Text(
              value,
              style: TextStyle(
                fontSize: R.fs(context, 20),
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final name = customer["name"] ?? "";
    final phone = (customer["phone"] as String?) ?? "";
    final int billsCount = (customer["billsCount"] as num?)?.toInt() ?? 0;
    final String? lastBill = customer["lastBillDate"] as String?;
    final double dueAmount = (customer["dueAmount"] as num?)?.toDouble() ?? 0.0;
    final bool hasDue = dueAmount > 0;

    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : "?";

    final lastBillFormatted = _formatLastBill(lastBill);
    final subtitle = billsCount > 0
        ? "$billsCount bill${billsCount == 1 ? '' : 's'}"
              "${lastBillFormatted.isNotEmpty ? ' · last $lastBillFormatted' : ''}"
        : "No bills yet";

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(customer: customer),
          ),
        );
        if (result == true) loadCustomers();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(context, 10)),
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: R.fluid(context, 44, 56),
              height: R.fluid(context, 44, 56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: R.sp(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasDue ? "due ₹${_formatAmount(dueAmount)}" : "settled",
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.w600,
                    color: hasDue ? AppColors.orange : AppColors.green,
                  ),
                ),
                SizedBox(height: R.sp(context, 6)),
                GestureDetector(
                  onTap: () => _makeCall(phone),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10),
                      vertical: R.sp(context, 5),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          size: R.icon(context, 12),
                          color: AppColors.textPrimaryDark,
                        ),
                        SizedBox(width: R.sp(context, 4)),
                        Text(
                          "Call",
                          style: TextStyle(
                            fontSize: R.fs(context, 11),
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(filteredCustomersProvider);
    final totalCustomers = ref.watch(totalCustomersProvider);
    final totalReceivable = ref.watch(totalReceivableProvider);
    final hPad = R.hPad(context, base: 16);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: hPad.copyWith(
          top: R.sp(context, 30),
          bottom: R.sp(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Customers",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                      fontSize: R.fs(context, 18),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _CustomerSearchDelegate(customers),
                    );
                  },
                  icon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: R.icon(context, 22),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddCustomerScreen()),
                    );
                    if (result == true) loadCustomers();
                  },
                  icon: Container(
                    width: R.fluid(context, 28, 32),
                    height: R.fluid(context, 28, 32),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: R.icon(context, 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 20)),
            Row(
              children: [
                _statCard("Customers", "$totalCustomers"),
                SizedBox(width: R.sp(context, 12)),
                _statCard(
                  "Receivable",
                  "₹${_formatAmount(totalReceivable)}",
                  valueColor: AppColors.primary,
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 20)),
            customers.isEmpty
                ? SizedBox(
                    height: R.fluid(context, 200, 300),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: R.icon(context, 48),
                            color: AppColors.textSecondary.withOpacity(0.4),
                          ),
                          SizedBox(height: R.sp(context, 12)),
                          Text(
                            "No customers added yet",
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customers.length,
                    itemBuilder: (context, index) =>
                        _customerCard(customers[index]),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Simple search delegate ────────────────────────────────────────
class _CustomerSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> customers;
  _CustomerSearchDelegate(this.customers);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = customers
        .where(
          (c) =>
              (c["name"] ?? "").toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (c["phone"] ?? "").toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();

    if (results.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Text(
            "No customers found",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final c = results[index];
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  (c["name"] ?? "?")[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(
                c["name"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              subtitle: Text(
                c["phone"] ?? "",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                close(context, null);
                await Future.delayed(const Duration(milliseconds: 150));
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailsScreen(customer: c),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
