import 'dart:math' hide log;

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

enum _Transition { pop, flip }

class _LetterWidgetState extends State<LetterWidget> {
  static final TextStyle letterStyle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  );

  LetterWithState? prev;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return ListenableBuilder(
      listenable: widget.letterWithState,
      builder: (context, child) {
        // If the letter changed, do a pop animation (scale up and back down). If the state
        // changed, do a flip animation.
        final which = prev?.state == widget.letterWithState.state ? _Transition.pop : _Transition.flip;
        final w = AnimatedSwitcher(
          duration: switch (which) {
            _Transition.pop => Duration(milliseconds: 250),
            _Transition.flip => Duration(milliseconds: 500),
          },
          transitionBuilder: switch (which) {
            _Transition.pop => _popTransitionBuilder,
            _Transition.flip => _flipTransitionBuilder,
          },
          layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
          child: letterWidget(palette),
        );

        prev = widget.letterWithState.copy();
        return w;
      },
    );
  }

  Widget _popTransitionBuilder(Widget widget, Animation<double> animation) {
    final scaleAnim = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.ease)),
        weight: 50.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.ease)),
        weight: 50.0,
      ),
    ]).animate(animation);

    return AnimatedBuilder(
      animation: scaleAnim,
      child: widget,
      builder: (context, child) {
        // This is called once per widget for each animation frame. The old and new widgets must
        // have unique keys so we can tell which one we're animating here!
        final isOldWidget = keyForState(this.widget.letterWithState) != widget.key;

        final value = isOldWidget ? 0.0 : scaleAnim.value;

        return Transform.scale(scale: value, alignment: Alignment.center, child: child!);
      },
    );
  }

  Widget _flipTransitionBuilder(Widget widget, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);

    return AnimatedBuilder(
      animation: rotateAnim,
      child: widget,
      builder: (context, child) {
        var tilt = ((animation.value - 0.5).abs() - 0.5) * -0.003;

        final value = min(rotateAnim.value, pi / 2);

        return Transform(
          transform: Matrix4.rotationX(value)..setEntry(3, 1, tilt),
          alignment: Alignment.center,
          child: child!,
        );
      },
    );
  }

  static ValueKey keyForState(LetterWithState? lws) => ValueKey((lws?.letter, lws?.state.index));

  Widget letterWidget(Palette palette) {
    final lws = widget.letterWithState;
    return Container(
      key: keyForState(lws),
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
      child: Align(
        alignment: Alignment.center,
        child: Text(lws.letter, style: letterStyle),
      ),
    );
  }
}
