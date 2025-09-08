import 'settings_persistence.dart';

class MemoryPersistence extends SettingsPersistence {
  final Map<String, dynamic> settings = {};

  String _get(String name, dynamic defaultValue) =>
      settings.putIfAbsent(name, () => defaultValue.toString());

  @override
  Future<bool> getBool(String name, {required bool defaultValue}) async =>
      bool.parse(_get(name, defaultValue));

  @override
  Future<int> getInt(String name, {required int defaultValue}) async =>
      int.parse(_get(name, defaultValue));

  @override
  Future<String> getString(String name, {required String defaultValue}) async =>
      _get(name, defaultValue);

  @override
  Future<void> setBool(String name, bool value) async =>
      settings[name] = value.toString();

  @override
  Future<void> setInt(String name, int value) async =>
      settings[name] = value.toString();

  @override
  Future<void> setString(String name, String value) async =>
      settings[name] = value;
}
