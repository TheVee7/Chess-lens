import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';
import 'ui/ui.dart';

/// Panel showing the engine evaluation, played vs best move, and PV.
class EnginePanel extends StatelessWidget {
  final MoveAnalysis? analysis;

  const EnginePanel({super.key, this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Text(
          'Select a move to see engine analysis',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }

    final a = analysis!;
    final classColor = AppTheme.classificationColor(a.classification);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Move header ─────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: classColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusInner),
                  border: Border.all(color: classColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${a.moveNumber}${a.isWhite ? '.' : '...'} ${a.san}',
                  style: TextStyle(
                    color: classColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              ClassificationBadge(classification: a.classification),
              if (a.engineTimedOut)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.inaccuracy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusInner),
                    border: Border.all(color: AppTheme.inaccuracy.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: AppTheme.inaccuracy),
                      SizedBox(width: 4),
                      Text(
                        'Timeout',
                        style: TextStyle(
                          color: AppTheme.inaccuracy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Eval change ────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Stockfish',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${a.evalBeforeStr} → ${a.evalAfterStr}',
                style: TextStyle(
                  color: _evalChangeColor(a),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // ── Best move ──────────────────────────────────────
          if (a.bestMoveSan != null && a.bestMoveSan != a.san) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(AppTheme.radiusInner),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Best: ${a.bestMoveSan}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── PV ─────────────────────────────────────────────
          if (a.pv.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                'PV: ${a.pv.join(' ')}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _evalChangeColor(MoveAnalysis a) {
    if (a.evalLoss > 100) return AppTheme.blunder;
    if (a.evalLoss > 50) return AppTheme.mistake;
    return AppTheme.textPrimary;
  }
}
