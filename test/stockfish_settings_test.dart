import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chess_lens/core/config/app_config.dart';
import 'package:chess_lens/core/config/settings_manager.dart';
import 'package:chess_lens/engine/stockfish_controller.dart';
import 'package:chess_lens/engine/analysis_manager.dart';
import 'package:chess_lens/ai/api_key_manager.dart';
import 'package:chess_lens/screens/settings/settings_screen.dart';
import 'package:chess_lens/models/chess_game.dart';

/// Test engine that records all UCI commands and analyze arguments sent to it.
class RecordingTestEngine implements Engine {
  final List<String> commands = [];
  bool isInitialized = false;
  bool isDisposed = false;
  int searchCount = 0;

  @override
  int hash = AppConfig.defaultHashMemory;

  @override
  int threads = AppConfig.defaultCpuThreads;

  @override
  Future<void> init() async {
    isInitialized = true;
    commands.add('init');
  }

  @override
  Future<void> newGame() async {
    commands.add('ucinewgame');
  }

  @override
  Future<void> setOptions({int? hash, int? threads}) async {
    if (hash != null) {
      this.hash = hash;
      commands.add('setoption name Hash value $hash');
    }
    if (threads != null) {
      this.threads = threads;
      commands.add('setoption name Threads value $threads');
    }
  }

  @override
  Future<AnalysisResult> analyze({
    required String fen,
    int? depth,
    int? movetime,
    int multiPv = 1,
  }) async {
    searchCount++;
    commands.add(
      'analyze: fen=$fen depth=$depth movetime=$movetime multiPv=$multiPv',
    );
    return const AnalysisResult(
      bestMove: 'e2e4',
      lines: [],
      depthReached: 14,
      elapsedTimeMs: 250,
    );
  }

  @override
  void stop() {
    commands.add('stop');
  }

