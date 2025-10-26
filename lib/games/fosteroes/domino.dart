import 'package:flutter/material.dart';

import 'board_state.dart';

class DraggableDomino extends StatefulWidget {
  final DominoState state;

  const DraggableDomino(this.state, {super.key});

  @override
  State<DraggableDomino> createState() => _DraggableDominoState();
}

class _DraggableDominoState extends State<DraggableDomino> {
  @override
  Widget build(BuildContext context) {
    /*AnimatedRotation(
          turns: widget.state.rotation / 4.0,
          duration: Duration(milliseconds: 200),
          child: 
          
          
    GestureDetector(
        onTap: () => setState(() => widget.state.rotation += 1),

        child: */

    return Draggable<DominoState>(
      feedback: Domino(widget.state), // TODO: Scale child to size of domino on board!
      childWhenDragging: DominoPlaceholder(),
      data: widget.state,
      child: Domino(widget.state),
    );
  }
}

class Domino extends StatelessWidget {
  final DominoState state;

  const Domino(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: BoxBorder.all(color: colors.inverseSurface, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HalfDomino(state.side1, colors.inverseSurface),
            VerticalDivider(thickness: 1, indent: 5, width: 0, endIndent: 5),
            _HalfDomino(state.side2, colors.inverseSurface),
          ],
        ),
      ),
    );
  }
}

class DominoPlaceholder extends StatelessWidget {
  static final color = Colors.grey.withValues(alpha: 0.5);

  const DominoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    width: _HalfDomino.width * 2 + 3,
    height: _HalfDomino.height + 3,
  );
}

class _HalfDomino extends StatelessWidget {
  static const width = 51.0, height = 50.0;
  static const hInset = 14.0;
  static const vInset = 15.0;

  static const pipSize = 8.0;
  static final pipRadius = pipSize / 2;

  static final double col1 = hInset - pipRadius,
      col2 = width / 2 - pipRadius,
      col3 = width - hInset - pipRadius;
  static final double row1 = vInset - pipRadius,
      row2 = height / 2 - pipRadius,
      row3 = height - vInset - pipRadius;

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
        2 => [
          Positioned(left: col1, top: row1, child: pip()),
          Positioned(left: row3, top: row3, child: pip()),
        ],
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
