import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

class DateRangePickerWidget extends StatelessWidget {
  final DateTimeRange selectedRange;
  final ValueChanged<DateTimeRange> onDateRangeSelected;

  const DateRangePickerWidget({
    super.key,
    required this.selectedRange,
    required this.onDateRangeSelected,
  });

  Future<void> _pickRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
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
      onDateRangeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = selectedRange.start.toString().split(' ')[0];
    final endStr = selectedRange.end.toString().split(' ')[0];

    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primary,
            size: R.icon(context, 18),
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
          Expanded(
            child: Text(
              '$startStr to $endStr',
              style: AppTextStyles.cardValue.copyWith(
                fontSize: R.fs(context, 12),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
          Container(
            height: R.sp(context, 32),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(R.radius(context, 8)),
            ),
            child: ElevatedButton(
              onPressed: () => _pickRange(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.sm),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 8)),
                ),
                elevation: 0,
              ),
              child: Text(
                'Filter',
                style: AppTextStyles.button.copyWith(
                  fontSize: R.fs(context, 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
