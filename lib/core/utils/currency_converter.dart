

class CurrencyConverter {
  CurrencyConverter._();

  
  static const Map<String, double> unitsPerUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'AED': 3.67,
    'INR': 83.5,
    'PKR': 278.0,
  };

  
  
  
  static double factor({required String fromCode, required String toCode}) {
    if (fromCode == toCode) return 1;
    final double? from = unitsPerUsd[fromCode];
    final double? to = unitsPerUsd[toCode];
    if (from == null || to == null || from == 0) return 1;
    return to / from;
  }

  
  static double convert(
    double amount, {
    required String fromCode,
    required String toCode,
  }) {
    if (fromCode == toCode) return amount;
    final double scaled = amount * factor(fromCode: fromCode, toCode: toCode);
    return (scaled * 100).round() / 100;
  }

  
  static bool usesDecimals(String code) =>
      code != 'PKR' && code != 'INR';
}
