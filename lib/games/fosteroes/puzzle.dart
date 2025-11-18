//import 'package:fft_games/games/fosteroes/domino.dart';

import 'domino_model.dart';
import 'region.dart';

enum PuzzleDifficulty { easy, medium, hard }

class PlacedDomino {
  final DominoModel domino;
  final Cell cell;
  final int rotation;

  PlacedDomino(this.domino, this.cell, this.rotation);
}

class Puzzle {
  //static Puzzle empty = Puzzle(difficulty: PuzzleDifficulty.easy, field: FieldRegion([]), hand: [], constraints: []);

  final FieldRegion field;
  final List<PlacedDomino> solution;
  late final List<DominoModel> dominoes;
  final List<ConstraintRegion> constraints;

  Puzzle({required this.field, required this.solution, required this.constraints}) {
    dominoes = solution.map((pd) => pd.domino).toList();
  }
}
