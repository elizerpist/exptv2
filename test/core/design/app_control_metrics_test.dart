import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/app_control_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';

void main() {
  test('B3M reference geometry is centralized', () {
    expect(B3mReferenceMetrics.compactTileHeight, 37);
    expect(B3mReferenceMetrics.compactTileRadius, 14);
    expect(B3mReferenceMetrics.carouselGap, 8);
    expect(B3mReferenceMetrics.horizontalPadding, 4);
    expect(B3mReferenceMetrics.verticalPadding, 0);
    expect(B3mReferenceMetrics.borderWidth, 1);
    expect(B3mReferenceMetrics.inactiveFontSize, 11);
    expect(B3mReferenceMetrics.activeFontSize, 15);
  });

  test('year tile height is ten percent below the direction control height', () {
    expect(AppSelectorMetrics.compactTileHeight, 37);
    expect(AppSelectorMetrics.yearTileHeight, closeTo(33.3, .0001));
  });

  test('B3M tile width and fixed slot preserve the five-item gap geometry', () {
    final tileWidth = B3mReferenceMetrics.compactTileWidthForViewport(378);

    expect(tileWidth, closeTo(69.2, .0001));
    expect(
      B3mReferenceMetrics.itemExtentForViewport(378),
      closeTo(77.2, .0001),
    );
    expect(
      5 * B3mReferenceMetrics.itemExtentForViewport(378) -
          B3mReferenceMetrics.carouselGap,
      closeTo(378, .0001),
    );
  });

  test('B3M typography keeps inactive and active rail sizes distinct', () {
    expect(
      FluviVisualTokens.railTextStyle.fontSize,
      B3mReferenceMetrics.inactiveFontSize,
    );
    expect(
      FluviVisualTokens.railActiveTextStyle.fontSize,
      B3mReferenceMetrics.activeFontSize,
    );
    expect(
      FluviVisualTokens.summaryLabelTextStyle.fontSize,
      FluviVisualTokens.bodyFontSize,
    );
  });
}
