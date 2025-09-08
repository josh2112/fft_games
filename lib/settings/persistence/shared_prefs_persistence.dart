import 'package:shared_preferences/shared_preferences.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';

class SharedPrefsPersistence extends SettingsPersistence {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  @override
  Future<Map<String, dynamic>> getAll() async => await prefs.getAll();

  @override
  Future<bool> getBool(String name, {required bool defaultValue}) async =>
      await prefs.getBool(name) ?? defaultValue;

  @override
  Future<int> getInt(String name, {required int defaultValue}) async =>
      await prefs.getInt(name) ?? defaultValue;

  @override
  Future<String> getString(String name, {required String defaultValue}) async =>
      await prefs.getString(name) ?? defaultValue;

  @override
  Future<void> setBool(String name, bool value) async =>
      await prefs.setBool(name, value);

  @override
  Future<void> setInt(String name, int value) async =>
      await prefs.setInt(name, value);

  @override
  Future<void> setString(String name, String value) async =>
      await prefs.setString(name, value);
}
