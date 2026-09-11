import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';
import 'current_bill_screen.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/data/models/product_model.dart';

// ─── Inline notification helper ───
void _showCustomNotification(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (ctx) => Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isError ? AppColors.red : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () => entry.remove());
}

// ─── Scanner Screen ───
class ScannerBillScreen extends ConsumerStatefulWidget {
  const ScannerBillScreen({super.key});

  @override
  ConsumerState<ScannerBillScreen> createState() => _ScannerBillScreenState();
}

class _ScannerBillScreenState extends ConsumerState<ScannerBillScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer _player = AudioPlayer();

  String? _lastBarcode;
  DateTime? _lastScanTime;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final productState = ref.read(productListProvider);
    if (productState.items.isEmpty && !productState.isInitialLoading) {
      Future.microtask(() {
        ref.read(productListProvider.notifier).loadProducts();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.stop();
    controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    // Debounce: ignore same barcode within 1.5 seconds
    final now = DateTime.now();
    if (_lastBarcode == barcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastBarcode = barcode;
    _lastScanTime = now;

    if (isProcessing) return;
    isProcessing = true;

    // Stop scanner to prevent multiple detections
    await controller.stop();

    final productState = ref.read(productListProvider);
    Product? product;
    try {
      product = productState.items.firstWhere(
        (p) => p.barcode.trim() == barcode.trim(),
      );
    } catch (_) {
      product = null;
    }

    if (product != null) {
      // ── Check stock ──
      if (product.quantity <= 0) {
        if (mounted) {
          _showCustomNotification(
            context,
            '${product.name} is out of stock',
            isError: true,
          );
        }
      } else {
        // ── Check if already in cart ──
        final cart = ref.read(billingProvider).cart;
        final alreadyInCart = cart.any((item) => item.productId == product!.id);

        if (alreadyInCart) {
          if (mounted) {
            _showCustomNotification(
              context,
              'Product already scanned',
              isError: true,
            );
          }
        } else {
          // ── Add new product ──
          ref.read(billingProvider.notifier).addProduct(product);
          await _player.play(AssetSource('sounds/scanner_beep.mp3'));

          if (mounted) {
            _showCustomNotification(
              context,
              '${product.name} added to bill',
              isError: false,
            );
          }
        }
      }
    } else {
      if (mounted) {
        _showCustomNotification(context, 'Product not found', isError: true);
      }
    }

    // Wait a bit before restarting
    await Future.delayed(const Duration(milliseconds: 600));
    await controller.start();
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── Scanner ──
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
                        onPressed: () async {
                          await controller.stop();
                          if (mounted) Navigator.pop(context);
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

          // ── Scanned Items List ──
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
                              'Scanned Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${billingState.totalItems} Items',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '₹ ${billingState.grandTotal.toStringAsFixed(2)}',
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity controls
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
                                              .decreaseQty(item.productId);
                                        },
                                        child: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.qty.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          ref
                                              .read(billingProvider.notifier)
                                              .increaseQty(item.productId);
                                        },
                                        child: const Icon(Icons.add, size: 18),
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
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CurrentBillScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Review Bill (${billingState.totalItems})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
