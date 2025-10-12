import 'package:logging/logging.dart';

import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';
import '../../settings/setting.dart';

class SettingsController {
  static final String _prefix = 'Fosterdle';

  static final _log = Logger('$_prefix.SettingsController');

  final SettingsPersistence _store;

  late final Setting<bool> isHardMode;
  late final JsonSetting<List<int>> solveCounts;
  late final Setting<int> numPlayed;
  late final Setting<int> numWon;
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;

  SettingsController({SettingsPersistence? store}) : _store = store ?? SharedPrefsPersistence() {
    isHardMode = Setting("$_prefix.hardMode", _store, false, log: _log);
    numPlayed = Setting("$_prefix.numPlayed", _store, 0, log: _log);
    numWon = Setting("$_prefix.numWon", _store, 0, log: _log);
    currentStreak = Setting("$_prefix.currentStreak", _store, 0, log: _log);
    maxStreak = Setting("$_prefix.maxStreak", _store, 0, log: _log);
    solveCounts = JsonSetting("$_prefix.solveCounts", _store, (obj) => List<int>.from(obj), [
      0,
      0,
      0,
      0,
      0,
      0,
    ], log: _log);
  }
}
