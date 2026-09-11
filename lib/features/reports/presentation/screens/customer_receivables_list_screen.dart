import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/reports_provider.dart';
import '../widgets/receivable_customer_card.dart';
import 'customer_receivable_details_screen.dart';

class CustomerReceivablesListScreen extends ConsumerStatefulWidget {
  const CustomerReceivablesListScreen({super.key});

  @override
  ConsumerState<CustomerReceivablesListScreen> createState() =>
      _CustomerReceivablesListScreenState();
}

class _CustomerReceivablesListScreenState
    extends ConsumerState<CustomerReceivablesListScreen> {
  String _activeChip = 'all';

  Future<void> _pickDateRange(BuildContext context) async {
    final notifier = ref.read(reportsProvider.notifier);
    final currentRange = ref.read(reportsProvider).selectedDateRange;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: currentRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _activeChip = 'custom');
      notifier.updateDateRange(picked);
    }
  }

  void _applyQuickFilter(String filter) {
    setState(() => _activeChip = filter);
    final notifier = ref.read(reportsProvider.notifier);
    final now = DateTime.now();

    if (filter == 'today') {
      notifier.updateDateRange(
        DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now),
      );
    } else if (filter == 'week') {
      notifier.updateDateRange(
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      );
    } else if (filter == 'month') {
      notifier.updateDateRange(
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      );
    } else if (filter == 'all') {
      notifier.updateDateRange(DateTimeRange(start: DateTime(2020), end: now));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final startStr = state.selectedDateRange.start.toString().split(' ')[0];
    final endStr = state.selectedDateRange.end.toString().split(' ')[0];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 56)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text(
            'Receivable from Customers',
            style: AppTextStyles.heading,
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: R.icon(context, AppSizes.iconLg),
              ),
              onPressed: () => _pickDateRange(context),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── CALENDAR FILTER CHIPS ──
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: R.sp(context, AppSpacing.sm),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.screenPadding),
              ),
              child: Row(
                children: [
                  _ReceivableFilterChip(
                    label: 'All',
                    selected: _activeChip == 'all',
                    onTap: () => _applyQuickFilter('all'),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  _ReceivableFilterChip(
                    label: 'Today',
                    selected: _activeChip == 'today',
                    onTap: () => _applyQuickFilter('today'),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  _ReceivableFilterChip(
                    label: 'Last 7 Days',
                    selected: _activeChip == 'week',
                    onTap: () => _applyQuickFilter('week'),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  _ReceivableFilterChip(
                    label: 'This Month',
                    selected: _activeChip == 'month',
                    onTap: () => _applyQuickFilter('month'),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  _ReceivableFilterChip(
                    label: 'Custom ($startStr - $endStr)',
                    selected: _activeChip == 'custom',
                    onTap: () => _pickDateRange(context),
                  ),
                ],
              ),
            ),
          ),

          // ── LIST BODY ──
          Expanded(
            child: state.receivables.isEmpty
                ? Center(
                    child: Text(
                      'No pending customer collections for this period',
                      style: AppTextStyles.subHeading,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(reportsProvider.notifier)
                          .fetchReportData();
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        R.sp(context, AppSpacing.screenPadding),
                        0,
                        R.sp(context, AppSpacing.screenPadding),
                        R.sp(context, 90),
                      ),
                      itemCount: state.receivables.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                      itemBuilder: (context, index) {
                        final customer = state.receivables[index];
                        return ReceivableCustomerCard(
                          customer: customer,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerReceivableDetailsScreen(
                                customerId: customer.id,
                                customerName: customer.customerName,
                                phone: customer.phone,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReceivableFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReceivableFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md + 2),
          vertical: R.sp(context, 6),
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(R.radius(context, 50)),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: selected ? AppColors.textWhite : Colors.black,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: R.fs(context, 12),
          ),
        ),
      ),
    );
  }
}
