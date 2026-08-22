import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import 'dashboard_header_budget_palette.dart';
import 'dashboard_header_portal_material_field.dart';
import 'dashboard_header_tap_wave.dart';
import 'dashboard_header_visual_engine.dart';

/// Pure bounded placement contract for the tuner.  The Header's expansion
/// geometry remains owned by [DashboardExpansionController]; this only uses
/// the already-resolved Header bottom edge to reserve visible space below it.
@immutable
final class DashboardHeaderVisualTunerPlacement {
  const DashboardHeaderVisualTunerPlacement({
    required this.top,
    required this.maxHeight,
  });

  final double top;
  final double maxHeight;

  static DashboardHeaderVisualTunerPlacement resolve({
    required double headerBottom,
    required double viewportHeight,
    required double safeBottom,
    double gap = 12,
  }) {
    final top = math.max(0.0, headerBottom + gap).toDouble();
    return DashboardHeaderVisualTunerPlacement(
      top: top,
      maxHeight: math.max(0, viewportHeight - top - safeBottom - gap),
    );
  }
}

/// Layer 4 Header action. This replaces the old global fullscreen action;
/// it is deliberately rendered above the Header gesture arbitration region.
final class DashboardHeaderVisualTunerButton extends StatelessWidget {
  const DashboardHeaderVisualTunerButton({super.key, required this.controller});

  final DashboardHeaderVisualController controller;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Header látványhangoló',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('dashboard-header-visual-tuner-button'),
        borderRadius: BorderRadius.circular(14),
        onTap: controller.toggleTuner,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: FluviVisualTokens.navigationInactiveIcon,
            size: 24,
          ),
        ),
      ),
    ),
  );
}

/// Development-only live control surface. It owns neither Header visual phase
/// nor Budget accounting state: all changes are routed to the dashboard
/// lifetime [DashboardHeaderVisualController].
final class DashboardHeaderVisualTuner extends StatelessWidget {
  const DashboardHeaderVisualTuner({super.key, required this.controller});

