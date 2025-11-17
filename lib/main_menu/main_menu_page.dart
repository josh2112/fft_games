import 'package:fft_games/games/fosteroes/fosteroes.dart' as fosteroes;
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/consts.dart';
import '../utils/dialog_or_bottom_sheet.dart';
import 'settings_dialog.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

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
              child: Transform.scale(
                scale: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 15,
                  children: [
                    GameCard(
                      'Fosterdle',
                      'Guess the five-letter word within six tries.',
                      "assets/tile-fosterdle.png",
                      Theme.of(context).colorScheme.primary,
                      ('Daily', () => context.go('/fosterdle')),
                    ),
                    GameCard(
                      'Fosteroes',
                      'Arrange dominoes on the board to satisfy all conditions.',
                      "assets/tile-fosteroes.png",
                      Theme.of(context).colorScheme.primary,
                      ('Daily', () => context.go('/fosteroes')),
                      actions: [
                        (
                          'Autogen',
                          () => context.go(
                            '/fosteroes',
                            extra: fosteroes.PlayPageParams(PuzzleType.autogen, PuzzleDifficulty.easy),
                          ),
                        ),
                      ],
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

typedef GameCardAction = (String label, void Function() action);

class GameCard extends StatelessWidget {
  final String title, summary, image;
  final Color color;
  late final Color textColor;
  final GameCardAction mainAction;
  final List<GameCardAction>? actions;

  GameCard(this.title, this.summary, this.image, this.color, this.mainAction, {super.key, this.actions}) {
    textColor = switch (ThemeData.estimateBrightnessForColor(color)) {
      Brightness.dark => Colors.white,
      Brightness.light => Colors.black,
    };
  }

  static Color textColorFor(Color color) => switch (ThemeData.estimateBrightnessForColor(color)) {
    Brightness.dark => Colors.white,
    Brightness.light => Colors.black,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Card(
        color: color,
        elevation: 2,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: mainAction.$2,
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
                            Text("${mainAction.$1}  ›", style: TextStyle(color: textColor)),
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
      Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: 5,
          children: [for (final a in actions ?? List<GameCardAction>.empty()) Expanded(child: button1(context, a))],
        ),
      ),
    ],
  );

  Widget button1(BuildContext context, (String, void Function()) a) => FilledButton(
    onPressed: a.$2,
    style: FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      alignment: Alignment.center,
      foregroundColor: textColorFor(Theme.of(context).colorScheme.inversePrimary),
    ),
    child: Text("$title ${a.$1}  ›"),
  );

  Widget button2(BuildContext context, (String, void Function()) a) => OutlinedButton(
    onPressed: a.$2,
    style: OutlinedButton.styleFrom(
      foregroundColor: textColor,
      alignment: Alignment.centerLeft,
      side: BorderSide(color: textColor.withValues(alpha: 0.5), width: 1),
    ),
    child: Text(a.$1),
  );
}
