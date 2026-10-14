import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

/// Dynamically resolves the best available Gemini Flash model for a given API key.
///
/// Discovers models via the Gemini REST API, selects the highest Flash version,
/// caches the result in [SharedPreferences] for 7 days, and provides fallback
/// options if resolution fails.
class ModelResolver {
  ModelResolver._();

  static const String _prefKeyModel = 'gemini_resolved_model';
  static const String _prefKeyTimestamp = 'gemini_resolved_model_timestamp';
  static const String _prefKeyKeyHash = 'gemini_resolved_model_key_hash';
  static const int _cacheTtlMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  /// Returns the cached model from [SharedPreferences] if valid and not expired.
  /// Performs zero network calls.
  static Future<String?> getCachedModel(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedModel = prefs.getString(_prefKeyModel);
      final timestamp = prefs.getInt(_prefKeyTimestamp);
      final cachedHash = prefs.getString(_prefKeyKeyHash);

      if (cachedModel != null &&
          cachedModel.isNotEmpty &&
          timestamp != null &&
          cachedHash == _hashKey(cleanKey)) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < _cacheTtlMs) {
          return cachedModel;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Resolves the optimal Gemini Flash model.
  ///
  /// Checks local cache first unless [forceRefresh] is true.
  /// If un-cached or expired, queries `GET {geminiBaseUrl}?key=...` with the API key,
  /// parses candidate models, and stores the highest Flash version.
  /// Falls back to [AppConfig.fallbackModels] on any failure.
  static Future<String> resolveModel({
    required String apiKey,
    http.Client? client,
    bool forceRefresh = false,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return AppConfig.fallbackModels.first;
    }

    final keyHash = _hashKey(cleanKey);

    // 1. Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = await getCachedModel(cleanKey);
      if (cached != null) {
        return cached;
      }
    }

    // 2. Query Gemini models API
    try {
      final httpClient = client ?? http.Client();
      final url = Uri.parse(
        '${AppConfig.geminiBaseUrl}?key=${Uri.encodeComponent(cleanKey)}',
      );

      final response = await httpClient.get(
        url,
        headers: {
          'x-goog-api-key': cleanKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = json['models'] as List<dynamic>? ?? [];

        const excludedKeywords = [
          'lite',
          'image',
          'tts',
          'live',
          'embedding',
          'preview',
        ];

        String? bestModel;
        double highestVersion = -1.0;

        for (final item in modelsList) {
          if (item is! Map<String, dynamic>) continue;
          final fullName = item['name']?.toString() ?? '';
          final supportedMethods =
              (item['supportedGenerationMethods'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

          // Must support generateContent
          if (!supportedMethods.contains('generateContent')) continue;

          final cleanName = fullName.startsWith('models/')
              ? fullName.substring(7)
              : fullName;
          final lower = cleanName.toLowerCase();

          // Must be a Flash model
          if (!lower.contains('flash')) continue;

          // Exclude variants like lite, image, tts, live, embedding, preview
          if (excludedKeywords.any((kw) => lower.contains(kw))) continue;

          // Parse version number (e.g. gemini-3.8-flash -> 3.8)
          final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
          final version = match != null
              ? double.tryParse(match.group(1)!) ?? 0.0
              : 0.0;

          if (version > highestVersion) {
            highestVersion = version;
            bestModel = cleanName;
          }
        }

        if (bestModel != null && bestModel.isNotEmpty) {
          // Cache successful resolution
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyModel, bestModel);
            await prefs.setInt(
              _prefKeyTimestamp,
              DateTime.now().millisecondsSinceEpoch,
            );
            await prefs.setString(_prefKeyKeyHash, keyHash);
          } catch (_) {}

          return bestModel;
        }
      }
    } catch (_) {
      // Network or API failure – fall through to fallback
    }

    // 3. Fallback to predefined models
    return AppConfig.fallbackModels.isNotEmpty
        ? AppConfig.fallbackModels.first
        : AppConfig.geminiModel;
  }

  /// Clears the cached resolved model from [SharedPreferences].
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyModel);
      await prefs.remove(_prefKeyTimestamp);
      await prefs.remove(_prefKeyKeyHash);
    } catch (_) {}
  }

  /// Generates a simple hash string for the API key to detect changes
  /// without storing the raw secret in SharedPreferences.
  static String _hashKey(String key) {
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return '${key.length}_$hash';
  }
}
