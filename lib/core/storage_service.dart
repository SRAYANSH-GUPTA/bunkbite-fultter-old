import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setString(String key, String value) async {
    if (_prefs == null) await init();
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    // If not initialized, return null (safe fallback)
    return _prefs?.getString(key);
  }

  Future<void> remove(String key) async {
    if (_prefs == null) await init();
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    if (_prefs == null) await init();
    await _prefs?.clear();
  }
}

final storageService = StorageService();
