import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:fft_games/games/fosteroes/puzzle_gen.dart';
import 'package:fft_games/games/fosteroes/settings.dart';
import 'package:flutter/material.dart';

import 'puzzle.dart';
import 'region.dart';

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
  final _dominoes = <DominoState, Cell>{};

  final Map<DominoState, int> _rotateFrom = {};
  final Map<DominoState, Offset> _animateFrom = {};

  late final UnmodifiableMapView<DominoState, Cell> dominoes;

  BoardDominoes() {
    dominoes = UnmodifiableMapView(_dominoes);
  }

  void clear() {
    _dominoes.clear();
    _rotateFrom.clear();
    _animateFrom.clear();
    notifyListeners();
  }

  void add(DominoState domino, Cell position, {int? rotateFrom, Offset? animateFrom}) {
    _dominoes[domino] = position;
    if (rotateFrom != null) {
      _rotateFrom[domino] = rotateFrom;
    }
    if (animateFrom != null) {
      _animateFrom[domino] = animateFrom;
    }
    notifyListeners();
  }

  void remove(DominoState domino) {
    _dominoes.remove(domino);
    _rotateFrom.remove(domino);
    _animateFrom.remove(domino);
    notifyListeners();
  }

  int? getRotateFrom(DominoState domino) => _rotateFrom.remove(domino);

  Offset? getAnimateFrom(DominoState domino) => _animateFrom.remove(domino);

  bool canPlace(Set<Cell> domino) {
    var allCells = dominoes.entries
        .where((e) => e.key.location == DominoLocation.board)
        .map((e) => e.key.area(e.value))
        .flattened;

    return !domino.any((c) => allCells.contains(c));
  }

  Map<Cell, int> cellContents() {
    final contents = <Cell, int>{};
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
  Cell baseCell;
  final int originalTurns;

  FloatingDomino(this.domino, this.baseCell, this.originalTurns);
}

class BoardState {
  static final rng = Random();

  final VoidCallback onWon, onBadSolution;

  final puzzle = ValueNotifier<Puzzle?>(null);

  final PuzzleDifficulty puzzleDifficulty;

  int _puzzleSeed = 0;

  var _allDominoes = <DominoState>[];

  final inHand = HandDominoes();
  final onBoard = BoardDominoes();

  final floatingDomino = ValueNotifier<FloatingDomino?>(null);

  final violatedConstraintRegions = ValueNotifier(<ConstraintRegion>[]);

  final elapsedTimeSecs = ValueNotifier<int>(0);

  final isInProgress = ValueNotifier(true);
  final isPaused = ValueNotifier(false);

  late final Timer _timer;

  BoardState(this.onWon, this.onBadSolution, this.puzzleDifficulty) {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (isInProgress.value && !isPaused.value) {
        elapsedTimeSecs.value += 1;
      }
    });
  }

  int makePuzzle([int? seed]) {
    _puzzleSeed = seed ?? rng.nextInt(1 << 32);

    final puzz = PuzzleGenerator(puzzleDifficulty, _puzzleSeed).generate();
    _allDominoes = puzz.dominoes.map((d) => DominoState(d.id, d.side1, d.side2)).toList();
    inHand.set(_allDominoes);
    onBoard.clear();
    puzzle.value = puzz;

    violatedConstraintRegions.value = [];

    for (final d in _allDominoes) {
      d.quarterTurns.addListener(() => onDominoRotated(d));
    }

    return _puzzleSeed;
  }

  void dispose() {
    _timer.cancel();

    for (final d in _allDominoes) {
      d.quarterTurns.removeListener(() => onDominoRotated(d));
    }
  }

  void clearBoard() {
    for (final d in onBoard.dominoes.keys) {
      inHand.tryPutBack(d);
    }
    onBoard.clear();
    violatedConstraintRegions.value = [];
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
      violatedConstraintRegions.value = [];
      return;
    }

    final cellContents = onBoard.cellContents();

    violatedConstraintRegions.value = puzzle.value!.constraints.where((cr) => false == cr.check(cellContents)).toList();

    if (puzzle.value!.constraints.every((cr) => true == cr.check(cellContents))) {
      isInProgress.value = false;
      onWon();
    } else {
      onBadSolution();
    }
  }

  Future applyGameState(List<SavedDominoPlacement> state, int elapsedTime, bool isCompleted) async {
    elapsedTimeSecs.value = elapsedTime;
    isInProgress.value = !isCompleted;

    for (final sdp in state) {
      final domino = inHand.positions.firstWhere((ds) => ds?.id == sdp.id)!;
      inHand.remove(domino);
      domino.location = DominoLocation.board;
      domino.quarterTurns.value = sdp.quarterTurns;
      onBoard.add(domino, Cell(sdp.x, sdp.y), animateFrom: Offset(0, 5));
      await Future.delayed(Duration(milliseconds: 200));
    }
  }
}
