import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
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
              child: ValueListenableBuilder<MindYearHeatmapFrame?>(
                valueListenable: frameListenable,
                builder: (context, frame, _) {
                  final days =
                      frame?.month(month) ?? const <MindYearHeatmapDay>[];
                  return GridView.builder(
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                    itemCount: days.length,
                    itemBuilder: (context, index) =>
                        MindYearHeatmapDayTile(day: days[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A square, paint-only local-day cell. It deliberately has no date header or
/// interaction owner in this first annual overview.
final class MindYearHeatmapDayTile extends StatelessWidget {
  const MindYearHeatmapDayTile({super.key, required this.day});

  final MindYearHeatmapDay day;

  Color get color => switch (day.paletteIntensity) {
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
  Widget build(BuildContext context) => Semantics(
    label: 'heatmap:${day.date.isoString}:${day.kind.name}:${day.total ?? 0}',
    child: DecoratedBox(
      key: ValueKey('mind-year-heatmap-day-${day.date.isoString}'),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    ),
  );
}
