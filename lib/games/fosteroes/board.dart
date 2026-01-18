import 'package:fft_games_lib/fosteroes/region.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_state.dart';
import 'constraint_label.dart';
import 'domino.dart';
import 'region_painter.dart';

class Board extends StatefulWidget {
  static const cellSize = 53.0;

  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final _dragTargetKey = GlobalKey();

  final ValueNotifier<DropHighlightRegion?> highlightArea = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final puzzle = boardState.puzzle.value!;

    return DragTarget<DominoState>(
      key: _dragTargetKey,
      builder: (context, candidateData, rejectedData) => Padding(
        padding: EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 15),
        child: SizedBox(
          width: puzzle.field.bounds.width * Board.cellSize,
          height: puzzle.field.bounds.height * Board.cellSize,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(painter: RegionPainter(puzzle.field, paletteForRegion(puzzle.field), Board.cellSize)),
              for (final c in puzzle.field.cells)
                Positioned(
                  left: c.x * Board.cellSize + 1,
                  top: c.y * Board.cellSize + 1,
                  child: Container(
                    width: Board.cellSize - 2,
                    height: Board.cellSize - 2,
                    decoration: BoxDecoration(
                      color: Colors.brown[200]!.withValues(alpha: 0.5),
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
                          left: dOnBoard.value.x * Board.cellSize,
                          top: dOnBoard.value.y * Board.cellSize,
                          child: Domino(
                            dOnBoard.key,
                            rotateFrom: boardState.onBoard.getRotateFrom(dOnBoard.key),
                            translateFrom: boardState.onBoard.getAnimateFrom(dOnBoard.key),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              for (final (i, r) in puzzle.constraints.indexed)
                CustomPaint(painter: RegionPainter(r, paletteForRegion(r, i), Board.cellSize)),
              Positioned(
                child: ValueListenableBuilder(
                  valueListenable: highlightArea,
                  builder: (context, value, child) => Stack(
                    children: [
                      if (value != null)
                        CustomPaint(painter: RegionPainter(value, paletteForRegion(value), Board.cellSize)),
                    ],
                  ),
                ),
              ),
              Positioned(
                child: ValueListenableBuilder(
                  valueListenable: boardState.violatedConstraintRegions,
                  builder: (context, violatedConstraintRegions, child) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (i, r) in puzzle.constraints.indexed)
                        ConstraintLabel(
                          r,
                          paletteForRegion(r, i),
                          Board.cellSize,
                          violatedConstraintRegions.contains(r),
                        ),
                    ],
                  ),
                ),
              ),

              ListenableBuilder(
                listenable: boardState.floatingDomino,
                builder: (context, child) {
                  final floating = boardState.floatingDomino.value;
                  return floating != null
                      ? Positioned(
                          left: floating.baseCell.x * Board.cellSize,
                          top: floating.baseCell.y * Board.cellSize,
                          child: Opacity(
                            opacity: 0.8,
                            child: Domino(floating.domino, rotateFrom: floating.originalTurns),
                          ),
                        )
                      : SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
      onWillAcceptWithDetails: (details) {
        details.data.location.value = DominoLocation.dragging;
        return true;
      },
      onMove: (details) => onDominoDragged(details, boardState),
      onAcceptWithDetails: (details) => onDominoDropped(details, boardState),
      onLeave: (_) => highlightArea.value = null,
    );
  }

  Cell _globalPositionToCell(Offset globalPosition) {
    final renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox;
    final pos = renderBox.globalToLocal(globalPosition) ~/ Board.cellSize;
    return Cell(pos.dx.toInt(), pos.dy.toInt());
  }

  void onDominoDragged(DragTargetDetails<DominoState> details, BoardState boardState) {
    // If there is a separate floating domino, put it back
    final floatingDomino = boardState.floatingDomino.value?.domino;
    if (floatingDomino != null && details.data != floatingDomino) {
      boardState.unfloatDomino(isReturning: !boardState.canSnapFloatingDomino());
    }

    for (final d in boardState.inHand.positions.where((d) => d?.location.value != DominoLocation.dragging)) {
      d?.quarterTurns.value = 0;
    }

    final baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.down : baseCell.right};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      highlightArea.value = DropHighlightRegion(cells.toList());
    } else {
      highlightArea.value = null;
    }
  }

  void onDominoDropped(DragTargetDetails<DominoState> details, BoardState boardState) {
    highlightArea.value = null;

    var baseCell = _globalPositionToCell(details.offset);
    final domino = details.data;

    final cells = {baseCell, domino.isVertical ? baseCell.down : baseCell.right};

    if (boardState.puzzle.value!.field.canPlace(cells) && boardState.onBoard.canPlace(cells)) {
      boardState.inHand.remove(domino);
      domino.location.value = DominoLocation.board;
      if (domino.direction == DominoDirection.left) {
        baseCell = baseCell.right;
      } else if (domino.direction == DominoDirection.up) {
        baseCell = baseCell.down;
      }

      if (boardState.floatingDomino.value?.domino == domino) {
        boardState.floatingDomino.value!.baseCell = baseCell;
        boardState.unfloatDomino();
      }

      boardState.onBoard.add(domino, baseCell);
      boardState.maybeCheckConstraints();
    } else {
      domino.location.revert();
    }
  }
}
