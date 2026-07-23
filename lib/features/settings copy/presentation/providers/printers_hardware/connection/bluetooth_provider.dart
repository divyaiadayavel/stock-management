import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../data/services/printers_hardware/management/permission_service.dart';
import '../printer_management/printers_hardware_provider.dart';

/// Thrown when the user denies (or hasn't yet granted) the Bluetooth /
/// Nearby Devices permission.
class BluetoothPermissionDeniedException implements Exception {
  const BluetoothPermissionDeniedException();
}

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
);

class BluetoothPrintersNotifier extends AutoDisposeAsyncNotifier<List<PrinterDevice>> {
  @override
  Future<List<PrinterDevice>> build() async {
    return _scanForDevices();
  }

  Future<List<PrinterDevice>> _scanForDevices() async {
    final granted =
        await ref.read(permissionServiceProvider).requestBluetoothPermissions();
    if (!granted) {
      throw const BluetoothPermissionDeniedException();
    }

    try {
      final repo = ref.read(printersHardwareRepositoryProvider);
      return await repo.scanBluetoothPrinters();
    } catch (e) {
      throw Exception('Bluetooth scan failed: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _scanForDevices());
  }
}

final bluetoothPrintersProvider =
    AsyncNotifierProvider.autoDispose<BluetoothPrintersNotifier, List<PrinterDevice>>(
  BluetoothPrintersNotifier.new,
);