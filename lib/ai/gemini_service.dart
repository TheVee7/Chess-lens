import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../models/move_analysis.dart';
import '../models/game_explanation.dart';
import 'gemini_prompt.dart';

/// Service that calls the Gemini REST API with the user's own key.
///
/// No ChessLens backend involved – all calls go directly from the device.
class GeminiService {
  final String apiKey;
  String _model;

  /// Models to try in order of preference.
  static const List<String> availableModels = [
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  String? lastError;

  GeminiService({
    required this.apiKey,
    String? model,
  }) : _model = model ?? AppConfig.geminiModel;

  String get currentModel => _model;

  // ── Public API ──────────────────────────────────────────────

  /// Explain a single move. Returns null on failure.
  Future<MoveExplanation?> explainMove(MoveAnalysis move) async {
    lastError = null;
    final prompt = GeminiPrompt.moveExplanation(move);
    final raw = await _call(prompt);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MoveExplanation.fromJson(json);
    } catch (e) {
      lastError = 'Failed to parse explanation: $e';
      debugPrint('ChessLens Gemini parse error: $e | Raw: $raw');
      return null;
    }
  }

  /// Generate an overall game review.
  Future<GameReview?> reviewGame(List<MoveAnalysis> importantMoves) async {
    lastError = null;
    final prompt = GeminiPrompt.gameReview(importantMoves);
    final raw = await _call(prompt);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return GameReview.fromJson(json);
    } catch (e) {
      lastError = 'Failed to parse review: $e';
      debugPrint('ChessLens Gemini review parse error: $e | Raw: $raw');
      return null;
    }
  }

  /// Quick connectivity / key validation test.
  /// Returns null on success, or an error description string on failure.
  Future<String?> testKeyWithError() async {
    final result = await _call('Respond with JSON: {"status":"ok"}', isTest: true);
    if (result != null) return null;
    return lastError ?? 'Failed to communicate with Gemini API';
  }

  /// Quick connectivity test boolean.
  Future<bool> testKey() async {
    final err = await testKeyWithError();
    return err == null;
  }

  // ── Internals ───────────────────────────────────────────────

  Future<String?> _call(String prompt, {bool isTest = false}) async {
    // Try preferred model, fallback to others if needed (e.g. 404 or unsupported model)
    final modelsToTry = [
      _model,
      ...availableModels.where((m) => m != _model),
    ];

    for (final model in modelsToTry) {
      final result = await _executeRequest(model, prompt, isTest: isTest);
      if (result != null) {
        _model = model;
        return result;
      }
    }
    return null;
  }

  Future<String?> _executeRequest(String model, String prompt, {bool isTest = false}) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      lastError = 'Gemini API key is empty';
      return null;
    }

    final url = Uri.parse(
      '${AppConfig.geminiBaseUrl}/$model:generateContent?key=$cleanKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': isTest ? prompt : '${GeminiPrompt.systemPrompt}\n\n$prompt'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        String msg = 'Gemini HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errJson['error'] is Map) {
            final errObj = errJson['error'] as Map<String, dynamic>;
            final message = errObj['message']?.toString() ?? '';
            final status = errObj['status']?.toString() ?? '';
            if (response.statusCode == 400 && message.toLowerCase().contains('api key')) {
              msg = 'Invalid API key. Please check your key in Google AI Studio.';
            } else if (response.statusCode == 403) {
              msg = 'Access forbidden (403): $message';
            } else if (response.statusCode == 429) {
              msg = 'Quota exceeded (429): Free tier limit reached. Please wait a moment.';
            } else if (response.statusCode == 404) {
              msg = 'Model $model not found (404).';
            } else {
              msg = message.isNotEmpty ? message : 'API Error ($status)';
            }
          }
        } catch (_) {
          msg = 'Server returned HTTP ${response.statusCode}';
        }
        lastError = msg;
        debugPrint('ChessLens Gemini API Error [$model]: $msg\nResponse: ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        lastError = 'No response candidates returned by Gemini';
        return null;
      }

      final content =
          (candidates[0] as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
      if (content == null) {
        lastError = 'Empty content returned by Gemini';
        return null;
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        lastError = 'Empty parts in Gemini response';
        return null;
      }

      String text = (parts[0] as Map<String, dynamic>)['text'] as String? ?? '';
      return _extractJson(text);
    } catch (e) {
      lastError = 'Connection failed: $e';
      debugPrint('ChessLens Gemini Connection Error [$model]: $e');
      return null;
    }
  }

  static String _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
  }
}
