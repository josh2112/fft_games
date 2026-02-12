import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarsp/yarsp.dart';

import '/games/fosteroes/fosteroes.dart' as fosteroes;
import '/settings/persistence/settings_persistence.dart';
import '/settings/setting.dart';
import '/utils/utils.dart';

typedef NewGameSetting = ({String prefix, String dateSettingName, String isCompletedSettingName});

// TODO: Finish migrating this over

final newGameSettingsProvider = FutureProvider.autoDispose.family((ref, NewGameSetting newGameSetting) async {
  final date = await ref.watch(
    dateTimeSharedPreferenceProvider(
      SharedPreference(
        "${newGameSetting.prefix}.${newGameSetting.dateSettingName}",
        DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ).future,
  );
  final isCompleted = await ref.watch(
    boolSharedPreferenceProvider(
      SharedPreference("${newGameSetting.prefix}.${newGameSetting.isCompletedSettingName}", false),
    ).future,
  );

  return date != DateUtils.dateOnly(DateTime.now()) || !isCompleted;
});

final fosteroesNewGameSettingsProvider = FutureProvider.autoDispose.family((ref, PuzzleDifficulty difficulty) async {
  return await ref.watch(
    newGameSettingsProvider((
      prefix: "${fosteroes.SettingsController.prefix}.${PuzzleType.daily.name}.${difficulty.name}",
      dateSettingName: "date",
      isCompletedSettingName: "isCompleted",
    )).future,
  );
});

class NewGameSettingsWatcher {
  final SettingsPersistence store;
  final Setting<DateTime> _date;
  final Setting<bool> _isCompleted;

  final isNewGameAvailable = ValueNotifier(false);

  NewGameSettingsWatcher(this.store, String prefix, String dateSettingName, String isCompletedSettingName)
    : _date = Setting(
        "$prefix.$dateSettingName",
        store,
        serializer: SettingSerializer.dateTime,
        DateTime.fromMillisecondsSinceEpoch(0),
      ),

      _isCompleted = Setting("$prefix.$isCompletedSettingName", store, false) {
    // We can't rely on addListener() here, since the settings getting updated in Fosterdle
    // are separate instances. Maybe make a settings source factory so we can always get the same instance
    // for a given key? This would also solve the problem of having to remember to pass the right params in
    // case we're accessing this setting for the first time.

    Future.wait([
      for (var s in [_date, _isCompleted]) s.waitLoaded,
    ]).then((_) => update());
  }

  Future update() async => isNewGameAvailable.value =
      await _date.update() != DateUtils.dateOnly(DateTime.now()) || !await _isCompleted.update();
}

class NewGameWatcher {
  final Map<PuzzleDifficulty, NewGameSettingsWatcher> fosteroesWatchers;

  final isAnyFosteroesDailyGameAvailable = ValueNotifier(false);

  NewGameWatcher(SettingsPersistence store)
    : fosteroesWatchers = {
        for (var diff in PuzzleDifficulty.values)
          diff: NewGameSettingsWatcher(
            store,
            "${fosteroes.SettingsController.prefix}.${PuzzleType.daily.name}.${diff.name}",
            "date",
            "isCompleted",
          ),
      };

  Future update() async {
    for (var w in fosteroesWatchers.values) {
      await w.update();
    }
    isAnyFosteroesDailyGameAvailable.value = fosteroesWatchers.values.any((w) => w.isNewGameAvailable.value);
  }
}
