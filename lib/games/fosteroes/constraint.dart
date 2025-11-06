import 'package:collection/collection.dart';

abstract class Constraint {
  const Constraint();

  bool check(List<int> values);
}

abstract class ValueConstraintBase extends Constraint {
  final int value;

  const ValueConstraintBase(this.value);
}

abstract class EqualityConstraintBase extends Constraint {}

class EqualConstraint extends EqualityConstraintBase {
  @override
  String toString() => "=";

  @override
  bool check(List<int> values) => values.toSet().length == 1;
}

class NotEqualConstraint extends EqualityConstraintBase {
  @override
  String toString() => "!=";

  @override
  bool check(List<int> values) => values.toSet().length == values.length;
}

class GreaterThanConstraint extends ValueConstraintBase {
  const GreaterThanConstraint(super.value);

  @override
  String toString() => ">$value";

  @override
  bool check(List<int> values) => values.sum > value;
}

class LessThanConstraint extends ValueConstraintBase {
  const LessThanConstraint(super.value);

  @override
  String toString() => "<$value";

  @override
  bool check(List<int> values) => values.sum < value;
}

class SumConstraint extends ValueConstraintBase {
  const SumConstraint(super.value);

  @override
  String toString() => "$value";

  @override
  bool check(List<int> values) => values.sum == value;
}
