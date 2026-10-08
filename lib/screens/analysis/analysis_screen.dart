import 'dart:math' as math;
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
import '../settings/settings_screen.dart';

import 'package:share_plus/share_plus.dart';

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
    final keyMgr = context.watch<ApiKeyManager>();

    return Consumer<GameController>(
      builder: (context, controller, _) {
        if (!_geminiStarted &&
            keyMgr.hasKey &&
            !controller.geminiRunning &&
            controller.analysis != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeStartGemini();
          });
        }

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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Game Review'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share PGN',
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: widget.game.rawPgn,
                      subject: 'ChessLens Game PGN',
                    ),
                  );
                },
              ),
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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                if (isLandscape) {
                  // ── Landscape side-by-side layout ─────────────────
                  final boardSize = math.max(
                    160.0,
                    math.min(
                      constraints.maxHeight - 84.0,
                      (constraints.maxWidth * 0.50) - 52.0,
                    ),
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Board + eval bar + controls
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: boardSize,
                                  child: EvalBar(
                                    evalCp: currentMove?.evalAfter ?? 0,
                                    isMate: currentMove?.isMateAfter ?? false,
                                    mateIn: currentMove?.mateAfter,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: boardSize,
                                  height: boardSize,
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
                            const SizedBox(height: 8),
                            SizedBox(
                              width: boardSize + 36.0,
                              child: _buildControls(controller),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Right: Analysis details
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: _buildDetailsColumn(
                              context, controller, currentMove, keyMgr),
                        ),
                      ),
                    ],
                  );
                }

                // ── Portrait layout ──────────────────────────────────
                final boardSize = math.max(
                  160.0,
                  math.min(
                    constraints.maxWidth - 52.0,
                    constraints.maxHeight * 0.44,
                  ),
                );

                return Column(
                  children: [
                    // Board + eval bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: boardSize,
                            child: EvalBar(
                              evalCp: currentMove?.evalAfter ?? 0,
                              isMate: currentMove?.isMateAfter ?? false,
                              mateIn: currentMove?.mateAfter,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
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

                    // Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildControls(controller),
                    ),
                    const SizedBox(height: 8),

                    // Analysis details
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildDetailsColumn(
                            context, controller, currentMove, keyMgr),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(GameController controller) {
    return AnalysisControls(
      onFirst: () => controller.goToStart(),
      onPrevious: () => controller.previousMove(),
      onNext: () => controller.nextMove(),
      onLast: () => controller.goToEnd(),
      onFlipBoard: () => setState(() => _boardFlipped = !_boardFlipped),
      onPreviousCritical: () => controller.previousCriticalMoment(),
      onNextCritical: () => controller.nextCriticalMoment(),
    );
  }

  Widget _buildDetailsColumn(
    BuildContext context,
    GameController controller,
    MoveAnalysis? currentMove,
    ApiKeyManager keyMgr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Engine panel.
        EnginePanel(analysis: currentMove),
        const SizedBox(height: 8),

        // Coach review (if this is an important move).
        if (currentMove != null && currentMove.isImportant)
          CoachReviewWidget(
            plyIndex: currentMove.plyIndex,
            status: controller.explanationStatus[currentMove.plyIndex] ??
                ExplanationStatus.waiting,
            explanation: controller.explanations[currentMove.plyIndex],
            errorMessage: controller.moveErrors[currentMove.plyIndex] ??
                controller.geminiError,
            canRetry: !controller.isInvalidKey,
            onRetry: () {
              if (keyMgr.hasKey) {
                controller.retryExplanation(keyMgr.apiKey!, currentMove);
              }
            },
          ),

        // Gemini progress indicator.
        if (controller.geminiRunning) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gemini analyzing important moves...',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // No API key warning (interactive).
        if (!keyMgr.hasKey &&
            currentMove != null &&
            currentMove.isImportant) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.key_rounded, color: AppTheme.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add Gemini API Key in Settings to enable Coach Reviews.',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.warning, size: 12),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}
