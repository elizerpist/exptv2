import 'package:flutter/widgets.dart';

typedef CenteredCarouselPositionAttached =
    void Function(ScrollPosition position, int attachedPositionCount);

typedef CenteredCarouselActivityChanged =
    void Function(
      ScrollActivity? previous,
      ScrollActivity next,
      double pixels,
      double velocity,
    );

/// Owns only the raw initial offset of a centered carousel viewport.
///
/// Cyclic anchor pixels are not user state. Disabling PageStorage prevents a
/// stale raw offset from overriding the logical anchor when the viewport is
/// attached again.
class CenteredCarouselScrollController extends ScrollController {
  CenteredCarouselScrollController() : super(keepScrollOffset: false);

  double _initialPixels = 0;
  double? _nextAttachedInitialPixels;

  CenteredCarouselPositionAttached? onPositionAttached;
  CenteredCarouselActivityChanged? onActivityChanged;

  @override
  double get initialScrollOffset => _initialPixels;

  void configureInitialPixels(double pixels) {
    assert(!hasClients, 'Initial pixels can only change while detached.');
    _initialPixels = pixels;
  }

  /// Stages pixels for the next [ScrollPosition] lifecycle without moving the
  /// current position. This is only for a semantic datasource replacement.
  void prepareNextAttachedInitialPixels(double pixels) {
    _initialPixels = pixels;
    _nextAttachedInitialPixels = pixels;
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    onPositionAttached?.call(position, positions.length);
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    final initialPixels = _nextAttachedInitialPixels ?? _initialPixels;
    _nextAttachedInitialPixels = null;
    return _CenteredCarouselScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialPixels,
      keepScrollOffset: false,
      oldPosition: oldPosition,
      onActivityChanged: (previous, next, pixels, velocity) {
        onActivityChanged?.call(previous, next, pixels, velocity);
      },
    );
  }
}

class _CenteredCarouselScrollPosition extends ScrollPositionWithSingleContext {
  _CenteredCarouselScrollPosition({
    required super.physics,
    required super.context,
    required super.initialPixels,
    required super.keepScrollOffset,
    required super.oldPosition,
    required this.onActivityChanged,
  });

  final CenteredCarouselActivityChanged onActivityChanged;

  @override
  void beginActivity(ScrollActivity? newActivity) {
    final previous = activity;
    super.beginActivity(newActivity);
    if (newActivity != null) {
      onActivityChanged(
        previous,
        newActivity,
        hasPixels ? pixels : 0,
        newActivity.velocity,
      );
    }
  }
}
