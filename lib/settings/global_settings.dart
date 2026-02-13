import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarsp/yarsp.dart';

import '/utils/consts.dart';

final themeModeSharedPreferenceProvider = AsyncNotifierProvider.autoDispose.family(
  (SharedPreference<ThemeMode> pref) => SerializedSharedPreferenceNotifier<ThemeMode>(
    pref,
    serialize: (themeMode) => themeMode.index.toString(),
    deserialize: (str) => ThemeMode.values[int.parse(str)],
  ),
);

/// Contains settings for all games, such as light/dark mode
class GlobalSettingsController {
  static final prefix = "fft_games";

  static final _version = intSharedPreferenceProvider(SharedPreference("$prefix.version", 0));

  final themeMode = themeModeSharedPreferenceProvider(SharedPreference("$prefix.themeMode", ThemeMode.system));

  static Future migrate(Ref ref) async {
    final ver = await ref.read(_version.future);
    if (ver != dbVersion) {
      // Migrations?
    }
    ref.read(_version.notifier).setValue(dbVersion);
  }
}

final globalSettingsProvider = FutureProvider((ref) async {
  await GlobalSettingsController.migrate(ref);
  return GlobalSettingsController();
});
