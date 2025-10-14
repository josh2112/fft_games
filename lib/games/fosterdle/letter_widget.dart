import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/flip_tile.dart';
import '../../utils/pop_tile.dart';
import 'board_state.dart';
import 'palette.dart';

class LetterWidget extends StatefulWidget {
  final LetterWithState letterWithState;

  const LetterWidget(this.letterWithState, {super.key});

  @override
  State<LetterWidget> createState() => _LetterWidgetState();
}

class _LetterWidgetState extends State<LetterWidget> {
  static final TextStyle letterStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // Copy of the previous state so we can animate between the two
  LetterWithState? prev;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return ListenableBuilder(
      listenable: widget.letterWithState,
      builder: (context, child) {
        Widget? w;

        if (prev != null) {
          if (prev?.letter != widget.letterWithState.letter && prev?.letter == '') {
            w = PopTile(
              key: ValueKey(widget.letterWithState.letter),
              animationDuration: Duration(milliseconds: 200),
              child: tile(widget.letterWithState, palette),
            );
          } else if (prev?.state != widget.letterWithState.state) {
            w = FlipTile(
              key: ValueKey(widget.letterWithState.state),
              animationDuration: Duration(milliseconds: 666),
              oldChild: tile(prev!, palette),
              newChild: tile(widget.letterWithState, palette),
            );
          }
        }

        prev = widget.letterWithState.copy();
        return w ?? tile(widget.letterWithState, palette);
      },
    );
  }

  Widget tile(LetterWithState lws, Palette palette) {
    return Container(
      width: 65,
      height: 65,
      margin: EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: lws.state == LetterState.notInWord || lws.state == LetterState.untried
            ? Border.all(color: palette.letterWidgetBorder, width: 2)
            : null,
        borderRadius: BorderRadius.circular(10),
        color: switch (lws.state) {
          LetterState.rightPlace => palette.letterRightPlace,
          LetterState.wrongPlace => palette.letterWrongPlace,
          _ => Theme.of(context).canvasColor,
        },
      ),
      child: Center(child: Text(lws.letter, style: letterStyle)),
    );
  }
}
