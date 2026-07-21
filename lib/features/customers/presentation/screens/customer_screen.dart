import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../provider/customer_provider.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

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

  // Exact formatting – no rounding
  String _formatAmountExact(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
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

  void _refreshData() {
    ref.invalidate(rawCustomersProvider);
    ref.invalidate(customerDashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(rawCustomersProvider);
    final summary = ref.watch(customerDashboardSummaryProvider);

    final int totalCount = summary["totalCount"] ?? 0;
    final double totalReceivable = summary["totalReceivable"] ?? 0.0;
    final hPad = R.hPad(context, base: 16);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryDark,
            size: R.icon(context, 22),
          ),
        ),
        title: Text(
          "Customers",
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
              );
              if (result == true) {
                _refreshData();
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: R.sp(context, 16)),
              width: R.fluid(context, 32, 36),
              height: R.fluid(context, 32, 36),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: R.icon(context, 20),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: hPad.copyWith(top: R.sp(context, 12), bottom: R.sp(context, 4)),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val.trim(),
              decoration: InputDecoration(
                hintText: "Search customer name or phone...",
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Stats cards
          Padding(
            padding: hPad.copyWith(top: R.sp(context, 12)),
            child: Row(
              children: [
                _statCard("Customers", "$totalCount"),
                SizedBox(width: R.sp(context, 12)),
                _statCard(
                  "Receivable",
                  "₹${_formatAmountExact(totalReceivable)}",
                  valueColor: AppColors.green,
                ),
              ],
            ),
          ),

          SizedBox(height: R.sp(context, 16)),

          // Customer list
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error fetching customers: $err")),
              data: (customersList) {
                if (customersList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: R.icon(context, 48),
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: R.sp(context, 12)),
                        Text(
                          "No customers found",
                          style: TextStyle(
                            fontSize: R.fs(context, 14),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    _refreshData();
                  },
                  child: ListView.builder(
                    padding: hPad.copyWith(bottom: R.sp(context, 24)),
                    itemCount: customersList.length,
                    itemBuilder: (context, index) {
                      final c = customersList[index];
                      final bool hasDue = c.currentBalance > 0;
                      final name = c.customerName;

                      final parts = name.trim().split(" ");
                      final initials = parts.length >= 2
                          ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
                          : name.isNotEmpty
                              ? name[0].toUpperCase()
                              : "?";

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsScreen(customer: c),
                            ),
                          );
                          if (result == true) {
                            _refreshData();
                          }
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
                                decoration: const BoxDecoration(
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
                                      c.customerCode,
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
                                    hasDue
                                        ? "due ₹${_formatAmountExact(c.currentBalance)}"
                                        : "settled",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 12),
                                      fontWeight: FontWeight.w600,
                                      color: hasDue ? AppColors.orange : AppColors.green,
                                    ),
                                  ),
                                  SizedBox(height: R.sp(context, 6)),
                                  GestureDetector(
                                    onTap: () => _makeCall(c.phone),
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
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}