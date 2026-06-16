// responsive_helper.dart
// Drop this file into: lib/core/utils/responsive_helper.dart

import 'package:flutter/material.dart';

/// Breakpoints
/// phone  : < 600
/// tablet : 600 – 1023
/// desktop: >= 1024
class R {
  R._();

  // ─── raw screen values ────────────────────────────────────────────────────
  static double w(BuildContext ctx) => MediaQuery.of(ctx).size.width;
  static double h(BuildContext ctx) => MediaQuery.of(ctx).size.height;

  // ─── device class ─────────────────────────────────────────────────────────
  static bool isPhone(BuildContext ctx) => w(ctx) < 600;
  static bool isTablet(BuildContext ctx) => w(ctx) >= 600 && w(ctx) < 1024;
  static bool isDesktop(BuildContext ctx) => w(ctx) >= 1024;

  // ─── fluid sizing helpers ─────────────────────────────────────────────────
  /// Returns a value that scales linearly between [min] and [max] as the
  /// screen width moves from 320 to 1440.
  static double fluid(
    BuildContext ctx,
    double min,
    double max, {
    double minW = 320,
    double maxW = 1440,
  }) {
    final ratio = ((w(ctx) - minW) / (maxW - minW)).clamp(0.0, 1.0);
    return min + (max - min) * ratio;
  }

  // ─── font sizes ───────────────────────────────────────────────────────────
  static double fs(BuildContext ctx, double base) =>
      fluid(ctx, base, base * 1.35);

  // ─── spacing ──────────────────────────────────────────────────────────────
  static double sp(BuildContext ctx, double base) =>
      fluid(ctx, base, base * 1.5);

  // ─── icon sizes ───────────────────────────────────────────────────────────
  static double icon(BuildContext ctx, double base) =>
      fluid(ctx, base, base * 1.3);

  // ─── horizontal content padding ──────────────────────────────────────────
  /// On wide screens, content is centred with a max-width cap.
  static EdgeInsets hPad(BuildContext ctx, {double base = 16}) {
    if (isDesktop(ctx)) {
      final side = (w(ctx) - 960) / 2;
      return EdgeInsets.symmetric(horizontal: side.clamp(base, 300));
    }
    if (isTablet(ctx)) {
      return EdgeInsets.symmetric(horizontal: sp(ctx, base * 1.5));
    }
    return EdgeInsets.symmetric(horizontal: base);
  }

  // ─── card radius ─────────────────────────────────────────────────────────
  static double radius(BuildContext ctx, double base) =>
      fluid(ctx, base, base * 1.2);

  // ─── grid cross-axis count ───────────────────────────────────────────────
  static int gridCols(
    BuildContext ctx, {
    int phone = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(ctx)) return desktop;
    if (isTablet(ctx)) return tablet;
    return phone;
  }

  // ─── grid child aspect ratio ─────────────────────────────────────────────
  static double gridRatio(
    BuildContext ctx, {
    double phone = 1.8,
    double tablet = 2.0,
    double desktop = 2.2,
  }) {
    if (isDesktop(ctx)) return desktop;
    if (isTablet(ctx)) return tablet;
    return phone;
  }

  // ─── image / avatar sizes ────────────────────────────────────────────────
  static double imgSize(BuildContext ctx, double fraction) {
    // fraction is the phone fraction of screen width (e.g. 0.20)
    return fluid(ctx, w(ctx) * fraction, 140);
  }

  // ─── search bar height ───────────────────────────────────────────────────
  static double searchH(BuildContext ctx) => fluid(ctx, 48, 60);

  // ─── button height ───────────────────────────────────────────────────────
  static double btnH(BuildContext ctx) => fluid(ctx, 50, 64);

  // ─── max content width ───────────────────────────────────────────────────
  static Widget maxW(Widget child, {double max = 960}) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: child,
    ),
  );
}
