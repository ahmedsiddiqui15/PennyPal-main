import 'package:intl/intl.dart';

import 'currency_converter.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _grouped = NumberFormat('#,##0');
  static final NumberFormat _groupedDecimal = NumberFormat('#,##0.00');

  
  
  
  
  static String money(
    num value, {
    String symbol = 'Rs.',
    bool? decimals,
    String? currencyCode,
  }) {
    final bool useDecimals = decimals ??
        (currencyCode != null
            ? CurrencyConverter.usesDecimals(currencyCode)
            : _symbolUsesDecimals(symbol) || value.abs() % 1 != 0);
    final bool negative = value < 0;
    final String body = useDecimals
        ? _groupedDecimal.format(value.abs())
        : _grouped.format(value.abs().round());
    return '${negative ? '-' : ''}$symbol$body';
  }

  static bool _symbolUsesDecimals(String symbol) {
    final String s = symbol.trim();
    return s == r'$' || s == '€' || s == '£' || s == 'AED';
  }

  
  static String compact(num value, {String symbol = 'Rs.'}) {
    final double v = value.abs().toDouble();
    final String sign = value < 0 ? '-' : '';
    if (v >= 1000000) return '$sign$symbol${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '$sign$symbol${(v / 1000).toStringAsFixed(1)}K';
    if (_symbolUsesDecimals(symbol) || v % 1 != 0) {
      return '$sign$symbol${v.toStringAsFixed(2)}';
    }
    return '$sign$symbol${v.round()}';
  }

  static String percent(double fraction, {int decimals = 0}) =>
      '${(fraction * 100).toStringAsFixed(decimals)}%';

  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String shortMonth(DateTime d) => DateFormat('MMM').format(d);
  static String dayName(DateTime d) => DateFormat('EEE').format(d);

  
  static String relativeDate(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7 && diff > 0) return '$diff days ago';
    return date(d);
  }

  static String greeting([DateTime? now]) {
    final int hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  
  static String initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final String s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
