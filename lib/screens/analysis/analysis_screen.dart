import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/game_controller.dart';
import '../../ai/api_key_manager.dart';
import '../../models/chess_game.dart';
import '../../models/move_analysis.dart';
import '../../widgets/chess_board/chess_board_widget.dart';
import '../../widgets/eval_bar.dart';
import '../../widgets/engine_panel.dart';
import '../../widgets/coach_review.dart';
import '../../widgets/analysis_controls.dart';
import '../summary/summary_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final ChessGame game;

  const AnalysisScreen({super.key, required this.game});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _boardFlipped = false;
  bool _geminiStarted = false;

  @override
  void initState() {
    super.initState();
    // Kick off Gemini analysis once, if API key available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartGemini();
    });
  }

  void _maybeStartGemini() {
    if (_geminiStarted) return;
    final keyMgr = context.read<ApiKeyManager>();
    final controller = context.read<GameController>();
    if (keyMgr.hasKey && !controller.geminiRunning) {
      _geminiStarted = true;
      controller.startGeminiAnalysis(keyMgr.apiKey!);
    }
  }

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

        final currentMove = controller.currentMoveAnalysis;
        final currentFen = controller.currentFen;

        // Determine best-move arrow squares.
        String? bestFrom, bestTo;
        if (currentMove != null &&
            currentMove.bestMoveUci != null &&
            currentMove.bestMoveUci!.length >= 4) {
          bestFrom = currentMove.bestMoveUci!.substring(0, 2);
          bestTo = currentMove.bestMoveUci!.substring(2, 4);
        }

        // Last move squares.
        String? lastFrom, lastTo;
        if (currentMove != null && currentMove.bestMoveUci != null) {
          // For the "played" move, we'd need UCI – approximate from FEN diff.
          // For now show bestMove arrow, not played move highlight.
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game Review'),
            actions: [
              if (controller.gameReview != null)
                IconButton(
                  icon: const Icon(Icons.summarize_rounded),
                  tooltip: 'Game Summary',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<GameController>.value(
                          value: controller,
                          child: SummaryScreen(game: widget.game),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // ── Board + eval bar ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eval bar.
                    SizedBox(
                      height: MediaQuery.of(context).size.width - 44,
                      child: EvalBar(
                        evalCp: currentMove?.evalAfter ?? 0,
                        isMate: currentMove?.isMateAfter ?? false,
                        mateIn: currentMove?.mateAfter,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Board.
                    Expanded(
                      child: ChessBoardWidget(
                        fen: currentFen,
                        flipped: _boardFlipped,
                        bestMoveFrom: bestFrom,
                        bestMoveTo: bestTo,
                        showBestMoveArrow: currentMove != null &&
                            currentMove.classification !=
                                MoveClassification.best,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Controls ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnalysisControls(
                  onFirst: () => controller.goToStart(),
                  onPrevious: () => controller.previousMove(),
                  onNext: () => controller.nextMove(),
                  onLast: () => controller.goToEnd(),
                  onFlipBoard: () =>
                      setState(() => _boardFlipped = !_boardFlipped),
                  onPreviousCritical: () =>
                      controller.previousCriticalMoment(),
                  onNextCritical: () => controller.nextCriticalMoment(),
                ),
              ),
              const SizedBox(height: 8),

              // ── Analysis details ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      // Engine panel.
                      EnginePanel(analysis: currentMove),
                      const SizedBox(height: 8),

                      // Coach review (if this is an important move).
                      if (currentMove != null && currentMove.isImportant)
                        CoachReviewWidget(
                          plyIndex: currentMove.plyIndex,
                          status: controller
                                  .explanationStatus[currentMove.plyIndex] ??
                              ExplanationStatus.waiting,
                          explanation:
                              controller.explanations[currentMove.plyIndex],
                          onRetry: () {
                            final keyMgr = context.read<ApiKeyManager>();
                            if (keyMgr.hasKey) {
                              controller.retryExplanation(
                                  keyMgr.apiKey!, currentMove);
                            }
                          },
                        ),

                      // Gemini progress indicator.
                      if (controller.geminiRunning) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gemini analyzing important moves...',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // No API key warning.
                      if (!context.watch<ApiKeyManager>().hasKey &&
                          currentMove != null &&
                          currentMove.isImportant) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key_rounded,
                                  color: AppTheme.warning, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Add your Gemini API key in Settings to enable Coach Reviews.',
                                  style: TextStyle(
                                    color: AppTheme.warning,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
