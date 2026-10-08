import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/game_controller.dart';
import '../models/game_explanation.dart';

/// Coach review card showing Gemini's explanation for a move.
class CoachReviewWidget extends StatelessWidget {
  final int plyIndex;
  final ExplanationStatus status;
  final MoveExplanation? explanation;
  final String? errorMessage;
  final bool canRetry;
  final VoidCallback? onRetry;

  const CoachReviewWidget({
    super.key,
    required this.plyIndex,
    required this.status,
    this.explanation,
    this.errorMessage,
    this.canRetry = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.surfaceLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Coach Review',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (status == ExplanationStatus.generating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Content ─────────────────────────────────────────
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (status) {
      case ExplanationStatus.waiting:
        return const Text(
          'Waiting for analysis...',
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
        );

      case ExplanationStatus.generating:
        return const Text(
          'Generating explanation...',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );

      case ExplanationStatus.done:
        if (explanation == null) {
          return const Text(
            'No explanation available.',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              explanation!.explanation,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (explanation!.betterMove.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: AppTheme.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation!.betterMove,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (explanation!.lesson.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: AppTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation!.lesson,
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 13,
                          height: 1.4,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coach Review unavailable',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              errorMessage ?? 'Stockfish analysis is still available.',
              style: TextStyle(
                color: errorMessage != null ? AppTheme.error : AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
            if (canRetry && onRetry != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}
