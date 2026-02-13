import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/games/fosterdle/board_state.dart';
import '/games/fosterdle/settings.dart';
import '/settings/settings_dialog.dart' as global;
import '/utils/multi_snack_bar.dart';

class SettingsDialog extends ConsumerWidget {
  final SettingsController settings;
  final BoardState boardState;
  final MultiSnackBarMessenger messenger;

  const SettingsDialog(this.settings, this.boardState, this.messenger, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => global.SettingsDialog(
    children: [
      global.SettingsEntry(
        title: "Hard mode",
        subtitle: "Each guess must use the letters you've learned",
        child: Consumer(
          builder: (context, ref, child) => switch (ref.watch(settings.isHardMode)) {
            AsyncData(value: final isHardMode) => Switch(
              value: isHardMode,
              onChanged: (v) {
                if (isHardMode && boardState.guesses.first.isSubmitted) {
                  messenger.showSnackBar("Can't turn off hard mode once you've made a guess!");
                } else {
                  ref.read(settings.isHardMode.notifier).toggle();
                }
              },
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    ],
  );
}
