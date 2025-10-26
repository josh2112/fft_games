import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';

class Hand extends StatelessWidget {
  const Hand({super.key});

  @override
  Widget build(BuildContext context) {
    final handState = context.watch<BoardState>().inHand;

    return ListenableBuilder(
      listenable: handState,
      builder: (context, child) => Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final d in handState.positions)
            if (d is DominoState) DraggableDomino(d) else DominoPlaceholder(),
        ],
      ),
    );
  }
}
