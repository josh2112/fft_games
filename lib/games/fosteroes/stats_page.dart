import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:fft_games/games/fosteroes/fosteroes.dart';
import 'package:fft_games/settings/new_game_settings_providers.dart';
import 'package:fft_games/settings/persistence/settings_persistence.dart';
import 'package:fft_games/utils/stats_widget.dart';
import 'package:fft_games/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as prov;

import '../../utils/confetti_star_path.dart';

class StatsPageParams extends PlayPageParams {
  final Duration elapsedTime;

  StatsPageParams(super.type, super.difficulty, this.elapsedTime);
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final newGamesAvail = NewGameWatcher(context.read<SettingsPersistence>());

  ConfettiController? _confettiController;

  StatsPageParams? _params;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await newGamesAvail.update();
      setState(() {});
    });
    super.initState();
  }

  bool get isAnotherGameAvailable =>
      _params?.puzzleType == PuzzleType.autogen ||
      PuzzleDifficulty.values.any((d) => true == newGamesAvail.fosteroesWatchers[d]!.isNewGameAvailable.value);

  @override
  void didChangeDependencies() {
    final params = GoRouterState.of(context).extra;
    if (params is StatsPageParams) {
      _params = params;
    }

    // Base the amount of confetti on the lengh of time to solve and puzzle difficulty
    final confettiDurationMsec = _params == null
        ? 0
        : (2000 *
                  (_params!.puzzleDifficulty.index + 1) /
                  switch (_params!.elapsedTime.inSeconds) {
                    > 15 => 1,
                    < 30 => 2,
                    < 60 => 3,
                    < 120 => 4,
                    < 300 => 5,
                    _ => 6,
                  })
              .toInt();

    _confettiController = _params == null
        ? null
        : (ConfettiController(duration: Duration(milliseconds: confettiDurationMsec))..play());

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.select((SettingsController settings) => settings);

    return Scaffold(
      appBar: AppBar(title: Text('Fosteroes Stats'), centerTitle: true),
      body: Stack(
        children: [
          if (_confettiController != null)
            Align(
              alignment: FractionalOffset(0.5, 0.1),
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.1,
                createParticlePath: drawStar,
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              if (_params != null)
                Text(
                  "You solved it!\n${_params!.elapsedTime.formatHHMMSS()}",
                  style: TextTheme.of(context).displaySmall,
                  textAlign: TextAlign.center,
                ),
              if (_params != null) const Spacer(),
              subtitle(context, "STATISTICS"),
              const SizedBox(height: 30),
              Column(
                spacing: 50,
                children: [
                  Row(
                    mainAxisAlignment: .center,
                    spacing: 50,
                    children: [
                      StatsWidget("Played", settings.numPlayed.value.toString()),
                      StatsWidget(
                        "Win %",
                        (settings.numWon.value / max(settings.numPlayed.value, 1) * 100).round().toString(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: .center,
                    spacing: 50,
                    children: [
                      StatsWidget("Current Streak", settings.currentStreak.value.toString()),
                      StatsWidget("Max Streak", settings.maxStreak.value.toString()),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              //*SolveCountsGraph(settings.solveCounts.value, widget.winLoseData),
              const Spacer(flex: 3),
              if (_params != null)
                Row(
                  mainAxisAlignment: .center,
                  spacing: 20,
                  children: [
                    ElevatedButton(onPressed: () => context.go('/'), child: Text("Home")),
                    if (isAnotherGameAvailable)
                      FilledButton(onPressed: () => context.go('/fosteroes'), child: Text("Play another")),
                  ],
                ),
              if (_params == null) ElevatedButton(onPressed: () => context.pop(), child: Text("Back")),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget subtitle(BuildContext context, String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Text(text, style: TextTheme.of(context).titleMedium),
  );
}
/*
class StatsWidget extends StatelessWidget {
  final String label, value;
  const StatsWidget(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(value, style: TextTheme.of(context).displayMedium),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

class SolveCountsGraph extends StatelessWidget {
  final List<int> solveCounts;
  final StatsPageWinLoseData? wonGameData;
  final int maxSolveCount;

  SolveCountsGraph(this.solveCounts, this.wonGameData, {super.key}) : maxSolveCount = solveCounts.reduce(max);

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < solveCounts.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 20, child: Text("${i + 1}", style: TextTheme.of(context).labelLarge)),
                  Container(
                    width: 180 - 160 * (maxSolveCount - solveCounts[i]) / max(maxSolveCount, 1),
                    color: wonGameData?.numGuesses == i + 1 ? palette.letterRightPlace : palette.letterWidgetBorder,
                    child: Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${solveCounts[i]}",
                          style: TextTheme.of(context).labelLarge!.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  solveCounts[i] == maxSolveCount ? SizedBox(width: 0) : Spacer(flex: maxSolveCount - solveCounts[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
*/