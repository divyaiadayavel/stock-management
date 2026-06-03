import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),

      body: MobileScanner(
        onDetect: (capture) {
          if (isScanned) return;

          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            final String code = barcode.rawValue ?? "";

            isScanned = true;

            Navigator.pop(context, code);

            break;
          }
        },
      ),
    );
  }
}
