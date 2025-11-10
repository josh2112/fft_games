import 'package:fft_games/games/fosteroes/domino.dart';

import 'region.dart';

enum PuzzleDifficulty { easy, medium, hard }

class Puzzle {
  //static Puzzle empty = Puzzle(difficulty: PuzzleDifficulty.easy, field: FieldRegion([]), hand: [], constraints: []);

  final FieldRegion field;
  final Map<DominoState, Cell> solution;
  late final List<DominoState> dominoes;
  final List<ConstraintRegion> constraints;

  Puzzle({required this.field, required this.solution, required this.constraints}) {
    dominoes = [...solution.keys];
    for (final d in dominoes) {
      d.quarterTurns.value = 0;
    }
  }
}
