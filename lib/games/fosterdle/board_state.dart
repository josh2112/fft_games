import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef WonGameCallback = Future<void> Function(int n);
typedef LostGameCallback = Future<void> Function(String answer);

enum LetterState { untried, notInWord, wrongPlace, rightPlace }

class LetterWithState with ChangeNotifier {
  String letter;
  LetterState state;

  LetterWithState({this.letter = '', this.state = LetterState.untried});

  LetterWithState copy() => LetterWithState(letter: letter, state: state);

  void updateLetter(String letter) {
    this.letter = letter;
    notifyListeners();
  }

  void updateLetterState(LetterState state) {
    this.state = state;
    notifyListeners();
  }
}

class LetterStateChangeEvent {
  final int index;
  final LetterState state;

  LetterStateChangeEvent(this.index, this.state);
}

enum GuessState { ok, wordNotInDictionary }

class Guess {
  final _incorrectGuessStreamController = StreamController.broadcast();

  final List<LetterWithState> letters;
  bool isSubmitted = false;

  Stream get incorrectGuessStream => _incorrectGuessStreamController.stream;

  bool get isFull => !letters.any((lws) => lws.letter.isEmpty);

  Guess(int length) : letters = List.generate(5, (v) => LetterWithState(), growable: false);

  void addLetter(String letter) {
    final i = letters.indexWhere((l) => l.letter.isEmpty);
    if (i >= 0) {
      letters[i].updateLetter(letter);
    }
  }

  void backspace() {
    final i = letters.lastIndexWhere((l) => l.letter.isNotEmpty);
    if (i >= 0) {
      letters[i].updateLetter('');
    }
  }

  Future<void> submit(List<LetterState> updatedStates) async {
    await _cascade(updatedStates);
    isSubmitted = true;
  }

  Future<void> _cascade(List<LetterState> updatedStates) async {
    for (final (i, state) in updatedStates.indexed) {
      letters[i].updateLetterState(state);
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  void fireIncorrectGuess() => _incorrectGuessStreamController.add(null);
}

class KeyboardState with ChangeNotifier {
  final Map<String, LetterState> keys = {for (var k in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split('')) k: LetterState.untried};

  LetterState state(String c) => keys[c]!;

  void setState(String c, LetterState state) => keys[c] = state;

  void notify() => notifyListeners();
}

class BoardState with ChangeNotifier {
  static final _numGuesses = 6;
  static final _epoch = DateTime(2025, 9, 23);

  final _loadCompleter = Completer<void>();

  Future<void> get isLoaded => _loadCompleter.future;

  late final HashSet<String> allowed;
  late final String word;
  final List<Guess> guesses = [];

  final WonGameCallback onWon;
  final LostGameCallback onLost;

  int _currentGuess = 0;

  bool isGameInProgress = true;

  Guess? get currentGuess => guesses.elementAtOrNull(_currentGuess);

  final KeyboardState keyboard = KeyboardState();

  BoardState({required this.onWon, required this.onLost}) {
    Future<void> init() async {
      final ls = LineSplitter();
      final wods = ls.convert(await rootBundle.loadString("assets/fosterdle/wod.txt"));
      allowed = HashSet.from(ls.convert(await rootBundle.loadString("assets/fosterdle/allowed.txt")))..addAll(wods);

      final now = DateTime.timestamp();
      final idx = now.difference(_epoch).inDays % wods.length;
      word = wods[idx].toUpperCase();
      guesses.addAll(List.generate(_numGuesses, (i) => Guess(word.length)));

      notifyListeners();
    }

    _loadCompleter.complete(init());
  }

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

  Future<SubmissionResult> submitGuess() async {
    final g = currentGuess;
    if (g is! Guess || !g.isFull) return SubmissionResult.incomplete;

    final guess = [...g.letters.map((lws) => lws.letter)];

    if (!allowed.contains(guess.join('').toLowerCase())) {
      g.fireIncorrectGuess();
      return SubmissionResult.wordNotInDictionary;
    }

    final target = word.split('');

    final updatedLetterStates = g.letters.map((lws) => lws.state).toList(growable: false);

    // First, look for letters that are in the right spot
    for (final (i, c) in guess.indexed) {
      if (target[i] == c) {
        updatedLetterStates[i] = LetterState.rightPlace;
        target[i] = '_';
      }
    }

    // Next, look for letters that are in the word but in the wrong spot
    for (final (j, c) in guess.indexed) {
      final i = target.indexOf(c);
      if (i >= 0 && updatedLetterStates[j] == LetterState.untried && target.contains(c)) {
        updatedLetterStates[j] = LetterState.wrongPlace;
        target[i] = '_';
      }
    }

    // Finally, color all other letters
    for (final (i, c) in guess.indexed) {
      if (updatedLetterStates[i] == LetterState.untried) {
        updatedLetterStates[i] = LetterState.notInWord;
      }

      if (updatedLetterStates[i].index > keyboard.state(c).index) {
        keyboard.setState(c, updatedLetterStates[i]);
      }
    }

    await g.submit(updatedLetterStates);

    await Future.delayed(Duration(milliseconds: 300));

    _currentGuess += 1;
    keyboard.notify();

    if (!updatedLetterStates.any((s) => s != LetterState.rightPlace)) {
      isGameInProgress = false;
      onWon(_currentGuess);
    } else if (_currentGuess == guesses.length) {
      isGameInProgress = false;
      onLost(word);
    }

    return SubmissionResult.ok;
  }

  Future<int> applyGameState(List<List<LetterWithState>> state, bool isComplete) async {
    isGameInProgress = false; // Ignore letter entry while we update the board

    for (int i = 0; i < state.length; ++i) {
      for (int j = 0; j < state[i].length; ++j) {
        guesses[i].letters[j].updateLetter(state[i][j].letter);
        guesses[i].letters[j].updateLetterState(state[i][j].state);
        await Future.delayed(Duration(milliseconds: 20));
      }
      guesses[i].isSubmitted = true;
      _currentGuess += 1;
    }

    isGameInProgress = !isComplete;

    if (isComplete) {
      bool won = !guesses[_currentGuess - 1].letters.any((s) => s.state != LetterState.rightPlace);
      int numGuesses = won ? _currentGuess : -1;

      return numGuesses;
    }

    return -1;
  }
}

enum SubmissionResult { ok, incomplete, wordNotInDictionary }

class HardModeCheckResult {
  static final HardModeCheckResult ok = HardModeCheckResult("");

  final int? place;
  final String letter;

  HardModeCheckResult(this.letter, {this.place});
}
