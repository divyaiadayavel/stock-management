import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../models/printers_hardware/receipt/receipt_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
import 'esc_pos_service.dart';

/// Compact 2‑column (Name | Price) Thermal Receipt Builder.
/// Font B is used throughout the body (smaller, narrower glyphs, more
/// chars/line) to cut paper usage, with bold applied for a touch more
/// visual weight (ESC/POS has no true pixel-level size step — bold
/// thickens strokes without changing the character cell width, so
/// alignment math is unaffected).
class ReceiptBuilder {
  final EscPosService _escPos;

  ReceiptBuilder({required EscPosService escPos}) : _escPos = escPos;

  // ============================================================
  // RECEIPT UI CONFIGURATION
  // Change only these values to customize receipt appearance.
  // ============================================================
  // ---------- Header ----------
  static const bool printLogo = true;
  static const bool printStoreName = true; // New toggle for store name
  static const bool printStoreAddress = true;
  static const bool printPhone = true;
  static const bool printGST = true;

  // ---------- Meta ----------
  static const bool printInvoiceNumber = true;
  static const bool printDate = true;
  static const bool printTime = true;

  // ---------- Items ----------
  static const bool printTableHeader = true;
  static const bool printQty = true;
  static const bool printPrice = true;

  // ---------- Summary ----------
  static const bool printSubtotal = true;
  static const bool printGSTSummary = true;
  static const bool printGrandTotal = true;

  // ---------- Footer ----------
  static const bool printPaymentMode = true;
  static const bool printReceiptId = true;
  static const bool printThankYou = true;

  // ---------- Receipt ----------
  static const bool printCut = true;
  static const bool printBottomFeed = true;

  // ---------- Dashed Line ----------
  static const bool useDashedLine = true;

  // ---------- Paper ----------
  static const int mm58CharWidth = 32;
  static const int mm80CharWidth = 48;

  // ---------- Body Font ----------
  static const PosFontType bodyFont = PosFontType.fontA;
  static const bool bodyBold = true;

  // ---------- Header Font ----------
  static const PosFontType headerFont = PosFontType.fontA;
  static const bool headerBold = true;
  static const PosTextSize headerWidth = PosTextSize.size1;
  static const PosTextSize headerHeight = PosTextSize.size1;

  // ---------- Total Font ----------
  static const PosTextSize totalWidth = PosTextSize.size1;
  static const PosTextSize totalHeight = PosTextSize.size1;
  static const bool totalBold = true;

  // ---------- Line Spacing ----------
  // 12 = Very Compact
  // 16 = Compact (Recommended)
  // 20 = Normal
  // 24 = Spacious
  static const int lineSpacing = 30;

  // ---------- Bottom Feed ----------
  static const int bottomFeedLines = 0;

  // ---------- Logo ----------
  static const int logoWidth58 = 140;
  static const int logoWidth80 = 220;

  // ---------- Separator ----------
  static const String dashLine = '------------------------------';

  // ---------- Alignment ----------
  static const PosAlign dashAlign = PosAlign.center;
  static const PosAlign footerAlign = PosAlign.center;
  static const PosAlign headerAlign = PosAlign.center;

  // ---------- Price Column ----------
  static const int minimumPriceWidth = 8;

  // ---------- Product Name ----------
  static const bool wrapLongNames = true;

  // ---------- Receipt Footer ----------
  static const String thankYouText = 'THANK YOU! VISIT AGAIN';

  // ============================================================
  // STYLES (derived from config above — do not edit directly)
  // ============================================================

  static const PosStyles _styleB = PosStyles(
    fontType: bodyFont,
    bold: bodyBold,
  );

  static const PosStyles _styleBBold = PosStyles(
    fontType: bodyFont,
    bold: true,
  );

  static const PosStyles _styleBCenter = PosStyles(
    fontType: bodyFont,
    align: footerAlign,
    bold: bodyBold,
  );

  /// Minimum characters reserved for the price column (covers the
  /// "Price" header label plus a little breathing room for small numbers).
  static const int _minPriceWidth = minimumPriceWidth;

  /// Body font character width per line.
  int _charWidth(PaperSize paperSize) =>
      paperSize == PaperSize.mm58 ? mm58CharWidth : mm80CharWidth;

