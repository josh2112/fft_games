import 'dart:convert';

import 'package:logging/logging.dart';

import '../../settings/persistence/settings_persistence.dart';
import '../../settings/persistence/shared_prefs_persistence.dart';
import '../../settings/setting.dart';

class SavedDominoPlacement {
  final int x, y;
  final int side1, side2;
  final int quarterTurns;

  const SavedDominoPlacement(this.x, this.y, this.side1, this.side2, this.quarterTurns);
}

class SettingsController {
  static final String _prefix = 'Fosteroes';

  static final _log = Logger('$_prefix.SettingsController');

  final SettingsPersistence _store;

  late final Setting<int> numPlayed;
  late final Setting<int> numWon;
  late final Setting<int> currentStreak;
  late final Setting<int> maxStreak;
  late final Setting<DateTime> gameStateDate;
  late final Setting<bool> gameStateIsCompleted;
  late final Setting<List<SavedDominoPlacement>> gameState;

  SettingsController({SettingsPersistence? store}) : _store = store ?? SharedPrefsPersistence() {
    gameStateDate = Setting.serialized(
      "$_prefix.gameState.date",
      _store,
      SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
      log: _log,
    );

    gameStateIsCompleted = Setting("$_prefix.gameState.isCompleted", _store, false, log: _log);

    gameState = Setting.serialized(
      "$_prefix.gameState",
      _store,
      SettingSerializer<List<SavedDominoPlacement>>(
        (List<SavedDominoPlacement> placements) => jsonEncode(
          placements.map(
            (p) => {"x": p.x, "y": p.y, "side1": p.side1, "side2": p.side2, "quarterTurns": p.quarterTurns},
          ).toList(),
        ),
        (String str) => [
          for (final p in jsonDecode(str))
            SavedDominoPlacement(p["x"], p["y"], p["side1"], p["side2"], p["quarterTurns"]),
        ],
      ),
      [],
      log: _log,
    );

    numPlayed = Setting("$_prefix.numPlayed", _store, 0, log: _log);
    numWon = Setting("$_prefix.numWon", _store, 0, log: _log);
    currentStreak = Setting("$_prefix.currentStreak", _store, 0, log: _log);
    maxStreak = Setting("$_prefix.maxStreak", _store, 0, log: _log);
  }
}
