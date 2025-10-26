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
      builder: (context, child) => DragTarget<DominoState>(
        builder: (context, candidateData, rejectedData) => Container(
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.amber.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.amber : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 25,
              runSpacing: 25,
              children: [
                for (final d in handState.positions)
                  Stack(children: [DominoPlaceholder(), if (d is DominoState) DraggableDomino(d)]),
              ],
            ),
          ),
        ),
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          if (handState.tryPutBack(details.data)) {
            context.read<BoardState>().onBoard.remove(details.data);
          }
        },
      ),
    );
  }
}
