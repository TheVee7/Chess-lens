import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/settings_manager.dart';
import '../../core/game_controller.dart';
import '../../models/chess_game.dart';
import '../../widgets/ui/ui.dart';
import 'quick_report_screen.dart';

/// Shown while Stockfish analyzes the game.
class LoadingScreen extends StatefulWidget {
  final ChessGame game;

  const LoadingScreen({super.key, required this.game});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final GameController _controller;
  bool _started = false;
  bool _transferredToReport = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
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
    if (am.result != null && !_transferredToReport) {
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
    super.dispose();
  }

  void _handleCancel() {
    _controller.cancelAnalysis();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final am = _controller.analysisManager;
    final progress = am.progress;
    final currentPly = am.currentPly;
    final totalPlies = am.totalPlies;
    final hasError = am.error != null;
    final engineDepth = context.read<SettingsManager>().engineDepth;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_transferredToReport) {
          _controller.cancelAnalysis();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(hasError ? 'Engine Error' : 'Analyzing game'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleCancel,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenMargin,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasError) ...[
                    // ── Match details caption ─────────────────────────
                    Text(
                      '${widget.game.white} vs ${widget.game.black}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Progress Ring ─────────────────────────────────
                    ProgressRing(
                      progress: progress,
                      size: 140,
                      label: totalPlies > 0
                          ? 'Move $currentPly of $totalPlies'
                          : 'Preparing Stockfish...',
                      sublabel: 'Stockfish depth $engineDepth',
                    ),
                  ] else ...[
                    // ── Error State Card ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.blunder.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(
                          color: AppTheme.blunder.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppTheme.blunder,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Stockfish engine failed to start or is unsupported on this platform architecture.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            am.error ?? 'Unknown engine error.',
                            style: GoogleFonts.inter(
                              color: AppTheme.blunder,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // ── Quiet Cancel / Go Back Text Button ────────────
                  AppTextButton(
                    label: hasError ? 'Go Back' : 'Cancel',
                    color: AppTheme.textSecondary,
                    onPressed: _handleCancel,
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
