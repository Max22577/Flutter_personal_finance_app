enum FilterOperator {
  isGreaterThanOrEqualTo,
  isLessThanOrEqualTo,
  isEqualTo,
}

class FieldFilter {
  final String field;
  final FilterOperator operator;
  final Object? value;

  FieldFilter(this.field, this.operator, this.value);
}

class OrderByOption {
  final String field;
  final bool descending;

  OrderByOption(this.field, {this.descending = false});
}