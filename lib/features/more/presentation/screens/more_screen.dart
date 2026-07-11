import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/storage/db_helper.dart';

import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import '../../../customers/presentation/screens/customer_screen.dart';
import '../../../inventory/presentation/screens/new_purchase_order_screen.dart';
import '../../../inventory/presentation/screens/low_stock_screen.dart';
import '../../../inventory/presentation/screens/stock_in_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

class StoreProfile {
  final String storeName;
  final String ownerName;
  final String planLabel;

  const StoreProfile({
    this.storeName = 'My Store',
    this.ownerName = '',
    this.planLabel = '',
  });

  String get initials {
    final parts = storeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class MoreScreenSummary {
  final StoreProfile store;
  final double supplierPayable;
  final int supplierCount;
  final double customerDue;
  final int customerCount;
  final int poOpenCount;
  final int poDueCount;

  const MoreScreenSummary({
    required this.store,
    required this.supplierPayable,
    required this.supplierCount,
    required this.customerDue,
    required this.customerCount,
    required this.poOpenCount,
    required this.poDueCount,
  });
}

final moreScreenSummaryProvider = FutureProvider.autoDispose<MoreScreenSummary>(
  (ref) async {
    final profileRow = await DBHelper.getStoreProfile();
    final store = profileRow == null
        ? const StoreProfile()
        : StoreProfile(
            storeName: (profileRow['storeName'] ?? 'My Store').toString(),
            ownerName: (profileRow['ownerName'] ?? '').toString(),
            planLabel: (profileRow['planLabel'] ?? '').toString(),
          );

    final supplierPayable = await DBHelper.getSupplierPayableTotal();
    final supplierCount = await DBHelper.getSupplierCount();
    final customerDue = await DBHelper.getCustomerDueTotal();
    final customerCount = await DBHelper.getCustomerCount();
    final poOpenCount = await DBHelper.getOpenPurchaseOrderCount();
    final poDueCount = await DBHelper.getDuePurchaseOrderCount();

    return MoreScreenSummary(
      store: store,
      supplierPayable: supplierPayable,
      supplierCount: supplierCount,
      customerDue: customerDue,
      customerCount: customerCount,
      poOpenCount: poOpenCount,
      poDueCount: poDueCount,
    );
  },
);

String formatShortCurrency(double value) {
  if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
  return '₹${value.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(moreScreenSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'More',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardValue.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: R.fs(context, 22),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: R.sp(context, AppSpacing.md)),
            child: Container(
              width: R.sp(context, 40),
              height: R.sp(context, 40),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.cardRadius),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.search),
                color: AppColors.textSecondary,
                iconSize: R.icon(context, 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(R.sp(context, 20)),
            child: Text(
              'Could not load data',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.refresh(moreScreenSummaryProvider),
          child: ListView(
            padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
            children: [
              _storeHeaderCard(context, summary.store),
              SizedBox(height: R.sp(context, AppSpacing.md)),
              _summaryGrid(context, summary),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              _sectionTitle(context, 'Inventory tools'),
              SizedBox(height: R.sp(context, AppSpacing.xs)),
              _toolsCard(context),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              _sectionTitle(context, 'System'),
              SizedBox(height: R.sp(context, AppSpacing.xs)),
              _systemCard(context),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Store header ──
  Widget _storeHeaderCard(BuildContext context, StoreProfile store) {
    final subtitleParts = [
      store.ownerName,
      store.planLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            // FIXED: Using R.sp instead of R.imgSize to prevent 17000px width!
            width: R.sp(context, 44),
            height: R.sp(context, 44),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              store.initials,
              maxLines: 1,
              style: AppTextStyles.cardValue.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardValue.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: R.fs(context, 16),
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: R.sp(context, 2)),
                    child: Text(
                      subtitleParts,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  // ── 2x2 dynamic summary cards ──
  Widget _summaryGrid(BuildContext context, MoreScreenSummary s) {
    final cards = [
      _SummaryCardData(
        icon: Icons.local_shipping_outlined,
        title: 'Suppliers',
        subtitle:
            '${formatShortCurrency(s.supplierPayable)} payable · ${s.supplierCount}',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const SuppliersScreen()),
        ),
      ),
      _SummaryCardData(
        icon: Icons.person_outline,
        title: 'Customers',
        subtitle:
            '${formatShortCurrency(s.customerDue)} due · ${s.customerCount}',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const CustomersScreen()),
        ),
      ),
      _SummaryCardData(
        icon: Icons.description_outlined,
        title: 'Purchase orders',
        subtitle: '${s.poOpenCount} open · ${s.poDueCount} due',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const NewPurchaseOrderScreen()),
        ),
      ),
      _SummaryCardData(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'valuation · GST · profit',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: R.sp(context, AppSpacing.sm),
      crossAxisSpacing: R.sp(context, AppSpacing.sm),
      childAspectRatio: 1.35,
      children: cards.map((c) => _summaryCard(context, c)).toList(),
    );
  }

  Widget _summaryCard(BuildContext context, _SummaryCardData data) {
    return GestureDetector(
      onTap: () => data.onTap(context),
      child: Container(
        padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(
            R.radius(context, AppSizes.cardRadius),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(R.sp(context, 6)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(R.radius(context, 8)),
              ),
              child: Icon(
                data.icon,
                color: AppColors.primary,
                size: R.icon(context, 18),
              ),
            ),
            const Spacer(),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardValue.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: R.fs(context, 14),
              ),
            ),
            SizedBox(height: R.sp(context, 2)),
            Text(
              data.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
                fontSize: R.fs(context, 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.cardValue.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: R.fs(context, 14),
      ),
    );
  }

  // ── Inventory tools list ──
  Widget _toolsCard(BuildContext context) {
    final items = [
      _ListItemData(
        icon: Icons.add_box_outlined,
        label: 'New purchase order',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const NewPurchaseOrderScreen()),
        ),
      ),
      _ListItemData(
        icon: Icons.warning_amber_outlined,
        label: 'Low stock',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const LowStockScreen()),
        ),
      ),
      _ListItemData(
        icon: Icons.move_to_inbox_outlined,
        label: 'Receive order',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const StockInScreen()),
        ),
      ),
    ];
    return _groupedCard(context, items);
  }

  // ── System list ──
  Widget _systemCard(BuildContext context) {
    final items = [
      _ListItemData(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      _ListItemData(
        icon: Icons.sync,
        label: 'Backup & sync',
        trailing: 'synced',
        trailingColor: Colors.green,
        onTap: (_) {},
      ),
      _ListItemData(
        icon: Icons.help_outline,
        label: 'Help & support',
        onTap: (_) {},
      ),
      _ListItemData(
        icon: Icons.logout,
        label: 'Sign out',
        iconColor: AppColors.red,
        labelColor: AppColors.red,
        onTap: (ctx) => _showSignOutDialog(ctx),
      ),
    ];
    return _groupedCard(context, items);
  }

  Widget _groupedCard(BuildContext context, List<_ListItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () => item.onTap(context),
                leading: Icon(
                  item.icon,
                  color: item.iconColor ?? AppColors.primary,
                  size: R.icon(context, 20),
                ),
                title: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardValue.copyWith(
                    color: item.labelColor,
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: item.trailing != null
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.sp(context, 8),
                          vertical: R.sp(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: (item.trailingColor ?? AppColors.primary)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            R.radius(context, 20),
                          ),
                        ),
                        child: Text(
                          item.trailing!,
                          style: AppTextStyles.small.copyWith(
                            color: item.trailingColor ?? AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: R.icon(context, 18),
                      ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.border, indent: 56),
            ],
          );
        }),
      ),
    );
  }

  // ── Sign-out confirmation ──
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              // Call actual sign-out logic here
            },
            child: Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;
  _SummaryCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ListItemData {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? trailingColor;
  final Color? iconColor;
  final Color? labelColor;
  final void Function(BuildContext) onTap;
  _ListItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.trailingColor,
    this.iconColor,
    this.labelColor,
  });
}
