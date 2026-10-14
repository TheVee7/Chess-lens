import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/config/settings_manager.dart';
import '../../ai/api_key_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _isEditingKey = false;
  bool? _isCustomTimeActive;

  bool _isPreset(int ms) =>
      ms == AppConfig.quickAnalysisTimeMs ||
      ms == AppConfig.balancedAnalysisTimeMs ||
      ms == AppConfig.thoroughAnalysisTimeMs;

  bool _customActive(SettingsManager settings) =>
      _isCustomTimeActive ?? !_isPreset(settings.analysisTimeMs);

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ───────────────────────── Shared building blocks ─────────────────────────

  Widget _card({required Widget child, Color? borderColor, Color? color}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor ?? AppTheme.surfaceBorder),
      ),
      child: child,
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: AppTheme.surfaceBorder,
  );

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Title + description on the left, current value badge on the right.
  Widget _settingHeader({
    required String title,
    required String description,
    required String value,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (extra != null) extra,
              ],
            ),
          ),
          const SizedBox(width: 12),
          _badge(value),
        ],
      ),
    );
  }

  /// Single selectable pill used by every chip row on this screen.
  Widget _choiceTile({
    required String label,
    String? sub,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryContainer
                  : AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMs(int ms) {
    if (ms >= 1000) {
      return '${ms ~/ 1000},${(ms % 1000).toString().padLeft(3, '0')} ms';
    }
    return '$ms ms';
  }

  // ─────────────────────────────────── Build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Gemini API', Icons.auto_awesome_rounded),
              const SizedBox(height: 12),
              _buildApiKeySection(),
              const SizedBox(height: 12),
              _buildTutorialLink(),
              const SizedBox(height: 32),

              _buildSectionTitle('Engine & Performance', Icons.speed_rounded),
              const SizedBox(height: 12),
              _buildEngineSettings(),
              const SizedBox(height: 32),

              _buildSectionTitle('About & Legal', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildAboutSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────── API key ────────────────────────────────

  Widget _buildApiKeySection() {
    return Consumer<ApiKeyManager>(
      builder: (context, keyMgr, _) {
        if (!keyMgr.hasKey || _isEditingKey) {
          return _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini AI Coach',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add your Gemini API key to enable human-level explanations of your game.\n\nYour API key is stored locally on this device and is used directly for Gemini requests.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                      errorText: keyMgr.validationError,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_isEditingKey && keyMgr.hasKey)
                        TextButton(
                          onPressed: keyMgr.isValidating
                              ? null
                              : () {
                                  setState(() => _isEditingKey = false);
                                  _keyController.clear();
                                },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 44),
                        ),
                        onPressed: keyMgr.isValidating
                            ? null
                            : () async {
                                final key = _keyController.text.trim();
                                if (key.isEmpty) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final valid = await keyMgr.save(key);
                                if (!mounted) return;
                                if (valid) {
                                  setState(() => _isEditingKey = false);
                                  _keyController.clear();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gemini API Key verified and saved!',
                                      ),
                                      backgroundColor: AppTheme.accent,
                                    ),
                                  );
                                }
                              },
                        child: keyMgr.isValidating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save & Verify Key'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Has key, not editing.
        final isValid = keyMgr.isValid;
        final hasError = keyMgr.validationError != null;
        final statusColor = hasError
            ? AppTheme.error
            : (isValid == true ? AppTheme.accent : AppTheme.warning);

        return _card(
          borderColor: hasError
              ? AppTheme.error.withValues(alpha: 0.5)
              : AppTheme.surfaceBorder,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasError
                            ? Icons.error_outline_rounded
                            : (isValid == true
                                  ? Icons.check_circle_rounded
                                  : Icons.key_rounded),
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasError
                            ? 'Key Verification Failed'
                            : (isValid == true
                                  ? 'API Key Connected & Verified'
                                  : 'API Key Saved'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: hasError || isValid == true
                              ? statusColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      onPressed: () => keyMgr.delete(),
                      tooltip: 'Delete API Key',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    keyMgr.maskedKey,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    keyMgr.validationError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditingKey = true),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change Key'),
                    ),
                    OutlinedButton.icon(
                      onPressed: keyMgr.isValidating
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await keyMgr.validateKey();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Connection successful! Gemini is ready.'
                                        : (keyMgr.validationError ??
                                              'Failed to connect to Gemini.'),
                                  ),
                                  backgroundColor: success
                                      ? AppTheme.accent
                                      : AppTheme.error,
                                ),
                              );
                            },
                      icon: keyMgr.isValidating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Test Connection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialLink() {
    return _card(
      color: AppTheme.primary.withValues(alpha: 0.05),
      borderColor: AppTheme.primary.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: AppTheme.primaryLight,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Don't have a Gemini API key?",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Watch this short guide on how to get your own API key for free from Google AI Studio.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  label: const Text(
                    'Watch Guide ↗',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                  onPressed: () => _launchUrl(AppConfig.geminiTutorialUrl),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppTheme.primaryLight,
                    size: 18,
                  ),
                  label: const Text(
                    'Get Key ↗',
                    style: TextStyle(color: AppTheme.primaryLight),
                  ),
                  onPressed: () => _launchUrl(AppConfig.geminiApiKeyUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────── Engine ─────────────────────────────────

  Widget _buildEngineSettings() {
    return Consumer<SettingsManager>(
      builder: (context, settings, _) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analysis time
              _settingHeader(
                title: 'Analysis Time per Position',
                description:
                    'Controls how long Stockfish searches each position. Longer searches may improve analysis but take more time.',
                value: _formatMs(settings.analysisTimeMs),
              ),
              _buildTimePresets(settings),
              _buildCustomTimeDial(settings),
              const SizedBox(height: 8),
              _divider(),

              // MultiPV
              _settingHeader(
                title: 'MultiPV (Lines)',
                description: 'Number of top moves to consider.',
                value: '${settings.multiPv}',
              ),
              Slider(
                value: settings.multiPv.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${settings.multiPv}',
                activeColor: AppTheme.primary,
                onChanged: (v) => settings.multiPv = v.toInt(),
              ),
              _divider(),

              // Hash memory
              _settingHeader(
                title: 'Hash Memory',
                description:
                    'Stores previously searched positions to improve search efficiency. Higher values consume more memory and do not guarantee faster analysis.',
                value: '${settings.hashMemory} MB',
              ),
              _buildOptionSelector(
                options: AppConfig.hashOptions,
                selectedValue: settings.hashMemory,
                labelBuilder: (v) => '$v MB',
                onSelected: (v) => settings.hashMemory = v,
              ),
              _divider(),

              // CPU threads
              _settingHeader(
                title: 'CPU Threads',
                description:
                    'More threads may improve analysis speed but increase CPU load and battery consumption.',
                value: '${settings.cpuThreads}',
                extra: settings.cpuThreads > settings.deviceCores
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Selected threads (${settings.cpuThreads}) exceed detected CPU cores (${settings.deviceCores}).',
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              _buildOptionSelector(
                options: AppConfig.threadOptions,
                selectedValue: settings.cpuThreads,
                labelBuilder: (v) => v == 1 ? '1 Thread' : '$v Threads',
                onSelected: (v) => settings.cpuThreads = v,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionSelector({
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
    required String Function(int) labelBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 16),
      child: Row(
        children: options
            .map(
              (option) => _choiceTile(
                label: labelBuilder(option),
                selected: option == selectedValue,
                onTap: () => onSelected(option),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimePresets(SettingsManager settings) {
    final customActive = _customActive(settings);
    final presets = [
      (label: 'Quick', ms: AppConfig.quickAnalysisTimeMs),
      (label: 'Balanced', ms: AppConfig.balancedAnalysisTimeMs),
      (label: 'Thorough', ms: AppConfig.thoroughAnalysisTimeMs),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
      child: Row(
        children: [
          for (final preset in presets)
            _choiceTile(
              label: preset.label,
              sub: _formatMs(preset.ms),
              selected: !customActive && settings.analysisTimeMs == preset.ms,
              onTap: () {
                setState(() => _isCustomTimeActive = false);
                settings.analysisTimeMs = preset.ms;
              },
            ),
          _choiceTile(
            label: 'Custom',
            sub: customActive ? _formatMs(settings.analysisTimeMs) : '100-2000',
            selected: customActive,
            onTap: () {
              setState(() => _isCustomTimeActive = true);
              if (_isPreset(settings.analysisTimeMs)) {
                settings.analysisTimeMs = 500;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTimeDial(SettingsManager settings) {
    final customActive = _customActive(settings);
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: customActive
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Search Time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: settings.analysisTimeMs
                          .clamp(100, 2000)
                          .toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 38,
                      label: _formatMs(settings.analysisTimeMs),
                      activeColor: AppTheme.primary,
                      onChanged: (v) => settings.analysisTimeMs = v.toInt(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '100 ms (Fast)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '2,000 ms (Deep)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ───────────────────────────────── About ──────────────────────────────────

  Widget _buildAboutSection() {
    return _card(
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          leading: const Icon(
            Icons.description_outlined,
            color: AppTheme.primaryLight,
          ),
          title: const Text('Open Source Licenses'),
          subtitle: const Text('ChessLens, Stockfish (GPL-3.0), and libraries'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'ChessLens',
              applicationVersion: '0.1.0',
              applicationLegalese:
                  'Copyright (c) 2024-2026 ChessLens Contributors.\nDistributed under the GNU General Public License v3.0 (GPL-3.0).\nBundles Stockfish chess engine under GPL-3.0.',
            );
          },
        ),
      ),
    );
  }
}