import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_body_order.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_logbox_layout_profile.dart';
import '../../../../core/design/dashboard_shadow_profile.dart';
import '../budget_content_card_style.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_logbox_height.dart';
import '../dashboard_shadow_style.dart';
import '../summary_pill_variant.dart';
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
  Widget build(BuildContext context) => Semantics(
    label: '$label $valueLabel',
    slider: true,
    child: Column(
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
    ),
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

/// Development-only live control surface. It owns neither Header visual phase
/// nor Budget accounting state: all changes are routed to the dashboard
/// lifetime [DashboardHeaderVisualController].
final class DashboardHeaderVisualTuner extends StatelessWidget {
  const DashboardHeaderVisualTuner({
    super.key,
    required this.controller,
    this.summaryPillVariants,
    this.bodyOrder,
    this.budgetContentCardStyle,
    this.cornerRoundness,
    this.shadowStyle,
    this.logBoxHeight,
  });

  final DashboardHeaderVisualController controller;
  final SummaryPillVariantController? summaryPillVariants;
  final DashboardBodyOrderController? bodyOrder;
  final BudgetContentCardStyleController? budgetContentCardStyle;
  final DashboardCornerRoundnessController? cornerRoundness;
  final DashboardShadowStyleController? shadowStyle;
  final DashboardLogBoxHeightController? logBoxHeight;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<DashboardHeaderVisualTuning>(
    valueListenable: controller.tuning,
    builder: (context, tuning, child) {
      final effect = DashboardHeaderEffectCatalog.effectFor(tuning.effect);
      final familyEffects = DashboardHeaderEffectCatalog.effectsForFamily(
        tuning.animationFamily,
      );
      final effectSelectorLabel = switch (tuning.animationFamily) {
        DashboardHeaderAnimationFamily.classicReference => 'Effekt',
        DashboardHeaderAnimationFamily.fullFieldFlow => 'Áramlás típusa',
        DashboardHeaderAnimationFamily.spaceFabricWarp => 'Térszövet típusa',
      };
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
              if (summaryPillVariants case final variants?) ...<Widget>[
                _SummaryPillExperimentSection(controller: variants),
                const SizedBox(height: 14),
              ],
              if (bodyOrder case final order?) ...<Widget>[
                _DashboardBodyOrderSection(controller: order),
                const SizedBox(height: 14),
              ],
              if (budgetContentCardStyle case final cardStyle?) ...<Widget>[
                _BudgetContentCardStyleSection(controller: cardStyle),
                const SizedBox(height: 14),
              ],
              if (shadowStyle case final shadows?) ...<Widget>[
                _DashboardShadowStyleSection(controller: shadows),
                const SizedBox(height: 14),
              ],
              if (logBoxHeight case final height?) ...<Widget>[
                _DashboardLogBoxHeightSection(controller: height),
                const SizedBox(height: 14),
              ],
              ValueListenableBuilder<Set<DashboardHeaderTunerSection>>(
                valueListenable: controller.expandedTunerSections,
                builder: (context, expandedSections, child) => Column(
                  children: <Widget>[
                    if (cornerRoundness case final roundness?) ...<Widget>[
                      _CollapsibleTunerSection(
                        key: const ValueKey<String>(
                          'dashboard-header-tuner-section-corner-roundness',
                        ),
                        title: 'Sarokkerekítés',
                        expanded: expandedSections.contains(
                          DashboardHeaderTunerSection.cornerRoundness,
                        ),
                        onToggle: () => controller.toggleTunerSection(
                          DashboardHeaderTunerSection.cornerRoundness,
                        ),
                        children: <Widget>[
                          _DashboardCornerRoundnessSection(
                            controller: roundness,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
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
                          title: 'Budget globális szín',
                          children: <Widget>[
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-cool-position-slider',
                              ),
                              label: 'Cool pozíció',
                              valueLabel:
                                  '${tuning.budgetCool.positionPercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.budgetCool.positionPercent,
                              onChanged:
                                  controller.setBudgetCoolPositionPercent,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-cool-window-width-slider',
                              ),
                              label: 'Ablakszélesség',
                              valueLabel:
                                  '${tuning.budgetCool.windowWidthPercent.toStringAsFixed(0)}%',
                              min: 10,
                              max: 100,
                              divisions: 90,
                              value: tuning.budgetCool.windowWidthPercent,
                              onChanged:
                                  controller.setBudgetCoolWindowWidthPercent,
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
                          title: 'Animációs család',
                          children: <Widget>[
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Animációs család',
                              ),
                              child: DropdownButtonHideUnderline(
                                child:
                                    DropdownButton<
                                      DashboardHeaderAnimationFamily
                                    >(
                                      key: const ValueKey<String>(
                                        'dashboard-header-animation-family-selector',
                                      ),
                                      value: tuning.animationFamily,
                                      isExpanded: true,
                                      items:
                                          <
                                            DropdownMenuItem<
                                              DashboardHeaderAnimationFamily
                                            >
                                          >[
                                            DropdownMenuItem<
                                              DashboardHeaderAnimationFamily
                                            >(
                                              value:
                                                  DashboardHeaderAnimationFamily
                                                      .classicReference,
                                              child: Text(
                                                DashboardHeaderAnimationFamily
                                                    .classicReference
                                                    .label,
                                              ),
                                            ),
                                            DropdownMenuItem<
                                              DashboardHeaderAnimationFamily
                                            >(
                                              value:
                                                  DashboardHeaderAnimationFamily
                                                      .fullFieldFlow,
                                              child: Text(
                                                DashboardHeaderAnimationFamily
                                                    .fullFieldFlow
                                                    .label,
                                              ),
                                            ),
                                            DropdownMenuItem<
                                              DashboardHeaderAnimationFamily
                                            >(
                                              value:
                                                  DashboardHeaderAnimationFamily
                                                      .spaceFabricWarp,
                                              child: Text(
                                                DashboardHeaderAnimationFamily
                                                    .spaceFabricWarp
                                                    .label,
                                              ),
                                            ),
                                          ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          controller.selectAnimationFamily(
                                            value,
                                          );
                                        }
                                      },
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _TunerSection(
                          title: effectSelectorLabel,
                          children: <Widget>[
                            if (tuning.animationFamily ==
                                DashboardHeaderAnimationFamily.classicReference)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text('Referencia mozgás · 69d109'),
                              ),
                            InputDecorator(
                              decoration: InputDecoration(
                                labelText: effectSelectorLabel,
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
                                        for (final option in familyEffects)
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
                        if (tuning.animationFamily ==
                            DashboardHeaderAnimationFamily
                                .fullFieldFlow) ...<Widget>[
                          const SizedBox(height: 14),
                          _TunerSection(
                            title: 'Színirány mozgás',
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text('Színirány sodródás'),
                                  ),
                                  Switch(
                                    key: const ValueKey<String>(
                                      'dashboard-header-orientation-enabled',
                                    ),
                                    value: tuning.paletteOrientation.enabled,
                                    onChanged: (enabled) => controller
                                        .setFullFieldPaletteOrientation(
                                          enabled: enabled,
                                        ),
                                  ),
                                ],
                              ),
                              if (tuning
                                  .paletteOrientation
                                  .enabled) ...<Widget>[
                                _TunerSlider(
                                  key: const ValueKey<String>(
                                    'dashboard-header-orientation-base-angle',
                                  ),
                                  label: 'Alapszög',
                                  valueLabel:
                                      '${tuning.paletteOrientation.baseAngleDegrees.toStringAsFixed(0)}°',
                                  min: 0,
                                  max: 360,
                                  divisions: 360,
                                  value: tuning
                                      .paletteOrientation
                                      .baseAngleDegrees,
                                  onChanged: (value) =>
                                      controller.setFullFieldPaletteOrientation(
                                        baseAngleDegrees: value,
                                      ),
                                ),
                                _TunerSlider(
                                  key: const ValueKey<String>(
                                    'dashboard-header-orientation-sweep',
                                  ),
                                  label: 'Szögkilengés',
                                  valueLabel:
                                      '${tuning.paletteOrientation.sweepDegrees.toStringAsFixed(0)}°',
                                  min: 0,
                                  max: 120,
                                  divisions: 120,
                                  value: tuning.paletteOrientation.sweepDegrees,
                                  onChanged: (value) =>
                                      controller.setFullFieldPaletteOrientation(
                                        sweepDegrees: value,
                                      ),
                                ),
                                _TunerSlider(
                                  key: const ValueKey<String>(
                                    'dashboard-header-orientation-speed',
                                  ),
                                  label: 'Szögmozgás sebesség',
                                  valueLabel: tuning.paletteOrientation.speed
                                      .toStringAsFixed(2),
                                  min: 0,
                                  max: 1,
                                  divisions: 100,
                                  value: tuning.paletteOrientation.speed,
                                  onChanged: (value) =>
                                      controller.setFullFieldPaletteOrientation(
                                        speed: value,
                                      ),
                                ),
                                _TunerSlider(
                                  key: const ValueKey<String>(
                                    'dashboard-header-orientation-phase',
                                  ),
                                  label: 'Szögfázis',
                                  valueLabel:
                                      '${tuning.paletteOrientation.phaseDegrees.toStringAsFixed(0)}°',
                                  min: 0,
                                  max: 360,
                                  divisions: 360,
                                  value: tuning.paletteOrientation.phaseDegrees,
                                  onChanged: (value) =>
                                      controller.setFullFieldPaletteOrientation(
                                        phaseDegrees: value,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
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

/// The Header menu owns only the runtime selection chrome. The selected
/// SummaryPill remains a presentation adapter over canonical dashboard state.
final class _SummaryPillExperimentSection extends StatelessWidget {
  const _SummaryPillExperimentSection({required this.controller});

  final SummaryPillVariantController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<SummaryPillVariant>(
        valueListenable: controller,
        builder: (context, selected, _) => RadioGroup<SummaryPillVariant>(
          groupValue: selected,
          onChanged: (variant) {
            if (variant != null) controller.select(variant);
          },
          child: _TunerSection(
            title: 'Időnavigáció / SummaryPill',
            children: <Widget>[
              for (final variant in SummaryPillVariant.values)
                Semantics(
                  selected: selected == variant,
                  inMutuallyExclusiveGroup: true,
                  label: 'SummaryPill ${variant.label}',
                  child: RadioListTile<SummaryPillVariant>(
                    key: ValueKey<String>(
                      'summary-pill-variant-${variant.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(variant.label),
                    value: variant,
                  ),
                ),
            ],
          ),
        ),
      );
}

/// A shell-only Budget preference. The pager and its presentation/query
/// owners stay mounted underneath this tuner control.
final class _BudgetContentCardStyleSection extends StatelessWidget {
  const _BudgetContentCardStyleSection({required this.controller});

  final BudgetContentCardStyleController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetContentLayout>(
        valueListenable: controller,
        builder: (context, selected, _) => RadioGroup<BudgetContentLayout>(
          groupValue: selected,
          onChanged: (layout) {
            if (layout != null) controller.select(layout);
          },
          child: _TunerSection(
            title: 'Budget megjelenés',
            children: <Widget>[
              for (final layout in BudgetContentLayout.values)
                Semantics(
                  selected: selected == layout,
                  inMutuallyExclusiveGroup: true,
                  label: 'Budget tartalom ${layout.label}',
                  child: RadioListTile<BudgetContentLayout>(
                    key: ValueKey<String>(
                      'dashboard-budget-content-${layout.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(layout.label),
                    value: layout,
                  ),
                ),
            ],
          ),
        ),
      );
}

final class _DashboardShadowStyleSection extends StatelessWidget {
  const _DashboardShadowStyleSection({required this.controller});

  final DashboardShadowStyleController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardShadowStyle>(
        valueListenable: controller,
        builder: (context, selected, _) => RadioGroup<DashboardShadowStyle>(
          groupValue: selected,
          onChanged: (style) {
            if (style != null) controller.select(style);
          },
          child: _TunerSection(
            title: 'Árnyék',
            children: <Widget>[
              for (final style in DashboardShadowStyle.values)
                Semantics(
                  selected: selected == style,
                  inMutuallyExclusiveGroup: true,
                  label: 'Árnyék ${_shadowLabel(style)}',
                  child: RadioListTile<DashboardShadowStyle>(
                    key: ValueKey<String>(
                      'dashboard-shadow-style-${style.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_shadowLabel(style)),
                    value: style,
                  ),
                ),
            ],
          ),
        ),
      );

  static String _shadowLabel(DashboardShadowStyle style) => switch (style) {
    DashboardShadowStyle.none => 'Nincs',
    DashboardShadowStyle.current => 'Jelenlegi',
    DashboardShadowStyle.soft => 'Finom',
    DashboardShadowStyle.reference3d => '3D',
  };
}

final class _DashboardLogBoxHeightSection extends StatelessWidget {
  const _DashboardLogBoxHeightSection({required this.controller});

  final DashboardLogBoxHeightController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardLogBoxHeight>(
        valueListenable: controller,
        builder: (context, height, _) => _TunerSection(
          title: 'LogBox',
          children: <Widget>[
            _TunerSlider(
              key: const ValueKey<String>('dashboard-logbox-height-slider'),
              label: 'LogBox magasság',
              valueLabel: '${(height.position * 100).round()}%',
              min: 0,
              max: 1,
              divisions: DashboardLogBoxHeight.divisions,
              value: height.position,
              onChanged: controller.setPosition,
            ),
          ],
        ),
      );
}

/// Each semantic surface family owns a normalized position. The central
/// profile remains responsible for family endpoints and geometry safety.
final class _DashboardCornerRoundnessSection extends StatelessWidget {
  const _DashboardCornerRoundnessSection({required this.controller});

  final DashboardCornerRoundnessController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardCornerSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'Sarokkerekítés',
          children: <Widget>[
            for (final family in DashboardCornerSurfaceFamily.values)
              _TunerSlider(
                key: ValueKey<String>('dashboard-corner-${family.name}-slider'),
                label: _cornerLabel(family),
                valueLabel: '${(settings.positionFor(family) * 100).round()}%',
                min: 0,
                max: 1,
                divisions: 10,
                value: settings.positionFor(family),
                onChanged: (position) =>
                    controller.setPosition(family, position),
              ),
          ],
        ),
      );

  static String _cornerLabel(DashboardCornerSurfaceFamily family) =>
      switch (family) {
        DashboardCornerSurfaceFamily.header => 'Header',
        DashboardCornerSurfaceFamily.contentCard => 'Mód content',
        DashboardCornerSurfaceFamily.directionControl => 'Bevétel / Kiadás',
        DashboardCornerSurfaceFamily.summaryPill => 'Summary',
        DashboardCornerSurfaceFamily.searchPill => 'Search',
        DashboardCornerSurfaceFamily.logBoxGroup => 'LogBox',
        DashboardCornerSurfaceFamily.budgetDistributionCard => 'Budget content',
      };
}

/// Three deterministic slot controls avoid nested drag ownership inside the
/// tuner sheet while maintaining one validated permutation model.
final class _DashboardBodyOrderSection extends StatelessWidget {
  const _DashboardBodyOrderSection({required this.controller});

  final DashboardBodyOrderController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardBodyOrder>(
        valueListenable: controller,
        builder: (context, order, _) => _TunerSection(
          title: 'Fejléc sorrend',
          children: <Widget>[
            for (var index = 0; index < order.components.length; index += 1)
              Row(
                key: ValueKey<String>(
                  'dashboard-body-order-${order.components[index].name}',
                ),
                children: <Widget>[
                  Text(
                    '${index + 1}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.components[index].label)),
                  IconButton(
                    key: ValueKey<String>('dashboard-body-order-up-$index'),
                    tooltip: 'Fel',
                    onPressed: index == 0
                        ? null
                        : () => controller.move(index, index - 1),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  IconButton(
                    key: ValueKey<String>('dashboard-body-order-down-$index'),
                    tooltip: 'Le',
                    onPressed: index == order.components.length - 1
                        ? null
                        : () => controller.move(index, index + 1),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
          ],
        ),
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
