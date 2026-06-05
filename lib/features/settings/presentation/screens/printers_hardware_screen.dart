import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PrintersHardwareScreen extends StatefulWidget {
  const PrintersHardwareScreen({super.key});

  @override
  State<PrintersHardwareScreen> createState() => _PrintersHardwareScreenState();
}

class _PrintersHardwareScreenState extends State<PrintersHardwareScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Printers & Hardware",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "Printer Settings",
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
                  _buildHardwareItem(
                    icon: Icons.print,
                    iconColor: Colors.blue,
                    title: "Bluetooth Printer",
                    status: "Not Connected",
                  ),
                  _buildDivider(),
                  _buildHardwareItem(
                    icon: Icons.receipt_long,
                    iconColor: Colors.purple,
                    title: "Thermal Printer",
                    status: "Not Connected",
                  ),
                  _buildDivider(),
                  _buildHardwareItem(
                    icon: Icons.wifi,
                    iconColor: Colors.blueAccent,
                    title: "Wi-Fi Printer",
                    status: "Not Connected",
                  ),
                  _buildDivider(),
                  _buildHardwareItem(
                    icon: Icons.usb,
                    iconColor: Colors.indigo,
                    title: "USB Printer",
                    status: "Not Connected",
                  ),
                  _buildDivider(),
                  _buildHardwareItem(
                    icon: Icons.print_outlined,
                    iconColor: Colors.blueGrey,
                    title: "Default Printer",
                    status: "Not Set",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "Other Hardware",
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
                  _buildHardwareItem(
                    icon: Icons.qr_code_scanner,
                    iconColor: Colors.teal,
                    title: "Barcode Scanner",
                    status: "Not Connected",
                  ),
                  _buildDivider(),
                  _buildHardwareItem(
                    icon: Icons.point_of_sale,
                    iconColor: Colors.green,
                    title: "Cash Drawer",
                    status: "Not Connected",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Test Print Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No printer connected")),
                  );
                },
                child: const Text(
                  "Test Print",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildHardwareItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
  }) {
    return InkWell(
      onTap: () {
        // Handle pairing/connection logic here later
      },
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
                    status,
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
}
