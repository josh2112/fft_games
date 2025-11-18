import 'dart:math';

import 'package:collection/collection.dart';

import 'constraint.dart';
import 'domino_model.dart';
import 'puzzle.dart';
import 'region.dart';

class _PuzzleDifficultyStats {
  static final byDifficulty = {
    PuzzleDifficulty.easy: _PuzzleDifficultyStats(
      minSize: 4,
      maxSize: 6,
      constraintCoverage: 0.80,
      neFrequency: 0.20,
      gtltFrequency: 0.10,
    ),
    PuzzleDifficulty.medium: _PuzzleDifficultyStats(
      minSize: 7,
      maxSize: 10,
      constraintCoverage: 0.85,
      neFrequency: 0.10,
      gtltFrequency: 0.10,
    ),
    PuzzleDifficulty.hard: _PuzzleDifficultyStats(
      minSize: 11,
      maxSize: 15,
      constraintCoverage: 0.90,
      neFrequency: 0.10,
      gtltFrequency: 0.10,
    ),
  };

  // Min and max number of dominoes
  final int minSize, maxSize;
  // Percentage of cells covered by a constraint
  final double constraintCoverage;
  // Percentage of time a not-equal constraint is included
  final double neFrequency;
  // Percentage of time a sum constraint is turned into a G.T. or L.T. constraint
  final double gtltFrequency;

  const _PuzzleDifficultyStats({
    required this.minSize,
    required this.maxSize,
    required this.constraintCoverage,
    required this.neFrequency,
    required this.gtltFrequency,
  });
}

extension RandomRange on Random {
  int nextIntInclusive(int min, int max) => nextInt(max - min + 1) + min;

  T next<T>(Iterable<T> list, T def) => list.isEmpty ? def : list.elementAt(nextInt(list.length));
}

typedef MatchesSegment = bool Function(int value, Map<Cell, int> group);

class PuzzleGenerator {
  final Random _rng;

  final PuzzleDifficulty difficulty;

  final filledCells = <Cell>{};
  final borderCells = <Cell>{};
  late final List<Cell> field;
  late final List<PlacedDomino> dominoLocations;

  PuzzleGenerator(this.difficulty, int seed) : _rng = Random(seed);

  Puzzle generate() {
    final stats = _PuzzleDifficultyStats.byDifficulty[difficulty]!;

    // Generate some random dominoes (number depends on difficulty)
    final dominoes = Iterable.generate(
      _rng.nextIntInclusive(stats.minSize, stats.maxSize),
      (i) => DominoModel(i, _rng.nextInt(7), _rng.nextInt(7)),
    );
    final locations = <PlacedDomino>[];

    // Place dominoes in a non-overlapping, contiguous group
    for (final d in dominoes) {
      bool placed = false;
      while (!placed) {
        // Choose a border cell
        final c1 = _rng.next(borderCells, Cell.origin);

        // Find an adjacent free cell and orient the domino properly
        for (final c2 in c1.borderCells().shuffled(_rng)) {
          if (!filledCells.contains(c2)) {
            locations.add(
              PlacedDomino(d, c1, switch ((c2 - c1)) {
                Cell(x: 1, y: 0) => 0,
                Cell(x: 0, y: 1) => 1,
                Cell(x: -1, y: 0) => 2,
                _ => 3,
              }),
            );

            // Update filled cells
            filledCells.addAll([c1, c2]);

            // Update border cells
            borderCells.addAll(c1.borderCells());
            borderCells.addAll(c2.borderCells());
            borderCells.removeAll(filledCells);

            placed = true;
            break;
          }
        }
      }
    }

    // Normalize cell values
    final offset = Cell(filledCells.map((c) => c.x).min, filledCells.map((c) => c.y).min);

    dominoLocations = [for (final pd in locations) PlacedDomino(pd.domino, pd.cell - offset, pd.rotation)];
    field = filledCells.map((c) => c - offset).toList();

    final pipLocations = dominoLocations.map(
      (dcr) => {dcr.cell: dcr.domino.side1, dcr.cell.adjacent(dcr.rotation): dcr.domino.side2},
    );

    // All cells mapped to their pip values
    final cells = {for (final m in pipLocations) ...m};

    // The list of cells that aren't part of a constraint, updated after each constraint-finding
    var unconstrainedCells = {...cells};

    // Build equality constraints: Find contiguous groups of size > 1 with the same pip
    final equalGroups = _segment({
      ...unconstrainedCells,
    }, (value, group) => group.values.first == value).where((g) => g.length > 1).sortedBy((g) => -g.length).toList();

    // Remove cells that are now in an equals group
    for (final c in equalGroups.map((g) => g.keys).flattened) {
      unconstrainedCells.remove(c);
    }

    // Mabye build non-equality constraints: Find contiguous groups of size > 1 with distinct pips
    Map<Cell, int> nonEqualGroup = {};

    if (_rng.nextDouble() <= stats.neFrequency) {
      nonEqualGroup =
          _segment(
            {...unconstrainedCells},
            (value, group) => !group.values.contains(value),
          ).where((g) => g.length > 1).sortedBy((g) => -g.length).firstOrNull ??
          {};

      // Remove cells that are now in a nonequals group
      for (final c in nonEqualGroup.keys) {
        unconstrainedCells.remove(c);
      }
    }

    // Segment the remaining cells into groups of max size 6

    final sumGroups = _segment({...unconstrainedCells}, (value, group) => group.length < 6).toList();

    // Now remove a couple cells from these constraints to hit the target coverage
    for (int i = 0; i < ((1 - stats.constraintCoverage) * filledCells.length).toInt(); ++i) {
      // Pick a nonempty group and remove one cell
      final g = sumGroups.sortedBy((g) => g.length).lastOrNull;
      g?.remove(g.keys.last);
    }

    final p = Puzzle(
      solution: dominoLocations,
      field: FieldRegion(field),
      constraints: [
        for (final g in equalGroups.where((g) => g.isNotEmpty)) ConstraintRegion(g.keys.toList(), EqualConstraint()),
        if (nonEqualGroup.isNotEmpty) ConstraintRegion(nonEqualGroup.keys.toList(), NotEqualConstraint()),
        for (final g in sumGroups.where((g) => g.isNotEmpty))
          ConstraintRegion(g.keys.toList(), SumConstraint(g.values.sum)),
      ],
    );

    return p;
  }

  Iterable<Map<Cell, int>> _segment(Map<Cell, int> valueByCell, MatchesSegment matches) sync* {
    void recurse(Cell c, Map<Cell, int> group) {
      group[c] = valueByCell.remove(c)!;
      for (final b in c.borderCells().where((b) => valueByCell.containsKey(b))) {
        if (matches(valueByCell[b]!, group) /*group.values.first == valueByCell[b]*/ ) {
          recurse(b, group);
        }
      }
    }

    while (valueByCell.isNotEmpty) {
      final e = valueByCell.entries.first;
      final group = <Cell, int>{};
      recurse(e.key, group);
      yield group;
    }
  }
}

// Dumb class that provides the next item in the list when next() is called. Wraps around.
class NextProvider<T> {
  final List<T> items;
  int _i = 0;

  NextProvider(this.items);

  T next() => items[(_i++) % items.length];
}
