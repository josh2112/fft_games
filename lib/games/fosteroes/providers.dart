import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/utils/utils.dart';
import 'settings.dart';

final settingsProvider = Provider((ref) => SettingsController());

/// Returns true if today's game of this [type] and [difficulty] has not been completed (the last game state is for a
/// previous day, or today's game has been started but not completed yet).
final isNewGameAvailableProvider = FutureProvider.family((
  ref,
  ({PuzzleType type, PuzzleDifficulty difficulty}) selection,
) async {
  if (selection.type == PuzzleType.autogen) return true;

  final gameSettings = ref.read(settingsProvider).gameSettings[selection]!;

  final lastPlayedDate = await ref.watch(gameSettings.date.future);
  final lastGameWasCompleted = await ref.watch(gameSettings.isCompleted.future);

  return lastPlayedDate.isBefore(DateUtils.dateOnly(DateTime.now())) || !lastGameWasCompleted;
});

/// Returns true if any of today's games for this [type] have not been completed yet.
final isAnyNewGameAvailableProvider = FutureProvider.family((ref, PuzzleType type) async {
  return (await Future.wait([
    for (final d in PuzzleDifficulty.values) ref.watch(isNewGameAvailableProvider((type: type, difficulty: d)).future),
  ])).contains(true);
});
