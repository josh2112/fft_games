import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yarsp/yarsp.dart';

import '/settings/global_settings.dart';
import '/utils/utils.dart';

class SavedDominoPlacement {
  final int id;
  final int x, y;
  final int quarterTurns;

  const SavedDominoPlacement(this.id, this.x, this.y, this.quarterTurns);
}

final dominoPlacementListSharedPreferenceNotifier = AsyncNotifierProvider.autoDispose.family(
  (SharedPreference<List<SavedDominoPlacement>> pref) => JsonSharedPreferenceNotifier(
    pref,
    serialize: (placements) => [
      for (final p in placements) {"id": p.id, "x": p.x, "y": p.y, "quarterTurns": p.quarterTurns},
    ],

    deserialize: (json) => [for (final p in json) SavedDominoPlacement(p["id"], p["x"], p["y"], p["quarterTurns"])],
  ),
);

// The settings for one game (combination of puzzle type and difficulty)
class GameSettingsController {
  final String prefix;

  late final date = dateTimeSharedPreferenceProvider(
    SharedPreference("$prefix.date", DateTime.fromMillisecondsSinceEpoch(0)),
  );
  late final isCompleted = boolSharedPreferenceProvider(SharedPreference("$prefix.isCompleted", false));

  late final seed = intSharedPreferenceProvider(SharedPreference("$prefix.seed", 0));

  late final elapsedTime = intSharedPreferenceProvider(SharedPreference("$prefix.elapsedTime", 0));
  late final state = dominoPlacementListSharedPreferenceNotifier(SharedPreference("$prefix.state", []));

  GameSettingsController(this.prefix, {Logger? log});

  void reset(WidgetRef ref) {
    ref.read(date.notifier).setValue(DateUtils.dateOnly(DateTime.now()));
    ref.read(isCompleted.notifier).setValue(false);
    ref.read(elapsedTime.notifier).setValue(0);
    ref.read(state.notifier).setValue([]);
  }
}

class SettingsController {
  static final String prefix = '${GlobalSettingsController.prefix}.Fosteroes';

  static final _log = Logger('$prefix.SettingsController');

  // Whether to show the timer
  final showTime = boolSharedPreferenceProvider(SharedPreference("$prefix.showTime", true));

  // Total number of games started
  final numPlayed = intSharedPreferenceProvider(SharedPreference("$prefix.numPlayed", 0));

  // Total number of games won
  final numWon = intSharedPreferenceProvider(SharedPreference("$prefix.numWon", 0));

  // Last date a daily game was won (for streaks)
  final lastDateDailyWon = dateTimeSharedPreferenceProvider(
    SharedPreference("$prefix.lastDateDailyWon", DateTime.fromMillisecondsSinceEpoch(0)),
  );

  // Number of consecutive days where at least one daily has been played and won
  final currentStreak = intSharedPreferenceProvider(SharedPreference("$prefix.currentStreak", 0));
  final maxStreak = intSharedPreferenceProvider(SharedPreference("$prefix.maxStreak", 0));

  final Map<(PuzzleType, PuzzleDifficulty), GameSettingsController> gameSettings = {
    for (final type in PuzzleType.values)
      for (final diff in PuzzleDifficulty.values)
        (type, diff): GameSettingsController("$prefix.${type.name}.${diff.name}"),
  };
}
