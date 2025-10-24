abstract class Constraint {
  const Constraint();
}

abstract class ValueConstraint extends Constraint {
  final int value;

  const ValueConstraint(this.value);
}

abstract class EqualityConstraint extends Constraint {}

class EqualConstraint extends EqualityConstraint {
  @override
  String toString() => "=";
}

class NotEqualConstraint extends EqualityConstraint {
  @override
  String toString() => "!=";
}

class GreaterThanConstraint extends ValueConstraint {
  const GreaterThanConstraint(super.value);

  @override
  String toString() => ">$value";
}

class LessThanConstraint extends ValueConstraint {
  const LessThanConstraint(super.value);

  @override
  String toString() => "<$value";
}

class SumConstraint extends ValueConstraint {
  const SumConstraint(super.value);

  @override
  String toString() => "$value";
}
