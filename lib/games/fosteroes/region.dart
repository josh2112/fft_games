import 'dart:math';

import 'package:fft_games/games/fosteroes/board_state.dart';
import 'package:fft_games/games/fosteroes/puzzle.dart';
import 'package:flutter/material.dart';

import 'constraint.dart';

class LineSegment {
  final Offset p1, p2;

  double get direction => (p2 - p1).direction;

  const LineSegment(this.p1, this.p2);

  @override
  String toString() => "$p1 -> $p2";
}

abstract class Region {
  final List<Offset> cells;

  late final List<Offset> contour;

  late final double width, height;

  Region(this.cells) {
    final lines = <LineSegment>[];
    for (final cell in cells) {
      final right = cell.translate(1, 0), bottom = cell.translate(0, 1);
      // Check each of 4 sides. If no cell on that side, add a line segment, orienting it based on
      // which side it's on.
      if (!cells.contains(cell.translate(0, -1))) lines.add(LineSegment(cell, right));
      if (!cells.contains(right)) lines.add(LineSegment(right, right.translate(0, 1)));
      if (!cells.contains(bottom)) lines.add(LineSegment(bottom.translate(1, 0), bottom));
      if (!cells.contains(cell.translate(-1, 0))) lines.add(LineSegment(bottom, cell));
    }

    // Now connect the lines. Pick one to start. Find the one that connects to it. If it's the same
    // direction, extend the previous one, otherwise append it. Continue until all have been
    // visited.

    final start = lines.removeAt(0);
    contour = [start.p1, start.p2];
    var lastDir = start.p2 - start.p1;

    while (lines.isNotEmpty) {
      final next = lines.firstWhere((ln) => ln.p1 == contour.last);
      var dir = next.p2 - next.p1;
      if (dir == lastDir) {
        contour[contour.length - 1] = next.p2;
      } else {
        contour.add(next.p2);
      }
      lines.remove(next);
      lastDir = dir;
    }

    contour.removeLast();

    final xs = contour.map((p) => p.dx), ys = contour.map((p) => p.dy);
    width = xs.reduce(max) - xs.reduce(min);
    height = ys.reduce(max) - ys.reduce(min);
  }
}

class FieldRegion extends Region {
  FieldRegion(super.cells);

  bool canPlace(DominoState domino, Offset cell) =>
      domino.area(cell).every((c) => cells.contains(c));
}

class HighlightRegion extends Region {
  final RegionPalette palette;

  HighlightRegion(super.cells, this.palette);
}

class ConstraintRegion extends HighlightRegion {
  final Constraint constraint;

  ConstraintRegion(super.cells, this.constraint, super.palette);
}
