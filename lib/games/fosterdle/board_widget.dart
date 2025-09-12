import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'letter_widget.dart';

// TODO: Cache current guess
// In didUpdateWidget(), see what letters have changed and rebuild them

class GuessRowWidget extends StatefulWidget {
  final Guess guess;

  const GuessRowWidget(this.guess, {super.key});

  @override
  State<GuessRowWidget> createState() => _GuessRowWidgetState();
}

class _GuessRowWidgetState extends State<GuessRowWidget> {
  @override
  void didUpdateWidget(covariant GuessRowWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [...widget.guess.letters.map((lws) => LetterWidget(lws))],
  );
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final guess in boardState.guesses)
            ListenableBuilder(listenable: guess, builder: (context, child) => GuessRowWidget(guess)),
        ],
      ),
    );
  }
}
