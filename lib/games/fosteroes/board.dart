import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class DominoState {
  final int side1, side2;

  Offset position;

  int rotation = 0;

  DominoState(this.side1, this.side2, this.position);
}

class Board extends StatefulWidget {
  Board({super.key});

  final dominoes = [DominoState(1, 2, Offset(0, 0)), DominoState(3, 4, Offset(1, 1)), DominoState(5, 6, Offset(2, 2))];

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  static const gridSize = 52.0;

  late final Region field;

  @override
  void initState() {
    field = Region([
      for (final d in widget.dominoes) d.position,
      for (final d in widget.dominoes) d.position.translate(1, 0),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(20),
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(5), // <- This should be the outset of the playing field
          child: SizedBox(
            width: field.width * gridSize,
            height: field.height * gridSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: ContourPainter(
                    field.contour,
                    gridSize,
                    fillPaint: Paint()
                      ..color = Colors.brown[200]!
                      ..style = PaintingStyle.fill,
                    strokePaint: Paint()
                      ..color = Colors.brown[800]!
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1,
                    outset: 5,
                  ),
                ),
                for (final d in widget.dominoes)
                  Positioned(left: d.position.dx * gridSize, top: d.position.dy * gridSize, child: Domino(d)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LineSegment {
  final Offset p1, p2;
  const LineSegment(this.p1, this.p2);

  bool get isHorizontal => p1.dx == p2.dx;

  @override
  String toString() => "$p1 -> $p2";
}

class Region {
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

    final xs = contour.map((p) => p.dx), ys = contour.map((p) => p.dy);
    width = xs.reduce(max) - xs.reduce(min);
    height = ys.reduce(max) - ys.reduce(min);
  }
}

class ContourPainter extends CustomPainter {
  final List<Offset> contour;
  final double gridSize, outset;
  final Paint? fillPaint, strokePaint;

  // TODO: Add border radius

  ContourPainter(this.contour, this.gridSize, {this.outset = 0, this.fillPaint, this.strokePaint});

  @override
  void paint(Canvas canvas, Size size) {
    final dirs = [
      for (int i = 1; i < contour.length; ++i) (contour[i] - contour[i - 1]).direction,
      (contour.first - contour.last).direction,
    ];

    final pts = contour.map((p) => p.scale(gridSize, gridSize)).toList();

    for (int i = 0; i < dirs.length - 1; ++i) {
      var offset = Offset.fromDirection(dirs[i] - pi / 2, outset);
      pts[i] = pts[i].translate(offset.dx, offset.dy);
      pts[i + 1] = pts[i + 1].translate(offset.dx, offset.dy);
    }

    var offset = Offset.fromDirection(dirs.last - pi / 2, outset);
    pts.last = pts.last.translate(offset.dx, offset.dy);

    final path = Path();
    path.moveTo(pts.first.dx, pts.first.dy);

    for (int i = 1; i < pts.length; ++i) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }

    if (fillPaint != null) {
      canvas.drawPath(path, fillPaint!);
    }

    if (strokePaint != null) {
      canvas.drawPath(dashPath(path, dashArray: CircularIntervalList([5, 5])), strokePaint!);
    }
  }

  @override
  bool shouldRepaint(covariant ContourPainter oldDelegate) =>
      !contour.equals(oldDelegate.contour) ||
      gridSize != oldDelegate.gridSize ||
      fillPaint != oldDelegate.fillPaint ||
      strokePaint != oldDelegate.strokePaint ||
      outset != oldDelegate.outset;
}
