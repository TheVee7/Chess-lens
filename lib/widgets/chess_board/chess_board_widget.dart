import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../core/theme/app_theme.dart';

/// A fully rendered chessboard with pieces, highlighting, and best-move arrow.
class ChessBoardWidget extends StatelessWidget {
  final String fen;
  final bool flipped;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? bestMoveFrom;
  final String? bestMoveTo;
  final bool showBestMoveArrow;

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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxWidth),
                painter: _BoardPainter(
                  fen: fen,
                  flipped: flipped,
                  lastMoveFrom: lastMoveFrom,
                  lastMoveTo: lastMoveTo,
                  bestMoveFrom: bestMoveFrom,
                  bestMoveTo: bestMoveTo,
                  showBestMoveArrow: showBestMoveArrow,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final String fen;
  final bool flipped;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? bestMoveFrom;
  final String? bestMoveTo;
  final bool showBestMoveArrow;

  _BoardPainter({
    required this.fen,
    required this.flipped,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.bestMoveFrom,
    this.bestMoveTo,
    this.showBestMoveArrow = false,
  });

  static const _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const _ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

  static const Map<String, String> _pieceUnicode = {
    'wK': '♔', 'wQ': '♕', 'wR': '♖', 'wB': '♗', 'wN': '♘', 'wP': '♙',
    'bK': '♚', 'bQ': '♛', 'bR': '♜', 'bB': '♝', 'bN': '♞', 'bP': '♟',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final board = chess_lib.Chess();
    board.load(fen);

    final sqSize = size.width / 8;
    final lightPaint = Paint()..color = AppTheme.boardLight;
    final darkPaint = Paint()..color = AppTheme.boardDark;
    final highlightPaint = Paint()..color = AppTheme.boardHighlight;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final rect = Rect.fromLTWH(
          col * sqSize, row * sqSize, sqSize, sqSize,
        );
        canvas.drawRect(rect, isLight ? lightPaint : darkPaint);

        final file = flipped ? 7 - col : col;
        final rank = flipped ? row : 7 - row;
        final sq = '${_files[file]}${_ranks[rank]}';

        // Highlight last move squares.
        if (sq == lastMoveFrom || sq == lastMoveTo) {
          canvas.drawRect(rect, highlightPaint);
        }

        // Draw piece.
        final piece = board.get(sq);
        if (piece != null) {
          final cPrefix =
              piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
          final tChar = piece.type.toString().toUpperCase();
          final unicode = _pieceUnicode['$cPrefix$tChar'];
          if (unicode != null) {
            final tp = TextPainter(
              text: TextSpan(
                text: unicode,
                style: TextStyle(
                  fontSize: sqSize * 0.78,
                  height: 1.0,
                  color: piece.color == chess_lib.Color.WHITE
                      ? const Color(0xFFFFF8E7)
                      : const Color(0xFF1A1D27),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(
              canvas,
              Offset(
                rect.left + (sqSize - tp.width) / 2,
                rect.top + (sqSize - tp.height) / 2,
              ),
            );
          }
        }

        // File / rank labels.
        if (rank == (flipped ? 7 : 0)) {
          _drawLabel(canvas, _files[file], rect.left + 2, rect.bottom - 12,
              sqSize * 0.15, isLight ? AppTheme.boardDark : AppTheme.boardLight);
        }
        if (col == (flipped ? 7 : 0)) {
          _drawLabel(canvas, _ranks[rank], rect.left + 2, rect.top + 2,
              sqSize * 0.15, isLight ? AppTheme.boardDark : AppTheme.boardLight);
        }
      }
    }

    // Best-move arrow.
    if (showBestMoveArrow && bestMoveFrom != null && bestMoveTo != null) {
      _drawArrow(canvas, sqSize, bestMoveFrom!, bestMoveTo!);
    }
  }

  void _drawLabel(Canvas c, String text, double x, double y, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(c, Offset(x, y));
  }

  void _drawArrow(Canvas canvas, double sqSize, String from, String to) {
    final fc = _files.indexOf(from[0]);
    final fr = _ranks.indexOf(from[1]);
    final tc = _files.indexOf(to[0]);
    final tr = _ranks.indexOf(to[1]);
    if (fc < 0 || fr < 0 || tc < 0 || tr < 0) return;

    final fx = (flipped ? 7 - fc : fc) * sqSize + sqSize / 2;
    final fy = (flipped ? fr : 7 - fr) * sqSize + sqSize / 2;
    final tx = (flipped ? 7 - tc : tc) * sqSize + sqSize / 2;
    final ty = (flipped ? tr : 7 - tr) * sqSize + sqSize / 2;

    final linePaint = Paint()
      ..color = AppTheme.bestMoveArrow
      ..strokeWidth = sqSize * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(fx, fy), Offset(tx, ty), linePaint);

    // Arrowhead.
    final angle = math.atan2(ty - fy, tx - fx);
    final headLen = sqSize * 0.35;
    final spread = 0.45;
    final arrowPaint = Paint()
      ..color = AppTheme.bestMoveArrow
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tx, ty)
      ..lineTo(
        tx - headLen * math.cos(angle - spread),
        ty - headLen * math.sin(angle - spread),
      )
      ..lineTo(
        tx - headLen * math.cos(angle + spread),
        ty - headLen * math.sin(angle + spread),
      )
      ..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.fen != fen ||
      old.flipped != flipped ||
      old.lastMoveFrom != lastMoveFrom ||
      old.lastMoveTo != lastMoveTo ||
      old.bestMoveFrom != bestMoveFrom ||
      old.bestMoveTo != bestMoveTo ||
      old.showBestMoveArrow != showBestMoveArrow;
}
