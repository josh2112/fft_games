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
                      actions: [('Daily', () => context.go('/fosterdle'))],
                    ),
                    GameCard(
                      'Fosteroes',
                      'Arrange dominoes on the board to satisfy all conditions.',
                      "assets/tile-fosteroes.png",
                      Theme.of(context).colorScheme.primary,
                      actions: [
                        ('Daily', () => context.go('/fosteroes')),
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

class GameCard extends StatelessWidget {
  final String title, summary, image;
  final Color color;
  late final Color textColor;
  final List<(String, void Function())> actions;

  GameCard(this.title, this.summary, this.image, this.color, {super.key, required this.actions}) {
    textColor = switch (ThemeData.estimateBrightnessForColor(color)) {
      Brightness.dark => Colors.white,
      Brightness.light => Colors.black,
    };
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Card(
        color: color,
        elevation: 2,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextTheme.of(context).titleLarge!.copyWith(color: textColor)),
                      Text(
                        summary,
                        textAlign: TextAlign.start,
                        style: TextStyle(color: textColor),
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
      ),
      Padding(
        padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: 10,
          children: [
            for (final a in actions)
              Expanded(
                child: OutlinedButton(onPressed: a.$2, child: Text(a.$1)),
              ),
          ],
        ),
      ),
    ],
  );
}