  Future<List<int>> buildReceiptBytes(
    ReceiptModel receipt,
    PrinterCapabilityModel capabilities,
  ) async {
    // 55mm rolls print at the same usable width as 58mm rolls, so route
    // anything under 70mm to the mm58 profile instead of defaulting to mm80.
    final paperSize =
        capabilities.paperWidthMm >= 70 ? PaperSize.mm80 : PaperSize.mm58;
    final width = _charWidth(paperSize);

    // --- Dynamic price column width ---
    // Sized to the longest price actually appearing on this receipt, so
    // 5-6 digit totals never overflow the line and force an unwanted wrap.
    final priceWidth = _computePriceWidth(receipt);
    final nameWidth = width - priceWidth - 1;

    List<int> bytes = [];

    // --- Hardware Reset ---
    bytes += const [0x1B, 0x40];
    bytes += const [0x1D, 0x21, 0x00];

    // --- Line Spacing ---
    bytes += [0x1B, 0x33, lineSpacing];

    // --- 1. Logo Block ---
    if (printLogo) {
      final logoPath = receipt.logoPath?.trim();
      if (logoPath != null && logoPath.isNotEmpty) {
        final logoBytes = await _buildLogoBytes(logoPath, paperSize);
        if (logoBytes != null) bytes += logoBytes;
      }
    }

    // --- 2. Store Header ---
    if (printStoreName && (receipt.storeName?.trim().isNotEmpty ?? false)) {
      bytes += await _escPos.text(
        receipt.storeName!.trim(),
        styles: const PosStyles(
          align: headerAlign,
          fontType: headerFont,
          bold: headerBold,
          width: headerWidth,
          height: headerHeight,
        ),
        paperSize: paperSize,
      );
    }

    if (printStoreAddress &&
        (receipt.storeAddress?.trim().isNotEmpty ?? false)) {
      final address = receipt.storeAddress!.trim().replaceAll('\n', ', ');
      bytes += await _escPos.text(address, styles: _styleBCenter, paperSize: paperSize);
    }

    if (printPhone &&
        (receipt.storePhone?.trim().isNotEmpty ?? false)) {
      bytes += await _escPos.text(
        'Ph - ${receipt.storePhone!.trim()}',
        styles: _styleBCenter,
        paperSize: paperSize,
      );
    }

    if (printGST &&
        (receipt.gstNumber?.trim().isNotEmpty ?? false)) {
      bytes += await _escPos.text(
        'GSTIN: ${receipt.gstNumber!.trim()}',
        styles: _styleBCenter,
        paperSize: paperSize,
      );
    }

    if (useDashedLine) {
      bytes += await _dash(paperSize);
    }

    // --- 3. Meta Information ---
    if (printInvoiceNumber) {
      bytes += await _escPos.text(
        'INV : #${receipt.receiptId}',
        styles: _styleB,
        paperSize: paperSize,
      );
    }

    final dateStr = _formatDate(receipt.timestamp);
    final timeStr = _formatTime(receipt.timestamp);
if (printDate || printTime) {
  final left = printDate ? dateStr : '';
  final right = printTime ? timeStr : '';

  bytes += await _escPos.text(
    _arrangeTwoColumns(left, right, width),
    styles: _styleB,
    paperSize: paperSize,
  );
}

// ADD THIS
if (useDashedLine) {
  bytes += await _dash(paperSize);
}

// --- 4. Two-Column Header: Name | Price ---
// if (printTableHeader) {
//   final tableHeader =
//       'NAME * QTY'.padRight(nameWidth) +
//       'PRICE'.padLeft(priceWidth);

//   bytes += await _escPos.text(
//     tableHeader,
//     styles: _styleBBold,
//     paperSize: paperSize,
//   );
// }
// --- 4. Two-Column Header: Service Name | Price ---
if (printTableHeader) {
  final isServiceReceipt = receipt.paymentMode == null;

  final tableHeader =
      (isServiceReceipt ? 'SERVICE NAME' : 'NAME * QTY')
          .padRight(nameWidth) +
      'PRICE'.padLeft(priceWidth);

  bytes += await _escPos.text(
    tableHeader,
    styles: _styleBBold,
    paperSize: paperSize,
  );
}

if (useDashedLine) {
  bytes += await _dash(paperSize);
}

    // --- 5. Product Rows: "item*qty"  |  price for that line ---
//     for (final item in receipt.items) {
//       final qtyStr = _qtyString(item.quantity);
// final productName = _sanitizeProductName(item.itemName);

// final displayName = printQty
//     ? '$productName *$qtyStr'
//     : productName;
for (final item in receipt.items) {
  final isServiceReceipt = receipt.paymentMode == null;

  final qtyStr = _qtyString(item.quantity);
  final productName = _sanitizeProductName(item.itemName);

  final displayName = isServiceReceipt
      ? productName
      : (printQty
          ? '$productName *$qtyStr'
          : productName);
      final priceText = printPrice
          ? item.totalAmount
              .toStringAsFixed(2)
              .padLeft(priceWidth)
          : ''.padLeft(priceWidth);

      if (displayName.length <= nameWidth) {
        final row = displayName.padRight(nameWidth) + priceText;
        bytes += await _escPos.text(row, styles: _styleB, paperSize: paperSize);
      } else if (!wrapLongNames) {
        // Truncate to a single line instead of wrapping onto extra lines.
        final truncated = displayName.substring(0, nameWidth);
        bytes += await _escPos.text(truncated + priceText, styles: _styleB, paperSize: paperSize);
      } else {
        final firstChunk = displayName.substring(0, nameWidth);
        String remaining = displayName.substring(nameWidth);

        bytes += await _escPos.text(firstChunk + priceText, styles: _styleB, paperSize: paperSize);

        while (remaining.isNotEmpty) {
          final take = remaining.length > nameWidth ? nameWidth : remaining.length;
          final chunk = remaining.substring(0, take);
          remaining = remaining.substring(take);
          bytes += await _escPos.text(chunk.padRight(width), styles: _styleB, paperSize: paperSize);
        }
      }
    }

    if (useDashedLine) {
      bytes += await _dash(paperSize);
    }

    // --- 6. Financial Summary — explicitly aligned to the same
    // nameWidth/priceWidth column as the item rows above (CGST + SGST
    // merged into a single GST line). ---
    if (printSubtotal) {
      final subTotalRow = 'Subtotal'.padRight(nameWidth) +
          receipt.subTotal.toStringAsFixed(2).padLeft(priceWidth);
      bytes += await _escPos.text(subTotalRow, styles: _styleB, paperSize: paperSize);
    }

    if (printGSTSummary) {
      final gstRow = 'GST'.padRight(nameWidth) +
          receipt.taxAmount.toStringAsFixed(2).padLeft(priceWidth);
      bytes += await _escPos.text(gstRow, styles: _styleB, paperSize: paperSize);
    }

    if (useDashedLine) {
      bytes += await _dash(paperSize);
    }

    if (printGrandTotal) {
      final totalRow = 'TOTAL'.padRight(nameWidth) +
          receipt.grandTotal.toStringAsFixed(2).padLeft(priceWidth);
      bytes += await _escPos.text(
        totalRow,
        styles: const PosStyles(
          bold: totalBold,
          width: totalWidth,
          height: totalHeight,
        ),
        paperSize: paperSize,
      );
    }

    if (useDashedLine) {
      bytes += await _dash(paperSize);
    }

    // --- 7. Footer ---
    final payment = (receipt.paymentMode?.trim().isNotEmpty ?? false)
        ? receipt.paymentMode!.trim().toUpperCase()
        : 'CASH';

    if (printPaymentMode) {
      bytes += await _escPos.text(
        'Payment : $payment',
        styles: _styleBCenter,
        paperSize: paperSize,
      );
    }

    if (printThankYou) {
      bytes += await _escPos.text(
        thankYouText,
        styles: const PosStyles(
          align: footerAlign,  // now configurable
          bold: true,
        ),
        paperSize: paperSize,
      );
    }

    if (printReceiptId) {
      bytes += await _escPos.text(
        receipt.receiptId,
        styles: _styleBCenter,
        paperSize: paperSize,
      );
    }

    // --- Restore default line spacing & Cut ---
    bytes += const [0x1B, 0x32];
    if (printBottomFeed) {
      bytes += await _escPos.feed(
        paperSize: paperSize,
        lines: bottomFeedLines,
      );
    }
    if (printCut) {
      bytes += await _escPos.cut(
        paperSize: paperSize,
      );
    }

    return bytes;
  }

