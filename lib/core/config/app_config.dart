/// Central configuration constants for ChessLens.
///
/// Keep all configurable URLs and defaults here so they can be
/// changed in a single place.
class AppConfig {
  AppConfig._();

  // ── Gemini ──────────────────────────────────────────────────────
  static const String geminiModel = 'gemini-2.0-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── Tutorial / Help URLs ────────────────────────────────────────
  /// URL of the tutorial video showing how to obtain a Gemini API key.
  static const String geminiTutorialUrl =
      'https://www.youtube.com/watch?v=o8iyrtQyrZM';

  /// Official page to create/manage a Gemini API key.
  static const String geminiApiKeyUrl =
      'https://aistudio.google.com/apikey';

  // ── Stockfish defaults ──────────────────────────────────────────
  static const int defaultEngineDepth = 18;
  static const int defaultMultiPV = 2;
  static const bool defaultShowBestMoveArrow = true;
  static const bool defaultAutoAnalyze = true;

  // ── Move classification thresholds (in centipawns) ──────────────
  /// Evaluation-loss thresholds used to classify a move.
  static const double blunderThreshold = 200;   // cp
  static const double mistakeThreshold = 100;   // cp
  static const double inaccuracyThreshold = 50; // cp

  // ── Gemini importance threshold ─────────────────────────────────
  /// Only positions with eval-loss ≥ this value (cp) are sent to Gemini.
  static const double geminiImportanceThreshold = 40;

  // ── UI ──────────────────────────────────────────────────────────
  static const String appName = 'ChessLens';
}
