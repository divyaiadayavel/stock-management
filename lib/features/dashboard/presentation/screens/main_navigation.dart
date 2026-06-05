import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../../../products/presentation/screens/product_screen.dart';
import '../../../sales/presentation/screens/billing_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final pages = [
    const DashboardScreen(), // Home
    const ProductScreen(), // Products
    const Placeholder(), // Bill (NOT USED NOW)
    const SuppliersScreen(),
    const SettingsScreen(), // Settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      /// 🔥 CENTER FLOATING BUTTON (BILL)
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            // ✅ OPEN BILLING SCREEN (FIXED)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillingScreen()),
            );
          },
          icon: const Icon(Icons.receipt_long, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔥 BOTTOM NAV BAR
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
              _navItem(Icons.home_outlined, "Home", 0),
              _navItem(Icons.inventory_2_outlined, "Products", 1),

              const SizedBox(width: 50),

              _navItem(Icons.local_shipping_outlined, "Suppliers", 3),
              _navItem(Icons.settings, "Settings", 4),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 NAV ITEM
  Widget _navItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => currentIndex = index);

        if (index == 1) {
          setState(() {
            currentIndex = 1;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
