import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum StatusChipVariant {
  connected,
  warning,
  error,
  neutral,
}

/// Compact status chip featuring a colored status dot and a label.
/// Variants: connected (green), warning (amber), error (red), neutral (secondary).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipVariant variant;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.connected,
    this.onTap,
  });

  Color get _color {
    switch (variant) {
      case StatusChipVariant.connected:
        return AppTheme.primary;
      case StatusChipVariant.warning:
        return AppTheme.inaccuracy;
      case StatusChipVariant.error:
        return AppTheme.blunder;
      case StatusChipVariant.neutral:
        return AppTheme.textSecondary;
    }
  }

  Color get _containerColor {
    switch (variant) {
      case StatusChipVariant.connected:
        return AppTheme.primaryContainer;
      case StatusChipVariant.warning:
        return AppTheme.inaccuracy.withValues(alpha: 0.15);
      case StatusChipVariant.error:
        return AppTheme.blunder.withValues(alpha: 0.15);
      case StatusChipVariant.neutral:
        return AppTheme.surfaceRaised;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _containerColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: onTap,
          child: chip,
        ),
      );
    }

    return chip;
  }
}
