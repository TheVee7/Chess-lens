import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Two-row navigation control bar pinned in the bottom thumb zone.
///
/// Row 1: First, Previous, Next (large, green filled `primary`), Last.
/// Row 2: Four labeled icon buttons: "Prev mistake", "Next mistake", "Flip", "Details".
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: First, Previous, Next (large primary), Last ───────────
          Row(
            children: [
              // First move
              Expanded(
                flex: 1,
                child: _buildIconButton(
                  icon: Icons.first_page_rounded,
                  tooltip: 'First move',
                  semanticsLabel: 'First move',
                  onTap: onFirst,
                  height: 48,
                ),
              ),
              const SizedBox(width: 8),

              // Previous move
              Expanded(
                flex: 1,
                child: _buildIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous move',
                  semanticsLabel: 'Previous move',
                  onTap: onPrevious,
                  height: 48,
                ),
              ),
              const SizedBox(width: 8),

              // Next move (large green filled primary)
              Expanded(
                flex: 2,
                child: _buildNextButton(),
              ),
              const SizedBox(width: 8),

              // Last move
              Expanded(
                flex: 1,
                child: _buildIconButton(
                  icon: Icons.last_page_rounded,
                  tooltip: 'Last move',
                  semanticsLabel: 'Last move',
                  onTap: onLast,
                  height: 48,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Row 2: Four labeled icon buttons ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildLabeledButton(
                  icon: Icons.warning_amber_rounded,
                  label: 'Prev mistake',
                  color: AppTheme.inaccuracy,
                  onTap: onPreviousCritical,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildLabeledButton(
                  icon: Icons.warning_amber_rounded,
                  label: 'Next mistake',
                  color: AppTheme.inaccuracy,
                  onTap: onNextCritical,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildLabeledButton(
                  icon: Icons.swap_vert_rounded,
                  label: 'Flip',
                  color: AppTheme.textPrimary,
                  onTap: onFlipBoard,
                ),
              ),
              if (onDetails != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: _buildLabeledButton(
                    icon: Icons.tune_rounded,
                    label: 'Details',
                    color: AppTheme.primary,
                    onTap: onDetails,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final bool isEnabled = onNext != null;
    return Semantics(
      button: true,
      label: 'Next move',
      child: Tooltip(
        message: 'Next move',
        child: SizedBox(
          height: 52,
          child: Material(
            color: isEnabled ? AppTheme.primary : AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              onTap: onNext,
              child: Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 32,
                  color: isEnabled ? AppTheme.onPrimary : AppTheme.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required String semanticsLabel,
    required VoidCallback? onTap,
    required double height,
  }) {
    final bool isEnabled = onTap != null;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusInner),
            border: Border.all(color: AppTheme.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusInner),
              onTap: onTap,
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isEnabled ? AppTheme.textPrimary : AppTheme.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusInner),
            border: Border.all(color: AppTheme.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusInner),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isEnabled ? color : AppTheme.textDisabled,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: isEnabled ? AppTheme.textSecondary : AppTheme.textDisabled,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
