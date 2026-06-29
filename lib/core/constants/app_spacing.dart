class AppSpacing {
  // ── Core Screen & Component Padding ──
  // Tightened up for mobile screens
  static const double screenPadding = 16.0; // Standard mobile side padding
  static const double cardPadding = 16.0; // Good internal card padding

  // ── Base-4 Vertical/Horizontal Spacing ──
  static const double xs = 4.0; // Tiny gaps (e.g., between icon and text)
  static const double sm =
      8.0; // Small gaps (e.g., between titles and subtitles)
  static const double md = 12.0; // Medium gaps
  static const double lg = 16.0; // Standard layout gap
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // ── Section Spacing ──
  // 👇 FIXED: Drastically reduced these to look normal on a phone
  static const double sectionGap = 24.0; // Replaces the massive 48.0 gap
  static const double sectionGapLg = 32.0; // Replaces the massive 64.0 gap
}
