import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../transactions/state/fast_info_metrics_resolver.dart';
import '../../../transactions/widgets/header_card/fast_info_card_surfaces.dart';
import '../../../transactions/widgets/slide_up_menu_card.dart';
import '../../models/fast_info_card_catalog.dart';
import '../../models/fast_info_card_help.dart';
import '../../models/fast_info_config.dart';
import 'fast_info_annotated_preview.dart';

Future<void> showFastInfoCardHelpSheet(
  BuildContext context, {
  required FastInfoCardDefinition card,
  required FastInfoMetricResult? metric,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'FastInfo magyarázat',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => Material(
      type: MaterialType.transparency,
      child: FastInfoCardHelpSheet(card: card, metric: metric),
    ),
  );
}

class FastInfoCardHelpSheet extends StatefulWidget {
  const FastInfoCardHelpSheet({
    super.key,
    required this.card,
    required this.metric,
  });

  final FastInfoCardDefinition card;
  final FastInfoMetricResult? metric;

  @override
  State<FastInfoCardHelpSheet> createState() => _FastInfoCardHelpSheetState();
}

class _FastInfoCardHelpSheetState extends State<FastInfoCardHelpSheet> {
  final _bodyDragExclusionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final metric = widget.metric;
    final help = fastInfoCardHelpForId(card.id);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;
    final panelHeight = MediaQuery.sizeOf(context).height * .92;
    return SlideUpMenuCard(
      cardKey: ValueKey('fastinfo-help-sheet-${card.id}'),
      debugLabel: 'FastInfoHelp:${card.id}',
      panelHeight: panelHeight,
      visible: true,
      deferEntryAnimation: true,
      dragExclusionKeys: [_bodyDragExclusionKey],
      onDismissed: () => Navigator.of(context).pop(),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _SheetHandle(key: ValueKey('fastinfo-help-drag-handle-${card.id}')),
            Expanded(
              child: KeyedSubtree(
                key: _bodyDragExclusionKey,
                child: SingleChildScrollView(
                  key: ValueKey('fastinfo-help-body-${card.id}'),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderPreview(card: card, metric: metric),
                      const SizedBox(height: 14),
                      Text(
                        card.title,
                        style: const TextStyle(
                          color: AppColors.gray900,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionTitle('Ez azt mutatja'),
                      const SizedBox(height: 6),
                      Text(
                        help.purpose,
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BodyText(help.details),
                      const SizedBox(height: 20),
                      _SectionTitle('Pill nézet'),
                      const SizedBox(height: 8),
                      FastInfoAnnotatedPreview(
                        card: card,
                        metric: metric,
                        type: FastInfoAnnotatedPreviewType.pill,
                        callouts: help.pillCallouts,
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle('Box nézet'),
                      const SizedBox(height: 8),
                      FastInfoAnnotatedPreview(
                        card: card,
                        metric: metric,
                        type: FastInfoAnnotatedPreviewType.box,
                        callouts: help.boxCallouts,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Így számol'),
                      const SizedBox(height: 6),
                      for (final item in help.calculation) _BodyBullet(item),
                      const SizedBox(height: 14),
                      _SectionTitle('Mit hasonlít?'),
                      const SizedBox(height: 6),
                      _BodyText(help.comparison),
                      const SizedBox(height: 14),
                      _SectionTitle('Ha nincs elég adat'),
                      const SizedBox(height: 6),
                      _BodyText(help.missingData),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _HeaderPreview extends StatelessWidget {
  const _HeaderPreview({required this.card, required this.metric});

  final FastInfoCardDefinition card;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final slot = FastInfoSlot.fromCard(card, FastInfoSlotType.box);
    return Center(
      child: SizedBox(
        key: ValueKey('fastinfo-help-card-preview-${card.id}'),
        width: 156,
        child: FastInfoBoxCard(
          slot: slot,
          metric: metric,
          index: 0,
          height: 136,
          slotKeyPrefix: 'fastinfo-help-card-preview-${card.id}-surface',
          dropKeyPrefix: 'fastinfo-help-card-preview-${card.id}-surface',
          clearKeyPrefix: 'fastinfo-help-card-preview-${card.id}-surface-clear',
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gray900,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gray700,
        fontSize: 13,
        height: 1.35,
      ),
    );
  }
}

class _BodyBullet extends StatelessWidget {
  const _BodyBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '- ',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          Expanded(child: _BodyText(text)),
        ],
      ),
    );
  }
}
