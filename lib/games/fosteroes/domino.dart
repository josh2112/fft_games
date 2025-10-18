import 'package:fft_games/games/fosteroes/board.dart';
import 'package:flutter/material.dart';

class Domino extends StatelessWidget {
  final DominoState domino;

  const Domino(this.domino, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5, left: 2, right: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(color: Colors.grey, offset: Offset(0, 2), blurRadius: 2)],
        ),
        child: RotatedBox(
          quarterTurns: domino.rotation,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HalfDomino(domino.side1),
                VerticalDivider(thickness: 1, indent: 5, width: 0, endIndent: 5),
                _HalfDomino(domino.side2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfDomino extends StatelessWidget {
  static final size = 50.0;
  static final hPad = 14.0;
  static final vPad = 15.0;

  static final pipSize = 8.0;
  static final pipRadius = pipSize / 2;

  static final double col1 = hPad - pipRadius, col2 = size / 2 - pipRadius, col3 = size - hPad - pipRadius;
  static final double row1 = vPad - pipRadius, row2 = size / 2 - pipRadius, row3 = size - vPad - pipRadius;
  //static const double

  final int pips;

  const _HalfDomino(this.pips);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
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
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black),
  );
}
