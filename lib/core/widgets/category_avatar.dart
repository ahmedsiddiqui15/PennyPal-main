import 'package:flutter/material.dart';

import '../constants/app_enums.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    this.expenseCategory,
    this.incomeCategory,
    this.icon,
    this.color,
    this.emoji,
    this.size = 44,
  });

  final ExpenseCategory? expenseCategory;
  final IncomeCategory? incomeCategory;
  final IconData? icon;
  final Color? color;
  final String? emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final IconData resolvedIcon = icon ??
        expenseCategory?.icon ??
        incomeCategory?.icon ??
        Icons.category_rounded;
    final Color resolvedColor = color ??
        expenseCategory?.color ??
        incomeCategory?.color ??
        Theme.of(context).colorScheme.primary;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.45))
          : Icon(resolvedIcon, color: resolvedColor, size: size * 0.5),
    );
  }
}
