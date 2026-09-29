import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kThemeMode = 'theme_mode';
  static const String _kCurrency = 'currency_code';
  static const String _kOnboardingSeen = 'onboarding_seen';
  static const String _kLastUserId = 'last_user_id';
  static const String _kNotifications = 'notifications_enabled';
  static const String _kAiHistory = 'ai_history';
  static const String _kReminderHour = 'reminder_hour';
  static const String _kLegacyAiApiKey = 'ai_gemini_api_key';
  static const String _kLegacyAiModel = 'ai_gemini_model';

  static Future<PreferencesService> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PreferencesService service = PreferencesService(prefs);
    await service._clearLegacyAiCredentials();
    return service;
  }

  Future<void> _clearLegacyAiCredentials() async {
    await _prefs.remove(_kLegacyAiApiKey);
    await _prefs.remove(_kLegacyAiModel);
  }

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  String get currencyCode => _prefs.getString(_kCurrency) ?? 'PKR';

  Future<void> setCurrencyCode(String code) =>
      _prefs.setString(_kCurrency, code);

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);

  String? get lastUserId => _prefs.getString(_kLastUserId);

  Future<void> setLastUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kLastUserId);
    } else {
      await _prefs.setString(_kLastUserId, id);
    }
  }

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotifications, value);

  int get reminderHour => _prefs.getInt(_kReminderHour) ?? 20;

  Future<void> setReminderHour(int hour) => _prefs.setInt(_kReminderHour, hour);

  List<String> get aiHistory => _prefs.getStringList(_kAiHistory) ?? const [];

  Future<void> setAiHistory(List<String> history) =>
      _prefs.setStringList(_kAiHistory, history);

  Future<void> clear() => _prefs.clear();
}