  /// Finds the longest price string that will actually appear on this
  /// receipt (items, subtotal, GST, grand total) and sizes the price
  /// column to fit it, so large totals never force an unwanted wrap.
  int _computePriceWidth(ReceiptModel receipt) {
    int maxLen = _minPriceWidth;
    for (final item in receipt.items) {
      final len = item.totalAmount.toStringAsFixed(2).length;
      if (len > maxLen) maxLen = len;
    }
    final subLen = receipt.subTotal.toStringAsFixed(2).length;
    final gstLen = receipt.taxAmount.toStringAsFixed(2).length;
    final totalLen = receipt.grandTotal.toStringAsFixed(2).length;
    maxLen = [maxLen, subLen, gstLen, totalLen].reduce((a, b) => a > b ? a : b);
    // +1 char of breathing room so the number never touches the item name.
    return maxLen + 1;
  }

  /// Centered dashed separator — printer-native center alignment, not
  /// manual space padding, so it's never lopsided regardless of the
  /// printer's actual font metrics.
  Future<List<int>> _dash(PaperSize paperSize) {
    return _escPos.text(
      dashLine,
      styles: const PosStyles(
        align: dashAlign,
        fontType: bodyFont,
        bold: bodyBold,
      ),
      paperSize: paperSize,
    );
  }

  String _qtyString(num quantity) {
    return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
  }

  Future<List<int>?> _buildLogoBytes(String logoPath, PaperSize paperSize) async {
    try {
      final file = File(logoPath);
      if (!await file.exists()) return null;
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final maxWidth = paperSize == PaperSize.mm58 ? logoWidth58 : logoWidth80;
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

  String _sanitizeProductName(String text) {
  return text
      .replaceAll(
        RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
          unicode: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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