import 'dart:math';

import 'package:fft_games/games/fosterdle/palette.dart';
import 'package:fft_games/games/fosterdle/settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StatsPageWinLoseData {
  final String word;
  final int numGuesses;

  const StatsPageWinLoseData(this.numGuesses, this.word);
}

class StatsPage extends StatelessWidget {
  final StatsPageWinLoseData? winLoseData;

  const StatsPage({super.key, this.winLoseData});

  @override
  Widget build(BuildContext context) {
    final String? message = switch (winLoseData?.numGuesses) {
      null => null,
      < 0 => "The word was ${winLoseData!.word}. Better luck tomorrow!",
      _ => 'You won!',
    };

    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text('Fosterdle Stats'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          if (message != null) Text(message, style: TextTheme.of(context).displaySmall, textAlign: TextAlign.center),
          if (message != null) const Spacer(),
          subtitle(context, "STATISTICS"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              StatsWidget("Played", settings.numPlayed.value.toString()),
              StatsWidget("Win %", (settings.numWon.value / max(settings.numPlayed.value, 1) * 100).round().toString()),
              StatsWidget("Current Streak", settings.currentStreak.value.toString()),
              StatsWidget("Max Streak", settings.maxStreak.value.toString()),
            ],
          ),
          const Spacer(),
          subtitle(context, "GUESS DISTRIBUTION"),
          SolveCountsGraph(settings.solveCounts.value, winLoseData),
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: () {
              if (winLoseData != null) {
                context.go('/');
              } else {
                context.pop();
              }
            },
            child: Text(winLoseData != null ? "Home" : 'Back'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget subtitle(BuildContext context, String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Text(text, style: TextTheme.of(context).titleMedium),
  );
}

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
