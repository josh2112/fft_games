import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'palette.dart';

class LetterWidget extends StatefulWidget {
  final LetterWithState letterWithState;
  late final LetterWithState letterWithStatePrev;

  LetterWidget(this.letterWithState, {super.key}) {
    letterWithStatePrev = LetterWithState(letterWithState.letter, letterWithState.state);
  }

  @override
  State<LetterWidget> createState() => _LetterWidgetState();
}

class _LetterWidgetState extends State<LetterWidget> {
  static final TextStyle letterStyle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  void didUpdateWidget(covariant LetterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    final border =
        widget.letterWithState.state == LetterState.notInWord || widget.letterWithState.state == LetterState.untried
        ? Border.all(color: palette.letterWidgetBorder, width: 2)
        : null;

    return AnimatedContainer(
      width: 65,
      height: 65,
      margin: EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: border,
        color: switch (widget.letterWithState.state) {
          LetterState.rightPlace => palette.letterRightPlace,
          LetterState.wrongPlace => palette.letterWrongPlace,
          _ => Colors.transparent,
        },
      ),
      duration: Duration(milliseconds: 330),
      child: Align(
        alignment: Alignment.center,
        child: Text(widget.letterWithState.letter, style: letterStyle),
      ),
    );
  }
}
