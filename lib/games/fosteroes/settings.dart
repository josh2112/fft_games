import 'dart:convert';

import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/utils/utils.dart';
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
}

class SettingsController {
  static final String _prefix = '${GlobalSettingsController.prefix}.Fosteroes';

  static final _log = Logger('$_prefix.SettingsController');

  // Total number of gamese started
  late final Setting<int> numPlayed;

  // Total number of games won
  late final Setting<int> numWon;

  // Number of consecutive days where at least one daily has been played and won
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;

  late final Map<(PuzzleType, PuzzleDifficulty), GameSettingsController> gameSettings;

  SettingsController({SettingsPersistence? store}) {
    store ??= SharedPrefsPersistence();
    numPlayed = Setting("$_prefix.numPlayed", store, 0, log: _log);
    numWon = Setting("$_prefix.numWon", store, 0, log: _log);
    currentStreak = Setting("$_prefix.currentStreak", store, 0, log: _log);
    maxStreak = Setting("$_prefix.maxStreak", store, 0, log: _log);

    gameSettings = {
      for (final type in PuzzleType.values)
        for (final diff in PuzzleDifficulty.values)
          (type, diff): GameSettingsController("$_prefix.${type.name}.${diff.name}", store),
    };
  }
}
