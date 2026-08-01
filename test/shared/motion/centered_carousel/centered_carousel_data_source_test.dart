import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_data_source.dart';

void main() {
  test('generated year source maps negative and positive logical indices', () {
    const source = YearCarouselDataSource(anchorYear: 2028);

    expect(source.mode, CenteredCarouselDataMode.generated);
    expect(source.finiteLength, isNull);
    expect(source.itemAtLogicalIndex(-3), 2025);
    expect(source.itemAtLogicalIndex(0), 2028);
    expect(source.itemAtLogicalIndex(4), 2032);
  });

  test('cyclic source normalizes both directions', () {
    const source = CyclicCarouselDataSource<String>(['a', 'b', 'c']);

    expect(source.itemAtLogicalIndex(-1), 'c');
    expect(source.itemAtLogicalIndex(0), 'a');
    expect(source.itemAtLogicalIndex(4), 'b');
  });
}
