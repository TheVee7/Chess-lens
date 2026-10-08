import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

/// Scrollable move list with classification indicators, supporting 200+ plies
/// and auto-scrolling to the selected move.
class MoveListWidget extends StatefulWidget {
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
  State<MoveListWidget> createState() => _MoveListWidgetState();
}

class _MoveListWidgetState extends State<MoveListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(MoveListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPly != oldWidget.selectedPly) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selectedPly == null || !_scrollController.hasClients) {
        return;
      }
      final rowIndex = widget.selectedPly! ~/ 2;
      const rowEstimatedHeight = 36.0;
      final target = (rowIndex * rowEstimatedHeight) - 72.0;
      final clamped = target.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairCount = (widget.moves.length + 1) ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: pairCount,
        itemExtent: 36.0,
        itemBuilder: (context, index) {
          final whiteIndex = index * 2;
          final white = widget.moves[whiteIndex];
          final black = (whiteIndex + 1 < widget.moves.length)
              ? widget.moves[whiteIndex + 1]
              : null;

          return _MoveRow(
            key: ValueKey('move_row_$index'),
            moveNumber: white.moveNumber,
            white: white,
            black: black,
            selectedPly: widget.selectedPly,
            onTap: widget.onTapMove,
          );
        },
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
    super.key,
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
            width: 34,
            child: Text(
              '$moveNumber.',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final symbol = _classificationSymbol(analysis.classification);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                analysis.san,
                style: TextStyle(
                  color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (symbol != null) ...[
              const SizedBox(width: 4),
              Text(
                symbol,
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
