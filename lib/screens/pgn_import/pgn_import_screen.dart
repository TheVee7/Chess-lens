import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../chess/pgn_parser.dart';
import '../../models/chess_game.dart';
import '../quick_report/loading_screen.dart';

class PgnImportScreen extends StatefulWidget {
  const PgnImportScreen({super.key});

  @override
  State<PgnImportScreen> createState() => _PgnImportScreenState();
}

class _PgnImportScreenState extends State<PgnImportScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasContent = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final pgn = _controller.text.trim();
    final validationError = PgnParser.validate(pgn);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final game = PgnParser.parse(pgn);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingScreen(game: game),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import PGN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Instructions ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Paste a complete PGN game below to start analysis.',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryLight,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── PGN input ───────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _error != null
                          ? AppTheme.error.withOpacity(0.5)
                          : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          '[Event "Casual Game"]\n[White "Player"]\n[Black "Opponent"]\n\n1. e4 e5 2. Nf3 Nc6 ...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: AppTheme.textTertiary.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),

              // ── Error ───────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Buttons ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      label: const Text('Clear'),
                      onPressed: _hasContent ? _clear : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: _hasContent
                          ? BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            )
                          : null,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_rounded, size: 20),
                        label: const Text('Analyze Game'),
                        style: _hasContent
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              )
                            : null,
                        onPressed: _hasContent ? _analyze : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
