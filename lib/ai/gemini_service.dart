import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../models/move_analysis.dart';
import '../models/game_explanation.dart';
import 'gemini_prompt.dart';

/// Categories of Gemini API failures.
enum GeminiErrorType {
  invalidKey,
  rateLimited,
  network,
  blocked,
  badResponse,
  server,
  unknown,
}

/// Detailed error describing why a Gemini request failed.
class GeminiError {
  final GeminiErrorType type;
  final String message;
  final int? statusCode;

  const GeminiError({
    required this.type,
    required this.message,
    this.statusCode,
  });

  String get description {
    switch (type) {
      case GeminiErrorType.invalidKey:
        return 'Invalid API key (400/403). Please verify your key in Google AI Studio.';
      case GeminiErrorType.rateLimited:
        return 'Rate limit exceeded (429). Free-tier quota reached. Please wait a moment.';
      case GeminiErrorType.network:
        return 'Network connection error. Check your internet connection.';
      case GeminiErrorType.blocked:
        return 'Response blocked by safety filters or no candidates returned.';
      case GeminiErrorType.badResponse:
        return 'Malformed response format received from model.';
      case GeminiErrorType.server:
        return 'Gemini server error (${statusCode ?? '5xx'}). Please retry shortly.';
      case GeminiErrorType.unknown:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  @override
  String toString() => 'GeminiError($type, $message)';
}

/// Result type for Gemini API operations.
sealed class GeminiResult<T> {
  const GeminiResult();
}

class Success<T> extends GeminiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends GeminiResult<T> {
  final GeminiError error;
  const Failure(this.error);
}

/// Service that calls the Gemini REST API with the user's own key.
/// All calls go directly from device to Google APIs without any intermediate backend.
class GeminiService {
  final String apiKey;
  final String model;
  final http.Client _client;

  String? lastError;

  GeminiService({
    required this.apiKey,
    String? model,
    http.Client? client,
  })  : model = model ?? AppConfig.geminiModel,
        _client = client ?? http.Client();

  String get currentModel => model;

  // ── Public API ──────────────────────────────────────────────

  /// Explain a single move with structured GeminiResult.
  Future<GeminiResult<MoveExplanation>> explainMoveResult(MoveAnalysis move) async {
    lastError = null;
    final prompt = GeminiPrompt.moveExplanation(move);
    final callResult = await _call(prompt);

    switch (callResult) {
      case Success<String>(:final data):
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final explanation = MoveExplanation.fromJson(json);
          return Success(explanation);
        } catch (e) {
          final err = GeminiError(
            type: GeminiErrorType.badResponse,
            message: 'Failed to parse move explanation JSON: $e',
          );
          lastError = err.description;
          return Failure(err);
        }
      case Failure<String>(:final error):
        lastError = error.description;
        return Failure(error);
    }
  }

  /// Explain a single move. Returns null on failure for simple callers.
  Future<MoveExplanation?> explainMove(MoveAnalysis move) async {
    final result = await explainMoveResult(move);
    return switch (result) {
      Success(:final data) => data,
      Failure() => null,
    };
  }

  /// Generate an overall game review with structured GeminiResult.
  Future<GeminiResult<GameReview>> reviewGameResult(List<MoveAnalysis> importantMoves) async {
    lastError = null;
    final prompt = GeminiPrompt.gameReview(importantMoves);
    final callResult = await _call(prompt);

    switch (callResult) {
      case Success<String>(:final data):
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final review = GameReview.fromJson(json);
          return Success(review);
        } catch (e) {
          final err = GeminiError(
            type: GeminiErrorType.badResponse,
            message: 'Failed to parse game review JSON: $e',
          );
          lastError = err.description;
          return Failure(err);
        }
      case Failure<String>(:final error):
        lastError = error.description;
        return Failure(error);
    }
  }

  /// Generate an overall game review. Returns null on failure for simple callers.
  Future<GameReview?> reviewGame(List<MoveAnalysis> importantMoves) async {
    final result = await reviewGameResult(importantMoves);
    return switch (result) {
      Success(:final data) => data,
      Failure() => null,
    };
  }

