import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

import '../../../auth/presentation/controllers/access_policy.dart';
import '../../../auth/presentation/providers/access_provider.dart';
import '../../../auth/presentation/widgets/access_guard.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  // Pages: Dashboard · Products · (Sale = FAB) · Inventory · More
  // Index:    0           1                          2           3
  static const List<(AppFeature, Widget)> _pages = [
    (
      AppFeature.dashboard,
      AccessGuard(feature: AppFeature.dashboard, child: DashboardScreen()),
    ),
    (
      AppFeature.products,
      AccessGuard(feature: AppFeature.products, child: ProductScreen()),
    ),
    // index 2 → Inventory
    (
      AppFeature.inventory,
      AccessGuard(feature: AppFeature.inventory, child: InventoryScreen()),
    ),
    // index 3 → More / Settings
    (
      AppFeature.settings,
      AccessGuard(feature: AppFeature.settings, child: SettingsScreen()),
    ),
  ];

  // Nav items (4 tabs — Sale is the center FAB, not a tab)
  static const List<(IconData, String, AppFeature)> _navItems = [
    (Icons.home_outlined, 'Home', AppFeature.dashboard),
    (Icons.inventory_2_outlined, 'Products', AppFeature.products),
   (Icons.widgets_outlined, 'Inventory', AppFeature.inventory),
    (Icons.more_horiz, 'More', AppFeature.settings),
  ];

  bool _canAccess(AppFeature feature) =>
      ref.read(canAccessFeatureProvider(feature));

  void _showAccessDenied(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label access is restricted for your role',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _onNavTap(int index) {
    final feature = _navItems[index].$3;
    if (!_canAccess(feature)) {
      _showAccessDenied(_navItems[index].$2);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openSale() {
    if (!_canAccess(AppFeature.billing)) {
      _showAccessDenied('Sale');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CurrentBillScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(roleAccessProvider);

    return Scaffold(
      body: _pages[_currentIndex].$2,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // Home
                Expanded(child: _navItem(0)),
                // Products
                Expanded(child: _navItem(1)),

                // ── CENTER  Sale  BUTTON ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: GestureDetector(
                    onTap: _openSale,
                    child: Container(
                      width: 56,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _canAccess(AppFeature.billing)
                            ? AppColors.brandGradient
                            : null,
                        color: _canAccess(AppFeature.billing)
                            ? null
                            : AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _canAccess(AppFeature.billing)
                            ? [
                                BoxShadow(
                                  color: AppColors.cyan.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _canAccess(AppFeature.billing)
                                ? Icons.currency_rupee
                                : Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Sale",
                            style: AppTextStyles.small.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Inventory
                Expanded(child: _navItem(2)),
                // More
                Expanded(child: _navItem(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final (icon, label, feature) = _navItems[index];
    final isActive = _currentIndex == index;
    final canAccess = _canAccess(feature);

    final displayIcon = canAccess ? icon : Icons.lock_outline;

    final color = isActive
        ? AppColors.primary
        : canAccess
        ? AppColors.textSecondary
        : AppColors.borderStrong;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(displayIcon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
