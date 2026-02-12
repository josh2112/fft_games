import 'dart:convert';

import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yarsp/yarsp.dart';

import '../../settings/global_settings.dart';

final solveCountsSharedPreferenceNotifier = AsyncNotifierProvider.autoDispose.family(
  (SharedPreference<List<int>> pref) => JsonSharedPreferenceNotifier<List<int>>(
    pref,
    serialize: (solveCounts) => solveCounts,
    deserialize: (json) => json.cast<int>(),
  ),
);

final guessesSharedPreferenceNotifier = AsyncNotifierProvider.autoDispose.family(
  (SharedPreference<List<List<LetterWithState>>> pref) => JsonSharedPreferenceNotifier<List<List<LetterWithState>>>(
    pref,
    serialize: (guesses) =>
        guesses.map((letters) => letters.map((lws) => "${lws.letter}${lws.state.index}").join()).toList(),
    deserialize: (json) => [
      for (final letters in json)
        [
          for (int i = 0; i < letters.length; i += 2)
            LetterWithState(letter: letters[i], state: LetterState.values[int.parse(letters[i + 1])]),
        ],
    ],
  ),
);

class SettingsController {
  static final String prefix = '${GlobalSettingsController.prefix}.Fosterdle';

  static final _log = Logger('$prefix.SettingsController');

  final isHardMode = boolSharedPreferenceProvider(SharedPreference("$prefix.hardMode", false));

  final numPlayed = intSharedPreferenceProvider(SharedPreference("$prefix.numPlayed", 0));
  final numWon = intSharedPreferenceProvider(SharedPreference("$prefix.numWon", 0));

  final currentStreak = intSharedPreferenceProvider(SharedPreference("$prefix.currentStreak", 0));
  final maxStreak = intSharedPreferenceProvider(SharedPreference("$prefix.maxStreak", 0));

  final gameStateDate = dateTimeSharedPreferenceProvider(
    SharedPreference("$prefix.gameState.date", DateTime.fromMillisecondsSinceEpoch(0)),
  );
  final gameStateIsCompleted = boolSharedPreferenceProvider(SharedPreference("$prefix.gameState.isCompleted", false));

  final solveCounts = solveCountsSharedPreferenceNotifier(SharedPreference("$prefix.solveCounts", [0, 0, 0, 0, 0, 0]));

  final gameStateGuesses = guessesSharedPreferenceNotifier(SharedPreference("$prefix.gameState.guesses", []));
}
