import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Canvas & Backgrounds ──
  static const Color cream = Color(0xFFFFF9ED);
  static const Color warmCream = Color(0xFFFAF5E8);
  static const Color paperWhite = Color(0xFFFFFBF2);

  // ── Graphic Borders ──
  static const Color ink = Color(0xFF111111);
  static const double borderThin = 2.0;
  static const double borderMed = 3.0;
  static const double borderThick = 4.0;

  // ── Chunky Shadows ──
  static const Offset shadowOffset = Offset(4, 4);
  static const Offset shadowOffsetSm = Offset(3, 3);
  static const Offset shadowOffsetLg = Offset(6, 6);

  // ── Accents ──
  static const Color cyberYellow = Color(0xFFFFF500);
  static const Color hotPink = Color(0xFFFF007A);
  static const Color electricCyan = Color(0xFF00D1FF);
  static const Color vibrantOrange = Color(0xFFFF5C00);

  // ── Supporting ──
  static const Color softPink = Color(0xFFFFC1D0);
  static const Color softYellow = Color(0xFFFFF3B0);
  static const Color softCyan = Color(0xFFB8ECFF);
  static const Color softLavender = Color(0xFFD8C4FF);
  static const Color mutedGreen = Color(0xFFB8E6C8);
  static const Color dimText = Color(0xFF666666);

  // ── Washi Tape Patterns ──
  static const List<Color> washiColors = [
    Color(0xFFFFC1D0), // pink
    Color(0xFFFFF3B0), // yellow
    Color(0xFFB8ECFF), // cyan
    Color(0xFFD8C4FF), // lavender
    Color(0xFFB8E6C8), // green
    Color(0xFFFFD4A8), // peach
  ];

  // ── Fonts ──

  // Editorial display heading (bold serif)
  static TextStyle headingLg = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: ink,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle headingMd = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.5,
  );

  static TextStyle headingSm = GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  // Monospace labels for metrics & metadata
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ink,
    letterSpacing: 0.5,
  );

  static TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: dimText,
    letterSpacing: 0.3,
  );

  static TextStyle monoAccent = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: 0.8,
  );

  // Handwritten / script for annotations
  static TextStyle hand = GoogleFonts.caveat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static TextStyle handLg = GoogleFonts.caveat(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static TextStyle handColor = GoogleFonts.caveat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: hotPink,
  );

  // Body text
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ink,
  );

  static TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  // ── Card Decoration ──
  static BoxDecoration cardDecoration({Color? fillColor, bool isRotated = false}) {
    return BoxDecoration(
      color: fillColor ?? paperWhite,
      border: Border.all(color: ink, width: borderMed),
      boxShadow: [
        BoxShadow(
          color: ink,
          offset: shadowOffset,
        ),
      ],
    );
  }

  static BoxDecoration cardDecorationSmall({Color? fillColor}) {
    return BoxDecoration(
      color: fillColor ?? paperWhite,
      border: Border.all(color: ink, width: borderThin),
      boxShadow: [
        BoxShadow(
          color: ink,
          offset: shadowOffsetSm,
        ),
      ],
    );
  }

  // ── Button Decoration ──
  static BoxDecoration buttonDecoration({Color fillColor = Colors.white}) {
    return BoxDecoration(
      color: fillColor,
      border: Border.all(color: ink, width: borderMed),
      boxShadow: [
        BoxShadow(
          color: ink,
          offset: shadowOffsetSm,
        ),
      ],
    );
  }

  static BoxDecoration accentButtonDecoration(Color accent) {
    return BoxDecoration(
      color: accent,
      border: Border.all(color: ink, width: borderMed),
      boxShadow: [
        BoxShadow(
          color: ink,
          offset: shadowOffsetSm,
        ),
      ],
    );
  }

  // ── Theme Data ──
  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.light(
        primary: ink,
        secondary: hotPink,
        surface: cream,
        onPrimary: cream,
        onSecondary: cream,
        onSurface: ink,
      ),
      textTheme: TextTheme(
        headlineLarge: headingLg,
        headlineMedium: headingMd,
        headlineSmall: headingSm,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: mono,
      ),
    );
  }
}
