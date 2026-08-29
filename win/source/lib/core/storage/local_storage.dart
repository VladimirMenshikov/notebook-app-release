import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _lastActiveTabKey = 'last_active_tab';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _biometricEnabledKey = 'biometric_login_enabled';
  static const _currentGroupIdKey = 'current_group_id';

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setLastActiveTab(String tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveTabKey, tab);
  }

  Future<String?> getLastActiveTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastActiveTabKey);
  }

  Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, url);
  }

  Future<String?> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey);
  }

  /// Текущий контекст группы (`null` — «Личное»).
  Future<void> setCurrentGroupId(String? groupId) async {
    final prefs = await SharedPreferences.getInstance();
    if (groupId == null) {
      await prefs.remove(_currentGroupIdKey);
    } else {
      await prefs.setString(_currentGroupIdKey, groupId);
    }
  }

  Future<String?> getCurrentGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentGroupIdKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
