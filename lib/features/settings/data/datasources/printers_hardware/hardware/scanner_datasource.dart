import 'dart:async';
import 'package:flutter/services.dart';

abstract class ScannerDataSource {
  Stream<String> get barcodeStream;
  void startListening();
  void stopListening(); // temporarily pause, not close
  void dispose();       // permanently release resources
}

class ScannerDataSourceImpl implements ScannerDataSource {
  final StreamController<String> _barcodeStreamController = StreamController<String>.broadcast();
  String _currentBarcode = '';
  DateTime? _lastKeyPress;

  static const int scannerThreshold = 50; // milliseconds

  @override
  Stream<String> get barcodeStream => _barcodeStreamController.stream;

  @override
  void startListening() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void stopListening() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    // Do NOT close the stream – it can be restarted later.
  }

  @override
  void dispose() {
    stopListening();
    _barcodeStreamController.close();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      if (_lastKeyPress != null && now.difference(_lastKeyPress!).inMilliseconds > scannerThreshold) {
        _currentBarcode = '';
      }
      _lastKeyPress = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_currentBarcode.isNotEmpty) {
          _barcodeStreamController.add(_currentBarcode);
          _currentBarcode = '';
        }
        return true;
      }

      if (event.character != null) {
        _currentBarcode += event.character!;
      }
    }
    return false;
  }
}