import 'dart:math';

import 'package:flutter/painting.dart';

class LineSegment {
  final Offset p1, p2;

  double get direction => (p2 - p1).direction;

  const LineSegment(this.p1, this.p2);

  @override
  String toString() => "$p1 -> $p2";
}

enum RegionRole { field, constraint }

class Region {
  final List<Offset> cells;
  final Color fill;
  final Color? stroke;
  final RegionRole role;

  late final List<Offset> contour;

  late final double width, height;

  Region(this.role, this.cells, double cellSize, this.fill, {this.stroke}) {
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

    for (int i = 0; i < contour.length; ++i) {
      contour[i] = contour[i].scale(cellSize, cellSize);
    }

    final xs = contour.map((p) => p.dx), ys = contour.map((p) => p.dy);
    width = xs.reduce(max) - xs.reduce(min);
    height = ys.reduce(max) - ys.reduce(min);
  }
}
