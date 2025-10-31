import 'package:collection/collection.dart';

abstract class Constraint {
  const Constraint();

  bool check(List<int> values);
}

abstract class ValueConstraint extends Constraint {
  final int value;

  const ValueConstraint(this.value);
}

abstract class EqualityConstraint extends Constraint {}

class EqualConstraint extends EqualityConstraint {
  @override
  String toString() => "=";

  @override
  bool check(List<int> values) => values.toSet().length == 1;
}

class NotEqualConstraint extends EqualityConstraint {
  @override
  String toString() => "!=";

  @override
  bool check(List<int> values) => values.toSet().length == values.length;
}

class GreaterThanConstraint extends ValueConstraint {
  const GreaterThanConstraint(super.value);

  @override
  String toString() => ">$value";

  @override
  bool check(List<int> values) => values.sum > value;
}

class LessThanConstraint extends ValueConstraint {
  const LessThanConstraint(super.value);

  @override
  String toString() => "<$value";

  @override
  bool check(List<int> values) => values.sum < value;
}

class SumConstraint extends ValueConstraint {
  const SumConstraint(super.value);

  @override
  String toString() => "$value";

  @override
  bool check(List<int> values) => values.sum == value;
}
