import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/game_controller.dart';
import '../models/move_analysis.dart';
import '../models/game_explanation.dart';

/// Fixed-height Coach Review panel with internal scrolling, status transitions,
/// and AI explanations located above the chessboard.
class CoachReviewWidget extends StatelessWidget {
  final MoveAnalysis? currentMove;
  final ExplanationStatus status;
  final MoveExplanation? explanation;
  final String? errorMessage;
  final bool canRetry;
  final VoidCallback? onRetry;
  final bool hasApiKey;
  final VoidCallback? onOpenSettings;
  final bool isGeminiRunning;
  final double height;
  final int? plyIndex;

  const CoachReviewWidget({
    super.key,
    this.currentMove,
    this.status = ExplanationStatus.waiting,
    this.explanation,
    this.errorMessage,
    this.canRetry = true,
    this.onRetry,
    this.hasApiKey = true,
    this.onOpenSettings,
    this.isGeminiRunning = false,
    this.height = 160.0,
    this.plyIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height == double.infinity ? null : height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: currentMove != null && currentMove!.isImportant
              ? AppTheme.classificationColor(currentMove!.classification).withValues(alpha: 0.35)
              : AppTheme.surfaceBorder,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row (stable, never moves) ─────────────────────────
          _buildHeader(),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.surfaceBorder),
          const SizedBox(height: 6),

          // ── Scrollable Body with smooth transition ───────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: SingleChildScrollView(
                key: ValueKey<String>(
                  '${currentMove?.plyIndex ?? -1}_${status.name}_$hasApiKey',
                ),
                physics: const ClampingScrollPhysics(),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (currentMove == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'Coach Review',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final m = currentMove!;
    final classColor = AppTheme.classificationColor(m.classification);
    final classLabel = AppTheme.classificationLabel(m.classification);
    final isAiWritten = status == ExplanationStatus.done && explanation != null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Classification icon chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: classColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppTheme.classificationIcon(m.classification),
                  color: classColor,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${m.moveNumber}${m.isWhite ? '.' : '...'} ${m.san}',
                  style: TextStyle(
                    color: classColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Classification badge text
          Text(
            classLabel,
            style: TextStyle(
              color: classColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),

          // Eval change
          Text(
            '${m.evalBeforeStr} → ${m.evalAfterStr}',
            style: TextStyle(
              color: _evalChangeColor(m),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),

          // Gemini AI badge
          if (isAiWritten) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryLight, size: 10),
                  SizedBox(width: 2),
                  Text(
                    'Gemini',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress spinner
          if (isGeminiRunning || status == ExplanationStatus.generating) ...[
            const SizedBox(width: 6),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 1. Start position (no move yet)
    if (currentMove == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textTertiary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Starting position. Use the controls below or tap any move in the strip to step through the game review.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final m = currentMove!;

    // 2. Non-critical move (no AI explanation triggered)
    if (!m.isImportant) {
      final isBest = m.classification == MoveClassification.best;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBest ? Icons.check_circle_rounded : Icons.check_rounded,
                  size: 16,
                  color: AppTheme.classificationColor(m.classification),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isBest
                        ? 'Best move! Matches the engine choice.'
                        : 'Good move. Maintains solid position (${m.evalAfterStr}).',
                    style: TextStyle(
                      color: AppTheme.classificationColor(m.classification),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (m.bestMoveSan != null && m.bestMoveSan != m.san) ...[
              const SizedBox(height: 6),
              Text(
                'Engine alternative: ${m.bestMoveSan}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 3. Important move without API key (when not already attempted or failed)
    if (!hasApiKey && status == ExplanationStatus.waiting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: onOpenSettings,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.key_rounded, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add Gemini API Key in Settings to unlock AI Coach explanations.',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.warning, size: 11),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Important move states by ExplanationStatus
    switch (status) {
      case ExplanationStatus.waiting:
      case ExplanationStatus.generating:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == ExplanationStatus.generating
                        ? 'Coach is analyzing this moment...'
                        : 'Waiting for coach analysis...',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSkeletonBar(0.85),
              const SizedBox(height: 5),
              _buildSkeletonBar(0.60),
            ],
          ),
        );

      case ExplanationStatus.done:
        if (explanation == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No explanation available for this move.',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          );
        }

        final exp = explanation!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exp.explanation,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (exp.betterMove.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppTheme.accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exp.betterMove,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (exp.lesson.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AppTheme.warning, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exp.lesson,
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case ExplanationStatus.failed:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage ?? 'Coach explanation unavailable.',
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
              if (canRetry && onRetry != null) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: onRetry,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        'Retry Explanation',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildSkeletonBar(double widthFraction) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: AppTheme.surfaceBorder.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static Color _evalChangeColor(MoveAnalysis a) {
    if (a.evalLoss > 100) return AppTheme.blunder;
    if (a.evalLoss > 50) return AppTheme.mistake;
    return AppTheme.textPrimary;
  }
}
