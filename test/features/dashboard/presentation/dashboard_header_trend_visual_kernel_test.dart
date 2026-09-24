import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';

void main() {
  test(
    'BALANCE-HEADER-DOMAIN RED: actual two-month and two-year domains both fill the fixed Mind-width plot',
    () {
      DashboardHeaderTrendTemporalProjection projectionFor(
        int start,
        int end,
      ) => DashboardHeaderTrendTemporalProjection(
        startInclusiveTemporalCoordinate: start,
        endInclusiveTemporalCoordinate: end,
      );

      for (final domain in <({int start, int end})>[
        (start: 20000 * 1440, end: 20061 * 1440),
        (start: 19000 * 1440, end: 19730 * 1440),
      ]) {
        final projection = projectionFor(domain.start, domain.end);
        expect(
          projection.plotXForCoordinate(
            domain.start,
            DashboardHeaderTrendChartStyle.plotWidth,
          ),
          0,
        );
        expect(
          projection.plotXForCoordinate(
            domain.end,
            DashboardHeaderTrendChartStyle.plotWidth,
          ),
          DashboardHeaderTrendChartStyle.plotWidth,
        );
      }
      expect(DashboardHeaderTrendChartStyle.plotWidth, 346);
      expect(DashboardHeaderTrendChartStyle.plotHeight, 60);
    },
  );

  test(
    'BALANCE-HEADER-PARITY RED: the shared trend kernel preserves Mind reference measurements and truthful one-point geometry',
    () {
      final onePoint = DashboardHeaderTrendSeries(
        startInclusiveTemporalCoordinate: 123,
        endInclusiveTemporalCoordinate: 123,
        points: const <DashboardHeaderTrendPoint>[
          DashboardHeaderTrendPoint(temporalCoordinate: 123, value: 600000),
        ],
      );
      final painter = DashboardHeaderTrendPainter(
        series: onePoint,
        minimumValue: 600000,
        maximumValue: 600000,
      );
      const size = Size(
        DashboardHeaderTrendChartStyle.plotWidth,
        DashboardHeaderTrendChartStyle.plotHeight,
      );
      const projection = DashboardHeaderTrendTemporalProjection(
        startInclusiveTemporalCoordinate: 123,
        endInclusiveTemporalCoordinate: 123,
      );
      final point = painter.pointOffsetAt(0, size, projection);

      expect(DashboardHeaderTrendChartStyle.detailLeft, 16);
      expect(DashboardHeaderTrendChartStyle.detailTop, 16);
      expect(DashboardHeaderTrendChartStyle.plotLeft, 16);
      expect(DashboardHeaderTrendChartStyle.plotTop, 48);
      expect(
        DashboardHeaderTrendChartStyle.lineColor,
        FluviVisualTokens.textOnAction,
      );
      expect(DashboardHeaderTrendChartStyle.lineWidth, 1.6);
      expect(DashboardHeaderTrendChartStyle.endpointRadius, 4.3);
      expect(DashboardHeaderTrendChartStyle.endpointStrokeWidth, 2);
      expect(DashboardHeaderTrendChartStyle.guideDash, 2);
      expect(DashboardHeaderTrendChartStyle.guideGap, 3);
      expect(DashboardHeaderTrendChartStyle.guideOpacity, .24);
      expect(DashboardHeaderTrendChartStyle.areaFadeStartOpacity, .30);
      expect(DashboardHeaderTrendChartStyle.areaFadeEndOpacity, 0);
      expect(point.dx, DashboardHeaderTrendChartStyle.plotWidth / 2);
      expect(point.dy, DashboardHeaderTrendChartStyle.plotHeight / 2);
    },
  );

  test('Header trend painter accepts a render-only foreground line colour', () {
    final series = DashboardHeaderTrendSeries(
      startInclusiveTemporalCoordinate: 0,
      endInclusiveTemporalCoordinate: 1,
      points: const <DashboardHeaderTrendPoint>[
        DashboardHeaderTrendPoint(temporalCoordinate: 0, value: 0),
        DashboardHeaderTrendPoint(temporalCoordinate: 1, value: 1),
      ],
    );
    final white = DashboardHeaderTrendPainter(
      series: series,
      minimumValue: 0,
      maximumValue: 1,
      lineColor: const Color(0xffffffff),
    );
    final black = DashboardHeaderTrendPainter(
      series: series,
      minimumValue: 0,
      maximumValue: 1,
      lineColor: const Color(0xff000000),
    );

    expect(white.lineColor, const Color(0xffffffff));
    expect(black.lineColor, const Color(0xff000000));
    expect(black.shouldRepaint(white), isTrue);
  });

  test(
    'HTY-04 RED: softened foreground changes only the existing line paint token',
    () {
      final series = DashboardHeaderTrendSeries(
        startInclusiveTemporalCoordinate: 10,
        endInclusiveTemporalCoordinate: 20,
        points: const <DashboardHeaderTrendPoint>[
          DashboardHeaderTrendPoint(temporalCoordinate: 10, value: -50),
          DashboardHeaderTrendPoint(temporalCoordinate: 20, value: 75),
        ],
      );
      final black = DashboardHeaderTrendPainter(
        series: series,
        minimumValue: -50,
        maximumValue: 75,
        lineColor: DashboardHeaderForegroundColor.black.color,
      );
      final softened = DashboardHeaderTrendPainter(
        series: series,
        minimumValue: -50,
        maximumValue: 75,
        lineColor: DashboardHeaderForegroundColor.softenedDark.color,
      );
      const plot = Size(
        DashboardHeaderTrendChartStyle.plotWidth,
        DashboardHeaderTrendChartStyle.plotHeight,
      );
      const projection = DashboardHeaderTrendTemporalProjection(
        startInclusiveTemporalCoordinate: 10,
        endInclusiveTemporalCoordinate: 20,
      );

      expect(softened.lineColor, const Color(0xd114213a));
      expect(
        DashboardHeaderTrendChartStyle.lineWidth,
        1.6,
        reason:
            'Foreground selection must not alter the shared stroke contract.',
      );
      expect(
        softened.pointOffsetAt(0, plot, projection),
        black.pointOffsetAt(0, plot, projection),
      );
      expect(
        softened.pointOffsetAt(1, plot, projection),
        black.pointOffsetAt(1, plot, projection),
      );
    },
  );

  test(
    'HIV-RED: the chart-underlay veil is independently colourized and optional',
    () {
      final painter = DashboardHeaderTrendPainter(
        series: DashboardHeaderTrendSeries(
          startInclusiveTemporalCoordinate: 0,
          endInclusiveTemporalCoordinate: 1,
          points: <DashboardHeaderTrendPoint>[
            DashboardHeaderTrendPoint(temporalCoordinate: 0, value: 1),
            DashboardHeaderTrendPoint(temporalCoordinate: 1, value: 2),
          ],
        ),
        minimumValue: 1,
        maximumValue: 2,
        lineColor: const Color(0xff000000),
        areaFadeColor: DashboardHeaderForegroundColor.softenedDark.color,
        showsAreaFade: false,
      );

      expect(painter.lineColor, const Color(0xff000000));
      expect(painter.areaFadeColor, const Color(0xd114213a));
      expect(painter.showsAreaFade, isFalse);
      final baseline = DashboardHeaderTrendPainter(
        series: painter.series,
        minimumValue: painter.minimumValue,
        maximumValue: painter.maximumValue,
        lineColor: painter.lineColor,
      );
      expect(
        painter.pointOffsetAt(
          1,
          const Size(
            DashboardHeaderTrendChartStyle.plotWidth,
            DashboardHeaderTrendChartStyle.plotHeight,
          ),
          const DashboardHeaderTrendTemporalProjection(
            startInclusiveTemporalCoordinate: 0,
            endInclusiveTemporalCoordinate: 1,
          ),
        ),
        baseline.pointOffsetAt(
          1,
          const Size(
            DashboardHeaderTrendChartStyle.plotWidth,
            DashboardHeaderTrendChartStyle.plotHeight,
          ),
          const DashboardHeaderTrendTemporalProjection(
            startInclusiveTemporalCoordinate: 0,
            endInclusiveTemporalCoordinate: 1,
          ),
        ),
      );
    },
  );
}
