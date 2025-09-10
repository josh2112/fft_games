import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'palette.dart';

class LetterWidget extends StatelessWidget {
  final LetterWithState letterWithState;

  static final TextStyle letterStyle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  );

  const LetterWidget(this.letterWithState, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    final border = letterWithState.state == LetterState.notInWord || letterWithState.state == LetterState.untried
        ? Border.all(color: Colors.grey[800]!, width: 2)
        : null;

    return AnimatedContainer(
      width: 62,
      height: 62,
      margin: EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: border,
        color: switch (letterWithState.state) {
          LetterState.rightPlace => palette.letterRightPlace,
          LetterState.wrongPlace => palette.letterWrongPlace,
          _ => Colors.transparent,
        },
      ),
      duration: Duration(milliseconds: 330),
      child: Align(
        alignment: Alignment.center,
        child: Text(letterWithState.letter, style: letterStyle),
      ),
    );
  }
}

class GuessWidget extends StatelessWidget {
  final Guess guess;
  const GuessWidget(this.guess, {super.key});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [...guess.letters.map((lws) => LetterWidget(lws))]);
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    return StreamBuilder(
      stream: boardState.guessStateChanges,
      builder: (context, child) => Column(children: [...boardState.guesses.map((g) => GuessWidget(g))]),
    );
  }
}
