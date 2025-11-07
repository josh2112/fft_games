import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsPersistence extends SettingsPersistence {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  @override
  Future<bool> containsKey(String name) => prefs.containsKey(name);

  @override
  Future<bool> getBool(String name, {required bool defaultValue}) async => await prefs.getBool(name) ?? defaultValue;

  @override
  Future<int> getInt(String name, {required int defaultValue}) async => await prefs.getInt(name) ?? defaultValue;

  @override
  Future<String> getString(String name, {required String defaultValue}) async =>
      await prefs.getString(name) ?? defaultValue;

  @override
  Future<Map<String, Object?>> getAll() => prefs.getAll();

  @override
  Future<void> setBool(String name, bool value) => prefs.setBool(name, value);

  @override
  Future<void> setInt(String name, int value) => prefs.setInt(name, value);

  @override
  Future<void> setString(String name, String value) => prefs.setString(name, value);

  @override
  Future<void> removeKey(String key) => prefs.remove(key);
}
