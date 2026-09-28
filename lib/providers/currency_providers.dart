import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/currency_converter.dart';
import '../models/user_model.dart';
import 'auth_providers.dart';
import 'finance_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

class CurrencyController {
  CurrencyController(this._ref);

  final Ref _ref;

  
  
  
  Future<String?> change(String newCode) async {
    final SettingsState settings = _ref.read(settingsProvider);
    final String oldCode = settings.currencyCode;
    if (oldCode == newCode) return null;

    final double factor =
        CurrencyConverter.factor(fromCode: oldCode, toCode: newCode);

    try {
      await _ref.read(settingsProvider.notifier).setCurrency(newCode);

      final String userId = _ref.read(currentUserIdProvider);
      if (userId.isNotEmpty && factor != 1) {
        await _ref
            .read(repositoryProvider)
            .convertCurrencyAmounts(userId, factor);
        await _ref.read(financeProvider.notifier).refresh();
      }

      final UserModel? user = _ref.read(currentUserProvider);
      if (user != null) {
        final String symbol = _ref.read(settingsProvider).currencySymbol;
        await _ref.read(authProvider.notifier).updateProfile(
              user.copyWith(
                currencyCode: newCode,
                currencySymbol: symbol,
                monthlyIncomeGoal: CurrencyConverter.convert(
                  user.monthlyIncomeGoal,
                  fromCode: oldCode,
                  toCode: newCode,
                ),
              ),
            );
      }
      return null;
    } catch (_) {
      await _ref.read(settingsProvider.notifier).setCurrency(oldCode);
      return 'Could not convert amounts to the new currency. Please try again.';
    }
  }
}

final currencyControllerProvider = Provider<CurrencyController>(
  (ref) => CurrencyController(ref),
);
