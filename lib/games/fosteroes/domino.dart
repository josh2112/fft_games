import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';

enum DominoLocation { hand, board }

class DominoState {
  final int side1, side2;
  int quarterTurns = 0;

  bool get isVertical => quarterTurns % 2 == 1;

  DominoLocation location = DominoLocation.hand;

  DominoState(this.side1, this.side2);

  Set<Offset> area(Offset baseCell) => switch (quarterTurns % 4) {
    0 => {baseCell, baseCell.translate(1, 0)},
    1 => {baseCell, baseCell.translate(0, 1)},
    2 => {baseCell, baseCell.translate(-1, 0)},
    _ => {baseCell, baseCell.translate(0, -1)},
  };
}

class Domino extends StatefulWidget {
  final DominoState state;
  final bool isBeingDragged;

  const Domino(this.state, {this.isBeingDragged = false, super.key});

  @override
  State<Domino> createState() => _DominoState();
}

// TODO: While being dragged, scale child to size of domino on board!

class _DominoState extends State<Domino> {
  @override
  Widget build(BuildContext context) {
    final meat = GestureDetector(
      onTap: () => setState(() => widget.state.quarterTurns += 1),
      behavior: HitTestBehavior.opaque,
      child: Draggable<DominoState>(
        feedback: RotatedBox(
          quarterTurns: widget.state.quarterTurns,
          child: Opacity(opacity: 0.8, child: _Domino(widget.state)),
        ),
        childWhenDragging: SizedBox(),
        hitTestBehavior: HitTestBehavior.opaque,
        data: widget.state,
        dragAnchorStrategy: centeredDragAnchorStrategy,
        child: _Domino(widget.state),
      ),
    );

    return AnimatedRotation(
      turns: widget.state.quarterTurns / 4.0,
      duration: Duration(milliseconds: 200),
      alignment: widget.state.location == DominoLocation.hand ? Alignment.center : FractionalOffset(0.25, 0.5),
      child: widget.isBeingDragged ? meat : DeferPointer(child: meat),
    );
  }

  // Returns an offset to the center of the domino, regardless of orientation.
  Offset centeredDragAnchorStrategy(Draggable<Object> d, BuildContext context, Offset point) =>
      (d.data as DominoState).isVertical
      ? Offset(_HalfDomino.height / 2, _HalfDomino.width)
      : Offset(_HalfDomino.width, _HalfDomino.height / 2);
}

class _Domino extends StatelessWidget {
  final DominoState state;

  const _Domino(this.state);

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

class _HalfDomino extends StatelessWidget {
  static const width = 51.0, height = 50.0;
  static const hInset = 14.0;
  static const vInset = 15.0;

  static const pipSize = 8.0;
  static final pipRadius = pipSize / 2;

  static final double col1 = hInset - pipRadius, col2 = width / 2 - pipRadius, col3 = width - hInset - pipRadius;
  static final double row1 = vInset - pipRadius, row2 = height / 2 - pipRadius, row3 = height - vInset - pipRadius;

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
