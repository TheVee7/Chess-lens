import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/config/settings_manager.dart';
import 'ai/api_key_manager.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
}

class ChessLensApp extends StatelessWidget {
  const ChessLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // We only use dark mode as requested for rich aesthetics
      home: const HomeScreen(),
    );
  }
}
