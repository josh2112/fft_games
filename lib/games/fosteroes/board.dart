import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'constraint_label.dart';
import 'domino.dart';
import 'puzzle.dart';
import 'region.dart';
import 'region_painter.dart';

class Board extends StatefulWidget {
  static const cellSize = 53.0;

  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final _dragTargetKey = GlobalKey();

  final ValueNotifier<HighlightRegion?> highlightArea = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final puzzle = boardState.puzzle.value!;

    return DragTarget<DominoState>(
      key: _dragTargetKey,
      builder: (context, candidateData, rejectedData) => Padding(
        padding: EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 15),
        child: SizedBox(
          width: puzzle.field.width * Board.cellSize,
          height: puzzle.field.height * Board.cellSize,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(painter: RegionPainter(puzzle.field, Board.cellSize)),
              for (final c in puzzle.field.cells)
                Positioned(
                  left: c.dx * Board.cellSize + 1,
                  top: c.dy * Board.cellSize + 1,
                  child: Container(
                    width: Board.cellSize - 2,
                    height: Board.cellSize - 2,
                    decoration: BoxDecoration(
                      color: Colors.brown[100]!,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                ),
              Positioned(
                child: ListenableBuilder(
                  listenable: boardState.onBoard,
                  builder: (context, child) => Stack(
                    children: [
                      for (final dOnBoard in boardState.onBoard.dominoes.entries)
                        Positioned(
                          left: dOnBoard.value.dx * Board.cellSize,
                          top: dOnBoard.value.dy * Board.cellSize,
                          child: Domino(dOnBoard.key),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                child: ValueListenableBuilder(
                  valueListenable: highlightArea,
                  builder: (context, value, child) =>
                      Stack(children: [if (value != null) CustomPaint(painter: RegionPainter(value, Board.cellSize))]),
                ),
              ),
              for (final r in puzzle.constraints) CustomPaint(painter: RegionPainter(r, Board.cellSize)),
              for (final r in puzzle.constraints) ConstraintLabel(r, Board.cellSize),
            ],
          ),
        ),
      ),
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) => onDragDomino(details, boardState),
      onAcceptWithDetails: (details) => onDropDomino(details, boardState),
      onLeave: (_) => highlightArea.value = null,
    );
  }

  Offset _globalPositionToCell(Offset globalPosition) {
    final renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox?;
    final pos = renderBox!.globalToLocal(globalPosition).translate(Board.cellSize / 2, Board.cellSize / 2);
    return pos ~/ Board.cellSize;
  }

  void onDragDomino(DragTargetDetails<DominoState> details, BoardState boardState) {
    final baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.translate(0, 1) : baseCell.translate(1, 0)};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      highlightArea.value = HighlightRegion(cells.toList(), RegionPalette(Colors.amber));
    } else {
      highlightArea.value = null;
    }
  }

  void onDropDomino(DragTargetDetails<DominoState> details, BoardState boardState) {
    highlightArea.value = null;

    final baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.translate(0, 1) : baseCell.translate(1, 0)};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      boardState.inHand.remove(domino);
      domino.location = DominoLocation.board;
      boardState.onBoard.add(domino, baseCell);
    }
  }
}
