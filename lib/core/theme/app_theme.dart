import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/move_analysis.dart';

/// ChessLens design system – tokens, typography, and component themes.
class AppTheme {
  AppTheme._();

  // ── Core color tokens ──────────────────────────────────────────
  static const Color background        = Color(0xFF0B1117);
  static const Color surface           = Color(0xFF121A22);
  static const Color surfaceRaised     = Color(0xFF161F29);
  static const Color border            = Color(0x0FFFFFFF); // rgba(255, 255, 255, 0.06)
  static const Color textPrimary       = Color(0xFFF2F5F8);
  static const Color textSecondary     = Color(0xFF8E9AA8);
  static const Color textDisabled      = Color(0xFF566270);
  static const Color primary           = Color(0xFF61E486);
  static const Color onPrimary         = Color(0xFF0B1117);
  static const Color primaryContainer  = Color(0xFF1B3B2A);

  // ── Move classification tokens ────────────────────────────────
  static const Color brilliant         = Color(0xFF2CC4A8);
  static const Color great             = Color(0xFF5F87F8);
  static const Color best              = Color(0xFF61E486);
  static const Color good              = Color(0xFF93A58A);
  static const Color inaccuracy        = Color(0xFFFBC654);
  static const Color mistake           = Color(0xFFF48C63);
  static const Color blunder           = Color(0xFFF26B73);

  // ── Backward-compatible aliases ───────────────────────────────
  static const Color surfaceLight      = surfaceRaised;
  static const Color surfaceBorder     = border;
  static const Color primaryLight      = primary;
  static const Color accent            = primary;
  static const Color accentDark        = primaryContainer;
  static const Color textTertiary      = textSecondary;
  static const Color error             = blunder;
  static const Color warning           = inaccuracy;
  static const Color success           = best;
  static const Color bestMove          = best;
  static const Color excellent         = great;
  static const Color book              = textSecondary;

  // ── Board colors ──────────────────────────────────────────────
  static const Color boardLight        = Color(0xFFE8ECCB);
  static const Color boardDark         = Color(0xFF739552);
  static const Color boardHighlight    = Color(0x4DFFEB3B);
  static const Color bestMoveArrow     = Color(0x9961E486);

  // ── Evaluation bar colors ─────────────────────────────────────
  static const Color whiteEval         = Color(0xFFEDEFF2);
  static const Color blackEval         = Color(0xFF2A313A);

  // ── Shapes & Geometry ─────────────────────────────────────────
  static const double radiusCard       = 20.0;
  static const double radiusInner      = 14.0;
  static const double radiusButton     = 14.0;
  static const double radiusChip       = 999.0;
  static const double buttonHeight     = 52.0;

  // Spacing grid (8px based)
  static const double screenMargin     = 16.0;
  static const double tileGap          = 12.0;
  static const double tilePadding      = 16.0;

  // Backward-compatible radius tokens
  static const double radiusSm         = 8.0;
  static const double radiusMd         = 14.0;
  static const double radiusLg         = 20.0;
  static const double radiusXl         = 24.0;

  // No gradients on backgrounds or buttons; no heavy shadows
  static List<BoxShadow> get cardShadow => const [];

  // Backward-compatible gradients (kept flat or subtle for unmigrated callers)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, primaryContainer],
  );
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surface],
  );

  // ── Typography helpers ─────────────────────────────────────────
  static TextStyle get titleStyle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 24 / 18,
      );

  static TextStyle get bodyStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 20 / 14,
      );

  static TextStyle get captionStyle => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 16 / 12,
      );

  static TextStyle tabularFigures([TextStyle? base]) {
    final style = base ?? bodyStyle;
    return style.copyWith(
      fontFeatures: [
        ...?style.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  // ── Classification Helpers ─────────────────────────────────────
  static Color classificationColor(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return blunder;
      case MoveClassification.mistake:
        return mistake;
      case MoveClassification.inaccuracy:
        return inaccuracy;
      case MoveClassification.best:
        return best;
      case MoveClassification.excellent:
        return great;
      case MoveClassification.good:
        return good;
      case MoveClassification.book:
        return textSecondary;
      case MoveClassification.forced:
        return textSecondary;
    }
  }

  static String classificationLabel(MoveClassification c) {
    switch (c) {
      case MoveClassification.best:
        return 'BEST';
      case MoveClassification.excellent:
        return 'GREAT';
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
        return Icons.check_circle_rounded;
      case MoveClassification.excellent:
        return Icons.verified_rounded;
      case MoveClassification.good:
        return Icons.check_rounded;
      case MoveClassification.book:
        return Icons.menu_book_rounded;
      case MoveClassification.forced:
        return Icons.arrow_forward_rounded;
    }
  }

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: primary,
        secondary: primary,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: blunder,
        onError: onPrimary,
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceRaised,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          minimumSize: const Size.fromHeight(buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surfaceRaised,
          foregroundColor: textPrimary,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          minimumSize: const Size.fromHeight(buttonHeight),
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          disabledForegroundColor: textDisabled,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceRaised,
        thumbColor: primary,
        overlayColor: primaryContainer.withValues(alpha: 0.3),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInner),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInner),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInner),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusInner),
          side: const BorderSide(color: border, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
