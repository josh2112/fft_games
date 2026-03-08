import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/games/fosterdle/providers.dart';
import '/utils/confetti_star_path.dart';
import 'palette.dart';

class StatsPageWinLoseData {
  final String word;
  final int numGuesses;

  bool get didWin => numGuesses >= 1 && numGuesses <= 6;

  const StatsPageWinLoseData(this.numGuesses, this.word);
}

class StatsPage extends ConsumerStatefulWidget {
  final StatsPageWinLoseData? winLoseData;

  const StatsPage({super.key, this.winLoseData});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late ConfettiController? _confettiController;

  @override
  void initState() {
    final confettiDurationMsec = (true == widget.winLoseData?.didWin) ? 2000 / widget.winLoseData!.numGuesses : 0;

    if (confettiDurationMsec > 0) {
      _confettiController = ConfettiController(duration: Duration(milliseconds: confettiDurationMsec.toInt()));
      _confettiController!.play();
    } else {
      _confettiController = null;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String? message = switch (widget.winLoseData?.numGuesses) {
      null => null,
      1 => 'Incredible! 😃',
      2 => 'Great! ☺️',
      3 => 'Well done! 😬',
      4 => 'Ok! 😐',
      5 => 'Whew! 🥴',
      6 => 'What a squeaker! 😰',
      _ => "The word was ${widget.winLoseData!.word}. Better luck tomorrow!",
    };

    final settings = ref.watch(settingsProvider);
    final palette = ref.watch(paletteProvider);

    final numPlayedState = ref.watch(settings.numPlayed);
    final numWonState = ref.watch(settings.numWon);
    final currentStreakState = ref.watch(settings.currentStreak);
    final maxStreakState = ref.watch(settings.maxStreak);
    final solveCountState = ref.watch(settings.solveCounts);

    if (!numPlayedState.hasValue ||
        !numWonState.hasValue ||
        !currentStreakState.hasValue ||
        !maxStreakState.hasValue ||
        !solveCountState.hasValue) {
      return const CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Fosterdle Stats'), centerTitle: true),
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
              if (message != null)
                Text(message, style: TextTheme.of(context).displaySmall, textAlign: TextAlign.center),
              if (message != null) const Spacer(),
              subtitle(context, "STATISTICS"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(numPlayedState.value!.toString(), style: TextTheme.of(context).displayMedium),
                      Text("Played", textAlign: TextAlign.center),
                      SizedBox(height: 20),
                      Text(currentStreakState.value!.toString(), style: TextTheme.of(context).displayMedium),
                      Text("Current Streak", textAlign: TextAlign.center),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        (numWonState.value! / max(numPlayedState.value!, 1) * 100).round().toString(),
                        style: TextTheme.of(context).displayMedium,
                      ),
                      Text("Win %", textAlign: TextAlign.center),
                      SizedBox(height: 20),
                      Text(maxStreakState.value!.toString(), style: TextTheme.of(context).displayMedium),
                      Text("Max Streak", textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              subtitle(context, "GUESS DISTRIBUTION"),
              SolveCountsGraph(solveCountState.value!, widget.winLoseData, palette),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () {
                  if (widget.winLoseData != null) {
                    context.go('/');
                  } else {
                    context.pop();
                  }
                },
                child: Text(widget.winLoseData != null ? "Home" : 'Back'),
              ),
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

class SolveCountsGraph extends StatelessWidget {
  final Palette palette;
  final List<int> solveCounts;
  final StatsPageWinLoseData? wonGameData;
  final int maxSolveCount;

  SolveCountsGraph(this.solveCounts, this.wonGameData, this.palette, {super.key})
    : maxSolveCount = solveCounts.reduce(max);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
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
