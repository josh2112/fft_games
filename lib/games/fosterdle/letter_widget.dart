import 'package:flutter/material.dart';

import '../../utils/flip_tile.dart';
import '../../utils/pop_tile.dart';
import 'board_state.dart';
import 'palette.dart';

class LetterWidget extends StatefulWidget {
  final LetterWithState letterWithState;
  final Palette palette;

  const LetterWidget(this.letterWithState, this.palette, {super.key});

  @override
  State<LetterWidget> createState() => _LetterWidgetState();
}

class _LetterWidgetState extends State<LetterWidget> {
  // Copy of the previous state so we can animate between the two
  LetterWithState? prev;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.letterWithState,
    builder: (context, child) {
      Widget? w;

      if (prev != null) {
        if (prev?.state != widget.letterWithState.state) {
          w = FlipTile(
            key: ValueKey(widget.letterWithState.state),
            animationDuration: Duration(milliseconds: 666),
            oldChild: tile(prev!, widget.palette),
            newChild: tile(widget.letterWithState, widget.palette),
          );
        } else if (prev?.letter != widget.letterWithState.letter && prev?.letter == '') {
          w = PopTile(
            key: ValueKey(widget.letterWithState.letter),
            animationDuration: Duration(milliseconds: 200),
            child: tile(widget.letterWithState, widget.palette),
          );
        }
      }

      prev = widget.letterWithState.copy();
      return w ?? tile(widget.letterWithState, widget.palette);
    },
  );

  Widget tile(LetterWithState lws, Palette palette) => Container(
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
    child: Center(
      child: Text(
        lws.letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    ),
  );
}
