import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:stock_management/features/dashboard/presentation/screens/main_navigation.dart';
import 'forgot_password_screen.dart';

// ══════════════════════════════════════════════════════════
// 🎬 STOCK LANDSCAPE ANIMATION PAINTER (Color Matched to Primary Blue)
// ══════════════════════════════════════════════════════════

class _LandscapePainter extends CustomPainter {
  final double drift;
  final double cloud;
  final double belt;
  final double scan;
  final double chart;
  final double box;
  final Color primaryColor;

  _LandscapePainter({
    required this.drift,
    required this.cloud,
    required this.belt,
    required this.scan,
    required this.chart,
    required this.box,
    required this.primaryColor,
  });

  final Paint _p = Paint()..isAntiAlias = true;

  void _rect(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color col, {
    double rx = 0,
  }) {
    _p.color = col;
    if (rx > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rx)),
        _p,
      );
    } else {
      c.drawRect(Rect.fromLTWH(x, y, w, h), _p);
    }
  }

  void _circle(Canvas c, double cx, double cy, double r, Color col) {
    _p.color = col;
    c.drawCircle(Offset(cx, cy), r, _p);
  }

  void _drawSky(Canvas c, Size s) {
    // Background matches base blue palette values
    _rect(c, 0, 0, s.width, s.height, primaryColor.withOpacity(0.15));
    _rect(c, 0, 0, s.width, s.height * 0.35, primaryColor.withOpacity(0.25));
  }

  void _drawHills(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;

    final backHill = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.25, h * 0.18, w * 0.55, h * 0.38)
      ..quadraticBezierTo(w * 0.75, h * 0.52, w, h * 0.42)
      ..lineTo(w, h * 0.68)
      ..lineTo(0, h * 0.68)
      ..close();
    _p.color = primaryColor.withOpacity(0.35);
    c.drawPath(backHill, _p);

    final midHill = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.18, h * 0.44, w * 0.42, h * 0.58)
      ..quadraticBezierTo(w * 0.65, h * 0.70, w * 0.85, h * 0.50)
      ..quadraticBezierTo(w * 0.93, h * 0.44, w, h * 0.52)
      ..lineTo(w, h * 0.78)
      ..lineTo(0, h * 0.78)
      ..close();
    _p.color = primaryColor.withOpacity(0.45);
    c.drawPath(midHill, _p);

    final ground = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.3, h * 0.72, w * 0.6, h * 0.76)
      ..quadraticBezierTo(w * 0.8, h * 0.79, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    _p.color = primaryColor.withOpacity(0.55);
    c.drawPath(ground, _p);

    _rect(
      c,
      w * 0.3,
      h * 0.74,
      w * 0.42,
      h * 0.06,
      primaryColor.withOpacity(0.65),
    );
    _rect(c, 0, h * 0.88, w, h * 0.12, primaryColor.withOpacity(0.4));

    _p.color = primaryColor.withOpacity(0.7);
    _p.strokeWidth = 1.5;
    _p.style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final shimX = (cloud * w * 1.2 + i * w / 5) % w;
      c.drawLine(
        Offset(shimX, h * 0.91 + i * 3),
        Offset(shimX + 28, h * 0.91 + i * 3),
        _p,
      );
    }
    _p.style = PaintingStyle.fill;
  }

  void _drawClouds(Canvas c, Size s) {
    void drawCloud(double basePct, double y, double scale) {
      final baseX = (basePct + cloud) % 1.2 - 0.1;
      final cx = baseX * s.width;
      _p.color = Colors.white.withOpacity(0.88);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, y, 52 * scale, 18 * scale),
          Radius.circular(10 * scale),
        ),
        _p,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 8 * scale, y - 9 * scale, 28 * scale, 20 * scale),
          Radius.circular(10 * scale),
        ),
        _p,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 24 * scale, y - 5 * scale, 20 * scale, 18 * scale),
          Radius.circular(8 * scale),
        ),
        _p,
      );
    }

    drawCloud(0.05, s.height * 0.08, 0.9);
    drawCloud(0.38, s.height * 0.05, 0.7);
    drawCloud(0.65, s.height * 0.11, 0.8);
    drawCloud(0.85, s.height * 0.06, 0.6);
  }

  void _drawPallet(Canvas c, Size s) {
    final bx = s.width * 0.10 + drift * 8;
    final by = s.height * 0.12 + math.sin(drift * math.pi * 2) * 6;

    _p.color = Colors.grey.shade400;
    _p.strokeWidth = 1.0;
    _p.style = PaintingStyle.stroke;
    c.drawLine(Offset(bx + 13, by + 34), Offset(bx + 8, by + 50), _p);
    c.drawLine(Offset(bx + 13, by + 34), Offset(bx + 18, by + 50), _p);
    _p.style = PaintingStyle.fill;

    _rect(c, bx, by, 26, 34, primaryColor.withOpacity(0.8), rx: 8);
    _p.color = primaryColor;
    _p.strokeWidth = 2;
    _p.style = PaintingStyle.stroke;
    c.drawLine(Offset(bx, by + 17), Offset(bx + 26, by + 17), _p);
    c.drawLine(Offset(bx + 13, by), Offset(bx + 13, by + 34), _p);
    _p.style = PaintingStyle.fill;

    _rect(c, bx + 4, by + 50, 18, 12, const Color(0xFF966F33), rx: 3);
    _rect(c, bx + 6, by + 52, 14, 8, const Color(0xFFC69C5D), rx: 2);
  }

  void _drawWarehouse(Canvas c, Size s) {
    final wx = s.width * 0.35;
    final wy = s.height * 0.56;
    final ww = s.width * 0.30;
    final wh = s.height * 0.22;

    _rect(c, wx, wy, ww, wh, Colors.white.withOpacity(0.9), rx: 4);
    final roof = Path()
      ..moveTo(wx - 4, wy)
      ..lineTo(wx + ww / 2, wy - wh * 0.28)
      ..lineTo(wx + ww + 4, wy)
      ..close();
    _p.color = primaryColor;
    c.drawPath(roof, _p);

    _rect(
      c,
      wx + ww * 0.38,
      wy + wh * 0.5,
      ww * 0.24,
      wh * 0.5,
      primaryColor,
      rx: 2,
    );
    _rect(
      c,
      wx + ww * 0.08,
      wy + wh * 0.2,
      ww * 0.18,
      wh * 0.22,
      primaryColor.withOpacity(0.2),
      rx: 3,
    );
    _rect(
      c,
      wx + ww * 0.74,
      wy + wh * 0.2,
      ww * 0.18,
      wh * 0.22,
      primaryColor.withOpacity(0.2),
      rx: 3,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'STOCK',
        style: TextStyle(
          fontSize: 7,
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(wx + ww * 0.28, wy + wh * 0.06));
  }

  void _drawScannerTower(Canvas c, Size s, double scanVal) {
    final tx = s.width * 0.75;
    final ty = s.height * 0.52;

    _p.color = primaryColor.withOpacity(0.7);
    _p.strokeWidth = 3;
    _p.style = PaintingStyle.stroke;
    c.drawLine(Offset(tx, ty), Offset(tx, ty + s.height * 0.26), _p);
    _p.style = PaintingStyle.fill;

    c.save();
    c.translate(tx, ty);
    c.rotate(scanVal * 0.5 - 0.25);
    _rect(c, -14, -10, 28, 20, primaryColor, rx: 4);
    _p.color = const Color(0xFF00E676);
    _p.strokeWidth = 1.2;
    _p.style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(-10 + i * 6.0, -6), Offset(-10 + i * 6.0, 6), _p);
    }
    _p.style = PaintingStyle.fill;
    _p.color = const Color(0xFF00E676).withOpacity(0.3 + scanVal * 0.4);
    c.drawRect(Rect.fromLTWH(14, -1, 20, 2), _p);
    c.restore();

    _rect(
      c,
      tx - 8,
      ty + s.height * 0.26,
      16,
      6,
      primaryColor.withOpacity(0.7),
      rx: 2,
    );
  }

  void _drawConveyor(Canvas c, Size s) {
    final bx = s.width * 0.30;
    final by = s.height * 0.78;
    final bw = s.width * 0.42;
    const bh = 10.0;

    _rect(c, bx, by, bw, bh, primaryColor.withOpacity(0.8), rx: 4);
    for (int i = 0; i < 12; i++) {
      final xOff = (belt * bw + i * (bw / 10)) % bw;
      _rect(c, bx + xOff - 2, by + 1, 3, bh - 2, primaryColor.withOpacity(0.5));
    }
    _circle(c, bx + 5, by + bh / 2, 6, primaryColor);
    _circle(c, bx + bw - 5, by + bh / 2, 6, primaryColor);

    for (int i = 0; i < 3; i++) {
      final rawX = bx + (belt * bw + i * bw / 3) % bw;
      if (rawX > bx - 5 && rawX < bx + bw - 10) {
        _rect(c, rawX, by - 18, 20, 18, const Color(0xFFE8BE6A), rx: 3);
        _rect(c, rawX + 2, by - 16, 16, 7, const Color(0xFFCC9E40), rx: 1);
        _p.color = const Color(0xFFAA7C20);
        _p.strokeWidth = 0.8;
        _p.style = PaintingStyle.stroke;
        c.drawLine(Offset(rawX + 10, by - 18), Offset(rawX + 10, by - 1), _p);
        _p.style = PaintingStyle.fill;
      }
    }
  }

  void _drawChart(Canvas c, Size s) {
    final cx = s.width * 0.80;
    final cy = s.height * 0.58;
    const cw = 44.0;
    const ch = 32.0;

    _rect(c, cx, cy, cw, ch, Colors.white.withOpacity(0.85), rx: 5);

    final barHeights = [
      0.4 + chart * 0.3,
      0.6 + chart * 0.2,
      0.5 - chart * 0.15,
      0.75 + chart * 0.1,
    ];
    final barColors = [
      primaryColor,
      primaryColor.withOpacity(0.7),
      const Color(0xFFFF9800),
      primaryColor.withOpacity(0.5),
    ];
    for (int i = 0; i < 4; i++) {
      final bh = (ch - 8) * barHeights[i].clamp(0.2, 1.0);
      _rect(c, cx + 4 + i * 10.0, cy + ch - 5 - bh, 7, bh, barColors[i], rx: 2);
    }
    _p.color = const Color(0xFFCCCCCC);
    _p.strokeWidth = 0.5;
    _p.style = PaintingStyle.stroke;
    c.drawLine(
      Offset(cx + 3, cy + ch - 5),
      Offset(cx + cw - 3, cy + ch - 5),
      _p,
    );
    _p.style = PaintingStyle.fill;
  }

  void _drawForklift(Canvas c, Size s) {
    final fx = s.width * 0.88 - drift * s.width * 0.18;
    final fy = s.height * 0.82;

    _rect(c, fx, fy - 22, 36, 22, primaryColor, rx: 4);
    _rect(c, fx + 22, fy - 30, 14, 16, primaryColor.withOpacity(0.7), rx: 3);
    _p.color = Colors.grey.shade700;
    _p.strokeWidth = 2.5;
    _p.style = PaintingStyle.stroke;
    c.drawLine(Offset(fx + 3, fy - 22), Offset(fx + 3, fy - 44), _p);
    c.drawLine(Offset(fx + 9, fy - 22), Offset(fx + 9, fy - 44), _p);
    _p.style = PaintingStyle.fill;
    _rect(c, fx - 12, fy - 36 + drift * 4, 14, 3, Colors.grey.shade600);
    _rect(c, fx - 12, fy - 30 + drift * 4, 14, 3, Colors.grey.shade600);
    _circle(c, fx + 6, fy, 6, Colors.grey.shade900);
    _circle(c, fx + 28, fy, 6, Colors.grey.shade900);
    _circle(c, fx + 6, fy, 2.5, Colors.grey.shade400);
    _circle(c, fx + 28, fy, 2.5, Colors.grey.shade400);
    _rect(
      c,
      fx - 12,
      fy - 50 + drift * 4,
      18,
      15,
      const Color(0xFFE8BE6A),
      rx: 2,
    );
    _rect(
      c,
      fx - 10,
      fy - 48 + drift * 4,
      14,
      6,
      const Color(0xFFCC9E40),
      rx: 1,
    );
  }

  void _drawFloatingIcons(Canvas c, Size s) {
    final qx = s.width * 0.68;
    final qy = s.height * 0.30 + math.sin(box * math.pi * 2) * 5;
    _rect(c, qx, qy, 16, 16, Colors.white.withOpacity(0.9), rx: 3);
    _p.color = primaryColor;
    _p.strokeWidth = 1.0;
    _p.style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      c.drawLine(
        Offset(qx + 3 + i * 4.0, qy + 4),
        Offset(qx + 3 + i * 4.0, qy + 12),
        _p,
      );
    }
    _p.style = PaintingStyle.fill;
    _rect(c, qx + 3, qy + 3, 4, 4, primaryColor, rx: 1);
    _rect(c, qx + 9, qy + 3, 4, 4, primaryColor, rx: 1);
    _rect(c, qx + 3, qy + 9, 4, 4, primaryColor, rx: 1);
  }

  void _drawRacks(Canvas c, Size s) {
    void rack(double x) {
      final y = s.height * 0.70;
      _rect(c, x, y, 3, s.height * 0.12, primaryColor);
      _rect(c, x - 5, y, 13, 3, primaryColor.withOpacity(0.8));
      _rect(
        c,
        x - 5,
        y + s.height * 0.04,
        13,
        3,
        primaryColor.withOpacity(0.8),
      );
      _rect(
        c,
        x - 5,
        y + s.height * 0.08,
        13,
        3,
        primaryColor.withOpacity(0.8),
      );
    }

    rack(s.width * 0.14);
    rack(s.width * 0.22);
  }

  @override
  void paint(Canvas c, Size s) {
    _drawSky(c, s);
    _drawHills(c, s);
    _drawClouds(c, s);
    _drawPallet(c, s);
    _drawRacks(c, s);
    _drawWarehouse(c, s);
    _drawScannerTower(c, s, scan);
    _drawChart(c, s);
    _drawConveyor(c, s);
    _drawForklift(c, s);
    _drawFloatingIcons(c, s);
  }

  @override
  bool shouldRepaint(_LandscapePainter old) => true;
}

