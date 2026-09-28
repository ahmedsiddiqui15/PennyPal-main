import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pennypal/models/financial_snapshot.dart';
import 'package:pennypal/services/ai_service.dart';
import 'package:pennypal/services/gemini_service.dart';

void main() {
  group('GeminiService', () {
    test('sends the prompt and key, then parses the answer', () async {
      late http.Request captured;
      final MockClient client = MockClient((http.Request request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'candidates': <Map<String, dynamic>>[
              <String, dynamic>{
                'content': <String, dynamic>{
                  'parts': <Map<String, dynamic>>[
                    <String, dynamic>{'text': 'Spend less on Food.'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final GeminiService service = GeminiService(
        client: client,
        baseUrl: 'https://example.test/v1beta',
      );

      final String text = await service.generate(
        apiKey: 'test-key',
        systemInstruction: 'You are Penny. Balance Rs. 5000.',
        userMessage: 'Where am I overspending?',
        model: 'gemini-flash-latest',
      );

      expect(text, 'Spend less on Food.');
      expect(
        captured.url.path,
        '/v1beta/models/gemini-flash-latest:generateContent',
      );
      expect(captured.headers['x-goog-api-key'], 'test-key');

      final Map<String, dynamic> body =
          jsonDecode(captured.body) as Map<String, dynamic>;
      final Map<String, dynamic> system =
          body['systemInstruction'] as Map<String, dynamic>;
      expect(
        (system['parts'] as List<dynamic>).first['text'],
        contains('Penny'),
      );
      final List<dynamic> contents = body['contents'] as List<dynamic>;
      expect(
        (contents.first['parts'] as List<dynamic>).first['text'],
        'Where am I overspending?',
      );
    });

    test('throws GeminiException on a non-200 response', () async {
      final MockClient client = MockClient(
        (_) async => http.Response('{"error":{"message":"bad key"}}', 403),
      );
      final GeminiService service = GeminiService(
        client: client,
        baseUrl: 'https://example.test/v1beta',
      );

      await expectLater(
        service.generate(
          apiKey: 'nope',
          systemInstruction: 's',
          userMessage: 'q',
        ),
        throwsA(isA<GeminiException>()),
      );
    });

    test('throws GeminiException when the prompt is blocked', () async {
      final MockClient client = MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'promptFeedback': <String, dynamic>{'blockReason': 'SAFETY'},
          }),
          200,
        ),
      );
      final GeminiService service = GeminiService(
        client: client,
        baseUrl: 'https://example.test/v1beta',
      );

      await expectLater(
        service.generate(
          apiKey: 'k',
          systemInstruction: 's',
          userMessage: 'q',
        ),
        throwsA(isA<GeminiException>()),
      );
    });

    test('retries a transient error and then succeeds', () async {
      int calls = 0;
      final MockClient client = MockClient((_) async {
        calls++;
        if (calls == 1) {
          return http.Response('{"error":{"message":"high demand"}}', 503);
        }
        return http.Response(
          jsonEncode(<String, dynamic>{
            'candidates': <Map<String, dynamic>>[
              <String, dynamic>{
                'content': <String, dynamic>{
                  'parts': <Map<String, dynamic>>[
                    <String, dynamic>{'text': 'ok'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final GeminiService service = GeminiService(
        client: client,
        baseUrl: 'https://example.test/v1beta',
        retryDelay: Duration.zero,
      );

      final String text = await service.generate(
        apiKey: 'k',
        systemInstruction: 's',
        userMessage: 'q',
      );

      expect(text, 'ok');
      expect(calls, 2);
    });

    test('gives up after retrying a persistent 503', () async {
      int calls = 0;
      final MockClient client = MockClient((_) async {
        calls++;
        return http.Response('{"error":{"message":"high demand"}}', 503);
      });
      final GeminiService service = GeminiService(
        client: client,
        baseUrl: 'https://example.test/v1beta',
        maxAttempts: 2,
        retryDelay: Duration.zero,
      );

      await expectLater(
        service.generate(
          apiKey: 'k',
          systemInstruction: 's',
          userMessage: 'q',
        ),
        throwsA(isA<GeminiException>()),
      );
      expect(calls, 2);
    });
  });

  group('AiService fallback', () {
    test('uses the offline coach when no key is set', () async {
      bool called = false;
      final MockClient client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final AiService ai = AiService(gemini: GeminiService(client: client));

      const String question = 'Where am I overspending?';
      final FinancialSnapshot snapshot = FinancialSnapshot.empty();
      final String reply = await ai.ask(question, snapshot);

      expect(called, isFalse);
      expect(reply, ai.respond(question, snapshot));
    });

    test('falls back to the offline coach when Gemini fails', () async {
      final MockClient client = MockClient(
        (_) async => http.Response('{"error":{"message":"boom"}}', 500),
      );
      final AiService ai = AiService(
        gemini: GeminiService(client: client, maxAttempts: 1),
      );

      final String reply = await ai.ask(
        'How can I save money?',
        FinancialSnapshot.empty(),
        geminiApiKey: 'k',
      );

      expect(reply, contains('Offline coach'));
    });

    test('surfaces the Gemini failure reason to the user', () async {
      final MockClient client = MockClient(
        (_) async => http.Response(
          '{"error":{"message":"API key not valid. Please pass a valid API key."}}',
          400,
        ),
      );
      final AiService ai = AiService(
        gemini: GeminiService(
          client: client,
          baseUrl: 'https://example.test/v1beta',
        ),
      );

      final String reply = await ai.ask(
        'hello',
        FinancialSnapshot.empty(),
        geminiApiKey: 'bad',
      );

      expect(reply, contains('rejected the API key'));
    });
  });

  group('AiService offline coach', () {
    final AiService ai = AiService(
      gemini: GeminiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );

    test('answers a budget question with budget advice, not food', () {
      final String reply =
          ai.respond('Create a budget for me', FinancialSnapshot.empty());
      expect(reply.toLowerCase(), contains('budget'));
      expect(reply.toLowerCase(), isNot(contains('cook 3 dinners')));
    });

    test('still recognises a greeting', () {
      expect(ai.respond('hi', FinancialSnapshot.empty()), contains('Penny'));
    });
  });
}
