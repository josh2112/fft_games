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

  final double _keySpacing = 7.0;

  const KeyboardWidget({required this.adapter, required this.letterStates, super.key});

  Widget _keyButton(String letter, Palette pal) => SizedBox(
    width: 45,
    height: 60,
    child: FilledButton(
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

  Widget _controlButton(VoidCallback onPressed, Widget child, Palette pal) => SizedBox(
    width: 70,
    height: 60,
    child: FilledButton(
      onPressed: onPressed,
      style: _keyboardButtonStyle.copyWith(backgroundColor: pal.keyboardKey),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Column(
      spacing: _keySpacing,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,
          children: [...'QWERTYUIOP'.split('').map((ltr) => _keyButton(ltr, palette))],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,

          children: [...'ASDFGHJKL'.split('').map((ltr) => _keyButton(ltr, palette))],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,
          children: [
            _controlButton(adapter.onSubmit, Text("ENTER"), palette),
            ...'ZXCVBNM'.split('').map((ltr) => _keyButton(ltr, palette)),
            _controlButton(adapter.onBackspace, Icon(Icons.backspace_outlined), palette),
          ],
        ),
      ],
    );
  }
}
