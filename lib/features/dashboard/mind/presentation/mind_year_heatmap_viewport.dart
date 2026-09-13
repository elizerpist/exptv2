import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../time_navigation/domain/local_date.dart';
import '../domain/mind_year_heatmap_projection.dart';

/// The one scroll owner for the Mind annual MonthCard region.
///
/// The parent surface decides Year visibility. This viewport owns neither a
/// query nor a slider: it observes one already-published annual read model.
final class MindYearHeatmapViewport extends StatefulWidget {
  const MindYearHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.scrollController,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final ScrollController? scrollController;

  @override
  State<MindYearHeatmapViewport> createState() =>
      _MindYearHeatmapViewportState();
}

final class _MindYearHeatmapViewportState
    extends State<MindYearHeatmapViewport> {
  late bool _hasFrame;

  @override
  void initState() {
    super.initState();
    _hasFrame = widget.frameListenable.value != null;
    widget.frameListenable.addListener(_onFrameChanged);
  }

  @override
  void didUpdateWidget(covariant MindYearHeatmapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.frameListenable, widget.frameListenable)) {
      oldWidget.frameListenable.removeListener(_onFrameChanged);
      _hasFrame = widget.frameListenable.value != null;
      widget.frameListenable.addListener(_onFrameChanged);
    }
  }

  @override
  void dispose() {
    widget.frameListenable.removeListener(_onFrameChanged);
    super.dispose();
  }

  void _onFrameChanged() {
    final hasFrame = widget.frameListenable.value != null;
    if (hasFrame == _hasFrame || !mounted) return;
    setState(() => _hasFrame = hasFrame);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasFrame) {
      return const SizedBox(key: ValueKey('mind-year-heatmap-unavailable'));
    }
    return KeyedSubtree(
      key: const ValueKey('mind-year-heatmap-scroll'),
      child: GridView(
        key: const ValueKey('mind-year-heatmap-grid'),
        controller: widget.scrollController,
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .64,
        ),
        children: List<Widget>.generate(
          12,
          (index) => MindYearHeatmapMonthCard(
            month: index + 1,
            frameListenable: widget.frameListenable,
          ),
        ),
      ),
    );
  }
}

/// Stable MonthCard shell. Its title is static across amount-only previews;
/// only the bounded day-tile field listens to the live frame.
final class MindYearHeatmapMonthCard extends StatelessWidget {
  const MindYearHeatmapMonthCard({
    super.key,
    required this.month,
    required this.frameListenable,
  });

  final int month;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: ValueKey('mind-year-heatmap-month-$month'),
    decoration: const BoxDecoration(
      color: FluviVisualTokens.surfaceMuted,
      borderRadius: FluviVisualTokens.smallRadius,
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              DashboardTimeLabelFormatter.monthName(month),
              maxLines: 1,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RepaintBoundary(
              child: Semantics(
                label:
                    'Mind heatmap ${DashboardTimeLabelFormatter.monthName(month)}',
                readOnly: true,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: ValueKey('mind-year-heatmap-month-cells-$month'),
                    painter: MindYearHeatmapMonthPainter(
                      month: month,
                      frameListenable: frameListenable,
                    ),
                    isComplex: false,
                    willChange: true,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Paints one month's non-interactive local-day cells as a single dynamic
/// field. The existing frame listenable is the repaint authority, so an amount
/// preview does not rebuild per-day widgets, nested viewports, or semantics.
final class MindYearHeatmapMonthPainter extends CustomPainter {
  MindYearHeatmapMonthPainter({
    required this.month,
    required this.frameListenable,
  }) : super(repaint: frameListenable);

  static const _columnCount = 7;
  static const _gap = 2.0;
  static const _cornerRadius = Radius.circular(2);

  final int month;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;

  @visibleForTesting
  Color colorForDate(LocalDate date) {
    final frame = frameListenable.value;
    if (frame == null) throw StateError('Missing heatmap frame.');
    final day = frame
        .month(month)
        .firstWhere(
          (candidate) => candidate.date == date,
          orElse: () => throw StateError('Missing heatmap day $date.'),
        );
    return colorFor(day);
  }

  @visibleForTesting
  Color colorFor(MindYearHeatmapDay day) => switch (day.paletteIntensity) {
    MindYearHeatmapPaletteIntensity.empty => FluviVisualTokens.mindHeatmapEmpty,
    MindYearHeatmapPaletteIntensity.minimum =>
      FluviVisualTokens.mindHeatmapMinimum,
    MindYearHeatmapPaletteIntensity.interpolated =>
      FluviVisualTokens.mindHeatmapInterpolated(day.intensity),
    MindYearHeatmapPaletteIntensity.maximum =>
      FluviVisualTokens.mindHeatmapMaximum,
    MindYearHeatmapPaletteIntensity.equalRange =>
      FluviVisualTokens.mindHeatmapEqualRange,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final days = frameListenable.value?.month(month);
    if (days == null || days.isEmpty || size.width <= 0) return;
    final cellExtent = (size.width - (_columnCount - 1) * _gap) / _columnCount;
    if (cellExtent <= 0) return;
    final paint = Paint();
    for (var index = 0; index < days.length; index += 1) {
      final row = index ~/ _columnCount;
      final column = index % _columnCount;
      final offset = Offset(
        column * (cellExtent + _gap),
        row * (cellExtent + _gap),
      );
      paint.color = colorFor(days[index]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, cellExtent, cellExtent),
          _cornerRadius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindYearHeatmapMonthPainter oldDelegate) =>
      month != oldDelegate.month ||
      !identical(frameListenable, oldDelegate.frameListenable);
}
