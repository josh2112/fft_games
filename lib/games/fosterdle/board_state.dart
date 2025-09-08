typedef WonGameCallback = Future<void> Function(int n);

class BoardState {
  final WonGameCallback onWin;

  final List<String> guesses = [];

  BoardState({required this.onWin}) {}

  void dispose() {}
}
