import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/gemini_config.dart';

class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => 'GeminiException: $message';
}

class GeminiService {
  GeminiService({
    http.Client? client,
    String? baseUrl,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(milliseconds: 600),
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? GeminiConfig.baseUrl,
        _maxAttempts = maxAttempts < 1 ? 1 : maxAttempts,
        _retryDelay = retryDelay;

  final http.Client _client;
  final String _baseUrl;
  final int _maxAttempts;
  final Duration _retryDelay;

  static const Duration _timeout = Duration(seconds: 25);

  
  
  static bool _isRetryable(int status) =>
      status == 429 ||
      status == 500 ||
      status == 502 ||
      status == 503 ||
      status == 504;

  
  
  
  
  
  
  
  Future<String> generate({
    required String apiKey,
    required String systemInstruction,
    required String userMessage,
    String? model,
  }) async {
    final String resolvedModel = (model == null || model.trim().isEmpty)
        ? GeminiConfig.defaultModel
        : model.trim();
    final Uri uri =
        Uri.parse('$_baseUrl/models/$resolvedModel:generateContent');

    final Map<String, dynamic> body = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': systemInstruction},
        ],
      },
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': userMessage},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.7,
        'maxOutputTokens': 600,
      },
    };

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final http.Response response = await _client
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          try {
            return _extractText(response.body);
          } on GeminiException {
            rethrow;
          } catch (_) {
            throw const GeminiException(
              'Gemini returned an unexpected response.',
            );
          }
        }

        if (_isRetryable(response.statusCode) && attempt < _maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        throw GeminiException(_describeError(response));
      } on GeminiException {
        
        
        rethrow;
      } catch (_) {
        
        if (attempt < _maxAttempts) {
          await _backoff(attempt);
          continue;
        }
        throw const GeminiException(
          'Could not reach Gemini. Check your connection and try again.',
        );
      }
    }
    throw const GeminiException('Gemini is unavailable right now.');
  }

  
  Future<void> _backoff(int attempt) =>
      Future<void>.delayed(_retryDelay * attempt);

  
  String _extractText(String responseBody) {
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiException('Gemini returned an unexpected response.');
    }

    final Object? feedback = decoded['promptFeedback'];
    if (feedback is Map<String, dynamic> && feedback['blockReason'] != null) {
      throw const GeminiException(
        'Gemini blocked that question. Try rephrasing it.',
      );
    }

    final Object? candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiException('Gemini did not return an answer.');
    }

    final Object? first = candidates.first;
    if (first is! Map<String, dynamic>) {
      throw const GeminiException('Gemini did not return an answer.');
    }

    final Object? content = first['content'];
    if (content is! Map<String, dynamic>) {
      throw const GeminiException('Gemini did not return an answer.');
    }

    final Object? parts = content['parts'];
    if (parts is! List) {
      throw const GeminiException('Gemini did not return an answer.');
    }

    final String text = parts
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> part) => part['text'])
        .whereType<String>()
        .join()
        .trim();

    if (text.isEmpty) {
      throw const GeminiException('Gemini did not return an answer.');
    }
    return text;
  }

  
  String _describeError(http.Response response) {
    String? detail;
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final Object? error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          detail = error['message'] as String;
        }
      }
    } catch (_) {
      
    }

    if (response.statusCode == 429) {
      return 'Gemini is rate-limited right now. Try again in a moment.';
    }
    if (response.statusCode == 503) {
      return 'Gemini is busy right now. Please try again shortly.';
    }
    if (detail != null && detail.isNotEmpty) {
      final String lower = detail.toLowerCase();
      if (lower.contains('api key') ||
          lower.contains('apikey') ||
          lower.contains('permission') ||
          lower.contains('credential')) {
        return 'Gemini is not available right now. Please try again later.';
      }
      if (lower.contains('model')) {
        return 'Gemini could not use the configured model. Please try again later.';
      }
      return 'Gemini could not answer right now. Please try again.';
    }
    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      return 'Gemini is not available right now. Please try again later.';
    }
    return 'Gemini request failed (${response.statusCode}).';
  }

  void dispose() => _client.close();
}
