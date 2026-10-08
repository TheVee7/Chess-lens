import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

/// Interactive evaluation graph showing the game's evaluation trajectory.
class EvaluationGraphWidget extends StatelessWidget {
  final List<MoveAnalysis> moves;
  final int? selectedPly;
  final ValueChanged<int>? onTapMove;
  final double? height;

  const EvaluationGraphWidget({
    super.key,
    required this.moves,
    this.selectedPly,
    this.onTapMove,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final graphHeight = height ?? (screenH * 0.22).clamp(120.0, 190.0);

    if (moves.isEmpty) {
      return SizedBox(height: graphHeight);
    }

    return Container(
      height: graphHeight,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              if (onTapMove == null) return;
              final dx = details.localPosition.dx;
              final barWidth = constraints.maxWidth / moves.length;
              final index = (dx / barWidth).floor().clamp(0, moves.length - 1);
              onTapMove!(index);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _EvalGraphPainter(
                moves: moves,
                selectedPly: selectedPly,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EvalGraphPainter extends CustomPainter {
  final List<MoveAnalysis> moves;
  final int? selectedPly;

  _EvalGraphPainter({required this.moves, this.selectedPly});

  @override
  void paint(Canvas canvas, Size size) {
    if (moves.isEmpty) return;

    final w = size.width;
    final h = size.height - 20; // leave room for move labels
    final midY = h / 2;

    // Clamp evals for display.
    const maxCp = 500.0;

    double evalToY(double cp) {
      final clamped = cp.clamp(-maxCp, maxCp);
      return midY - (clamped / maxCp) * midY;
    }

    // ── Grid lines ───────────────────────────────────────────
    final gridPaint = Paint()
      ..color = AppTheme.surfaceBorder
      ..strokeWidth = 0.5;

    // Zero line.
    canvas.drawLine(Offset(0, midY), Offset(w, midY), gridPaint);

    // +/- markers.
    for (final cp in [100.0, 200.0, 300.0]) {
      canvas.drawLine(
        Offset(0, evalToY(cp)),
        Offset(w, evalToY(cp)),
        gridPaint..color = AppTheme.surfaceBorder.withValues(alpha: 0.3),
      );
      canvas.drawLine(
        Offset(0, evalToY(-cp)),
        Offset(w, evalToY(-cp)),
        gridPaint..color = AppTheme.surfaceBorder.withValues(alpha: 0.3),
      );
    }

    // ── Fill areas ───────────────────────────────────────────
    final stepW = w / moves.length;
    final whiteFill = Path();
    final blackFill = Path();

    whiteFill.moveTo(0, midY);
    blackFill.moveTo(0, midY);

    for (int i = 0; i < moves.length; i++) {
      final x = i * stepW + stepW / 2;
      final cp = moves[i].evalAfter;
      final y = evalToY(cp);

      if (cp >= 0) {
        whiteFill.lineTo(x, y);
        blackFill.lineTo(x, midY);
      } else {
        whiteFill.lineTo(x, midY);
        blackFill.lineTo(x, y);
      }
    }

    whiteFill.lineTo(w, midY);
    whiteFill.close();
    blackFill.lineTo(w, midY);
    blackFill.close();

    canvas.drawPath(
      whiteFill,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      blackFill,
      Paint()..color = AppTheme.textTertiary.withValues(alpha: 0.15),
    );

    // ── Line ─────────────────────────────────────────────────
    final linePath = Path();
    for (int i = 0; i < moves.length; i++) {
      final x = i * stepW + stepW / 2;
      final y = evalToY(moves[i].evalAfter);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Critical moment markers ──────────────────────────────
    for (int i = 0; i < moves.length; i++) {
      final m = moves[i];
      if (!m.isImportant) continue;
      final x = i * stepW + stepW / 2;
      final y = evalToY(m.evalAfter);
      Color dotColor;
      switch (m.classification) {
        case MoveClassification.blunder:
          dotColor = AppTheme.blunder;
          break;
        case MoveClassification.mistake:
          dotColor = AppTheme.mistake;
          break;
        case MoveClassification.inaccuracy:
          dotColor = AppTheme.inaccuracy;
          break;
        default:
          dotColor = AppTheme.textSecondary;
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = dotColor);
    }

    // ── Selected move marker ─────────────────────────────────
    if (selectedPly != null &&
        selectedPly! >= 0 &&
        selectedPly! < moves.length) {
      final x = selectedPly! * stepW + stepW / 2;
      final y = evalToY(moves[selectedPly!].evalAfter);
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = AppTheme.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = AppTheme.accent);

      // Vertical line.
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = AppTheme.accent.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
    }

    // ── Move number labels ───────────────────────────────────
    final labelInterval = math.max(1, moves.length ~/ 8);
    for (int i = 0; i < moves.length; i += labelInterval) {
      final moveNum = moves[i].moveNumber;
      final x = i * stepW + stepW / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '$moveNum',
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _EvalGraphPainter old) =>
      old.moves != moves || old.selectedPly != selectedPly;
}
