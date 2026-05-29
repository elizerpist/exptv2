import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/transactions/widgets/header_card/fast_info_panel.dart';
import '../../models/fast_info_card_catalog.dart';
import '../../models/fast_info_config.dart';

class FastInfoOptionsPanel extends StatefulWidget {
  const FastInfoOptionsPanel({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final FastInfoConfig config;
  final ValueChanged<FastInfoConfig> onChanged;

  @override
  State<FastInfoOptionsPanel> createState() => _FastInfoOptionsPanelState();
}

class _FastInfoOptionsPanelState extends State<FastInfoOptionsPanel> {
  late FastInfoConfig _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.config;
  }

  @override
  void didUpdateWidget(covariant FastInfoOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) _draft = widget.config;
  }

  Set<String> get _assignedIds {
    return <String>{
      for (final slot in _draft.pills) if (slot != null) slot.id,
      for (final slot in _draft.boxes) if (slot != null) slot.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final freeCards = fastInfoCardCatalog
        .where((card) => !_assignedIds.contains(card.id))
        .toList(growable: false);

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: FastInfoPanel(
            config: _draft,
            backgroundColor: AppColors.gray100,
            onDropPillCard: (index, cardId) => _assign(FastInfoSlotType.pill, index, cardId),
            onDropBoxCard: (index, cardId) => _assign(FastInfoSlotType.box, index, cardId),
            onClearPillSlot: (index) => _clear(FastInfoSlotType.pill, index),
            onClearBoxSlot: (index) => _clear(FastInfoSlotType.box, index),
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: const ValueKey('fastinfo-card-pool'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
            ),
            itemCount: freeCards.length,
            itemBuilder: (context, index) => _PoolCard(card: freeCards[index]),
          ),
        ),
      ],
    );
  }

  void _assign(FastInfoSlotType type, int index, String cardId) {
    final card = fastInfoCardById(cardId);
    if (card == null) return;
    final pills = List<FastInfoSlot?>.from(_draft.pills);
    final boxes = List<FastInfoSlot?>.from(_draft.boxes);

    for (var i = 0; i < pills.length; i += 1) {
      if (pills[i]?.id == cardId) pills[i] = null;
    }
    for (var i = 0; i < boxes.length; i += 1) {
      if (boxes[i]?.id == cardId) boxes[i] = null;
    }

    if (type == FastInfoSlotType.pill) {
      pills[index] = FastInfoSlot.fromCard(card, FastInfoSlotType.pill);
    } else {
      boxes[index] = FastInfoSlot.fromCard(card, FastInfoSlotType.box);
    }
    _emit(FastInfoConfig(pills: pills, boxes: boxes));
  }

  void _clear(FastInfoSlotType type, int index) {
    final pills = List<FastInfoSlot?>.from(_draft.pills);
    final boxes = List<FastInfoSlot?>.from(_draft.boxes);
    if (type == FastInfoSlotType.pill) {
      pills[index] = null;
    } else {
      boxes[index] = null;
    }
    _emit(FastInfoConfig(pills: pills, boxes: boxes));
  }

  void _emit(FastInfoConfig config) {
    setState(() => _draft = config);
    widget.onChanged(config);
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.card});

  final FastInfoCardDefinition card;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      key: ValueKey('fastinfo-pool-card-${card.id}'),
      data: card.id,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 160, height: 70),
          child: _PoolCardSurface(card: card, elevated: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _PoolCardSurface(card: card),
      ),
      child: _PoolCardSurface(card: card),
    );
  }
}

class _PoolCardSurface extends StatelessWidget {
  const _PoolCardSurface({required this.card, this.elevated = false});

  final FastInfoCardDefinition card;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.18 : 0.08),
            offset: Offset(0, elevated ? 4 : 2),
            blurRadius: elevated ? 10 : 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.pillValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
