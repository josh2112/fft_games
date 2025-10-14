import 'dart:convert';

import 'package:fft_games/games/fosterdle/board_state.dart';
import 'package:fft_games/settings/setting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game state serialization', () {
    final guesses = [
      [
        LetterWithState(letter: 'a', state: LetterState.rightPlace),
        LetterWithState(letter: 'c', state: LetterState.wrongPlace),
        LetterWithState(letter: 'a', state: LetterState.rightPlace),
      ],
    ];

    final serializer = SettingSerializer<List<List<LetterWithState>>>(
      (guesses) =>
          jsonEncode(guesses.map((letters) => letters.map((lws) => "${lws.letter}${lws.state.index}").join()).toList()),
      (str) => [
        for (final letters in jsonDecode(str))
          [
            for (int i = 0; i < letters.length; i += 2)
              LetterWithState(letter: letters[i], state: LetterState.values[int.parse(letters[i + 1])]),
          ],
      ],
    );

    final json = serializer.serialize(guesses);
    print(json);
    final g2 = serializer.deserialize(json);
    print(g2);
  });
}
