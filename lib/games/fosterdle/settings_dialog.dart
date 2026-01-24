import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:fft_games/settings/global_settings.dart';
import 'package:fft_games/utils/multi_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov;

class SettingsDialog extends StatelessWidget {
  final SettingsController settings;
  final BoardState boardState;
  final MultiSnackBarMessenger messenger;

  const SettingsDialog(this.settings, this.boardState, this.messenger, {super.key});

  @override
  Widget build(BuildContext context) {
    final globalSettings = context.watch<GlobalSettingsController>();

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
              trailing: ValueListenableBuilder(
                valueListenable: globalSettings.themeMode,
                builder: (context, themeMode, child) => DropdownButton(
                  value: ThemeMode.values[themeMode],
                  onChanged: (v) => globalSettings.themeMode.value = v!.index,
                  items: ThemeMode.values
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m, child: Text("${m.name[0].toUpperCase()}${m.name.substring(1)}")),
                      )
                      .toList(),
                ),
              ),
            ),
            ListTile(
              title: Text("Hard mode"),
              subtitle: Text("Each guess must use the letters you've learned"),
              trailing: ValueListenableBuilder(
                valueListenable: settings.isHardMode,
                builder: (context, hardMode, child) =>
                    Switch(value: hardMode, onChanged: (v) => _maybeToggleHardMode(settings, boardState, context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeToggleHardMode(SettingsController settings, BoardState boardState, BuildContext context) {
    if (settings.isHardMode.value && boardState.guesses.first.isSubmitted) {
      messenger.showSnackBar("Can't turn off hard mode once you've made a guess!");
    } else {
      settings.isHardMode.value = !settings.isHardMode.value;
    }
  }
}
