import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/game_controller.dart';
import '../../models/chess_game.dart';
import '../../models/move_analysis.dart';
import '../../widgets/evaluation_graph.dart';
import '../../widgets/move_list.dart';
import '../../widgets/ui/ui.dart';
import '../analysis/analysis_screen.dart';

class QuickReportScreen extends StatefulWidget {
  final ChessGame game;
  final GameController? controller;

  const QuickReportScreen({
    super.key,
    required this.game,
    this.controller,
  });

  @override
  State<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends State<QuickReportScreen> {
  GameController? _ownedController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownedController ??= widget.controller ?? context.read<GameController>();
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _navigateToReview(GameController controller) {
    controller.goToStart();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: AnalysisScreen(game: widget.game),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Consumer<GameController>(
      builder: (context, controller, _) {
        final analysis = controller.analysis;
        if (analysis == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        final whitePlayer = game.whiteElo.isNotEmpty
            ? '${game.white} (${game.whiteElo})'
            : game.white;
        final blackPlayer = game.blackElo.isNotEmpty
            ? '${game.black} (${game.blackElo})'
            : game.black;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game report'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.screenMargin,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Header Tile (2 wide) ─────────────────────
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // White player
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.textSecondary,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                whitePlayer,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Black player
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2A313A),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.textSecondary,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                blackPlayer,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (game.result.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceRaised,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusInner,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.border,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            game.result,
                                            style: AppTheme.tabularFigures(
                                              GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${game.totalMoves} moves',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.tileGap),

                        // ── 2. Two Accuracy Tiles (1 wide each) ─────────
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 320;
                            final whiteTile = AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Center(
                                child: StatRing(
                                  value: analysis.whiteAccuracy,
                                  caption: game.white,
                                  size: 84,
                                ),
                              ),
                            );

                            final blackTile = AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Center(
                                child: StatRing(
                                  value: analysis.blackAccuracy,
                                  caption: game.black,
                                  size: 84,
                                ),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  whiteTile,
                                  const SizedBox(height: AppTheme.tileGap),
                                  blackTile,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: whiteTile),
                                const SizedBox(width: AppTheme.tileGap),
                                Expanded(child: blackTile),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.tileGap),

                        // ── 3. Move Quality Tile (2 wide) ───────────────
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Move quality',
                                padding: const EdgeInsets.only(bottom: 10),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        'White',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        'Black',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.best,
                                label: 'Best',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.best] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.best] ??
                                    0,
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.excellent,
                                label: 'Excellent',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.excellent] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.excellent] ??
                                    0,
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.good,
                                label: 'Good',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.good] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.good] ??
                                    0,
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.inaccuracy,
                                label: 'Inaccurate',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.inaccuracy] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.inaccuracy] ??
                                    0,
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.mistake,
                                label: 'Mistake',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.mistake] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.mistake] ??
                                    0,
                              ),
                              _MoveQualityRow(
                                classification: MoveClassification.blunder,
                                label: 'Blunder',
                                whiteCount: analysis.whiteClassifications[
                                        MoveClassification.blunder] ??
                                    0,
                                blackCount: analysis.blackClassifications[
                                        MoveClassification.blunder] ??
                                    0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.tileGap),

                        // ── 4. Evaluation Tile (2 wide) ─────────────────
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Evaluation',
                                padding: EdgeInsets.only(bottom: 12),
                              ),
                              EvaluationGraphWidget(
                                moves: analysis.moves,
                                selectedPly: controller.currentPlyIndex >= 0
                                    ? controller.currentPlyIndex
                                    : null,
                                onTapMove: (ply) => controller.goToMove(ply),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.tileGap),

                        // ── 5. Moves Tile (2 wide) ──────────────────────
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Moves',
                                padding: EdgeInsets.only(bottom: 12),
                              ),
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
                                          ChangeNotifierProvider<
                                              GameController>.value(
                                        value: controller,
                                        child: AnalysisScreen(game: game),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pinned Bottom Bar ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppTheme.screenMargin),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(
                      top: BorderSide(color: AppTheme.border, width: 1),
                    ),
                  ),
                  child: PrimaryButton(
                    label: 'Review game',
                    showTrailingArrow: true,
                    onPressed: () => _navigateToReview(controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoveQualityRow extends StatelessWidget {
  final MoveClassification classification;
  final String label;
  final int whiteCount;
  final int blackCount;

  const _MoveQualityRow({
    required this.classification,
    required this.label,
    required this.whiteCount,
    required this.blackCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.classificationColor(classification);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ClassificationDot(classification: classification, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$whiteCount',
              textAlign: TextAlign.center,
              style: AppTheme.tabularFigures(
                GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: whiteCount > 0 ? color : AppTheme.textDisabled,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '$blackCount',
              textAlign: TextAlign.center,
              style: AppTheme.tabularFigures(
                GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: blackCount > 0 ? color : AppTheme.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
