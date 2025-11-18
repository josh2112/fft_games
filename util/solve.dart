import 'dart:collection';

import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino_model.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/games/fosteroes/puzzle_gen.dart' show PuzzleGenerator;
import 'package:fft_games/games/fosteroes/region.dart';

// TODO: Needs work; works great on small puzzle but out-of-memory on regular-sized.

/*
  3
  1 1 2
  3/1, 1/2  1-1 equals  3 3
*/
final puzz1 = Puzzle(
  field: FieldRegion([Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)]),
  solution: [PlacedDomino(DominoModel(0, 3, 1), Cell(0, 0), 1), PlacedDomino(DominoModel(1, 1, 2), Cell(1, 1), 0)],
  constraints: [
    ConstraintRegion([Cell(0, 1), Cell(1, 1)], EqualConstraint()),
    ConstraintRegion([Cell(0, 0)], SumConstraint(3)),
  ],
);

class PlacedDominoNode {
  final DominoModel domino;
  final Cell cell;
  final int rotation;
  final PlacedDominoNode? prev;

  PlacedDominoNode(this.domino, this.cell, this.rotation, this.prev);

  @override
  String toString() => "$domino at $cell r $rotation";

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
  final sw = Stopwatch()..start();

  // Strategy:
  // 1) Take the next domino.
  // 2) For each rotation 0,1,2,3 (or just 0,1 if the pips are the same):
  //    a) Find each cell pair where it'll fit. For each of those:
  //       i) Check for violated constraints. If none, enqueue a new state.

  final boardCells = p.field.cells.toSet();
  final dominoSet = {...p.dominoes};

  final states = Queue<PlacedDominoNode?>()..add(null);

  while (states.isNotEmpty) {
    final s = states.removeFirst();

    final dominoPlacements = PlacedDominoNode.flattened(s);

    // Build a map of filled cells and their contents
    final board = <Cell, int>{};
    for (final dp in dominoPlacements) {
      board[dp.cell] = dp.domino.side1;
      board[dp.cell.adjacent(dp.rotation)] = dp.domino.side2;
    }

    // Find first unplaced domino
    final d = dominoSet.difference(dominoPlacements.map((d) => d.domino).toSet()).firstOrNull;
    if (d == null) {
      if (p.constraints.every((cr) => true == cr.check(board))) {
        print("Solved in ${sw.elapsed}");
        print(dominoPlacements);
      } else {
        print("No solution found! ${sw.elapsed}");
      }
      return;
    }

    final numRotations = d.side1 == d.side2 ? 2 : 4;

    for (var r = 0; r < numRotations; r++) {
      final offset = Cell.origin.adjacent(r);

      for (final Cell c in boardCells.difference(board.keys.toSet())) {
        final c2 = c + offset;
        if (!boardCells.contains(c2)) continue;

        // Check if we will violate any constraints by placing this cell here. If not,
        // make & enqueue a new state
        board[c] = d.side1;
        board[c2] = d.side2;
        if (!p.constraints
            .where((cr) => cr.cells.contains(c) || cr.cells.contains(c2))
            .any((cr) => false == cr.check(board))) {
          //print("New state: ${states.last}");
          states.add(PlacedDominoNode(d, c, r, s));
        }

        board.remove(c);
        board.remove(c2);
      }
    }
  }
}

Puzzle puzzleFromDate(DateTime dt) =>
    PuzzleGenerator(PuzzleDifficulty.easy, int.parse(dt.toString().split(' ').first.split('-').join())).generate();

void main() {
  //solve(puzz1);
  solve(puzzleFromDate(DateTime(2025, 11, 18)));
}
