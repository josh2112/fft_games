import 'puzzle.dart';
import 'constraint_label.dart';
import 'domino.dart';
import 'region_painter.dart';

import 'package:flutter/material.dart';

class DominoState {
  final int side1, side2;

  Offset position;

  int rotation = 0;

  DominoState(this.side1, this.side2, this.position);
}

class Board extends StatefulWidget {
  Board({super.key});

  final dominoes = [DominoState(1, 2, Offset(0, 0)), DominoState(5, 6, Offset(2, 2))];

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  static const cellSize = 52.0;

  final ValueNotifier<Puzzle?> puzzle = ValueNotifier(null);

  Future loadPuzzle(String path) async {
    puzzle.value = await Puzzle.fromJsonFile(path);
  }

  @override
  void initState() {
    loadPuzzle('assets/json/puzzle1.json');
    super.initState();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: puzzle,
    builder: (context, puzzle, child) => puzzle == null
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: EdgeInsets.all(5), // <- This should be >= the outset of the playing field
                  child: SizedBox(
                    width: puzzle.field.width * cellSize,
                    height: puzzle.field.height * cellSize,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(painter: RegionPainter(puzzle.field, cellSize)),
                        for (final c in puzzle.field.cells)
                          Positioned(
                            left: c.dx * cellSize + 1,
                            top: c.dy * cellSize + 1,
                            child: Container(
                              width: cellSize - 2,
                              height: cellSize - 2,
                              decoration: BoxDecoration(
                                color: Colors.brown[100]!,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              ),
                            ),
                          ),
                        for (final d in widget.dominoes)
                          Positioned(left: d.position.dx * cellSize, top: d.position.dy * cellSize, child: Domino(d)),
                        for (final r in puzzle.constraints) CustomPaint(painter: RegionPainter(r, cellSize)),
                        for (final r in puzzle.constraints) ConstraintLabel(r, cellSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}
