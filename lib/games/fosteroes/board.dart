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
              ListenableBuilder(
                listenable: boardState.floatingDomino,
                builder: (context, child) {
                  final floating = boardState.floatingDomino.value;
                  return floating != null
                      ? Positioned(
                          left: floating.baseCell.dx * Board.cellSize,
                          top: floating.baseCell.dy * Board.cellSize,
                          child: Opacity(opacity: 0.8, child: Domino(floating.domino)),
                        )
                      : SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
      onWillAcceptWithDetails: (details) {
        details.data.location = DominoLocation.dragging;
        return true;
      },
      onMove: (details) => onDominoDragged(details, boardState),
      onAcceptWithDetails: (details) => onDominoDropped(details, boardState),
      onLeave: (_) => highlightArea.value = null,
    );
  }

  Offset _globalPositionToCell(Offset globalPosition) {
    final renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox;
    final pos = renderBox.globalToLocal(globalPosition) ~/ Board.cellSize;
    return pos;
  }

  void onDominoDragged(DragTargetDetails<DominoState> details, BoardState boardState) {
    // If there is a separate floating domino, put it back
    final floatingDomino = boardState.floatingDomino.value?.domino;
    if (floatingDomino != null && details.data != floatingDomino) {
      boardState.unfloatDomino(isReturning: !boardState.canSnapFloatingDomino());
    }

    final baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.translate(0, 1) : baseCell.translate(1, 0)};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      highlightArea.value = HighlightRegion(cells.toList(), RegionPalette(Colors.amber));
    } else {
      highlightArea.value = null;
    }
  }

  void onDominoDropped(DragTargetDetails<DominoState> details, BoardState boardState) {
    highlightArea.value = null;

    var baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.translate(0, 1) : baseCell.translate(1, 0)};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      boardState.inHand.remove(domino);
      domino.location = DominoLocation.board;
      if (domino.direction == DominoDirection.left) {
        baseCell = baseCell.translate(1, 0);
      } else if (domino.direction == DominoDirection.up) {
        baseCell = baseCell.translate(0, 1);
      }

      if (boardState.floatingDomino.value?.domino == domino) {
        boardState.floatingDomino.value!.baseCell = baseCell;
        boardState.unfloatDomino();
      }

      boardState.onBoard.add(domino, baseCell);

      checkConstraints(boardState);
    } else {
      if (boardState.floatingDomino.value?.domino == domino) {
        domino.location = DominoLocation.floating;
      }
    }
  }

  void checkConstraints(BoardState boardState) {
    final cellContents = boardState.onBoard.cellContents();

    for (final c in boardState.puzzle.value!.constraints) {
      c.check(cellContents);
    }
  }
}
