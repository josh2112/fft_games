import 'dart:convert';

import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:logging/logging.dart';

import '../../settings/global_settings.dart';
import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';
import '../../settings/setting.dart';

class SettingsController {
  static final String _prefix = '${GlobalSettingsController.prefix}.Fosterdle';

  static final _log = Logger('$_prefix.SettingsController');

  final SettingsPersistence _store;

  late final Setting<bool> isHardMode;
  late final Setting<List<int>> solveCounts;
  late final Setting<int> numPlayed;
  late final Setting<int> numWon;
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;
  late final Setting<DateTime> gameStateDate;
  late final Setting<bool> gameStateIsCompleted;
  late final Setting<List<List<LetterWithState>>> gameStateGuesses;

  SettingsController({SettingsPersistence? store}) : _store = store ?? SharedPrefsPersistence() {
    isHardMode = Setting("$_prefix.hardMode", _store, false, log: _log);

    gameStateDate = Setting(
      "$_prefix.gameState.date",
      _store,
      serializer: SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
      log: _log,
    );

    gameStateIsCompleted = Setting("$_prefix.gameState.isCompleted", _store, false, log: _log);

    gameStateGuesses = Setting(
      "$_prefix.gameState.guesses",
      _store,
      serializer: SettingSerializer<List<List<LetterWithState>>>(
        (guesses) => jsonEncode(
          guesses.map((letters) => letters.map((lws) => "${lws.letter}${lws.state.index}").join()).toList(),
        ),
        (str) => [
          for (final letters in jsonDecode(str))
            [
              for (int i = 0; i < letters.length; i += 2)
                LetterWithState(letter: letters[i], state: LetterState.values[int.parse(letters[i + 1])]),
            ],
        ],
      ),
      [],
      log: _log,
    );

    numPlayed = Setting("$_prefix.numPlayed", _store, 0, log: _log);
    numWon = Setting("$_prefix.numWon", _store, 0, log: _log);
    currentStreak = Setting("$_prefix.currentStreak", _store, 0, log: _log);
    maxStreak = Setting("$_prefix.maxStreak", _store, 0, log: _log);

    solveCounts = Setting(
      "$_prefix.solveCounts",
      _store,
      serializer: SettingSerializer(jsonEncode, (str) => List<int>.from(jsonDecode(str))),
      [0, 0, 0, 0, 0, 0],
      log: _log,
    );
  }
}
