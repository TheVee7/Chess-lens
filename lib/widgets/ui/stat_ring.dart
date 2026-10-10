import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Circular accuracy ring displaying an accuracy percentage with tabular figures
/// and a caption beneath.
class StatRing extends StatelessWidget {
  final double value; // 0.0 - 100.0
  final String caption;
  final double size;
  final Color? color;
  final double strokeWidth;

  const StatRing({
    super.key,
    required this.value,
    required this.caption,
    this.size = 100.0,
    this.color,
    this.strokeWidth = 8.0,
  });

  Color get _resolvedColor {
    if (color != null) return color!;
    if (value >= 90) return AppTheme.best;
    if (value >= 70) return AppTheme.great;
    if (value >= 50) return AppTheme.inaccuracy;
    return AppTheme.blunder;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _resolvedColor;
    final progressFraction = (value / 100.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  fraction: progressFraction,
                  color: ringColor,
                  trackColor: AppTheme.surfaceRaised,
                  strokeWidth: strokeWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${value.toStringAsFixed(0)}%',
                    style: AppTheme.tabularFigures(
                      GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Circular progress ring for analysis progress.
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String? label;
  final String? sublabel;
  final double size;

  const ProgressRing({
    super.key,
    required this.progress,
    this.label,
    this.sublabel,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  fraction: progress.clamp(0.0, 1.0),
                  color: AppTheme.primary,
                  trackColor: AppTheme.surfaceRaised,
                  strokeWidth: 9.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$percent%',
                    style: AppTheme.tabularFigures(
                      GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(
            label!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
        if (sublabel != null) ...[
          const SizedBox(height: 4),
          Text(
            sublabel!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    if (fraction > 0) {
      final activePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final sweepAngle = 2 * math.pi * fraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
