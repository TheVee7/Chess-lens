import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:chess_lens/ai/gemini_service.dart';
import 'package:chess_lens/models/move_analysis.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

MoveAnalysis _dummyMove() {
  return const MoveAnalysis(
    plyIndex: 4,
    moveNumber: 3,
    isWhite: true,
    san: 'd4',
    fenBefore: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
    fenAfter: 'rnbqkbnr/pppp1ppp/8/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq - 0 3',
    evalBefore: 30.0,
    evalAfter: 200.0,
    evalLoss: 170.0,
    classification: MoveClassification.mistake,
    bestMoveSan: 'Bc4',
    bestMoveUci: 'f1c4',
    pv: ['Bc4', 'Nc6'],
  );
}

void main() {
  group('GeminiService', () {
    test('successful 200 OK response returns Success with MoveExplanation', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'explanation': 'Pushing d4 too early allowed Black to equalize immediately.',
                    'betterMove': 'Bc4 develops with tempo on the weak f7 square.',
                    'lesson': 'Complete minor piece development before opening the center.'
                  })
                }
              ]
            }
          }
        ]
      };

      final client = MockHttpClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-api-key');
        expect(request.url.queryParameters.containsKey('key'), isFalse);

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(mockResponse))),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(apiKey: 'test-api-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Success>());
      final explanation = (result as Success).data;
      expect(explanation.explanation, contains('Pushing d4 too early'));
      expect(explanation.betterMove, contains('Bc4 develops'));
      expect(explanation.lesson, contains('Complete minor piece development'));
    });

    test('HTTP 400 returns invalidKey failure without retrying', () async {
      int attempts = 0;
      final client = MockHttpClient((request) async {
        attempts++;
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'error': {'code': 400, 'message': 'API key not valid'}
          }))),
          400,
        );
      });

      final service = GeminiService(apiKey: 'bad-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Failure>());
      expect((result as Failure).error.type, GeminiErrorType.invalidKey);
      expect(attempts, 1); // No retries on invalid key
    });

    test('HTTP 429 rate limit retries and recovers on attempt 2', () async {
      int attempts = 0;
      final mockSuccessResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'explanation': 'Good tactical move.',
                    'betterMove': '',
                    'lesson': 'Keep pieces active.'
                  })
                }
              ]
            }
          }
        ]
      };

      final client = MockHttpClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"error": {"code": 429, "message": "Rate limited"}}')),
            429,
          );
        }
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(mockSuccessResponse))),
          200,
        );
      });

      final service = GeminiService(apiKey: 'test-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Success>());
      expect(attempts, 2);
    });

    test('empty candidates returns blocked failure', () async {
      final client = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'candidates': []}))),
          200,
        );
      });

      final service = GeminiService(apiKey: 'test-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Failure>());
      expect((result as Failure).error.type, GeminiErrorType.blocked);
    });

    test('malformed JSON response returns badResponse failure', () async {
      final client = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'This is plain text, not valid JSON!'}
                  ]
                }
              }
            ]
          }))),
          200,
        );
      });

      final service = GeminiService(apiKey: 'test-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Failure>());
      expect((result as Failure).error.type, GeminiErrorType.badResponse);
    });
  });
}
