import 'dart:collection';

import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart' show Puzzle;
import 'package:fft_games/games/fosteroes/region.dart';

/*
  3
  1 1 2
  3/1, 1/2  1-1 equals  3 3
*/
final puzz1 = Puzzle(
  field: FieldRegion([Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)]),
  solution: {DominoState(0, 3, 1)..quarterTurns.value = 1: Cell(0, 0), DominoState(1, 1, 2): Cell(1, 1)},
  constraints: [
    ConstraintRegion([Cell(0, 1), Cell(1, 1)], EqualConstraint()),
    ConstraintRegion([Cell(0, 0)], SumConstraint(3)),
  ],
);

class Domino {
  final int id, side1, side2, rotation;

  Domino(this.id, this.side1, this.side2, this.rotation);

  @override
  operator ==(Object other) => identical(this, other) || (other is Domino && other.id == id);

  @override
  int get hashCode => id;
}

class PlacedDominoNode {
  final Domino domino;
  final Cell cell;
  final PlacedDominoNode? prev;

  PlacedDominoNode(this.domino, this.cell, this.prev);

  static List<PlacedDominoNode> flattened(PlacedDominoNode? node) {
    final list = <PlacedDominoNode>[];
    var cur = node;
    while (cur != null) {
      list.add(cur);
      cur = cur.prev;
    }
    return list;
  }
}

void solve(Puzzle p) {
  // Strategy:
  // 1) Take the next domino.
  // 2) For each rotation 0,1,2,3 (or just 0,1 if the pips are the same):
  //    a) Find each cell pair where it'll fit. For each of those:
  //       i) Check for violated constraints. If none, enqueue a new state.

  final dominoSet = {...p.dominoes.map((d) => Domino(d.id, d.side1, d.side2, 0))};

  final states = Queue<PlacedDominoNode?>()..add(null);

  while (states.isNotEmpty) {
    final s = states.removeFirst();

    final dominoPlacements = PlacedDominoNode.flattened(s);

    // Build a map of cells and their contents (0-6 or -1 for unfilled cells)
    final board = {for (final c in p.field.cells) c: -1};
    for (final dp in dominoPlacements) {
      board[dp.cell] = dp.domino.side1;
      board[dp.cell.adjacent(dp.domino.rotation)] = dp.domino.side2;
    }

    // Find first unplaced domino
    final d = dominoSet.difference(dominoPlacements.map((d) => d.domino).toSet()).firstOrNull;
    if (d == null) break;

    final numRotations = d.side1 == d.side2 ? 2 : 4;

    for (var r = 0; r < numRotations; r++) {
      final offset = Cell.origin.adjacent(r);
      for (final Cell c in board.keys.where((c) => board[c] == -1 && board[c + offset] == -1)) {
        // TODO: Check if we will violate any constraints by placing this cell here. If not,
        // make & enqueue a new state!
      }
    }
  }
}

void main() {
  solve(puzz1);
}
