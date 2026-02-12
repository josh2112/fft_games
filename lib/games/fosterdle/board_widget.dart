import 'package:flutter/material.dart';

import '/games/fosterdle/fosterdle.dart';
import '/utils/shake_widget.dart';
import 'board_state.dart';
import 'letter_widget.dart';

class GuessRowWidget extends StatefulWidget {
  final Guess guess;
  final Palette palette;

  const GuessRowWidget(this.guess, this.palette, {super.key});

  @override
  State<GuessRowWidget> createState() => _GuessRowWidgetState();
}

class _GuessRowWidgetState extends State<GuessRowWidget> {
  final shakeController = ShakeController();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: widget.guess.incorrectGuessStream,
    builder: (context, snapshot) {
      shakeController.shake();
      return ShakeWidget(
        controller: shakeController,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [...widget.guess.letters.map((lws) => LetterWidget(lws, widget.palette))],
        ),
      );
    },
  );
}

class BoardWidget extends StatelessWidget {
  final BoardState boardState;
  final Palette palette;

  const BoardWidget(this.boardState, this.palette, {super.key});

  @override
  Widget build(BuildContext context) {
    if (boardState.guesses.isEmpty) {
      return Center(child: SizedBox.square(dimension: 64, child: const CircularProgressIndicator(value: null)));
    } else {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (final guess in boardState.guesses) GuessRowWidget(guess, palette)],
        ),
      );
    }
  }
}
