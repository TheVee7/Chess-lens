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
  final Map<int, String> _moveErrors = {};
  GameReview? _gameReview;

  Map<int, MoveExplanation> get explanations => _explanations;
  Map<int, ExplanationStatus> get explanationStatus => _explanationStatus;
  Map<int, String> get moveErrors => _moveErrors;
  GameReview? get gameReview => _gameReview;

  bool _geminiRunning = false;
  bool get geminiRunning => _geminiRunning;

  String? _geminiError;
  String? get geminiError => _geminiError;

  bool _isInvalidKey = false;
  bool get isInvalidKey => _isInvalidKey;

  // ── Load a game ─────────────────────────────────────────────

  void loadGame(ChessGame game) {
    _game = game;
    _currentPlyIndex = -1;
    _explanations.clear();
    _explanationStatus.clear();
    _moveErrors.clear();
    _isInvalidKey = false;
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
    if (_geminiRunning) return; // Guard against concurrent runs

    _geminiRunning = true;
    _geminiError = null;
    _isInvalidKey = false;
    notifyListeners();

    final gemini = GeminiService(apiKey: apiKey);

    // Cap total requests (top 15 most critical moves by evalLoss) to protect quotas
    final criticalMoves = List<MoveAnalysis>.from(analysis!.criticalMoments)
      ..sort((a, b) => b.evalLoss.compareTo(a.evalLoss));
    final importantMoves = criticalMoves.take(15).toList()
      ..sort((a, b) => a.plyIndex.compareTo(b.plyIndex));

    // Mark all as waiting
    for (final m in importantMoves) {
      _explanationStatus[m.plyIndex] = ExplanationStatus.waiting;
      _moveErrors.remove(m.plyIndex);
    }
    notifyListeners();

    // Process sequentially with short pacing delays
    for (final m in importantMoves) {
      if (!_geminiRunning) break;

      _explanationStatus[m.plyIndex] = ExplanationStatus.generating;
      notifyListeners();

      final result = await gemini.explainMoveResult(m);
      switch (result) {
        case Success<MoveExplanation>(:final data):
          _explanations[m.plyIndex] = data;
          _explanationStatus[m.plyIndex] = ExplanationStatus.done;
          _moveErrors.remove(m.plyIndex);
        case Failure<MoveExplanation>(:final error):
          _explanationStatus[m.plyIndex] = ExplanationStatus.failed;
          _moveErrors[m.plyIndex] = error.description;
          _geminiError = error.description;
          if (error.type == GeminiErrorType.invalidKey) {
            _isInvalidKey = true;
            // Abort remaining moves immediately on invalid key
            _geminiRunning = false;
            notifyListeners();
            return;
          }
      }
      notifyListeners();

      // Pace calls to protect free-tier rate limits
      await Future.delayed(const Duration(milliseconds: 350));
    }

    if (_geminiRunning && !_isInvalidKey) {
      final reviewResult = await gemini.reviewGameResult(importantMoves);
      switch (reviewResult) {
        case Success<GameReview>(:final data):
          _gameReview = data;
        case Failure<GameReview>(:final error):
          _geminiError = error.description;
      }
    }

    _geminiRunning = false;
    notifyListeners();
  }

  /// Retry a single failed explanation.
  Future<void> retryExplanation(String apiKey, MoveAnalysis move) async {
    if (_isInvalidKey) return;
    final gemini = GeminiService(apiKey: apiKey);
    _explanationStatus[move.plyIndex] = ExplanationStatus.generating;
    notifyListeners();

    final result = await gemini.explainMoveResult(move);
    switch (result) {
      case Success<MoveExplanation>(:final data):
        _explanations[move.plyIndex] = data;
        _explanationStatus[move.plyIndex] = ExplanationStatus.done;
        _moveErrors.remove(move.plyIndex);
      case Failure<MoveExplanation>(:final error):
        _explanationStatus[move.plyIndex] = ExplanationStatus.failed;
        _moveErrors[move.plyIndex] = error.description;
        _geminiError = error.description;
        if (error.type == GeminiErrorType.invalidKey) {
          _isInvalidKey = true;
        }
    }
    notifyListeners();
  }

  void cancelAnalysis() {
    analysisManager.cancel();
    notifyListeners();
  }
}
