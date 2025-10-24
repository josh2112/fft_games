import 'dart:math';
import 'package:fft_games/games/fosteroes/region.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class RegionPainter extends CustomPainter {
  final Region _region;
  final double cellSize;

  const RegionPainter(this._region, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final pt in _region.contour) pt.scale(cellSize, cellSize)];

    const double halfPi = pi / 2, twoPi = pi * 2;
    double angle(double d1, double d2) {
      var d = d2 - d1;
      if (d > halfPi) d -= twoPi;
      if (d < -halfPi) d += twoPi;
      return d;
    }

    // Direction of the line segment starting at this point, e.g. lineDirs[1] = pts[1] => pts[2]

    final lineDirs = [
      for (int i = 0; i < pts.length; ++i) (pts[(i + 1) % pts.length] - pts[i]).direction,
    ];

    final outset = _region is Field ? 5.0 : -2.0;
    final cornerRadius = _region is Field ? 5.0 : 3.0;

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

    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = _region is ConstraintArea ? _region.palette.fill : Colors.brown[200]!
        ..style = PaintingStyle.fill,
    );

    // This is a cheap imitation of what NYT Pips does -- their dashed outline
    // is aligned with the inside edge of the fill, not centered on the edge.
    // But flutter doesn't have a method to align or inset a stroke path.
    canvas.drawPath(
      path,
      Paint()
        ..color = _region is ConstraintArea ? _region.palette.fill : Colors.brown[200]!
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    if (_region is ConstraintArea) {
      canvas.drawPath(
        dashPath(path, dashArray: CircularIntervalList([8, 8])),
        Paint()
          ..color = _region.palette.stroke
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RegionPainter oldDelegate) => _region != oldDelegate._region;
}
