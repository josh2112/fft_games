import 'package:fft_games/games/wordle/board_state.dart';
import 'package:fft_games/games/wordle/settings.dart';
import 'package:fft_games/utils/top_snack_bar.dart';
import 'package:flutter/material.dart';

class SettingsDialog extends StatelessWidget {
  final SettingsController settings;
  final BoardState boardState;

  const SettingsDialog(this.settings, this.boardState, {super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
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

  void _maybeToggleHardMode(SettingsController settings, BoardState boardState, BuildContext context) {
    if (settings.isHardMode.value && boardState.guesses.first.isSubmitted) {
      showTopSnackBar(context, "Can't turn off hard mode once you've made a guess!");
    } else {
      settings.isHardMode.value = !settings.isHardMode.value;
    }
  }
}
