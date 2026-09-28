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
  static const String _kAiApiKey = 'ai_gemini_api_key';
  static const String _kAiModel = 'ai_gemini_model';

  static Future<PreferencesService> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
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

  
  
  String? get aiApiKey {
    final String? value = _prefs.getString(_kAiApiKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setAiApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _prefs.remove(_kAiApiKey);
    } else {
      await _prefs.setString(_kAiApiKey, key);
    }
  }

  
  String? get aiModel {
    final String? value = _prefs.getString(_kAiModel);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setAiModel(String? model) async {
    if (model == null || model.isEmpty) {
      await _prefs.remove(_kAiModel);
    } else {
      await _prefs.setString(_kAiModel, model);
    }
  }

  Future<void> clear() => _prefs.clear();
}
