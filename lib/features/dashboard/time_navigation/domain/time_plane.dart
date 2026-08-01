enum TimePlane {
  sum,
  year,
  month;

  bool isBroaderThan(TimePlane other) => index < other.index;

  bool get canMoveFiner => this != TimePlane.month;

  bool get canMoveBroader => this != TimePlane.sum;
}
