import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  bool isLoading = true;

  bool barcodeEnabled = true;
  bool lowStockAlert = true;
  String lowStockLimit = "5";
  bool stockManagement = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    String? barcodeStr = settings["barcodeEnabled"];
    barcodeEnabled = barcodeStr == null ? true : barcodeStr == "true";

    String? alertStr = settings["lowStockAlert"];
    lowStockAlert = alertStr == null ? true : alertStr == "true";

    lowStockLimit = settings["lowStockLimit"] ?? "5";

    String? stockStr = settings["stockManagement"];
    stockManagement = stockStr == null ? true : stockStr == "true";

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateToggleSetting(String dbKey, bool newValue) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(dbKey, newValue.toString());
    setState(() {
      if (dbKey == "barcodeEnabled") barcodeEnabled = newValue;
      if (dbKey == "lowStockAlert") lowStockAlert = newValue;
      if (dbKey == "stockManagement") stockManagement = newValue;
    });
  }

  void _openEditDialog() {
    final TextEditingController ctrl = TextEditingController(
      text: lowStockLimit,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Edit Low Stock Limit"),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Limit Quantity",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                String newValue = ctrl.text.trim();
                await ref
                    .read(settingsRepositoryProvider)
                    .saveSetting("lowStockLimit", newValue);

                if (!mounted) return;
                navigator.pop();
                _loadSettings();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Customize (Products & Units)",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Product Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildNavActionItem(
                          icon: Icons.category_outlined,
                          iconColor: Colors.redAccent,
                          title: "Product Categories",
                          subtitle: "Manage your product categories",
                          onTap: () {
                            // Navigate to Categories Screen
                          },
                        ),
                        _buildDivider(),
                        _buildNavActionItem(
                          icon: Icons.ad_units,
                          iconColor: Colors.orange,
                          title: "Units",
                          subtitle: "Manage product units",
                          onTap: () {
                            // Navigate to Units Screen
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.qr_code_scanner,
                          iconColor: Colors.green,
                          title: "Barcode Settings",
                          subtitle: "Enable barcode for products",
                          value: barcodeEnabled,
                          dbKey: "barcodeEnabled",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orangeAccent,
                          title: "Low Stock Alert",
                          subtitle: "Enable alerts for low stock",
                          value: lowStockAlert,
                          dbKey: "lowStockAlert",
                        ),
                        _buildDivider(),
                        _buildNavActionItem(
                          icon: Icons.sim_card_outlined,
                          iconColor: Colors.blueAccent,
                          title: "Low Stock Limit",
                          subtitle: lowStockLimit,
                          onTap: _openEditDialog,
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.inventory_2_outlined,
                          iconColor: Colors.teal,
                          title: "Stock Management",
                          subtitle: "Enable stock tracking",
                          value: stockManagement,
                          dbKey: "stockManagement",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildNavActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.blue,
            onChanged: (newValue) => _updateToggleSetting(dbKey, newValue),
          ),
        ],
      ),
    );
  }
}
