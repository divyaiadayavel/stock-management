import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../providers/billing_provider.dart';
import 'current_bill_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerBillScreen extends ConsumerStatefulWidget {
  const ScannerBillScreen({super.key});

  @override
  ConsumerState<ScannerBillScreen> createState() => _ScannerBillScreenState();
}

class _ScannerBillScreenState extends ConsumerState<ScannerBillScreen> {
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer _player = AudioPlayer();
  bool isProcessing = false;

  Future<void> _onBarcodeDetected(String barcode) async {
    if (isProcessing) return;

    isProcessing = true;

    final product = await DBHelper.getProductByBarcode(barcode);

    if (product != null) {
      ref.read(billingProvider.notifier).addToCart(product, 1);

      await _player.play(AssetSource('sounds/scanner_beep.mp3'));
    }

    await Future.delayed(const Duration(seconds: 2));

    isProcessing = false;
  }

  @override
  void dispose() {
    _player.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);

    return Scaffold(
      backgroundColor: Colors.black,

      body: Column(
        children: [
          /// ================= SCANNER =================
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first.rawValue;

                    if (barcode != null) {
                      _onBarcodeDetected(barcode);
                    }
                  },
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ================= PRODUCT AREA =================
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Scanned Items",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              "${billingState.cart.length} Items",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        const Spacer(),

                        Text(
                          "₹ ${billingState.total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: billingState.cart.length,
                      itemBuilder: (context, index) {
                        final item = billingState.cart[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text("₹${item.price}"),
                                  ],
                                ),
                              ),

                              Container(
                                width: 110,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          ref
                                              .read(billingProvider.notifier)
                                              .decreaseQty(index);
                                        },
                                        child: const Icon(Icons.remove),
                                      ),
                                    ),

                                    Text(item.qty.toString()),

                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          ref
                                              .read(billingProvider.notifier)
                                              .increaseQty(index);
                                        },
                                        child: const Icon(Icons.add),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CurrentBillScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Review Bill (${billingState.cart.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
