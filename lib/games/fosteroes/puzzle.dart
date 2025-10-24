import 'dart:convert';

import 'package:fft_games/games/fosteroes/constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'region.dart';

class ConstraintAreaPalette {
  final Color label, fill, stroke;

  ConstraintAreaPalette(MaterialColor color) : label = color, fill = color[200]!.withAlpha(96), stroke = color[800]!;
}

class Palette {
  final List<ConstraintAreaPalette> constraintAreaPalette = [
    ConstraintAreaPalette(Colors.green),
    ConstraintAreaPalette(Colors.blue),
    ConstraintAreaPalette(Colors.red),
  ];
}

class Puzzle {
  final Field field;
  final List<ConstraintArea> constraints;

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

    final def = jsonDecode(await rootBundle.loadString('assets/fosteroes/puzzle1.json'));
    final field = Field(parseOffsets(def["field"]));

    final pals = Palette().constraintAreaPalette;
    int i = 0;

    final constraints = [
      for (final c in def["constraints"])
        ConstraintArea(parseOffsets(c["cells"]), parseConstraint(c), pals[i++ % pals.length]),
    ];
    return Puzzle._(field, constraints);
  }

  Puzzle._(this.field, this.constraints);
}
