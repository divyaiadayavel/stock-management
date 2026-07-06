import '../../../../domain/entities/printers_hardware/printer/printer_capability.dart';

class PrinterCapabilityModel extends PrinterCapability {
  const PrinterCapabilityModel({
    super.paperWidthMm = 80,
    super.supports58mm = true,
    super.supports80mm = true,
    super.supportsA4 = false,
    super.supportsLetter = false,
    super.supportsBarcode = true,
    super.supportsQrCode = true,
    super.supportsCashDrawerKick = true,
    super.supportsLogo = false,
    super.supportsImage = false,
    super.supportsPdf = false,
    super.supportsAutoCut = false,
    super.supportsBeep = false,
    super.supportsColor = false,
    super.maxCopies = 1,
  });

  factory PrinterCapabilityModel.fromEntity(PrinterCapability entity) {
    return PrinterCapabilityModel(
      paperWidthMm: entity.paperWidthMm,
      supports58mm: entity.supports58mm,
      supports80mm: entity.supports80mm,
      supportsA4: entity.supportsA4,
      supportsLetter: entity.supportsLetter,
      supportsBarcode: entity.supportsBarcode,
      supportsQrCode: entity.supportsQrCode,
      supportsCashDrawerKick: entity.supportsCashDrawerKick,
      supportsLogo: entity.supportsLogo,
      supportsImage: entity.supportsImage,
      supportsPdf: entity.supportsPdf,
      supportsAutoCut: entity.supportsAutoCut,
      supportsBeep: entity.supportsBeep,
      supportsColor: entity.supportsColor,
      maxCopies: entity.maxCopies,
    );
  }

  factory PrinterCapabilityModel.fromJson(Map<String, dynamic> json) {
    return PrinterCapabilityModel(
      paperWidthMm: (json['paperWidthMm'] as num?)?.toInt() ?? 80,
      supports58mm: _boolFromJson(json['supports58mm']) ?? true,
      supports80mm: _boolFromJson(json['supports80mm']) ?? true,
      supportsA4: _boolFromJson(json['supportsA4']) ?? false,
      supportsLetter: _boolFromJson(json['supportsLetter']) ?? false,
      supportsBarcode: _boolFromJson(json['supportsBarcode']) ?? true,
      supportsQrCode: _boolFromJson(json['supportsQrCode']) ?? true,
      supportsCashDrawerKick: _boolFromJson(json['supportsCashDrawerKick']) ?? true,
      supportsLogo: _boolFromJson(json['supportsLogo']) ?? false,
      supportsImage: _boolFromJson(json['supportsImage']) ?? false,
      supportsPdf: _boolFromJson(json['supportsPdf']) ?? false,
      supportsAutoCut: _boolFromJson(json['supportsAutoCut']) ?? false,
      supportsBeep: _boolFromJson(json['supportsBeep']) ?? false,
      supportsColor: _boolFromJson(json['supportsColor']) ?? false,
      maxCopies: (json['maxCopies'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paperWidthMm': paperWidthMm,
      'supports58mm': supports58mm,
      'supports80mm': supports80mm,
      'supportsA4': supportsA4,
      'supportsLetter': supportsLetter,
      'supportsBarcode': supportsBarcode,
      'supportsQrCode': supportsQrCode,
      'supportsCashDrawerKick': supportsCashDrawerKick,
      'supportsLogo': supportsLogo,
      'supportsImage': supportsImage,
      'supportsPdf': supportsPdf,
      'supportsAutoCut': supportsAutoCut,
      'supportsBeep': supportsBeep,
      'supportsColor': supportsColor,
      'maxCopies': maxCopies,
    };
  }

  @override
  PrinterCapabilityModel copyWith({
    int? paperWidthMm,
    bool? supports58mm,
    bool? supports80mm,
    bool? supportsA4,
    bool? supportsLetter,
    bool? supportsBarcode,
    bool? supportsQrCode,
    bool? supportsCashDrawerKick,
    bool? supportsLogo,
    bool? supportsImage,
    bool? supportsPdf,
    bool? supportsAutoCut,
    bool? supportsBeep,
    bool? supportsColor,
    int? maxCopies,
  }) {
    return PrinterCapabilityModel(
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      supports58mm: supports58mm ?? this.supports58mm,
      supports80mm: supports80mm ?? this.supports80mm,
      supportsA4: supportsA4 ?? this.supportsA4,
      supportsLetter: supportsLetter ?? this.supportsLetter,
      supportsBarcode: supportsBarcode ?? this.supportsBarcode,
      supportsQrCode: supportsQrCode ?? this.supportsQrCode,
      supportsCashDrawerKick: supportsCashDrawerKick ?? this.supportsCashDrawerKick,
      supportsLogo: supportsLogo ?? this.supportsLogo,
      supportsImage: supportsImage ?? this.supportsImage,
      supportsPdf: supportsPdf ?? this.supportsPdf,
      supportsAutoCut: supportsAutoCut ?? this.supportsAutoCut,
      supportsBeep: supportsBeep ?? this.supportsBeep,
      supportsColor: supportsColor ?? this.supportsColor,
      maxCopies: maxCopies ?? this.maxCopies,
    );
  }

  PrinterCapability toEntity() => this;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterCapabilityModel &&
          runtimeType == other.runtimeType &&
          paperWidthMm == other.paperWidthMm &&
          supports58mm == other.supports58mm &&
          supports80mm == other.supports80mm &&
          supportsA4 == other.supportsA4 &&
          supportsLetter == other.supportsLetter &&
          supportsBarcode == other.supportsBarcode &&
          supportsQrCode == other.supportsQrCode &&
          supportsCashDrawerKick == other.supportsCashDrawerKick &&
          supportsLogo == other.supportsLogo &&
          supportsImage == other.supportsImage &&
          supportsPdf == other.supportsPdf &&
          supportsAutoCut == other.supportsAutoCut &&
          supportsBeep == other.supportsBeep &&
          supportsColor == other.supportsColor &&
          maxCopies == other.maxCopies;

  @override
  int get hashCode =>
      paperWidthMm.hashCode ^
      supports58mm.hashCode ^
      supports80mm.hashCode ^
      supportsA4.hashCode ^
      supportsLetter.hashCode ^
      supportsBarcode.hashCode ^
      supportsQrCode.hashCode ^
      supportsCashDrawerKick.hashCode ^
      supportsLogo.hashCode ^
      supportsImage.hashCode ^
      supportsPdf.hashCode ^
      supportsAutoCut.hashCode ^
      supportsBeep.hashCode ^
      supportsColor.hashCode ^
      maxCopies.hashCode;
}