import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/printers_hardware/printer/printer_settings.dart';
import '../printer_management/printers_hardware_provider.dart';

class ReceiptSettingsNotifier
    extends AutoDisposeAsyncNotifier<PrinterSettings> {
  @override
  Future<PrinterSettings> build() async {
    return ref.read(printersHardwareRepositoryProvider).getReceiptSettings();
  }

  Future<void> save(PrinterSettings settings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(printersHardwareRepositoryProvider)
          .saveReceiptSettings(settings);
      return settings;
    });
  }
}

final receiptSettingsProvider = AsyncNotifierProvider.autoDispose<
    ReceiptSettingsNotifier, PrinterSettings>(
  ReceiptSettingsNotifier.new,
);
