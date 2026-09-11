// =============================================================================
// lib/features/reports/presentation/widgets/report_shared_widgets.dart
// -----------------------------------------------------------------------------
// Shared, reusable pieces for every screen in the Reports feature so the whole
// section looks and behaves consistently (same header bar, same stat tiles,
// same list-row cards, same loading/error/empty handling), using the app's
// existing AppColors / AppTextStyles / AppSizes / AppSpacing / R helpers.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ── Formatters ───────────────────────────────────────────────────────────────

/// Indian-grouped currency string, e.g. 2223710.20 -> "2,23,710.20".
String formatInr(num value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final isNeg = parts[0].startsWith('-');
  String number = isNeg ? parts[0].substring(1) : parts[0];
  final decimal = parts.length > 1 ? parts[1] : '00';

  String grouped;
  if (number.length <= 3) {
    grouped = number;
  } else {
    final lastThree = number.substring(number.length - 3);
    var remaining = number.substring(0, number.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    grouped = '${groups.join(',')},$lastThree';
  }
  return '${isNeg ? '-' : ''}$grouped.$decimal';
}

String formatRupee(num value) => '₹${formatInr(value)}';

String formatReportDate(DateTime d) {
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
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$mm $ampm';
}

// ── Header Bar ────────────────────────────────────────────────────────────────
/// Matches the existing screens' back-arrow + title app bar, with an optional
/// trailing "All Time (Live)" style range chip (tap to change).
class ReportHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? rangeLabel;
  final VoidCallback? onRangeTap;

  const ReportHeaderBar({
    super.key,
    required this.title,
    this.rangeLabel,
    this.onRangeTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 17)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
actions: [
  if (rangeLabel != null && rangeLabel!.trim().isNotEmpty)
    Padding(
      padding: EdgeInsets.only(
        right: R.sp(context, AppSpacing.screenPadding),
      ),
      child: _RangeChip(
        label: rangeLabel!,
        onTap: onRangeTap,
      ),
    ),
],
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _RangeChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 10),
          vertical: R.sp(context, 6),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textPrimaryDark,
                fontSize: R.fs(context, 11),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: R.sp(context, 2)),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: R.icon(context, 14),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Async wrapper ─────────────────────────────────────────────────────────────
/// Consistent loading / error / empty / data states for every report screen
/// so a not-yet-connected backend degrades gracefully instead of crashing.
class ReportAsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  const ReportAsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'No data yet — connect the backend to see live data.',
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load this report.\nPull to refresh once the backend is connected.',
                textAlign: TextAlign.center,
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.small,
              ),
            ),
          );
        }
        return builder(context, data);
      },
    );
  }
}

// ── Stat tile (2 or 4-up grid of KPI cards) ───────────────────────────────────
class ReportStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const ReportStatTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: R.sp(context, 30),
                height: R.sp(context, 30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: R.icon(context, 15)),
              ),
              SizedBox(width: R.sp(context, 6)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: R.fs(context, 11),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, 8)),
          Text(
            value,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: R.fs(context, 16),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            SizedBox(height: R.sp(context, 2)),
            Text(
              subtitle!,
              style: AppTextStyles.small.copyWith(
                color: color,
                fontSize: R.fs(context, 10),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// A 2-column responsive grid of [ReportStatTile]s (2 or 4 tiles).
class ReportStatGrid extends StatelessWidget {
  final List<ReportStatTile> tiles;
  const ReportStatGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final hasSecond = i + 1 < tiles.length;
      rows.add(
        Row(
          children: [
            Expanded(child: tiles[i]),
            if (hasSecond) SizedBox(width: R.sp(context, AppSpacing.sm)),
            if (hasSecond) Expanded(child: tiles[i + 1]),
          ],
        ),
      );
      if (i + 2 < tiles.length)
        rows.add(SizedBox(height: R.sp(context, AppSpacing.sm)));
    }
    return Column(children: rows);
  }
}

// ── Segmented chips (All / Cash / Split Tender, tabs with counts) ────────────
class ReportChipOption {
  final String value;
  final String label;
  const ReportChipOption(this.value, this.label);
}

class ReportSegmentedChips extends StatelessWidget {
  final List<ReportChipOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const ReportSegmentedChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isActive = opt.value == selected;
          return Padding(
            padding: EdgeInsets.only(right: R.sp(context, AppSpacing.xs)),
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 14),
                  vertical: R.sp(context, 8),
                ),
                decoration: BoxDecoration(
                  color: isActive ? null : AppColors.card,
                  gradient: isActive ? AppColors.brandGradient : null,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: AppTextStyles.small.copyWith(
                    color: isActive ? Colors.white : AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: R.fs(context, 12),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class ReportSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const ReportSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 13)),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: AppTextStyles.small,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: R.icon(context, 18),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: R.sp(context, 12)),
        ),
      ),
    );
  }
}

