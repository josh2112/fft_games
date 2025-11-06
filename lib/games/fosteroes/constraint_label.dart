import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

import 'constraint.dart';
import 'region.dart';
import 'region_painter.dart';

class ConstraintLabel extends StatelessWidget {
  static const double size = 36;
  static const Offset offset = Offset(17, 16.2);

  final ConstraintRegion region;
  final RegionPalette palette;
  final double cellSize;

  const ConstraintLabel(this.region, this.palette, this.cellSize, {super.key});

  @override
  Widget build(BuildContext context) {
    final y = region.cells.map((c) => c.y).reduce(max);
    final x = region.cells.where((c) => c.y == y).map((pt) => pt.x).reduce(max);
    return Positioned(
      left: (x + 1) * cellSize - offset.dx,
      top: (y + 1) * cellSize - offset.dy,
      child: ClipPath(
        clipper: ConstraintLabelClip(),
        child: Container(
          width: size,
          height: size,
          color: palette.stroke,
          child: Center(
            child: Text(
              region.constraint.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: region.constraint is EqualityConstraintBase ? 16 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConstraintLabelClip extends CustomClipper<Path> {
  static final Path path = parseSvgPath(
    "M 0.50000023,0 C 0.47165759,-5.545189e-8 0.4433074,0.01085607 0.42159029,0.03257305 l -0.0335772,0.03357569 1e-7,0.13344327 c -1e-7,0.0921373 -0.0741944,0.16630258 -0.16633169,0.16630258 l -0.1334144,1.4e-7 -0.05569216,0.0556921 c -0.04343389,0.0434339 -0.04343378,0.11335769 1.8e-7,0.15679157 l 0.38901365,0.38904197 c 0.0434339,0.0434343 0.11338603,0.0434343 0.15682029,0 L 0.96742418,0.578407 c 0.0434339,-0.0434339 0.0434339,-0.11338603 3e-8,-0.1568203 L 0.57838196,0.0325732 C 0.55666499,0.01085622 0.52834211,0 0.50000023,0 Z",
  );

  const ConstraintLabelClip();

  @override
  Path getClip(Size size) {
    return path.transform(Float64List.fromList([size.width, 0, 0, 0, 0, size.width, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
