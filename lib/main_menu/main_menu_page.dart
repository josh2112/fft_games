import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' hide Consumer;

import '/games/fosterdle/providers.dart' as fosterdle;
import '/settings/new_game_settings_providers.dart';
import '/settings/persistence/settings_persistence.dart';
import '/utils/consts.dart';
import '/utils/dialog_or_bottom_sheet.dart';
import '/utils/utils.dart';
import 'settings_dialog.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

  late final NewGameWatcher newGamesAvail = NewGameWatcher(context.read<SettingsPersistence>());

  @override
  void didUpdateWidget(covariant MainMenuPage oldWidget) {
    newGamesAvail.update();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Foster Family Times Games', style: TextTheme.of(context).titleLarge, textAlign: TextAlign.center),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 15,
                  children: [
                    Consumer(
                      builder: (context, ref, child) => GameCard(
                        'Fosterdle',
                        'Guess the five-letter word within six tries.',
                        "assets/tile-fosterdle.png",
                        Theme.of(context).colorScheme.primary,
                        GameCardAction(
                          'Daily',
                          '',
                          () => context.go('/fosterdle'),
                          isNew: switch (ref.watch(fosterdle.isNewGameAvailableProvider)) {
                            AsyncData(:final value) => value,
                            _ => false,
                          },
                        ),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: newGamesAvail.fosteroesWatchers[PuzzleDifficulty.easy]!.isNewGameAvailable,
                      builder: (context, isNew, child) => GameCard(
                        'Fosteroes',
                        'Arrange dominoes on the board to satisfy all conditions.',
                        "assets/tile-fosteroes.png",
                        Theme.of(context).colorScheme.primary,
                        GameCardAction(
                          'Daily',
                          '',
                          () => context.go('/fosteroes', extra: PuzzleType.daily),
                          isNew: isNew,
                        ),
                        secondaryAction: GameCardAction(
                          'Autogen',
                          'Unlimited play',
                          () => context.go('/fosteroes', extra: PuzzleType.autogen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) => OutlinedButton.icon(
                onPressed: () => showDialogOrBottomSheet(context, SettingsDialog()),
                label: Text("Settings"),
                icon: Icon(Icons.settings),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  "Version $version${(isRunningWithWasm ? '\nWASM enabled' : '')}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GameCardAction {
  final String label, description;
  final VoidCallback action;
  final bool isNew;

  GameCardAction(this.label, this.description, this.action, {this.isNew = false});
}

class GameCard extends StatelessWidget {
  final String title, summary, image;
  final Color color;
  late final Color textColor;
  final GameCardAction mainAction;
  final GameCardAction? secondaryAction;

  GameCard(this.title, this.summary, this.image, this.color, this.mainAction, {super.key, this.secondaryAction}) {
    textColor = switch (ThemeData.estimateBrightnessForColor(color)) {
      Brightness.dark => Colors.white,
      Brightness.light => Colors.black,
    };
  }

  @override
  Widget build(BuildContext context) => Column(
    verticalDirection: VerticalDirection.up,
    children: [
      if (secondaryAction != null)
        Transform.translate(
          offset: Offset(0, -15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(width: double.infinity, child: GameCardActionButton(secondaryAction!)),
          ),
        ),
      Card(
        color: color,
        elevation: 2,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: mainAction.action,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsGeometry.only(left: 25, right: 25, top: 15, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextTheme.of(context).titleLarge!.copyWith(color: textColor)),
                            Expanded(
                              child: Text(
                                summary,
                                textAlign: TextAlign.start,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            Badge(
                              alignment: Alignment.centerRight,
                              offset: Offset(30, -9),
                              label: Text("New"),
                              isLabelVisible: mainAction.isNew,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(mainAction.label, style: TextStyle(color: textColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: ClipRSuperellipse(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: Image.asset(image, fit: BoxFit.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class GameCardActionButton extends StatelessWidget {
  final GameCardAction action;
  const GameCardActionButton(this.action, {super.key});

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: action.action,
    style: FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      alignment: Alignment.centerLeft,
      foregroundColor: textColorFor(Theme.of(context).colorScheme.inversePrimary),
      padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 20),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(action.label),
        Text(action.description, style: TextTheme.of(context).bodySmall),
      ],
    ),
  );

  static Color textColorFor(Color color) => switch (ThemeData.estimateBrightnessForColor(color)) {
    Brightness.dark => Colors.white,
    Brightness.light => Colors.black,
  };
}
