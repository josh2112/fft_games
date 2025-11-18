class DominoModel {
  final int id, side1, side2;

  DominoModel(this.id, this.side1, this.side2);

  @override
  operator ==(Object other) => identical(this, other) || (other is DominoModel && other.id == id);

  @override
  int get hashCode => id;

  @override
  String toString() => "$side1/$side2";
}
