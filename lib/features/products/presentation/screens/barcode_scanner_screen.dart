import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanned = false;
  late final AudioPlayer _player;

  late final MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();

    // ── Camera controller ──────────────────────────────────────────────────
    // DetectionSpeed.normal is faster at first detection than noDuplicates
    // (which deliberately slows re-detection).  We guard against duplicates
    // ourselves with the _isScanned flag instead.
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );

    // ── Audio — pre-load so playback fires instantly ───────────────────────
    // FIX: old code called setSource() (async, not awaited) then resume()
    // which ran before the source was ready.  The correct approach is:
    //   1. Create player
    //   2. setReleaseMode so the audio object is kept after first play
    //   3. Call play() when needed — it internally loads from the cached
    //      source on every call, which is reliable and works first time.
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.stop); // keep loaded; don't release
    // Pre-load the asset into the audio engine NOW so the first play() call
    // is instant (no disk-read latency).
    _player.setSource(AssetSource('sounds/scanner_beep.mp3'));
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Guard: only handle the very first successful scan
    if (_isScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    // Lock immediately so concurrent callbacks are ignored
    setState(() => _isScanned = true);

    // Stop the camera — no more frames needed
    await _scannerController.stop();

    // ── Play beep ──────────────────────────────────────────────────────────
    // FIX: the old code used resume() after setSource(), which requires the
    // player to be in a "paused" state first.  After initState the player is
    // in "stopped/prepared" state, so resume() silently does nothing.
    // Using seek(zero) + resume() works reliably once setSource has settled.
    try {
      await _player.seek(Duration.zero); // rewind to start
      await _player.resume(); // play the pre-loaded source
    } catch (_) {
      // Sound failure must never block navigation — ignore all errors.
    }

    // ── Navigate back immediately ──────────────────────────────────────────
    // FIX: old code awaited a 500 ms delay BEFORE returning, which is why
    // the app felt slow.  We pop straight away; the beep plays in the
    // background while the previous screen is already animating back in.
    if (mounted) {
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Keep the default AppBar so the user can cancel / go back
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // ── Camera feed ──────────────────────────────────────────────────
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),

          // ── Dimmed overlay with transparent cut-out ───────────────────────
          CustomPaint(
            painter: _OverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // ── Corner brackets drawn on top of the cut-out ──────────────────
          const Center(child: _ScannerBrackets()),

          // ── Hint text ────────────────────────────────────────────────────
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode inside the box',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // ── Scanned confirmation flash ────────────────────────────────────
          if (_isScanned)
            const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 80,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay: dark background with a clear rectangle cut-out
// Using CustomPainter is faster than ShapeBorder because it skips
// the inner/outer path difference computation every frame.
// ─────────────────────────────────────────────────────────────────────────────
class _OverlayPainter extends CustomPainter {
  static const double _cutOutSize = 260;
  static const double _radius = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cutOut = Rect.fromCenter(
      center: center,
      width: _cutOutSize,
      height: _cutOutSize,
    );

    final dimPaint = Paint()..color = Colors.black.withOpacity(0.62);

    // Draw the four dark quadrants around the cut-out
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cutOut.top), dimPaint);
    canvas.drawRect(
      Rect.fromLTRB(0, cutOut.top, cutOut.left, cutOut.bottom),
      dimPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(cutOut.right, cutOut.top, size.width, cutOut.bottom),
      dimPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, cutOut.bottom, size.width, size.height),
      dimPaint,
    );

    // Rounded border around the cut-out
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOut, const Radius.circular(_radius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner bracket decorations (purely visual, not recomputed every frame)
// ─────────────────────────────────────────────────────────────────────────────
class _ScannerBrackets extends StatelessWidget {
  const _ScannerBrackets();

  static const double _size = 260;
  static const double _arm = 28;
  static const double _strokeW = 3.5;
  static const Color _color = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(painter: _BracketPainter()),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const a = 28.0; // arm length
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(const Offset(0, a), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(a, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - a, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, a), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - a), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(a, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - a, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - a), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
