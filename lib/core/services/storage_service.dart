import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _backendUrlKey = 'backend_url';

  static Future<void> saveBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, url);
  }

  static Future<String?> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey);
  }

  static Future<void> clearBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendUrlKey);
  }
}
