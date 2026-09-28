import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import 'animated_counter.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.symbol = 'Rs.',
    this.ownerName = 'Student',
  });

  final double balance;
  final double income;
  final double expense;
  final String symbol;
  final String ownerName;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      decoration: BoxDecoration(
        gradient: AppColors.amberGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        boxShadow: AppShadows.amber,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Balance',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: _hidden ? 'Show balance' : 'Hide balance',
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: widget.balance,
            builder: (v) => Text(
              _hidden ? '${widget.symbol}••••••' : _money(v),
              style: AppTextStyles.amount.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.south_west_rounded,
                  label: 'Income',
                  value: _hidden ? '••••' : _money(widget.income),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.north_east_rounded,
                  label: 'Expenses',
                  value: _hidden ? '••••' : _money(widget.expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(double v) {
    final String digits = v.abs().round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${v < 0 ? '-' : ''}${widget.symbol}$buffer';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
