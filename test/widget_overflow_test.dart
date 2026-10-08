import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chess_lens/ai/api_key_manager.dart';
import 'package:chess_lens/core/config/settings_manager.dart';
import 'package:chess_lens/core/game_controller.dart';
import 'package:chess_lens/core/theme/app_theme.dart';
import 'package:chess_lens/models/chess_game.dart';
import 'package:chess_lens/models/game_analysis.dart';
import 'package:chess_lens/models/game_explanation.dart';
import 'package:chess_lens/models/move_analysis.dart';
import 'package:chess_lens/screens/home/home_screen.dart';
import 'package:chess_lens/screens/pgn_import/pgn_import_screen.dart';
import 'package:chess_lens/screens/quick_report/quick_report_screen.dart';
import 'package:chess_lens/screens/analysis/analysis_screen.dart';
import 'package:chess_lens/screens/summary/summary_screen.dart';
import 'package:chess_lens/screens/settings/settings_screen.dart';

class StubGameController extends GameController {
  final GameAnalysis? stubAnalysis;
  final GameReview? stubReview;

  StubGameController({this.stubAnalysis, this.stubReview});

  @override
  GameAnalysis? get analysis => stubAnalysis;

  @override
  GameReview? get gameReview => stubReview;
}

ChessGame _createSampleGame() {
  return const ChessGame(
    headers: {
      'White': 'Magnus Carlsen',
      'Black': 'Hikaru Nakamura',
      'Result': '1-0',
      'Event': 'World Championship',
    },
    moves: [
      GameMove(
        plyIndex: 0,
        moveNumber: 1,
        isWhite: true,
        san: 'e4',
        fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        uci: 'e2e4',
      ),
      GameMove(
        plyIndex: 1,
        moveNumber: 1,
        isWhite: false,
        san: 'e5',
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        uci: 'e7e5',
      ),
    ],
    rawPgn: '1. e4 e5 1-0',
  );
}

GameAnalysis _createSampleAnalysis() {
  final moves = [
    const MoveAnalysis(
      plyIndex: 0,
      moveNumber: 1,
      isWhite: true,
      san: 'e4',
      fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      fenAfter: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      evalBefore: 20.0,
      evalAfter: 25.0,
      evalLoss: 0.0,
      classification: MoveClassification.best,
      bestMoveSan: 'e4',
      bestMoveUci: 'e2e4',
      pv: ['e4', 'e5', 'Nf3'],
    ),
    const MoveAnalysis(
      plyIndex: 1,
      moveNumber: 1,
      isWhite: false,
      san: 'e5',
      fenBefore: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      fenAfter: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
      evalBefore: 25.0,
      evalAfter: 30.0,
      evalLoss: 5.0,
      classification: MoveClassification.excellent,
      bestMoveSan: 'c5',
      bestMoveUci: 'c7c5',
      pv: ['c5', 'Nf3'],
    ),
  ];

  return GameAnalysis(
    moves: moves,
    whiteAccuracy: 94.2,
    blackAccuracy: 88.6,
    whiteClassifications: {MoveClassification.best: 1},
    blackClassifications: {MoveClassification.excellent: 1},
  );
}

Widget _wrapScreen(Widget screen, {GameController? controller, double textScale = 1.0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ApiKeyManager>(create: (_) => ApiKeyManager()),
      ChangeNotifierProvider<SettingsManager>(create: (_) => SettingsManager()),
      if (controller != null)
        ChangeNotifierProvider<GameController>.value(value: controller),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
        ),
        child: screen,
      ),
    ),
  );
}

void main() {
  final testSizes = [
    const Size(320, 568),
    const Size(360, 640),
    const Size(411, 891),
    const Size(891, 411), // Landscape
  ];

  final textScales = [1.0, 1.5];

  final game = _createSampleGame();
  final analysis = _createSampleAnalysis();
  final review = const GameReview(
    summary: 'A clean opening phase with accurate central development by White.',
    keyLessons: ['Control the center with pawns', 'Develop pieces early'],
  );

  for (final size in testSizes) {
    for (final scale in textScales) {
      final desc = '${size.width.toInt()}x${size.height.toInt()} scale $scale';

      testWidgets('HomeScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapScreen(const HomeScreen(), textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('PgnImportScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapScreen(const PgnImportScreen(), textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('SettingsScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapScreen(const SettingsScreen(), textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('QuickReportScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = StubGameController(stubAnalysis: analysis, stubReview: review);
        await tester.pumpWidget(
          _wrapScreen(
            QuickReportScreen(game: game, controller: controller),
            controller: controller,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('AnalysisScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = StubGameController(stubAnalysis: analysis, stubReview: review);
        await tester.pumpWidget(
          _wrapScreen(
            AnalysisScreen(game: game),
            controller: controller,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('SummaryScreen no overflow at $desc', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = StubGameController(stubAnalysis: analysis, stubReview: review);
        await tester.pumpWidget(
          _wrapScreen(
            SummaryScreen(game: game),
            controller: controller,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
