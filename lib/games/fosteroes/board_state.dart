import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'puzzle.dart';

class HandDominoes extends ChangeNotifier {
  var _positions = <DominoState?>[];

  late final UnmodifiableListView<DominoState?> positions;

  HandDominoes() {
    positions = UnmodifiableListView(_positions);
  }

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
    var allCells = _dominoes.entries.map((e) => e.key.area(e.value)).flattened.toSet().difference(domino);
    return !domino.any((c) => allCells.contains(c));
  }
}

class BoardState {
  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  final inHand = HandDominoes();
  final onBoard = BoardDominoes();

  final ValueNotifier<(DominoState, Offset)?> floatingDomino = ValueNotifier(null);

  BoardState() {
    loadPuzzle('assets/fosteroes/testpuzzles/puzzle2.json');
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

  void onDominoRotated(DominoState d) {
    if (d.location == DominoLocation.board && floatingDomino.value?.$1 != d) {
      final offset = onBoard.dominoes[d]!;
      onBoard.remove(d);
      floatingDomino.value = (d, offset);
    } else if (floatingDomino.value?.$1 == d) {
      final turns = d.quarterTurns;
      Future.delayed(Duration(milliseconds: 500), () {
        // Unless we've been clicked again, try to snap this domino back to the board
        if (turns == d.quarterTurns) {
          final baseCell = floatingDomino.value!.$2;
          final cells = d.area(baseCell);

          if (puzzle.value!.field.canPlace(cells) && onBoard.canPlace(cells)) {
            floatingDomino.value = null;
            onBoard.add(d, baseCell);
          }
        }
      });
    }
  }
}
