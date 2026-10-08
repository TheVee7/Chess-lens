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
/// Exception thrown when the Stockfish engine encounters an error or timeout.
class EngineException implements Exception {
  final String message;
  const EngineException(this.message);

  @override
  String toString() => 'EngineException: $message';
}

/// Controller for the Stockfish engine via the `stockfish` Flutter plugin.
///
/// Usage:
///   final sf = StockfishController();
///   await sf.init();
///   final info = await sf.analyze(fen: '...', depth: 18, multiPv: 2);
///   sf.dispose();
class StockfishController {
  static Stockfish? _activeStockfish;

  Stockfish? _stockfish;
  StreamSubscription<String>? _subscription;
  bool _ready = false;
  bool _isDisposed = false;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<AnalysisResult>? _analysisCompleter;

  bool _cancelled = false;

  final Map<int, UciInfo> _currentInfoLines = {};
  String? _currentBestMove;

  bool get isReady => _ready && _stockfish?.state.value == StockfishState.ready;

  /// Initialize the Stockfish process.
  Future<void> init() async {
    _isDisposed = false;
    _ready = false;

    // Acquire stockfish engine instance asynchronously.
    _stockfish = await _acquireStockfish();
    _activeStockfish = _stockfish;

    // Attach single persistent stdout listener
    _subscription?.cancel();
    _subscription = _stockfish!.stdout.listen(_handleStdout);

    // Initialize UCI protocol
    _uciOkCompleter = Completer<void>();
    _sendStdin('uci');

    try {
      await _uciOkCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const EngineException('Timed out waiting for uciok from Stockfish');
        },
      );
    } catch (e) {
      dispose();
      if (e is EngineException) rethrow;
      throw EngineException('Failed to initialize UCI engine: $e');
    }

    // Ensure engine is ready for commands
    _readyOkCompleter = Completer<void>();
    _sendStdin('isready');
    try {
      await _readyOkCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw const EngineException('Timed out waiting for readyok after init');
        },
      );
    } catch (e) {
      dispose();
      if (e is EngineException) rethrow;
      throw EngineException('Failed waiting for engine readyok: $e');
    }

    _ready = true;
  }

  Future<Stockfish> _acquireStockfish() async {
    try {
      return await stockfishAsync();
    } catch (e) {
      if (e is StateError &&
          (e.message.contains('Only one instance') ||
              e.message.contains('Multiple instances'))) {
        // Dispose active instance if alive and retry once
        await _forceDisposeActive();
        await Future.delayed(const Duration(milliseconds: 150));
        return await stockfishAsync();
      }
      throw EngineException('Failed to start Stockfish process: $e');
    }
  }

  static Future<void> _forceDisposeActive() async {
    final active = _activeStockfish;
    _activeStockfish = null;
    if (active != null) {
      try {
        if (active.state.value == StockfishState.ready) {
          active.dispose();
        }
      } catch (_) {}
    }
  }

  void _sendStdin(String command) {
    final sf = _stockfish;
    if (sf != null && sf.state.value == StockfishState.ready) {
      sf.stdin = command;
    }
  }

  void _handleStdout(String line) {
    final trimmed = line.trim();
    if (trimmed == 'uciok') {
      if (_uciOkCompleter != null && !_uciOkCompleter!.isCompleted) {
        _uciOkCompleter!.complete();
      }
    } else if (trimmed == 'readyok') {
      if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
        _readyOkCompleter!.complete();
      }
    } else if (trimmed.startsWith('info ')) {
      final info = UciParser.parseInfoLine(trimmed);
      if (info != null && info.depth > 0) {
        final existing = _currentInfoLines[info.multiPv];
        if (existing == null || info.depth >= existing.depth) {
          _currentInfoLines[info.multiPv] = info;
        }
      }
    } else if (trimmed.startsWith('bestmove ') || trimmed.startsWith('bestmove')) {
      final bm = UciParser.parseBestMove(trimmed);
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
    if (_stockfish == null || !_ready) {
      throw const EngineException('Stockfish is not initialized or ready');
    }

    _cancelled = false;
    _currentInfoLines.clear();
    _currentBestMove = null;

    _sendStdin('stop');

    _readyOkCompleter = Completer<void>();
    _sendStdin('isready');
    try {
      await _readyOkCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (_) {}

    if (_cancelled) {
      return const AnalysisResult(bestMove: '', lines: []);
    }

    _sendStdin('setoption name MultiPV value $multiPv');
    _sendStdin('position fen $fen');

    _analysisCompleter = Completer<AnalysisResult>();
    _sendStdin('go depth $depth');

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
    _sendStdin('stop');
    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(AnalysisResult(
        bestMove: _currentBestMove ?? '',
        lines: _currentInfoLines.values.toList(),
      ));
    }
  }

  /// Dispose of the engine. Safe to call multiple times without throwing.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ready = false;

    try {
      _subscription?.cancel();
      _subscription = null;
    } catch (_) {}

    final sf = _stockfish;
    _stockfish = null;
    if (identical(_activeStockfish, sf)) {
      _activeStockfish = null;
    }

    if (sf != null) {
      try {
        if (sf.state.value == StockfishState.ready) {
          sf.dispose();
        }
      } catch (_) {
        // Suppress any errors during engine shutdown
      }
    }
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
