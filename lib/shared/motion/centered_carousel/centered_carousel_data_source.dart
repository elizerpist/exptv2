/// The lifecycle and indexing contract for a centered carousel's data.
enum CenteredCarouselDataMode { bounded, cyclic, generated }

abstract interface class CenteredCarouselDataSource<T> {
  const CenteredCarouselDataSource();

  CenteredCarouselDataMode get mode;

  T itemAtLogicalIndex(int logicalIndex);

  int? get finiteLength;
}

class BoundedCarouselDataSource<T> extends CenteredCarouselDataSource<T> {
  const BoundedCarouselDataSource(this.items);

  final List<T> items;

  @override
  CenteredCarouselDataMode get mode => CenteredCarouselDataMode.bounded;

  @override
  int? get finiteLength => items.length;

  @override
  T itemAtLogicalIndex(int logicalIndex) {
    if (logicalIndex < 0 || logicalIndex >= items.length) {
      throw RangeError.index(logicalIndex, items);
    }
    return items[logicalIndex];
  }
}

class CyclicCarouselDataSource<T> extends CenteredCarouselDataSource<T> {
  const CyclicCarouselDataSource(this.items);

  final List<T> items;

  @override
  CenteredCarouselDataMode get mode => CenteredCarouselDataMode.cyclic;

  @override
  int? get finiteLength => items.length;

  @override
  T itemAtLogicalIndex(int logicalIndex) {
    if (items.isEmpty) {
      throw StateError('Cyclic carousel cannot use an empty list.');
    }
    final normalized =
        ((logicalIndex % items.length) + items.length) % items.length;
    return items[normalized];
  }
}

class GeneratedCarouselDataSource<T> extends CenteredCarouselDataSource<T> {
  const GeneratedCarouselDataSource(this.builder);

  final T Function(int logicalIndex) builder;

  @override
  CenteredCarouselDataMode get mode => CenteredCarouselDataMode.generated;

  @override
  int? get finiteLength => null;

  @override
  T itemAtLogicalIndex(int logicalIndex) => builder(logicalIndex);
}

class YearCarouselDataSource extends GeneratedCarouselDataSource<int> {
  const YearCarouselDataSource({required this.anchorYear})
    : super(_yearAtIndex);

  final int anchorYear;

  static int _yearAtIndex(int logicalIndex) => logicalIndex;

  @override
  int itemAtLogicalIndex(int logicalIndex) => anchorYear + logicalIndex;
}
