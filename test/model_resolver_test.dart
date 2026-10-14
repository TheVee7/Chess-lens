import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chess_lens/ai/model_resolver.dart';
import 'package:chess_lens/ai/gemini_service.dart';
import 'package:chess_lens/core/config/app_config.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ModelResolver', () {
    test('resolves highest flash version and filters out disallowed variants', () async {
      final mockModelsResponse = {
        'models': [
          {
            'name': 'models/gemini-1.5-flash',
            'supportedGenerationMethods': ['generateContent']
          },
          {
            'name': 'models/gemini-3.5-flash-lite',
            'supportedGenerationMethods': ['generateContent']
          },
          {
            'name': 'models/gemini-2.5-flash-image',
            'supportedGenerationMethods': ['generateContent']
          },
          {
            'name': 'models/gemini-3.8-flash',
            'supportedGenerationMethods': ['generateContent']
          },
          {
            'name': 'models/gemini-3.9-flash-preview',
            'supportedGenerationMethods': ['generateContent']
          },
          {
            'name': 'models/text-embedding-004',
            'supportedGenerationMethods': ['embedContent']
          },
        ]
      };

      final client = MockHttpClient((request) async {
        expect(request.method, 'GET');
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(mockModelsResponse))),
          200,
        );
      });

      final model = await ModelResolver.resolveModel(
        apiKey: 'test-key',
        client: client,
        forceRefresh: true,
      );

      expect(model, 'gemini-3.8-flash');
    });

    test('falls back to fallbackModels when GET models fails', () async {
      final client = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"error": "Failed"}')),
          500,
        );
      });

      final model = await ModelResolver.resolveModel(
        apiKey: 'test-key',
        client: client,
        forceRefresh: true,
      );

      expect(model, AppConfig.fallbackModels.first);
    });

    test('caches resolved model and reuses it on subsequent calls', () async {
      int getCalls = 0;
      final client = MockHttpClient((request) async {
        getCalls++;
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'models': [
              {
                'name': 'models/gemini-3.8-flash',
                'supportedGenerationMethods': ['generateContent']
              }
            ]
          }))),
          200,
        );
      });

      final model1 = await ModelResolver.resolveModel(
        apiKey: 'test-key',
        client: client,
      );
      final model2 = await ModelResolver.resolveModel(
        apiKey: 'test-key',
        client: client,
      );

      expect(model1, 'gemini-3.8-flash');
      expect(model2, 'gemini-3.8-flash');
      expect(getCalls, 1); // Second call used cache
    });
  });

  group('GeminiService 404 self-healing', () {
    test('on 404 clears cache, re-resolves, and recovers', () async {
      int requestCount = 0;
      final client = MockHttpClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          // First POST fails with 404
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'error': {'code': 404, 'message': 'models/gemini-2.0-flash is not found'}
            }))),
            404,
          );
        } else if (requestCount == 2) {
          // Re-resolution GET models
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'models': [
                {
                  'name': 'models/gemini-3.8-flash',
                  'supportedGenerationMethods': ['generateContent']
                }
              ]
            }))),
            200,
          );
        } else {
          // Retry POST succeeds with 200
          expect(request.url.path, contains('gemini-3.8-flash'));
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'explanation': 'Tactical recovery.',
                          'betterMove': '',
                          'lesson': ''
                        })
                      }
                    ]
                  }
                }
              ]
            }))),
            200,
          );
        }
      });

      final service = GeminiService(apiKey: 'test-key', client: client);
      final result = await service.explainMoveResult(_dummyMove());

      expect(result, isA<Success>());
      expect(service.model, 'gemini-3.8-flash');
      expect(requestCount, 3); // 1: failed POST, 2: GET models, 3: successful POST
    });
  });
}
