import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/games/fosterdle/palette.dart';
import '/games/fosterdle/settings.dart';

final paletteProvider = Provider((ref) => Palette());

final settingsProvider = Provider((ref) => SettingsController());

final isNewGameAvailableProvider = FutureProvider((ref) async {
  final settings = ref.read(settingsProvider);

  return await ref.read(settings.gameStateDate.future) != DateUtils.dateOnly(DateTime.now()) ||
      !await ref.watch(settings.gameStateIsCompleted.future);
});
