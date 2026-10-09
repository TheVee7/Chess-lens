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
import 'package:chess_lens/screens/analysis/analysis_screen.dart';
import 'package:chess_lens/widgets/coach_review.dart';
import 'package:chess_lens/widgets/move_strip.dart';
import 'package:chess_lens/widgets/analysis_controls.dart';

class StubFullGameController extends GameController {
  final GameAnalysis? stubAnalysis;
  final GameReview? stubReview;
  final Map<int, MoveExplanation> stubExplanations;
  final Map<int, ExplanationStatus> stubStatus;
  final Map<int, String> stubErrors;
  int _stubPly = -1;

  StubFullGameController({
    this.stubAnalysis,
    this.stubReview,
    this.stubExplanations = const {},
    this.stubStatus = const {},
    this.stubErrors = const {},
    int initialPly = -1,
  }) : _stubPly = initialPly;

  @override
  GameAnalysis? get analysis => stubAnalysis;

  @override
  GameReview? get gameReview => stubReview;

  @override
  int get currentPlyIndex => _stubPly;

  @override
  MoveAnalysis? get currentMoveAnalysis {
    if (stubAnalysis == null || _stubPly < 0 || _stubPly >= stubAnalysis!.moves.length) {
      return null;
    }
    return stubAnalysis!.moves[_stubPly];
  }

  @override
  Map<int, MoveExplanation> get explanations => stubExplanations;

  @override
  Map<int, ExplanationStatus> get explanationStatus => stubStatus;

  @override
  Map<int, String> get moveErrors => stubErrors;

  @override
  void goToMove(int plyIndex) {
    if (stubAnalysis == null) return;
    _stubPly = plyIndex.clamp(-1, stubAnalysis!.moves.length - 1);
    notifyListeners();
  }

  @override
  void nextMove() => goToMove(_stubPly + 1);

  @override
  void previousMove() => goToMove(_stubPly - 1);
}

ChessGame _createTestGame() {
  return const ChessGame(
    headers: {
      'White': 'Magnus Carlsen',
      'Black': 'Hikaru Nakamura',
      'Result': '1-0',
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
      GameMove(
        plyIndex: 2,
        moveNumber: 2,
        isWhite: true,
        san: 'f4',
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq f3 0 2',
        uci: 'f2f4',
      ),
    ],
    rawPgn: '1. e4 e5 2. f4 1-0',
  );
}

GameAnalysis _createTestAnalysis() {
  return const GameAnalysis(
    moves: [
      MoveAnalysis(
        plyIndex: 0,
        moveNumber: 1,
        isWhite: true,
        san: 'e4',
        fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        fenAfter: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        evalBefore: 20,
        evalAfter: 25,
        evalLoss: 0,
        classification: MoveClassification.best,
        bestMoveSan: 'e4',
        bestMoveUci: 'e2e4',
      ),
      MoveAnalysis(
        plyIndex: 1,
        moveNumber: 1,
        isWhite: false,
        san: 'e5',
        fenBefore: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        fenAfter: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        evalBefore: 25,
        evalAfter: 20,
        evalLoss: 5,
        classification: MoveClassification.good,
        bestMoveSan: 'c5',
        bestMoveUci: 'c7c5',
      ),
      MoveAnalysis(
        plyIndex: 2,
        moveNumber: 2,
        isWhite: true,
        san: 'f4',
        fenBefore: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        fenAfter: 'rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq f3 0 2',
        evalBefore: 20,
        evalAfter: -160,
        evalLoss: 180,
        classification: MoveClassification.blunder,
        bestMoveSan: 'Nf3',
        bestMoveUci: 'g1f3',
      ),
    ],
    whiteAccuracy: 85.0,
    blackAccuracy: 92.0,
    whiteClassifications: {
      MoveClassification.best: 1,
      MoveClassification.blunder: 1,
    },
    blackClassifications: {
      MoveClassification.good: 1,
    },
  );
}

