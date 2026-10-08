import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/config/settings_manager.dart';
import 'ai/api_key_manager.dart';
import 'screens/home/home_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global Flutter framework error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Global Flutter error: ${details.exceptionAsString()}');
    };

    // User-friendly error widget that doesn't leak raw stack traces
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: AppTheme.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected display error occurred. Please try restarting the action or navigating back.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    };

    // Load configuration/keys before starting the app.
    final apiKeyManager = ApiKeyManager();
    await apiKeyManager.load();

    final settingsManager = SettingsManager();
    await settingsManager.load();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: apiKeyManager),
          ChangeNotifierProvider.value(value: settingsManager),
        ],
        child: const ChessLensApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught asynchronous zone error: $error');
  });
}

class ChessLensApp extends StatelessWidget {
  const ChessLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
