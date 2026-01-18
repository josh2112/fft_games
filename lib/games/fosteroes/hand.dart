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

  Widget dominoHolderWidget(List<Widget> children) => GridView.extent(
    padding: const EdgeInsets.all(8.0),
    childAspectRatio: 2,
    maxCrossAxisExtent: 150,
    mainAxisSpacing: 9,
    crossAxisSpacing: 9,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: children,
  );

  @override
  Widget build(BuildContext context) {
    final handState = context.select((BoardState bs) => bs.inHand);

    return ListenableBuilder(
      listenable: handState,
      builder: (context, child) => DragTarget<DominoState>(
        builder: (context, candidateData, rejectedData) => Container(
          decoration: candidateData.isNotEmpty ? highlightBox : normalBox,
          child: Stack(
            children: [
              dominoHolderWidget([for (final _ in handState.positions) Center(child: DominoPlaceholder())]),
              dominoHolderWidget([
                for (final d in handState.positions)
                  if (d is DominoState)
                    Center(child: Domino(d))
                  else
                    Visibility(visible: false, child: DominoPlaceholder()),
              ]),
            ],
          ),
        ),
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          if (handState.tryPutBack(details.data)) {
            final boardState = context.read<BoardState>();
            details.data.location.value == DominoLocation.hand;
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
