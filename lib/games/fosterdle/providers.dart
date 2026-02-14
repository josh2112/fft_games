import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/games/fosterdle/palette.dart';
import '/games/fosterdle/settings.dart';

final paletteProvider = Provider((ref) => Palette());

final settingsProvider = Provider((ref) => SettingsController());

/// Returns true if today's game has not been completed (the last game state is for a previous day, or today's game
/// has been started but not completed yet).
final isNewGameAvailableProvider = FutureProvider((ref) async {
  final settings = ref.read(settingsProvider);

  final lastPlayedDate = await ref.watch(settings.gameStateDate.future);
  final lastGameWasCompleted = await ref.watch(settings.gameStateIsCompleted.future);

  return lastPlayedDate.isBefore(DateUtils.dateOnly(DateTime.now())) || !lastGameWasCompleted;
});
