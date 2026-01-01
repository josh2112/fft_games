import 'dart:convert';

import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../settings/global_settings.dart';
import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';
import '../../settings/setting.dart';

class SavedDominoPlacement {
  final int id;
  final int x, y;
  final int quarterTurns;

  const SavedDominoPlacement(this.id, this.x, this.y, this.quarterTurns);
}

// The settings for one game (combination of puzzle type and difficulty)
class GameSettingsController {
  late final Setting<DateTime> date;
  late final Setting<int> elapsedTime;
  late final Setting<int> seed;
  late final Setting<List<SavedDominoPlacement>> state;
  late final Setting<bool> isCompleted;

  GameSettingsController(String prefix, SettingsPersistence store, {Logger? log}) {
    date = Setting(
      "$prefix.date",
      store,
      serializer: SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
      log: log,
    );

    isCompleted = Setting("$prefix.isCompleted", store, false, log: log);

    state = Setting(
      "$prefix.state",
      store,
      serializer: SettingSerializer<List<SavedDominoPlacement>>(
        (List<SavedDominoPlacement> placements) => jsonEncode(
          placements.map((p) => {"id": p.id, "x": p.x, "y": p.y, "quarterTurns": p.quarterTurns}).toList(),
        ),
        (String str) => [
          for (final p in jsonDecode(str)) SavedDominoPlacement(p["id"], p["x"], p["y"], p["quarterTurns"]),
        ],
      ),
      [],
      log: log,
    );

    elapsedTime = Setting("$prefix.elapsedTime", store, 0, log: log);

    seed = Setting("$prefix.seed", store, 0, log: log);
  }

  Future waitUntilLoaded() =>
      Future.wait([date.waitLoaded, state.waitLoaded, isCompleted.waitLoaded, elapsedTime.waitLoaded, seed.waitLoaded]);

  void reset() {
    date.value = DateUtils.dateOnly(DateTime.now());
    isCompleted.value = false;
    elapsedTime.value = 0;
    state.value = [];
  }
}

class SettingsController {
  static final String prefix = '${GlobalSettingsController.prefix}.Fosteroes';

  static final _log = Logger('$prefix.SettingsController');

  // Whether to show the timer
  late final Setting<bool> showTime;

  // Total number of games started
  late final Setting<int> numPlayed;

  // Total number of games won
  late final Setting<int> numWon;

  // Last date a daily game was won (for streaks)
  late final Setting<DateTime> lastDateDailyWon;

  // Number of consecutive days where at least one daily has been played and won
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;

  late final Map<(PuzzleType, PuzzleDifficulty), GameSettingsController> gameSettings;

  SettingsController({SettingsPersistence? store}) {
    store ??= SharedPrefsPersistence();
    showTime = Setting("$prefix.showTime", store, true, log: _log);
    numPlayed = Setting("$prefix.numPlayed", store, 0, log: _log);
    numWon = Setting("$prefix.numWon", store, 0, log: _log);
    currentStreak = Setting("$prefix.currentStreak", store, 0, log: _log);
    maxStreak = Setting("$prefix.maxStreak", store, 0, log: _log);
    lastDateDailyWon = Setting(
      "$prefix.lastDateDailyWon",
      store,
      serializer: SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
    );

    gameSettings = {
      for (final type in PuzzleType.values)
        for (final diff in PuzzleDifficulty.values)
          (type, diff): GameSettingsController("$prefix.${type.name}.${diff.name}", store),
    };
  }
}
