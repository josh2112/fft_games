import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fft_games/games/fosteroes/domino.dart';
import 'package:fft_games/games/fosteroes/region.dart';
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

  final constraints = <Region>[];
  late final Region field;

  @override
  void initState() {
    field = Region(
      RegionRole.field,
      [for (final d in widget.dominoes) d.position, for (final d in widget.dominoes) d.position.translate(1, 0)],
      gridSize,
      Colors.brown[200]!,
    );

    constraints.add(
      Region(
        RegionRole.constraint,
        [widget.dominoes[0].position, widget.dominoes[0].position.translate(1, 0)],
        gridSize,
        Colors.green[200]!.withAlpha(64),
        stroke: Colors.green[800]!,
      ),
    );
    constraints.add(
      Region(
        RegionRole.constraint,
        [Offset(2, 1), Offset(2, 2)],
        gridSize,
        Colors.blue[200]!.withAlpha(64),
        stroke: Colors.blue[800]!,
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(20),
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(5), // <- This should be >= the outset of the playing field
          child: SizedBox(
            width: field.width,
            height: field.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: RegionPainter(field)),
                for (final d in widget.dominoes)
                  Positioned(left: d.position.dx * gridSize, top: d.position.dy * gridSize, child: Domino(d)),
                for (final r in constraints) CustomPaint(painter: RegionPainter(r)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class RegionPainter extends CustomPainter {
  final Region region;

  const RegionPainter(this.region);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [...region.contour];

    const double halfPi = pi / 2, twoPi = pi * 2;
    double angle(double d1, double d2) {
      var d = d2 - d1;
      if (d > halfPi) d -= twoPi;
      if (d < -halfPi) d += twoPi;
      return d;
    }

    // Direction of the line segment starting at this point, e.g. lineDirs[1] = pts[1] => pts[2]
    final lineDirs = [for (int i = 0; i < pts.length; ++i) (pts[(i + 1) % pts.length] - pts[i]).direction];

    final outset = region.role == RegionRole.field ? 5.0 : -2.0;
    final cornerRadius = region.role == RegionRole.field ? 5.0 : 3.0;

    for (int i = 0; i < pts.length; ++i) {
      int i2 = (i + 1) % pts.length;
      final offset = Offset.fromDirection((pts[i2] - pts[i]).direction - pi / 2, outset);
      pts[i] += offset;
      pts[i2] += offset;
    }

    final path = Path();

    var pt2 = pts[0] - Offset.fromDirection(lineDirs.last, cornerRadius);
    path.moveTo(pt2.dx, pt2.dy);

    for (int i = 0; i < pts.length; ++i) {
      // Assuming already at start of arc at i, draw the arc at i, then the line from i to i+1

      path.arcToPoint(
        pts[i] + Offset.fromDirection(lineDirs[i], cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: angle(lineDirs[(i - 1) % pts.length], lineDirs[i]) > 0,
      );

      var pt2 = pts[(i + 1) % pts.length] - Offset.fromDirection(lineDirs[i], cornerRadius);
      path.lineTo(pt2.dx, pt2.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = region.fill
        ..style = PaintingStyle.fill,
    );

    if (region.stroke != null) {
      canvas.drawPath(
        dashPath(path, dashArray: CircularIntervalList([3, 3])),
        Paint()
          ..color = region.stroke!
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RegionPainter oldDelegate) => !region.contour.equals(oldDelegate.region.contour);
}
