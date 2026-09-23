import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
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
}
