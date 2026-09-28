import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/config/gemini_config.dart';
import '../services/preferences_service.dart';
import 'service_providers.dart';

@immutable
class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.onboardingSeen,
    this.aiApiKey,
    this.aiModel,
  });

  final ThemeMode themeMode;
  final String currencyCode;
  final String currencySymbol;
  final bool notificationsEnabled;
  final int reminderHour;
  final bool onboardingSeen;

  
  final String? aiApiKey;

  
  final String? aiModel;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currencyCode,
    String? currencySymbol,
    bool? notificationsEnabled,
    int? reminderHour,
    bool? onboardingSeen,
    String? aiApiKey,
    bool clearAiApiKey = false,
    String? aiModel,
    bool clearAiModel = false,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
        aiApiKey: clearAiApiKey ? null : (aiApiKey ?? this.aiApiKey),
        aiModel: clearAiModel ? null : (aiModel ?? this.aiModel),
      );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(_initialState(_prefs));

  final PreferencesService _prefs;

  static SettingsState _initialState(PreferencesService prefs) => SettingsState(
        themeMode: _parseTheme(prefs.themeMode),
        currencyCode: prefs.currencyCode,
        currencySymbol: _symbolFor(prefs.currencyCode),
        notificationsEnabled: prefs.notificationsEnabled,
        reminderHour: prefs.reminderHour,
        onboardingSeen: prefs.onboardingSeen,
        aiApiKey: prefs.aiApiKey,
        aiModel: prefs.aiModel,
      );

  static ThemeMode _parseTheme(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _symbolFor(String code) {
    for (final CurrencyOption option in AppConfig.currencies) {
      if (option.code == code) return option.symbol;
    }
    return 'Rs.';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setThemeMode(mode.name);
  }

  Future<void> setCurrency(String code) async {
    state = state.copyWith(
      currencyCode: code,
      currencySymbol: _symbolFor(code),
    );
    await _prefs.setCurrencyCode(code);
  }

  
  
  
  Future<void> syncCurrencyPreference(String code) => setCurrency(code);

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setNotificationsEnabled(value);
  }

  Future<void> setReminderHour(int hour) async {
    state = state.copyWith(reminderHour: hour);
    await _prefs.setReminderHour(hour);
  }

  Future<void> markOnboardingSeen() async {
    state = state.copyWith(onboardingSeen: true);
    await _prefs.setOnboardingSeen(true);
  }

  Future<void> setAiApiKey(String? key) async {
    final String? normalized =
        (key == null || key.trim().isEmpty) ? null : key.trim();
    state = state.copyWith(
      aiApiKey: normalized,
      clearAiApiKey: normalized == null,
    );
    await _prefs.setAiApiKey(normalized);
  }

  Future<void> setAiModel(String? model) async {
    final String? normalized =
        (model == null || model.trim().isEmpty) ? null : model.trim();
    state = state.copyWith(
      aiModel: normalized,
      clearAiModel: normalized == null,
    );
    await _prefs.setAiModel(normalized);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(ref.watch(preferencesProvider)),
);

final currencySymbolProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).currencySymbol,
);

final currencyCodeProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).currencyCode,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider).themeMode,
);

final effectiveAiApiKeyProvider = Provider<String>((ref) {
  final String? stored = ref.watch(settingsProvider).aiApiKey;
  if (stored != null && stored.isNotEmpty) return stored;
  return GeminiConfig.envApiKey;
});

final effectiveAiModelProvider = Provider<String>((ref) {
  final String? stored = ref.watch(settingsProvider).aiModel;
  if (stored != null && stored.isNotEmpty) return stored;
  return GeminiConfig.defaultModel;
});
