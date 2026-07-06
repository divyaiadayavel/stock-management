// =========================================================
// lib/features/inventory/presentation/screens/inventory_screen.dart
// =========================================================
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/storage/db_helper.dart';
import 'stock_screen.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import 'low_stock_screen.dart';
import 'new_purchase_order_screen.dart';
import 'receive_order_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_InventoryCardData>[
      _InventoryCardData(
        title: 'Stock',
        subtitle: 'on-hand by item',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'In Stock',
        subtitle: 'add received stock',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockInScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Out Stock',
        subtitle: 'remove / issue stock',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockOutScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Low Stock',
        subtitle: 'items below reorder',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LowStockScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'New Purchase Order',
        subtitle: 'order from supplier',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewPurchaseOrderScreen()),
        ),
      ),
      _InventoryCardData(
        title: 'Receive Order',
        subtitle: 'mark PO as received',
        onTap: () async {
          final openPOs = await DBHelper.getOpenPurchaseOrders();
          if (openPOs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No open purchase orders')),
            );
            return;
          }
          if (openPOs.length == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiveOrderScreen(poId: openPOs.first['id']),
              ),
            );
            return;
          }
          final picked = await showModalBottomSheet<int>(
            context: context,
            builder: (ctx) => ListView(
              shrinkWrap: true,
              children: openPOs
                  .map(
                    (po) => ListTile(
                      title: Text(
                        'PO-${po['id'].toString().padLeft(4, '0')} · ${po['supplierName']}',
                      ),
                      onTap: () => Navigator.pop(ctx, po['id']),
                    ),
                  )
                  .toList(),
            ),
          );
          if (picked != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiveOrderScreen(poId: picked),
              ),
            );
          }
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 56)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text('Inventory', style: AppTextStyles.heading),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          R.sp(context, AppSpacing.screenPadding),
          R.sp(context, AppSpacing.sm),
          R.sp(context, AppSpacing.screenPadding),
          R.sp(context, AppSpacing.xl),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: R.sp(context, AppSpacing.sm),
            mainAxisSpacing: R.sp(context, AppSpacing.sm),
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, i) => _InventoryCard(data: cards[i]),
        ),
      ),
    );
  }
}

class _InventoryCardData {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _InventoryCardData({
    required this.title,
    required this.subtitle,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.title,
              style: AppTextStyles.cardValue.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: R.fs(context, AppSizes.iconSm),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            Text(
              data.subtitle,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
