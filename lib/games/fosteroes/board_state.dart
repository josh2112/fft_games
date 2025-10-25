import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'puzzle.dart';

class DominoState {
  final int side1, side2;

  int rotation = 0;

  DominoState(this.side1, this.side2);
}

class BoardState {
  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  final hand = <DominoState>[];
  final onBoard = <DominoState, Offset>{};
  DominoState? inTransition;

  BoardState() {
    loadPuzzle('assets/fosteroes/testpuzzles/puzzle2.json');
  }

  Future loadPuzzle(String path) async {
    final puzz = await Puzzle.fromJsonFile(path);
    hand.clear();
    hand.addAll(puzz.dominoes);
    onBoard.clear();
    inTransition = null;
    puzzle.value = puzz;
  }
}