// ══════════════════════════════════════════════════════════
// 🔑  LOGIN SCREEN
// ══════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  bool hidePassword = true;
  bool rememberMe = false;
  bool validateEmailNow = false;
  bool validatePasswordNow = false;
  String storeName = "Catalystack";
  String tagline = "Smart Billing for Modern Stores";
  String? logoPath;

  late AnimationController _driftCtrl;
  late AnimationController _cloudCtrl;
  late AnimationController _beltCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _boxCtrl;

  @override
  void initState() {
    super.initState();
    loadBranding();

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        setState(() => validateEmailNow = true);
        formKey.currentState?.validate();
      }
    });
    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        setState(() => validatePasswordNow = true);
        formKey.currentState?.validate();
      }
    });

    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _beltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _boxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  Future<void> loadBranding() async {
    try {
      final data = await DBHelper.getProfile();
      if (data != null && mounted) {
        setState(() {
          storeName = data['storeName'] ?? "Catalystack";
          tagline = data['tagline'] ?? "Smart Billing for Modern Stores";
          logoPath = data['logoPath'];
        });
      }
    } catch (_) {}
  }

  Future<void> loginUser() async {
    setState(() {
      validateEmailNow = true;
      validatePasswordNow = true;
    });
    if (!formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(emailController.text.trim(), passwordController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      final error =
          ref.read(authControllerProvider).error ?? "Invalid email or password";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    _driftCtrl.dispose();
    _cloudCtrl.dispose();
    _beltCtrl.dispose();
    _scanCtrl.dispose();
    _chartCtrl.dispose();
    _boxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    final bannerHeight = size.height * 0.35;
    const overlapRadius = 36.0;
    const overlapAmount = 40.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ══════════════════════════════════════════
          // LAYER 1 — Blue-themed custom painter asset background
          // ══════════════════════════════════════════
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _driftCtrl,
                _cloudCtrl,
                _beltCtrl,
                _scanCtrl,
                _chartCtrl,
                _boxCtrl,
              ]),
              builder: (_, __) => CustomPaint(
                size: Size(size.width, bannerHeight),
                painter: _LandscapePainter(
                  drift: _driftCtrl.value,
                  cloud: _cloudCtrl.value,
                  belt: _beltCtrl.value,
                  scan: _scanCtrl.value,
                  chart: _chartCtrl.value,
                  box: _boxCtrl.value,
                  primaryColor: AppColors.primary,
                ),
              ),
            ),
          ),

          // ══════════════════════════════════════════
          // LAYER 2 — White baseline sheet mask overlay
          // ══════════════════════════════════════════
          Positioned(
            top: bannerHeight - overlapAmount,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(overlapRadius),
                  topRight: Radius.circular(overlapRadius),
                ),
              ),
            ),
          ),

          // ══════════════════════════════════════════
          // LAYER 3 — Fixed view content box (No Scroll)
          // ══════════════════════════════════════════
          Positioned(
            top: bannerHeight - overlapAmount,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: size.width * 0.06,
                  right: size.width * 0.06,
                  top: R.sp(context, 20),
                  bottom: R.sp(context, 16),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 25,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Branding ──────────────────
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: R.radius(context, 40),
                                    backgroundColor: Colors.blue.shade50,
                                    backgroundImage:
                                        logoPath != null && logoPath!.isNotEmpty
                                        ? FileImage(File(logoPath!))
                                        : null,
                                    child:
                                        (logoPath == null || logoPath!.isEmpty)
                                        ? Icon(
                                            Icons.store,
                                            size: R.icon(context, 36),
                                            color: Colors.blue,
                                          )
                                        : null,
                                  ),
                                  SizedBox(height: R.sp(context, 10)),
                                  Text(
                                    storeName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: R.fs(context, 24),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: R.sp(context, 4)),
                                  Text(
                                    tagline,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: R.fs(context, 13),
                                      color: Colors.black54,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: R.sp(context, 20)),

                            // ── Email ──────────────────────
                            Text(
                              "Email Address",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: R.fs(context, 14),
                              ),
                            ),
                            SizedBox(height: R.sp(context, 6)),
                            TextFormField(
                              controller: emailController,
                              focusNode: emailFocus,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: R.fs(context, 14)),
                              autovalidateMode: validateEmailNow
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email is required";
                                }
                                final emailRegex = RegExp(
                                  r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return "Enter valid email (example@gmail.com)";
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(passwordFocus),
                              decoration: inputDecoration(
                                "Enter your email",
                                Icons.email_outlined,
                              ),
                            ),

                            SizedBox(height: R.sp(context, 14)),

                            // ── Password ───────────────────
                            Text(
                              "Password",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: R.fs(context, 14),
                              ),
                            ),
                            SizedBox(height: R.sp(context, 6)),
                            TextFormField(
                              controller: passwordController,
                              focusNode: passwordFocus,
                              obscureText: hidePassword,
                              style: TextStyle(fontSize: R.fs(context, 14)),
                              autovalidateMode: validatePasswordNow
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password is required";
                                }
                                if (value.length < 6) {
                                  return "Minimum 6 characters required";
                                }
                                return null;
                              },
                              decoration: inputDecoration(
                                "Enter your password",
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: R.icon(context, 20),
                                  ),
                                  onPressed: () => setState(
                                    () => hidePassword = !hidePassword,
                                  ),
                                ),
                              ),
                              onFieldSubmitted: (_) => loginUser(),
                            ),

                            SizedBox(height: R.sp(context, 10)),

                            // ── Remember + Forgot ──────────
                            Row(
                              children: [
                                SizedBox(
                                  height: R.fluid(context, 22, 26),
                                  width: R.fluid(context, 22, 26),
                                  child: Checkbox(
                                    value: rememberMe,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) =>
                                        setState(() => rememberMe = v ?? false),
                                  ),
                                ),
                                SizedBox(width: R.sp(context, 8)),
                                Expanded(
                                  child: Text(
                                    "Remember me",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: R.fs(context, 12),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: R.fluid(context, 6, 10),
                                      vertical: R.fluid(context, 6, 10),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: R.fs(context, 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: R.sp(context, 16)),

                            // ── Login Button ───────────────
                            SizedBox(
                              width: double.infinity,
                              height: R.btnH(context),
                              child: ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      R.radius(context, 14),
                                    ),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "LOGIN",
                                        style: TextStyle(
                                          fontSize: R.fs(context, 16),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      prefixIcon: Icon(icon, color: Colors.black54, size: R.icon(context, 20)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff7f8fa),
      contentPadding: EdgeInsets.symmetric(
        horizontal: R.fluid(context, 14, 18),
        vertical: R.fluid(context, 14, 18),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
