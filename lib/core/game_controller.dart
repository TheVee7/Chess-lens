import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chess_game.dart';
import '../models/move_analysis.dart';
import '../models/game_analysis.dart';
import '../models/game_explanation.dart';
import '../engine/analysis_manager.dart';
import '../ai/gemini_service.dart';

/// Status of a Gemini explanation for an important move.
enum ExplanationStatus { waiting, generating, done, failed }

/// Central controller that coordinates the full analysis pipeline:
///   PGN → Stockfish → Quick Report → Gemini explanations → Final review.
class GameController extends ChangeNotifier {
  ChessGame? _game;
  ChessGame? get game => _game;

  final AnalysisManager analysisManager = AnalysisManager();

  GameAnalysis? get analysis => analysisManager.result;

  // ── Current board position ──────────────────────────────────
  int _currentPlyIndex = -1; // -1 = starting position
  int get currentPlyIndex => _currentPlyIndex;

  MoveAnalysis? get currentMoveAnalysis {
    if (analysis == null || _currentPlyIndex < 0) return null;
    if (_currentPlyIndex >= analysis!.moves.length) return null;
    return analysis!.moves[_currentPlyIndex];
  }

  String get currentFen {
    if (analysis == null || _currentPlyIndex < 0) {
      return 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    }
    return analysis!.moves[_currentPlyIndex].fenAfter;
  }

  // ── Gemini explanations ─────────────────────────────────────
  final Map<int, MoveExplanation> _explanations = {};
  final Map<int, ExplanationStatus> _explanationStatus = {};
  GameReview? _gameReview;

  Map<int, MoveExplanation> get explanations => _explanations;
  Map<int, ExplanationStatus> get explanationStatus => _explanationStatus;
  GameReview? get gameReview => _gameReview;

  bool _geminiRunning = false;
  bool get geminiRunning => _geminiRunning;

  String? _geminiError;
  String? get geminiError => _geminiError;

  // ── Load a game ─────────────────────────────────────────────

  void loadGame(ChessGame game) {
    _game = game;
    _currentPlyIndex = -1;
    _explanations.clear();
    _explanationStatus.clear();
    _gameReview = null;
    notifyListeners();
  }

  // ── Navigation ──────────────────────────────────────────────

  void goToMove(int plyIndex) {
    if (analysis == null) return;
    _currentPlyIndex = plyIndex.clamp(-1, analysis!.moves.length - 1);
    notifyListeners();
  }

  void goToStart() => goToMove(-1);

  void goToEnd() {
    if (analysis == null) return;
    goToMove(analysis!.moves.length - 1);
  }

  void nextMove() => goToMove(_currentPlyIndex + 1);

  void previousMove() => goToMove(_currentPlyIndex - 1);

  /// Jump to the next critical moment.
  void nextCriticalMoment() {
    if (analysis == null) return;
    final critical = analysis!.criticalMoments;
    for (final m in critical) {
      if (m.plyIndex > _currentPlyIndex) {
        goToMove(m.plyIndex);
        return;
      }
    }
  }

  /// Jump to the previous critical moment.
  void previousCriticalMoment() {
    if (analysis == null) return;
    final critical = analysis!.criticalMoments.reversed;
    for (final m in critical) {
      if (m.plyIndex < _currentPlyIndex) {
        goToMove(m.plyIndex);
        return;
      }
    }
  }

  // ── Stockfish analysis ──────────────────────────────────────

  Future<void> startAnalysis({int? depth, int? multiPv}) async {
    if (_game == null) return;
    if (depth != null) analysisManager.depth = depth;
    if (multiPv != null) analysisManager.multiPv = multiPv;

    analysisManager.addListener(_onAnalysisUpdate);
    await analysisManager.analyzeGame(_game!);
    analysisManager.removeListener(_onAnalysisUpdate);
  }

  void _onAnalysisUpdate() => notifyListeners();

  // ── Gemini explanations ─────────────────────────────────────

  /// Run Gemini explanations progressively for important moves.
  Future<void> startGeminiAnalysis(String apiKey) async {
    if (analysis == null) return;

    _geminiRunning = true;
    _geminiError = null;
    notifyListeners();

    final gemini = GeminiService(apiKey: apiKey);
    final importantMoves = analysis!.criticalMoments;

    // Mark all as waiting.
    for (final m in importantMoves) {
      _explanationStatus[m.plyIndex] = ExplanationStatus.waiting;
    }
    notifyListeners();

    // Process one by one (progressive).
    for (final m in importantMoves) {
      _explanationStatus[m.plyIndex] = ExplanationStatus.generating;
      notifyListeners();

      final explanation = await gemini.explainMove(m);
      if (explanation != null) {
        _explanations[m.plyIndex] = explanation;
        _explanationStatus[m.plyIndex] = ExplanationStatus.done;
      } else {
        _explanationStatus[m.plyIndex] = ExplanationStatus.failed;
        if (gemini.lastError != null) {
          _geminiError = gemini.lastError;
        }
      }
      notifyListeners();
    }

    // Overall review.
    _gameReview = await gemini.reviewGame(importantMoves);
    if (_gameReview == null && gemini.lastError != null) {
      _geminiError = gemini.lastError;
    }

    _geminiRunning = false;
    notifyListeners();
  }

  /// Retry a single failed explanation.
  Future<void> retryExplanation(String apiKey, MoveAnalysis move) async {
    final gemini = GeminiService(apiKey: apiKey);
    _explanationStatus[move.plyIndex] = ExplanationStatus.generating;
    notifyListeners();

    final explanation = await gemini.explainMove(move);
    if (explanation != null) {
      _explanations[move.plyIndex] = explanation;
      _explanationStatus[move.plyIndex] = ExplanationStatus.done;
    } else {
      _explanationStatus[move.plyIndex] = ExplanationStatus.failed;
      if (gemini.lastError != null) {
        _geminiError = gemini.lastError;
      }
    }
    notifyListeners();
  }

  void cancelAnalysis() {
    analysisManager.cancel();
    notifyListeners();
  }
}
