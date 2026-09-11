import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../data/services/printers_hardware/management/permission_service.dart';
import '../printer_management/printers_hardware_provider.dart';

class WifiPermissionDeniedException implements Exception {
  const WifiPermissionDeniedException();

  @override
  String toString() =>
      'Location permission is needed to scan the Wi-Fi network.';
}

final wifiPermissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
);

class WifiPrintersNotifier extends AutoDisposeAsyncNotifier<List<PrinterDevice>> {
  @override
  Future<List<PrinterDevice>> build() async {
    return _scanForDevices();
  }

  Future<List<PrinterDevice>> _scanForDevices() async {
    final granted =
        await ref.read(wifiPermissionServiceProvider).requestWifiScanPermissions();
    if (!granted) {
      throw const WifiPermissionDeniedException();
    }

    try {
      final repo = ref.read(printersHardwareRepositoryProvider);
      return await repo.scanWifiPrinters();
    } catch (e) {
      throw Exception('WiFi network scan failed: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _scanForDevices());
  }
}

final wifiPrintersProvider = AsyncNotifierProvider.autoDispose<WifiPrintersNotifier, List<PrinterDevice>>(
  WifiPrintersNotifier.new,
);
