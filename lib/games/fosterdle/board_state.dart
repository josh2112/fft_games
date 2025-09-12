import 'dart:async';

import 'package:flutter/material.dart';

typedef WonGameCallback = Future<void> Function(int n);
typedef LostGameCallback = Future<void> Function(String answer);

enum LetterState { untried, notInWord, wrongPlace, rightPlace }

class LetterWithState {
  final String letter;
  final LetterState state;
  final bool submitted;

  LetterWithState({this.letter = '', this.state = LetterState.untried, this.submitted = false});

  LetterWithState copyWith({String? letter, LetterState? state, bool? submitted}) => LetterWithState(
    letter: letter ?? this.letter,
    state: state ?? this.state,
    submitted: submitted ?? this.submitted,
  );
}

class Guess with ChangeNotifier {
  final List<LetterWithState> letters = List.generate(5, (v) => LetterWithState());

  bool isSubmitted = false;

  bool get isFull => !letters.any((lws) => lws.letter.isEmpty);

  void addLetter(String letter) {
    final idx = letters.indexWhere((l) => l.letter.isEmpty);
    if (idx >= 0) {
      letters[idx] = letters[idx].copyWith(letter: letter);
      notifyListeners();
    }
  }

  void backspace() {
    final idx = letters.lastIndexWhere((l) => l.letter.isNotEmpty);
    if (idx >= 0) {
      letters[idx] = letters[idx].copyWith(letter: '');
      notifyListeners();
    }
  }
}

class BoardState {
  final String word;

  final WonGameCallback onWon;
  final LostGameCallback onLost;

  final List<Guess> guesses = List.generate(6, (i) => Guess());

  int _currentGuess = 0;

  Guess? get currentGuess => guesses.elementAtOrNull(_currentGuess);

  final Map<String, LetterState> keyboardState = {
    for (var k in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split('')) k: LetterState.untried,
  };

  final StreamController<void> _keyboardStateChanges = StreamController<void>.broadcast();

  Stream<void> get keyboardStateChanges => _keyboardStateChanges.stream;

  BoardState({required String word, required this.onWon, required this.onLost}) : word = word.toUpperCase();

  void addLetter(String letter) => currentGuess?.addLetter(letter);

  void removeLetter() => currentGuess?.backspace();

  HardModeCheckResult checkHardMode() {
    final g = currentGuess;
    if (_currentGuess == 0 || g is! Guess || !g.isFull) return HardModeCheckResult.ok;

    final guess = [...g.letters.map((lws) => lws.letter)];
    final prevGuess = guesses.elementAt(_currentGuess - 1).letters;

    final prevRight = prevGuess.indexed.where((item) => item.$2.state == LetterState.rightPlace);

    // Xth letter must be X
    for (final rp in prevRight) {
      if (guess[rp.$1] != rp.$2.letter) {
        return HardModeCheckResult(rp.$2.letter, place: rp.$1);
      }
    }

    // wrong-place letters in previous guess
    final prevWrong = [
      ...prevGuess.indexed.where((item) => item.$2.state == LetterState.wrongPlace).map((item) => item.$2.letter),
    ];

    final rightIndices = [...prevRight.map((item) => item.$1)];

    // remaining letters in new guess (after right place have been checked)
    final guessRemaining = [...guess.indexed.where((item) => !rightIndices.contains(item.$1)).map((item) => item.$2)];

    // Guess must contain X
    for (String ltr in prevWrong) {
      final i = guessRemaining.indexOf(ltr);
      if (i < 0) {
        return HardModeCheckResult(ltr);
      }
      guessRemaining.removeAt(i);
    }

    return HardModeCheckResult.ok;
  }

  void submitGuess() {
    final g = currentGuess;
    if (g is! Guess || !g.isFull) return;

    g.isSubmitted = true;

    final guess = [...g.letters.map((lws) => lws.letter)];
    final target = word.split('');

    // First, look for letters that are in the right spot
    for (final (i, c) in guess.indexed) {
      if (target[i] == c) {
        g.letters[i] = g.letters[i].copyWith(state: LetterState.rightPlace);
        target[i] = '_';
      }
    }

    // Next, look for letters that are in the word but in the wrong spot
    for (final (j, c) in guess.indexed) {
      final i = target.indexOf(c);
      if (i >= 0 && g.letters[j].state == LetterState.untried && target.contains(c)) {
        g.letters[j] = g.letters[i].copyWith(state: LetterState.wrongPlace);
        target[i] = '_';
      }
    }

    // Finally, color all other letters
    for (final (i, c) in guess.indexed) {
      if (g.letters[i].state == LetterState.untried) {
        g.letters[i] = g.letters[i].copyWith(state: LetterState.notInWord);
      }

      final state = g.letters[i].state;
      if (state.index > keyboardState[c]!.index) keyboardState[c] = state;
    }

    _currentGuess += 1;
    _keyboardStateChanges.add(null);

    if (!g.letters.any((lws) => lws.state != LetterState.rightPlace)) {
      onWon(_currentGuess);
    } else if (_currentGuess == guesses.length) {
      onLost(word);
    }
  }

  void dispose() {}
}

class HardModeCheckResult {
  static final HardModeCheckResult ok = HardModeCheckResult("");

  final int? place;
  final String letter;

  HardModeCheckResult(this.letter, {this.place});
}
