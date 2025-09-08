abstract class SettingsPersistence {
  Future<String> getString(String name, {required String defaultValue});
  Future<bool> getBool(String name, {required bool defaultValue});
  Future<int> getInt(String name, {required int defaultValue});

  Future<void> setString(String name, String value);
  Future<void> setBool(String name, bool value);
  Future<void> setInt(String name, int value);

  Future<Map<String, dynamic>> getAll();
}
