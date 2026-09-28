import '../../core/constants/app_enums.dart';

import 'receipt_ocr_stub.dart'
    if (dart.library.io) 'receipt_ocr_io.dart' as platform;

class ParsedReceipt {
  const ParsedReceipt({
    required this.amount,
    required this.category,
    required this.merchant,
    this.date,
    this.rawText = '',
    this.confidence = 0,
  });

  final double amount;
  final ExpenseCategory category;
  final String merchant;
  final DateTime? date;
  final String rawText;

  
  final double confidence;

  bool get isValid => amount > 0 && confidence > 0.2;
}

abstract class ReceiptOcrService {
  
  bool get isSupported;

  
  Future<ParsedReceipt> parse(String imagePath);
}

ReceiptOcrService createReceiptOcrService() => platform.create();

ExpenseCategory categoriseText(String text) {
  final String t = text.toLowerCase();
  const Map<ExpenseCategory, List<String>> keywords = {
    ExpenseCategory.food: [
      'restaurant', 'cafe', 'café', 'food', 'pizza', 'burger', 'biryani',
      'kfc', 'mcdonald', 'starbucks', 'bakery', 'juice', 'tea', 'coffee',
      'grocery', 'supermarket', 'mart', 'lunch', 'dinner', 'breakfast',
      'meal', 'snack', 'canteen', 'cafeteria',
    ],
    ExpenseCategory.transport: [
      'uber', 'careem', 'taxi', 'bus', 'train', 'fuel', 'petrol', 'diesel',
      'rickshaw', 'metro', 'parking', 'toll',
    ],
    ExpenseCategory.shopping: [
      'mall', 'store', 'shop', 'clothing', 'shoes', 'zara', 'h&m', 'amazon',
      'daraz', 'outfitter', 'khaadi',
    ],
    ExpenseCategory.education: [
      'book', 'books', 'stationery', 'tuition', 'academy', 'course', 'library',
      'university', 'college', 'fee', 'fees',
    ],
    ExpenseCategory.entertainment: [
      'cinema', 'movie', 'netflix', 'spotify', 'game', 'gaming', 'concert',
      'youtube', 'playstation',
    ],
    ExpenseCategory.bills: [
      'electric', 'electricity', 'gas', 'water', 'internet', 'wifi', 'mobile',
      'phone bill', 'utility', 'bill', 'recharge', 'fbr', 'invoice',
    ],
    ExpenseCategory.savings: [
      'saving', 'savings', 'saved', 'deposit', 'piggy', 'emergency fund',
    ],
  };

  for (final MapEntry<ExpenseCategory, List<String>> entry in keywords.entries) {
    if (entry.value.any(t.contains)) return entry.key;
  }
  return ExpenseCategory.other;
}

final RegExp _amountToken = RegExp(
  r'(?<!\d)(\d{1,3}(?:[,\s]\d{3})+(?:\.\d{1,2})?|\d{1,6}(?:\.\d{1,2})?)(?!\d)',
);

const String _amountCapture =
    r'(\d{1,3}(?:[,\s]\d{3})+(?:\.\d{1,2})?|\d{1,6}(?:\.\d{1,2})?)';

bool _isYear(double value) =>
    value == value.roundToDouble() && value >= 1900 && value <= 2099;

bool _isPlausibleAmount(double value) {
  if (value <= 0 || value >= 1000000) return false;
  
  if (_isYear(value)) return false;
  
  if (value >= 100000 && value == value.roundToDouble()) return false;
  return true;
}

double? _parseAmountToken(String raw) {
  final String cleaned = raw.replaceAll(',', '').replaceAll(' ', '');
  return double.tryParse(cleaned);
}

double? _extractLabeledAmount(String text) {
  final List<RegExp> patterns = [
    RegExp(
      r'(?:grand\s*)?total\s*(?:amount|due|payable)?\s*[:\-=]?\s*'
      r'(?:rs\.?|pkr|usd|\$|€|£)?\s*'
      '$_amountCapture',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:amount\s*(?:due|payable)|net\s*amount|balance\s*due|to\s*pay|'
      r'payable|paid|payment)\s*[:\-=]?\s*'
      r'(?:rs\.?|pkr|usd|\$|€|£)?\s*'
      '$_amountCapture',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:rs\.?|pkr|usd|\$|€|£)\s*'
      '$_amountCapture',
      caseSensitive: false,
    ),
  ];

  final List<double> hits = [];
  for (final RegExp pattern in patterns) {
    for (final RegExpMatch m in pattern.allMatches(text)) {
      final double? value = _parseAmountToken(m.group(1)!);
      if (value != null && _isPlausibleAmount(value)) hits.add(value);
    }
  }
  if (hits.isEmpty) return null;
  
  return hits.last;
}

double _extractLastPlausibleAmount(String text) {
  final List<double> candidates = [];
  for (final RegExpMatch m in _amountToken.allMatches(text)) {
    final double? value = _parseAmountToken(m.group(1)!);
    if (value != null && _isPlausibleAmount(value)) candidates.add(value);
  }
  if (candidates.isEmpty) return 0;

  
  
  final int start =
      candidates.length >= 3 ? candidates.length - 3 : 0;
  final List<double> tail = candidates.sublist(start);
  return tail.reduce((a, b) => a > b ? a : b);
}

