// lib/features/expenses/presentation/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_management/core/constants/app_colors.dart';
import 'package:stock_management/core/constants/app_sizes.dart';
import 'package:stock_management/core/constants/app_spacing.dart';
import 'package:stock_management/core/constants/app_text_styles.dart';
import 'package:stock_management/features/expenses/data/models/expense_model.dart';
import 'package:stock_management/features/expenses/presentation/providers/expense_provider.dart';
import 'package:stock_management/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:stock_management/features/expenses/presentation/screens/expense_details_screen.dart';
import 'package:stock_management/features/expenses/presentation/widgets/expense_tile.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
      ),
    );
  }

  void _openDetails(ExpenseModel expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailsScreen(
          expense: expense,
        ),
      ),
    );
  }

  // ==========================================================
  // DATE RANGE PICKER
  // ==========================================================

  Future<void> _pickDateRange(
    DateTimeRange? currentRange,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          currentRange ??
          DateTimeRange(
            start: DateTime.now().subtract(
              const Duration(days: 7),
            ),
            end: DateTime.now(),
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

    ref
        .read(expenseProvider.notifier)
        .setDateRange(picked);
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final grouped = state.groupedByDate;

    final filterLabel = state.dateRange != null
        ? '${_formatDate(state.dateRange!.start)}'
            ' - '
            '${_formatDate(state.dateRange!.end)}'
        : 'All Time';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimaryDark,
          ),
          onPressed: () =>
              Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Expenses',
          style: AppTextStyles.appBarTitle.copyWith(
            color: AppColors.textPrimaryDark,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER + FILTERS
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // TOTAL EXPENSE CARD
                  // ==================================================

                  _TotalExpensesCard(
                    total: state.totalForFilter,
                    filterLabel: filterLabel,
                    onAddExpense: _openAddExpense,
                  ),

                  const SizedBox(
                    height: AppSpacing.md,
                  ),

                  // ==================================================
                  // SEARCH
                  // ==================================================

                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                      notifier.setSearchQuery(value);
                    },
                    style: AppTextStyles.cardValue.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, notes...',
                      hintStyle: AppTextStyles.small,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color:
                            AppColors.textSecondary,
                        size: AppSizes.iconLg,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors
                                        .textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController
                                        .clear();

                                    setState(() {});

                                    notifier
                                        .setSearchQuery(
                                      '',
                                    );
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppSizes.radiusMd,
                        ),
                        borderSide:
                            const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppSizes.radiusMd,
                        ),
                        borderSide:
                            const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppSizes.radiusMd,
                        ),
                        borderSide:
                            const BorderSide(
                          color: AppColors.cyanDim,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: AppSpacing.md,
                  ),

                  // ==================================================
                  // PAYMENT FILTER + CALENDAR BUTTON
                  // ==================================================

                  Row(
                    children: [
                      _GradientFilterChip(
                        label: 'All',
                        selected:
                            state.paymentMethodFilter ==
                                null,
                        onTap: () {
                          notifier
                              .setPaymentMethodFilter(
                            null,
                          );
                        },
                      ),

                      const SizedBox(
                        width: AppSpacing.sm,
                      ),

                      _GradientFilterChip(
                        label: 'Cash',
                        selected:
                            state.paymentMethodFilter ==
                                PaymentMethod.cash,
                        onTap: () {
                          notifier
                              .setPaymentMethodFilter(
                            PaymentMethod.cash,
                          );
                        },
                      ),

                      const SizedBox(
                        width: AppSpacing.sm,
                      ),

                      _GradientFilterChip(
                        label: 'UPI',
                        selected:
                            state.paymentMethodFilter ==
                                PaymentMethod.upi,
                        onTap: () {
                          notifier
                              .setPaymentMethodFilter(
                            PaymentMethod.upi,
                          );
                        },
                      ),

                      const Spacer(),

                      // ==================================================
                      // CALENDAR BUTTON
                      // ==================================================

                      _CalendarButton(
                        active:
                            state.dateRange != null,
                        onTap: () {
                          _pickDateRange(
                            state.dateRange,
                          );
                        },
                      ),
                    ],
                  ),

                  // ==================================================
                  // SELECTED DATE RANGE
                  // ==================================================

                  if (state.dateRange != null) ...[
                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    _SelectedDateFilter(
                      start:
                          state.dateRange!.start,
                      end:
                          state.dateRange!.end,
                      onClear: () {
                        notifier.setDateRange(null);
                      },
                    ),
                  ],

                  const SizedBox(
                    height: AppSpacing.sm,
                  ),
                ],
              ),
            ),

            // ==================================================
            // DIVIDER
            // ==================================================

            const Divider(
              height: 1,
              color: AppColors.border,
            ),

            // ==================================================
            // EXPENSE LIST
            // ==================================================

            Expanded(
              child:
                  state.isLoading &&
                          state.expenses.isEmpty
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : state.error != null &&
                              state.expenses.isEmpty
                          ? _ExpenseLoadError(
                              message:
                                  state.error!,
                              onRetry:
                                  notifier
                                      .loadExpenses,
                            )
                          : RefreshIndicator(
                              onRefresh:
                                  notifier.loadExpenses,
                              color:
                                  AppColors.primary,
                              backgroundColor:
                                  Colors.white,
                              displacement: 24,
                              strokeWidth: 2.5,
                              child: grouped.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding:
                                          const EdgeInsets.only(
                                        top: 80,
                                        bottom:
                                            AppSpacing
                                                .xl,
                                      ),
                                      children: const [
                                        _EmptyExpenses(),
                                      ],
                                    )
                                  : ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding:
                                          const EdgeInsets.only(
                                        bottom:
                                            AppSpacing
                                                .xl,
                                      ),
                                      children: [
                                        for (final entry
                                            in grouped
                                                .entries) ...[
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .fromLTRB(
                                              AppSpacing
                                                  .screenPadding,
                                              AppSpacing.md,
                                              AppSpacing
                                                  .screenPadding,
                                              AppSpacing.xs,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      Text(
                                                    entry
                                                        .key,
                                                    style: AppTextStyles
                                                        .small
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${state.totalFor(entry.value).toStringAsFixed(2)}',
                                                  style: AppTextStyles
                                                      .small
                                                      .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          for (final expense
                                              in entry
                                                  .value)
                                            ExpenseTile(
                                              expense:
                                                  expense,
                                              searchQuery:
                                                  _searchController
                                                      .text,
                                              onTap: () =>
                                                  _openDetails(
                                                expense,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// TOTAL EXPENSE CARD
// ============================================================

class _TotalExpensesCard
    extends StatelessWidget {
  final double total;
  final String filterLabel;
  final VoidCallback onAddExpense;

  const _TotalExpensesCard({
    required this.total,
    required this.filterLabel,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        AppSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius:
            BorderRadius.circular(
          AppSizes.radiusLg,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.xs,
                ),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  filterLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          ElevatedButton.icon(
            onPressed: onAddExpense,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.white,
              foregroundColor:
                  AppColors.primary,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  AppSizes.radiusMd,
                ),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// PAYMENT FILTER CHIP
// ============================================================

class _GradientFilterChip
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GradientFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          AppSizes.radiusLg,
        ),
        child: Container(
          height: 40,
          padding:
              const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? AppColors.brandGradient
                : null,
            color: selected
                ? null
                : AppColors.card,
            borderRadius:
                BorderRadius.circular(
              AppSizes.radiusLg,
            ),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily:
                  AppTextStyles.fontBody,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.textWhite
                  : AppColors.textPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// CALENDAR BUTTON
// ============================================================

class _CalendarButton
    extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _CalendarButton({
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            gradient: active
                ? AppColors.brandGradient
                : null,
            color: active
                ? null
                : AppColors.card,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : AppColors.border,
            ),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            size: 20,
            color: active
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}


// ============================================================
// SELECTED DATE FILTER
// ============================================================

class _SelectedDateFilter
    extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback onClear;

  const _SelectedDateFilter({
    required this.start,
    required this.end,
    required this.onClear,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      padding:
          const EdgeInsets.only(
        left: 13,
        right: 3,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              AppColors.primary.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          // ==================================================
          // DATE ICON
          // ==================================================

          Icon(
            Icons.date_range_rounded,
            size: 18,
            color: AppColors.primary,
          ),

          const SizedBox(width: 9),

          // ==================================================
          // DATE RANGE
          // ==================================================

          Expanded(
            child: Text(
              '${_formatDate(start)}'
              '  →  '
              '${_formatDate(end)}',
              style:
                  AppTextStyles.small.copyWith(
                color:
                    AppColors.textPrimaryDark,
                fontWeight:
                    FontWeight.w600,
              ),
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),

          // ==================================================
          // CLEAR BUTTON
          // ==================================================

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClear,
              borderRadius:
                  BorderRadius.circular(20),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// LOAD ERROR
// ============================================================

class _ExpenseLoadError
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ExpenseLoadError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFEF4444),
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              'Couldn\'t load expenses',
              style:
                  AppTextStyles.sectionTitle
                      .copyWith(
                color:
                    AppColors.textPrimaryDark,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: AppSpacing.xs,
            ),

            Text(
              message,
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            ElevatedButton.icon(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyExpenses
    extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color:
                  AppColors.textSecondary,
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              'No expenses yet',
              style:
                  AppTextStyles.sectionTitle
                      .copyWith(
                color:
                    AppColors.textPrimaryDark,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: AppSpacing.xs,
            ),

            Text(
              'Tap Add Expense to record your first expense.',
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}