  /// Detailed connectivity and key validation test.
  Future<GeminiResult<bool>> testKeyResult() async {
    final result = await _call('Respond with JSON: {"status":"ok"}', isTest: true);
    return switch (result) {
      Success() => const Success(true),
      Failure(:final error) => Failure(error),
    };
  }

  /// Quick connectivity / key validation test.
  /// Returns null on success, or an error description string on failure.
  Future<String?> testKeyWithError() async {
    final result = await testKeyResult();
    return switch (result) {
      Success() => null,
      Failure(:final error) => error.description,
    };
  }

  /// Quick connectivity test boolean.
  Future<bool> testKey() async {
    final result = await testKeyResult();
    return result is Success<bool>;
  }

  // ── Internals ───────────────────────────────────────────────

  Future<GeminiResult<String>> _call(String prompt, {bool isTest = false}) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return const Failure(GeminiError(
        type: GeminiErrorType.invalidKey,
        message: 'Gemini API key is empty',
      ));
    }

    final url = Uri.parse('${AppConfig.geminiBaseUrl}/$model:generateContent');

    final body = jsonEncode({
      if (!isTest)
        'systemInstruction': {
          'parts': [
            {'text': GeminiPrompt.systemPrompt}
          ]
        },
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    });

    const maxTries = 3;
    GeminiError? lastError;

    for (int attempt = 1; attempt <= maxTries; attempt++) {
      try {
        final response = await _client
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': cleanKey,
              },
              body: body,
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          try {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = json['candidates'] as List<dynamic>?;
            if (candidates == null || candidates.isEmpty) {
              return const Failure(GeminiError(
                type: GeminiErrorType.blocked,
                message: 'No candidates returned (response may be blocked by safety filters)',
                statusCode: 200,
              ));
            }

            final content =
                (candidates[0] as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts == null || parts.isEmpty) {
              return const Failure(GeminiError(
                type: GeminiErrorType.blocked,
                message: 'Empty content parts returned by Gemini',
                statusCode: 200,
              ));
            }

            final text = (parts[0] as Map<String, dynamic>)['text'] as String? ?? '';
            final jsonStr = _extractJson(text);
            return Success(jsonStr);
          } catch (e) {
            return Failure(GeminiError(
              type: GeminiErrorType.badResponse,
              message: 'Failed to parse JSON response: $e',
              statusCode: 200,
            ));
          }
        }

        final statusCode = response.statusCode;
        String errorMessage = 'HTTP $statusCode';
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errJson['error'] is Map) {
            final errObj = errJson['error'] as Map<String, dynamic>;
            errorMessage = errObj['message']?.toString() ?? errorMessage;
          }
        } catch (_) {}

        if (statusCode == 400 || statusCode == 403) {
          return Failure(GeminiError(
            type: GeminiErrorType.invalidKey,
            message: errorMessage,
            statusCode: statusCode,
          ));
        } else if (statusCode == 429) {
          lastError = GeminiError(
            type: GeminiErrorType.rateLimited,
            message: errorMessage,
            statusCode: statusCode,
          );
        } else if (statusCode >= 500) {
          lastError = GeminiError(
            type: GeminiErrorType.server,
            message: errorMessage,
            statusCode: statusCode,
          );
        } else {
          return Failure(GeminiError(
            type: GeminiErrorType.unknown,
            message: errorMessage,
            statusCode: statusCode,
          ));
        }
      } catch (e) {
        lastError = GeminiError(
          type: GeminiErrorType.network,
          message: 'Connection failed: $e',
        );
      }

      // Retry with exponential backoff on retryable errors
      if (attempt < maxTries &&
          (lastError.type == GeminiErrorType.rateLimited ||
              lastError.type == GeminiErrorType.server ||
              lastError.type == GeminiErrorType.network)) {
        final backoffMs = 400 * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: backoffMs));
      } else {
        break;
      }
    }

    return Failure(lastError ??
        const GeminiError(
          type: GeminiErrorType.unknown,
          message: 'Unknown error occurred',
        ));
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
