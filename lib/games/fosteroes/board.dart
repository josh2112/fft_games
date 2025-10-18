import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class DominoState {
  final int side1, side2;

  int x = 0, y = 0;

  int rotation = 0;

  DominoState(this.side1, this.side2, {this.x = 0, this.y = 0});
}

class Board extends StatefulWidget {
  Board({super.key});

  final dominoes = [DominoState(1, 2, x: 0, y: 0), DominoState(3, 4, x: 1, y: 1), DominoState(5, 6, x: 2, y: 2)];

  @override
  State<Board> createState() => _BoardState();
}

class LineSegment {
  final Offset p1, p2;
  const LineSegment(this.p1, this.p2);

  bool get isHorizontal => p1.dx == p2.dx;

  @override
  String toString() => "$p1 -> $p2";
}

class _BoardState extends State<Board> {
  static const gridSize = 50.0;

  // TODO: What is the size of this fucken domino?

  final boardCells = [Offset(1, 0), Offset(2, 0), Offset(0, 1), Offset(1, 1)];

  late final List<Offset> contour;

  @override
  void initState() {
    contour = makeContour(boardCells);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(20),
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: gridSize * 4,
          height: gridSize * 4,
          child: Stack(
            children: [
              CustomPaint(
                painter: ContourPainter(
                  contour,
                  gridSize,
                  fillPaint: Paint()
                    ..color = Colors.brown[200]!
                    ..style = PaintingStyle.fill,
                  strokePaint: Paint()
                    ..color = Colors.brown[800]!
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2,
                ),
              ),
              for (final d in widget.dominoes) Positioned(left: d.x * gridSize, top: d.y * gridSize, child: Domino(d)),
            ],
          ),
        ),
      ),
    ),
  );

  List<Offset> makeContour(List<Offset> cells) {
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
    final contour = [start.p1, start.p2];
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

    return contour;
  }
}

class ContourPainter extends CustomPainter {
  final List<Offset> contour;
  final double gridSize;
  final Paint? fillPaint, strokePaint;

  const ContourPainter(this.contour, this.gridSize, {this.fillPaint, this.strokePaint});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    path.moveTo(contour.first.dx * gridSize, contour.first.dy * gridSize);

    for (final ls in contour.skip(1)) {
      path.lineTo(ls.dx * gridSize, ls.dy * gridSize);
    }

    if (fillPaint != null) {
      canvas.drawPath(path, fillPaint!);
    }

    if (strokePaint != null) {
      canvas.drawPath(dashPath(path, dashArray: CircularIntervalList([5, 5])), strokePaint!);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
