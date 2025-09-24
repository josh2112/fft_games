import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/settings/persistence/shared_prefs_persistence.dart';
import 'package:fft_games/settings/setting.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GlobalSettingsController {
  static final _log = Logger('GlobalSettingsController');

  final SettingsPersistence _store;

  late final Setting<int> themeMode;

  GlobalSettingsController({SettingsPersistence? store})
    : _store = store ?? SharedPrefsPersistence() {
    themeMode = Setting("themeMode", _store, ThemeMode.system.index, log: _log);
  }
}
