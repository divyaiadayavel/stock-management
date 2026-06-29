import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 👇 Added Design System Imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

import '../../../auth/presentation/controllers/access_policy.dart';
import '../../../auth/presentation/providers/access_provider.dart';
import '../../../auth/presentation/widgets/access_guard.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../../../sales/presentation/screens/current_bill_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  // Fixed page list — AccessGuard handles showing restricted view
  // when the role cannot access that feature
  static const List<(AppFeature, Widget)> _pages = [
    (
      AppFeature.dashboard,
      AccessGuard(feature: AppFeature.dashboard, child: DashboardScreen()),
    ),
    (
      AppFeature.products,
      AccessGuard(feature: AppFeature.products, child: ProductScreen()),
    ),
    (
      AppFeature.suppliers,
      AccessGuard(feature: AppFeature.suppliers, child: SuppliersScreen()),
    ),
    (
      AppFeature.settings,
      AccessGuard(feature: AppFeature.settings, child: SettingsScreen()),
    ),
  ];

  // Nav bar items — order matches _pages above (billing is FAB, not a tab)
  static const List<(IconData, String, AppFeature)> _navItems = [
    (Icons.home_outlined, 'Home', AppFeature.dashboard),
    (Icons.inventory_2_outlined, 'Products', AppFeature.products),
    (Icons.local_shipping_outlined, 'Suppliers', AppFeature.suppliers),
    (Icons.settings_outlined, 'Settings', AppFeature.settings),
  ];

  bool _canAccess(AppFeature feature) {
    return ref.read(canAccessFeatureProvider(feature));
  }

  void _showAccessDenied(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label access is restricted for your role',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.red, // 👈 Updated to Semantic Danger
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

  void _openBilling() {
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
      // ── NO floatingActionButton, NO floatingActionButtonLocation ──
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
                // Inventory
                Expanded(child: _navItem(1)),

                // ── CENTER BILLING BUTTON ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: GestureDetector(
                    onTap: _canAccess(AppFeature.billing)
                        ? _openBilling
                        : () => _showAccessDenied('Billing'),
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
                      child: Icon(
                        _canAccess(AppFeature.billing)
                            ? Icons.shopping_cart_outlined
                            : Icons.lock_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Suppliers
                Expanded(child: _navItem(2)),
                // Settings
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

    // Locked icon when role cannot access this tab
    final displayIcon = canAccess ? icon : Icons.lock_outline;

    // 👇 Updated to use Catalystack Colors
    final color = isActive
        ? AppColors
              .primary // Active uses Brand Blue
        : canAccess
        ? AppColors
              .textSecondary // Inactive uses Muted Gray
        : AppColors.borderStrong; // Disabled uses strong border color

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque, // Ensures the whole column is clickable
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
              letterSpacing: 0, // Reset tracking for nav bar
            ),
          ),
        ],
      ),
    );
  }
}

// // ─── Billing FAB ──────────────────────────────────────────────────────────────
// class _BillingFab extends StatelessWidget {
//   const _BillingFab({required this.canAccess, required this.onTap});

//   final bool canAccess;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 52,
//       width: 52,
//       child: FloatingActionButton(
//         onPressed: canAccess ? onTap : null,
//         elevation: 4,
//         backgroundColor: Colors.transparent,
//         tooltip: canAccess ? 'Billing' : 'Billing restricted',
//         child: Ink(
//           decoration: BoxDecoration(
//             gradient: canAccess ? AppColors.brandGradient : null,
//             color: canAccess ? null : AppColors.borderStrong,
//             shape: BoxShape.circle,
//             boxShadow: canAccess
//                 ? [
//                     BoxShadow(
//                       color: AppColors.cyan.withOpacity(0.35),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3),
//                     ),
//                   ]
//                 : null,
//           ),
//           child: Icon(
//             canAccess ? Icons.shopping_cart_outlined : Icons.lock_outline,
//             color: Colors.white,
//             size: 24,
//           ),
//         ),
//       ),
//     );
//   }
// }
