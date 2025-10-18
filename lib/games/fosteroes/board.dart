import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:flutter/material.dart';

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
  String toString() {
    return "$p1 -> $p2";
  }
}

class _BoardState extends State<Board> {
  static const gridSize = 52.0;

  final boardCells = [Offset(1, 0), Offset(2, 0)]; //[Offset(1, 0), Offset(2, 0), Offset(0, 1), Offset(1, 1)];

  @override
  void initState() {
    makeContour(boardCells);
    super.initState();
  }

  void makeContour(List<Offset> cells) {
    final lines = <LineSegment>[];
    for (final cell in cells) {
      final left = cell.translate(-1, 0),
          right = cell.translate(1, 0),
          top = cell.translate(0, -1),
          bottom = cell.translate(0, 1);
      // Check each of 4 sides. If no cell on that side, add a line segment, orienting it based on
      // which side it's on.
      if (!cells.contains(top)) lines.add(LineSegment(cell, right));
      if (!cells.contains(right)) lines.add(LineSegment(right, right.translate(0, 1)));
      if (!cells.contains(bottom)) lines.add(LineSegment(bottom.translate(1, 0), bottom));
      if (!cells.contains(left)) lines.add(LineSegment(bottom, cell));
    }

    // Now connect the lines. Pick 1 to start. Find the one that connects to it. If it's the same
    // direction, extend the previous one, otherwise append it. Continue until all have been
    // visited.

    final contour = [lines.removeAt(0)];

    while (lines.isNotEmpty) {
      final next = lines.firstWhere((ln) => ln.p1 == contour.last.p2);
      if (next.isHorizontal == contour.last.isHorizontal) {
        contour[contour.length - 1] = LineSegment(contour.last.p1, next.p2);
      } else {
        contour.add(next);
      }
    }

    print(contour);
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
              for (final d in widget.dominoes) Positioned(left: d.x * gridSize, top: d.y * gridSize, child: Domino(d)),
            ],
          ),
        ),
      ),
    ),
  );
}