Widget _wrapAnalysis(Widget screen, {required GameController controller, double textScale = 1.0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ApiKeyManager>(create: (_) => ApiKeyManager()),
      ChangeNotifierProvider<SettingsManager>(create: (_) => SettingsManager()),
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
  final game = _createTestGame();
  final analysis = _createTestAnalysis();

  group('AnalysisScreen Layout Redesign Tests', () {
    const testSizes = [
      Size(320, 568),
      Size(360, 640),
      Size(411, 891),
      Size(891, 411), // Landscape
    ];
    const testScales = [1.0, 1.5];

    for (final size in testSizes) {
      for (final scale in testScales) {
        testWidgets('AnalysisScreen renders cleanly at ${size.width}x${size.height} scale $scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final controller = StubFullGameController(
            stubAnalysis: analysis,
            initialPly: 2, // Blunder move
            stubStatus: {2: ExplanationStatus.done},
            stubExplanations: {
              2: const MoveExplanation(
                moveNumber: 2,
                title: 'Blunder',
                explanation: 'A premature King Gambit push that severely weakens White kingside diagonal.',
                betterMove: '2. Nf3 develops knights and guards e5.',
                lesson: 'Do not weaken the f-pawn when uncastled.',
              ),
            },
          );

          await tester.pumpWidget(_wrapAnalysis(AnalysisScreen(game: game), controller: controller, textScale: scale));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(CoachReviewWidget), findsOneWidget);
          expect(find.byType(MoveStripWidget), findsOneWidget);
          expect(find.byType(AnalysisControls), findsOneWidget);
        });
      }
    }

    testWidgets('Long coach explanation scrolls inside card without overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const longExplanation =
          'This is an exceptionally detailed analysis explaining why 2. f4 is a serious tactical blunder. '
          'Pushing the f-pawn opens the fragile e1-h4 diagonal directly to the White monarch. '
          'Black can immediately respond with 2... exf4 3. Nf3 g5, cementing the pawn wedge, '
          'or play the sharp Falkbeer Countergambit 2... d5 3. exd5 e4! with commanding initiative. '
          'Grandmaster theory advises developing minor pieces before opening flanks.';

      final controller = StubFullGameController(
        stubAnalysis: analysis,
        initialPly: 2,
        stubStatus: {2: ExplanationStatus.done},
        stubExplanations: {
          2: const MoveExplanation(
            moveNumber: 2,
            title: 'Blunder',
            explanation: longExplanation,
            betterMove: '2. Nf3 secures e5 and enables rapid castling kingside.',
            lesson: 'Flank pawn advances before piece development expose the king to devastating tactical shots.',
          ),
        },
      );

      await tester.pumpWidget(_wrapAnalysis(AnalysisScreen(game: game), controller: controller, textScale: 1.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Displays failed coach explanation with retry option cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = StubFullGameController(
        stubAnalysis: analysis,
        initialPly: 2,
        stubStatus: {2: ExplanationStatus.failed},
        stubErrors: {2: 'Rate limit exceeded. Please wait 60 seconds.'},
      );

      await tester.pumpWidget(_wrapAnalysis(AnalysisScreen(game: game), controller: controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Rate limit exceeded. Please wait 60 seconds.'), findsOneWidget);
      expect(find.text('Retry Explanation'), findsOneWidget);
    });

    testWidgets('Coach panel height remains completely stable when stepping between moves', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = StubFullGameController(
        stubAnalysis: analysis,
        initialPly: 0, // Best move (non-critical, no explanation)
        stubStatus: {2: ExplanationStatus.done},
        stubExplanations: {
          2: const MoveExplanation(
            moveNumber: 2,
            title: 'Blunder',
            explanation: 'King Gambit blunder text here.',
            betterMove: '2. Nf3',
            lesson: 'Develop pieces',
          ),
        },
      );

      await tester.pumpWidget(_wrapAnalysis(AnalysisScreen(game: game), controller: controller));
      await tester.pumpAndSettle();

      final coachFinder = find.byType(CoachReviewWidget);
      expect(coachFinder, findsOneWidget);
      final heightNonCritical = tester.getSize(coachFinder).height;

      // Jump to ply 2 (critical blunder move with AI text)
      controller.goToMove(2);
      await tester.pumpAndSettle();

      final heightCritical = tester.getSize(coachFinder).height;

      // Assert height did not change AT ALL!
      expect(heightCritical, equals(heightNonCritical));

      // Jump to start position (ply -1)
      controller.goToMove(-1);
      await tester.pumpAndSettle();

      final heightStart = tester.getSize(coachFinder).height;
      expect(heightStart, equals(heightNonCritical));
    });

    testWidgets('Opens Details bottom sheet containing EnginePanel and MoveList', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = StubFullGameController(
        stubAnalysis: analysis,
        initialPly: 1,
      );

      await tester.pumpWidget(_wrapAnalysis(AnalysisScreen(game: game), controller: controller));
      await tester.pumpAndSettle();

      // Tap Details button in controls
      final detailsButton = find.byIcon(Icons.tune_rounded);
      expect(detailsButton, findsOneWidget);
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      // Bottom sheet is now open
      expect(find.text('Engine & Move Details'), findsOneWidget);
      expect(find.text('Full Move History'), findsOneWidget);
      expect(find.text('Evaluation Trajectory'), findsOneWidget);
    });
  });
}
