import 'package:flutter/material.dart';

import '../../../../app/shell/bnb03_bottom_navigation.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/design/fluvi_surface_fill.dart';
import '../../application/transaction_direction_controller.dart';
import 'fluvi_brand_mark.dart';

enum FluviBrandFillTarget { logo, background, bottomNavigation }

typedef FluviBrandAppearanceChanged =
    void Function(
      FluviBrandSurfaceAppearance appearance, {
      required bool persist,
    });

/// The compact three-target adaptation of the approved mark editor.
/// Choosing a swatch is intentionally separate from applying it: the target
/// preview is the explicit apply surface, so accidental palette browsing never
/// overwrites an already personalised logo or app surface.
Future<void> showFluviBrandEditorSheet({
  required BuildContext context,
  required FluviBrandSurfaceAppearance appearance,
  required FluviBrandAppearanceChanged onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _FluviBrandEditorSheet(appearance: appearance, onChanged: onChanged),
);

final class _FluviBrandEditorSheet extends StatefulWidget {
  const _FluviBrandEditorSheet({
    required this.appearance,
    required this.onChanged,
  });

  final FluviBrandSurfaceAppearance appearance;
  final FluviBrandAppearanceChanged onChanged;

  @override
  State<_FluviBrandEditorSheet> createState() => _FluviBrandEditorSheetState();
}

final class _FluviBrandEditorSheetState extends State<_FluviBrandEditorSheet> {
  late FluviBrandSurfaceAppearance _appearance = widget.appearance;
  late _BrandPaletteChoice _selected = _categoryChoice('color_08');
  FluviBrandFillTarget _target = FluviBrandFillTarget.logo;

  void _updateAppearance(
    FluviBrandSurfaceAppearance next, {
    bool persist = true,
  }) {
    setState(() => _appearance = next);
    widget.onChanged(next, persist: persist);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      key: const ValueKey('fluvi-brand-editor-sheet'),
      margin: const EdgeInsets.only(top: 72),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            offset: const Offset(0, -10),
            blurRadius: 30,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF536078).withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _BrandTargetSelector(
              value: _target,
              onChanged: (value) => setState(() => _target = value),
            ),
            const SizedBox(height: 14),
            SizedBox(
              key: const ValueKey('fluvi-brand-editor-preview'),
              height: 178,
              child: Center(child: _buildTargetPreview()),
            ),
            const SizedBox(height: 14),
            _SwatchWrap(
              choices: _lightPalette,
              selectedId: _selected.id,
              prefix: 'light',
              onSelected: _select,
            ),
            const SizedBox(height: 10),
            _SwatchWrap(
              choices: _appPalette,
              selectedId: _selected.id,
              prefix: 'app',
              onSelected: _select,
            ),
            const SizedBox(height: 10),
            _SwatchWrap(
              choices: <_BrandPaletteChoice>[
                for (final token in CategoryColorCatalog.all)
                  _categoryChoice(token.id),
              ],
              selectedId: _selected.id,
              prefix: 'category',
              onSelected: _select,
            ),
            const SizedBox(height: 16),
            for (
              var index = 0;
              index < _appearance.customSlots.length;
              index++
            ) ...[
              _CustomGradientSlotEditor(
                key: ValueKey('fluvi-brand-editor-custom-slot-$index'),
                slotIndex: index,
                slot: _appearance.customSlots[index],
                selectedFill: () => _selected.fill,
                selected: _selected.id == 'custom-$index',
                onSelect: () => _select(
                  _BrandPaletteChoice(
                    id: 'custom-$index',
                    fill: _appearance.customSlots[index],
                  ),
                ),
                onChanged: (fill, {required bool persist}) {
                  final next = _appearance.withCustomSlot(index, fill);
                  _updateAppearance(next, persist: persist);
                  if (_selected.id == 'custom-$index') {
                    setState(
                      () => _selected = _BrandPaletteChoice(
                        id: 'custom-$index',
                        fill: fill,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );

  void _select(_BrandPaletteChoice choice) =>
      setState(() => _selected = choice);

  Widget _buildTargetPreview() => switch (_target) {
    FluviBrandFillTarget.logo => _LogoTargetPreview(
      appearance: _appearance,
      onArcTap: _applyToArc,
    ),
    FluviBrandFillTarget.background => _SurfaceTargetPreview(
      key: const ValueKey('fluvi-brand-background-preview'),
      label: 'Koppints a háttér alkalmazásához',
      fill: _appearance.pageBackground,
      onTap: () => _applyToSurface(FluviBrandFillTarget.background),
    ),
    FluviBrandFillTarget.bottomNavigation => _BottomNavigationTargetPreview(
      fill: _appearance.bottomNavigation,
      onTap: () => _applyToSurface(FluviBrandFillTarget.bottomNavigation),
    ),
  };

  void _applyToArc(_FluviBrandArc arc) {
    final next = switch (arc) {
      _FluviBrandArc.top => _appearance.copyWith(logoTop: _selected.fill),
      _FluviBrandArc.bottom => _appearance.copyWith(logoBottom: _selected.fill),
    };
    _updateAppearance(next);
  }

  void _applyToSurface(FluviBrandFillTarget target) {
    final next = switch (target) {
      FluviBrandFillTarget.background => _appearance.copyWith(
        pageBackground: _selected.fill,
      ),
      FluviBrandFillTarget.bottomNavigation => _appearance.copyWith(
        bottomNavigation: _selected.fill,
      ),
      FluviBrandFillTarget.logo => _appearance,
    };
    _updateAppearance(next);
  }
}

enum _FluviBrandArc { top, bottom }

final class _BrandTargetSelector extends StatelessWidget {
  const _BrandTargetSelector({required this.value, required this.onChanged});

  final FluviBrandFillTarget value;
  final ValueChanged<FluviBrandFillTarget> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFECEEF7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: <Widget>[
        for (final target in FluviBrandFillTarget.values)
          Expanded(
            child: _BrandTargetOption(
              target: target,
              selected: target == value,
              onTap: () => onChanged(target),
            ),
          ),
      ],
    ),
  );
}

final class _BrandTargetOption extends StatelessWidget {
  const _BrandTargetOption({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final FluviBrandFillTarget target;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (target) {
    FluviBrandFillTarget.logo => 'Logó',
    FluviBrandFillTarget.background => 'Háttér',
    FluviBrandFillTarget.bottomNavigation => 'Bottom nav',
  };

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: _label,
    child: Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: ValueKey('fluvi-brand-target-${target.name}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            _label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF19264D)
                  : const Color(0xFF718096),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _LogoTargetPreview extends StatelessWidget {
  const _LogoTargetPreview({required this.appearance, required this.onArcTap});

  final FluviBrandSurfaceAppearance appearance;
  final ValueChanged<_FluviBrandArc> onArcTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FluviBrandMark(
            key: const ValueKey('fluvi-brand-editor-mark-preview'),
            appearance: appearance,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
          Positioned(
            left: constraints.maxWidth * .22,
            right: constraints.maxWidth * .12,
            top: constraints.maxHeight * .12,
            height: constraints.maxHeight * .34,
            child: _ArcApplyButton(arc: _FluviBrandArc.top, onTap: onArcTap),
          ),
          Positioned(
            left: constraints.maxWidth * .22,
            right: constraints.maxWidth * .28,
            top: constraints.maxHeight * .46,
            height: constraints.maxHeight * .40,
            child: _ArcApplyButton(arc: _FluviBrandArc.bottom, onTap: onArcTap),
          ),
        ],
      ),
    ),
  );
}

final class _ArcApplyButton extends StatelessWidget {
  const _ArcApplyButton({required this.arc, required this.onTap});

  final _FluviBrandArc arc;
  final ValueChanged<_FluviBrandArc> onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: arc == _FluviBrandArc.top
        ? 'Kitöltés alkalmazása a logó felső ívére'
        : 'Kitöltés alkalmazása a logó alsó ívére',
    child: GestureDetector(
      key: ValueKey('fluvi-brand-apply-logo-${arc.name}'),
      behavior: HitTestBehavior.translucent,
      onTap: () => onTap(arc),
      child: const ColoredBox(color: Colors.transparent),
    ),
  );
}

final class _SurfaceTargetPreview extends StatelessWidget {
  const _SurfaceTargetPreview({
    super.key,
    required this.label,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final FluviSurfaceFill fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: fill.gradient()),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: _foregroundFor(fill),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _BottomNavigationTargetPreview extends StatelessWidget {
  const _BottomNavigationTargetPreview({
    required this.fill,
    required this.onTap,
  });

  final FluviSurfaceFill fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Kitöltés alkalmazása a bottom navra',
    child: GestureDetector(
      key: const ValueKey('fluvi-brand-bottom-navigation-preview'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 344,
            child: Bnb03BottomNavigation(
              selected: Bnb03Item.home,
              onChanged: (_) {},
              transactionDirection: TransactionDirection.income,
              bottomNavigationFill: fill,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _SwatchWrap extends StatelessWidget {
  const _SwatchWrap({
    required this.choices,
    required this.selectedId,
    required this.prefix,
    required this.onSelected,
  });

  final List<_BrandPaletteChoice> choices;
  final String selectedId;
  final String prefix;
  final ValueChanged<_BrandPaletteChoice> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final choice in choices)
        _BrandSwatchButton(
          key: ValueKey('fluvi-brand-palette-$prefix-${choice.id}'),
          fill: choice.fill,
          selected: selectedId == choice.id,
          onTap: () => onSelected(choice),
        ),
    ],
  );
}

final class _BrandSwatchButton extends StatelessWidget {
  const _BrandSwatchButton({
    super.key,
    required this.fill,
    required this.selected,
    required this.onTap,
  });

  final FluviSurfaceFill fill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Színminta',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: fill.gradient(),
          border: Border.all(
            color: selected ? const Color(0xFF14213A) : Colors.white,
            width: selected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              offset: const Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    ),
  );
}

final class _CustomGradientSlotEditor extends StatelessWidget {
  const _CustomGradientSlotEditor({
    super.key,
    required this.slotIndex,
    required this.slot,
    required this.selectedFill,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final int slotIndex;
  final FluviSurfaceFill slot;
  final ValueGetter<FluviSurfaceFill> selectedFill;
  final bool selected;
  final VoidCallback onSelect;
  final void Function(FluviSurfaceFill fill, {required bool persist}) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _BrandSwatchButton(fill: slot, selected: selected, onTap: onSelect),
      const SizedBox(width: 10),
      _EndpointButton(
        label: 'L',
        fill: FluviSurfaceFill.solid(slot.leftArgb),
        onTap: () => onChanged(
          slot.copyWith(leftArgb: selectedFill().leftArgb, clearMiddle: true),
          persist: true,
        ),
      ),
      const SizedBox(width: 8),
      _EndpointButton(
        label: 'R',
        fill: FluviSurfaceFill.solid(slot.rightArgb),
        onTap: () => onChanged(
          slot.copyWith(rightArgb: selectedFill().rightArgb, clearMiddle: true),
          persist: true,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Slider(
          key: ValueKey('fluvi-brand-custom-boundary-slider-$slotIndex'),
          value: slot.boundaryPercent,
          min: 0,
          max: 100,
          onChanged: (value) =>
              onChanged(slot.copyWith(boundaryPercent: value), persist: false),
          onChangeEnd: (value) =>
              onChanged(slot.copyWith(boundaryPercent: value), persist: true),
        ),
      ),
    ],
  );
}

final class _EndpointButton extends StatelessWidget {
  const _EndpointButton({
    required this.label,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final FluviSurfaceFill fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label == 'L' ? 'Bal végpont másolása' : 'Jobb végpont másolása',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: fill.gradient(),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF14213A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

@immutable
final class _BrandPaletteChoice {
  const _BrandPaletteChoice({required this.id, required this.fill});
  _BrandPaletteChoice.solid(String id, int color)
    : this(id: id, fill: FluviSurfaceFill.solid(color));

  final String id;
  final FluviSurfaceFill fill;
}

_BrandPaletteChoice _categoryChoice(String id) {
  final token = CategoryColorCatalog.resolve(id);
  return _BrandPaletteChoice(
    id: id,
    fill: FluviSurfaceFill(
      leftArgb: token.colorA.toARGB32(),
      middleArgb: token.middleColor.toARGB32(),
      rightArgb: token.colorB.toARGB32(),
      boundaryPercent: 52,
    ),
  );
}

final _lightPalette = <_BrandPaletteChoice>[
  _BrandPaletteChoice.solid('D1', 0xFFFFFFFF),
  _BrandPaletteChoice.solid('N5', 0xFFFCFCFD),
  _BrandPaletteChoice.solid('O5', 0xFFFAFAFA),
  _BrandPaletteChoice.solid('E1', 0xFFF8FAFC),
  _BrandPaletteChoice.solid('P5', 0xFFF7F8FB),
  _BrandPaletteChoice.solid('A6', 0xFFF4F6F8),
  _BrandPaletteChoice.solid('F1', 0xFFF1F5F9),
  _BrandPaletteChoice.solid('B6', 0xFFEEF2F6),
  _BrandPaletteChoice.solid('N3', 0xFFF4F0E8),
];

final _appPalette = <_BrandPaletteChoice>[
  _BrandPaletteChoice.solid('white', 0xFFFFFFFF),
  _BrandPaletteChoice.solid('gray50', 0xFFF8FAFC),
  _BrandPaletteChoice.solid('gray100', 0xFFF1F5F9),
  _BrandPaletteChoice.solid('gray200', 0xFFE2E8F0),
  _BrandPaletteChoice.solid('gray300', 0xFFCBD5E1),
  _BrandPaletteChoice.solid('gray400', 0xFF94A3B8),
  _BrandPaletteChoice.solid('gray500', 0xFF64748B),
  _BrandPaletteChoice.solid('gray600', 0xFF475569),
  _BrandPaletteChoice.solid('gray700', 0xFF334155),
  _BrandPaletteChoice.solid('gray800', 0xFF1E293B),
  _BrandPaletteChoice.solid('gray900', 0xFF0F172A),
  _BrandPaletteChoice.solid('primary', 0xFF06B6D4),
  _BrandPaletteChoice.solid('primaryDark', 0xFF0891B2),
  _BrandPaletteChoice.solid('primaryLight', 0xFF67E8F9),
  _BrandPaletteChoice.solid('income', 0xFF22C55E),
  _BrandPaletteChoice.solid('expense', 0xFFEF4444),
];

Color _foregroundFor(FluviSurfaceFill fill) =>
    fill.effectiveMiddle.computeLuminance() > .48
    ? const Color(0xFF19264D)
    : Colors.white;
