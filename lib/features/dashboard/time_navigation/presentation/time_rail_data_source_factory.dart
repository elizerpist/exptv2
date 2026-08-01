import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';

abstract final class TimeRailDataSourceFactory {
  static CenteredCarouselDataSource<int> forPlane({
    required TimePlane plane,
    required int yearAnchor,
    required YearMonth monthCursor,
  }) {
    return switch (plane) {
      TimePlane.sum => YearCarouselDataSource(anchorYear: yearAnchor),
      TimePlane.year => CyclicCarouselDataSource<int>(
        List<int>.generate(12, (index) => index + 1, growable: false),
      ),
      TimePlane.month => CyclicCarouselDataSource<int>(
        List<int>.generate(
          monthCursor.daysInMonth,
          (index) => index + 1,
          growable: false,
        ),
      ),
    };
  }

  static int logicalIndexForValue({
    required TimePlane plane,
    required int value,
    required int yearAnchor,
  }) {
    return switch (plane) {
      TimePlane.sum => value - yearAnchor,
      TimePlane.year || TimePlane.month => value - 1,
    };
  }

  static int valueForLogicalIndex({
    required TimePlane plane,
    required int logicalIndex,
    required int yearAnchor,
    required YearMonth monthCursor,
  }) {
    return switch (plane) {
      TimePlane.sum => yearAnchor + logicalIndex,
      TimePlane.year => _positiveModulo(logicalIndex, 12) + 1,
      TimePlane.month =>
        _positiveModulo(logicalIndex, monthCursor.daysInMonth) + 1,
    };
  }

  static int _positiveModulo(int value, int modulus) {
    return ((value % modulus) + modulus) % modulus;
  }
}
