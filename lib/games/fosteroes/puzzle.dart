import 'dart:convert';

import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domino.dart';
import 'region.dart';

class RegionPalette {
  final Color label, fill, stroke;

  RegionPalette(MaterialColor color) : label = color, fill = color[200]!.withAlpha(96), stroke = color[800]!;
}

class Palette {
  final List<RegionPalette> constraintAreaPalette = [
    RegionPalette(Colors.green),
    RegionPalette(Colors.blue),
    RegionPalette(Colors.red),
  ];
}

class Puzzle {
  final FieldRegion field;
  final List<ConstraintRegion> constraints;
  final List<DominoState> dominoes;

  static Future<Puzzle> fromJsonFile(String path) async {
    List<Offset> parseOffsets(List<dynamic> list) {
      return [for (final xy in list) Offset(xy[0].toDouble(), xy[1].toDouble())];
    }

    Constraint parseConstraint(Map<String, dynamic> c) => switch (c["type"]) {
      "+" => SumConstraint(c["value"].toInt()),
      "<" => LessThanConstraint(c["value"].toInt()),
      ">" => GreaterThanConstraint(c["value"].toInt()),
      "!=" => NotEqualConstraint(),
      _ => EqualConstraint(),
    };

    final def = jsonDecode(await rootBundle.loadString(path));
    final field = FieldRegion(parseOffsets(def["field"]));

    final pals = Palette().constraintAreaPalette;
    int i = 0;

    final constraints = [
      for (final c in def["constraints"])
        ConstraintRegion(parseOffsets(c["cells"]), parseConstraint(c), pals[i++ % pals.length]),
    ];

    i = 0;
    final hand = [for (final d in parseOffsets(def["hand"])) DominoState(d.dx.toInt(), d.dy.toInt())];
    return Puzzle._(field, constraints, hand);
  }

  Puzzle._(this.field, this.constraints, this.dominoes);
}
