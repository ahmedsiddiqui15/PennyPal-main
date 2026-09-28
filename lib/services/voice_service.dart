import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/constants/app_enums.dart';
import 'ocr/receipt_ocr.dart' show categoriseText;

class ParsedVoiceExpense {
  const ParsedVoiceExpense({
    required this.amount,
    required this.category,
    required this.description,
    this.rawText = '',
  });

  final double amount;
  final ExpenseCategory category;
  final String description;
  final String rawText;

  bool get isValid => amount > 0;
}

class VoiceCaptureService {
  VoiceCaptureService();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  
  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onStatus: (_) {},
        onError: (_) {},
      );
    } catch (e) {
      _available = false;
      if (kDebugMode) {
        debugPrint('VoiceCaptureService.initialize failed: $e');
      }
    }
    return _available;
  }

  Future<void> start({
    required void Function(String words) onResult,
    void Function(String error)? onError,
  }) async {
    if (!_available) {
      final bool ok = await initialize();
      if (!ok) {
        onError?.call('Speech recognition is not available on this device.');
        return;
      }
    }
    try {
      await _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
        
        listenFor: const Duration(seconds: 12),
        
        pauseFor: const Duration(seconds: 3),
        
        partialResults: true,
        
        localeId: 'en_US',
      );
    } catch (e) {
      onError?.call('Could not start listening: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {
      
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {
      
    }
  }
}

ParsedVoiceExpense parseVoiceExpense(String sentence) {
  final String text = sentence.toLowerCase();

  double amount = 0;
  final RegExpMatch? currency = RegExp(
    r'(?:rs\.?|pkr|rupees?|\$|dollars?)?\s*(\d{1,3}(?:,\d{3})+|\d+(?:\.\d{1,2})?)\s*(?:rs\.?|pkr|rupees?|k\b|thousand|dollars?)?',
  ).firstMatch(text);
  if (currency != null) {
    final String raw = currency.group(1)!.replaceAll(',', '');
    amount = double.tryParse(raw) ?? 0;
    if (text.contains('thousand') || RegExp(r'\d\s*k\b').hasMatch(text)) {
      amount *= 1000;
    }
  }

  
  String description = sentence
      .replaceAll(
        RegExp(
          r'\b(i|spent|paid|bought|add|expense|on|for|rs|pkr|rupees|dollars)\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\d[\d,\.]*'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (description.isEmpty) {
    description = text.contains('lunch') || text.contains('dinner')
        ? 'Meal'
        : 'Spoken expense';
  }

  return ParsedVoiceExpense(
    amount: amount,
    category: categoriseText(sentence),
    description: description[0].toUpperCase() + description.substring(1),
    rawText: sentence,
  );
}
