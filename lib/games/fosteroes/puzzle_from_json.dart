import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'constraint.dart';
import 'domino.dart';
import 'puzzle.dart';
import 'region.dart';

class _NytEmptyConstraint extends Constraint {
  @override
  bool check(List<int> values) => true;
}

Cell _cellFromCoord(List<dynamic> coord) => Cell(coord[1], coord[0]);

ConstraintRegion _parseNytRegion(Map<String, dynamic> region) {
  // indices, type, target
  // empty, sum, equals, unequal, greater, less
  final cells = [for (final coord in region["indices"]) _cellFromCoord(coord)];
  final value = region["target"];
  final constraint = switch (region["type"]) {
    "equals" => EqualConstraint(),
    "unequal" => NotEqualConstraint(),
    "sum" => SumConstraint(value!),
    "greater" => GreaterThanConstraint(value!),
    "less" => LessThanConstraint(value!),
    _ => _NytEmptyConstraint(),
  };

  return ConstraintRegion(cells, constraint);
}

Puzzle _fromJson(Map<String, dynamic> json, PuzzleDifficulty diff) {
  final constraintRegions = [for (final r in json["regions"]) _parseNytRegion(r)];

  final cells = constraintRegions.map((r) => r.cells).flattened.toList();

  constraintRegions.removeWhere((r) => r.constraint is _NytEmptyConstraint);

  final dominoesJson = json["dominoes"] as List<dynamic>;

  final dominoes = [for (final (i, ab) in dominoesJson.indexed) DominoState(i, ab[0], ab[1])];

  final solution = json["solution"];

  final dominoToCell = <DominoState, Cell>{};

  for (int i = 0; i < solution.length; ++i) {
    var c1 = _cellFromCoord(solution[i][0]), c2 = _cellFromCoord(solution[i][1]);
    dominoes[i].quarterTurns.value = switch ((c2 - c1)) {
      Cell(x: 1, y: 0) => 0,
      Cell(x: 0, y: 1) => 1,
      Cell(x: -1, y: 0) => 2,
      _ => 3,
    };
    dominoToCell[dominoes[i]] = c1;
  }

  return Puzzle(difficulty: diff, field: FieldRegion(cells), solution: dominoToCell, constraints: constraintRegions);
}

Puzzle loadPuzzleJson(String path, PuzzleDifficulty diff) {
  final json = jsonDecode(File(path).readAsStringSync())[diff.name];
  if (json["id"] <= 0) {
    throw Exception("Puzzle not defined");
  }
  return _fromJson(json, diff);
}
