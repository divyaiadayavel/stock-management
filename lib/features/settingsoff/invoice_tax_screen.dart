import 'package:flutter/material.dart';
// Update these paths if your folder structure differs
import '../../../../core/storage/db_helper.dart';
import '../../core/constants/app_colors.dart';

class InvoiceTaxScreen extends StatefulWidget {
  const InvoiceTaxScreen({super.key});

  @override
  State<InvoiceTaxScreen> createState() => _InvoiceTaxScreenState();
}

class _InvoiceTaxScreenState extends State<InvoiceTaxScreen> {
  bool isLoading = true;

  // Default values
  String invoicePrefix = "INV";
  String invoiceFormat = "INV-0001";
  String nextInvoiceNumber = "INV-000123";
  String defaultDueDate = "15 Days";
  bool showGst = true;
  bool showDiscount = true;
  String invoiceFooter = "Thanks for your business!";
  String termsConditions = "No return without permission.";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Fetch values from the existing 'settings' table
    invoicePrefix = await DBHelper.getSetting("invoicePrefix") ?? "INV";
    invoiceFormat = await DBHelper.getSetting("invoiceFormat") ?? "INV-0001";
    nextInvoiceNumber =
        await DBHelper.getSetting("nextInvoiceNumber") ?? "INV-000123";
    defaultDueDate = await DBHelper.getSetting("defaultDueDate") ?? "15 Days";

    // For booleans, we check if the stored string is "true"
    String? gstStored = await DBHelper.getSetting("showGst");
    showGst = gstStored == null ? true : gstStored == "true";

    String? discountStored = await DBHelper.getSetting("showDiscount");
    showDiscount = discountStored == null ? true : discountStored == "true";

    invoiceFooter =
        await DBHelper.getSetting("invoiceFooter") ??
        "Thanks for your business!";
    termsConditions =
        await DBHelper.getSetting("termsConditions") ??
        "No return without permission.";

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateToggleSetting(String dbKey, bool newValue) async {
    await DBHelper.saveSetting(dbKey, newValue.toString());
    setState(() {
      if (dbKey == "showGst") showGst = newValue;
      if (dbKey == "showDiscount") showDiscount = newValue;
    });
  }

  void _openEditDialog(String title, String dbKey, String currentValue) {
    final TextEditingController ctrl = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Edit $title"),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newValue = ctrl.text.trim();
                await DBHelper.saveSetting(dbKey, newValue);

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadSettings(); // Reload to reflect changes
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$title updated successfully")),
                  );
                }
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
        backgroundColor: AppColors.primary ?? Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Invoice & Tax",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                      "Invoice Settings",
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
                        _buildTextItem(
                          icon: Icons.receipt_outlined,
                          iconColor: Colors.blue,
                          title: "Invoice Prefix",
                          value: invoicePrefix,
                          dbKey: "invoicePrefix",
                        ),
                        _buildDivider(),
                        _buildTextItem(
                          icon: Icons.numbers,
                          iconColor: Colors.teal,
                          title: "Invoice Number Format",
                          value: invoiceFormat,
                          dbKey: "invoiceFormat",
                        ),
                        _buildDivider(),
                        _buildTextItem(
                          icon: Icons.pin_invoke,
                          iconColor: Colors.indigo,
                          title: "Next Invoice Number",
                          value: nextInvoiceNumber,
                          dbKey: "nextInvoiceNumber",
                        ),
                        _buildDivider(),
                        _buildTextItem(
                          icon: Icons.calendar_today_outlined,
                          iconColor: Colors.blueGrey,
                          title: "Default Due Date",
                          value: defaultDueDate,
                          dbKey: "defaultDueDate",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.percent,
                          iconColor: Colors.redAccent,
                          title: "Show GST in Invoice",
                          value: showGst,
                          dbKey: "showGst",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.discount_outlined,
                          iconColor: Colors.green,
                          title: "Show Discount in Invoice",
                          value: showDiscount,
                          dbKey: "showDiscount",
                        ),
                        _buildDivider(),
                        _buildTextItem(
                          icon: Icons.format_align_center,
                          iconColor: Colors.blueAccent,
                          title: "Invoice Footer",
                          value: invoiceFooter,
                          dbKey: "invoiceFooter",
                        ),
                        _buildDivider(),
                        _buildTextItem(
                          icon: Icons.article_outlined,
                          iconColor: Colors.deepOrange,
                          title: "Terms & Conditions",
                          value: termsConditions,
                          dbKey: "termsConditions",
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

  // Widget for Text fields with a Chevron (>)
  Widget _buildTextItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String dbKey,
  }) {
    return InkWell(
      onTap: () => _openEditDialog(title, dbKey, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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

  // Widget for Toggle Switch fields
  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ), // slightly less vertical padding to account for switch size
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.blue,
            onChanged: (newValue) => _updateToggleSetting(dbKey, newValue),
          ),
        ],
      ),
    );
  }
}
