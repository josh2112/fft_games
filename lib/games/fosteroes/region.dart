import 'dart:math';

import 'package:collection/collection.dart';

import 'constraint.dart';

class Cell {
  static final origin = Cell(0, 0);

  final int x, y;

  const Cell(this.x, this.y);

  Cell get right => Cell(x + 1, y);
  Cell get left => Cell(x - 1, y);
  Cell get up => Cell(x, y - 1);
  Cell get down => Cell(x, y + 1);

  List<Cell> borderCells() => [left, right, up, down];

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Cell && other.x == x && other.y == y);

  Cell operator +(Cell other) => Cell(x + other.x, y + other.y);

  Cell operator -(Cell other) => Cell(x - other.x, y - other.y);

  double get direction => atan2(y, x);

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => "$x,$y";

  Cell adjacent(int quarterTurns) => switch (quarterTurns % 4) {
    0 => right,
    1 => down,
    2 => left,
    _ => up,
  };
}

class LineSegment {
  final Cell p1, p2;

  double get direction => (p2 - p1).direction;

  const LineSegment(this.p1, this.p2);

  @override
  String toString() => "$p1 -> $p2";
}

class Bounds {
  static Bounds zero = Bounds(0, 0, 0, 0);

  final int left, top, right, bottom;

  int get width => right - left;
  int get height => bottom - top;

  Bounds(this.left, this.top, this.right, this.bottom);

  Bounds expandToInclude(Bounds other) =>
      Bounds(min(left, other.left), min(top, other.top), max(right, other.right), max(bottom, other.bottom));
}

// A boundary of a closed area. Can also have child contours which are interpreted as holes in the contour.
class Contour {
  // Stored as cells but of course these are points at the corners of cell (e.g. (0,0)->(0,1) is a line from the
  // top-left to the bottom-left of the cell at (0,0)).
  final List<Cell> points;

  final List<Contour> holes = [];

  late final Bounds bounds;

  Contour(this.points) {
    final xs = points.map((p) => p.x), ys = points.map((p) => p.y);
    bounds = Bounds(xs.reduce(min), ys.reduce(min), xs.reduce(max), ys.reduce(max));
  }
}

abstract class Region {
  final List<Cell> cells;

  late final List<Contour> contours;

  late final Bounds bounds;

  Region(this.cells) {
    // 1) Identify islands by splitting the cells into connected regions.
    // 2) For each connected region, process the contour:
    //    a) Make a list of line segments of border pixels
    //    b) Pick a line segment and trace a complete contour
    //    c) If any line segments left, repeat b) (but these contours will be holes)

    contours = _split(cells).map((island) => _contourize(island)).toList();

    Bounds bounds = contours.firstOrNull?.bounds ?? Bounds.zero;
    for (final b in contours.map((c) => c.bounds).skip(1)) {
      bounds = bounds.expandToInclude(b);
    }
    this.bounds = bounds;
  }

  static Contour _contourize(Set<Cell> cells) {
    final lines = <LineSegment>[];

    // Now connect the lines. Pick one to start. Find the one that connects to it. If it's the same
    // direction, extend the previous one, otherwise append it. Continue until all have been
    // visited.

    for (final cell in cells) {
      // Check each of 4 sides. If no cell on that side, add a line segment, orienting it based on
      // which side it's on.
      if (!cells.contains(cell.up)) lines.add(LineSegment(cell, cell.right));
      if (!cells.contains(cell.right)) lines.add(LineSegment(cell.right, cell.right.down));
      if (!cells.contains(cell.down)) lines.add(LineSegment(cell.right.down, cell.down));
      if (!cells.contains(cell.left)) lines.add(LineSegment(cell.down, cell));
    }

    List<Contour> contours = [];
    while (lines.isNotEmpty) {
      contours.add(Contour(_findBoundary(lines)));
    }

    // Now we have a list of contours. One of them will be the outside and the others will be holes.
    final leftmost = contours.map((c) => c.bounds.left).min;
    final parentContour = contours.firstWhere((c) => c.bounds.left == leftmost);
    parentContour.holes.addAll(contours.where((c) => c != parentContour));

    return parentContour;
  }

  static List<Cell> _findBoundary(List<LineSegment> lines) {
    final start = lines.removeAt(0);
    var boundary = [start.p1, start.p2];
    var lastDir = start.p2 - start.p1;

    while (lines.isNotEmpty) {
      final next = lines.firstWhereOrNull((ln) => ln.p1 == boundary.last);
      if (next == null) {
        // Whoops -- we have additional line segments, but they're not connected to the main
        // contour! They must form one or more holes.
        break;
      }

      var dir = next.p2 - next.p1;
      if (dir == lastDir) {
        boundary[boundary.length - 1] = next.p2;
      } else {
        boundary.add(next.p2);
      }
      lines.remove(next);
      lastDir = dir;
    }

    boundary.removeLast();

    // Ensure that if we started in the middle of the line, we collapse it
    if ((boundary[1] - boundary[0]).direction == (boundary[0] - boundary.last).direction) {
      boundary[0] = boundary.last;
      boundary.removeLast();
    }

    return boundary;
  }

  static List<Set<Cell>> _split(List<Cell> cells) {
    final unvisited = {...cells};

    void floodFill(Cell cell, Set<Cell> island) {
      for (final c in cell.borderCells()) {
        if (unvisited.contains(c) && island.add(c)) {
          unvisited.remove(c);
          floodFill(c, island);
        }
      }
    }

    final islands = <Set<Cell>>[];

    while (unvisited.isNotEmpty) {
      islands.add({unvisited.first});
      unvisited.remove(unvisited.first);
      floodFill(islands.last.first, islands.last);
    }
    return islands;
  }
}

class FieldRegion extends Region {
  FieldRegion(super.cells);

  bool canPlace(Set<Cell> domino) => domino.every((c) => cells.contains(c));
}

class ConstraintRegion extends Region {
  final Constraint constraint;

  ConstraintRegion(super.cells, this.constraint);

  bool check(Map<Cell, int> cellContents) {
    final values = cellContents.entries.where((e) => cells.contains(e.key)).map((e) => e.value).toList();
    return values.length != cells.length ? false : constraint.check(values);
  }
}

class DropHighlightRegion extends Region {
  DropHighlightRegion(super.cells);
}
