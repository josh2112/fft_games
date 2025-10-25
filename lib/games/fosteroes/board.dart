import 'package:provider/provider.dart';

import 'board_state.dart';
import 'constraint_label.dart';
import 'domino.dart';
import 'region_painter.dart';

import 'package:flutter/material.dart';

class Board extends StatefulWidget {
  static const cellSize = 52.0;

  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  @override
  Widget build(BuildContext context) {
    final boardState = context.watch<BoardState>();
    final puzzle = boardState.puzzle.value!;

    return Padding(
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
                left: dOnBoard.value.dx,
                top: dOnBoard.value.dy,
                child: Domino(dOnBoard.key),
              ),
            for (final r in puzzle.constraints)
              CustomPaint(painter: RegionPainter(r, Board.cellSize)),
            for (final r in puzzle.constraints) ConstraintLabel(r, Board.cellSize),
          ],
        ),
      ),
    );
  }
}
