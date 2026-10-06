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

    if (_controller.analysisManager.result != null) {
      _controller.removeListener(_onUpdate);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<GameController>.value(
            value: _controller,
            child: QuickReportScreen(game: widget.game),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final am = _controller.analysisManager;
    final progress = am.progress;
    final currentPly = am.currentPly;
    final totalPlies = am.totalPlies;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated icon ─────────────────────────────
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
                              color: AppTheme.primary
                                  .withOpacity(0.3 + _pulseController.value * 0.2),
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
                ),
                const SizedBox(height: 32),

                Text(
                  'Analyzing Game',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
                      : 'Preparing...',
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

                if (am.error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      am.error!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Cancel ────────────────────────────────────
                TextButton(
                  onPressed: () {
                    _controller.cancelAnalysis();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
