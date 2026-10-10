import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../core/theme/app_theme.dart';
import '../../ai/api_key_manager.dart';
import '../../widgets/ui/ui.dart';
import '../pgn_import/pgn_import_screen.dart';
import '../settings/settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenMargin,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo mark + wordmark
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.center_focus_strong_rounded,
                              size: 18,
                              color: AppTheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'ChessLens',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Settings icon button
                  AppIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Hero Card ───────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review any game',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stockfish checks the moves. Gemini explains them.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Analyze a game',
                      showTrailingArrow: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PgnImportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.tileGap),

              // ── Two tiles: AI Coach & Engine (Responsive row/col) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 340;

                  final aiTile = Consumer<ApiKeyManager>(
                    builder: (context, keyMgr, _) {
                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        onTap: !keyMgr.hasKey
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'AI coach',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: keyMgr.hasKey
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StatusChip(
                              label: keyMgr.hasKey ? 'Connected' : 'No API key',
                              variant: keyMgr.hasKey
                                  ? StatusChipVariant.connected
                                  : StatusChipVariant.warning,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              keyMgr.hasKey
                                  ? 'Coach explanations enabled'
                                  : 'Add your key in Settings for coach explanations',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  final engineTile = AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Engine',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.memory_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const StatusChip(
                          label: 'Offline',
                          variant: StatusChipVariant.connected,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Stockfish, runs offline on your phone',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        aiTile,
                        const SizedBox(height: AppTheme.tileGap),
                        engineTile,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: aiTile),
                      const SizedBox(width: AppTheme.tileGap),
                      Expanded(child: engineTile),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTheme.tileGap),

              // ── One wide tile: Game Report ──────────────────────────
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusInner),
                        border: Border.all(
                          color: AppTheme.border,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.insights_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Game report',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy, move quality and an evaluation graph.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
