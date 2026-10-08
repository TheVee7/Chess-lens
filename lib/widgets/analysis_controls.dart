import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Navigation controls for stepping through game moves.
class AnalysisControls extends StatelessWidget {
  final VoidCallback? onFirst;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLast;
  final VoidCallback? onFlipBoard;
  final VoidCallback? onPreviousCritical;
  final VoidCallback? onNextCritical;

  const AnalysisControls({
    super.key,
    this.onFirst,
    this.onPrevious,
    this.onNext,
    this.onLast,
    this.onFlipBoard,
    this.onPreviousCritical,
    this.onNextCritical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            onTap: onFirst,
            tooltip: 'First move',
          ),
          _ControlButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            tooltip: 'Previous',
            large: true,
          ),
          _ControlButton(
            icon: Icons.warning_amber_rounded,
            onTap: onPreviousCritical,
            tooltip: 'Previous mistake',
            color: AppTheme.warning,
          ),
          _ControlButton(
            icon: Icons.swap_vert_rounded,
            onTap: onFlipBoard,
            tooltip: 'Flip board',
          ),
          _ControlButton(
            icon: Icons.warning_amber_rounded,
            onTap: onNextCritical,
            tooltip: 'Next mistake',
            color: AppTheme.warning,
          ),
          _ControlButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            tooltip: 'Next',
            large: true,
          ),
          _ControlButton(
            icon: Icons.skip_next_rounded,
            onTap: onLast,
            tooltip: 'Last move',
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool large;
  final Color? color;

  const _ControlButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
    this.large = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 6 : 4,
              vertical: large ? 8 : 6,
            ),
            child: Icon(
              icon,
              size: large ? 24 : 20,
              color: onTap != null
                  ? (color ?? AppTheme.textPrimary)
                  : AppTheme.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
