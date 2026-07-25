import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class EscPosService {
  CapabilityProfile? _profile;

  Future<CapabilityProfile> _getProfile() async {
    return _profile ??= await CapabilityProfile.load();
  }

  Future<Generator> createGenerator({
    required PaperSize paperSize,
  }) async {
    final profile = await _getProfile();
    return Generator(paperSize, profile);
  }

  Future<List<int>> initialize({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.reset();
  }

  Future<List<int>> feed({PaperSize paperSize = PaperSize.mm80, int lines = 1}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.feed(lines);
  }

  Future<List<int>> cut({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.cut();
  }

  Future<List<int>> partialCut({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.cut(mode: PosCutMode.partial);
  }

  Future<List<int>> text(String value, {
    PaperSize paperSize = PaperSize.mm80,
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
  }) async {
    final generator = await createGenerator(paperSize: paperSize);
    final bytes = <int>[];
    bytes.addAll(generator.text(value, styles: styles));
    if (linesAfter > 0) bytes.addAll(generator.feed(linesAfter));
    return bytes;
  }

  Future<List<int>> barcode(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.barcode(Barcode.code128(value.split('')));
  }

  Future<List<int>> qrCode(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.qrcode(value);
  }

  Future<List<int>> image(img.Image image, {PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.image(image);
  }

  List<int> cashDrawerKick() => const [27, 112, 0, 25, 250];
  List<int> buzzer() => const [27, 66, 4, 1];

  Future<List<int>> horizontalRule({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.hr();
  }

  Future<List<int>> reset({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.reset();
  }

  // ----- New helper methods -----
  Future<List<int>> logo({required img.Image logo, PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.image(logo);
  }

  Future<List<int>> table(List<String> columns, List<int> widths,
      {PaperSize paperSize = PaperSize.mm80, PosStyles? styles}) async {
    final generator = await createGenerator(paperSize: paperSize);
    final cols = <PosColumn>[];
    for (var i = 0; i < columns.length; i++) {
      cols.add(PosColumn(
        text: columns[i],
        width: widths[i],
        styles: styles ?? const PosStyles(),
      ));
    }
    return generator.row(cols);
  }

  Future<List<int>> row(List<PosColumn> columns, {PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    return generator.row(columns);
  }

  Future<List<int>> doubleHr({PaperSize paperSize = PaperSize.mm80}) async {
    final generator = await createGenerator(paperSize: paperSize);
    final bytes = generator.hr() + generator.hr();
    return bytes;
  }

  // Renamed parameter to 'value'
  Future<List<int>> center(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    return text(value, paperSize: paperSize, styles: const PosStyles(align: PosAlign.center));
  }

  Future<List<int>> left(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    return text(value, paperSize: paperSize, styles: const PosStyles(align: PosAlign.left));
  }

  Future<List<int>> right(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    return text(value, paperSize: paperSize, styles: const PosStyles(align: PosAlign.right));
  }

  Future<List<int>> reverse(String value, {PaperSize paperSize = PaperSize.mm80}) async {
    return text(value, paperSize: paperSize, styles: const PosStyles(reverse: true));
  }
}