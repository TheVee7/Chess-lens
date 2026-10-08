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

        final evalBefore = toWhiteCp(resultBefore, isWhite);
        final evalAfter = toWhiteCp(resultAfter, !isWhite);
        final isMateBefore = resultBefore.scoreMate != null;
        final isMateAfter = resultAfter.scoreMate != null;
        final mateBefore = toWhiteMate(resultBefore, isWhite);
        final mateAfter = toWhiteMate(resultAfter, !isWhite);

        // Eval loss (from the mover's perspective, ≥ 0)
        final moverCpBefore = isWhite ? evalBefore : -evalBefore;
        final moverCpAfter = isWhite ? evalAfter : -evalAfter;
        final evalLoss = math.max(0.0, moverCpBefore - moverCpAfter);

        // Best move SAN
        _positionManager.load(fenBefore);
        final bestSan = _positionManager.uciToSan(resultBefore.bestMove);

        // Played move UCI
        final playedUci = move.uci ?? _positionManager.sanToUci(move.san) ?? '';

        // Classification
        final classification = _classifyMove(
          evalLoss,
          resultBefore.bestMove,
          playedUci,
          resultBefore,
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
          engineTimedOut: resultBefore.partial || resultAfter.partial,
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
          whiteAccuracy: calcAccuracy(whiteMoves),
          blackAccuracy: calcAccuracy(blackMoves),
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

  /// Normalizes engine score from side-to-move perspective to White-perspective centipawns.
  /// Mate-in-N is converted to bounded centipawns: sign * (10000 - |N| * 10), clamped.
  static double toWhiteCp(AnalysisResult r, bool whiteToMove) {
    double moverCp;
    if (r.scoreMate != null) {
      final mate = r.scoreMate!;
      if (mate > 0) {
        // Side to move delivers mate in N
        moverCp = (10000.0 - mate.abs() * 10.0).clamp(9000.0, 10000.0);
      } else if (mate < 0) {
        // Side to move is mated in |N|
        moverCp = -(10000.0 - mate.abs() * 10.0).clamp(9000.0, 10000.0);
      } else {
        // Mate 0 (already checkmated)
        moverCp = -10000.0;
      }
    } else {
      moverCp = (r.scoreCp ?? 0).toDouble().clamp(-10000.0, 10000.0);
    }
    return whiteToMove ? moverCp : -moverCp;
  }

  /// Returns mate-in-N from White's perspective (+N if White mates, -N if Black mates).
  static int? toWhiteMate(AnalysisResult r, bool whiteToMove) {
    if (r.scoreMate == null) return null;
    return whiteToMove ? r.scoreMate : -r.scoreMate!;
  }

  static MoveClassification _classifyMove(
    double evalLoss,
    String bestMoveUci,
    String playedUci,
    AnalysisResult resultBefore,
  ) {
    if (playedUci.isNotEmpty) {
      if (playedUci == bestMoveUci) {
        return MoveClassification.best;
      }

      // Treat as best if matching any top MultiPV line within 10 cp of top line
      if (resultBefore.lines.isNotEmpty) {
        final topLine = resultBefore.lines.first;
        final topScore = topLine.score;
        if (topScore != null) {
          for (final line in resultBefore.lines) {
            if (line.pv.isNotEmpty && line.pv.first == playedUci) {
              if (line.score != null && (topScore - line.score!).abs() <= 10) {
                return MoveClassification.best;
              }
            }
          }
        }
      }
    }

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

  // ── Accuracy (Lichess standard win-% model) ─────────────────
  /// Uses Lichess win-percentage sigmoid and standard accuracy formula:
  ///   acc = 103.1668 * exp(-0.04354 * winDiff) - 3.1669, clamped to [0, 100].
  /// Aggregated per side using arithmetic mean.
  static double calcAccuracy(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return 100.0;
    double total = 0.0;
    for (final m in moves) {
      final moverCpBefore = m.isWhite ? m.evalBefore : -m.evalBefore;
      final moverCpAfter = m.isWhite ? m.evalAfter : -m.evalAfter;
      final winBefore = winPercent(moverCpBefore);
      final winAfter = winPercent(moverCpAfter);
      total += moveAccuracy(winBefore, winAfter);
    }
    return (total / moves.length).clamp(0.0, 100.0);
  }

  static double winPercent(double cpMover) {
    return 50.0 + 50.0 * (2.0 / (1.0 + math.exp(-0.00368208 * cpMover)) - 1.0);
  }

  static double moveAccuracy(double winBefore, double winAfter) {
    final winDiff = math.max(0.0, winBefore - winAfter);
    final acc = 103.1668 * math.exp(-0.04354 * winDiff) - 3.1669;
    return acc.clamp(0.0, 100.0);
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

  @override
  void dispose() {
    cancel();
    _engine.dispose();
    super.dispose();
  }
}
