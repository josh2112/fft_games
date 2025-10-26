import 'package:provider/provider.dart';

import 'board_state.dart';
import 'constraint_label.dart';
import 'domino.dart';
import 'puzzle.dart';
import 'region_painter.dart';

import 'package:flutter/material.dart';

class Board extends StatefulWidget {
  static const cellSize = 53.0;

  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final _dragTargetKey = GlobalKey();

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
              for (final dOnBoard in boardState.onBoard.entries)
                Positioned(
                  left: dOnBoard.value.dx * Board.cellSize,
                  top: dOnBoard.value.dy * Board.cellSize,
                  child: DraggableDomino(dOnBoard.key),
                ),
              for (final r in puzzle.constraints)
                CustomPaint(painter: RegionPainter(r, Board.cellSize)),
              for (final r in puzzle.constraints) ConstraintLabel(r, Board.cellSize),
            ],
          ),
        ),
      ),
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) => onDragDomino(details, puzzle),
      onAcceptWithDetails: (details) => onDropDomino(details, boardState),
    );
  }

  Offset globalPositionToCell(Offset globalPosition) {
    final renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox!.globalToLocal(globalPosition) ~/ Board.cellSize;
  }

  void onDragDomino(DragTargetDetails<DominoState> details, Puzzle puzzle) {
    final cell = globalPositionToCell(details.offset);
    if (puzzle.field.cells.contains(cell)) {
      print(cell);
      // TODO: Highlight the destination cells
    }
  }

  void onDropDomino(DragTargetDetails<DominoState> details, BoardState boardState) {
    final cell = globalPositionToCell(details.offset);
    if (boardState.puzzle.value!.field.cells.contains(cell)) {
      boardState.inHand.remove(details.data);
      boardState.onBoard[details.data] = cell;
    }
    return;
  }
}
