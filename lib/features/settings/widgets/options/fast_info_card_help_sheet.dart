import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../transactions/state/fast_info_metrics_resolver.dart';
import '../../models/fast_info_card_catalog.dart';
import '../../models/fast_info_card_help.dart';
import 'fast_info_annotated_preview.dart';

Future<void> showFastInfoCardHelpSheet(
  BuildContext context, {
  required FastInfoCardDefinition card,
  required FastInfoMetricResult? metric,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.gray100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: .92,
      child: FastInfoCardHelpSheet(card: card, metric: metric),
    ),
  );
}

class FastInfoCardHelpSheet extends StatelessWidget {
  const FastInfoCardHelpSheet({
    super.key,
    required this.card,
    required this.metric,
  });

  final FastInfoCardDefinition card;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final help = fastInfoCardHelpForId(card.id);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;
    return Material(
      color: AppColors.gray100,
      child: SingleChildScrollView(
        key: ValueKey('fastinfo-help-sheet-${card.id}'),
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      color: AppColors.gray900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('fastinfo-help-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.gray600),
                  tooltip: 'Bezárás',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              help.purpose,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              help.details,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
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
            _SectionTitle('Számítás'),
            const SizedBox(height: 6),
            for (final item in help.calculation) _BodyBullet(item),
            const SizedBox(height: 14),
            _SectionTitle('Összehasonlítás'),
            const SizedBox(height: 6),
            _BodyText(help.comparison),
            const SizedBox(height: 14),
            _SectionTitle('Ha nincs elég adat'),
            const SizedBox(height: 6),
            _BodyText(help.missingData),
          ],
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
            '• ',
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
