import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../ai/api_key_manager.dart';
import '../../widgets/chess_board/chess_board_widget.dart';
import '../pgn_import/pgn_import_screen.dart';
import '../settings/settings_screen.dart';

/// All Home copy, links and the sample game live here. Edit freely.
class _HomeCopy {
  static const headlineTop = 'Understand\nyour games,\n';
  static const headlineAccent = 'improve faster.';
  static const subline =
      'Get the turning points, an accuracy breakdown, and a coach that explains your mistakes in plain English.';

  static const ctaTitle = 'Analyze a Game';
  static const ctaSubtitle = 'Paste a PGN or share one into ChessLens';

  static const howTitle = 'How it works';
  static const steps = <_Step>[
    _Step(Icons.description_outlined, 'Import a game',
        'Paste your PGN or share one from another app.'),
    _Step(Icons.search_rounded, 'Get instant analysis',
        'Powered by Stockfish for accurate insights.'),
    _Step(Icons.bar_chart_rounded, 'Improve your play',
        'See accuracy, mistakes and key lessons.'),
  ];

  static const exampleTitle = 'Example Analysis';
  static const exampleLink = 'View example';
  static const exampleCardTitle = "See what you'll get";
  static const exampleCardText =
      'Open a sample game with move suggestions, accuracy and key takeaways.';

  static const exampleFen =
      'rnbqk2r/pppp1Qpp/5n2/2b1p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4';

  static const samplePgn = '''[Event "Live Chess"]
[Site "Chess.com"]
[Date "2026.10.07"]
[Round "?"]
[White "veeSharma"]
[Black "prakharshukla20170"]
[Result "1-0"]
[TimeControl "600"]
[WhiteElo "529"]
[BlackElo "357"]
[Termination "veeSharma won by checkmate"]
[ECO "C20"]
[EndTime "13:39:37 GMT+0000"]
[Link "https://www.chess.com/game/live/184955771052?username=veesharma"]

1. e4 e5 2. Bc4 Bc5 3. Qh5 Nf6 4. Qxf7# 1-0
''';

  static const creatorName = 'Vee';
  static const creatorLine = 'Open source. Free to use.';
  static const githubProfileUrl = 'https://github.com/TheVee7';
  static const linkedinUrl =
      'https://www.linkedin.com/in/varun-dev-sharma-b88260259/';
  static const repoUrl = 'https://github.com/TheVee7/Chess-lens';
  static const issuesUrl = 'https://github.com/TheVee7/Chess-lens/issues';
  static const credit = 'Powered by Stockfish. Coached by Gemini.';
}

class _Step {
  final IconData icon;
  final String title;
  final String text;
  const _Step(this.icon, this.title, this.text);
}

/// Colors for this screen, sampled from the reference design.
class _HomeColors {
  static const bg = Color(0xFF0B1312);
  static const card = Color(0xFF141D1D);
  static const cardBorder = Color(0xFF1E2829);
  static const iconTile = Color(0xFF1E2828);
  static const accent = Color(0xFF74BD6F);
  static const badge = Color(0xFF63AC6E);
  static const ctaTop = Color(0xFF528A54);
  static const ctaBottom = Color(0xFF2A5E3B);
  static const ctaIconTile = Color(0xFF71B76D);
  static const amber = Color(0xFFFBC654);
  static const orange = Color(0xFFF48C63);
}

