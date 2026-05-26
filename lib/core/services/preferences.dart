import 'package:shared_preferences/shared_preferences.dart';
class PreferencesService {
  static const String _currencyKey = 'app_currency';
  static const String _languageKey = 'app_language';
  static const String _dateFormatKey = 'app_date_format';
  static const String _numberFormatKey = 'app_number_format';
  static const String _lastRateSyncKey = 'last_rate_sync_time';
  
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Currency
  Future<String> getCurrency() async {
    final prefs = await _prefs;
    return prefs.getString(_currencyKey) ?? 'KSH';
  }

  Future<void> setCurrency(String currencyCode) async {
    final prefs = await _prefs;
    await prefs.setString(_currencyKey, currencyCode);
  }

  // Language
  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'English';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, language);
  }

  // Date Format
  Future<String> getDateFormat() async {
    final prefs = await _prefs;
    return prefs.getString(_dateFormatKey) ?? 'MM/DD/YYYY';
  }

  Future<void> setDateFormat(String format) async {
    final prefs = await _prefs;
    await prefs.setString(_dateFormatKey, format);
  }

  // Number Format
  Future<String> getNumberFormat() async {
    final prefs = await _prefs;
    return prefs.getString(_numberFormatKey) ?? '1,234.56';
  }

  Future<void> setNumberFormat(String format) async {
    final prefs = await _prefs;
    await prefs.setString(_numberFormatKey, format);
  }

  // Clear all preferences
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<DateTime?> getLastRateSync() async {
    final prefs = await _prefs;
    final timestamp = prefs.getInt(_lastRateSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Sets the last time rates were successfully synced.
  Future<void> setLastRateSync(DateTime time) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastRateSyncKey, time.millisecondsSinceEpoch);
  }

  /// Helper to check if a sync is needed (e.g., more than 24 hours ago)
  Future<bool> shouldSyncRates() async {
    final lastSync = await getLastRateSync();
    if (lastSync == null) return true; // Never synced

    final difference = DateTime.now().difference(lastSync);
    return difference.inHours >= 24;
  }
}