import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'puzzle.dart';

class DominoState {
  final int side1, side2;
  int rotation = 0;

  DominoState(this.side1, this.side2);
}

class HandState extends ChangeNotifier {
  var _positions = <DominoState?>[];

  List<DominoState?> get positions => _positions;

  HandState();

  void set(List<DominoState> initialSet) {
    _positions = List<DominoState?>.from(initialSet, growable: false);
    notifyListeners();
  }

  void remove(DominoState domino) {
    int i = _positions.indexOf(domino);
    if (i != -1) {
      _positions[i] = null;
      notifyListeners();
    }
  }
}

class BoardState {
  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  final inHand = HandState();
  final onBoard = <DominoState, Offset>{};

  BoardState() {
    loadPuzzle('assets/fosteroes/testpuzzles/puzzle2.json');
  }

  Future loadPuzzle(String path) async {
    final puzz = await Puzzle.fromJsonFile(path);
    inHand.set(puzz.dominoes);
    onBoard.clear();
    puzzle.value = puzz;
  }
}
