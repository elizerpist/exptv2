import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/transactions/widgets/header_card/fast_info_card_surfaces.dart';
import '../../../transactions/state/fast_info_metrics_resolver.dart';
import '../../models/fast_info_card_catalog.dart';
import '../../models/fast_info_card_help.dart';
import '../../models/fast_info_config.dart';

enum FastInfoAnnotatedPreviewType { pill, box }

class FastInfoAnnotatedPreview extends StatelessWidget {
  const FastInfoAnnotatedPreview({
    super.key,
    required this.card,
    required this.metric,
    required this.type,
    required this.callouts,
  });

  final FastInfoCardDefinition card;
  final FastInfoMetricResult? metric;
  final FastInfoAnnotatedPreviewType type;
  final List<FastInfoHelpCallout> callouts;

  @override
  Widget build(BuildContext context) {
    final selectedCallouts = callouts.take(4).toList(growable: false);
    final isPill = type == FastInfoAnnotatedPreviewType.pill;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final previewHeight = isPill ? 38.0 : 136.0;
    final scaledPreviewHeight = previewHeight * textScale.clamp(1.0, 1.6);
    final previewWidth = isPill ? 320.0 : 156.0;
    final slot = FastInfoSlot.fromCard(
      card,
      isPill ? FastInfoSlotType.pill : FastInfoSlotType.box,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final diagramHeight =
            (isPill ? 176.0 : 244.0) + (scaledPreviewHeight - previewHeight);
        final maxPreviewWidth = width <= 32 ? width : width - 32;
        final minPreviewWidth = maxPreviewWidth < 120.0
            ? maxPreviewWidth
            : 120.0;
        final actualPreviewWidth = previewWidth.clamp(
          minPreviewWidth,
          maxPreviewWidth,
        );
        final previewRect = Rect.fromLTWH(
          (width - actualPreviewWidth) / 2,
          isPill ? 70 : 76,
          actualPreviewWidth,
          scaledPreviewHeight,
        );
        final labelRects = _labelRects(width, diagramHeight);

        return SizedBox(
          height: diagramHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: ValueKey('fastinfo-help-${type.name}-arrows-${card.id}'),
                  painter: _FastInfoCalloutArrowPainter(
                    callouts: selectedCallouts,
                    labelRects: labelRects,
                    previewRect: previewRect,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: previewRect,
                child: Center(
                  child: KeyedSubtree(
                    key: ValueKey('fastinfo-help-${type.name}-${card.id}'),
                    child: isPill
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 320,
                              height: scaledPreviewHeight,
                              child: FastInfoPillCard(
                                slot: slot,
                                metric: metric,
                                index: 0,
                                height: scaledPreviewHeight,
                                slotKeyPrefix:
                                    'fastinfo-help-${type.name}-${card.id}-surface',
                                dropKeyPrefix:
                                    'fastinfo-help-${type.name}-${card.id}-surface',
                                clearKeyPrefix:
                                    'fastinfo-help-${type.name}-${card.id}-surface-clear',
                              ),
                            ),
                          )
                        : FastInfoBoxCard(
                            slot: slot,
                            metric: metric,
                            index: 0,
                            height: scaledPreviewHeight,
                            slotKeyPrefix:
                                'fastinfo-help-${type.name}-${card.id}-surface',
                            dropKeyPrefix:
                                'fastinfo-help-${type.name}-${card.id}-surface',
                            clearKeyPrefix:
                                'fastinfo-help-${type.name}-${card.id}-surface-clear',
                          ),
                  ),
                ),
              ),
              for (var i = 0; i < selectedCallouts.length; i += 1)
                Positioned.fromRect(
                  rect: labelRects[i],
                  child: _CalloutLabel(selectedCallouts[i].label),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Rect> _labelRects(double width, double height) {
    final labelWidth = ((width - 36) / 2).clamp(118.0, 190.0);
    const labelHeight = 52.0;
    return <Rect>[
      Rect.fromLTWH(0, 0, labelWidth, labelHeight),
      Rect.fromLTWH(width - labelWidth, 0, labelWidth, labelHeight),
      Rect.fromLTWH(0, height - labelHeight, labelWidth, labelHeight),
      Rect.fromLTWH(
        width - labelWidth,
        height - labelHeight,
        labelWidth,
        labelHeight,
      ),
    ];
  }
}

class _CalloutLabel extends StatelessWidget {
  const _CalloutLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray800,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _FastInfoCalloutArrowPainter extends CustomPainter {
  const _FastInfoCalloutArrowPainter({
    required this.callouts,
    required this.labelRects,
    required this.previewRect,
  });

  final List<FastInfoHelpCallout> callouts;
  final List<Rect> labelRects;
  final Rect previewRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (var i = 0; i < callouts.length && i < labelRects.length; i += 1) {
      final start = labelRects[i].center;
      final target = _targetFor(callouts[i].anchor);
      canvas.drawLine(start, target, paint);
      final direction = start - target;
      final length = direction.distance == 0 ? 1.0 : direction.distance;
      final unit = direction / length;
      final normal = Offset(-unit.dy, unit.dx);
      final path = Path()
        ..moveTo(target.dx, target.dy)
        ..lineTo(
          target.dx + unit.dx * 8 + normal.dx * 4,
          target.dy + unit.dy * 8 + normal.dy * 4,
        )
        ..lineTo(
          target.dx + unit.dx * 8 - normal.dx * 4,
          target.dy + unit.dy * 8 - normal.dy * 4,
        )
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  Offset _targetFor(FastInfoHelpAnchor anchor) {
    final normalized = _anchorOffsets[anchor] ?? const Offset(.5, .5);
    return Offset(
      previewRect.left + previewRect.width * normalized.dx,
      previewRect.top + previewRect.height * normalized.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _FastInfoCalloutArrowPainter oldDelegate) {
    return true;
  }
}

const _anchorOffsets = <FastInfoHelpAnchor, Offset>{
  FastInfoHelpAnchor.pillValue: Offset(.42, .50),
  FastInfoHelpAnchor.pillTrend: Offset(.82, .50),
  FastInfoHelpAnchor.title: Offset(.18, .12),
  FastInfoHelpAnchor.primaryValue: Offset(.28, .28),
  FastInfoHelpAnchor.secondaryValues: Offset(.32, .50),
  FastInfoHelpAnchor.avatar: Offset(.13, .82),
  FastInfoHelpAnchor.trend: Offset(.86, .82),
  FastInfoHelpAnchor.visual: Offset(.58, .82),
};
