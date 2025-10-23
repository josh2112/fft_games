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
                    cornerRadius: 10,
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
  final double direction;

  LineSegment(this.p1, this.p2) : direction = (p2 - p1).direction;

  @override
  String toString() => "$p1 -> $p2";
}

class Region {
  final List<Offset> cells;
  late final List<LineSegment> contour;

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

    contour = <LineSegment>[];

    // Now connect the lines. Find a corner to start.
    for (int i = 1; i < lines.length; ++i) {
      if (lines[i - 1].direction != lines[i].direction) {
        contour.add(lines[i]);
        lines.removeAt(i);
        break;
      }
    }

    // From the last line segment, find the one that connects to it.
    // If it's the same  direction, extend the previous one, otherwise append it. Continue until
    // all have been visited.

    while (lines.isNotEmpty) {
      final cur = contour.last;
      final next = lines.firstWhere((ln) => ln.p1 == cur.p2);
      if (next.direction == cur.direction) {
        contour.last = LineSegment(cur.p1, next.p2);
      } else {
        contour.add(next);
      }
      lines.remove(next);
    }

    final xall = contour.map((ls) => ls.p1.dx), yall = contour.map((ls) => ls.p1.dy);
    width = xall.reduce(max) - xall.reduce(min);
    height = yall.reduce(max) - yall.reduce(min);
  }
}

class ContourPainter extends CustomPainter {
  final List<LineSegment> contour;
  final double gridSize, outset;
  final Paint? fillPaint, strokePaint;

  // TODO: Add border radius

  final double cornerRadius;

  ContourPainter(
    this.contour,
    this.gridSize, {
    this.outset = 0,
    this.cornerRadius = 0,
    this.fillPaint,
    this.strokePaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaled = contour.map((ls) {
      final offset = Offset.fromDirection(ls.direction - pi / 2, outset);
      return LineSegment(
        ls.p1.scale(gridSize, gridSize).translate(offset.dx, offset.dy),
        ls.p2.scale(gridSize, gridSize).translate(offset.dx, offset.dy),
      );
    }).toList();

    // Returns whether the angle between line segments ls1 and ls2 is clockwise or counter-clockwise
    bool isCCW(int i1, int i2) {
      var d = scaled[i2].direction - scaled[i1].direction;
      if (d > pi / 2) d -= pi * 2;
      if (d < -pi / 2) d += pi * 2;
      return d < 0;
    }

    // Backs up end of the first line and pushes forward beginning of the second line
    void fixConcaveCorner(int i1, int i2) {
      var off = Offset.fromDirection(scaled[i1].direction, cornerRadius);
      var p = scaled[i1].p2.translate(-off.dx, -off.dy);
      scaled[i1] = LineSegment(scaled[i1].p1, p);
      off = Offset.fromDirection(scaled[i2].direction, cornerRadius);
      p = scaled[i2].p1.translate(off.dx, off.dy);
      scaled[i2] = LineSegment(p, scaled[i2].p2);
    }

    if (cornerRadius > 0) {
      for (int i = 1; i < scaled.length; ++i) {
        if (isCCW(i - 1, i)) {
          fixConcaveCorner(i - 1, i);
        }
      }

      if (isCCW(scaled.length - 1, 0)) {
        fixConcaveCorner(scaled.length - 1, 0);
      }
    }

    final path = Path();
    path.moveTo(scaled.first.p1.dx, scaled.first.p1.dy);
    path.lineTo(scaled.first.p2.dx, scaled.first.p2.dy);

    for (int i = 1; i < scaled.length; ++i) {
      path.arcToPoint(scaled[i].p1, radius: Radius.circular(cornerRadius / 2), clockwise: !isCCW(i - 1, i));
      path.lineTo(scaled[i].p2.dx, scaled[i].p2.dy);
    }

    path.arcToPoint(
      scaled.first.p1,
      radius: Radius.circular(cornerRadius / 2),
      clockwise: !isCCW(scaled.length - 1, 0),
    );
    path.lineTo(scaled.first.p2.dx, scaled.first.p2.dy);

    if (fillPaint != null) {
      canvas.drawPath(path, fillPaint!);
    }

    if (strokePaint != null) {
      canvas.drawPath(path, strokePaint!);
      //dashPath(path, dashArray: CircularIntervalList([3, 3])), strokePaint!);
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
