import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_lens/widgets/chess_board/chess_board_widget.dart';

void main() {
  const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  group('ChessBoardWidget Tests', () {
    for (final size in [const Size(320, 568), const Size(411, 891)]) {
      testWidgets('pumps cleanly at ${size.width}x${size.height} (unflipped, last move & arrow)',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChessBoardWidget(
                fen: initialFen,
                flipped: false,
                lastMoveFrom: 'e2',
                lastMoveTo: 'e4',
                bestMoveFrom: 'e7',
                bestMoveTo: 'e5',
                showBestMoveArrow: true,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ChessBoardWidget), findsOneWidget);
      });

      testWidgets('pumps cleanly at ${size.width}x${size.height} (flipped)',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChessBoardWidget(
                fen: initialFen,
                flipped: true,
                lastMoveFrom: 'd2',
                lastMoveTo: 'd4',
                bestMoveFrom: 'd7',
                bestMoveTo: 'd5',
                showBestMoveArrow: true,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ChessBoardWidget), findsOneWidget);
      });
    }
  });
}
