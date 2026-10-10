import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/move_analysis.dart';

/// Pill badge showing move classification (BEST, GREAT, MISTAKE, etc.) with
/// tinted container and classification color.
class ClassificationBadge extends StatelessWidget {
  final MoveClassification classification;
  final String? customLabel;
  final bool showIcon;

  const ClassificationBadge({
    super.key,
    required this.classification,
    this.customLabel,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.classificationColor(classification);
    final label = customLabel ?? AppTheme.classificationLabel(classification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              AppTheme.classificationIcon(classification),
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple colored circle matching a move classification.
class ClassificationDot extends StatelessWidget {
  final MoveClassification classification;
  final double size;

  const ClassificationDot({
    super.key,
    required this.classification,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.classificationColor(classification);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
