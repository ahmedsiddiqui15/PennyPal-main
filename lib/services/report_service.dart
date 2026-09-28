import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_enums.dart';
import '../core/utils/formatters.dart';
import '../models/financial_snapshot.dart';
import '../models/report_model.dart';

class ReportService {
  const ReportService();

  
  
  ReportModel buildReport(FinancialSnapshot snapshot, String userId) {
    final Map<String, double> breakdown = {};
    for (final MapEntry<ExpenseCategory, double> entry
        in snapshot.topCategories) {
      breakdown[entry.key.label] = entry.value;
    }

    return ReportModel(
      id: '',
      userId: userId,
      title: 'Monthly Report',
      period: Formatters.monthYear(DateTime.now()),
      totalIncome: snapshot.monthIncome,
      totalExpense: snapshot.monthExpense,
      totalSaved: snapshot.monthIncome - snapshot.monthExpense,
      categoryBreakdown: breakdown,
      monthlyTrend: snapshot.monthlySeries,
      summary: _summaryText(snapshot),
      generatedAt: DateTime.now(),
    );
  }

  String _summaryText(FinancialSnapshot s) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      'You earned ${s.monthIncome.round()} and spent ${s.monthExpense.round()} '
      'this month, saving ${(s.monthIncome - s.monthExpense).round()}.',
    );
    buffer.writeln(
      'Your financial health score is ${s.healthScore}/100 (${s.healthLabel}).',
    );
    final ExpenseCategory? top = s.topCategory;
    if (top != null) {
      buffer.writeln(
        'The biggest category was ${top.label} at ${s.amountFor(top).round()}.',
      );
    }
    buffer.writeln(
      'Expected spending next month: ${s.predictedNextMonth.round()}.',
    );
    return buffer.toString();
  }

  
  Future<Uint8List> buildPdf(ReportModel report, {String symbol = 'Rs.'}) async {
    final pw.Document doc = pw.Document();

    final pw.TextStyle h1 = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey900,
    );
    const pw.TextStyle muted = pw.TextStyle(fontSize: 10, color: PdfColors.grey600);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PennyPal', style: h1),
                    pw.Text('Fresh All Along', style: muted),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(report.period,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.Text(
                      'Generated ${Formatters.date(report.generatedAt)}',
                      style: muted,
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(color: PdfColors.amber),
          ],
        ),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: muted,
          ),
        ),
        build: (pw.Context context) => [
          pw.SizedBox(height: 8),
          pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _metric('Income', '$symbol${report.totalIncome.round()}'),
              _metric('Expenses', '$symbol${report.totalExpense.round()}'),
              _metric('Net savings', '$symbol${report.netSavings.round()}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            report.summary.isEmpty ? 'No summary generated.' : report.summary,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Spending by category',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (report.categoryBreakdown.isEmpty)
            pw.Text('No expenses recorded this month.', style: muted)
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Category', 'Amount', 'Share'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.amber100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
              data: report.categoryBreakdown.entries
                  .map(
                    (MapEntry<String, double> e) => [
                      e.key,
                      '$symbol${e.value.round()}',
                      report.totalExpense <= 0
                          ? '0%'
                          : '${((e.value / report.totalExpense) * 100).round()}%',
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Monthly trend (income vs expense)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _trendTable(report, symbol),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Generated by PennyPal — your student finance companion.',
              style: muted,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _metric(String label, String value) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  )),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  pw.Widget _trendTable(ReportModel report, String symbol) {
    final List<Map<String, dynamic>> rows = report.monthlyTrend
        .where((Map<String, dynamic> m) =>
            (m['income'] as num? ?? 0) > 0 || (m['expense'] as num? ?? 0) > 0)
        .toList();

    if (rows.isEmpty) {
      return pw.Text('Not enough history yet.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['Month', 'Income', 'Expenses', 'Net'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      cellStyle: const pw.TextStyle(fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.amber100),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      data: rows.map((Map<String, dynamic> m) {
        final double income = (m['income'] as num?)?.toDouble() ?? 0;
        final double expense = (m['expense'] as num?)?.toDouble() ?? 0;
        return [
          '${m['label']} ${m['year']}',
          '$symbol${income.round()}',
          '$symbol${expense.round()}',
          '$symbol${(income - expense).round()}',
        ];
      }).toList(),
    );
  }

  
  Future<void> sharePdf(ReportModel report, {String symbol = 'Rs.'}) async {
    final Uint8List bytes = await buildPdf(report, symbol: symbol);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'pennypal_${report.period.replaceAll(' ', '_').toLowerCase()}.pdf',
    );
  }

  
  String buildCsv(List<dynamic> transactions) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Date,Type,Category,Description,Amount');
    for (final dynamic tx in transactions) {
      final String date = Formatters.date(tx.date as DateTime);
      final String type = tx.type == TransactionType.income ? 'Income' : 'Expense';
      final String category = (tx.categoryLabel as String).replaceAll(',', ' ');
      final String description =
          ((tx.description as String).isEmpty ? category : tx.description as String)
              .replaceAll(',', ' ')
              .replaceAll('\n', ' ');
      buffer.writeln(
        '$date,$type,$category,$description,${(tx.amount as double).toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }
}