  @override
  void dispose() {
    isDisposed = true;
    commands.add('dispose');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsManager - Defaults and Validation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default values for new installations', () {
      final settings = SettingsManager();
      expect(settings.analysisTimeMs, AppConfig.defaultAnalysisTimeMs);
      expect(settings.analysisTimeMs, 300);
      expect(settings.hashMemory, AppConfig.defaultHashMemory);
      expect(settings.hashMemory, 64);
      expect(AppConfig.hashOptions, contains(64));

      final expectedThreads = Platform.numberOfProcessors < 2 ? 1 : 2;
      expect(settings.cpuThreads, expectedThreads);
      expect(AppConfig.threadOptions, contains(expectedThreads));

      // MultiPV default remains intact
      expect(settings.multiPv, AppConfig.defaultMultiPV);
    });

    test('validates and clamps analysis time within range (100-2000 ms)', () {
      final settings = SettingsManager();

      settings.analysisTimeMs = 50;
      expect(settings.analysisTimeMs, 100);

      settings.analysisTimeMs = 3000;
      expect(settings.analysisTimeMs, 2000);

      settings.analysisTimeMs = 1000;
      expect(settings.analysisTimeMs, 1000);
    });

    test('validates and rejects invalid option values in setters', () {
      final settings = SettingsManager();

      // Hash options are 16, 32, 64, 128
      settings.hashMemory = 999;
      expect(settings.hashMemory, 64);

      settings.hashMemory = 32;
      expect(settings.hashMemory, 32);

      // Thread options are 1, 2, 4
      settings.cpuThreads = 3;
      expect(settings.cpuThreads, settings.cpuThreads);

      settings.cpuThreads = 4;
      expect(settings.cpuThreads, 4);
    });
  });

  group('SettingsManager - Persistence, Migration, and Loading', () {
    test('persists analysisTimeMs across app restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsManager();

      settings.analysisTimeMs = 1000;
      settings.hashMemory = 128;
      settings.cpuThreads = 4;
      await Future<void>.delayed(Duration.zero);

      final reloadedSettings = SettingsManager();
      await reloadedSettings.load();

      expect(reloadedSettings.analysisTimeMs, 1000);
      expect(reloadedSettings.hashMemory, 128);
      expect(reloadedSettings.cpuThreads, 4);
    });

    test(
      'migrates legacy depth settings without breaking existing installations',
      () async {
        // Legacy low depth (<= 8) -> quick preset (100 ms)
        SharedPreferences.setMockInitialValues({'engine_depth': 8});
        final quickSettings = SettingsManager();
        await quickSettings.load();
        expect(quickSettings.analysisTimeMs, 100);

        // Legacy moderate depth (9-14) -> balanced preset (300 ms)
        SharedPreferences.setMockInitialValues({'engine_depth': 12});
        final balancedSettings = SettingsManager();
        await balancedSettings.load();
        expect(balancedSettings.analysisTimeMs, 300);

        // Legacy high depth (>= 15) -> thorough preset (1000 ms)
        SharedPreferences.setMockInitialValues({'engine_depth': 18});
        final thoroughSettings = SettingsManager();
        await thoroughSettings.load();
        expect(thoroughSettings.analysisTimeMs, 1000);
      },
    );

    test(
      'legacy depth does NOT override existing saved analysis_time_ms',
      () async {
        SharedPreferences.setMockInitialValues({
          'analysis_time_ms': 100,
          'engine_depth': 24,
        });

        final settings = SettingsManager();
        await settings.load();

        expect(settings.analysisTimeMs, 100);
      },
    );

    test(
      'safely falls back when stored analysis_time_ms is invalid or corrupted',
      () async {
        SharedPreferences.setMockInitialValues({
          'analysis_time_ms': -500,
          'hash_memory': 256,
          'cpu_threads': -1,
        });

        final settings = SettingsManager();
        await settings.load();

        expect(settings.analysisTimeMs, 300);
        expect(settings.hashMemory, 64);
        final expectedThreads = Platform.numberOfProcessors < 2 ? 1 : 2;
        expect(settings.cpuThreads, expectedThreads);
      },
    );
  });

  group('Stockfish Integration & Analysis Propagation', () {
    test(
      'AnalysisManager propagates movetime to Engine before analysis',
      () async {
        final testEngine = RecordingTestEngine();
        final manager = AnalysisManager(engine: testEngine);

        manager.movetime = 1000;
        manager.hash = 128;
        manager.threads = 4;
        manager.multiPv = 1;

        expect(manager.movetime, 1000);
        expect(manager.hash, 128);
        expect(manager.threads, 4);
        expect(manager.multiPv, 1);
      },
    );

    test(
      'AnalysisManager executes go movetime for full-game analysis',
      () async {
        final testEngine = RecordingTestEngine();
        final manager = AnalysisManager(engine: testEngine);
        manager.movetime = 300;

        final game = ChessGame(
          headers: {
            'Event': 'Test',
            'White': 'White',
            'Black': 'Black',
            'Result': '*',
          },
          rawPgn: '1. e4',
          moves: [
            GameMove(
              plyIndex: 0,
              moveNumber: 1,
              isWhite: true,
              san: 'e4',
              uci: 'e2e4',
              fen:
                  'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
            ),
          ],
        );

        final analysis = await manager.analyzeGame(game);
        expect(analysis, isNotNull);
        expect(
          testEngine.commands.any((cmd) => cmd.contains('movetime=300')),
          isTrue,
        );
        expect(testEngine.commands.contains('init'), isTrue);
        expect(testEngine.commands.contains('ucinewgame'), isTrue);
        expect(testEngine.commands.contains('dispose'), isTrue);
      },
    );

    test(
      'AnalysisResult stores and exposes depthReached and elapsedTimeMs',
      () {
        const result = AnalysisResult(
          bestMove: 'e2e4',
          lines: [],
          depthReached: 16,
          elapsedTimeMs: 295,
        );
        expect(result.depthReached, 16);
        expect(result.elapsedTimeMs, 295);
        expect(result.actualDepth, 16);
        expect(result.partial, isFalse);
      },
    );
  });

  group('SettingsScreen UI', () {
    Widget createSettingsScreen(SettingsManager settings) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ApiKeyManager>(create: (_) => ApiKeyManager()),
          ChangeNotifierProvider<SettingsManager>.value(value: settings),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets(
      'renders Analysis Time per Position with presets and removes Depth',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsManager();
        await settings.load();

        await tester.pumpWidget(createSettingsScreen(settings));
        await tester.pumpAndSettle();

        // Verify section title
        expect(find.text('Engine & Performance'), findsOneWidget);

        // Verify user-facing Depth is removed
        expect(find.text('Engine Depth'), findsNothing);

        // Verify Analysis Time per Position title and explanation
        expect(find.text('Analysis Time per Position'), findsOneWidget);
        expect(
          find.text(
            'Controls how long Stockfish searches each position. Longer searches may improve analysis but take more time.',
          ),
          findsOneWidget,
        );

        // Verify presets
        expect(find.text('Quick'), findsOneWidget);
        expect(find.text('Balanced'), findsOneWidget);
        expect(find.text('Thorough'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);

        // Verify custom dial is initially hidden when preset (Balanced) is active
        expect(find.text('Custom Search Time'), findsNothing);

        // Verify existing MultiPV, Hash Memory, and CPU Threads remain intact
        expect(find.text('MultiPV (Lines)'), findsOneWidget);
        expect(find.text('Hash Memory'), findsOneWidget);
        expect(find.text('CPU Threads'), findsOneWidget);

        // Tap 'Custom' preset and verify the custom dial expands into view
        await tester.ensureVisible(find.text('Custom'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();
        expect(find.text('Custom Search Time'), findsOneWidget);

        // Tap 'Thorough' preset and verify custom dial collapses and time updates to 1000
        await tester.ensureVisible(find.text('Thorough'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thorough'));
        await tester.pumpAndSettle();
        expect(settings.analysisTimeMs, 1000);
        expect(find.text('Custom Search Time'), findsNothing);

        // Tap 'Quick' preset and verify analysisTimeMs is updated to 100 and dial stays hidden
        await tester.ensureVisible(find.text('Quick'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Quick'));
        await tester.pumpAndSettle();
        expect(settings.analysisTimeMs, 100);
        expect(find.text('Custom Search Time'), findsNothing);

        // Tap 'Balanced' preset and verify analysisTimeMs is updated to 300
        await tester.ensureVisible(find.text('Balanced'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Balanced'));
        await tester.pumpAndSettle();
        expect(settings.analysisTimeMs, 300);
        expect(find.text('Custom Search Time'), findsNothing);
      },
    );
  });
}
