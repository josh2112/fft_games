import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';

class Hand extends StatelessWidget {
  static final BoxDecoration normalBox = BoxDecoration(
    border: Border.all(color: Colors.transparent, width: 2),
    borderRadius: BorderRadius.circular(10),
  );
  static final BoxDecoration highlightBox = BoxDecoration(
    color: Colors.amber.withValues(alpha: 0.2),
    border: Border.all(color: Colors.amber, width: 2),
    borderRadius: BorderRadius.circular(10),
  );

  const Hand({super.key});

  @override
  Widget build(BuildContext context) {
    final handState = context.select((BoardState bs) => bs.inHand);

    return ListenableBuilder(
      listenable: handState,
      builder: (context, child) => DragTarget<DominoState>(
        builder: (context, candidateData, rejectedData) => Container(
          decoration: candidateData.isNotEmpty ? highlightBox : normalBox,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 25,
              runSpacing: 25,
              children: [
                for (final d in handState.positions)
                  Stack(clipBehavior: Clip.none, children: [DominoPlaceholder(), if (d is DominoState) Domino(d)]),
              ],
            ),
          ),
        ),
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          if (handState.tryPutBack(details.data)) {
            final boardState = context.read<BoardState>();
            details.data.location == DominoLocation.hand;
            details.data.quarterTurns.value = 0;
            if (boardState.floatingDomino.value?.domino == details.data) {
              boardState.floatingDomino.value = null;
            } else {
              boardState.onBoard.remove(details.data);
            }
          }
        },
      ),
    );
  }
}
