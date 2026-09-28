import '../core/utils/json_utils.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSaved,
    this.categoryBreakdown = const {},
    this.monthlyTrend = const [],
    this.summary = '',
    required this.generatedAt,
  });

  final String id;
  final String userId;
  final String title;

  
  final String period;
  final double totalIncome;
  final double totalExpense;
  final double totalSaved;

  
  final Map<String, double> categoryBreakdown;

  
  final List<Map<String, dynamic>> monthlyTrend;
  final String summary;
  final DateTime generatedAt;

  double get netSavings => totalIncome - totalExpense;

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) => ReportModel(
        id: id,
        userId: asString(map['userId']),
        title: asString(map['title'], 'Monthly Report'),
        period: asString(map['period']),
        totalIncome: asDouble(map['totalIncome']),
        totalExpense: asDouble(map['totalExpense']),
        totalSaved: asDouble(map['totalSaved']),
        categoryBreakdown: asMap(map['categoryBreakdown']).map(
          (k, v) => MapEntry(k, asDouble(v)),
        ),
        monthlyTrend: (map['monthlyTrend'] as List?)
                ?.map((e) => asMap(e))
                .toList() ??
            const [],
        summary: asString(map['summary']),
        generatedAt: asDateTime(map['generatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'period': period,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'totalSaved': totalSaved,
        'categoryBreakdown': categoryBreakdown,
        'monthlyTrend': monthlyTrend,
        'summary': summary,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
