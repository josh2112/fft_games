import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:flutter/material.dart';

typedef KeyPressedCallback = void Function(String key);

mixin KeyboardAdapter {
  void onLetter(String letter);
  void onBackspace();
  void onSubmit();
}

class KeyboardWidget extends StatelessWidget {
  final KeyboardAdapter adapter;

  final Map<String, LetterState> letterStates;

  static final Map<LetterState, WidgetStateProperty<Color>> letterStateToColor = {
    LetterState.untried: WidgetStateProperty.all<Color>(Colors.grey),
    LetterState.notInWord: WidgetStateProperty.all<Color>(Colors.grey[800]!),
    LetterState.wrongPlace: WidgetStateProperty.all<Color>(Colors.orange),
    LetterState.rightPlace: WidgetStateProperty.all<Color>(Colors.green),
  };

  final keyButtonPadding = EdgeInsets.symmetric(horizontal: 0, vertical: 20);
  final controlButtonPadding = WidgetStateProperty.all<EdgeInsetsGeometry>(
    EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  );

  final ButtonStyle keyboardButtonStyle = FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
  );

  final double _keySpacing = 5.0;

  KeyboardWidget({required this.adapter, required this.letterStates, super.key});

  Widget _keyButton(String letter) => FilledButton(
    onPressed: () => adapter.onLetter(letter),
    style: keyboardButtonStyle.copyWith(backgroundColor: letterStateToColor[letterStates[letter]]),
    child: Text(letter),
  );

  Widget _controlButton(VoidCallback onPressed, Widget child) => FilledButton(
    onPressed: onPressed,
    style: keyboardButtonStyle.copyWith(
      backgroundColor: letterStateToColor[LetterState.untried],
      padding: controlButtonPadding,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: _keySpacing,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,
          children: [...'QWERTYUIOP'.split('').map((ltr) => _keyButton(ltr))],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,

          children: [...'ASDFGHJKL'.split('').map((ltr) => _keyButton(ltr))],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: _keySpacing,
          children: [
            _controlButton(adapter.onSubmit, Text("ENTER")),
            ...'ZXCVBNM'.split('').map((ltr) => _keyButton(ltr)),
            _controlButton(adapter.onBackspace, Icon(Icons.backspace_outlined)),
          ],
        ),
      ],
    );
  }
}
