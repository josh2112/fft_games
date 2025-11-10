enum PuzzleType { daily, autogen }

extension DurationToString on Duration {
  String formatHHMMSS() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String mm = twoDigits(inMinutes.remainder(60));
    String ss = twoDigits(inSeconds.remainder(60));
    return "$inHours:$mm:$ss";
  }
}
