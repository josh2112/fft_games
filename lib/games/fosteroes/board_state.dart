import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:fft_games/games/fosteroes/settings.dart';
import 'package:flutter/material.dart';

import 'puzzle.dart';

class HandDominoes extends ChangeNotifier {
  var _positions = <DominoState?>[];

  UnmodifiableListView<DominoState?> get positions => UnmodifiableListView<DominoState?>(_positions);

  bool get isEmpty => positions.every((p) => p == null);

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

  final Map<DominoState, int> _rotateFrom = {};

  late final UnmodifiableMapView<DominoState, Offset> dominoes;

  BoardDominoes() {
    dominoes = UnmodifiableMapView(_dominoes);
  }

  void clear() {
    _dominoes.clear();
    _rotateFrom.clear();
    notifyListeners();
  }

  void add(DominoState domino, Offset position, {int? rotateFrom}) {
    _dominoes[domino] = position;
    if (rotateFrom != null) {
      _rotateFrom[domino] = rotateFrom;
    }
    notifyListeners();
  }

  void remove(DominoState domino) {
    _dominoes.remove(domino);
    _rotateFrom.remove(domino);
    notifyListeners();
  }

  int? getRotateFrom(DominoState domino) => _rotateFrom.remove(domino);

  bool canPlace(Set<Offset> domino) {
    var allCells = dominoes.entries
        .where((e) => e.key.location == DominoLocation.board)
        .map((e) => e.key.area(e.value))
        .flattened;

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
  final _loadCompleter = Completer<void>();

  Future<void> get isLoaded => _loadCompleter.future;

  final VoidCallback onWon;

  final puzzle = ValueNotifier<Puzzle?>(null);

  final inHand = HandDominoes();
  final onBoard = BoardDominoes();

  final floatingDomino = ValueNotifier<FloatingDomino?>(null);

  final elapsedTimeSecs = ValueNotifier<int>(0);

  final isInProgress = ValueNotifier(true);
  bool isPaused = false;

  BoardState(this.onWon) {
    final puzzlePath = 'assets/fosteroes/testpuzzles/puzzle3.json';

    Future<void> init() async {
      final puzz = await Puzzle.fromJsonFile(puzzlePath);
      inHand.set(puzz.dominoes);
      onBoard.clear();
      puzzle.value = puzz;

      for (final d in puzz.dominoes) {
        d.quarterTurns.addListener(() => onDominoRotated(d));
      }

      Timer.periodic(Duration(seconds: 1), (_) {
        if (isInProgress.value && !isPaused) {
          elapsedTimeSecs.value += 1;
        }
      });
    }

    _loadCompleter.complete(init());
  }

  // Removes this domino from the board and makes it float
  void floatDomino(DominoState d) {
    final baseCell = onBoard.dominoes[d];
    if (baseCell == null) {
      return;
    }
    onBoard.remove(d);
    d.location = DominoLocation.floating;
    floatingDomino.value = FloatingDomino(d, baseCell, d.quarterTurns.value - 1);
  }

  bool canSnapFloatingDomino() {
    final float = floatingDomino.value;
    if (float != null) {
      final cells = float.domino.area(float.baseCell).toSet();
      return puzzle.value!.field.canPlace(cells) && onBoard.canPlace(cells);
    }
    return false;
  }

  // Snaps the floating domino back to the board in its original or new position
  void unfloatDomino({bool isReturning = false}) {
    if (floatingDomino.value != null) {
      final float = floatingDomino.value!;
      final rotateFrom = float.domino.quarterTurns.value;
      if (isReturning) {
        float.domino.quarterTurns.value = float.originalTurns;
      }
      float.domino.location = DominoLocation.board;
      floatingDomino.value = null;
      onBoard.add(float.domino, float.baseCell, rotateFrom: rotateFrom);
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

  void maybeCheckConstraints() {
    if (!inHand.isEmpty || floatingDomino.value != null) {
      return;
    }

    final cellContents = onBoard.cellContents();

    if (puzzle.value!.constraints.every((c) => c.check(cellContents))) {
      isInProgress.value = false;
      onWon();
    }
  }

  Future applyGameState(List<SavedDominoPlacement> state, int elapsedTime, bool isCompleted) async {
    elapsedTimeSecs.value = elapsedTime;
    isInProgress.value = !isCompleted;

    for (final sdp in state) {
      final domino = inHand.positions.firstWhere((ds) => ds?.side1 == sdp.side1 && ds?.side2 == sdp.side2)!;
      inHand.remove(domino);
      domino.location = DominoLocation.board;
      domino.quarterTurns.value = sdp.quarterTurns;
      onBoard.add(domino, Offset(sdp.x.toDouble(), sdp.y.toDouble()));
      await Future.delayed(Duration(milliseconds: 150));
    }
  }
}
