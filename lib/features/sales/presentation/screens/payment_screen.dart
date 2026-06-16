import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart'; // Make sure this path is correct
import 'invoice_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_provider.dart';
import '../../../../core/constants/app_curve.dart';
import '../providers/billing_provider.dart';

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
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: R.icon(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: R.fs(context, 20),
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: R.icon(context, 24),
            ),
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
              // Dynamically switches paddings based on screen breakpoint (Centers and caps at 960px on desktop)
              padding: R.hPad(context, base: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: R.sp(context, 20)),

                  // ================= AMOUNT CARD =================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(R.sp(context, 24)),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "TOTAL PAYABLE AMOUNT",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: R.fs(context, 12),
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: R.sp(context, 8)),
                        Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: R.fs(context, 32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: R.sp(context, 12)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: R.sp(context, 12),
                            vertical: R.sp(context, 6),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              R.radius(context, 20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: R.icon(context, 16),
                              ),
                              SizedBox(width: R.sp(context, 6)),
                              Text(
                                invoiceNumber,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: R.fs(context, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 30)),

                  Text(
                    "Select Payment Method",
                    style: TextStyle(
                      fontSize: R.fs(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ================= CASH =================
                  _buildPaymentOption(
                    context: context,
                    selectedMethod: selectedMethod,
                    paymentNotifier: paymentNotifier,
                    title: "Cash",
                    subtitle: "Instant settlement at counter",
                    icon: Icons.money,
                    value: "Cash",
                  ),

                  SizedBox(height: R.sp(context, 12)),

                  // ================= UPI =================
                  _buildPaymentOption(
                    context: context,
                    selectedMethod: selectedMethod,
                    paymentNotifier: paymentNotifier,
                    title: "UPI / Digital Payment",
                    subtitle: "Secure Google Pay, PhonePe, etc.",
                    icon: Icons.account_balance_wallet_outlined,
                    value: "UPI",
                    isExpanded: selectedMethod == "UPI",
                  ),

                  SizedBox(height: R.sp(context, 60)),

                  // ================= SECURITY =================
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: R.icon(context, 16),
                          color: Colors.grey,
                        ),
                        SizedBox(width: R.sp(context, 4)),
                        Text(
                          "Secure 256-bit encrypted transaction",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: R.fs(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ================= INVOICE BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: R.btnH(
                      context,
                    ), // Responsive button height scaling from 50 to 64
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: R.icon(context, 20),
                      ),
                      label: Text(
                        "Open Invoice",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: R.fs(context, 16),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            R.radius(context, 12),
                          ),
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
                        // Clear current bill
                        ref.read(billingProvider.notifier).clearCart();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceScreen(invoiceId: invoiceId),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: R.sp(context, 20)),
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
    required BuildContext context,
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
        padding: EdgeInsets.all(R.sp(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
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
                  padding: EdgeInsets.all(R.sp(context, 8)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(R.radius(context, 8)),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: R.icon(context, 24),
                  ),
                ),
                SizedBox(width: R.sp(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: R.fs(context, 16),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: R.fs(context, 12),
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
              SizedBox(height: R.sp(context, 16)),
              TextField(
                controller: _upiController,
                style: TextStyle(fontSize: R.fs(context, 14)),
                decoration: InputDecoration(
                  labelText: "UPI ID",
                  labelStyle: TextStyle(fontSize: R.fs(context, 14)),
                  hintText: "username@bank",
                  hintStyle: TextStyle(fontSize: R.fs(context, 14)),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: R.sp(context, 8.0)),
                child: Text(
                  "OR",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: R.fs(context, 12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.qr_code_scanner, size: R.icon(context, 20)),
                label: Text(
                  "Scan QR Code",
                  style: TextStyle(fontSize: R.fs(context, 14)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, R.fluid(context, 45, 55)),
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
