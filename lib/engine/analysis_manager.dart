import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../chess/position_manager.dart';
import '../models/chess_game.dart';
import '../models/move_analysis.dart';
import '../models/game_analysis.dart';
import '../core/config/app_config.dart';
import 'stockfish_controller.dart';
import 'uci_parser.dart';

/// Orchestrates Stockfish analysis of every position in a game.
class AnalysisManager extends ChangeNotifier {
  final StockfishController _engine = StockfishController();
  final PositionManager _positionManager = PositionManager();

  bool _analyzing = false;
  bool get isAnalyzing => _analyzing;

  bool _cancelled = false;

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
    if (_analyzing) return _result;
    _analyzing = true;
    _cancelled = false;
    _error = null;
    _result = null;
    _totalPlies = game.moves.length;
    _currentPly = 0;
    notifyListeners();

    if (game.moves.isEmpty) {
      _analyzing = false;
      _result = const GameAnalysis(
        moves: [],
        whiteAccuracy: 100,
        blackAccuracy: 100,
        whiteClassifications: {},
        blackClassifications: {},
      );
      notifyListeners();
      return _result;
    }

    try {
      await _engine.init();
      if (_cancelled) return null;

      // Send ucinewgame once per game to prepare engine hash
      await _engine.newGame();
      if (_cancelled) return null;

      final startFen = game.headers['FEN'] ??
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      final fens = <String>[startFen, ...game.moves.map((m) => m.fen!)];
      final positionResults = List<AnalysisResult?>.filled(fens.length, null);

      // Analyze start position (ply 0)
      positionResults[0] = await _analyzePosition(fens[0]);
      if (_cancelled) return null;

      final analyses = <MoveAnalysis>[];

      for (int i = 0; i < game.moves.length; i++) {
        if (_cancelled) break;
        await Future.delayed(Duration.zero); // yield for UI responsiveness
        if (_cancelled) break;

        // Position after move i is analyzed once
        positionResults[i + 1] = await _analyzePosition(fens[i + 1]);
        if (_cancelled) break;

        final move = game.moves[i];
        final fenBefore = fens[i];
        final fenAfter = fens[i + 1];
        final isWhite = move.isWhite;
        final resultBefore = positionResults[i]!;
        final resultAfter = positionResults[i + 1]!;

        // Eval before (normalised to White's perspective)
        final evalBeforeData = _scoreToWhitePerspective(resultBefore, isWhite);
        final evalBefore = evalBeforeData.score;
        final isMateBefore = evalBeforeData.isMate;
        final mateBefore = evalBeforeData.mateIn;

        final evalAfterData = _scoreToWhitePerspective(resultAfter, !isWhite);
        final evalAfter = evalAfterData.score;
        final isMateAfter = evalAfterData.isMate;
        final mateAfter = evalAfterData.mateIn;

        // Eval loss (from the mover's perspective, ≥ 0)
        double evalLoss;
        if (isWhite) {
          evalLoss = evalBefore - evalAfter;
        } else {
          evalLoss = evalAfter - evalBefore;
        }
        if (evalLoss < 0) evalLoss = 0;

        // Best move SAN
        _positionManager.load(fenBefore);
        final bestSan = _positionManager.uciToSan(resultBefore.bestMove);

        // Classification
        final classification = _classifyMove(
          evalLoss,
          resultBefore.bestMove,
          move.san,
          fenBefore,
        );

        // PV in SAN
        _positionManager.load(fenBefore);
        final pvSan = <String>[];
        for (final uci in resultBefore.pv.take(5)) {
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
          bestMoveUci: resultBefore.bestMove,
          pv: pvSan,
          evalLoss: evalLoss,
          classification: classification,
        ));

        _currentPly = i + 1;
        notifyListeners();
      }

      if (!_cancelled) {
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
      }

      _analyzing = false;
      notifyListeners();
      return _result;
    } catch (e) {
      if (!_cancelled) {
        _error = e.toString();
      }
      _analyzing = false;
      notifyListeners();
      return null;
    } finally {
      _engine.dispose();
    }
  }

  AnalysisResult _terminalResult(PositionManager pm) {
    if (pm.isCheckmate) {
      return const AnalysisResult(
        bestMove: '',
        lines: [
          UciInfo(
            depth: 0,
            score: -10000,
            mate: 0,
            multiPv: 1,
          ),
        ],
      );
    } else {
      return const AnalysisResult(
        bestMove: '',
        lines: [
          UciInfo(
            depth: 0,
            score: 0,
            mate: null,
            multiPv: 1,
          ),
        ],
      );
    }
  }

  Future<AnalysisResult> _analyzePosition(String fen) async {
    _positionManager.load(fen);
    if (_positionManager.isCheckmate ||
        _positionManager.isStalemate ||
        _positionManager.isGameOver) {
      return _terminalResult(_positionManager);
    }
    return await _engine.analyze(
      fen: fen,
      depth: _depth,
      multiPv: _multiPv,
    );
  }

  _EvalData _scoreToWhitePerspective(AnalysisResult result, bool isWhiteToMove) {
    if (result.scoreMate != null) {
      final mateIn = isWhiteToMove ? result.scoreMate! : -result.scoreMate!;
      final score = result.scoreMate! > 0 ? 10000.0 : -10000.0;
      return _EvalData(
        score: isWhiteToMove ? score : -score,
        isMate: true,
        mateIn: mateIn,
      );
    } else {
      final score = (result.scoreCp ?? 0).toDouble();
      return _EvalData(
        score: isWhiteToMove ? score : -score,
        isMate: false,
        mateIn: null,
      );
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
    _cancelled = true;
    _engine.stop();
    _analyzing = false;
    notifyListeners();
  }
}

class _EvalData {
  final double score;
  final bool isMate;
  final int? mateIn;
  _EvalData({required this.score, required this.isMate, this.mateIn});
}
