class BudgetBarGeometry {
  const BudgetBarGeometry._();

  static const barCenterY = 112.0;
  static const barHorizontalInset = 40.0;
  static const barHeight = 54.0 * 0.80;
  static const frameHeight = barHeight * 1.20;
  static const overhang = (frameHeight - barHeight) / 2;
  static const barTop = barCenterY - barHeight / 2;
  static const frameTop = barCenterY - frameHeight / 2;
  static const frameHorizontalInset = barHorizontalInset - overhang;
  static const radius = barHeight / 2;
  static const frameRadius = frameHeight / 2;

  static double minVisibleWidth(double height) => height * 1.20;

  static double visibleWidth({
    required double availableWidth,
    required double height,
    required double ratio,
  }) {
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    final minWidth = minVisibleWidth(
      height,
    ).clamp(0.0, availableWidth).toDouble();
    return (availableWidth * clampedRatio)
        .clamp(minWidth, availableWidth)
        .toDouble();
  }
}
