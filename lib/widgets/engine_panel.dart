import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/move_analysis.dart';

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
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: const Text(
          'Select a move to see engine analysis',
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
        ),
      );
    }

    final a = analysis!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Move header ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _classColor(a.classification).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${a.moveNumber}${a.isWhite ? '.' : '...'} ${a.san}',
                  style: TextStyle(
                    color: _classColor(a.classification),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ClassificationBadge(classification: a.classification),
              if (a.engineTimedOut) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Timeout',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Eval change ────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 16, color: AppTheme.textTertiary),
              const SizedBox(width: 6),
              const Text('Stockfish',
                  style: TextStyle(
                      color: AppTheme.textTertiary, fontSize: 12)),
              const Spacer(),
              Text(
                '${a.evalBeforeStr} → ${a.evalAfterStr}',
                style: TextStyle(
                  color: _evalChangeColor(a),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // ── Best move ──────────────────────────────────────
          if (a.bestMoveSan != null && a.bestMoveSan != a.san) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 6),
                Text(
                  'Best: ${a.bestMoveSan}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],

          // ── PV ─────────────────────────────────────────────
          if (a.pv.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'PV: ${a.pv.join(' ')}',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  static Color _classColor(MoveClassification c) {
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
        return AppTheme.textSecondary;
    }
  }

  static Color _evalChangeColor(MoveAnalysis a) {
    if (a.evalLoss > 100) return AppTheme.blunder;
    if (a.evalLoss > 50) return AppTheme.mistake;
    return AppTheme.textPrimary;
  }
}

class _ClassificationBadge extends StatelessWidget {
  final MoveClassification classification;

  const _ClassificationBadge({required this.classification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String get _label {
    switch (classification) {
      case MoveClassification.best:
        return 'BEST';
      case MoveClassification.excellent:
        return 'EXCELLENT';
      case MoveClassification.good:
        return 'GOOD';
      case MoveClassification.book:
        return 'BOOK';
      case MoveClassification.inaccuracy:
        return 'INACCURACY';
      case MoveClassification.mistake:
        return 'MISTAKE';
      case MoveClassification.blunder:
        return 'BLUNDER';
      case MoveClassification.forced:
        return 'FORCED';
    }
  }

  Color get _color {
    switch (classification) {
      case MoveClassification.best:
        return AppTheme.bestMove;
      case MoveClassification.excellent:
        return AppTheme.excellent;
      case MoveClassification.good:
        return AppTheme.good;
      case MoveClassification.book:
        return AppTheme.book;
      case MoveClassification.inaccuracy:
        return AppTheme.inaccuracy;
      case MoveClassification.mistake:
        return AppTheme.mistake;
      case MoveClassification.blunder:
        return AppTheme.blunder;
      case MoveClassification.forced:
        return AppTheme.textSecondary;
    }
  }
}
