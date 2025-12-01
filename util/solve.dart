import 'dart:collection';

import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino_model.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/games/fosteroes/puzzle_gen.dart';
import 'package:fft_games/games/fosteroes/region.dart';

/*
  Board:
   A
   B C D
  Dominoes: 3/1, 1/2
  Constraints: BC:=, A:3
  Solution:
   3
   1 1 2
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
/// TODO: Take into account remaining dominoes too!
bool isConstraintViable(
  List<int> cells,
  Constraint constraint,
  Map<int, int> cellContents,
  Set<DominoModel> remainingDominoes,
) {
  final values = cellContents.entries.where((e) => cells.contains(e.key)).map((e) => e.value).toList();
  return values.length != cells.length || constraint.check(values);
}

Map<Cell, int>? solve(Puzzle p) {
  final cellToIndex = {for (final (i, c) in p.field.cells.indexed) c: i};
  final indexToCell = {for (final e in cellToIndex.entries) e.value: e.key};

  // Constraints, keyed by list of cell indices
  final constraints = {for (final cr in p.constraints) cr.cells.map((c) => cellToIndex[c]!).toList(): cr.constraint};

  // Treat the playing field as a graph and store the list of edges. This way we don't have to care about horizontal/
  // vertical. Only look right and down so we don't duplicate edges.
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

    if (state.edges.isEmpty) {
      // Yay, we solved it
      return {for (final e in state.filled.entries) indexToCell[e.key]!: e.value};
    }

    // Ensure we don't cause an unfillable hole by always placing dominoes across the most isolated cells... or
    // "corneriest" corners... that is, the cells with fewest number of edges.
    final edgeCounts = <int, int>{};
    for (final (c1, c2) in state.edges) {
      edgeCounts[c1] = (edgeCounts[c1] ?? 0) + 1;
      edgeCounts[c2] = (edgeCounts[c2] ?? 0) + 1;
    }
    final corneriestCell = edgeCounts.entries.reduce((a, b) => a.value <= b.value ? a : b).key;

    // For each of this cell's edges, try each remaining domino, forward and reverse.
    for (final edge in state.edges.where((e) => e.$1 == corneriestCell || e.$2 == corneriestCell)) {
      // Remove all edges connecting to either of the cells in [edge]
      final edges = state.edges
          .where((e) => e.$1 != edge.$1 && e.$2 != edge.$1 && e.$1 != edge.$2 && e.$2 != edge.$2)
          .toList();
      for (final domino in state.dominoes) {
        final remainingDominoes = {...state.dominoes}..remove(domino);
        // Try this domino both ways
        for (final d in [domino, DominoModel(domino.id, domino.side2, domino.side1)]) {
          final pips = {...state.filled, edge.$1: d.side1, edge.$2: d.side2};
          // If we place [d] across [edge], are all constraints still viable?
          if (constraints.entries.every((e) => isConstraintViable(e.key, e.value, pips, remainingDominoes))) {
            // Make & queue a new state with the placed domino
            states.add(SolveState(pips, edges, remainingDominoes));
          }
        }
      }
    }
  }

  return null;
}

void solveAndPrint(Puzzle p) {
  final sw = Stopwatch()..start();
  final pips = solve(p);
  final elapsed = sw.elapsed;
  if (pips == null) {
    print("No solution found");
    return;
  }

  print("Found solution in $elapsed");
  print(
    List.generate(
      p.field.bounds.height,
      (y) => List.generate(p.field.bounds.width, (x) => pips[Cell(x, y)]?.toString() ?? '.'),
    ).map((r) => r.join('')).join('\n'),
  );
}

void main() {
  Puzzle puzzleFromSeed(int seed) => PuzzleGenerator(PuzzleDifficulty.easy, seed).generate();
  Puzzle puzzleFromDate(DateTime dt) => puzzleFromSeed(int.parse(dt.toString().split(' ').first.split('-').join()));

  //solveAndPrint(puzz1);
  //solveAndPrint(puzzleFromDate(DateTime(2025, 12, 1)));
  solveAndPrint(puzzleFromSeed(3404927097));
}
