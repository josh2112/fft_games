import 'package:fft_games/games/fosterdle/palette.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paletteProvider = Provider((ref) => Palette());

final settingsProvider = Provider((ref) => SettingsController());

final isNewGameAvailableProvider = FutureProvider((ref) async {
  final settings = ref.read(settingsProvider);

  return await ref.read(settings.gameStateDate.future) != DateUtils.dateOnly(DateTime.now()) ||
      !await ref.watch(settings.gameStateIsCompleted.future);
});