  final DashboardHeaderVisualController controller;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<DashboardHeaderVisualTuning>(
    valueListenable: controller.tuning,
    builder: (context, tuning, child) {
      final effect = DashboardHeaderEffectCatalog.effectFor(tuning.effect);
      final opacity = DashboardHeaderOpacityScale.valueAt(
        tuning.opacityScalePosition,
      );
      return Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FluviVisualTokens.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ListView(
            key: const ValueKey<String>('dashboard-header-visual-tuner-list'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Header látványhangoló',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>(
                      'dashboard-header-visual-tuner-close',
                    ),
                    tooltip: 'Bezárás',
                    onPressed: controller.closeTuner,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Set<DashboardHeaderTunerSection>>(
                valueListenable: controller.expandedTunerSections,
                builder: (context, expandedSections, child) => Column(
                  children: <Widget>[
                    _CollapsibleTunerSection(
                      key: const ValueKey<String>(
                        'dashboard-header-tuner-section-animation',
                      ),
                      title: 'Header animáció',
                      expanded: expandedSections.contains(
                        DashboardHeaderTunerSection.animation,
                      ),
                      onToggle: () => controller.toggleTunerSection(
                        DashboardHeaderTunerSection.animation,
                      ),
                      children: <Widget>[
                        _TunerSection(
                          title: 'Budget színablak',
                          children: <Widget>[
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-window-width-slider',
                              ),
                              label: 'Ablakszélesség',
                              valueLabel:
                                  '${tuning.budgetWindowWidthPercent.toStringAsFixed(0)}%',
                              min: 10,
                              max: 100,
                              divisions: 90,
                              value: tuning.budgetWindowWidthPercent,
                              onChanged: controller.setBudgetWindowWidthPercent,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-opacity-slider',
                              ),
                              label: 'Áttetszőség',
                              valueLabel:
                                  '${tuning.opacityScalePosition.toStringAsFixed(0)}% · ${opacity.toStringAsFixed(2)}',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.opacityScalePosition,
                              onChanged: controller.setOpacityScalePosition,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TunerSection(
                          title: 'Effekt',
                          children: <Widget>[
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Effekt',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<DashboardHeaderEffectId>(
                                  key: const ValueKey<String>(
                                    'dashboard-header-effect-selector',
                                  ),
                                  value: tuning.effect,
                                  isExpanded: true,
                                  items:
                                      <
                                        DropdownMenuItem<
                                          DashboardHeaderEffectId
                                        >
                                      >[
                                        for (final option
                                            in DashboardHeaderEffectCatalog
                                                .effects)
                                          DropdownMenuItem<
                                            DashboardHeaderEffectId
                                          >(
                                            value: option.id,
                                            child: Text(option.label),
                                          ),
                                      ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.selectEffect(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (effect.controls.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          _TunerSection(
                            title: 'Effekt paraméterek',
                            children: <Widget>[
                              for (final control in effect.controls)
                                _TunerSlider(
                                  key: ValueKey<String>(
                                    'dashboard-header-effect-control-${control.id}',
                                  ),
                                  label: control.label,
                                  valueLabel: _formatControlValue(
                                    tuning.settingsFor(effect.id)[control.id] ??
                                        control.defaultValue,
                                    control.step,
                                  ),
                                  min: control.min,
                                  max: control.max,
                                  divisions:
                                      ((control.max - control.min) /
                                              control.step)
                                          .round(),
                                  value:
                                      tuning.settingsFor(
                                        effect.id,
                                      )[control.id] ??
                                      control.defaultValue,
                                  onChanged: (value) => controller
                                      .setEffectControl(control.id, value),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        ValueListenableBuilder<int>(
                          valueListenable: controller.portalSettingsGeneration,
                          builder: (context, generation, child) => Column(
                            children: <Widget>[
                              _PortalTunerChannelSection(
                                controller: controller,
                                channel:
                                    DashboardHeaderPortalChannel.innerMotion,
                              ),
                              const SizedBox(height: 14),
                              _PortalTunerChannelSection(
                                controller: controller,
                                channel: DashboardHeaderPortalChannel
                                    .backgroundMorph,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _TunerSection(
                          title: 'Pulzus',
                          children: <Widget>[
                            Text(
                              'A Color Lab 1560 ms-os, lineárisan elhaló fényimpulzusa.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              key: const ValueKey<String>(
                                'dashboard-header-pulse-trigger',
                              ),
                              onPressed: controller.triggerPulse,
                              icon: const Icon(Icons.bolt_rounded),
                              label: const Text('Pulzus indítása'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ValueListenableBuilder<DashboardHeaderTapWaveTuning>(
                          valueListenable: controller.tapWaveTuning,
                          builder: (context, tapWave, child) => _TunerSection(
                            title: 'Header tap wave',
                            children: <Widget>[
                              Text(
                                'Color Lab rózsaszín/magenta, több rétegű érintési hullám.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              for (final control
                                  in DashboardHeaderTapWaveCatalog.controls)
                                _TunerSlider(
                                  key: ValueKey<String>(
                                    'dashboard-header-tap-wave-control-${control.id}',
                                  ),
                                  label: control.label,
                                  valueLabel: _formatTapWaveControlValue(
                                    tapWave.valueFor(control.id),
                                    control,
                                  ),
                                  min: control.min,
                                  max: control.max,
                                  divisions:
                                      ((control.max - control.min) /
                                              control.step)
                                          .round(),
                                  value: tapWave.valueFor(control.id),
                                  onChanged: (value) => controller
                                      .setTapWaveControl(control.id, value),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CollapsibleTunerSection(
                      key: const ValueKey<String>(
                        'dashboard-header-tuner-section-category-scales',
                      ),
                      title: 'Kategória színskálák',
                      expanded: expandedSections.contains(
                        DashboardHeaderTunerSection.categoryColorScales,
                      ),
                      onToggle: () => controller.toggleTunerSection(
                        DashboardHeaderTunerSection.categoryColorScales,
                      ),
                      children: <Widget>[
                        _BudgetCategoryPalettePreview(controller: controller),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A top-level section keeps the bounded sheet compact without creating a
/// second control surface. Its state is supplied by the dashboard-lifetime
/// Header controller, never by a ticker or local `setState`.
final class _CollapsibleTunerSection extends StatelessWidget {
  const _CollapsibleTunerSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluviVisualTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: expanded,
          label: title,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: FluviVisualTokens.navigationInactiveIcon,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    ),
  );
}

/// The complete 21-colour palette catalogue. It reads only the cached pure
/// palette domain, so expanding it cannot ask Budget presentation/domain state
/// to rebuild or perform any I/O.
final class _BudgetCategoryPalettePreview extends StatelessWidget {
  const _BudgetCategoryPalettePreview({required this.controller});

  final DashboardHeaderVisualController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Minden kanonikus kategóriaszín saját, tízslotos Header-skálája.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder<BudgetHeaderDebugSnapshot?>(
        valueListenable: controller.budgetDebugSnapshot,
        builder: (context, snapshot, child) =>
            _ActiveBudgetPaletteSummary(snapshot: snapshot),
      ),
      const SizedBox(height: 10),
      for (final palette in BudgetHeaderPaletteCatalog.allCategoryPalettes)
        _BudgetPaletteRow(palette: palette),
    ],
  );
}

final class _ActiveBudgetPaletteSummary extends StatelessWidget {
  const _ActiveBudgetPaletteSummary({required this.snapshot});

  final BudgetHeaderDebugSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final value = snapshot;
    if (value == null) {
      return const Text('Aktív Budget-cél még nincs kötve.');
    }
    final mode = value.paletteMode == BudgetHeaderPaletteMode.paletteWindow
        ? 'limit-skála'
        : 'kanonikus gradiens';
    return Text(
      'Aktív: ${value.colorId} · ${value.palette.id} · $mode\n'
      'ablak ${value.windowLeftPercent?.toStringAsFixed(1) ?? '-'}–'
      '${value.windowRightPercent?.toStringAsFixed(1) ?? '-'}% · '
      'A #${value.colorA.toARGB32().toRadixString(16).padLeft(8, '0')} · '
      'B #${value.colorB.toARGB32().toRadixString(16).padLeft(8, '0')}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

final class _BudgetPaletteRow extends StatelessWidget {
  const _BudgetPaletteRow({required this.palette});

  final BudgetHeaderPalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey<String>('dashboard-header-palette-row-${palette.id}'),
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: palette.canonicalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
            Text(palette.id, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 6),
            Text(
              'azonosság: ${BudgetHeaderPalette.canonicalSlotIndex + 1}. slot',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            for (final (index, color) in palette.slots.indexed)
              Expanded(
                child: Container(
                  key: ValueKey<String>(
                    'dashboard-header-palette-slot-${palette.id}-$index',
                  ),
                  height: 18,
                  margin: EdgeInsets.only(
                    right: index == palette.slots.length - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: index == BudgetHeaderPalette.canonicalSlotIndex
                          ? Colors.white
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// Each source selector gets its own tuner section and controller state. The
/// shared material catalog provides the option order/control metadata; neither
/// section rebuilds on the animation clock because it listens only to semantic
/// Portal configuration changes.
final class _PortalTunerChannelSection extends StatelessWidget {
  const _PortalTunerChannelSection({
    required this.controller,
    required this.channel,
  });

  final DashboardHeaderVisualController controller;
  final DashboardHeaderPortalChannel channel;

  @override
  Widget build(BuildContext context) {
    final inner = channel == DashboardHeaderPortalChannel.innerMotion;
    final state = inner
        ? controller.portalInnerMotion
        : controller.portalBackgroundMorph;
    final prefix = inner ? 'inner' : 'background';
    final effect = DashboardHeaderPortalMaterialCatalog.effectFor(state.effect);
    return _TunerSection(
      title: inner ? 'PORTÁL BELSŐ MOZGÁS' : 'Portal háttér-morph',
      children: <Widget>[
        Row(
          children: <Widget>[
            OutlinedButton(
              key: ValueKey<String>('dashboard-header-portal-$prefix-enabled'),
              onPressed: () =>
                  controller.setPortalEnabled(channel, !state.enabled),
              child: Text(state.enabled ? 'BE' : 'KI'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Effekt'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DashboardHeaderPortalMaterialEffectId>(
                    key: ValueKey<String>(
                      'dashboard-header-portal-$prefix-selector',
                    ),
                    value: state.effect,
                    isExpanded: true,
                    items:
                        <
                          DropdownMenuItem<
                            DashboardHeaderPortalMaterialEffectId
                          >
                        >[
                          for (final option
                              in DashboardHeaderPortalMaterialCatalog.effects)
                            DropdownMenuItem<
                              DashboardHeaderPortalMaterialEffectId
                            >(value: option.id, child: Text(option.label)),
                        ],
                    onChanged: state.enabled
                        ? (value) {
                            if (value != null) {
                              controller.selectPortalEffect(channel, value);
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: ValueKey<String>('dashboard-header-portal-$prefix-reset'),
            onPressed: state.enabled
                ? () => controller.resetActivePortalEffect(channel)
                : null,
            child: const Text('Aktív mód reset'),
          ),
        ),
        if (inner) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Rotáció · ${state.rotationEnabled ? 'BE' : 'KI'}'),
              ),
              Switch(
                key: const ValueKey<String>(
                  'dashboard-header-portal-inner-rotation',
                ),
                value: state.rotationEnabled,
                onChanged: state.enabled
                    ? (enabled) =>
                          controller.setPortalInnerRotation(enabled: enabled)
                    : null,
              ),
            ],
          ),
          _TunerSlider(
            key: const ValueKey<String>(
              'dashboard-header-portal-inner-rotation-speed',
            ),
            label: 'Rotáció sebesség',
            valueLabel: '${state.rotationSpeed.toStringAsFixed(0)}%',
            min: 0,
            max: 100,
            divisions: 100,
            value: state.rotationSpeed,
            onChanged: state.enabled
                ? (value) => controller.setPortalInnerRotation(speed: value)
                : null,
          ),
        ] else ...<Widget>[
          _TunerSlider(
            key: const ValueKey<String>(
              'dashboard-header-portal-background-center',
            ),
            label: 'Közép',
            valueLabel: '${state.paletteCenterPercent.toStringAsFixed(0)}%',
            min: 0,
            max: 100,
            divisions: 100,
            value: state.paletteCenterPercent,
            onChanged: state.enabled
                ? (value) =>
                      controller.setPortalBackgroundPalette(center: value)
                : null,
          ),
          _TunerSlider(
            key: const ValueKey<String>(
              'dashboard-header-portal-background-window',
            ),
            label: 'Ablak',
            valueLabel: '${state.paletteWindowPercent.toStringAsFixed(0)}%',
            min: 10,
            max: 100,
            divisions: 90,
            value: state.paletteWindowPercent,
            onChanged: state.enabled
                ? (value) =>
                      controller.setPortalBackgroundPalette(window: value)
                : null,
          ),
        ],
        for (final control in effect.controls)
          _TunerSlider(
            key: ValueKey<String>(
              'dashboard-header-portal-$prefix-control-${control.id}',
            ),
            label: control.label,
            valueLabel: _formatSourceControlValue(
              state.settingsFor(effect.id)[control.id] ?? control.defaultValue,
              control,
            ),
            min: control.min,
            max: control.max,
            divisions: ((control.max - control.min) / control.step).round(),
            value:
                state.settingsFor(effect.id)[control.id] ??
                control.defaultValue,
            onChanged: state.enabled
                ? (value) =>
                      controller.updatePortalControl(channel, control.id, value)
                : null,
          ),
      ],
    );
  }
}

final class _TunerSection extends StatelessWidget {
  const _TunerSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      ...children,
    ],
  );
}

final class _TunerSlider extends StatelessWidget {
  const _TunerSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(valueLabel, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
      Slider(
        min: min,
        max: max,
        divisions: divisions,
        value: value.clamp(min, max).toDouble(),
        onChanged: onChanged,
      ),
    ],
  );
}

String _formatControlValue(double value, double step) {
  final text = step.toString();
  final dot = text.indexOf('.');
  final decimals = dot == -1 ? 0 : text.length - dot - 1;
  return value.toStringAsFixed(decimals);
}

String _formatSourceControlValue(
  double value,
  DashboardHeaderEffectControl control,
) {
  final number = _formatControlValue(value, control.step);
  return control.unit.isEmpty ? number : '$number ${control.unit}';
}

String _formatTapWaveControlValue(
  double value,
  DashboardHeaderTapWaveControl control,
) {
  final number = _formatControlValue(value, control.step);
  return control.unit.isEmpty ? number : '$number ${control.unit}';
}
