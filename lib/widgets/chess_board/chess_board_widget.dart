import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import '../../core/theme/app_theme.dart';

/// A rendered chessboard using chessground with pieces, highlighting, and best-move arrow.
class ChessBoardWidget extends StatelessWidget {
  final String fen;
  final bool flipped;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? bestMoveFrom;
  final String? bestMoveTo;
  final bool showBestMoveArrow;

  static const ChessboardColorScheme _boardColorScheme = ChessboardColorScheme(
    lightSquare: AppTheme.boardLight,
    darkSquare: AppTheme.boardDark,
    background: SolidColorChessboardBackground(
      lightSquare: AppTheme.boardLight,
      darkSquare: AppTheme.boardDark,
    ),
    whiteCoordBackground: SolidColorChessboardBackground(
      lightSquare: AppTheme.boardLight,
      darkSquare: AppTheme.boardDark,
      coordinates: true,
    ),
    blackCoordBackground: SolidColorChessboardBackground(
      lightSquare: AppTheme.boardLight,
      darkSquare: AppTheme.boardDark,
      coordinates: true,
      orientation: Side.black,
    ),
    lastMove: HighlightDetails(solidColor: AppTheme.boardHighlight),
    selected: HighlightDetails(solidColor: Color(0x6014551e)),
    validMoves: Color(0x4014551e),
    validPremoves: Color(0x40203085),
  );

  const ChessBoardWidget({
    super.key,
    required this.fen,
    this.flipped = false,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.bestMoveFrom,
    this.bestMoveTo,
    this.showBestMoveArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    Move? lastMove;
    if (lastMoveFrom != null && lastMoveTo != null) {
      final from = Square.parse(lastMoveFrom!);
      final to = Square.parse(lastMoveTo!);
      if (from != null && to != null) {
        lastMove = NormalMove(from: from, to: to);
      }
    }

    final shapes = <Shape>{};
    if (showBestMoveArrow && bestMoveFrom != null && bestMoveTo != null) {
      final from = Square.parse(bestMoveFrom!);
      final to = Square.parse(bestMoveTo!);
      if (from != null && to != null && from != to) {
        shapes.add(
          Arrow(
            color: AppTheme.bestMoveArrow,
            orig: from,
            dest: to,
            scale: 0.85,
          ),
        );
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.maxWidth.isFinite
              ? (constraints.maxHeight.isFinite
                  ? math.min(constraints.maxWidth, constraints.maxHeight)
                  : constraints.maxWidth)
              : 300.0;

          return Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: StaticChessboard(
                size: boardSize,
                orientation: flipped ? Side.black : Side.white,
                fen: fen,
                lastMove: lastMove,
                shapes: shapes,
                settings: StaticChessboardSettings(
                  colorScheme: _boardColorScheme,
                  pieceAssets: PieceSet.cburnettAssets,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.cardShadow,
                  enableCoordinates: true,
                  showLastMove: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
