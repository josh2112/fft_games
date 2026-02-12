import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:fft_games/games/fosteroes/settings.dart' as fosteroes;
import 'package:yarsp/yarsp.dart';

import '../utils/consts.dart';
import 'persistence/settings_persistence.dart';

final themeModeSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(
  (SharedPreference<ThemeMode> pref) => SerializedSharedPreferenceNotifier<ThemeMode>(
    pref,
    serialize: (themeMode) => themeMode.index.toString(),
    deserialize: (str) => ThemeMode.values[int.parse(str)],
  ),
);

final globalSettingsProvider = Provider((ref) => GlobalSettingsController());

/// Contains settings for all games, such as light/dark mode
class GlobalSettingsController {
  static final _log = Logger('GlobalSettingsController');

  static final prefix = "fft_games";

  //final _version = intSharedPreferenceProvider(SharedPreference("$prefix.version", 0));

  final themeMode = themeModeSharedPreferenceProvider(SharedPreference("$prefix.themeMode", ThemeMode.system));

  // TODO: Rewrite once Fosteroes settings are converted over
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
      if (ver < 2) {
        // Version 2: Reset Fosteroes stats
        var fs = fosteroes.SettingsController(store: store);
        var settingsToReset = [fs.numPlayed, fs.numWon, fs.currentStreak, fs.maxStreak];
        await Future.wait(settingsToReset.map((s) => s.waitLoaded));
        for (final s in settingsToReset) {
          s.value = 0;
        }
      }
      await store.setInt("$prefix.version", dbVersion);
    }
  }
}
