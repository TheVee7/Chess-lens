import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../chess/position_manager.dart';
import '../models/chess_game.dart';
import '../models/move_analysis.dart';
import '../models/game_analysis.dart';
import '../core/config/app_config.dart';
import 'stockfish_controller.dart';

/// Orchestrates Stockfish analysis of every position in a game.
class AnalysisManager extends ChangeNotifier {
  final StockfishController _engine = StockfishController();
  final PositionManager _positionManager = PositionManager();

  bool _analyzing = false;
  bool get isAnalyzing => _analyzing;

  int _currentPly = 0;
  int get currentPly => _currentPly;

  int _totalPlies = 0;
  int get totalPlies => _totalPlies;

  double get progress =>
      _totalPlies > 0 ? _currentPly / _totalPlies : 0;

  GameAnalysis? _result;
  GameAnalysis? get result => _result;

  String? _error;
  String? get error => _error;

  int _depth = AppConfig.defaultEngineDepth;
  int _multiPv = AppConfig.defaultMultiPV;

  set depth(int v) => _depth = v;
  set multiPv(int v) => _multiPv = v;

  /// Analyze the full game. Notifies listeners with progress.
  Future<GameAnalysis?> analyzeGame(ChessGame game) async {
    _analyzing = true;
    _error = null;
    _result = null;
    _totalPlies = game.moves.length;
    _currentPly = 0;
    notifyListeners();

    try {
      await _engine.init();

      final analyses = <MoveAnalysis>[];

      // We need the FEN *before* each move. Start from the initial position.
      String previousFen =
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

      for (int i = 0; i < game.moves.length; i++) {
        final move = game.moves[i];
        final fenBefore = previousFen;
        final fenAfter = move.fen!;

        // Analyze the position BEFORE the move.
        final result = await _engine.analyze(
          fen: fenBefore,
          depth: _depth,
          multiPv: _multiPv,
        );

        final isWhite = move.isWhite;

        // --- Eval before (normalised to White's perspective) ---
        double evalBefore;
        bool isMateBefore = false;
        int? mateBefore;
        if (result.scoreMate != null) {
          isMateBefore = true;
          mateBefore = isWhite ? result.scoreMate! : -result.scoreMate!;
          evalBefore = result.scoreMate! > 0 ? 10000.0 : -10000.0;
          if (!isWhite) evalBefore = -evalBefore;
        } else {
          evalBefore = (result.scoreCp ?? 0).toDouble();
          if (!isWhite) evalBefore = -evalBefore;
        }

        // --- Eval after (analyse the resulting position) ---
        final afterResult = await _engine.analyze(
          fen: fenAfter,
          depth: _depth,
          multiPv: 1,
        );

        double evalAfter;
        bool isMateAfter = false;
        int? mateAfter;
        final afterIsWhite = !isWhite;
        if (afterResult.scoreMate != null) {
          isMateAfter = true;
          mateAfter =
              afterIsWhite ? afterResult.scoreMate! : -afterResult.scoreMate!;
          evalAfter = afterResult.scoreMate! > 0 ? 10000.0 : -10000.0;
          if (!afterIsWhite) evalAfter = -evalAfter;
        } else {
          evalAfter = (afterResult.scoreCp ?? 0).toDouble();
          if (!afterIsWhite) evalAfter = -evalAfter;
        }

        // --- Eval loss (from the mover's perspective, ≥ 0) ---
        double evalLoss;
        if (isWhite) {
          evalLoss = evalBefore - evalAfter;
        } else {
          evalLoss = evalAfter - evalBefore;
        }
        if (evalLoss < 0) evalLoss = 0;

        // --- Best move SAN ---
        _positionManager.load(fenBefore);
        final bestSan = _positionManager.uciToSan(result.bestMove);

        // --- Classification ---
        final classification = _classifyMove(
          evalLoss,
          result.bestMove,
          move.san,
          fenBefore,
        );

        // --- PV in SAN ---
        _positionManager.load(fenBefore);
        final pvSan = <String>[];
        for (final uci in result.pv.take(5)) {
          final san = _positionManager.uciToSan(uci);
          if (san != null) {
            pvSan.add(san);
            _positionManager.makeMoveUci(uci);
          } else {
            break;
          }
        }

        analyses.add(MoveAnalysis(
          plyIndex: move.plyIndex,
          moveNumber: move.moveNumber,
          isWhite: isWhite,
          san: move.san,
          fenBefore: fenBefore,
          fenAfter: fenAfter,
          evalBefore: evalBefore,
          evalAfter: evalAfter,
          isMateBefore: isMateBefore,
          isMateAfter: isMateAfter,
          mateBefore: mateBefore,
          mateAfter: mateAfter,
          bestMoveSan: bestSan,
          bestMoveUci: result.bestMove,
          pv: pvSan,
          evalLoss: evalLoss,
          classification: classification,
        ));

        previousFen = fenAfter;
        _currentPly = i + 1;
        notifyListeners();
      }

      // ── Aggregates ──────────────────────────────────────────
      final whiteMoves = analyses.where((m) => m.isWhite).toList();
      final blackMoves = analyses.where((m) => !m.isWhite).toList();

      _result = GameAnalysis(
        moves: analyses,
        whiteAccuracy: _calcAccuracy(whiteMoves),
        blackAccuracy: _calcAccuracy(blackMoves),
        whiteClassifications: _countClassifications(whiteMoves),
        blackClassifications: _countClassifications(blackMoves),
      );

      _analyzing = false;
      notifyListeners();
      return _result;
    } catch (e) {
      _error = e.toString();
      _analyzing = false;
      notifyListeners();
      return null;
    } finally {
      _engine.dispose();
    }
  }

  MoveClassification _classifyMove(
    double evalLoss,
    String bestMoveUci,
    String playedSan,
    String fen,
  ) {
    _positionManager.load(fen);
    final bestSan = _positionManager.uciToSan(bestMoveUci);
    if (bestSan == playedSan) return MoveClassification.best;

    if (evalLoss >= AppConfig.blunderThreshold) {
      return MoveClassification.blunder;
    }
    if (evalLoss >= AppConfig.mistakeThreshold) {
      return MoveClassification.mistake;
    }
    if (evalLoss >= AppConfig.inaccuracyThreshold) {
      return MoveClassification.inaccuracy;
    }
    if (evalLoss <= 10) return MoveClassification.excellent;
    return MoveClassification.good;
  }

  // ── Accuracy (win-% harmonic model) ───────────────────────
  double _calcAccuracy(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return 100;
    double total = 0;
    for (final m in moves) {
      final winBefore = _winPercent(m.evalBefore, m.isWhite);
      final winAfter = _winPercent(m.evalAfter, m.isWhite);
      total += _moveAccuracy(winBefore, winAfter);
    }
    return total / moves.length;
  }

  double _winPercent(double cpWhite, bool isWhite) {
    final cp = isWhite ? cpWhite : -cpWhite;
    return 50 + 50 * (2 / (1 + math.exp(-0.00368208 * cp)) - 1);
  }

  double _moveAccuracy(double winBefore, double winAfter) {
    if (winBefore <= winAfter) return 100;
    final ratio = winAfter / winBefore;
    return (ratio * 100).clamp(0, 100);
  }

  Map<MoveClassification, int> _countClassifications(
      Iterable<MoveAnalysis> moves) {
    final counts = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };
    for (final m in moves) {
      counts[m.classification] = (counts[m.classification] ?? 0) + 1;
    }
    return counts;
  }

  void cancel() {
    _engine.dispose();
    _analyzing = false;
    notifyListeners();
  }
}
