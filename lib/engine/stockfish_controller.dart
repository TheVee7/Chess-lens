import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';

import '../core/config/app_config.dart';
import 'uci_parser.dart';

/// Controller for the Stockfish engine via the `stockfish` Flutter plugin.
///
/// Usage:
///   final sf = StockfishController();
///   await sf.init();
///   final info = await sf.analyze(fen: '...', movetime: 300, multiPv: 1);
///   sf.dispose();
/// Exception thrown when the Stockfish engine encounters an error or timeout.
class EngineException implements Exception {
  final String message;
  const EngineException(this.message);

  @override
  String toString() => 'EngineException: $message';
}

/// Abstract interface for a chess analysis engine to facilitate testing and decoupling.
abstract class Engine {
  int get hash;
  set hash(int value);
  int get threads;
  set threads(int value);

  Future<void> init();
  Future<void> newGame();
  Future<void> setOptions({int? hash, int? threads});
  Future<AnalysisResult> analyze({
    required String fen,
    int? depth,
    int? movetime,
    int multiPv = 1,
  });
  void stop();
  void dispose();
}

/// Controller for the Stockfish engine via the `stockfish` Flutter plugin.
///
/// Usage:
///   final sf = StockfishController();
///   await sf.init();
///   final info = await sf.analyze(fen: '...', depth: 18, multiPv: 2);
///   sf.dispose();
class StockfishController implements Engine {
  static Stockfish? _activeStockfish;

  Stockfish? _stockfish;
  StreamSubscription<String>? _subscription;
  bool _ready = false;
  bool _isDisposed = false;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<AnalysisResult>? _analysisCompleter;
  Completer<void>? _stopCompleter;

  bool _cancelled = false;
  int? _currentMultiPv;
  bool _isSearching = false;
  bool _isEngineSearching = false;
  int _currentSearchId = 0;
  Stopwatch? _currentStopwatch;

  int _hash = AppConfig.defaultHashMemory;
  int _threads = AppConfig.defaultCpuThreads;
  int? _currentHash;
  int? _currentThreads;

  StockfishController({int? hash, int? threads})
    : _hash = hash ?? AppConfig.defaultHashMemory,
      _threads = threads ?? AppConfig.defaultCpuThreads;

  @override
  int get hash => _hash;
  @override
  set hash(int value) {
    if (_isSearching) return;
    _hash = value;
  }

  @override
  int get threads => _threads;
  @override
  set threads(int value) {
    if (_isSearching) return;
    _threads = value;
  }

  int get currentSearchId => _currentSearchId;

  final Map<int, UciInfo> _currentInfoLines = {};
  String? _currentBestMove;

  bool get isReady => _ready && _stockfish?.state.value == StockfishState.ready;

