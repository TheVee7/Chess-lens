import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

/// Scrollable move list with classification indicators.
class MoveListWidget extends StatelessWidget {
  final List<MoveAnalysis> moves;
  final int? selectedPly;
  final ValueChanged<int>? onTapMove;

  const MoveListWidget({
    super.key,
    required this.moves,
    this.selectedPly,
    this.onTapMove,
  });

  @override
  Widget build(BuildContext context) {
    // Group into full moves (pairs of white + black).
    final rows = <Widget>[];
    for (int i = 0; i < moves.length; i += 2) {
      final white = moves[i];
      final black = (i + 1 < moves.length) ? moves[i + 1] : null;
      rows.add(_MoveRow(
        moveNumber: white.moveNumber,
        white: white,
        black: black,
        selectedPly: selectedPly,
        onTap: onTapMove,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        shrinkWrap: true,
        children: rows,
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  final int moveNumber;
  final MoveAnalysis white;
  final MoveAnalysis? black;
  final int? selectedPly;
  final ValueChanged<int>? onTap;

  const _MoveRow({
    required this.moveNumber,
    required this.white,
    this.black,
    this.selectedPly,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          // Move number.
          SizedBox(
            width: 32,
            child: Text(
              '$moveNumber.',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // White move.
          Expanded(
            child: _MoveCell(
              analysis: white,
              isSelected: selectedPly == white.plyIndex,
              onTap: () => onTap?.call(white.plyIndex),
            ),
          ),
          const SizedBox(width: 8),
          // Black move.
          Expanded(
            child: black != null
                ? _MoveCell(
                    analysis: black!,
                    isSelected: selectedPly == black!.plyIndex,
                    onTap: () => onTap?.call(black!.plyIndex),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _MoveCell extends StatelessWidget {
  final MoveAnalysis analysis;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MoveCell({
    required this.analysis,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              analysis.san,
              style: TextStyle(
                color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (_classificationSymbol(analysis.classification) != null) ...[
              const SizedBox(width: 4),
              Text(
                _classificationSymbol(analysis.classification)!,
                style: TextStyle(
                  color: _classificationColor(analysis.classification),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _classificationSymbol(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return '??';
      case MoveClassification.mistake:
        return '?';
      case MoveClassification.inaccuracy:
        return '?!';
      case MoveClassification.best:
        return '✓';
      case MoveClassification.excellent:
        return '✓';
      default:
        return null;
    }
  }

  static Color _classificationColor(MoveClassification c) {
    switch (c) {
      case MoveClassification.blunder:
        return AppTheme.blunder;
      case MoveClassification.mistake:
        return AppTheme.mistake;
      case MoveClassification.inaccuracy:
        return AppTheme.inaccuracy;
      case MoveClassification.best:
        return AppTheme.bestMove;
      case MoveClassification.excellent:
        return AppTheme.excellent;
      default:
        return AppTheme.textTertiary;
    }
  }
}