// ── Status badge (PAID / SUBMITTED / RECEIVED / ORDERED / CRITICAL ...) ──────
class ReportBadge extends StatelessWidget {
  final String label;
  final Color color;
  const ReportBadge({super.key, required this.label, required this.color});

  /// Picks a sensible color automatically from common status strings.
  factory ReportBadge.auto(String label) {
    final upper = label.toUpperCase();
    Color color;
    if ([
      'PAID',
      'RECEIVED',
      'SUBMITTED',
      'ACTIVE',
      'SETTLED',
    ].contains(upper)) {
      color = AppColors.green;
    } else if ([
      'PENDING',
      'ORDERED',
      'AWAITING DELIVERY',
      'PARTIAL_CASH',
      'PARTIAL CASH',
      'DUE',
    ].contains(upper)) {
      color = AppColors.orange;
    } else if (['CRITICAL', 'OUT OF STOCK', 'OVERDUE'].contains(upper)) {
      color = AppColors.red;
    } else if (upper == 'LOW STOCK') {
      color = AppColors.orange;
    } else {
      color = AppColors.cyanDim;
    }
    return ReportBadge(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, 8),
        vertical: R.sp(context, 3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusSm),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: R.fs(context, 9.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Generic tappable list row card ────────────────────────────────────────────
class ReportListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailingTop;
  final Color? trailingTopColor;
  final String? trailingBottom;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Color? leadingColor;

  const ReportListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailingTop,
    this.trailingTopColor,
    this.trailingBottom,
    this.onTap,
    this.leadingIcon,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
        margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(
            R.radius(context, AppSizes.cardRadius),
          ),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: R.sp(context, 34),
                height: R.sp(context, 34),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (leadingColor ?? AppColors.primary).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon,
                  color: leadingColor ?? AppColors.primary,
                  size: R.icon(context, 16),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardValue.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: R.fs(context, 13),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: R.sp(context, 3)),
                  Text(
                    subtitle,
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 11),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingTop != null) ...[
              SizedBox(width: R.sp(context, AppSpacing.xs)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trailingTop!,
                    style: AppTextStyles.cardValue.copyWith(
                      color: trailingTopColor ?? AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: R.fs(context, 13),
                    ),
                  ),
                  if (trailingBottom != null) ...[
                    SizedBox(height: R.sp(context, 4)),
                    trailingBottom!.startsWith('__badge__')
                        ? ReportBadge.auto(
                            trailingBottom!.replaceFirst('__badge__', ''),
                          )
                        : Text(
                            trailingBottom!,
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 10),
                            ),
                          ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────
class ReportSectionTitle extends StatelessWidget {
  final String text;
  const ReportSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.xs)),
      child: Text(
        text,
        style: AppTextStyles.sectionTitle.copyWith(fontSize: R.fs(context, 15)),
      ),
    );
  }
}

// ── Key-value row (used in Invoice/PO/Service/Profitability detail screens) ──
class ReportKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const ReportKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.cardValue.copyWith(
                fontSize: R.fs(context, bold ? 14 : 12.5),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card container that wraps a group of [ReportKeyValueRow]s / any content
/// with the standard card chrome (used by detail screens).
class ReportSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const ReportSectionCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                fontSize: R.fs(context, 10.5),
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
          ],
          child,
        ],
      ),
    );
  }
}

/// Standard scaffold used by every new report screen — header + refreshable
/// scroll body — so all of them share the same skeleton.
class ReportScaffold extends StatelessWidget {
  final String title;
  final String? rangeLabel;
  final VoidCallback? onRangeTap;
  final Future<void> Function()? onRefresh;
  final Widget child;
  final Widget? bottomBar;

  const ReportScaffold({
    super.key,
    required this.title,
    this.rangeLabel,
    this.onRangeTap,
    this.onRefresh,
    required this.child,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ReportHeaderBar(
        title: title,
        rangeLabel: rangeLabel,
        onRangeTap: onRangeTap,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.screenPadding),
              vertical: R.sp(context, AppSpacing.sm),
            ),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
