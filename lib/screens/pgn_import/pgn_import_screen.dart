import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../chess/pgn_parser.dart';
import '../../widgets/ui/ui.dart';
import '../quick_report/loading_screen.dart';

/// Screen allowing the user to paste PGN text and import a game.
class PgnImportScreen extends StatefulWidget {
  final String? initialPgn;

  const PgnImportScreen({super.key, this.initialPgn});

  @override
  State<PgnImportScreen> createState() => _PgnImportScreenState();
}

class _PgnImportScreenState extends State<PgnImportScreen> {
  late final TextEditingController _controller;
  bool _hasContent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPgn);
    _hasContent = _controller.text.trim().isNotEmpty;

    _controller.addListener(() {
      final hasNow = _controller.text.trim().isNotEmpty;
      if (hasNow != _hasContent) {
        setState(() {
          _hasContent = hasNow;
        });
      }
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

    try {
      final game = PgnParser.parse(pgn);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(game: game),
        ),
      );
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not parse PGN: $e');
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve room for padding, error, buttons, and appbar
            final availableHeight = constraints.maxHeight;
            final textFieldHeight = (availableHeight - 170).clamp(160.0, 460.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.screenMargin),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppTheme.screenMargin * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Large Card with PGN input ───────────────────────
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paste your PGN here',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: textFieldHeight,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceRaised,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusInner),
                                border: Border.all(
                                  color: _error != null
                                      ? AppTheme.blunder.withValues(alpha: 0.5)
                                      : AppTheme.border,
                                  width: 1,
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
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.5),
                                    fontSize: 13,
                                  ),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Red-tinted Error Card ───────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.blunder.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusInner),
                            border: Border.all(
                              color: AppTheme.blunder.withValues(alpha: 0.30),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.blunder,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.blunder,
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 16),

                      // ── Action Buttons ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SecondaryButton(
                              label: 'Clear',
                              onPressed: _hasContent ? _clear : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: PrimaryButton(
                              label: 'Analyze game',
                              showTrailingArrow: true,
                              onPressed: _hasContent ? _analyze : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
