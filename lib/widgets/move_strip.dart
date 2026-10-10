import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

/// Horizontally scrolling single-line strip of rounded-rectangle move chips.
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
  static const double _chipWidth = 82.0;
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalItems,
        separatorBuilder: (_, _) => const SizedBox(width: _chipSpacing),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = widget.currentPlyIndex == -1;
            return _buildChip(
              isSelected: isSelected,
              label: 'Start',
              symbol: null,
              color: AppTheme.primary,
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
    final chipRadius = BorderRadius.circular(AppTheme.radiusInner);

    return SizedBox(
      width: _chipWidth,
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.16)
            : AppTheme.surfaceRaised,
        borderRadius: chipRadius,
        child: InkWell(
          borderRadius: chipRadius,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: chipRadius,
              border: Border.all(
                color: isSelected ? color : AppTheme.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      fontFeatures: const [FontFeature.tabularFigures()],
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
