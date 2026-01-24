import 'package:fft_games/utils/shake_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov;

import 'board_state.dart';
import 'letter_widget.dart';

class GuessRowWidget extends StatefulWidget {
  final Guess guess;

  const GuessRowWidget(this.guess, {super.key});

  @override
  State<GuessRowWidget> createState() => _GuessRowWidgetState();
}

class _GuessRowWidgetState extends State<GuessRowWidget> {
  final shakeController = ShakeController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.guess.incorrectGuessStream,
      builder: (context, snapshot) {
        shakeController.shake();
        return ShakeWidget(
          controller: shakeController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [...widget.guess.letters.map((lws) => LetterWidget(lws))],
          ),
        );
      },
    );
  }
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    if (boardState.guesses.isEmpty) {
      return Center(child: SizedBox.square(dimension: 64, child: const CircularProgressIndicator(value: null)));
    } else {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (final guess in boardState.guesses) GuessRowWidget(guess)],
        ),
      );
    }
  }
}