  /// Send ucinewgame once and await readyok to reset hash once per game.
  @override
  Future<void> newGame() async {
    if (_stockfish == null || !_ready) return;
    await _stopPreviousSearch();
    _sendStdin('ucinewgame');
    _readyOkCompleter = Completer<void>();
    _sendStdin('isready');
    try {
      await _readyOkCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  Future<void> _stopPreviousSearch() async {
    if (!_isSearching && !_isEngineSearching) return;
    _isSearching = false;
    _sendStdin('stop');
    if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
      try {
        await _stopCompleter!.future.timeout(
          const Duration(milliseconds: 1000),
        );
      } catch (_) {}
    }
    _isEngineSearching = false;

    // Drain and synchronize engine queue with isready -> readyok
    _readyOkCompleter = Completer<void>();
    _sendStdin('isready');
    try {
      await _readyOkCompleter!.future.timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  /// Initialize the Stockfish process.
  @override
  Future<void> init() async {
    _isDisposed = false;
    _ready = false;
    _isSearching = false;
    _currentMultiPv = null;

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
          throw const EngineException(
            'Timed out waiting for uciok from Stockfish',
          );
        },
      );
    } catch (e) {
      dispose();
      if (e is EngineException) rethrow;
      throw EngineException('Failed to initialize UCI engine: $e');
    }

    // Apply Threads, Hash, and MultiPV options after uciok
    try {
      _sendStdin('setoption name Threads value $_threads');
      _currentThreads = _threads;
      _sendStdin('setoption name Hash value $_hash');
      _currentHash = _hash;
      _sendStdin('setoption name MultiPV value 1');
      _currentMultiPv = 1;
    } catch (_) {
      // Handle unsupported options or engine errors safely
    }

    // Ensure engine is ready for commands
    _readyOkCompleter = Completer<void>();
    _sendStdin('isready');
    try {
      await _readyOkCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw const EngineException(
            'Timed out waiting for readyok after init',
          );
        },
      );
    } catch (e) {
      dispose();
      if (e is EngineException) rethrow;
      throw EngineException('Failed waiting for engine readyok: $e');
    }

    _ready = true;
  }

  /// Update engine options (Hash and Threads).
  ///
  /// Changes are not applied if an active search is running to avoid interference.
  @override
  Future<void> setOptions({int? hash, int? threads}) async {
    if (_isSearching) {
      // Ensure configuration changes cannot interfere with an active search
      return;
    }

    if (hash != null) _hash = hash;
    if (threads != null) _threads = threads;

    if (!_ready || _stockfish == null) {
      // Options will be applied when init() runs after uciok
      return;
    }

    bool changed = false;
    if (_currentThreads != _threads) {
      try {
        _sendStdin('setoption name Threads value $_threads');
        _currentThreads = _threads;
        changed = true;
      } catch (_) {}
    }
    if (_currentHash != _hash) {
      try {
        _sendStdin('setoption name Hash value $_hash');
        _currentHash = _hash;
        changed = true;
      } catch (_) {}
    }

    if (changed) {
      _readyOkCompleter = Completer<void>();
      _sendStdin('isready');
      try {
        await _readyOkCompleter!.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {}
    }
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
      if (info != null && info.depth > 0 && _isSearching) {
        if (!info.isBound) {
          _currentInfoLines[info.multiPv] = info;
        } else {
          // Ignore bound lines when an exact score is already present
          final existing = _currentInfoLines[info.multiPv];
          if (existing == null ||
              (existing.isBound && info.depth >= existing.depth)) {
            _currentInfoLines[info.multiPv] = info;
          }
        }
      }
    } else if (trimmed.startsWith('bestmove ') ||
        trimmed.startsWith('bestmove')) {
      final bm = UciParser.parseBestMove(trimmed);
      _isEngineSearching = false;
      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        _stopCompleter!.complete();
      }

      if (_isSearching) {
        _isSearching = false;
        _currentBestMove = bm;
        final elapsed = _currentStopwatch?.elapsedMilliseconds;
        final depthReached = _currentInfoLines.values.fold<int>(
          0,
          (max, line) => math.max(max, line.depth),
        );
        if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
          _analysisCompleter!.complete(
            AnalysisResult(
              bestMove: _currentBestMove ?? '',
              lines: _currentInfoLines.values.toList(),
              partial: false,
              depthReached: depthReached,
              elapsedTimeMs: elapsed,
            ),
          );
        }
      }
    }
  }

  /// Analyze a position. Returns the best info lines for each MultiPV.
  @override
  Future<AnalysisResult> analyze({
    required String fen,
    int? depth,
    int? movetime,
    int multiPv = 1,
  }) async {
    if (_stockfish == null || !_ready) {
      throw const EngineException('Stockfish is not initialized or ready');
    }

    _cancelled = false;
    await _stopPreviousSearch();

    _currentInfoLines.clear();
    _currentBestMove = null;

    if (_cancelled) {
      return const AnalysisResult(bestMove: '', lines: []);
    }

    // Ensure options are in sync before analysis starts
    bool optionsChanged = false;
    if (_currentThreads != _threads) {
      try {
        _sendStdin('setoption name Threads value $_threads');
        _currentThreads = _threads;
        optionsChanged = true;
      } catch (_) {}
    }
    if (_currentHash != _hash) {
      try {
        _sendStdin('setoption name Hash value $_hash');
        _currentHash = _hash;
        optionsChanged = true;
      } catch (_) {}
    }
    if (optionsChanged) {
      _readyOkCompleter = Completer<void>();
      _sendStdin('isready');
      try {
        await _readyOkCompleter!.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {}
    }

    if (_currentMultiPv != multiPv) {
      _sendStdin('setoption name MultiPV value $multiPv');
      _currentMultiPv = multiPv;
      _readyOkCompleter = Completer<void>();
      _sendStdin('isready');
      try {
        await _readyOkCompleter!.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {}
    }
    _sendStdin('position fen $fen');

    _currentSearchId++;
    _isSearching = true;
    _isEngineSearching = true;
    _stopCompleter = Completer<void>();
    _analysisCompleter = Completer<AnalysisResult>();
    _currentStopwatch = Stopwatch()..start();

    final Duration timeoutDuration;
    if (movetime != null) {
      _sendStdin('go movetime $movetime');
      // Watchdog timeout gives engine headroom to terminate search and respond
      timeoutDuration = Duration(milliseconds: math.max(3000, movetime * 3));
    } else {
      final targetDepth = depth ?? AppConfig.defaultEngineDepth;
      _sendStdin('go depth $targetDepth');
      timeoutDuration = Duration(seconds: math.max(10, targetDepth * 3));
    }

    try {
      final result = await _analysisCompleter!.future.timeout(timeoutDuration);
      debugPrint(
        'Stockfish: fen=$fen movetime=$movetime depthReached=${result.depthReached} '
        'elapsed=${result.elapsedTimeMs}ms bestmove=${result.bestMove}',
      );
      return result;
    } on TimeoutException {
      // Watchdog timeout reached: stop engine and collect partial info
      _isSearching = false;
      _sendStdin('stop');

      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        try {
          await _stopCompleter!.future.timeout(
            const Duration(milliseconds: 1000),
          );
        } catch (_) {}
      }
      _isEngineSearching = false;

      // Drain and synchronize engine queue with isready -> readyok
      _readyOkCompleter = Completer<void>();
      _sendStdin('isready');
      try {
        await _readyOkCompleter!.future.timeout(
          const Duration(milliseconds: 1000),
          onTimeout: () {},
        );
      } catch (_) {}

      final elapsed = _currentStopwatch?.elapsedMilliseconds;
      final depthReached = _currentInfoLines.values.fold<int>(
        0,
        (max, line) => math.max(max, line.depth),
      );

      final fallbackMove =
          _currentBestMove ??
          (_currentInfoLines[1]?.pv.isNotEmpty == true
              ? _currentInfoLines[1]!.pv.first
              : '');

      debugPrint(
        'Stockfish timeout: fen=$fen movetime=$movetime depthReached=$depthReached '
        'elapsed=${elapsed}ms bestmove=$fallbackMove (partial)',
      );

      return AnalysisResult(
        bestMove: fallbackMove,
        lines: _currentInfoLines.values.toList(),
        partial: true,
        depthReached: depthReached,
        elapsedTimeMs: elapsed,
      );
    } catch (e) {
      return AnalysisResult(
        bestMove: _currentBestMove ?? '',
        lines: _currentInfoLines.values.toList(),
        partial: true,
        depthReached: _currentInfoLines.values.fold<int>(
          0,
          (max, line) => math.max(max, line.depth),
        ),
        elapsedTimeMs: _currentStopwatch?.elapsedMilliseconds,
      );
    }
  }

  @override
  void stop() {
    _cancelled = true;
    if (_isSearching || _isEngineSearching) {
      _isSearching = false;
      _sendStdin('stop');
    }
    if (_analysisCompleter != null && !_analysisCompleter!.isCompleted) {
      _analysisCompleter!.complete(
        AnalysisResult(
          bestMove: _currentBestMove ?? '',
          lines: _currentInfoLines.values.toList(),
          partial: true,
          depthReached: _currentInfoLines.values.fold<int>(
            0,
            (max, line) => math.max(max, line.depth),
          ),
          elapsedTimeMs: _currentStopwatch?.elapsedMilliseconds,
        ),
      );
    }
  }

  /// Dispose of the engine. Safe to call multiple times without throwing.
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ready = false;
    _isSearching = false;
    _isEngineSearching = false;
    _currentMultiPv = null;
    _currentHash = null;
    _currentThreads = null;

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
  final String bestMove; // UCI best move
  final List<UciInfo> lines; // one per MultiPV line
  final bool partial;
  final int? depthReached;
  final int? elapsedTimeMs;

  const AnalysisResult({
    required this.bestMove,
    required this.lines,
    this.partial = false,
    this.depthReached,
    this.elapsedTimeMs,
  });

  int get actualDepth =>
      depthReached ?? (lines.isNotEmpty ? lines.first.depth : 0);

  /// The top line's centipawn score (from engine / side-to-move perspective).
  int? get scoreCp => lines.isNotEmpty ? lines.first.score : null;

  /// The top line's mate-in-N.
  int? get scoreMate => lines.isNotEmpty ? lines.first.mate : null;

  /// The top principal variation.
  List<String> get pv => lines.isNotEmpty ? lines.first.pv : [];
}
