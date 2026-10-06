import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChessLens design system – colours, typography, and component themes.
class AppTheme {
  AppTheme._();

  // ── Core palette ──────────────────────────────────────────────
  static const Color background      = Color(0xFF0F1117);
  static const Color surface         = Color(0xFF1A1D27);
  static const Color surfaceLight    = Color(0xFF242837);
  static const Color surfaceBorder   = Color(0xFF2E3347);
  static const Color primary         = Color(0xFF6C63FF);
  static const Color primaryLight    = Color(0xFF8B83FF);
  static const Color accent          = Color(0xFF00D9A6);
  static const Color accentDark      = Color(0xFF00B389);
  static const Color textPrimary     = Color(0xFFF0F0F5);
  static const Color textSecondary   = Color(0xFF9DA3B7);
  static const Color textTertiary    = Color(0xFF6B7185);
  static const Color error           = Color(0xFFFF6B6B);
  static const Color warning         = Color(0xFFFFBB5C);
  static const Color success         = Color(0xFF51CF66);

  // ── Move classification colours ───────────────────────────────
  static const Color bestMove        = Color(0xFF00D9A6);
  static const Color excellent       = Color(0xFF51CF66);
  static const Color good            = Color(0xFF8BC34A);
  static const Color book            = Color(0xFFA0AEC0);
  static const Color inaccuracy      = Color(0xFFFFBB5C);
  static const Color mistake         = Color(0xFFFF8C42);
  static const Color blunder         = Color(0xFFFF6B6B);

  // ── Eval bar ──────────────────────────────────────────────────
  static const Color whiteEval = Color(0xFFF0F0F5);
  static const Color blackEval = Color(0xFF1A1D27);

  // ── Board ─────────────────────────────────────────────────────
  static const Color boardLight  = Color(0xFFE8DECC);
  static const Color boardDark   = Color(0xFF9B7653);
  static const Color boardHighlight = Color(0x4DFFEB3B);
  static const Color bestMoveArrow  = Color(0x9900D9A6);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4E54C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D9A6), Color(0xFF00B389)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1D27), Color(0xFF0F1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Shape / Radius ────────────────────────────────────────────
  static const double radiusSm  = 8;
  static const double radiusMd  = 12;
  static const double radiusLg  = 16;
  static const double radiusXl  = 24;

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: background,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: surfaceBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
