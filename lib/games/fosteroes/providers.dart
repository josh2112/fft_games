import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/utils/utils.dart';
import 'settings.dart';

final settingsProvider = Provider((ref) => SettingsController());

final isNewGameAvailableProvider = FutureProvider.family((
  ref,
  ({PuzzleType type, PuzzleDifficulty difficulty}) selection,
) async {
  if (selection.type == PuzzleType.autogen) return true;

  final gameSettings = ref.read(settingsProvider).gameSettings[selection]!;

  return await ref.watch(gameSettings.date.future) != DateUtils.dateOnly(DateTime.now()) ||
      !await ref.watch(gameSettings.isCompleted.future);
});

final isAnyNewGameAvailableProvider = FutureProvider.family((ref, PuzzleType type) async {
  return (await Future.wait([
    for (final d in PuzzleDifficulty.values) ref.watch(isNewGameAvailableProvider((type: type, difficulty: d)).future),
  ])).contains(true);
});
