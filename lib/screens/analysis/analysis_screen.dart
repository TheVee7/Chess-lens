import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/game_controller.dart';
import '../../ai/api_key_manager.dart';
import '../../models/chess_game.dart';
import '../../models/move_analysis.dart';
import '../../widgets/chess_board/chess_board_widget.dart';
import '../../widgets/eval_bar.dart';
import '../../widgets/engine_panel.dart';
import '../../widgets/coach_review.dart';
import '../../widgets/move_strip.dart';
import '../../widgets/move_list.dart';
import '../../widgets/evaluation_graph.dart';
import '../../widgets/analysis_controls.dart';
import '../summary/summary_screen.dart';
import '../settings/settings_screen.dart';

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

        // Best-move arrow squares
        String? bestFrom, bestTo;
        if (currentMove != null &&
            currentMove.bestMoveUci != null &&
            currentMove.bestMoveUci!.length >= 4) {
          bestFrom = currentMove.bestMoveUci!.substring(0, 2);
          bestTo = currentMove.bestMoveUci!.substring(2, 4);
        }

        // Last-move highlight squares
        String? lastFrom, lastTo;
        if (currentMove != null &&
            currentMove.plyIndex >= 0 &&
            currentMove.plyIndex < widget.game.moves.length) {
          final move = widget.game.moves[currentMove.plyIndex];
          if (move.uci != null && move.uci!.length >= 4) {
            lastFrom = move.uci!.substring(0, 2);
            lastTo = move.uci!.substring(2, 4);
          }
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
                  return _buildLandscapeLayout(
                    context,
                    constraints,
                    controller,
                    currentMove,
                    currentFen,
                    lastFrom,
                    lastTo,
                    bestFrom,
                    bestTo,
                    keyMgr,
                  );
                }

                return _buildPortraitLayout(
                  context,
                  constraints,
                  controller,
                  currentMove,
                  currentFen,
                  lastFrom,
                  lastTo,
                  bestFrom,
                  bestTo,
                  keyMgr,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    BoxConstraints constraints,
    GameController controller,
    MoveAnalysis? currentMove,
    String currentFen,
    String? lastFrom,
    String? lastTo,
    String? bestFrom,
    String? bestTo,
    ApiKeyManager keyMgr,
  ) {
    final totalH = constraints.maxHeight;
    final totalW = constraints.maxWidth;

    // Minimum budget calculations to prevent any overflow
    const minCoachHeight = 110.0;
    const maxCoachHeight = 175.0;
    const moveStripHeight = 38.0;
    const controlsHeight = 56.0;
    const verticalPaddings = 24.0; // 4 spacing gaps of 6dp

    final fixedOverhead = moveStripHeight + controlsHeight + verticalPaddings;
    final availableForBoardAndCoach = math.max(0.0, totalH - fixedOverhead);

    double coachHeight = (totalH * 0.24).clamp(minCoachHeight, maxCoachHeight);
    double remainingForBoard = availableForBoardAndCoach - coachHeight;

    if (remainingForBoard < 160.0 && availableForBoardAndCoach > minCoachHeight) {
      coachHeight = math.max(minCoachHeight, availableForBoardAndCoach - 160.0);
      remainingForBoard = availableForBoardAndCoach - coachHeight;
    }

    final maxBoardWidth = math.max(100.0, totalW - 52.0);
    final boardSize = math.max(100.0, math.min(maxBoardWidth, remainingForBoard));

    return Column(
      children: [
        // Thin Gemini progress line at top of screen
        if (controller.geminiRunning)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppTheme.primary,
          ),

        // 1. Coach panel (top) – fixed stable height, scrollable inside
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CoachReviewWidget(
            height: coachHeight,
            currentMove: currentMove,
            status: currentMove != null
                ? (controller.explanationStatus[currentMove.plyIndex] ??
                    ExplanationStatus.waiting)
                : ExplanationStatus.waiting,
            explanation: currentMove != null
                ? controller.explanations[currentMove.plyIndex]
                : null,
            errorMessage: currentMove != null
                ? (controller.moveErrors[currentMove.plyIndex] ??
                    controller.geminiError)
                : null,
            canRetry: !controller.isInvalidKey,
            onRetry: () {
              if (keyMgr.hasKey && currentMove != null) {
                controller.retryExplanation(keyMgr.apiKey!, currentMove);
              }
            },
            hasApiKey: keyMgr.hasKey,
            onOpenSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            isGeminiRunning: controller.geminiRunning,
          ),
        ),
        const SizedBox(height: 6),

        // 2. Board row (middle) – centered, responsive square
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200) {
                        controller.nextMove();
                      } else if (v > 200) {
                        controller.previousMove();
                      }
                    },
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: ChessBoardWidget(
                        fen: currentFen,
                        flipped: _boardFlipped,
                        lastMoveFrom: lastFrom,
                        lastMoveTo: lastTo,
                        bestMoveFrom: bestFrom,
                        bestMoveTo: bestTo,
                        showBestMoveArrow: currentMove != null &&
                            currentMove.classification !=
                                MoveClassification.best,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 3. Move strip – single line horizontally scrolling move chips
        MoveStripWidget(
          moves: controller.analysis!.moves,
          currentPlyIndex: controller.currentPlyIndex,
          onTapMove: (ply) => controller.goToMove(ply),
        ),
        const SizedBox(height: 6),

        // 4. Control bar (bottom, pinned in thumb zone)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnalysisControls(
            onFirst: () => controller.goToStart(),
            onPrevious: () => controller.previousMove(),
            onNext: () => controller.nextMove(),
            onLast: () => controller.goToEnd(),
            onFlipBoard: () => setState(() => _boardFlipped = !_boardFlipped),
            onPreviousCritical: () => controller.previousCriticalMoment(),
            onNextCritical: () => controller.nextCriticalMoment(),
            onDetails: () => _openDetailsSheet(context, controller),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    BoxConstraints constraints,
    GameController controller,
    MoveAnalysis? currentMove,
    String currentFen,
    String? lastFrom,
    String? lastTo,
    String? bestFrom,
    String? bestTo,
    ApiKeyManager keyMgr,
  ) {
    final totalH = constraints.maxHeight;
    final totalW = constraints.maxWidth;

    final maxBoardByWidth = (totalW * 0.52) - 52.0;
    final maxBoardByHeight = totalH - 24.0;
    final boardSize =
        math.max(120.0, math.min(maxBoardByWidth, maxBoardByHeight));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Board + Eval bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -200) {
                    controller.nextMove();
                  } else if (v > 200) {
                    controller.previousMove();
                  }
                },
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: ChessBoardWidget(
                    fen: currentFen,
                    flipped: _boardFlipped,
                    lastMoveFrom: lastFrom,
                    lastMoveTo: lastTo,
                    bestMoveFrom: bestFrom,
                    bestMoveTo: bestTo,
                    showBestMoveArrow: currentMove != null &&
                        currentMove.classification != MoveClassification.best,
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),

        // Right column: Coach panel, Move strip, Control bar pinned at bottom
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Expanded(
                  child: CoachReviewWidget(
                    height: double.infinity,
                    currentMove: currentMove,
                    status: currentMove != null
                        ? (controller.explanationStatus[currentMove.plyIndex] ??
                            ExplanationStatus.waiting)
                        : ExplanationStatus.waiting,
                    explanation: currentMove != null
                        ? controller.explanations[currentMove.plyIndex]
                        : null,
                    errorMessage: currentMove != null
                        ? (controller.moveErrors[currentMove.plyIndex] ??
                            controller.geminiError)
                        : null,
                    canRetry: !controller.isInvalidKey,
                    onRetry: () {
                      if (keyMgr.hasKey && currentMove != null) {
                        controller.retryExplanation(
                            keyMgr.apiKey!, currentMove);
                      }
                    },
                    hasApiKey: keyMgr.hasKey,
                    onOpenSettings: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                    isGeminiRunning: controller.geminiRunning,
                  ),
                ),
                const SizedBox(height: 6),
                MoveStripWidget(
                  moves: controller.analysis!.moves,
                  currentPlyIndex: controller.currentPlyIndex,
                  onTapMove: (ply) => controller.goToMove(ply),
                ),
                const SizedBox(height: 6),
                AnalysisControls(
                  onFirst: () => controller.goToStart(),
                  onPrevious: () => controller.previousMove(),
                  onNext: () => controller.nextMove(),
                  onLast: () => controller.goToEnd(),
                  onFlipBoard: () =>
                      setState(() => _boardFlipped = !_boardFlipped),
                  onPreviousCritical: () => controller.previousCriticalMoment(),
                  onNextCritical: () => controller.nextCriticalMoment(),
                  onDetails: () => _openDetailsSheet(context, controller),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openDetailsSheet(BuildContext context, GameController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: Consumer<GameController>(
            builder: (ctx, ctrl, _) {
              final move = ctrl.currentMoveAnalysis;
              final gameAnalysis = ctrl.analysis;

              return DraggableScrollableSheet(
                initialChildSize: 0.70,
                minChildSize: 0.35,
                maxChildSize: 0.94,
                expand: false,
                builder: (scrollCtx, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                      border: Border(
                        top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 8),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.analytics_rounded,
                                  size: 18, color: AppTheme.primaryLight),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Engine & Move Details',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: AppTheme.textSecondary,
                                onPressed: () =>
                                    Navigator.pop(bottomSheetContext),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.surfaceBorder),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              // Engine evaluation panel
                              EnginePanel(analysis: move),
                              const SizedBox(height: 16),

                              // Evaluation trajectory graph
                              if (gameAnalysis != null &&
                                  gameAnalysis.moves.isNotEmpty) ...[
                                const Text(
                                  'Evaluation Trajectory',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                EvaluationGraphWidget(
                                  moves: gameAnalysis.moves,
                                  selectedPly: ctrl.currentPlyIndex,
                                  onTapMove: (ply) => ctrl.goToMove(ply),
                                  height: 140,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Full move list
                              if (gameAnalysis != null &&
                                  gameAnalysis.moves.isNotEmpty) ...[
                                const Text(
                                  'Full Move History',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MoveListWidget(
                                  moves: gameAnalysis.moves,
                                  selectedPly: ctrl.currentPlyIndex,
                                  onTapMove: (ply) => ctrl.goToMove(ply),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
