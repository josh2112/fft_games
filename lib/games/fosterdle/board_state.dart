import 'dart:async';

typedef WonGameCallback = Future<void> Function(int n);

enum LetterState { untried, notInWord, wrongPlace, rightPlace }

class LetterWithState {
  String letter;
  LetterState state;

  LetterWithState(this.letter, this.state);
}

class Guess {
  final List<LetterWithState> letters = List.generate(5, (v) => LetterWithState('', LetterState.untried));

  bool get isFull => !letters.any((lws) => lws.letter.isEmpty);

  bool addLetter(String letter) {
    final idx = letters.indexWhere((l) => l.letter.isEmpty);
    if (idx >= 0) letters[idx].letter = letter;
    return idx >= 0;
  }

  bool backspace() {
    final idx = letters.lastIndexWhere((l) => l.letter.isNotEmpty);
    if (idx >= 0) letters[idx].letter = '';
    return idx >= 0;
  }
}

class BoardState {
  final String word;

  final WonGameCallback onWin;

  final List<Guess> guesses = List.generate(5, (i) => Guess());

  int _currentGuess = 0;

  Guess? get currentGuess => guesses.elementAtOrNull(_currentGuess);

  final Map<String, LetterState> keyboardState = {
    for (var k in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split('')) k: LetterState.untried,
  };

  final StreamController<void> _keyboardStateChanges = StreamController<void>.broadcast();
  final StreamController<void> _guessStateChanges = StreamController<void>.broadcast();

  Stream<void> get keyboardStateChanges => _keyboardStateChanges.stream;
  Stream<void> get guessStateChanges => _guessStateChanges.stream;

  BoardState({required String word, required this.onWin}) : word = word.toUpperCase();

  void addLetter(String letter) {
    if (true == currentGuess?.addLetter(letter)) _guessStateChanges.add(null);
  }

  void removeLetter() {
    if (true == currentGuess?.backspace()) _guessStateChanges.add(null);
  }

  void submitGuess() {
    final g = currentGuess;
    if (g is! Guess || !g.isFull) return;

    final guess = [...g.letters.map((lws) => lws.letter)];
    final target = word.split('');

    // First, look for letters that are in the right spot
    for (final (i, c) in guess.indexed) {
      if (target[i] == c) {
        g.letters[i].state = LetterState.rightPlace;
        target[i] = '_';
      }
    }

    // Next, look for letters that are in the word but in the wrong spot
    for (final c in guess) {
      final i = target.indexOf(c);
      if (i >= 0 && g.letters[i].state == LetterState.untried && target.contains(c)) {
        g.letters[i].state = LetterState.wrongPlace;
        target[i] = '_';
      }
    }

    // Finally, color all other letters
    for (final (i, c) in guess.indexed) {
      if (g.letters[i].state == LetterState.untried) g.letters[i].state == LetterState.notInWord;

      final state = g.letters[i].state;
      if (state.index > keyboardState[c]!.index) keyboardState[c] = state;
    }

    _currentGuess += 1;
    _keyboardStateChanges.add(null);
    _guessStateChanges.add(null);
  }

  void dispose() {}
}
