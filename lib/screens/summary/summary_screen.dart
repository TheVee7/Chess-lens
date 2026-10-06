import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/game_controller.dart';
import '../../models/chess_game.dart';

class SummaryScreen extends StatelessWidget {
  final ChessGame game;

  const SummaryScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Review'),
      ),
      body: Consumer<GameController>(
        builder: (context, controller, _) {
          final review = controller.gameReview;
          final isRunning = controller.geminiRunning;

          if (review == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRunning) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Gemini is analyzing your game...',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppTheme.warning.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Game review is not available.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary ─────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overall Performance',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    review.summary,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Key lessons ─────────────────────────────────────
                if (review.keyLessons.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: AppTheme.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Key Takeaways',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...review.keyLessons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lesson = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lesson,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
