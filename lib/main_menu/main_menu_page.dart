import 'package:fft_games/games/fosterdle/fosterdle.dart' as fosterdle;
import 'package:fft_games/games/fosteroes/fosteroes.dart' as fosteroes;
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/settings/setting.dart';
import 'package:fft_games_lib/fosteroes/puzzle.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  late final NewGamesAvailableSettingsController newGamesAvail = NewGamesAvailableSettingsController(
    context.read<SettingsPersistence>(),
  );

  @override
  void initState() {
    super.initState();
  }

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 15,
                children: [
                  ValueListenableBuilder(
                    valueListenable: context.watch<fosterdle.SettingsController>().isNewGameAvailable,
                    builder: (conntext, isNew, child) {
                      print('isn ew ??????  $isNew');
                      return GameCard(
                        'Fosterdle',
                        'Guess the five-letter word within six tries.',
                        "assets/tile-fosterdle.png",
                        Theme.of(context).colorScheme.primary,
                        GameCardAction('Daily', '', () => context.go('/fosterdle'), isNew: isNew),
                      );
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: newGamesAvail.isFosteroesNew,
                    builder: (context, isNew, child) => GameCard(
                      'Fosteroes',
                      'Arrange dominoes on the board to satisfy all conditions.',
                      "assets/tile-fosteroes.png",
                      Theme.of(context).colorScheme.primary,
                      GameCardAction('Daily', '', () => context.go('/fosteroes'), isNew: isNew),
                      secondaryAction: GameCardAction(
                        'Autogen',
                        'Unlimited play',
                        () => context.go(
                          '/fosteroes',
                          extra: fosteroes.PlayPageParams(PuzzleType.autogen, PuzzleDifficulty.easy),
                        ),
                      ),
                    ),
                  ),
                ],
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

class NewGamesAvailableSettingsController {
  final SettingsPersistence store;

  late final Setting<DateTime> fosterdleDate, fosteroesDate;
  late final Setting<bool> fosterdleIsCompleted, fosteroesIsCompleted;

  final isFosterdleNew = ValueNotifier<bool>(false);
  final isFosteroesNew = ValueNotifier<bool>(false);

  NewGamesAvailableSettingsController(this.store) {
    fosterdleDate = Setting(
      "${fosterdle.SettingsController.prefix}.gameState.date",
      store,
      serializer: SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
    );

    fosterdleIsCompleted = Setting("${fosterdle.SettingsController.prefix}.gameState.isCompleted", store, false);

    fosteroesDate = Setting(
      "${fosteroes.SettingsController.prefix}.${PuzzleType.daily.name}.${fosteroes.PuzzleDifficulty.easy.name}.date",
      store,
      serializer: SettingSerializer.dateTime,
      DateTime.fromMillisecondsSinceEpoch(0),
    );

    fosteroesIsCompleted = Setting(
      "${fosteroes.SettingsController.prefix}.${PuzzleType.daily.name}.${fosteroes.PuzzleDifficulty.easy.name}.isCompleted",
      store,
      false,
    );
    // We can't rely on addListener() here, since the settings getting updated in Fosterdle
    // are separate instances. Maybe make a settings source factory so we can always get the same instance
    // for a given key?

    Future.wait([
      for (var s in [fosterdleDate, fosterdleIsCompleted, fosteroesDate, fosteroesIsCompleted]) s.waitLoaded,
    ]).then((_) => update());
  }

  void update() async {
    isFosterdleNew.value =
        await fosterdleDate.update() != DateUtils.dateOnly(DateTime.now()) || !await fosterdleIsCompleted.update();

    isFosteroesNew.value =
        await fosteroesDate.update() != DateUtils.dateOnly(DateTime.now()) || !await fosteroesIsCompleted.update();
  }
}
