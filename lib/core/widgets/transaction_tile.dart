import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/app_enums.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../utils/formatters.dart';
import '../../models/expense_model.dart';
import '../../models/transaction_model.dart';
import 'category_avatar.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.symbol = 'Rs.',
    this.onTap,
    this.showDate = true,
  });

  final TransactionModel transaction;
  final String symbol;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isIncome = transaction.isIncome;
    final Color amountColor = isIncome ? AppColors.success : AppColors.danger;

    final ExpenseCategory expenseCategory =
        ExpenseCategory.fromKey(transaction.categoryKey);
    final IncomeCategory incomeCategory =
        IncomeCategory.fromKey(transaction.categoryKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              CategoryAvatar(
                expenseCategory: isIncome ? null : expenseCategory,
                incomeCategory: isIncome ? incomeCategory : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isEmpty
                          ? transaction.categoryLabel
                          : transaction.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transaction.categoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption
                                .copyWith(color: palette.textSecondary),
                          ),
                        ),
                        if (showDate) ...[
                          Text(
                            '  •  ',
                            style: AppTextStyles.caption
                                .copyWith(color: palette.textSecondary),
                          ),
                          Text(
                            Formatters.relativeDate(transaction.date),
                            style: AppTextStyles.caption
                                .copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${Formatters.money(transaction.amount, symbol: symbol)}',
                    style: AppTextStyles.subtitle.copyWith(color: amountColor),
                  ),
                  if (transaction.source != EntrySource.manual)
                    Text(
                      transaction.source.label,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textSecondary.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
