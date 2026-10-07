import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Gemini API'),
              const SizedBox(height: 16),
              _buildApiKeySection(),
              const SizedBox(height: 16),
              _buildTutorialLink(),
              const SizedBox(height: 48),

              _buildSectionTitle('Analysis Engine'),
              const SizedBox(height: 16),
              _buildEngineSettings(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Consumer<ApiKeyManager>(
      builder: (context, keyMgr, _) {
        if (!keyMgr.hasKey || _isEditingKey) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gemini AI Coach',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
                    errorText: keyMgr.validationError,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
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
                    const Spacer(),
                    ElevatedButton(
                      onPressed: keyMgr.isValidating
                          ? null
                          : () async {
                              final key = _keyController.text.trim();
                              if (key.isNotEmpty) {
                                final valid = await keyMgr.save(key);
                                if (!mounted) return;
                                if (valid) {
                                  setState(() => _isEditingKey = false);
                                  _keyController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gemini API Key verified and saved!'),
                                      backgroundColor: AppTheme.accent,
                                    ),
                                  );
                                }
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
          );
        }

        // Has key, not editing.
        final isValid = keyMgr.isValid;
        final hasError = keyMgr.validationError != null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: hasError
                  ? AppTheme.error.withOpacity(0.5)
                  : AppTheme.surfaceBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : (isValid == true
                            ? Icons.check_circle_rounded
                            : Icons.key_rounded),
                    color: hasError
                        ? AppTheme.error
                        : (isValid == true ? AppTheme.accent : AppTheme.warning),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasError
                        ? 'Key Verification Failed'
                        : (isValid == true
                            ? 'API Key Connected & Verified'
                            : 'API Key Saved'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasError
                          ? AppTheme.error
                          : (isValid == true
                              ? AppTheme.accent
                              : AppTheme.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 20),
                    onPressed: () => keyMgr.delete(),
                    tooltip: 'Delete API Key',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Key: ${keyMgr.maskedKey}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 8),
                Text(
                  keyMgr.validationError!,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _isEditingKey = true),
                    child: const Text('Change Key'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: keyMgr.isValidating
                        ? null
                        : () async {
                            final success = await keyMgr.validateKey();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
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
        );
      },
    );
  }

  Widget _buildTutorialLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Don\'t have a Gemini API key?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch this short guide on how to get your own API key for free from Google AI Studio.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.play_circle_fill_rounded,
                    color: AppTheme.primary),
                label: const Text(
                  'Watch Guide ↗',
                  style: TextStyle(color: AppTheme.primary),
                ),
                onPressed: () => _launchUrl(AppConfig.geminiTutorialUrl),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _launchUrl(AppConfig.geminiApiKeyUrl),
                child: const Text(
                  'Get Key ↗',
                  style: TextStyle(color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSettings() {
    return Consumer<SettingsManager>(
      builder: (context, settings, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            children: [
              // Engine Depth
              ListTile(
                title: const Text('Engine Depth'),
                subtitle: const Text('Higher depth means better analysis but takes longer.'),
                trailing: Text(
                  '${settings.engineDepth}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight),
                ),
              ),
              Slider(
                value: settings.engineDepth.toDouble(),
                min: 10,
                max: 24,
                divisions: 14,
                activeColor: AppTheme.primary,
                onChanged: (v) => settings.engineDepth = v.toInt(),
              ),
              const Divider(),

              // MultiPV
              ListTile(
                title: const Text('MultiPV (Lines)'),
                subtitle: const Text('Number of top moves to consider.'),
                trailing: Text(
                  '${settings.multiPv}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight),
                ),
              ),
              Slider(
                value: settings.multiPv.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppTheme.primary,
                onChanged: (v) => settings.multiPv = v.toInt(),
              ),
            ],
          ),
        );
      },
    );
  }
}
