import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'palette.dart';

class LetterWidget extends StatefulWidget {
  final LetterWithState letterWithState;

  const LetterWidget(this.letterWithState, {super.key});

  @override
  State<LetterWidget> createState() => _LetterWidgetState();
}

class _LetterWidgetState extends State<LetterWidget> with TickerProviderStateMixin {
  static final TextStyle letterStyle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  );

  LetterWithState? prev;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 60),
    vsync: this,
  );

  late final _bounceAnimation = Tween<double>(
    begin: 1,
    end: 1.2,
  ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return ListenableBuilder(
      listenable: widget.letterWithState,
      builder: (context, child) {
        Widget? w;
        if (prev != null && prev != widget.letterWithState) {
          // Determine what changed
          final cur = widget.letterWithState;

          if (cur.letter != prev!.letter) {
            // Do scale
            log("Scale transition");
            _animationController.repeat(reverse: true, count: 2);
            w = ScaleTransition(scale: _bounceAnimation, child: letterWidget(palette));
          } else if (cur.state != prev!.state) {
            // Do flip
            log("Flip transition");
            w = AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: letterWidget(palette),
            );
          }
        }

        prev = widget.letterWithState.copy();
        return w ??= letterWidget(palette);
      },
    );
  }

  Widget letterWidget(Palette palette, {Key? key}) {
    final border =
        widget.letterWithState.state == LetterState.notInWord ||
            widget.letterWithState.state == LetterState.untried
        ? Border.all(color: palette.letterWidgetBorder, width: 2)
        : null;

    return Container(
      key: key,
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
      child: Align(
        alignment: Alignment.center,
        child: Text(widget.letterWithState.letter, style: letterStyle),
      ),
    );
  }
}
