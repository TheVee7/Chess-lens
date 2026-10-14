import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chess_game.dart';
import '../models/move_analysis.dart';
import '../models/game_analysis.dart';
import '../models/game_explanation.dart';
import '../engine/analysis_manager.dart';
import '../ai/gemini_service.dart';
import '../ai/rule_based_explainer.dart';

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
      return _game?.startFen ??
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    }
    return analysis!.moves[_currentPlyIndex].fenAfter;
  }

  // ── Gemini explanations ─────────────────────────────────────
  final Map<int, MoveExplanation> _explanations = {};
  final Map<int, ExplanationStatus> _explanationStatus = {};
  final Map<int, String> _moveErrors = {};
  final Set<int> _aiExplained = {};
  GameReview? _gameReview;

  Map<int, MoveExplanation> get explanations => _explanations;
  Map<int, ExplanationStatus> get explanationStatus => _explanationStatus;
  Map<int, String> get moveErrors => _moveErrors;
  GameReview? get gameReview => _gameReview;
  bool isAiExplained(int plyIndex) => _aiExplained.contains(plyIndex);

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
    _aiExplained.clear();
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
    generateOfflineExplanations();
  }

  void _onAnalysisUpdate() => notifyListeners();

  /// Generate deterministic rule-based offline explanations for critical moves.
  void generateOfflineExplanations() {
    if (analysis == null) return;
    for (final m in analysis!.criticalMoments) {
      _explanations.putIfAbsent(m.plyIndex, () => RuleBasedExplainer.explain(m));
      _explanationStatus[m.plyIndex] = ExplanationStatus.done;
    }
    _gameReview ??= RuleBasedExplainer.review(analysis!.moves);
    notifyListeners();
  }

  // ── Gemini explanations ─────────────────────────────────────

  /// Collects Stockfish analysis responses and sends everything to Gemini in a single request.
  Future<void> startGeminiAnalysis(String apiKey) async {
    if (analysis == null || _geminiRunning) return;

    _geminiRunning = true;
    _geminiError = null;
    _isInvalidKey = false;
    notifyListeners();

    final gemini = GeminiService(apiKey: apiKey);

    // Collect top important moves by evalLoss from Stockfish analysis
    final criticalMoves = List<MoveAnalysis>.from(analysis!.criticalMoments)
      ..sort((a, b) => b.evalLoss.compareTo(a.evalLoss));
    final importantMoves = criticalMoves.take(15).toList()
      ..sort((a, b) => a.plyIndex.compareTo(b.plyIndex));

    // Send the whole thing to Gemini API in a single request
    final result = await gemini.explainBatchResult(
      importantMoves,
      reviewMoves: importantMoves,
    );

    switch (result) {
      case Success(:final data):
        for (final m in importantMoves) {
          final explanation = data.moves[m.plyIndex];
          if (explanation != null) {
            _explanations[m.plyIndex] = explanation;
            _aiExplained.add(m.plyIndex);
            _explanationStatus[m.plyIndex] = ExplanationStatus.done;
            _moveErrors.remove(m.plyIndex);
          } else if (!_explanations.containsKey(m.plyIndex)) {
            _explanationStatus[m.plyIndex] = ExplanationStatus.failed;
            _moveErrors[m.plyIndex] = 'Move explanation missing from response';
          }
        }
        if (data.review != null) {
          _gameReview = data.review;
        }
      case Failure(:final error):
        for (final m in importantMoves) {
          if (!_explanations.containsKey(m.plyIndex)) {
            _explanationStatus[m.plyIndex] = ExplanationStatus.failed;
            _moveErrors[m.plyIndex] = error.description;
          }
        }
        _geminiError = error.description;
        if (error.type == GeminiErrorType.invalidKey) {
          _isInvalidKey = true;
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
        _aiExplained.add(move.plyIndex);
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

  @override
  void dispose() {
    analysisManager.dispose();
    super.dispose();
  }
}