double extractAmount(String text) {
  if (text.trim().isEmpty) return 0;
  return _extractLabeledAmount(text) ?? _extractLastPlausibleAmount(text);
}

String extractMerchant(String text) {
  final List<String> lines = text
      .split(RegExp(r'[\n|]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && l.length > 2 && !_looksLikeNoise(l))
      .toList();
  if (lines.isEmpty) return 'Receipt';
  return lines.first.length > 40 ? lines.first.substring(0, 40) : lines.first;
}

bool _looksLikeNoise(String line) {
  final String t = line.toLowerCase();
  if (RegExp(r'^https?://').hasMatch(t)) return true;
  if (RegExp(r'^\d{10,}$').hasMatch(t.replaceAll(RegExp(r'\D'), ''))) {
    return true;
  }
  return false;
}

DateTime? extractDate(String text) {
  final RegExpMatch? match =
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(text);
  if (match == null) return null;
  try {
    final int day = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    int year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

double? extractAmountFromQrPayload(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) return null;

  final double? emv = _emvTagAmount(text, '54');
  if (emv != null && _isPlausibleAmount(emv)) return emv;

  
  final RegExpMatch? json = RegExp(
    r'''(?:"|')?(?:amount|total|amt|grandTotal|invoiceAmount)(?:"|')?\s*[:=]\s*"?(?<v>\d+(?:[.,]\d{1,2})?)"?''',
    caseSensitive: false,
  ).firstMatch(text);
  if (json != null) {
    final double? v =
        double.tryParse(json.namedGroup('v')!.replaceAll(',', '.'));
    if (v != null && _isPlausibleAmount(v)) return v;
  }

  
  final RegExpMatch? kv = RegExp(
    r'(?:amount|amt|total|payable)\s*[=:]\s*(\d+(?:[.,]\d{1,2})?)',
    caseSensitive: false,
  ).firstMatch(text);
  if (kv != null) {
    final double? v = double.tryParse(kv.group(1)!.replaceAll(',', '.'));
    if (v != null && _isPlausibleAmount(v)) return v;
  }

  
  if (text.contains('|')) {
    for (final String part in text.split('|').reversed) {
      final double? v = double.tryParse(part.trim().replaceAll(',', ''));
      if (v != null && _isPlausibleAmount(v) && !_isYear(v)) return v;
    }
  }

  final double labeled = extractAmount(text);
  return labeled > 0 ? labeled : null;
}

double? _emvTagAmount(String raw, String tagId) {
  int i = 0;
  while (i + 4 <= raw.length) {
    final String id = raw.substring(i, i + 2);
    final int? len = int.tryParse(raw.substring(i + 2, i + 4));
    if (len == null || len < 0) return null;
    i += 4;
    if (i + len > raw.length) return null;
    final String value = raw.substring(i, i + len);
    i += len;
    if (id == tagId) return double.tryParse(value);
    
    if (int.tryParse(id) != null) {
      final int idNum = int.parse(id);
      if (idNum >= 26 && idNum <= 51 && value.length >= 4) {
        final double? nested = _emvTagAmount(value, tagId);
        if (nested != null) return nested;
      }
    }
  }
  return null;
}

String? extractMerchantFromQrPayload(String raw) {
  final String? emvName = _emvTagString(raw, '59');
  if (emvName != null && emvName.trim().length > 1) return emvName.trim();
  return null;
}

String? _emvTagString(String raw, String tagId) {
  int i = 0;
  while (i + 4 <= raw.length) {
    final String id = raw.substring(i, i + 2);
    final int? len = int.tryParse(raw.substring(i + 2, i + 4));
    if (len == null || len < 0) return null;
    i += 4;
    if (i + len > raw.length) return null;
    final String value = raw.substring(i, i + len);
    i += len;
    if (id == tagId) return value;
    if (int.tryParse(id) != null) {
      final int idNum = int.parse(id);
      if (idNum >= 26 && idNum <= 51 && value.length >= 4) {
        final String? nested = _emvTagString(value, tagId);
        if (nested != null) return nested;
      }
    }
  }
  return null;
}

ParsedReceipt buildParsedReceipt(
  String rawText, {
  List<String> qrPayloads = const [],
}) {
  double amount = 0;
  String merchant = '';
  DateTime? date;
  final StringBuffer combined = StringBuffer(rawText);
  double confidence = 0.15;

  for (final String payload in qrPayloads) {
    if (payload.trim().isEmpty) continue;
    combined.writeln(payload);
    final double? qrAmount = extractAmountFromQrPayload(payload);
    if (qrAmount != null && qrAmount > amount) {
      amount = qrAmount;
      confidence = 0.9;
    }
    merchant = extractMerchantFromQrPayload(payload) ?? merchant;
  }

  final String allText = combined.toString();
  if (amount <= 0) {
    amount = extractAmount(allText);
    confidence = amount > 0 ? 0.75 : 0.15;
  } else {
    
    confidence = confidence < 0.75 && rawText.trim().isNotEmpty ? 0.85 : confidence;
  }

  if (merchant.isEmpty) merchant = extractMerchant(allText);
  date = extractDate(allText);

  return ParsedReceipt(
    amount: amount,
    category: categoriseText(allText),
    merchant: merchant,
    date: date,
    rawText: allText,
    confidence: confidence,
  );
}
