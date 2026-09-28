import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food', Icons.restaurant_rounded, Color(0xFFF97316)),
  transport('Transport', Icons.directions_bus_rounded, Color(0xFF3B82F6)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  education('Education', Icons.menu_book_rounded, Color(0xFF8B5CF6)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFF06B6D4)),
  bills('Bills', Icons.receipt_long_rounded, Color(0xFFEF4444)),
  savings('Savings', Icons.savings_rounded, Color(0xFF14B8A6)),
  other('Other', Icons.category_rounded, Color(0xFF64748B));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static ExpenseCategory fromKey(String? key) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == (key ?? '').toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

enum IncomeCategory {
  allowance('Allowance', Icons.family_restroom_rounded, Color(0xFF16A34A)),
  partTime('Part-time Job', Icons.work_rounded, Color(0xFF0EA5E9)),
  scholarship('Scholarship', Icons.school_rounded, Color(0xFF8B5CF6)),
  gift('Gift', Icons.card_giftcard_rounded, Color(0xFFEC4899)),
  other('Other Income', Icons.attach_money_rounded, Color(0xFF64748B));

  const IncomeCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static IncomeCategory fromKey(String? key) {
    return IncomeCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == (key ?? '').toLowerCase(),
      orElse: () => IncomeCategory.other,
    );
  }
}

enum TransactionType {
  income,
  expense;

  static TransactionType fromKey(String? key) =>
      (key ?? '').toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense;
}

enum UserRole {
  student,
  admin;

  static UserRole fromKey(String? key) =>
      (key ?? '').toLowerCase() == 'admin' ? UserRole.admin : UserRole.student;

  String get label => this == UserRole.admin ? 'Administrator' : 'Student';
}

enum SupportStatus {
  pending('Pending', Color(0xFFF59E0B)),
  inProgress('In Progress', Color(0xFF3B82F6)),
  resolved('Resolved', Color(0xFF16A34A));

  const SupportStatus(this.label, this.color);
  final String label;
  final Color color;

  static SupportStatus fromKey(String? key) => SupportStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (key ?? '').toLowerCase(),
        orElse: () => SupportStatus.pending,
      );
}

enum BudgetPeriod {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const BudgetPeriod(this.label);
  final String label;

  static BudgetPeriod fromKey(String? key) => BudgetPeriod.values.firstWhere(
        (p) => p.name.toLowerCase() == (key ?? '').toLowerCase(),
        orElse: () => BudgetPeriod.monthly,
      );
}
