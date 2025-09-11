import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'palette.dart';

typedef KeyPressedCallback = void Function(String key);

mixin KeyboardAdapter {
  void onLetter(String letter);
  void onBackspace();
  void onSubmit();
}

class KeyboardWidget extends StatelessWidget {
  final KeyboardAdapter adapter;

  final Map<String, LetterState> letterStates;

  static final ButtonStyle _keyboardButtonStyle = FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    foregroundColor: Colors.white,
    padding: EdgeInsets.zero,
  );

  static final TextStyle _keyTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.proportional,
  );

  final double _keySpacingHoriz = 5.0;
  final double _keySpacingVert = 6.0;
  final double _keyHeight = 56;

  const KeyboardWidget({required this.adapter, required this.letterStates, super.key});

  Widget _bc2(Widget b) => Flexible(
    flex: 2,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: _keyHeight, maxHeight: _keyHeight, maxWidth: 45),
      child: b,
    ),
  );

  Widget _bc3(Widget b) => Flexible(
    flex: 3,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: _keyHeight, maxHeight: _keyHeight, maxWidth: 60),
      child: b,
    ),
  );

  Widget halfKeySpace() => Flexible(flex: 1, child: SizedBox(height: 60));

  Widget _keyButton(String letter, Palette pal, BuildContext ctx) => _bc2(
    FilledButton(
      onPressed: () => adapter.onLetter(letter),
      style: _keyboardButtonStyle.copyWith(
        backgroundColor: switch (letterStates[letter]) {
          LetterState.rightPlace => WidgetStateProperty.all<Color>(pal.letterRightPlace),
          LetterState.wrongPlace => WidgetStateProperty.all<Color>(pal.letterWrongPlace),
          LetterState.notInWord => pal.keyboardKeyNotInWord,
          _ => pal.keyboardKey,
        },
      ),
      child: Text(letter, style: _keyTextStyle),
    ),
  );

  Widget _controlButton(VoidCallback onPressed, Widget child, Palette pal) => _bc3(
    FilledButton(
      onPressed: onPressed,
      style: _keyboardButtonStyle.copyWith(backgroundColor: pal.keyboardKey),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Column(
      spacing: _keySpacingVert,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacingHoriz,
          children: [...'QWERTYUIOP'.split('').map((ltr) => _keyButton(ltr, palette, context))],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacingHoriz,

          children: [
            halfKeySpace(),
            ...'ASDFGHJKL'.split('').map((ltr) => _keyButton(ltr, palette, context)),
            halfKeySpace(),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacingHoriz,
          children: [
            _controlButton(adapter.onSubmit, Text("ENTER"), palette),
            ...'ZXCVBNM'.split('').map((ltr) => _keyButton(ltr, palette, context)),
            _controlButton(adapter.onBackspace, Icon(Icons.backspace_outlined), palette),
          ],
        ),
      ],
    );
  }
}