const String _heroAsset = 'assets/hero.webp';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // For sharing or opening when app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening when app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final file = files.first;
    String pgnContent = '';

    if (file.type == SharedMediaType.text) {
      pgnContent = file.path;
    } else if (file.type == SharedMediaType.file &&
        file.path.toLowerCase().endsWith('.pgn')) {
      try {
        pgnContent = await File(file.path).readAsString();
      } catch (e) {
        debugPrint("Error reading PGN file: $e");
      }
    } else {
      // It's an image or other unhandled type for now.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Received unhandled file type: ${file.type.name}'),
        ),
      );
      return;
    }

    if (pgnContent.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PgnImportScreen(initialPgn: pgnContent),
        ),
      );
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  // ── Navigation / link helpers ───────────────────────────────────────────

  void _openImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PgnImportScreen()),
    );
  }

  void _openExample() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PgnImportScreen(initialPgn: _HomeCopy.samplePgn),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _openUrl(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open $url: $e');
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the link")),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomeColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenMargin,
            vertical: 12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bigText = MediaQuery.textScalerOf(context).scale(1.0) > 1.25;
              final narrow = width < 340 || bigText;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildHero(width),
                  const SizedBox(height: 20),
                  _buildCta(),
                  const SizedBox(height: 12),
                  _buildQuickTiles(),
                  const SizedBox(height: 32),
                  _SectionHeader(title: _HomeCopy.howTitle),
                  const SizedBox(height: 14),
                  _buildSteps(narrow),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: _HomeCopy.exampleTitle,
                    actionLabel: _HomeCopy.exampleLink,
                    onAction: _openExample,
                  ),
                  const SizedBox(height: 14),
                  _buildExampleCard(),
                  const SizedBox(height: 36),
                  _buildFooter(),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Chess',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'Lens',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: _HomeColors.accent,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _openSettings,
          iconSize: 26,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(
            Icons.settings_outlined,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHero(double width) {
    final compact = width < 340;
    final img = width * (compact ? 0.68 : 0.74);
    final headSize = compact ? 29.0 : (width < 380 ? 32.0 : 34.0);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, minHeight: img * 0.88),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Mascot, shifted to the right to leave space from text.
          Positioned(
            right: -img * 0.22,
            top: -img * 0.04,
            width: img,
            height: img,
            child: ExcludeSemantics(
              child: Image.asset(
                _heroAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.62),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _HomeCopy.headlineTop,
                          style: GoogleFonts.inter(
                            fontSize: headSize,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: _HomeCopy.headlineAccent,
                          style: GoogleFonts.inter(
                            fontSize: headSize,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: _HomeColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.62),
                  child: Text(
                    _HomeCopy.subline,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    return Semantics(
      button: true,
      label: '${_HomeCopy.ctaTitle}. ${_HomeCopy.ctaSubtitle}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_HomeColors.ctaTop, _HomeColors.ctaBottom],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _openImport,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _HomeColors.ctaIconTile,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _HomeCopy.ctaTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _HomeCopy.ctaSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTiles() {
    return Consumer<ApiKeyManager>(
      builder: (context, keyMgr, _) {
        final String subtitle;
        final Color color;
        if (keyMgr.isValidating) {
          subtitle = 'Checking key...';
          color = AppTheme.textSecondary;
        } else if (keyMgr.hasKey && keyMgr.isValid != false) {
          subtitle = 'Connected';
          color = _HomeColors.accent;
        } else if (keyMgr.hasKey) {
          subtitle = 'Key rejected';
          color = _HomeColors.orange;
        } else {
          subtitle = 'Add Gemini key';
          color = _HomeColors.amber;
        }
        return _ActionTile(
          icon: Icons.auto_awesome_outlined,
          title: 'AI coach',
          subtitle: subtitle,
          subtitleColor: color,
          onTap: _openSettings,
        );
      },
    );
  }

  Widget _buildSteps(bool narrow) {
    final steps = _HomeCopy.steps;
    if (narrow) {
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepRow(index: i + 1, step: steps[i]),
            if (i != steps.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(child: _StepCard(index: i + 1, step: steps[i])),
            if (i != steps.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleCard() {
    return _SurfaceCard(
      onTap: _openExample,
      semanticLabel:
          '${_HomeCopy.exampleCardTitle}. ${_HomeCopy.exampleCardText}',
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 112,
              height: 112,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ChessBoardWidget(
                    fen: _HomeCopy.exampleFen,
                    flipped: false,
                    lastMoveFrom: 'h5',
                    lastMoveTo: 'f7',
                    showBestMoveArrow: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _HomeCopy.exampleCardTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _HomeCopy.exampleCardText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 26,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: _HomeColors.cardBorder),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Built by ${_HomeCopy.creatorName}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              _HomeCopy.creatorLine,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: [
            _FooterLink(
              label: 'GitHub profile',
              external: true,
              onTap: () => _openUrl(_HomeCopy.githubProfileUrl),
            ),
            _FooterLink(
              label: 'Source code',
              external: true,
              onTap: () => _openUrl(_HomeCopy.repoUrl),
            ),
            _FooterLink(
              label: 'Report an issue',
              external: true,
              onTap: () => _openUrl(_HomeCopy.issuesUrl),
            ),
            _FooterLink(
              label: 'LinkedIn',
              external: true,
              onTap: () => _openUrl(_HomeCopy.linkedinUrl),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _HomeCopy.credit,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Small private widgets ────────────────────────────────────────────────

/// Rounded dark card with a hairline border and an optional tap action.
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: _HomeColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _HomeColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: card,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _HomeColors.iconTile,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.3,
                    color: subtitleColor ?? AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final _Step step;
  const _StepCard({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberBadge(index),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _HomeColors.iconTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, size: 20, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Used instead of `_StepCard` on narrow screens or with large text.
class _StepRow extends StatelessWidget {
  final int index;
  final _Step step;
  const _StepRow({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumberBadge(index),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _HomeColors.iconTile,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(step.icon, size: 20, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.text,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge(this.number);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _HomeColors.badge,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0B1312),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _HomeColors.accent,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.only(left: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final bool external;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.external,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (external) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.north_east_rounded,
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}