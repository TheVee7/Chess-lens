import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/settings_manager.dart';
import '../../core/game_controller.dart';
import '../../models/chess_game.dart';
import 'quick_report_screen.dart';

/// Shown while Stockfish analyzes the game.
class LoadingScreen extends StatefulWidget {
  final ChessGame game;

  const LoadingScreen({super.key, required this.game});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final AnimationController _pulseController;
  bool _started = false;
  bool _transferredToReport = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _startAnalysis();
    }
  }

  Future<void> _startAnalysis() async {
    final settings = context.read<SettingsManager>();
    _controller.loadGame(widget.game);
    _controller.addListener(_onUpdate);

    await _controller.startAnalysis(
      depth: settings.engineDepth,
      multiPv: settings.multiPv,
    );
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});

    final am = _controller.analysisManager;
    if (am.error != null) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    } else if (am.result != null && !_transferredToReport) {
      _transferredToReport = true;
      _controller.removeListener(_onUpdate);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<GameController>.value(
            value: _controller,
            child: QuickReportScreen(
              game: widget.game,
              controller: _controller,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    if (!_transferredToReport) {
      _controller.cancelAnalysis();
      _controller.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final am = _controller.analysisManager;
    final progress = am.progress;
    final currentPly = am.currentPly;
    final totalPlies = am.totalPlies;
    final hasError = am.error != null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_transferredToReport) {
          _controller.cancelAnalysis();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated icon / Error icon ─────────────────────────────
                  if (!hasError)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _pulseController.value * 0.08,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3 + _pulseController.value * 0.2,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.memory_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.error,
                      ),
                    ),
                  const SizedBox(height: 32),

                  Text(
                    hasError ? 'Engine Error' : 'Analyzing Game',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasError ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.game.white} vs ${widget.game.black}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!hasError) ...[
                    // ── Progress bar ──────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(
                          progress < 1.0 ? AppTheme.primary : AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      totalPlies > 0
                          ? 'Move $currentPly / $totalPlies'
                          : 'Preparing Stockfish...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stockfish depth ${context.read<SettingsManager>().engineDepth}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ] else ...[
                    // ── Error container ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Stockfish engine failed to start or is unsupported on this platform architecture.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            am.error ?? 'Unknown engine error.',
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Cancel / Back button ───────────────────────
                  TextButton(
                    onPressed: () {
                      _controller.cancelAnalysis();
                      Navigator.pop(context);
                    },
                    child: Text(
                      hasError ? 'Go Back' : 'Cancel',
                      style: const TextStyle(color: AppTheme.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
