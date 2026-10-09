import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/move_analysis.dart';

/// ChessLens design system – colours, typography, and component themes.
class AppTheme {
  AppTheme._();

  // ── Core palette ──────────────────────────────────────────────
  static const Color background      = Color(0xFF101214);
  static const Color surface         = Color(0xFF181A1D);
  static const Color surfaceLight    = Color(0xFF22252A);
  static const Color surfaceBorder   = Color(0xFF2E3347);
  static const Color primary         = Color(0xFF81B64C);
  static const Color primaryLight    = Color(0xFF9CCC65);
  static const Color accent          = Color(0xFF81B64C);
  static const Color accentDark      = Color(0xFF5D8E35);
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xFFA6A9AF);
  static const Color textTertiary    = Color(0xFF737780);
  static const Color error           = Color(0xFFD9534F);
  static const Color warning         = Color(0xFFF0C15C);
  static const Color success         = Color(0xFF81B64C);

  // ── Move classification colours ───────────────────────────────
  static const Color bestMove        = Color(0xFF81B64C);
  static const Color excellent       = Color(0xFF81B64C);
  static const Color good            = Color(0xFF5D8E35);
  static const Color book            = Color(0xFFA6A9AF);
  static const Color inaccuracy      = Color(0xFFF0C15C);
  static const Color mistake         = Color(0xFFE89B3D);
  static const Color blunder         = Color(0xFFD9534F);

  static Color classificationColor(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return blunder;
      case MoveClassification.mistake:
        return mistake;
      case MoveClassification.inaccuracy:
        return inaccuracy;
      case MoveClassification.best:
        return bestMove;
      case MoveClassification.excellent:
        return excellent;
      case MoveClassification.good:
        return good;
      case MoveClassification.book:
        return book;
      case MoveClassification.forced:
        return textSecondary;
    }
  }

  static String classificationLabel(MoveClassification c) {
    switch (c) {
      case MoveClassification.best:
        return 'BEST';
      case MoveClassification.excellent:
        return 'EXCELLENT';
      case MoveClassification.good:
        return 'GOOD';
      case MoveClassification.book:
        return 'BOOK';
      case MoveClassification.inaccuracy:
        return 'INACCURACY';
      case MoveClassification.mistake:
        return 'MISTAKE';
      case MoveClassification.blunder:
        return 'BLUNDER';
      case MoveClassification.forced:
        return 'FORCED';
    }
  }

  static String? classificationSymbol(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return '??';
      case MoveClassification.mistake:
        return '?';
      case MoveClassification.inaccuracy:
        return '?!';
      case MoveClassification.best:
      case MoveClassification.excellent:
        return '✓';
      default:
        return null;
    }
  }

  static IconData classificationIcon(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return Icons.close_rounded;
      case MoveClassification.mistake:
        return Icons.priority_high_rounded;
      case MoveClassification.inaccuracy:
        return Icons.help_outline_rounded;
      case MoveClassification.best:
      case MoveClassification.excellent:
        return Icons.check_circle_rounded;
      case MoveClassification.good:
        return Icons.check_rounded;
      case MoveClassification.book:
        return Icons.menu_book_rounded;
      case MoveClassification.forced:
        return Icons.arrow_forward_rounded;
    }
  }

  // ── Eval bar ──────────────────────────────────────────────────
  static const Color whiteEval = Color(0xFFFFFFFF);
  static const Color blackEval = Color(0xFF181A1D);

  // ── Board ─────────────────────────────────────────────────────
  static const Color boardLight  = Color(0xFFEBECD0);
  static const Color boardDark   = Color(0xFF739552);
  static const Color boardHighlight = Color(0x4DFFEB3B);
  static const Color bestMoveArrow  = Color(0x9981B64C);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9CCC65), Color(0xFF81B64C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF81B64C), Color(0xFF5D8E35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF181A1D), Color(0xFF101214)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
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
