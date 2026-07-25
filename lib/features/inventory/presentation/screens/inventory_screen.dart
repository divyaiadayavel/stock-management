// =========================================================
// lib/features/inventory/presentation/screens/inventory_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/inventory_provider.dart';
import 'low_stock_screen.dart';
import 'new_purchase_order_screen.dart';
import 'receive_order_screen.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import 'stock_screen.dart';

// Accent colors used only for the Quick Action icon circles.
class _Accent {
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF14B8A6);
}

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── 1. STOCK SECTION CARDS ───────────────────────────────
    final stockCards = <_InventoryCardData>[
      _InventoryCardData(
        title: 'Stock',
        subtitle: 'On-hand by item',
        icon: Icons.inventory_2_rounded,
        color: _Accent.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'In Stock',
        subtitle: 'Add received stock',
        icon: Icons.arrow_downward_rounded,
        color: _Accent.green,

        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockInScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Out Stock',
        subtitle: 'Remove / issue stock',
        icon: Icons.arrow_upward_rounded,
        color: _Accent.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockOutScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Low Stock',
        subtitle: 'Items below reorder',
        icon: Icons.warning_amber_rounded,
        color: _Accent.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LowStockScreen()),
        ),
      ),
    ];

    // ── 2. PURCHASE SECTION CARDS ─────────────────────────────
    final purchaseCards = <_InventoryCardData>[
      _InventoryCardData(
        title: 'New Purchase Order',
        subtitle: 'Order from supplier',
        icon: Icons.shopping_bag_rounded,
        color: _Accent.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewPurchaseOrderScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Receive Order',
        subtitle: 'Mark PO as received',
        icon: Icons.local_shipping_rounded,
        color: _Accent.teal,
        onTap: () {
          // 🔥 Simply navigate to the receive order screen – selection handled inside
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReceiveOrderScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 48)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text('Inventory', style: AppTextStyles.heading),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, AppSpacing.screenPadding),
            vertical: R.sp(context, AppSpacing.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HERO STAT CARD ──
              const _InventoryHeroCard(),
              SizedBox(height: R.sp(context, AppSpacing.md)),

              // ── STOCK SECTION ──
              Text('Stock', style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.md)),

              // ── STOCK SECTION ──
              // Removed Expanded(flex: 2) and used a hard limit on the Column container instead
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: R.sp(context, 100), // Fixed height for Row 1
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _InventoryCard(data: stockCards[0])),
                        SizedBox(width: R.sp(context, AppSpacing.sm)),
                        Expanded(child: _InventoryCard(data: stockCards[1])),
                      ],
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.md)),
                  SizedBox(
                    height: R.sp(context, 100), // Fixed height for Row 2
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _InventoryCard(data: stockCards[2])),
                        SizedBox(width: R.sp(context, AppSpacing.sm)),
                        Expanded(child: _InventoryCard(data: stockCards[3])),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: R.sp(context, AppSpacing.md)),

              // ── PURCHASE SECTION ──
              Text('Purchase', style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.md)),
              SizedBox(
                height: R.sp(context, 100), // Fixed height for Purchase Row
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _InventoryCard(data: purchaseCards[0])),
                    SizedBox(width: R.sp(context, AppSpacing.sm)),
                    Expanded(child: _InventoryCard(data: purchaseCards[1])),
                  ],
                ),
              ),

              SizedBox(height: R.sp(context, AppSpacing.xl)),

              // ── PROMO BANNER ──
              const _InventoryPromoBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// HELPER CARDS & WIDGETS
// =========================================================

class _InventoryCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _InventoryCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _InventoryCard extends StatelessWidget {
  final _InventoryCardData data;
  const _InventoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 8),
          vertical: R.sp(context, 2),
        ),
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
              width: R.sp(context, 36),
              height: R.sp(context, 36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: R.icon(context, 16),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: AppTextStyles.cardValue.copyWith(
                            fontWeight: FontWeight.normal,
                            fontSize: R.fs(context, AppSizes.iconSm),
                          ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: R.icon(context, 14),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Text(
                    data.subtitle,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: R.fs(context, 11),
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
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

class _InventoryHeroCard extends ConsumerWidget {
  const _InventoryHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(inventorySummaryProvider);

    return summary.when(
      data: (data) {
        final totalItems = data.totalStockUnits;
        final totalValue = data.inventoryValue;

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
              // ── TOTAL ITEMS ICON (LEFT) ──
              Container(
                width: R.sp(context, 36),
                height: R.sp(context, 36),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: R.icon(context, 14),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.md)),
              // ── TOTAL ITEMS TEXT ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Items',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$totalItems',
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: R.fs(context, 20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── MIDDLE SEPARATOR ──
              Container(
                width: 1,
                height: R.sp(context, 28),
                color: AppColors.border,
                margin: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.xs),
                ),
              ),

              // ── TOTAL VALUE ICON (MOVED TO LEFT SIDE OF TEXT) ──
              Container(
                width: R.sp(context, 36),
                height: R.sp(context, 36),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: R.icon(context, 14),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.md)),
              // ── TOTAL VALUE TEXT ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Value',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${_formatAmount(totalValue)}',
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: R.fs(context, 18),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  static String _formatAmount(double value) {
    final intPart = value.round().toString();
    if (intPart.length <= 3) return intPart;
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final buffer = StringBuffer();
    while (rest.length > 2) {
      buffer.write(',${rest.substring(rest.length - 2)}');
      rest = rest.substring(0, rest.length - 2);
    }
    return '$rest${buffer.toString()},$last3'.replaceFirst(RegExp(r'^,'), '');
  }
}

class _InventoryPromoBanner extends StatelessWidget {
  const _InventoryPromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding - 2)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: R.sp(
              context,
              80,
            ), // 👈 Increased further for a larger appearance
            height: R.sp(
              context,
              80,
            ), // 👈 Increased further for a larger appearance
            child: Image.asset(
              'assets/inventory.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inventory_rounded,
                  color: AppColors.primary,
                  size: R.icon(
                    context,
                    36,
                  ), // 👈 Fallback icon size increased to match
                );
              },
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.md)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Keep your stock in control',
                  style: AppTextStyles.cardValue.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: R.fs(context, AppSizes.iconSm),
                  ),
                ),
                SizedBox(height: R.sp(context, 2)),
                Text(
                  'Track inventory, manage orders and never run out of stock.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: R.fs(context, 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}