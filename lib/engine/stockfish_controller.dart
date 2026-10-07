import 'dart:async';
import 'package:stockfish/stockfish.dart';
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
  
  Completer<void>? _readyCompleter;
  Completer<AnalysisResult>? _analysisCompleter;
  
  bool _cancelled = false;
  
  final Map<int, UciInfo> _currentInfoLines = {};
  String? _currentBestMove;

  bool get isReady => _ready;

  /// Initialize the Stockfish process.
  Future<void> init() async {
    _stockfish = Stockfish();
    
    // Wait for the engine state to be ready
    while (_stockfish!.state.value != StockfishState.ready) {
      if (_stockfish!.state.value == StockfishState.error ||
          _stockfish!.state.value == StockfishState.disposed) {
        throw StateError('Failed to start Stockfish');
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _subscription = _stockfish!.stdout.listen(_handleStdout);

    _readyCompleter = Completer<void>();
    _stockfish!.stdin = 'uci';
    _stockfish!.stdin = 'isready';
    await _readyCompleter!.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    
    _ready = true;
  }

  void _handleStdout(String line) {
    if (line.contains('readyok')) {
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }
    } else if (line.startsWith('info ')) {
      final info = UciParser.parseInfoLine(line);
      if (info != null && info.depth > 0) {
        final existing = _currentInfoLines[info.multiPv];
        if (existing == null || info.depth >= existing.depth) {
          _currentInfoLines[info.multiPv] = info;
        }
      }
    } else if (line.startsWith('bestmove ')) {
      final bm = UciParser.parseBestMove(line);
      if (bm != null) {
        _currentBestMove = bm;
        if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
          _analysisCompleter!.complete(AnalysisResult(
            bestMove: _currentBestMove!,
            lines: _currentInfoLines.values.toList(),
          ));
        }
      }
    }
  }

  /// Analyze a position. Returns the best info lines for each MultiPV.
  Future<AnalysisResult> analyze({
    required String fen,
    int depth = 18,
    int multiPv = 2,
  }) async {
    if (_stockfish == null) throw StateError('Stockfish not initialized');

    _cancelled = false;
    _currentInfoLines.clear();
    _currentBestMove = null;

    _stockfish!.stdin = 'stop';
    
    _readyCompleter = Completer<void>();
    _stockfish!.stdin = 'isready';
    await _readyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () {});
    
    if (_cancelled) {
       return const AnalysisResult(bestMove: '', lines: []);
    }

    _stockfish!.stdin = 'setoption name MultiPV value $multiPv';
    _stockfish!.stdin = 'position fen $fen';
    
    _analysisCompleter = Completer<AnalysisResult>();
    _stockfish!.stdin = 'go depth $depth';

    try {
      return await _analysisCompleter!.future;
    } catch (e) {
      return AnalysisResult(
        bestMove: _currentBestMove ?? '',
        lines: _currentInfoLines.values.toList(),
      );
    }
  }

  void stop() {
    _cancelled = true;
    _stockfish?.stdin = 'stop';
    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(AnalysisResult(
        bestMove: _currentBestMove ?? '',
        lines: _currentInfoLines.values.toList(),
      ));
    }
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
