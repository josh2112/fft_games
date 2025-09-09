import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';

class LetterWidget extends StatelessWidget {
  final LetterWithState letterWithState;

  static final Map<LetterState, Color> letterStateToColor = {
    LetterState.untried: Colors.black,
    LetterState.notInWord: Colors.black,
    LetterState.wrongPlace: Colors.orange,
    LetterState.rightPlace: Colors.green,
  };

  const LetterWidget(this.letterWithState, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: 50,
      height: 50,
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 3),
        color: letterStateToColor[letterWithState.state],
      ),
      duration: Duration(milliseconds: 330),
      child: Align(
        alignment: Alignment.center,
        child: Text(letterWithState.letter, style: Theme.of(context).textTheme.headlineLarge),
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
