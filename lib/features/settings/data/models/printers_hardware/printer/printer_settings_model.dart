import '../../../../domain/entities/printers_hardware/printer/printer_settings.dart';

class PrinterSettingsModel extends PrinterSettings {
  const PrinterSettingsModel({
    required super.printerId,
    super.isDefault = false,
    super.autoPrintReceipt = true,
    super.printCopies = 1,
    super.showLogo = true,
    super.showGst = true,
    super.footerText = '',
    super.paperSize = 'mm80',
  });

  factory PrinterSettingsModel.fromEntity(PrinterSettings entity) {
    return PrinterSettingsModel(
      printerId: entity.printerId,
      isDefault: entity.isDefault,
      autoPrintReceipt: entity.autoPrintReceipt,
      printCopies: entity.printCopies,
      showLogo: entity.showLogo,
      showGst: entity.showGst,
      footerText: entity.footerText,
      paperSize: entity.paperSize,
    );
  }

  factory PrinterSettingsModel.fromJson(Map<String, dynamic> json) {
    return PrinterSettingsModel(
      printerId: json['printerId']?.toString() ?? '',
      isDefault: _boolFromJson(json['isDefault']) ?? false,
      autoPrintReceipt: _boolFromJson(json['autoPrintReceipt']) ?? true,
      printCopies: _intFromJson(json['printCopies']) ?? 1,
      showLogo: _boolFromJson(json['showLogo']) ?? true,
      showGst: _boolFromJson(json['showGst']) ?? true,
      footerText: json['footerText']?.toString() ?? '',
      paperSize: json['paperSize']?.toString() ?? 'mm80',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'printerId': printerId,
      'isDefault': isDefault,
      'autoPrintReceipt': autoPrintReceipt,
      'printCopies': printCopies,
      'showLogo': showLogo,
      'showGst': showGst,
      'footerText': footerText,
      'paperSize': paperSize,
    };
  }

  @override
  PrinterSettingsModel copyWith({
    String? printerId,
    bool? isDefault,
    bool? autoPrintReceipt,
    int? printCopies,
    bool? showLogo,
    bool? showGst,
    String? footerText,
    String? paperSize,
  }) {
    return PrinterSettingsModel(
      printerId: printerId ?? this.printerId,
      isDefault: isDefault ?? this.isDefault,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      printCopies: printCopies ?? this.printCopies,
      showLogo: showLogo ?? this.showLogo,
      showGst: showGst ?? this.showGst,
      footerText: footerText ?? this.footerText,
      paperSize: paperSize ?? this.paperSize,
    );
  }

  PrinterSettings toEntity() => this;

  static bool? _boolFromJson(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterSettingsModel &&
          runtimeType == other.runtimeType &&
          printerId == other.printerId &&
          isDefault == other.isDefault &&
          autoPrintReceipt == other.autoPrintReceipt &&
          printCopies == other.printCopies &&
          showLogo == other.showLogo &&
          showGst == other.showGst &&
          footerText == other.footerText &&
          paperSize == other.paperSize;

  @override
  int get hashCode =>
      printerId.hashCode ^
      isDefault.hashCode ^
      autoPrintReceipt.hashCode ^
      printCopies.hashCode ^
      showLogo.hashCode ^
      showGst.hashCode ^
      footerText.hashCode ^
      paperSize.hashCode;
}