import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:fft_games_lib/fosteroes/domino.dart' as model;
import 'package:fft_games_lib/fosteroes/region.dart';
import 'package:flutter/material.dart';

enum DominoLocation { hand, board, floating, dragging }

enum DominoDirection { right, down, left, up }

class DominoLocationNotifier extends ValueNotifier<DominoLocation> {
  late DominoLocation _prev;

  DominoLocationNotifier(super.value) : _prev = value;

  @override
  set value(DominoLocation newValue) {
    if (newValue != value) {
      print("domino location $value => $newValue");
      _prev = value;
      super.value = newValue;
    }
  }

  void revert() => value = _prev;
}

class DominoState extends model.Domino {
  final ValueNotifier<int> quarterTurns = ValueNotifier(0);

  final location = DominoLocationNotifier(DominoLocation.hand);

  DominoDirection get direction => DominoDirection.values[quarterTurns.value % 4];

  bool get isVertical => quarterTurns.value % 2 == 1;

  DominoState(super.id, super.side1, super.side2);

  List<Cell> area(Cell baseCell) => [baseCell, baseCell.adjacent(quarterTurns.value)];

  @override
  String toString() => "Domino $side1/$side2 ${direction.name}, ${location.value.name}";
}

class Domino extends StatefulWidget {
  final DominoState state;
  final int? rotateFrom;
  final Offset? translateFrom;

  Domino(this.state, {this.rotateFrom, this.translateFrom}) : super(key: ValueKey(state));

  @override
  State<Domino> createState() => _DominoState();
}

// TODO: While being dragged, scale child to size of domino on board!

class _DominoState extends State<Domino> {
  int? initialRotation;
  Offset? initialTranslation;

  @override
  initState() {
    super.initState();
    initialRotation = widget.rotateFrom;
    initialTranslation = widget.translateFrom;

    // If given an initial rotation, use it initially, then immediately rebuild with the current rotation.
    if (initialRotation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => initialRotation = null);
      });
    }

    // If given an initial translation, use it initially, then immediately rebuild with no translation.
    if (initialTranslation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => initialTranslation = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: (initialTranslation ?? Offset.zero),
      duration: Duration(milliseconds: 200),
      child: ListenableBuilder(
        listenable: widget.state.location,
        builder: (context, child) => AnimatedRotation(
          turns: (initialRotation ?? widget.state.quarterTurns.value) / 4.0,
          duration: Duration(milliseconds: 200),
          alignment: widget.state.location.value == DominoLocation.hand
              ? Alignment.center
              : FractionalOffset(0.25, 0.5),
          child: DeferPointer(
            child: GestureDetector(
              onTap: onRotateDomino,
              behavior: HitTestBehavior.opaque,
              child: Draggable<DominoState>(
                feedback: RotatedBox(
                  quarterTurns: widget.state.quarterTurns.value,
                  child: Opacity(opacity: 0.8, child: _Domino(widget.state)),
                ),
                childWhenDragging: SizedBox(),
                hitTestBehavior: HitTestBehavior.opaque,
                data: widget.state,
                dragAnchorStrategy: centeredDragAnchorStrategy,
                onDragStarted: () => widget.state.location.value = DominoLocation.dragging,
                onDraggableCanceled: (v, o) => widget.state.location.revert(),
                child: _Domino(widget.state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Returns an offset to the center of the domino, regardless of orientation.
  Offset centeredDragAnchorStrategy(Draggable<Object> d, BuildContext context, Offset point) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final local = renderObject.globalToLocal(point);

    final xform = Matrix4.identity()
      ..translateByDouble(HalfDomino.width, HalfDomino.height / 2, 0, 1)
      ..rotateZ((d.data as DominoState).quarterTurns.value * pi / 2)
      ..translateByDouble(-HalfDomino.width, -HalfDomino.height / 2, 0, 1);

    var xformed = MatrixUtils.transformPoint(xform, local);

    if ((d.data as DominoState).isVertical) {
      // TODO: Big hack -- figure out what the correct formula is!
      xformed += Offset(-HalfDomino.height / 2, HalfDomino.height / 2);
    }

    return xformed;
  }

  void onRotateDomino() {
    setState(() => widget.state.quarterTurns.value += 1);
  }
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
        borderRadius: BorderRadius.circular(6),
        border: BoxBorder.all(color: colors.inverseSurface, width: 1.5),
      ),

      width: HalfDomino.width * 2 + 4,
      height: HalfDomino.height + 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          HalfDomino(state.side1, colors.inverseSurface),
          VerticalDivider(thickness: 1, indent: 5, width: 1, endIndent: 5),
          HalfDomino(state.side2, colors.inverseSurface),
        ],
      ),
    );
  }
}

class HalfDomino extends StatelessWidget {
  static const width = 51.0, height = 50.0;
  static const hInset = 14.0;
  static const vInset = 15.0;

  static const pipSize = 8.0;
  static final pipRadius = pipSize / 2;

  static final double col1 = hInset - pipRadius, col2 = width / 2 - pipRadius, col3 = width - hInset - pipRadius;
  static final double row1 = vInset - pipRadius, row2 = height / 2 - pipRadius, row3 = height - vInset - pipRadius;

  final int pips;
  final Color color;

  const HalfDomino(this.pips, this.color, {super.key});

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
    width: HalfDomino.width * 2 + 3,
    height: HalfDomino.height + 3,
  );
}
