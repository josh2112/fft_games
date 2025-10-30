import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'puzzle.dart';

class HandDominoes extends ChangeNotifier {
  var _positions = <DominoState?>[];

  get positions => UnmodifiableListView<DominoState?>(_positions);

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
    domino.location = DominoLocation.hand;
    domino.quarterTurns.value = 0;
    notifyListeners();
    return true;
  }
}

class BoardDominoes extends ChangeNotifier {
  final _dominoes = <DominoState, Offset>{};

  late final UnmodifiableMapView<DominoState, Offset> dominoes;

  BoardDominoes() {
    dominoes = UnmodifiableMapView(_dominoes);
  }

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

  bool canPlace(Set<Offset> domino) {
    var allCells = dominoes.entries.map((e) => e.key.area(e.value)).flattened.toSet().difference(domino);
    return !domino.any((c) => allCells.contains(c));
  }

  Map<Offset, int> cellContents() {
    final contents = <Offset, int>{};
    for (final e in dominoes.entries) {
      final cells = e.key.area(e.value);
      contents[cells[0]] = e.key.side1;
      contents[cells[1]] = e.key.side2;
    }
    return contents;
  }
}

class FloatingDomino {
  final DominoState domino;
  Offset baseCell;
  final int originalTurns;

  FloatingDomino(this.domino, this.baseCell, this.originalTurns);
}

class BoardState {
  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  final inHand = HandDominoes();
  final onBoard = BoardDominoes();

  final ValueNotifier<FloatingDomino?> floatingDomino = ValueNotifier(null);

  BoardState() {
    loadPuzzle('assets/fosteroes/testpuzzles/puzzle3.json');
  }

  Future loadPuzzle(String path) async {
    final puzz = await Puzzle.fromJsonFile(path);
    inHand.set(puzz.dominoes);
    onBoard.clear();
    puzzle.value = puzz;

    for (final d in puzz.dominoes) {
      d.quarterTurns.addListener(() => onDominoRotated(d));
    }
  }

  // Removes this domino from the board and makes it float
  void floatDomino(DominoState d) {
    print("Trying to float $d");
    final baseCell = onBoard.dominoes[d];
    if (baseCell == null) {
      return;
    }
    onBoard.remove(d);
    d.location = DominoLocation.floating;
    floatingDomino.value = FloatingDomino(d, baseCell, d.quarterTurns.value - 1);
    print("Floated $d");
  }

  bool canSnapFloatingDomino() {
    final float = floatingDomino.value;
    if (float != null) {
      final cells = float.domino.area(float.baseCell);
      return puzzle.value!.field.canPlace(cells.toSet()) && onBoard.canPlace(cells.toSet());
    }
    return false;
  }

  // Snaps the floating domino back to the board in its original or new position
  void unfloatDomino({bool isReturning = false}) {
    print("Trying to unfloat ${floatingDomino.value?.domino}");
    if (floatingDomino.value != null) {
      final float = floatingDomino.value!;
      if (isReturning) {
        print(" - returning ${float.domino}");
        float.domino.quarterTurns.value = float.originalTurns;
      }
      float.domino.location = DominoLocation.board;
      floatingDomino.value = null;
      onBoard.add(float.domino, float.baseCell);
      print("Unfloated ${float.domino}");
    }
  }

  void onDominoRotated(DominoState d) {
    if (d.location == DominoLocation.board) {
      // If another domino is floating, return it to its original position.
      if (floatingDomino.value?.domino != d) {
        unfloatDomino(isReturning: true);
      }

      floatDomino(d);
    }

    if (d.location == DominoLocation.floating) {
      // Turn it, and try to snap it in place after some delay (if it hasn't been turned again)
      final previousTurns = d.quarterTurns;
      Future.delayed(Duration(milliseconds: 500), () {
        // Unless we've been turned again, try to snap this domino back to the board
        if (d.location == DominoLocation.floating && previousTurns == d.quarterTurns) {
          if (canSnapFloatingDomino()) {
            unfloatDomino();
          }
        }
      });
    }
  }
}
