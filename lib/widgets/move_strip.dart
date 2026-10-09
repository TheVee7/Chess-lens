import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

/// Horizontally scrolling single-line strip of move chips with classification markers.
class MoveStripWidget extends StatefulWidget {
  final List<MoveAnalysis> moves;
  final int currentPlyIndex;
  final ValueChanged<int>? onTapMove;

  const MoveStripWidget({
    super.key,
    required this.moves,
    required this.currentPlyIndex,
    this.onTapMove,
  });

  @override
  State<MoveStripWidget> createState() => _MoveStripWidgetState();
}

class _MoveStripWidgetState extends State<MoveStripWidget> {
  final ScrollController _scrollController = ScrollController();
  static const double _chipWidth = 78.0;
  static const double _chipSpacing = 6.0;

  @override
  void didUpdateWidget(MoveStripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPlyIndex != oldWidget.currentPlyIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // Index 0 is the "Start" chip, moves start at index 1
      final itemIndex = widget.currentPlyIndex + 1;
      final target = (itemIndex * (_chipWidth + _chipSpacing)) -
          (_scrollController.position.viewportDimension / 2) +
          (_chipWidth / 2);
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
    // Total items: 1 (Start chip) + number of moves
    final totalItems = widget.moves.length + 1;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: totalItems,
        separatorBuilder: (_, _) => const SizedBox(width: _chipSpacing),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = widget.currentPlyIndex == -1;
            return _buildChip(
              isSelected: isSelected,
              label: 'Start',
              symbol: null,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              onTap: () => widget.onTapMove?.call(-1),
            );
          }

          final moveIndex = index - 1;
          final move = widget.moves[moveIndex];
          final isSelected = widget.currentPlyIndex == move.plyIndex;
          final symbol = AppTheme.classificationSymbol(move.classification);
          final classColor = AppTheme.classificationColor(move.classification);
          final moveLabel = move.isWhite
              ? '${move.moveNumber}. ${move.san}'
              : '${move.moveNumber}... ${move.san}';

          return _buildChip(
            isSelected: isSelected,
            label: moveLabel,
            symbol: symbol,
            color: classColor,
            onTap: () => widget.onTapMove?.call(move.plyIndex),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required bool isSelected,
    required String label,
    required String? symbol,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: _chipWidth,
      child: Material(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.18)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (symbol != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
