import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../utils/consts.dart';
import 'persistence/settings_persistence.dart';
import 'setting.dart';

/// Contains settings for all games, such as light/dark mode
class GlobalSettingsController {
  static final _log = Logger('GlobalSettingsController');

  static final prefix = "fft_games";

  final SettingsPersistence _store;

  late final Setting<int> themeMode;

  GlobalSettingsController(SettingsPersistence store) : _store = store {
    themeMode = Setting("$prefix.themeMode", _store, ThemeMode.system.index, log: _log);
  }

  static Future migrate(SettingsPersistence store) async {
    final ver = await store.getInt("$prefix.version", defaultValue: 0);
    if (ver != dbVersion) {
      if (ver < 1) {
        // Version 1: Added "fft_games" prefix for all setting names
        for (final e in (await store.getAll()).entries.where(
          (e) => e.key == 'themeMode' || e.key.startsWith('Fosteroes') || e.key.startsWith('Fosterdle'),
        )) {
          final key = "$prefix.${e.key}", value = e.value;
          await switch (value) {
            int() => store.setInt(key, value),
            bool() => store.setBool(key, value),
            String _ => store.setString(key, value),
            _ => throw ("Catastrophic error migrating settings"),
          };
          store.removeKey(e.key);
        }
      }
      await store.setInt("$prefix.version", dbVersion);
    }
  }
}
