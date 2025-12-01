import 'dart:collection';

import 'package:args/args.dart';
import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino_model.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/games/fosteroes/puzzle_gen.dart';
import 'package:fft_games/games/fosteroes/region.dart';
import 'package:intl/intl.dart';

import 'fetch_nyt_puzzles.dart';

// TODO: Gets stuck on some hard puzzles

/*
 A pathologically simple puzzle just for testing
 Board: A B
 Dominoes: 0/0
 Constraints: None
 Solution: 0/0
*/
final puzz0 = Puzzle(
  field: FieldRegion([Cell(0, 0), Cell(1, 0)]),
  constraints: [],
  solution: [PlacedDomino(DominoModel(0, 0, 0), Cell(0, 0), 0)],
);

/* Board:
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

/// Fosteroes autogen puzzle from seed
Puzzle puzzleFromSeed(int seed, [PuzzleDifficulty diff = PuzzleDifficulty.easy]) =>
    PuzzleGenerator(diff, seed).generate();

/// Fosteroes puzzle for date
Puzzle puzzleFromDate(DateTime dt, [PuzzleDifficulty diff = PuzzleDifficulty.easy]) =>
    puzzleFromSeed(int.parse(dt.toString().split(' ').first.split('-').join()), diff);

class SolveState {
  // Filled cells
  final Map<Cell, int> filled;
  // Unfilled edges
  final List<(Cell, Cell)> edges;
  // Remaining dominoes
  final Set<DominoModel> dominoes;

  SolveState(this.filled, this.edges, this.dominoes);
}

/// Returns whether or not the constraint is viable (i.e. satisfied or still possible to satisfy).
/// TODO: Take into account remaining dominoes too!
bool isConstraintViable(
  List<Cell> cells,
  Constraint constraint,
  Map<Cell, int> cellContents,
  Set<DominoModel> remainingDominoes,
) {
  final values = cellContents.entries.where((e) => cells.contains(e.key)).map((e) => e.value).toList();
  return values.length != cells.length || constraint.check(values);
}

Map<Cell, int>? solve(Puzzle p) {
  // Treat the playing field as a graph and store the list of edges. This way we don't have to care about horizontal/
  // vertical. Only look right and down so we don't duplicate edges.
  final allEdges = <(Cell, Cell)>[];
  for (final c in p.field.cells) {
    for (final c2 in [c.right, c.down]) {
      if (p.field.cells.contains(c2)) {
        allEdges.add((c, c2));
      }
    }
  }

  // Constraints, keyed by list of cells
  final constraints = {for (final cr in p.constraints) cr.cells: cr.constraint};

  final states = Queue<SolveState>.from([
    SolveState({}, allEdges, {...p.dominoes}),
  ]);

  while (states.isNotEmpty) {
    final state = states.removeFirst();

    if (state.edges.isEmpty) {
      // Yay, we solved it
      return {for (final e in state.filled.entries) e.key: e.value};
    }

    // Ensure we don't cause an unfillable hole by always placing dominoes across the most isolated cells... or
    // "corneriest" corners... that is, the cells with fewest number of edges.
    final edgeCounts = <Cell, int>{};
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

void main(List<String> args) async {
  final dateFormat = DateFormat('yyyy-MM-dd');

  final parser = ArgParser()
    ..addOption(
      'date',
      abbr: 'd',
      defaultsTo: dateFormat.format(DateTime.now()),
      help: 'Date to fetch puzzles for (default = today)',
    )
    ..addOption('seed', abbr: 's', help: 'Seed to use for autogen puzzles')
    ..addOption(
      'difficulty',
      abbr: 'f',
      defaultsTo: PuzzleDifficulty.easy.name,
      allowed: PuzzleDifficulty.values.map((e) => e.name),
      help: 'Puzzle difficulty (default = easy)',
    )
    ..addFlag(
      'nyt',
      abbr: 'n',
      defaultsTo: false,
      help: 'Fetch the NYT puzzle for provided date (instead of the Fosteroes generated puzzle)',
    );

  final opts = parser.parse(args);

  final seed = int.tryParse(opts.option('seed') ?? "");
  final diff = PuzzleDifficulty.values.firstWhere((e) => e.name == opts.option('difficulty'));
  final date = DateTime.parse(opts.option('date')!);
  final doNyt = opts.flag('nyt');

  if (seed != null && doNyt) {
    print("Error: NYT puzzles require a date, not a seed.");
    return;
  }

  final puzzle = seed != null
      ? puzzleFromSeed(seed, diff)
      : (doNyt ? (await fetchNYTPuzzles(date))[diff]! : puzzleFromDate(date, diff));

  print(
    "Fetched ${doNyt ? 'NYT' : 'Fosteroes'} ${seed != null ? 'autogen #$seed' : dateFormat.format(date)} ${diff.name}",
  );

  final sw = Stopwatch()..start();
  final pips = solve(puzzle);
  final elapsed = sw.elapsed;

  if (pips != null) {
    print("Solved in $elapsed");
    print(
      List.generate(
        puzzle.field.bounds.height,
        (y) => List.generate(puzzle.field.bounds.width, (x) => pips[Cell(x, y)]?.toString() ?? '.'),
      ).map((r) => r.join('')).join('\n'),
    );
  } else {
    print("No solution found");
  }
}
