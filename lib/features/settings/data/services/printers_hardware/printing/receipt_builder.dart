import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../models/printers_hardware/receipt/receipt_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
import 'esc_pos_service.dart';

/// Professional Thermal Receipt Builder with bulletproof 4-column compact item alignment.
class ReceiptBuilder {
  final EscPosService _escPos;

  ReceiptBuilder({required EscPosService escPos}) : _escPos = escPos;

  int _charWidth(PaperSize paperSize) =>
      paperSize == PaperSize.mm58 ? 32 : 48;

  Future<List<int>> buildReceiptBytes(
    ReceiptModel receipt,
    PrinterCapabilityModel capabilities,
  ) async {
    final paperSize =
        capabilities.paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final width = _charWidth(paperSize);
    List<int> bytes = [];

    // --- Hardware Reset ---
    bytes += const [0x1B, 0x40];
    bytes += const [0x1D, 0x21, 0x00];

    // --- 1. Logo Block ---
    final logoPath = receipt.logoPath?.trim();
    if (logoPath != null && logoPath.isNotEmpty) {
      final logoBytes = await _buildLogoBytes(logoPath, paperSize);
      if (logoBytes != null) bytes += logoBytes;
    }

    // --- 2. Store Header ---
    if (receipt.storeName?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.text(
        receipt.storeName!.trim(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
        paperSize: paperSize,
      );
    }

    if (receipt.storeAddress?.trim().isNotEmpty ?? false) {
      final address = receipt.storeAddress!.trim().replaceAll('\n', ', ');
      bytes += await _escPos.center(address, paperSize: paperSize);
    }

    if (receipt.storePhone?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.center('Ph - ${receipt.storePhone!.trim()}', paperSize: paperSize);
    }
    
    if (receipt.gstNumber?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.center('GSTIN: ${receipt.gstNumber!.trim()}', paperSize: paperSize);
    }

    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    // --- 3. Meta Information ---
    bytes += await _escPos.left('INV : #${receipt.receiptId}', paperSize: paperSize);
    
    final dateStr = _formatDate(receipt.timestamp);
    final timeStr = _formatTime(receipt.timestamp);
    bytes += await _escPos.left(_arrangeTwoColumns(dateStr, timeStr, width), paperSize: paperSize);
    
    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    // --- 4. Micro-Managed 4-Column Layout Spacing ---
    // Total Chars Allocation for 58mm (32 Total): Item(13), Qty(4), Price(7), Amount(8)
    // Total Chars Allocation for 80mm (48 Total): Item(23), Qty(5), Price(10), Amount(10)
    final int qtyWidth = paperSize == PaperSize.mm58 ? 4 : 5;
    final int priceWidth = paperSize == PaperSize.mm58 ? 7 : 10;
    final int amountWidth = paperSize == PaperSize.mm58 ? 8 : 10;
    final int itemWidth = width - qtyWidth - priceWidth - amountWidth;

    final tableHeader = 'Item'.padRight(itemWidth) +
        'Qty.'.padLeft(qtyWidth) + 
        'Price'.padLeft(priceWidth) + 
        'Amount'.padLeft(amountWidth);
    bytes += await _escPos.left(tableHeader, paperSize: paperSize);
    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    // --- 5. Product Rows with Dynamic Word Wrapping & Zero Row Gaps ---
    for (final item in receipt.items) {
      final qtyText = '${item.quantity}'.padLeft(qtyWidth);
      final priceText = item.unitPrice.toStringAsFixed(2).padLeft(priceWidth);
      final amountText = item.totalAmount.toStringAsFixed(2).padLeft(amountWidth);
      String itemName = item.itemName.trim();

      if (itemName.length <= itemWidth) {
        // Fits perfectly on one line
        final row = itemName.padRight(itemWidth) + qtyText + priceText + amountText;
        bytes += await _escPos.left(row, paperSize: paperSize);
      } else {
        // Break name up cleanly without causing empty layout shifts
        final String firstLineChunk = itemName.substring(0, itemWidth);
        itemName = itemName.substring(itemWidth);

        final firstRow = firstLineChunk + qtyText + priceText + amountText;
        bytes += await _escPos.left(firstRow, paperSize: paperSize);

        // Keep wrapping trailing item descriptions directly under column 1 (tight coupling)
        while (itemName.isNotEmpty) {
          final int lengthToTake = itemName.length > itemWidth ? itemWidth : itemName.length;
          final String trailingChunk = itemName.substring(0, lengthToTake);
          itemName = itemName.substring(lengthToTake);

          // Render remaining name snippet padded cleanly out away from values
          bytes += await _escPos.left(trailingChunk.padRight(width), paperSize: paperSize);
        }
      }
    }

    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    // --- 6. Financial Summary Block ---
    final subTotalValue = receipt.subTotal.toStringAsFixed(2);
    bytes += await _escPos.left(_arrangeTwoColumns('Subtotal', subTotalValue, width), paperSize: paperSize);

    final halfTax = receipt.taxAmount / 2;
    bytes += await _escPos.left(_arrangeTwoColumns('CGST 0.00', halfTax.toStringAsFixed(2), width), paperSize: paperSize);
    bytes += await _escPos.left(_arrangeTwoColumns('SGST 0.00', halfTax.toStringAsFixed(2), width), paperSize: paperSize);
    
    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    final grandTotalValue = receipt.grandTotal.toStringAsFixed(2);
    final totalRow = 'TOTAL'.padRight(width - grandTotalValue.length) + grandTotalValue;
    bytes += await _escPos.text(
      totalRow,
      styles: const PosStyles(bold: true),
      paperSize: paperSize,
    );

    bytes += await _escPos.left('-' * width, paperSize: paperSize);

    // --- 7. Footer Meta Area ---
    final payment = (receipt.paymentMode?.trim().isNotEmpty ?? false)
        ? receipt.paymentMode!.trim().toUpperCase()
        : 'CASH';
        
    bytes += await _escPos.center('Payment : $payment', paperSize: paperSize);
    
    bytes += await _escPos.text(
      'THANK YOU! VISIT AGAIN',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperSize: paperSize,
    );
    
    bytes += await _escPos.center(receipt.receiptId, paperSize: paperSize);

    // Cut routine
    bytes += await _escPos.feed(paperSize: paperSize, lines: 3);
    bytes += await _escPos.cut(paperSize: paperSize);

    return bytes;
  }

  Future<List<int>?> _buildLogoBytes(String logoPath, PaperSize paperSize) async {
    try {
      final file = File(logoPath);
      if (!await file.exists()) return null;
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final maxWidth = paperSize == PaperSize.mm58 ? 140 : 220;
      if (decoded.width > maxWidth) {
        final scale = maxWidth / decoded.width;
        final resized = img.copyResize(
          decoded, 
          width: maxWidth, 
          height: (decoded.height * scale).round(),
        );
        final generator = await _escPos.createGenerator(paperSize: paperSize);
        return generator.image(resized, align: PosAlign.center);
      }

      final generator = await _escPos.createGenerator(paperSize: paperSize);
      return generator.image(decoded, align: PosAlign.center);
    } catch (_) {
      return null;
    }
  }

  String _arrangeTwoColumns(String left, String right, int width) {
    final spacesCount = width - left.length - right.length;
    if (spacesCount > 0) {
      return left + (' ' * spacesCount) + right;
    }
    return '$left $right';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$day-${months[value.month - 1]}-${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final minute = value.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}