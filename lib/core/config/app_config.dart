

class AppConfig {
  AppConfig._();

  
  
  static bool firebaseReady = false;

  static const String appName = 'PennyPal';
  static const String tagline = 'Fresh All Along';
  static const String appVersion = '1.0.0';

  
  static const List<CurrencyOption> currencies = [
    CurrencyOption(code: 'PKR', symbol: 'Rs.', label: 'Pakistani Rupee'),
    CurrencyOption(code: 'USD', symbol: r'$', label: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€', label: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£', label: 'British Pound'),
    CurrencyOption(code: 'INR', symbol: '₹', label: 'Indian Rupee'),
    CurrencyOption(code: 'AED', symbol: 'AED ', label: 'UAE Dirham'),
  ];
}

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.label,
  });

  final String code;
  final String symbol;
  final String label;

  String get display => '$code ($symbol)';
}
