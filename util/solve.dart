import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino_model.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/games/fosteroes/puzzle_gen.dart';
import 'package:fft_games/games/fosteroes/region.dart';

// TODO: Needs work; works great on small puzzle but slow and never finds solution on medium-sized.
// Problems to solve:
// 1) Should we make a graph out of the board? We would no longer have to worry about direction or rotating dominoes.
// 2) How to prevent 1-sized 'holes' that can never be filled? Always choose the 'corneriest' corner for the next
//    placement -- find cells with fewest number of adjacents and choose one of them (this is another benefit to having
//    the board in graph form).
// 3) Better pruning: In addition to checking the constraint on which we're placing a tile, check if the remaining
//    dominoes can satisfy the remaining constraints.

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

class SolveState {
  // Filled cells
  final Map<int, int> filled;
  // Unfilled edges
  final List<(int, int)> edges;
  // Remaining dominoes
  final Set<DominoModel> dominoes;

  SolveState(this.filled, this.edges, this.dominoes);
}

/// Returns whether or not the constraint is viable (i.e. satisfied or still possible to satisfy).
/// TODO: And can the remaining dominoes satisfy the remaining constraints?
bool isConstraintViable(
  List<int> cells,
  Constraint constraint,
  Map<int, int> cellContents,
  Set<DominoModel> remainingDominoes,
) {
  final values = cellContents.entries.where((e) => cells.contains(e.key)).map((e) => e.value).toList();
  return values.length != cells.length || constraint.check(values);
}

void solve(Puzzle p) {
  final sw = Stopwatch()..start();

  final cellToIndex = {for (final (i, c) in p.field.cells.indexed) c: i};
  final indexToCell = {for (final e in cellToIndex.entries) e.value: e.key};

  // Constraints, keyed by list of cell indices
  final constraints = {for (final cr in p.constraints) cr.cells.map((c) => cellToIndex[c]!).toList(): cr.constraint};

  // Build edge list. Only look right and down so we don't duplicate edges.
  final allEdges = <(int, int)>[];
  for (final c in p.field.cells) {
    for (final c2 in [c.right, c.down]) {
      if (p.field.cells.contains(c2)) {
        allEdges.add((cellToIndex[c]!, cellToIndex[c2]!));
      }
    }
  }

  final allDominoes = {...p.dominoes};

  final states = Queue<SolveState>.from([SolveState({}, allEdges, allDominoes)]);

  while (states.isNotEmpty) {
    final state = states.removeFirst();

    // Find the "corneriest" corners - cells with fewest number of adjacents - and choose first.
    final cellCounts = <int, int>{};
    for (final (c1, c2) in state.edges) {
      cellCounts[c1] = (cellCounts[c1] ?? 0) + 1;
      cellCounts[c2] = (cellCounts[c2] ?? 0) + 1;
    }
    final corneriestCell = cellCounts.entries.reduce((a, b) => a.value <= b.value ? a : b).key;

    // For each of this cell's edges, try each remaining domino, forward and reverse.
    for (final edge in state.edges.where((e) => e.$1 == corneriestCell || e.$2 == corneriestCell)) {
      // Group the constraints into those affected by this edge and those not.
      final groupedConstraintKeys = constraints.keys.groupListsBy(
        (cells) => cells.contains(edge.$1) || cells.contains(edge.$2),
      );
      for (final domino in state.dominoes) {
        final remainingDominoes = {...state.dominoes}..remove(domino);
        for (final d in [domino, DominoModel(domino.id, domino.side2, domino.side1)]) {
          final pips = {...state.filled, edge.$1: d.side1, edge.$2: d.side2};
          // If we place [d] across [edge], are all constraints still viable?
          if (constraints.entries.every((e) => isConstraintViable(e.key, e.value, pips, remainingDominoes))) {
            // TODO: Make & queue a new state with the placed domino
          }
        }
      }
    }
  }
}

Puzzle puzzleFromDate(DateTime dt) =>
    PuzzleGenerator(PuzzleDifficulty.easy, int.parse(dt.toString().split(' ').first.split('-').join())).generate();

void main() {
  solve(puzz1);
  //solve(puzzleFromDate(DateTime(2025, 11, 18)));
}
