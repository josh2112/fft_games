import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:fft_games/settings/global_settings.dart';
import 'package:fft_games/utils/multi_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDialog extends ConsumerWidget {
  final SettingsController settings;
  final BoardState boardState;
  final MultiSnackBarMessenger messenger;

  const SettingsDialog(this.settings, this.boardState, this.messenger, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSettings = ref.read(globalSettingsProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: EdgeInsetsGeometry.only(top: 8, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(right: 15),
                  child: Align(alignment: Alignment.centerRight, child: CloseButton()),
                ),
                Center(
                  child: Container(
                    color: Colors.transparent,
                    child: Text("Settings", style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text("Color theme"),
              trailing: Consumer(
                builder: (context, ref, child) => switch (ref.watch(globalSettings.themeMode)) {
                  AsyncData(value: final themeMode) => DropdownButton(
                    value: themeMode,
                    onChanged: (newThemeMode) => ref.read(globalSettings.themeMode.notifier).setValue(newThemeMode!),
                    items: ThemeMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text("${m.name[0].toUpperCase()}${m.name.substring(1)}"),
                          ),
                        )
                        .toList(),
                  ),

                  _ => const CircularProgressIndicator(),
                },
              ),
            ),
            ListTile(
              title: Text("Hard mode"),
              subtitle: Text("Each guess must use the letters you've learned"),
              trailing: Consumer(
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
        ),
      ),
    );
  }
}
