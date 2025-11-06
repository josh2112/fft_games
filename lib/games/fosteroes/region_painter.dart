import 'dart:math';

import 'package:flutter/material.dart';

import 'region.dart';
//import 'package:path_drawing/path_drawing.dart';

class RegionPalette {
  final Color label, fill, stroke;

  RegionPalette(MaterialColor color) : label = color, fill = color[200]!.withAlpha(96), stroke = color[800]!;
}

final fieldRegionPalette = RegionPalette(Colors.brown);
final dropHighlightRegionPalette = RegionPalette(Colors.amber);

final List<RegionPalette> constraintAreaPalette = [
  RegionPalette(Colors.green),
  RegionPalette(Colors.red),
  RegionPalette(Colors.blue),
  RegionPalette(Colors.purple),
  RegionPalette(Colors.deepOrange),
];

RegionPalette paletteForRegion(Region r, [int? i]) => switch (r) {
  FieldRegion _ => fieldRegionPalette,
  DropHighlightRegion _ => dropHighlightRegionPalette,
  _ => constraintAreaPalette[i! % constraintAreaPalette.length],
};

class RegionPainter extends CustomPainter {
  final Region _region;
  final RegionPalette _palette;
  final double cellSize;

  const RegionPainter(this._region, this._palette, this.cellSize);

  @override
  bool? hitTest(Offset position) => false;

  @override
  void paint(Canvas canvas, Size size) {
    for (final contour in _region.contours) {
      paintContour(canvas, contour);
    }
  }

  void paintContour(Canvas canvas, Contour contour) {
    final outset = (_region is FieldRegion ? 5.0 : -2.5);
    final cornerRadius = _region is FieldRegion ? 5.0 : 3.5;

    var path = _makePath(contour, outset, cornerRadius);

    for (final c in contour.holes) {
      path = Path.combine(PathOperation.difference, path, _makePath(c, outset, cornerRadius));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _palette.fill
        ..style = PaintingStyle.fill,
    );

    if (_region is! FieldRegion) {
      // This is a cheap imitation of what NYT Pips does -- their dashed outline
      // is aligned with the inside edge of the fill, not centered on the edge.
      // But flutter doesn't have a method to align or inset a stroke path.
      canvas.drawPath(
        path,
        Paint()
          ..color = _palette.fill
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        path, //dashPath(path, dashArray: CircularIntervalList([5, 2])),
        Paint()
          ..color = _palette.stroke
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RegionPainter oldDelegate) => _region != oldDelegate._region;

  Path _makePath(Contour contour, double outset, double cornerRadius) {
    final pts = [for (final pt in contour.points) Offset(pt.x * cellSize, pt.y * cellSize)];

    const double halfPi = pi / 2, twoPi = pi * 2;
    double angle(double d1, double d2) {
      var d = d2 - d1;
      if (d > halfPi) d -= twoPi;
      if (d < -halfPi) d += twoPi;
      return d;
    }

    // Direction of the line segment starting at this point, e.g. lineDirs[1] = pts[1] => pts[2]

    final lineDirs = [for (int i = 0; i < pts.length; ++i) (pts[(i + 1) % pts.length] - pts[i]).direction];

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
    return path;
  }
}
