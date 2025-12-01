import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:fft_games/games/fosteroes/domino_model.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:fft_games/games/fosteroes/region.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  final dominoes = [for (final (i, ab) in dominoesJson.indexed) DominoModel(i, ab[0], ab[1])];

  final solution = json["solution"];

  final placedDominoes = <PlacedDomino>[];

  for (int i = 0; i < solution.length; ++i) {
    var c1 = _cellFromCoord(solution[i][0]), c2 = _cellFromCoord(solution[i][1]);
    placedDominoes.add(
      PlacedDomino(dominoes[i], c1, switch ((c2 - c1)) {
        Cell(x: 1, y: 0) => 0,
        Cell(x: 0, y: 1) => 1,
        Cell(x: -1, y: 0) => 2,
        _ => 3,
      }),
    );
  }

  return Puzzle(field: FieldRegion(cells), solution: placedDominoes, constraints: constraintRegions);
}

class FetchPuzzleException implements Exception {
  final http.Response response;
  FetchPuzzleException(this.response);

  @override
  String toString() => 'Failed to fetch puzzle: HTTP status ${response.statusCode} ${response.reasonPhrase}';
}

/// Fetches NYT Fosteroes puzzles, keyed by difficulty, for the given date.
Future<Map<PuzzleDifficulty, Puzzle>> fetchNYTPuzzles(DateTime date) async {
  final req = await http.get(
    Uri.https('www.nytimes.com', '/svc/pips/v1/${DateFormat('yyyy-MM-dd').format(date)}.json'),
  );
  if (req.statusCode != 200) {
    throw FetchPuzzleException(req);
  }
  final json = jsonDecode(req.body);
  return {for (final diff in PuzzleDifficulty.values) diff: _fromJson(json[diff.name]!, diff)};
}
