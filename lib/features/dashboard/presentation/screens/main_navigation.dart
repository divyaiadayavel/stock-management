import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/access_policy.dart';
import '../../../auth/presentation/providers/access_provider.dart';
import '../../../auth/presentation/widgets/access_guard.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../../../sales/presentation/screens/add_product_bill_screen.dart';
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
        content: Text('$label access is restricted for your role'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    if (!_canAccess(AppFeature.billing)) {
      _showAccessDenied('Billing');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductBillScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the nav re-evaluates when auth state changes (e.g. logout)
    ref.watch(roleAccessProvider);

    return Scaffold(
      body: _pages[_currentIndex].$2,
      floatingActionButton: _BillingFab(
        canAccess: _canAccess(AppFeature.billing),
        onTap: _openBilling,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 12,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0),
              _navItem(1),
              const SizedBox(width: 50), // FAB notch gap
              _navItem(2),
              _navItem(3),
            ],
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
    final color = isActive
        ? Colors.blue
        : canAccess
        ? Colors.grey
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(displayIcon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ─── Billing FAB ──────────────────────────────────────────────────────────────

class _BillingFab extends StatelessWidget {
  const _BillingFab({required this.canAccess, required this.onTap});

  final bool canAccess;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = canAccess ? Colors.blue : Colors.grey.shade400;

    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          canAccess ? Icons.receipt_long : Icons.lock_outline,
          color: Colors.white,
          size: 26,
        ),
        tooltip: canAccess ? 'Billing' : 'Billing restricted',
      ),
    );
  }
}
