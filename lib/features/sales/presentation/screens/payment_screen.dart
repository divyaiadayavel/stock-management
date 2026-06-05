import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'invoice_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_provider.dart';
import '../../../../core/constants/app_curve.dart';

class PaymentScreen extends ConsumerWidget {
  final double totalAmount;
  final String invoiceNumber;
  final int invoiceId;

  PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.invoiceNumber,
    required this.invoiceId,
  });

  final TextEditingController _upiController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(paymentProvider);

    final paymentNotifier = ref.read(paymentProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),

            onPressed: () {},
          ),
        ],
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              // Set to horizontal: 20 to preserve your exact original padding consistency
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ================= AMOUNT CARD =================
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Column(
                      children: [
                        const Text(
                          "TOTAL PAYABLE AMOUNT",

                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "₹${totalAmount.toStringAsFixed(2)}",

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 16,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                invoiceNumber,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Select Payment Method",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= CASH =================
                  _buildPaymentOption(
                    selectedMethod: selectedMethod,
                    paymentNotifier: paymentNotifier,
                    title: "Cash",
                    subtitle: "Instant settlement at counter",
                    icon: Icons.money,
                    value: "Cash",
                  ),

                  const SizedBox(height: 12),

                  // ================= UPI =================
                  _buildPaymentOption(
                    selectedMethod: selectedMethod,
                    paymentNotifier: paymentNotifier,
                    title: "UPI / Digital Payment",
                    subtitle: "Secure Google Pay, PhonePe, etc.",
                    icon: Icons.account_balance_wallet_outlined,
                    value: "UPI",
                    isExpanded: selectedMethod == "UPI",
                  ),

                  const SizedBox(height: 60),

                  // ================= SECURITY =================
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: const [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),

                        SizedBox(width: 4),

                        Text(
                          "Secure 256-bit encrypted transaction",

                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= INVOICE BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long, color: Colors.white),

                      label: const Text(
                        "Open Invoice",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      onPressed: () {
                        // ✅ Check payment method selected or not
                        if (selectedMethod == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a payment method"),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceScreen(invoiceId: invoiceId),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= PAYMENT OPTION =================
  Widget _buildPaymentOption({
    required String? selectedMethod,
    required StateController<String?> paymentNotifier,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    bool isExpanded = false,
  }) {
    bool isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () {
        paymentNotifier.state = value;
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,

            width: isSelected ? 2 : 1,
          ),
        ),

        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Icon(icon, color: AppColors.primary),
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
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        subtitle,

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Radio<String>(
                  value: value,
                  groupValue: selectedMethod,
                  activeColor: AppColors.primary,

                  onChanged: (val) {
                    paymentNotifier.state = val!;
                  },
                ),
              ],
            ),

            // ================= UPI FIELD =================
            if (isExpanded) ...[
              const SizedBox(height: 16),

              TextField(
                controller: _upiController,

                decoration: const InputDecoration(
                  labelText: "UPI ID",
                  hintText: "username@bank",
                  border: OutlineInputBorder(),

                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),

                child: Text(
                  "OR",

                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              OutlinedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.qr_code_scanner),

                label: const Text("Scan QR Code"),

                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,

                  minimumSize: const Size(double.infinity, 45),

                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
