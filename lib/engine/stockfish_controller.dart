import 'dart:async';
import 'package:flutter_stockfish_plugin/stockfish.dart';
import 'uci_parser.dart';

/// Controller for the Stockfish engine via the `stockfish` Flutter plugin.
///
/// Usage:
///   final sf = StockfishController();
///   await sf.init();
///   final info = await sf.analyze(fen: '...', depth: 18, multiPv: 2);
///   sf.dispose();
class StockfishController {
  Stockfish? _stockfish;
  StreamSubscription<String>? _subscription;
  bool _ready = false;

  bool get isReady => _ready;

  /// Initialize the Stockfish process.
  Future<void> init() async {
    _stockfish = Stockfish();
    final completer = Completer<void>();

    _subscription = _stockfish!.stdout.listen((line) {
      if (line.contains('uciok') || line.contains('Stockfish')) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    _stockfish!.stdin = 'uci';

    // Wait for `uciok`, with a timeout.
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // If we don't get uciok, still try to continue.
      },
    );

    _stockfish!.stdin = 'isready';
    await _waitForReadyOk();
    _ready = true;
  }

  /// Analyze a position. Returns the best info lines for each MultiPV.
  Future<AnalysisResult> analyze({
    required String fen,
    int depth = 18,
    int multiPv = 2,
  }) async {
    if (_stockfish == null) throw StateError('Stockfish not initialized');

    _stockfish!.stdin = 'stop';
    await Future.delayed(const Duration(milliseconds: 50));
    _stockfish!.stdin = 'ucinewgame';
    _stockfish!.stdin = 'isready';
    await _waitForReadyOk();

    _stockfish!.stdin = 'setoption name MultiPV value $multiPv';
    _stockfish!.stdin = 'position fen $fen';

    final completer = Completer<AnalysisResult>();
    final infoLines = <int, UciInfo>{}; // multiPv → best info
    String? bestMove;

    // Cancel any previous listener.
    await _subscription?.cancel();
    _subscription = _stockfish!.stdout.listen((line) {
      final info = UciParser.parseInfoLine(line);
      if (info != null && info.depth > 0) {
        final existing = infoLines[info.multiPv];
        if (existing == null || info.depth > existing.depth) {
          infoLines[info.multiPv] = info;
        }
      }

      final bm = UciParser.parseBestMove(line);
      if (bm != null) {
        bestMove = bm;
        if (!completer.isCompleted) {
          completer.complete(AnalysisResult(
            bestMove: bestMove!,
            lines: infoLines.values.toList(),
          ));
        }
      }
    });

    _stockfish!.stdin = 'go depth $depth';

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _stockfish!.stdin = 'stop';
        return AnalysisResult(
          bestMove: bestMove ?? '',
          lines: infoLines.values.toList(),
        );
      },
    );
  }

  /// Wait for `readyok`.
  Future<void> _waitForReadyOk() async {
    final c = Completer<void>();
    late StreamSubscription<String> sub;
    sub = _stockfish!.stdout.listen((line) {
      if (line.contains('readyok')) {
        sub.cancel();
        if (!c.isCompleted) c.complete();
      }
    });
    await c.future.timeout(const Duration(seconds: 5), onTimeout: () {
      sub.cancel();
    });
  }

  /// Dispose of the engine.
  void dispose() {
    _subscription?.cancel();
    _stockfish?.dispose();
    _stockfish = null;
    _ready = false;
  }
}

/// Result of a single position analysis.
class AnalysisResult {
  final String bestMove;       // UCI best move
  final List<UciInfo> lines;   // one per MultiPV line

  const AnalysisResult({
    required this.bestMove,
    required this.lines,
  });

  /// The top line's centipawn score (from engine / side-to-move perspective).
  int? get scoreCp => lines.isNotEmpty ? lines.first.score : null;

  /// The top line's mate-in-N.
  int? get scoreMate => lines.isNotEmpty ? lines.first.mate : null;

  /// The top principal variation.
  List<String> get pv => lines.isNotEmpty ? lines.first.pv : [];
}
