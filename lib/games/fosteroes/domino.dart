import 'package:fft_games/games/fosteroes/board.dart';
import 'package:flutter/material.dart';

class Domino extends StatelessWidget {
  final DominoState domino;

  const Domino(this.domino, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(5),
        border: BoxBorder.all(color: colors.inverseSurface, width: 1),
        boxShadow: [BoxShadow(color: Colors.grey, offset: Offset(0, 2), blurRadius: 2)],
      ),
      child: RotatedBox(
        quarterTurns: domino.rotation,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HalfDomino(domino.side1, colors.inverseSurface),
              VerticalDivider(thickness: 1, indent: 5, width: 0, endIndent: 5),
              _HalfDomino(domino.side2, colors.inverseSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalfDomino extends StatelessWidget {
  static const width = 51.0, height = 50.0;
  static const hInset = 14.0;
  static const vInset = 15.0;

  static const pipSize = 8.0;
  static final pipRadius = pipSize / 2;

  static final double col1 = hInset - pipRadius, col2 = width / 2 - pipRadius, col3 = width - hInset - pipRadius;
  static final double row1 = vInset - pipRadius, row2 = height / 2 - pipRadius, row3 = height - vInset - pipRadius;
  //static const double

  final int pips;
  final Color color;

  const _HalfDomino(this.pips, this.color);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Stack(
      children: switch (pips) {
        1 => [Positioned(left: col2, top: row2, child: pip())],
        2 => [Positioned(left: col1, top: row1, child: pip()), Positioned(left: row3, top: row3, child: pip())],
        3 => [
          Positioned(left: col1, top: row1, child: pip()),
          Positioned(left: col2, top: row2, child: pip()),
          Positioned(left: col3, top: row3, child: pip()),
        ],
        4 => [
          Positioned(left: col1, top: row1, child: pip()),
          Positioned(left: col1, top: row3, child: pip()),
          Positioned(left: col3, top: row1, child: pip()),
          Positioned(left: col3, top: row3, child: pip()),
        ],
        5 => [
          Positioned(left: col1, top: row1, child: pip()),
          Positioned(left: col1, top: row3, child: pip()),
          Positioned(left: col3, top: row1, child: pip()),
          Positioned(left: col3, top: row3, child: pip()),
          Positioned(left: col2, top: row2, child: pip()),
        ],
        6 => [
          Positioned(left: col1, top: row1, child: pip()),
          Positioned(left: col2, top: row1, child: pip()),
          Positioned(left: col3, top: row1, child: pip()),
          Positioned(left: col1, top: row3, child: pip()),
          Positioned(left: col2, top: row3, child: pip()),
          Positioned(left: col3, top: row3, child: pip()),
        ],
        _ => [],
      },
    ),
  );

  Widget pip() => Container(
    width: pipSize,
    height: pipSize,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
