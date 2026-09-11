import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/report_extras.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import 'service_job_details_screen.dart';

class ServicesReportsScreen extends ConsumerStatefulWidget {
  const ServicesReportsScreen({super.key});

  @override
  ConsumerState<ServicesReportsScreen> createState() =>
      _ServicesReportsScreenState();
}

class _ServicesReportsScreenState extends ConsumerState<ServicesReportsScreen> {
  // Keep the existing service-category filter logic.
  String _category = 'all';

  // Date filter.
  String _period = 'this_month';

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String get _periodLabel {
    switch (_period) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      default:
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatShortDate(_customStartDate!)} - '
              '${_formatShortDate(_customEndDate!)}';
        }
        return 'This Month';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _buildProviderKey() {
    if (_period == 'custom' &&
        _customStartDate != null &&
        _customEndDate != null) {
      return '$_category|custom:'
          '${_formatDate(_customStartDate!)}:'
          '${_formatDate(_customEndDate!)}';
    }

    return '$_category|$_period';
  }

  Future<void> _selectDateFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: R.sp(context, 10)),
                Container(
                  width: R.sp(context, 36),
                  height: R.sp(context, 4),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                SizedBox(height: R.sp(context, 8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, AppSpacing.md),
                    vertical: R.sp(context, 8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Date Range',
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: R.fs(context, 15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _dateOption(
                  sheetContext,
                  value: 'today',
                  label: 'Today',
                  icon: Icons.today_rounded,
                ),
                _dateOption(
                  sheetContext,
                  value: 'this_week',
                  label: 'This Week',
                  icon: Icons.date_range_rounded,
                ),
                _dateOption(
                  sheetContext,
                  value: 'this_month',
                  label: 'This Month',
                  icon: Icons.calendar_month_rounded,
                ),
                _dateOption(
                  sheetContext,
                  value: 'this_year',
                  label: 'This Year',
                  icon: Icons.calendar_today_rounded,
                ),
                _dateOption(
                  sheetContext,
                  value: 'custom',
                  label: 'Custom Date Range',
                  icon: Icons.edit_calendar_rounded,
                ),
                SizedBox(height: R.sp(context, 8)),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == 'custom') {
      await _selectCustomDateRange();
      return;
    }

    setState(() {
      _period = selected;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  Widget _dateOption(
    BuildContext sheetContext, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _period == value;

    return InkWell(
      onTap: () => Navigator.pop(sheetContext, value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md),
          vertical: R.sp(context, 12),
        ),
        child: Row(
          children: [
            Container(
              width: R.sp(context, 36),
              height: R.sp(context, 36),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: R.icon(context, 18),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: R.fs(context, 13),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: R.icon(context, 19),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();

    final initialStart = _customStartDate ?? DateTime(now.year, now.month, 1);

    final initialEnd = _customEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
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

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _period = 'custom';
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
  }

  String _customerDisplayName(String customerName, String invoiceNumber) {
    final name = customerName.trim();

    // Backend may return this when no customer name was entered.
    if (name.isEmpty ||
        name.toLowerCase() == 'walk-in customer' ||
        name.toLowerCase() == 'walkin customer' ||
        name.toLowerCase() == 'walk in customer' ||
        name.toLowerCase() == 'unknown customer' ||
        name.toLowerCase() == 'customer') {
      return invoiceNumber.isNotEmpty ? invoiceNumber : 'Service Job';
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = _buildProviderKey();

    final jobsAsync = ref.watch(serviceJobsProvider(providerKey));

    return ReportScaffold(
      title: 'Services Reports',

      // IMPORTANT:
      // No rangeLabel here.
      // This removes the "This Month" button from the APP BAR.
      //
      // The Date Range card below remains and continues to control
      // Today / This Week / This Month / This Year / Custom Date Range.
      onRefresh: () async {
        ref.invalidate(serviceJobsProvider(providerKey));
      },

      child: ReportAsyncView<List<ServiceJobSummary>>(
        value: jobsAsync,
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'No service jobs found for this date range.',
        builder: (context, jobs) {
          final safeJobs = jobs;

          final types = <String>{
            'all',
            ...safeJobs
                .map((j) => j.serviceType.trim())
                .where((type) => type.isNotEmpty),
          }.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // DATE RANGE FILTER
              // ----------------------------------------------------------
              InkWell(
                onTap: _selectDateFilter,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 12),
                    vertical: R.sp(context, 11),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: R.sp(context, 34),
                        height: R.sp(context, 34),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: R.icon(context, 18),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Range',
                              style: AppTextStyles.small.copyWith(
                                fontSize: R.fs(context, 10.5),
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: R.sp(context, 1)),
                            Text(
                              _periodLabel,
                              style: AppTextStyles.cardValue.copyWith(
                                fontSize: R.fs(context, 13),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: R.icon(context, 21),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ----------------------------------------------------------
              // EXISTING SERVICE CATEGORY FILTER
              // ----------------------------------------------------------
              if (types.length > 1)
                ReportSegmentedChips(
                  options: types
                      .map(
                        (t) => ReportChipOption(
                          t,
                          t == 'all' ? 'All (${safeJobs.length})' : t,
                        ),
                      )
                      .toList(),
                  selected: _category,
                  onChanged: (v) {
                    setState(() {
                      _category = v;
                    });
                  },
                ),

              if (types.length > 1)
                SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ----------------------------------------------------------
              // SERVICE JOB CARDS
              // ----------------------------------------------------------
              ...safeJobs
                  .where(
                    (j) => _category == 'all' || j.serviceType == _category,
                  )
                  .map((j) {
                    final displayName = _customerDisplayName(
                      j.customerName,
                      j.invoiceNumber,
                    );

                    final invoice = j.invoiceNumber.trim();

                    return ReportListCard(
                      leadingIcon: Icons.miscellaneous_services_rounded,
                      leadingColor: AppColors.cyanDim,

                      // Do NOT show database ID/jobId here.
                      // Show customer name if entered.
                      // Otherwise show invoice number.
                      title: displayName,

                      subtitle:
                          '${j.serviceType} • ${formatReportDate(j.date)}'
                          '${invoice.isNotEmpty && displayName != invoice ? '\n$invoice' : ''}'
                          '${j.fieldLabel.isEmpty ? '' : '\n${j.fieldLabel}: ${j.fieldValue}'}',

                      trailingTop: formatRupee(j.amount),
                      trailingBottom: '__badge__${j.status}',

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ServiceJobDetailsScreen(jobId: j.jobId),
                          ),
                        );
                      },
                    );
                  }),
            ],
          );
        },
      ),
    );
  }
}
