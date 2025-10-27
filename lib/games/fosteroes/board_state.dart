import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'puzzle.dart';

class DominoState {
  final int side1, side2;
  int quarterTurns = 0;

  DominoState(this.side1, this.side2);

  Set<Offset> area(Offset baseCell) => switch (quarterTurns % 4) {
    0 => {baseCell, baseCell.translate(1, 0)},
    1 => {baseCell, baseCell.translate(0, 1)},
    2 => {baseCell, baseCell.translate(-1, 0)},
    _ => {baseCell, baseCell.translate(0, -1)},
  };
}

class HandDominoes extends ChangeNotifier {
  var _positions = <DominoState?>[];

  List<DominoState?> get positions => _positions;

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

  bool tryPutBack(DominoState domino) {
    if (_positions.contains(domino)) return false;
    _positions[_positions.indexWhere((ds) => ds == null)] = domino;
    notifyListeners();
    return true;
  }
}

class BoardDominoes extends ChangeNotifier {
  final _dominoes = <DominoState, Offset>{};

  Map<DominoState, Offset> get dominoes => _dominoes;

  void clear() {
    _dominoes.clear();
    notifyListeners();
  }

  void add(DominoState domino, Offset position) {
    _dominoes[domino] = position;
    notifyListeners();
  }

  void remove(DominoState domino) {
    _dominoes.remove(domino);
    notifyListeners();
  }

  bool canPlace(DominoState domino, Offset cell) {
    var dominoCells = domino.area(cell);
    var allCells = dominoes.entries.map((e) => e.key.area(e.value)).flattened.toSet().difference(dominoCells);
    return !dominoCells.any((c) => allCells.contains(c));
  }
}

class BoardState {
  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  final inHand = HandDominoes();
  final onBoard = BoardDominoes();

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
