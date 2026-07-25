import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../printer_management/printers_hardware_provider.dart';

class UsbPrintersNotifier extends AutoDisposeAsyncNotifier<List<PrinterDevice>> {
  @override
  Future<List<PrinterDevice>> build() async {
    return _scanForDevices();
  }

  Future<List<PrinterDevice>> _scanForDevices() async {
    try {
      final repo = ref.read(printersHardwareRepositoryProvider);
      return await repo.scanUsbPrinters();
    } catch (e) {
      throw Exception('USB scan failed: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _scanForDevices());
  }
}

final usbPrintersProvider = AsyncNotifierProvider.autoDispose<UsbPrintersNotifier, List<PrinterDevice>>(
  UsbPrintersNotifier.new,
);