import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/game_controller.dart';
import '../../models/chess_game.dart';
import '../../models/move_analysis.dart';
import '../../widgets/evaluation_graph.dart';
import '../../widgets/move_list.dart';
import '../analysis/analysis_screen.dart';

class QuickReportScreen extends StatelessWidget {
  final ChessGame game;

  const QuickReportScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final analysis = controller.analysis;
        if (analysis == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game Review'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────
                Center(
                  child: Text(
                    'GAME REVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${game.white} vs ${game.black}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (game.result.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      game.result,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Accuracy cards ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _AccuracyCard(
                        label: game.white,
                        accuracy: analysis.whiteAccuracy,
                        isWhite: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccuracyCard(
                        label: game.black,
                        accuracy: analysis.blackAccuracy,
                        isWhite: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Classification breakdown ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ClassificationColumn(
                        classifications: analysis.whiteClassifications,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ClassificationColumn(
                        classifications: analysis.blackClassifications,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Evaluation graph ──────────────────────────
                Text(
                  'EVALUATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                EvaluationGraphWidget(
                  moves: analysis.moves,
                  selectedPly: controller.currentPlyIndex >= 0
                      ? controller.currentPlyIndex
                      : null,
                  onTapMove: (ply) => controller.goToMove(ply),
                ),
                const SizedBox(height: 24),

                // ── Move list ─────────────────────────────────
                Text(
                  'MOVES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                MoveListWidget(
                  moves: analysis.moves,
                  selectedPly: controller.currentPlyIndex >= 0
                      ? controller.currentPlyIndex
                      : null,
                  onTapMove: (ply) {
                    controller.goToMove(ply);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<GameController>.value(
                          value: controller,
                          child: AnalysisScreen(game: game),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Review game button ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        onTap: () {
                          controller.goToStart();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChangeNotifierProvider<GameController>.value(
                                value: controller,
                                child: AnalysisScreen(game: game),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Review Game',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────

class _AccuracyCard extends StatelessWidget {
  final String label;
  final double accuracy;
  final bool isWhite;

  const _AccuracyCard({
    required this.label,
    required this.accuracy,
    required this.isWhite,
  });

  @override
  Widget build(BuildContext context) {
    final color = accuracy >= 90
        ? AppTheme.bestMove
        : accuracy >= 70
            ? AppTheme.excellent
            : accuracy >= 50
                ? AppTheme.inaccuracy
                : AppTheme.mistake;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : const Color(0xFF333333),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.textTertiary,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${accuracy.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            'Accuracy',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassificationColumn extends StatelessWidget {
  final Map<MoveClassification, int> classifications;

  const _ClassificationColumn({required this.classifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          _ClassRow('✓', 'Best',
              classifications[MoveClassification.best] ?? 0, AppTheme.bestMove),
          _ClassRow('✓', 'Excellent',
              classifications[MoveClassification.excellent] ?? 0, AppTheme.excellent),
          _ClassRow('', 'Good',
              classifications[MoveClassification.good] ?? 0, AppTheme.good),
          _ClassRow('?!', 'Inaccurate',
              classifications[MoveClassification.inaccuracy] ?? 0, AppTheme.inaccuracy),
          _ClassRow('?', 'Mistake',
              classifications[MoveClassification.mistake] ?? 0, AppTheme.mistake),
          _ClassRow('??', 'Blunder',
              classifications[MoveClassification.blunder] ?? 0, AppTheme.blunder),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final String symbol;
  final String label;
  final int count;
  final Color color;

  const _ClassRow(this.symbol, this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: count > 0 ? color : AppTheme.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
