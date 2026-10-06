import 'dart:convert';
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
  final String _model;

  GeminiService({
    required this.apiKey,
    String model = AppConfig.geminiModel,
  }) : _model = model;

  // ── Public API ──────────────────────────────────────────────

  /// Explain a single move. Returns null on failure.
  Future<MoveExplanation?> explainMove(MoveAnalysis move) async {
    final prompt = GeminiPrompt.moveExplanation(move);
    final raw = await _call(prompt);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MoveExplanation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Generate an overall game review.
  Future<GameReview?> reviewGame(List<MoveAnalysis> importantMoves) async {
    final prompt = GeminiPrompt.gameReview(importantMoves);
    final raw = await _call(prompt);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return GameReview.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Quick connectivity / key validation test.
  Future<bool> testKey() async {
    try {
      final result = await _call('Respond with exactly: {"status":"ok"}');
      return result != null;
    } catch (_) {
      return false;
    }
  }

  // ── Internals ───────────────────────────────────────────────

  Future<String?> _call(String prompt) async {
    final url = Uri.parse(
      '${AppConfig.geminiBaseUrl}/$_model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '${GeminiPrompt.systemPrompt}\n\n$prompt'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
      },
    });

    try {
      final response = await http
          .post(url,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final content =
          (candidates[0] as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      String text = (parts[0] as Map<String, dynamic>)['text'] as String? ?? '';
      // Strip markdown fences if present.
      text = text
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      return text;
    } catch (_) {
      return null;
    }
  }
}
