import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Navigation controls for stepping through game moves in the bottom thumb zone.
class AnalysisControls extends StatelessWidget {
  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;
  final VoidCallback? onFlipBoard;
  final VoidCallback? onPreviousCritical;
  final VoidCallback? onNextCritical;
  final VoidCallback? onDetails;

  const AnalysisControls({
    super.key,
    this.onFirst,
    this.onPrevious,
    this.onNext,
    this.onLast,
    this.onFlipBoard,
    this.onPreviousCritical,
    this.onNextCritical,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _buildItem(
            flex: 1,
            icon: Icons.skip_previous_rounded,
            onTap: onFirst,
            tooltip: 'First move',
          ),
          _buildItem(
            flex: 1,
            icon: Icons.warning_amber_rounded,
            onTap: onPreviousCritical,
            tooltip: 'Previous mistake',
            color: AppTheme.warning,
          ),
          _buildItem(
            flex: 2,
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            tooltip: 'Previous',
            large: true,
          ),
          _buildItem(
            flex: 2,
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            tooltip: 'Next',
            large: true,
          ),
          _buildItem(
            flex: 1,
            icon: Icons.warning_amber_rounded,
            onTap: onNextCritical,
            tooltip: 'Next mistake',
            color: AppTheme.warning,
          ),
          _buildItem(
            flex: 1,
            icon: Icons.skip_next_rounded,
            onTap: onLast,
            tooltip: 'Last move',
          ),
          _buildItem(
            flex: 1,
            icon: Icons.swap_vert_rounded,
            onTap: onFlipBoard,
            tooltip: 'Flip board',
          ),
          if (onDetails != null)
            _buildItem(
              flex: 1,
              icon: Icons.tune_rounded,
              onTap: onDetails,
              tooltip: 'Details & Analysis',
              color: AppTheme.primaryLight,
            ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required int flex,
    required IconData icon,
    VoidCallback? onTap,
    required String tooltip,
    bool large = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: large ? 28 : 20,
                color: onTap != null
                    ? (color ?? (large ? AppTheme.textPrimary : AppTheme.textSecondary))
                    : AppTheme.textTertiary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
