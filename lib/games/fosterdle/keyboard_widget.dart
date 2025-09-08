import 'package:flutter/material.dart';

class KeyboardWidget extends StatelessWidget {
  const KeyboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: 'QWERTYUIOP'
              .split('')
              .map((ltr) => FilledButton(onPressed: _onKeyPressed, child: Text(ltr)))
              .toList(growable: false),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: 'ASDFGHJKL'
              .split('')
              .map((ltr) => FilledButton(onPressed: _onKeyPressed, child: Text(ltr)))
              .toList(growable: false),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(onPressed: _onEnterKeyPressed, child: Text("ENTER")),
            ...'ZXCVBNM'.split('').map((ltr) => FilledButton(onPressed: _onKeyPressed, child: Text(ltr))),

            FilledButton(onPressed: _onEnterKeyPressed, child: Icon(Icons.backspace_outlined)),
          ],
        ),
      ],
    );
  }

  void _onKeyPressed() {}
  void _onEnterKeyPressed() {}
}
