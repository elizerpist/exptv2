import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/financial_limits/presentation/budget_ring_presentation.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_body_order.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_logbox_layout_profile.dart';
import '../../../../core/design/dashboard_shadow_profile.dart';
import '../budget_content_card_style.dart';
import '../budget_section_order.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_border_style.dart';
import '../dashboard_logbox_height.dart';
import '../dashboard_logbox_amount_palette.dart';
import '../dashboard_logbox_search_pill_visibility.dart';
import '../dashboard_budget_header_presentation.dart';
import '../dashboard_shell_presentation.dart';
import '../dashboard_shadow_style.dart';
import '../summary_pill_variant.dart';
import '../dashboard_summary_presentation.dart';
import '../../mind/domain/mind_behavioral_score_settings.dart';
import '../../mind/domain/mind_header_score_chart_presentation.dart';
import '../../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../../application/dashboard_balance_history_projection.dart';
import 'balance_presentation_settings.dart';
import 'dashboard_header_portal_material_field.dart';
import 'dashboard_header_category_scale.dart';
import 'dashboard_header_balance_color_scale.dart';
import 'dashboard_header_mind_score_color.dart';
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
  Widget build(BuildContext context) {
    final hidesHeading = _TunerSectionHeadingScope.hidesHeading(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!hidesHeading) ...<Widget>[
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
        ],
        ...children,
      ],
    );
  }
}

/// The collapsible chrome owns a top-level topic heading. Its direct body
/// keeps the existing setting widgets, but must not repeat that same heading.
/// Nested Header-animation subtopics deliberately use their own headings.
final class _TunerSectionHeadingScope extends InheritedWidget {
  const _TunerSectionHeadingScope({
    required this.hidesChildHeading,
    required super.child,
  });

  final bool hidesChildHeading;

  static bool hidesHeading(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_TunerSectionHeadingScope>()
          ?.hidesChildHeading ??
      false;

  @override
  bool updateShouldNotify(_TunerSectionHeadingScope oldWidget) =>
      hidesChildHeading != oldWidget.hidesChildHeading;
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

/// Reusable pair of independent Header foreground choices. The state itself
/// remains in the one dashboard-lifetime visual controller; this widget only
/// renders intent controls for a mode.
final class _HeaderForegroundControls extends StatelessWidget {
  const _HeaderForegroundControls({
    required this.keyPrefix,
    required this.textColor,
    required this.chartColor,
    required this.iconColor,
    required this.chartVeilColor,
    required this.chartVeilEnabled,
    required this.onTextColorChanged,
    required this.onChartColorChanged,
    required this.onIconColorChanged,
    required this.onChartVeilColorChanged,
    required this.onChartVeilEnabledChanged,
  });

  final String keyPrefix;
  final DashboardHeaderForegroundColor textColor;
  final DashboardHeaderForegroundColor chartColor;
  final DashboardHeaderForegroundColor iconColor;
  final DashboardHeaderForegroundColor chartVeilColor;
  final bool chartVeilEnabled;
  final ValueChanged<DashboardHeaderForegroundColor> onTextColorChanged;
  final ValueChanged<DashboardHeaderForegroundColor> onChartColorChanged;
  final ValueChanged<DashboardHeaderForegroundColor> onIconColorChanged;
  final ValueChanged<DashboardHeaderForegroundColor> onChartVeilColorChanged;
  final ValueChanged<bool> onChartVeilEnabledChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(height: 4),
      Text('Szöveg színe', style: Theme.of(context).textTheme.labelMedium),
      RadioGroup<DashboardHeaderForegroundColor>(
        groupValue: textColor,
        onChanged: (value) {
          if (value != null) onTextColorChanged(value);
        },
        child: _ForegroundChoiceWrap(keyPrefix: '$keyPrefix-text'),
      ),
      Text(
        'Vonaldiagram színe',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      RadioGroup<DashboardHeaderForegroundColor>(
        groupValue: chartColor,
        onChanged: (value) {
          if (value != null) onChartColorChanged(value);
        },
        child: _ForegroundChoiceWrap(keyPrefix: '$keyPrefix-chart'),
      ),
      Text('Ikon színe', style: Theme.of(context).textTheme.labelMedium),
      RadioGroup<DashboardHeaderForegroundColor>(
        groupValue: iconColor,
        onChanged: (value) {
          if (value != null) onIconColorChanged(value);
        },
        child: _ForegroundChoiceWrap(keyPrefix: '$keyPrefix-icon'),
      ),
      SwitchListTile(
        key: ValueKey<String>('$keyPrefix-veil-enabled'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          'Vonal alatti fátyol',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        value: chartVeilEnabled,
        onChanged: onChartVeilEnabledChanged,
      ),
      Text('Fátyol színe', style: Theme.of(context).textTheme.labelMedium),
      RadioGroup<DashboardHeaderForegroundColor>(
        groupValue: chartVeilColor,
        onChanged: (value) {
          if (value != null) onChartVeilColorChanged(value);
        },
        child: _ForegroundChoiceWrap(keyPrefix: '$keyPrefix-veil'),
      ),
    ],
  );
}

/// Budget has no Header line chart, but its Header mode icon consumes the
/// same existing foreground catalog and dashboard-lifetime tuning owner.
final class _HeaderIconColorControls extends StatelessWidget {
  const _HeaderIconColorControls({
    required this.keyPrefix,
    required this.iconColor,
    required this.onIconColorChanged,
  });

  final String keyPrefix;
  final DashboardHeaderForegroundColor iconColor;
  final ValueChanged<DashboardHeaderForegroundColor> onIconColorChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(height: 4),
      Text('Ikon színe', style: Theme.of(context).textTheme.labelMedium),
      RadioGroup<DashboardHeaderForegroundColor>(
        groupValue: iconColor,
        onChanged: (value) {
          if (value != null) onIconColorChanged(value);
        },
        child: _ForegroundChoiceWrap(keyPrefix: '$keyPrefix-icon'),
      ),
    ],
  );
}

/// Wraps instead of constraining the new third option into a too-narrow tile.
/// It has no state or gesture owner: the surrounding [RadioGroup] owns both.
final class _ForegroundChoiceWrap extends StatelessWidget {
  const _ForegroundChoiceWrap({required this.keyPrefix});

  final String keyPrefix;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 420 ? 140.0 : 132.0;
      return Wrap(
        children: <Widget>[
          for (final color in DashboardHeaderForegroundColor.values)
            SizedBox(
              width: width,
              child: RadioListTile<DashboardHeaderForegroundColor>(
                key: ValueKey<String>('$keyPrefix-${color.name}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(color.label),
                value: color,
              ),
            ),
        ],
      );
    },
  );
}

/// The one dashboard-session appearance owner. These controls deliberately
/// bind the app-wide [FluviGlobalAppearance] rather than keeping an independent
/// Header-only typeface or palette selection.
final class _GlobalAppearanceControls extends StatelessWidget {
  const _GlobalAppearanceControls({
    required this.appearance,
    required this.controller,
  });

  final FluviGlobalAppearance appearance;
  final DashboardHeaderVisualController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('Direction színek', style: Theme.of(context).textTheme.labelMedium),
      KeyedSubtree(
        key: const ValueKey<String>('fluvi-direction-color-profile-selector'),
        child: RadioGroup<FluviDirectionColorProfile>(
          groupValue: appearance.directionColorProfile,
          onChanged: (value) {
            if (value != null) controller.setDirectionColorProfile(value);
          },
          child: Wrap(
            children: <Widget>[
              for (final candidate in FluviDirectionColorProfile.values)
                SizedBox(
                  width: 132,
                  child: RadioListTile<FluviDirectionColorProfile>(
                    key: ValueKey<String>(
                      'fluvi-direction-color-profile-${candidate.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.label),
                    value: candidate,
                  ),
                ),
            ],
          ),
        ),
      ),
      Text('Avatar színek', style: Theme.of(context).textTheme.labelMedium),
      KeyedSubtree(
        key: const ValueKey<String>('fluvi-avatar-color-profile-selector'),
        child: RadioGroup<CategoryAvatarColorProfile>(
          groupValue: appearance.avatarColorProfile,
          onChanged: (value) {
            if (value != null) controller.setAvatarColorProfile(value);
          },
          child: Wrap(
            children: <Widget>[
              for (final candidate in CategoryAvatarColorProfile.values)
                SizedBox(
                  width: 132,
                  child: RadioListTile<CategoryAvatarColorProfile>(
                    key: ValueKey<String>(
                      'fluvi-avatar-color-profile-${candidate.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.label),
                    value: candidate,
                  ),
                ),
            ],
          ),
        ),
      ),
      SwitchListTile(
        key: const ValueKey<String>('fluvi-direction-artwork-toggle'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          'Direction artwork',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        value: appearance.showsDirectionArtwork,
        onChanged: controller.setShowsDirectionArtwork,
      ),
      Text('Betűtípus', style: Theme.of(context).textTheme.labelMedium),
      KeyedSubtree(
        key: const ValueKey<String>('fluvi-global-typography-selector'),
        child: RadioGroup<FluviTypographyProfile>(
          groupValue: appearance.typography,
          onChanged: (value) {
            if (value != null) controller.setGlobalTypography(value);
          },
          child: Wrap(
            children: <Widget>[
              for (final candidate in FluviTypographyProfile.values)
                SizedBox(
                  width: 132,
                  child: RadioListTile<FluviTypographyProfile>(
                    key: ValueKey<String>(
                      'fluvi-global-typography-${candidate.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.label),
                    value: candidate,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// The Header menu renders these settings, while their separate controllers
/// retain the financial-model and heatmap-presentation ownership.
final class _MindBehavioralScoreSettingsSection extends StatelessWidget {
  const _MindBehavioralScoreSettingsSection({required this.controller});

  final MindBehavioralScoreSettingsController controller;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindBehavioralScoreSettings>(
    valueListenable: controller,
    builder: (context, settings, _) {
      final causal =
          settings.expenseAlgorithm == MindExpenseScoreAlgorithm.causalTrailing;
      return _TunerSection(
        title: 'Mind score',
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Kiadási score számítás'),
          ),
          RadioGroup<MindExpenseScoreAlgorithm>(
            groupValue: settings.expenseAlgorithm,
            onChanged: (algorithm) {
              if (algorithm != null) controller.setExpenseAlgorithm(algorithm);
            },
            child: Column(
              children: <Widget>[
                for (final algorithm in MindExpenseScoreAlgorithm.values)
                  RadioListTile<MindExpenseScoreAlgorithm>(
                    key: ValueKey(
                      'mind-expense-score-algorithm-${algorithm.name}',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(algorithm.tunerLabel),
                    value: algorithm,
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Kauzális előzmény'),
          ),
          if (!causal)
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                'Csak a Kauzális · trailing módban aktív.',
                style: TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          RadioGroup<MindCausalHistoryOrigin>(
            groupValue: settings.causalHistoryOrigin,
            onChanged: (origin) {
              if (causal && origin != null) {
                controller.setCausalHistoryOrigin(origin);
              }
            },
            child: Column(
              children: <Widget>[
                for (final origin in MindCausalHistoryOrigin.values)
                  RadioListTile<MindCausalHistoryOrigin>(
                    key: ValueKey('mind-causal-history-origin-${origin.name}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    enabled: causal,
                    title: Text(origin.tunerLabel),
                    value: origin,
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

final class _MindHeaderScoreChartPresentationSection extends StatelessWidget {
  const _MindHeaderScoreChartPresentationSection({required this.controller});

  final MindHeaderScoreChartPresentationController controller;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindHeaderScoreChartPresentationSettings>(
    valueListenable: controller,
    builder: (context, settings, _) => _TunerSection(
      title: 'Mind chart',
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Line chart időjelölések'),
        ),
        RadioGroup<MindHeaderScoreChartTimeLabels>(
          groupValue: settings.timeLabels,
          onChanged: (visibility) {
            if (visibility != null) controller.setTimeLabels(visibility);
          },
          child: Column(
            children: <Widget>[
              for (final visibility in MindHeaderScoreChartTimeLabels.values)
                RadioListTile<MindHeaderScoreChartTimeLabels>(
                  key: ValueKey(
                    'mind-header-score-chart-time-labels-${visibility.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(visibility.tunerLabel),
                  value: visibility,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _BalancePresentationSection extends StatelessWidget {
  const _BalancePresentationSection({required this.controller});

  final BalancePresentationController controller;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<BalancePresentationSettings>(
    valueListenable: controller,
    builder: (context, settings, _) => _TunerSection(
      title: 'Balance',
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Header chart nézet'),
        ),
        RadioGroup<BalanceHeaderChartMode>(
          groupValue: settings.chartMode,
          onChanged: (mode) {
            if (mode != null) controller.setChartMode(mode);
          },
          child: Column(
            children: <Widget>[
              for (final mode in BalanceHeaderChartMode.values)
                RadioListTile<BalanceHeaderChartMode>(
                  key: ValueKey('balance-header-chart-mode-${mode.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(mode.tunerLabel),
                  value: mode,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Line chart időjelölések'),
        ),
        RadioGroup<BalanceHeaderChartTimeLabels>(
          groupValue: settings.timeLabels,
          onChanged: (visibility) {
            if (visibility != null) controller.setTimeLabels(visibility);
          },
          child: Column(
            children: <Widget>[
              for (final visibility in BalanceHeaderChartTimeLabels.values)
                RadioListTile<BalanceHeaderChartTimeLabels>(
                  key: ValueKey(
                    'balance-header-history-chart-time-labels-${visibility.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(visibility.tunerLabel),
                  value: visibility,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Utolsó tranzakció kártya'),
        ),
        RadioGroup<BalanceLatestTransactionCardPresentation>(
          groupValue: settings.latestTransactionCardPresentation,
          onChanged: (presentation) {
            if (presentation != null) {
              controller.setLatestTransactionCardPresentation(presentation);
            }
          },
          child: Column(
            children: <Widget>[
              for (final presentation
                  in BalanceLatestTransactionCardPresentation.values)
                RadioListTile<BalanceLatestTransactionCardPresentation>(
                  key: ValueKey(
                    'balance-latest-card-presentation-${presentation.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(presentation.tunerLabel),
                  value: presentation,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _MindYearHeatmapPresentationSection extends StatelessWidget {
  const _MindYearHeatmapPresentationSection({required this.controller});

  final MindYearHeatmapPresentationController controller;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
    valueListenable: controller,
    builder: (context, settings, _) => _TunerSection(
      title: 'Mind hőtérkép',
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Színezés'),
        ),
        RadioGroup<MindYearHeatmapPaletteStyle>(
          groupValue: settings.paletteStyle,
          onChanged: (style) {
            if (style != null) controller.setPaletteStyle(style);
          },
          child: Column(
            children: <Widget>[
              for (final style in MindYearHeatmapPaletteStyle.values)
                RadioListTile<MindYearHeatmapPaletteStyle>(
                  key: ValueKey('mind-heatmap-palette-${style.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(style.tunerLabel),
                  value: style,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Színfelbontás'),
        ),
        RadioGroup<MindHeatmapScaleResolution>(
          groupValue: settings.scaleResolution,
          onChanged: (resolution) {
            if (resolution != null) {
              controller.setScaleResolution(resolution);
            }
          },
          child: Column(
            children: <Widget>[
              for (final resolution in MindHeatmapScaleResolution.values)
                RadioListTile<MindHeatmapScaleResolution>(
                  key: ValueKey(
                    'mind-heatmap-scale-resolution-${resolution.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(resolution.tunerLabel),
                  value: resolution,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Day idővonal'),
        ),
        RadioGroup<MindDayTimelineLayout>(
          groupValue: settings.dayTimelineLayout,
          onChanged: (layout) {
            if (layout != null) controller.setDayTimelineLayout(layout);
          },
          child: Column(
            children: <Widget>[
              for (final layout in MindDayTimelineLayout.values)
                RadioListTile<MindDayTimelineLayout>(
                  key: ValueKey('mind-day-timeline-layout-${layout.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(layout.tunerLabel),
                  value: layout,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Sum évblokk'),
        ),
        RadioGroup<MindSumYearRowLayout>(
          groupValue: settings.sumYearRowLayout,
          onChanged: (layout) {
            if (layout != null) controller.setSumYearRowLayout(layout);
          },
          child: Column(
            children: <Widget>[
              for (final layout in MindSumYearRowLayout.values)
                RadioListTile<MindSumYearRowLayout>(
                  key: ValueKey('mind-sum-row-layout-${layout.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(layout.tunerLabel),
                  value: layout,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Sum hónapjelölés'),
        ),
        RadioGroup<MindSumMonthLabelPlacement>(
          groupValue: settings.sumMonthLabelPlacement,
          onChanged: (placement) {
            if (placement != null) {
              controller.setSumMonthLabelPlacement(placement);
            }
          },
          child: Column(
            children: <Widget>[
              for (final placement in MindSumMonthLabelPlacement.values)
                RadioListTile<MindSumMonthLabelPlacement>(
                  key: ValueKey(
                    'mind-sum-month-label-placement-${placement.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(placement.tunerLabel),
                  value: placement,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Sum grafikonok egyszerre'),
        ),
        RadioGroup<MindSumVisibleChartCount>(
          groupValue: settings.sumVisibleChartCount,
          onChanged: (count) {
            if (count != null) controller.setSumVisibleChartCount(count);
          },
          child: Column(
            children: <Widget>[
              for (final count in MindSumVisibleChartCount.values)
                RadioListTile<MindSumVisibleChartCount>(
                  key: ValueKey('mind-sum-visible-chart-count-${count.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(count.tunerLabel),
                  value: count,
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Éves hónapkártyák'),
        ),
        SwitchListTile(
          key: const ValueKey<String>('mind-year-month-card-border-enabled'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Hónapkártya keret'),
          subtitle: const Text('Csak a 3×4 és 2×6 kártyás nézetben'),
          value: settings.yearMonthCardBorderEnabled,
          onChanged: controller.setYearMonthCardBorderEnabled,
        ),
        SwitchListTile(
          key: const ValueKey<String>('mind-year-profitability-tint-enabled'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Hónapkártya háttér'),
          subtitle: const Text('Nyereség/zárás szerint'),
          value: settings.yearMonthCardProfitabilityTintEnabled,
          onChanged: controller.setYearMonthCardProfitabilityTintEnabled,
        ),
        Semantics(
          label:
              'Profitabilitás háttér erőssége ${(settings.yearMonthCardProfitabilityTintOpacity * 100).round()}%',
          child: Column(
            key: const ValueKey<String>('mind-year-profitability-tint-opacity'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Háttér erőssége ${(settings.yearMonthCardProfitabilityTintOpacity * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
              Slider(
                value: settings.yearMonthCardProfitabilityTintOpacity,
                onChanged: controller.setYearMonthCardProfitabilityTintOpacity,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Sum részletes vonal'),
        ),
        RadioGroup<MindSumLineInterpolationMode>(
          groupValue: settings.sumLineInterpolationMode,
          onChanged: (mode) {
            if (mode != null) controller.setSumLineInterpolationMode(mode);
          },
          child: Column(
            children: <Widget>[
              for (final mode in MindSumLineInterpolationMode.values)
                RadioListTile<MindSumLineInterpolationMode>(
                  key: ValueKey('mind-sum-line-interpolation-${mode.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(mode.tunerLabel),
                  value: mode,
                ),
            ],
          ),
        ),
        Semantics(
          label:
              'Catmull–Rom feszesség ${(settings.sumLineCatmullRomTension * 100).round()}%',
          child: Column(
            key: const ValueKey<String>('mind-sum-line-catmull-rom-tension'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Catmull–Rom feszesség ${(settings.sumLineCatmullRomTension * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
              Slider(
                value: settings.sumLineCatmullRomTension,
                onChanged: controller.setSumLineCatmullRomTension,
              ),
            ],
          ),
        ),
        SwitchListTile(
          key: const ValueKey<String>('mind-sum-line-smoothing-enabled'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Súlyozott időbeli simítás'),
          value: settings.sumLineTemporalSmoothingEnabled,
          onChanged: controller.setSumLineTemporalSmoothingEnabled,
        ),
        RadioGroup<MindSumSmoothingWindow>(
          groupValue: settings.sumLineSmoothingWindow,
          onChanged: (window) {
            if (window != null) controller.setSumLineSmoothingWindow(window);
          },
          child: Column(
            children: <Widget>[
              for (final window in MindSumSmoothingWindow.values)
                RadioListTile<MindSumSmoothingWindow>(
                  key: ValueKey(
                    'mind-sum-line-smoothing-window-${window.name}',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(window.tunerLabel),
                  value: window,
                ),
            ],
          ),
        ),
        SwitchListTile(
          key: const ValueKey<String>(
            'mind-sum-line-zoom-adaptive-smoothing-enabled',
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Zoom-adaptív simítás'),
          subtitle: const Text(
            'Részletnél fokozatosan nyers adatra tér vissza',
          ),
          value: settings.sumLineZoomAdaptiveSmoothingEnabled,
          onChanged: controller.setSumLineZoomAdaptiveSmoothingEnabled,
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
    this.budgetSectionOrder,
    this.summaryPresentation,
    this.cornerRoundness,
    this.shadowStyle,
    this.border,
    this.logBoxHeight,
    this.amountPalette,
    this.searchPillVisibility,
    this.budgetHeaderPresentation,
    this.budgetRingPresentation,
    this.shellPresentation,
    this.mindBehavioralScoreSettings,
    this.mindHeaderScoreChartPresentation,
    this.mindYearHeatmapPresentation,
    this.balancePresentationSettings,
  });

  final DashboardHeaderVisualController controller;
  final SummaryPillVariantController? summaryPillVariants;
  final DashboardBodyOrderController? bodyOrder;
  final BudgetContentCardStyleController? budgetContentCardStyle;
  final BudgetSectionOrderController? budgetSectionOrder;
  final DashboardSummaryPresentationController? summaryPresentation;
  final DashboardCornerRoundnessController? cornerRoundness;
  final DashboardShadowStyleController? shadowStyle;
  final DashboardBorderController? border;
  final DashboardLogBoxHeightController? logBoxHeight;
  final DashboardLogBoxAmountPaletteController? amountPalette;
  final DashboardLogBoxSearchPillController? searchPillVisibility;
  final DashboardBudgetHeaderPresentationController? budgetHeaderPresentation;
  final BudgetRingPresentationController? budgetRingPresentation;
  final DashboardShellPresentationController? shellPresentation;
  final MindBehavioralScoreSettingsController? mindBehavioralScoreSettings;
  final MindHeaderScoreChartPresentationController?
  mindHeaderScoreChartPresentation;
  final MindYearHeatmapPresentationController? mindYearHeatmapPresentation;
  final BalancePresentationController? balancePresentationSettings;

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
              _DashboardHeaderTunerTopic(
                key: const ValueKey<String>(
                  'dashboard-header-tuner-section-appearance',
                ),
                controller: controller,
                section: DashboardHeaderTunerSection.appearance,
                title: 'MEGJELENÉS',
                children: <Widget>[
                  _GlobalAppearanceControls(
                    appearance: tuning.globalAppearance,
                    controller: controller,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (summaryPillVariants case final variants?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-summary-pill-variants',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.summaryPillVariants,
                  title: 'Időnavigáció / SummaryPill',
                  children: <Widget>[
                    _SummaryPillExperimentSection(controller: variants),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (summaryPresentation case final summary?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-summary-presentation',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.summaryPresentation,
                  title: 'Summary megjelenés',
                  children: <Widget>[
                    _DashboardSummaryPresentationSection(controller: summary),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (bodyOrder case final order?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-body-order',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.bodyOrder,
                  title: 'Fejléc sorrend',
                  children: <Widget>[
                    _DashboardBodyOrderSection(controller: order),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (budgetContentCardStyle case final cardStyle?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-budget-content-card-style',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.budgetContentCardStyle,
                  title: 'Budget megjelenés',
                  children: <Widget>[
                    _BudgetContentCardStyleSection(controller: cardStyle),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (budgetSectionOrder case final order?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-budget-section-order',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.budgetSectionOrder,
                  title: 'Budget szekciósorrend',
                  children: <Widget>[
                    _BudgetSectionOrderSection(controller: order),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (shadowStyle case final shadows?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-shadow-style',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.shadowStyle,
                  title: 'Árnyék',
                  children: <Widget>[
                    _DashboardShadowStyleSection(controller: shadows),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (logBoxHeight case final height?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-logbox-height',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.logBoxHeight,
                  title: 'LogBox magasság',
                  children: <Widget>[
                    _DashboardLogBoxHeightSection(controller: height),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (searchPillVisibility case final searchPill?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-search-pill-visibility',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.searchPillVisibility,
                  title: 'LogBox keresés',
                  children: <Widget>[
                    _DashboardSearchPillVisibilitySection(
                      controller: searchPill,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (budgetHeaderPresentation
                  case final budgetHeader?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-budget-header-presentation',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.budgetHeaderPresentation,
                  title: 'Budget Header',
                  children: <Widget>[
                    _DashboardBudgetHeaderPresentationSection(
                      controller: budgetHeader,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (budgetRingPresentation case final ring?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-budget-ring-presentation',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.budgetRingPresentation,
                  title: 'SUM Budget',
                  children: <Widget>[
                    _BudgetRingPresentationSection(controller: ring),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (shellPresentation case final shell?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-shell-presentation',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.shellPresentation,
                  title: 'BottomNav',
                  children: <Widget>[
                    _DashboardBottomNavPresentationSection(controller: shell),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (mindBehavioralScoreSettings
                  case final scoreSettings?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-mind-behavioral-score',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.mindBehavioralScore,
                  title: 'Mind score',
                  children: <Widget>[
                    _MindBehavioralScoreSettingsSection(
                      controller: scoreSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (mindHeaderScoreChartPresentation
                  case final chartPresentation?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-mind-header-score-chart',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.mindHeaderScoreChart,
                  title: 'Mind chart',
                  children: <Widget>[
                    _MindHeaderScoreChartPresentationSection(
                      controller: chartPresentation,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (mindYearHeatmapPresentation
                  case final heatmapPresentation?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-mind-year-heatmap',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.mindYearHeatmap,
                  title: 'Mind hőtérkép',
                  children: <Widget>[
                    _MindYearHeatmapPresentationSection(
                      controller: heatmapPresentation,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (balancePresentationSettings
                  case final balanceSettings?) ...<Widget>[
                _DashboardHeaderTunerTopic(
                  key: const ValueKey<String>(
                    'dashboard-header-tuner-section-balance-presentation',
                  ),
                  controller: controller,
                  section: DashboardHeaderTunerSection.balancePresentation,
                  title: 'Balance',
                  children: <Widget>[
                    _BalancePresentationSection(controller: balanceSettings),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              ValueListenableBuilder<Set<DashboardHeaderTunerSection>>(
                valueListenable: controller.expandedTunerSections,
                builder: (context, expandedSections, child) => Column(
                  children: <Widget>[
                    if (border case final borders?) ...<Widget>[
                      _CollapsibleTunerSection(
                        key: const ValueKey<String>(
                          'dashboard-header-tuner-section-borders',
                        ),
                        title: 'Körvonalak',
                        expanded: expandedSections.contains(
                          DashboardHeaderTunerSection.borders,
                        ),
                        onToggle: () => controller.toggleTunerSection(
                          DashboardHeaderTunerSection.borders,
                        ),
                        children: <Widget>[
                          _DashboardBorderSection(controller: borders),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (amountPalette case final palettes?) ...<Widget>[
                      _CollapsibleTunerSection(
                        key: const ValueKey<String>(
                          'dashboard-header-tuner-section-logbox-amount-colours',
                        ),
                        title: 'LogBox összegszínek',
                        expanded: expandedSections.contains(
                          DashboardHeaderTunerSection.logBoxAmountColours,
                        ),
                        onToggle: () => controller.toggleTunerSection(
                          DashboardHeaderTunerSection.logBoxAmountColours,
                        ),
                        children: <Widget>[
                          _DashboardLogBoxAmountPaletteSection(
                            controller: palettes,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
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
                      suppressChildTunerHeading: false,
                      children: <Widget>[
                        _TunerSection(
                          title: 'Header ikon',
                          children: <Widget>[
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-mode-icon-size-slider',
                              ),
                              label: 'Módikon mérete',
                              valueLabel:
                                  '${tuning.headerModeIconSizePercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.headerModeIconSizePercent,
                              onChanged:
                                  controller.setHeaderModeIconSizePercent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TunerSection(
                          title: 'Balance Header szín',
                          children: <Widget>[
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Paletta',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<DashboardBalanceHeaderPalette>(
                                  key: const ValueKey<String>(
                                    'dashboard-header-balance-palette-selector',
                                  ),
                                  value: tuning.balanceColor.palette,
                                  isExpanded: true,
                                  items: DashboardBalanceHeaderPaletteCatalog
                                      .palettes
                                      .map(
                                        (palette) =>
                                            DropdownMenuItem<
                                              DashboardBalanceHeaderPalette
                                            >(
                                              value: palette,
                                              child: Text(palette.label),
                                            ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (palette) {
                                    if (palette != null) {
                                      controller.selectBalanceHeaderPalette(
                                        palette,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Színerősség',
                              ),
                              child: DropdownButtonHideUnderline(
                                child:
                                    DropdownButton<
                                      DashboardBalanceHeaderPaletteVariant
                                    >(
                                      key: const ValueKey<String>(
                                        'dashboard-header-balance-variant-selector',
                                      ),
                                      value: tuning.balanceColor.variant,
                                      isExpanded: true,
                                      items: DashboardBalanceHeaderPaletteCatalog
                                          .variants
                                          .map(
                                            (variant) =>
                                                DropdownMenuItem<
                                                  DashboardBalanceHeaderPaletteVariant
                                                >(
                                                  value: variant,
                                                  child: Text(variant.label),
                                                ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (variant) {
                                        if (variant != null) {
                                          controller
                                              .selectBalanceHeaderPaletteVariant(
                                                variant,
                                              );
                                        }
                                      },
                                    ),
                              ),
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-balance-position-slider',
                              ),
                              label: 'Pozíció',
                              valueLabel:
                                  '${tuning.balanceColor.positionPercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.balanceColor.positionPercent,
                              onChanged:
                                  controller.setBalanceHeaderPositionPercent,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-balance-window-width-slider',
                              ),
                              label: 'Ablakméret',
                              valueLabel:
                                  '${tuning.balanceColor.windowWidthPercent.toStringAsFixed(0)}%',
                              min: 10,
                              max: 100,
                              divisions: 90,
                              value: tuning.balanceColor.windowWidthPercent,
                              onChanged:
                                  controller.setBalanceHeaderWindowWidthPercent,
                            ),
                            _HeaderForegroundControls(
                              keyPrefix: 'dashboard-header-balance',
                              textColor: tuning.balanceHeader.textColor,
                              chartColor: tuning.balanceHeader.chartColor,
                              iconColor: tuning.balanceHeader.iconColor,
                              chartVeilColor:
                                  tuning.balanceHeader.chartVeilColor,
                              chartVeilEnabled:
                                  tuning.balanceHeader.chartVeilEnabled,
                              onTextColorChanged:
                                  controller.setBalanceHeaderTextColor,
                              onChartColorChanged:
                                  controller.setBalanceHeaderChartColor,
                              onIconColorChanged:
                                  controller.setBalanceHeaderIconColor,
                              onChartVeilColorChanged:
                                  controller.setBalanceHeaderChartVeilColor,
                              onChartVeilEnabledChanged:
                                  controller.setBalanceHeaderChartVeilEnabled,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-balance-opacity-slider',
                              ),
                              label: 'Balance áttetszőség',
                              valueLabel:
                                  '${tuning.balanceHeader.opacityPercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.balanceHeader.opacityPercent,
                              onChanged:
                                  controller.setBalanceHeaderOpacityPercent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TunerSection(
                          title: 'Budget Header szín',
                          children: <Widget>[
                            RadioGroup<DashboardBudgetHeaderColorSource>(
                              groupValue: tuning.budgetCategory.source,
                              onChanged: (source) {
                                if (source != null) {
                                  controller.selectBudgetHeaderColorSource(
                                    source,
                                  );
                                }
                              },
                              child: Column(
                                children:
                                    <
                                      RadioListTile<
                                        DashboardBudgetHeaderColorSource
                                      >
                                    >[
                                      RadioListTile<
                                        DashboardBudgetHeaderColorSource
                                      >(
                                        key: const ValueKey<String>(
                                          'dashboard-header-colour-source-cool',
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Cool'),
                                        value: DashboardBudgetHeaderColorSource
                                            .cool,
                                      ),
                                      RadioListTile<
                                        DashboardBudgetHeaderColorSource
                                      >(
                                        key: const ValueKey<String>(
                                          'dashboard-header-colour-source-category',
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Kategória'),
                                        value: DashboardBudgetHeaderColorSource
                                            .category,
                                      ),
                                    ],
                              ),
                            ),
                            if (tuning.budgetCategory.source ==
                                DashboardBudgetHeaderColorSource
                                    .cool) ...<Widget>[
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
                            ] else
                              _TunerSlider(
                                key: const ValueKey<String>(
                                  'dashboard-header-category-window-width-slider',
                                ),
                                label: 'Ablakszélesség',
                                valueLabel:
                                    '${tuning.budgetCategory.windowWidthPercent.toStringAsFixed(0)}%',
                                min: 10,
                                max: 100,
                                divisions: 90,
                                value: tuning.budgetCategory.windowWidthPercent,
                                onChanged: controller
                                    .setBudgetCategoryWindowWidthPercent,
                              ),
                            _HeaderIconColorControls(
                              keyPrefix: 'dashboard-header-budget',
                              iconColor: tuning.budgetHeader.iconColor,
                              onIconColorChanged:
                                  controller.setBudgetHeaderIconColor,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-budget-opacity-slider',
                              ),
                              label: 'Budget áttetszőség',
                              valueLabel:
                                  '${tuning.budgetHeader.opacityPercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.budgetHeader.opacityPercent,
                              onChanged:
                                  controller.setBudgetHeaderOpacityPercent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TunerSection(
                          title: 'Mind Header szín',
                          children: <Widget>[
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Paletta',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<MindHeaderScorePalette>(
                                  key: const ValueKey<String>(
                                    'dashboard-header-mind-palette-selector',
                                  ),
                                  value: tuning.mindScore.palette,
                                  isExpanded: true,
                                  items: MindHeaderScorePalette.values
                                      .map(
                                        (palette) =>
                                            DropdownMenuItem<
                                              MindHeaderScorePalette
                                            >(
                                              value: palette,
                                              child: Text(palette.label),
                                            ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (palette) {
                                    if (palette != null) {
                                      controller.selectMindHeaderPalette(
                                        palette,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-mind-score-window-width-slider',
                              ),
                              label: 'Ablakszélesség',
                              valueLabel:
                                  '${tuning.mindScore.windowWidthPercent.toStringAsFixed(0)}%',
                              min: 10,
                              max: 100,
                              divisions: 90,
                              value: tuning.mindScore.windowWidthPercent,
                              onChanged: controller
                                  .setMindHeaderScoreWindowWidthPercent,
                            ),
                            _HeaderForegroundControls(
                              keyPrefix: 'dashboard-header-mind',
                              textColor: tuning.mindHeader.textColor,
                              chartColor: tuning.mindHeader.chartColor,
                              iconColor: tuning.mindHeader.iconColor,
                              chartVeilColor: tuning.mindHeader.chartVeilColor,
                              chartVeilEnabled:
                                  tuning.mindHeader.chartVeilEnabled,
                              onTextColorChanged:
                                  controller.setMindHeaderTextColor,
                              onChartColorChanged:
                                  controller.setMindHeaderChartColor,
                              onIconColorChanged:
                                  controller.setMindHeaderIconColor,
                              onChartVeilColorChanged:
                                  controller.setMindHeaderChartVeilColor,
                              onChartVeilEnabledChanged:
                                  controller.setMindHeaderChartVeilEnabled,
                            ),
                            _TunerSlider(
                              key: const ValueKey<String>(
                                'dashboard-header-mind-opacity-slider',
                              ),
                              label: 'Mind áttetszőség',
                              valueLabel:
                                  '${tuning.mindHeader.opacityPercent.toStringAsFixed(0)}%',
                              min: 0,
                              max: 100,
                              divisions: 100,
                              value: tuning.mindHeader.opacityPercent,
                              onChanged: controller.setMindHeaderOpacityPercent,
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

final class _BudgetRingPresentationSection extends StatelessWidget {
  const _BudgetRingPresentationSection({required this.controller});

  final BudgetRingPresentationController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetRingPresentationSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'SUM Budget',
          children: <Widget>[
            RadioGroup<BudgetSumRingStyle>(
              groupValue: settings.sumRingStyle,
              onChanged: (style) {
                if (style != null) controller.selectSumRingStyle(style);
              },
              child: Column(
                children: <Widget>[
                  for (final style in BudgetSumRingStyle.values)
                    RadioListTile<BudgetSumRingStyle>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(switch (style) {
                        BudgetSumRingStyle.current => 'Jelenlegi',
                        BudgetSumRingStyle.coloredScaleWhiteArc =>
                          'Színes skála + fehér szegmens',
                        BudgetSumRingStyle.coloredScaleMovingSphere =>
                          'Színes skála + gömb',
                      }),
                      value: style,
                    ),
                ],
              ),
            ),
            RadioGroup<BudgetHealthyColorMode>(
              groupValue: settings.healthyColorMode,
              onChanged: (mode) {
                if (mode != null) controller.selectHealthyColorMode(mode);
              },
              child: Column(
                children: <Widget>[
                  for (final mode in BudgetHealthyColorMode.values)
                    RadioListTile<BudgetHealthyColorMode>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        mode == BudgetHealthyColorMode.fixedGreen
                            ? 'Egészséges szín: Zöld'
                            : 'Egészséges szín: Kategóriaszín',
                      ),
                      value: mode,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

final class _DashboardSummaryPresentationSection extends StatelessWidget {
  const _DashboardSummaryPresentationSection({required this.controller});

  final DashboardSummaryPresentationController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardSummaryPresentationSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'Summary megjelenés',
          children: <Widget>[
            SwitchListTile(
              key: const ValueKey('dashboard-summary-separators'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Elválasztók'),
              value: settings.showSeparators,
              onChanged: controller.setSeparatorsVisible,
            ),
            _SummaryRadioGroup<SummaryTemporalFlingPresentation>(
              label: 'Idő-fling látvány',
              value: settings.temporalFlingPresentation,
              values: SummaryTemporalFlingPresentation.values,
              itemLabel: (value) => value.label,
              onChanged: controller.selectTemporalFlingPresentation,
              keyPrefix: 'dashboard-summary-fling-presentation',
            ),
            _SummaryRadioGroup<SummarySegmentedOrientation>(
              label: 'Szekciós elrendezés',
              value: settings.segmentedOrientation,
              values: SummarySegmentedOrientation.values,
              itemLabel: (value) => value.label,
              onChanged: controller.selectSegmentedOrientation,
              keyPrefix: 'dashboard-summary-segmented-orientation',
            ),
          ],
        ),
      );
}

final class _SummaryRadioGroup<T> extends StatelessWidget {
  const _SummaryRadioGroup({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
    required this.keyPrefix,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        for (final item in values)
          RadioListTile<T>(
            key: ValueKey('$keyPrefix-$item'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(itemLabel(item)),
            value: item,
          ),
      ],
    ),
  );
}

final class _BudgetSectionOrderSection extends StatelessWidget {
  const _BudgetSectionOrderSection({required this.controller});

  final BudgetSectionOrderController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetSectionOrder>(
        valueListenable: controller,
        builder: (context, selected, _) => RadioGroup<BudgetSectionOrder>(
          groupValue: selected,
          onChanged: (order) {
            if (order != null) controller.select(order);
          },
          child: _TunerSection(
            title: 'Budget szekciósorrend',
            children: <Widget>[
              for (final order in BudgetSectionOrder.values)
                RadioListTile<BudgetSectionOrder>(
                  key: ValueKey('dashboard-budget-section-order-${order.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(order.label),
                  value: order,
                ),
            ],
          ),
        ),
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

final class _DashboardSearchPillVisibilitySection extends StatelessWidget {
  const _DashboardSearchPillVisibilitySection({required this.controller});

  final DashboardLogBoxSearchPillController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardLogBoxSearchPillSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'LogBox',
          children: <Widget>[
            SwitchListTile.adaptive(
              key: const ValueKey('dashboard-logbox-search-pill-visible'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('SearchPill'),
              value: settings.isVisible,
              onChanged: controller.setVisible,
            ),
            RadioGroup<DashboardQueryFacetPillStyle>(
              groupValue: settings.queryFacetPillStyle,
              onChanged: (value) {
                if (value != null) controller.selectQueryFacetPillStyle(value);
              },
              child: Column(
                children: <Widget>[
                  for (final style in DashboardQueryFacetPillStyle.values)
                    RadioListTile<DashboardQueryFacetPillStyle>(
                      key: ValueKey(
                        'dashboard-query-facet-style-${style.name}',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        style == DashboardQueryFacetPillStyle.current
                            ? 'Query kapszula: Jelenlegi'
                            : 'Query kapszula: Avatárszín',
                      ),
                      value: style,
                    ),
                ],
              ),
            ),
            RadioGroup<DashboardQueryFacetPlacement>(
              groupValue: settings.queryFacetPlacement,
              onChanged: (value) {
                if (value != null) controller.selectQueryFacetPlacement(value);
              },
              child: Column(
                children: <Widget>[
                  for (final placement in DashboardQueryFacetPlacement.values)
                    RadioListTile<DashboardQueryFacetPlacement>(
                      key: ValueKey(
                        'dashboard-query-facet-placement-${placement.name}',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        placement == DashboardQueryFacetPlacement.bodyTop
                            ? 'Query kapszulák helye: Body teteje'
                            : 'Query kapszulák helye: SearchPillben',
                      ),
                      value: placement,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

final class _DashboardBudgetHeaderPresentationSection extends StatelessWidget {
  const _DashboardBudgetHeaderPresentationSection({required this.controller});

  final DashboardBudgetHeaderPresentationController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardBudgetHeaderPresentationSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'Budget Header',
          children: <Widget>[
            _TunerSlider(
              key: const ValueKey('dashboard-header-partition-height'),
              label: 'Partíció magasság',
              valueLabel: '+${settings.partitionHeightPercent.round()}%',
              min: 0,
              max: 100,
              divisions: 100,
              value: settings.partitionHeightPercent,
              onChanged: controller.setPartitionHeightPercent,
            ),
            RadioGroup<DashboardBudgetHeaderForeground>(
              groupValue: settings.foreground,
              onChanged: (value) {
                if (value != null) controller.selectForeground(value);
              },
              child: Column(
                children: <Widget>[
                  for (final foreground
                      in DashboardBudgetHeaderForeground.values)
                    RadioListTile<DashboardBudgetHeaderForeground>(
                      key: ValueKey(
                        'dashboard-header-foreground-${foreground.name}',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        foreground == DashboardBudgetHeaderForeground.white
                            ? 'Fehér'
                            : 'Fekete',
                      ),
                      value: foreground,
                    ),
                ],
              ),
            ),
            SwitchListTile(
              key: const ValueKey('dashboard-header-partition-contour'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Partíció kontúr'),
              value: settings.showPartitionContour,
              onChanged: controller.setPartitionContour,
            ),
            RadioGroup<DashboardHeaderTextContrastStyle>(
              groupValue: settings.textContrastStyle,
              onChanged: (style) {
                if (style != null) controller.selectTextContrastStyle(style);
              },
              child: Column(
                children: <Widget>[
                  for (final style in DashboardHeaderTextContrastStyle.values)
                    RadioListTile<DashboardHeaderTextContrastStyle>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(switch (style) {
                        DashboardHeaderTextContrastStyle.none =>
                          'Szöveg kontraszt: Nincs',
                        DashboardHeaderTextContrastStyle.hardOppositeShadow =>
                          'Szöveg kontraszt: Éles árnyék',
                        DashboardHeaderTextContrastStyle.oppositeOutline =>
                          'Szöveg kontraszt: Körvonal',
                      }),
                      value: style,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

final class _DashboardBottomNavPresentationSection extends StatelessWidget {
  const _DashboardBottomNavPresentationSection({required this.controller});

  final DashboardShellPresentationController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardShellPresentationSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'BottomNav',
          children: <Widget>[
            _SummaryRadioGroup<DashboardBottomNavLayoutStyle>(
              label: 'Elrendezés',
              value: settings.bottomNavLayoutStyle,
              values: DashboardBottomNavLayoutStyle.values,
              itemLabel: (value) =>
                  value == DashboardBottomNavLayoutStyle.raisedFab
                  ? 'Kiemelkedő közép'
                  : 'Sík, benne lévő közép',
              onChanged: controller.selectBottomNavLayoutStyle,
              keyPrefix: 'dashboard-bottom-nav-layout',
            ),
            _SummaryRadioGroup<DashboardBottomNavEdgeShape>(
              label: 'Felső szélek',
              value: settings.bottomNavEdgeShape,
              values: DashboardBottomNavEdgeShape.values,
              itemLabel: (value) => value == DashboardBottomNavEdgeShape.rounded
                  ? 'Kerekített'
                  : 'Egyenes',
              onChanged: controller.selectBottomNavEdgeShape,
              keyPrefix: 'dashboard-bottom-nav-edge-shape',
            ),
            _SummaryRadioGroup<DashboardBottomNavTopBorder>(
              label: 'Felső kontúr',
              value: settings.bottomNavTopBorder,
              values: DashboardBottomNavTopBorder.values,
              itemLabel: (value) => value == DashboardBottomNavTopBorder.off
                  ? 'Ki'
                  : 'Vékony szürke',
              onChanged: controller.selectBottomNavTopBorder,
              keyPrefix: 'dashboard-bottom-nav-top-border',
            ),
          ],
        ),
      );
}

/// One switch per independently rendered outer dashboard component. The
/// controller owns all state; switches only collect intent and never change
/// geometry, query or row semantics.
final class _DashboardBorderSection extends StatelessWidget {
  const _DashboardBorderSection({required this.controller});

  final DashboardBorderController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardBorderSettings>(
        valueListenable: controller,
        builder: (context, settings, _) => _TunerSection(
          title: 'Körvonalak',
          children: <Widget>[
            for (final surface in DashboardBorderSurface.values)
              SwitchListTile.adaptive(
                key: ValueKey<String>('dashboard-border-${surface.name}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_borderLabel(surface)),
                value: settings.isEnabled(surface),
                onChanged: (enabled) => controller.setEnabled(surface, enabled),
              ),
          ],
        ),
      );

  static String _borderLabel(DashboardBorderSurface surface) =>
      switch (surface) {
        DashboardBorderSurface.header => 'Header',
        DashboardBorderSurface.incomeDirection => 'Bevétel',
        DashboardBorderSurface.expenseDirection => 'Kiadás',
        DashboardBorderSurface.summary => 'Summary',
        DashboardBorderSurface.searchPill => 'Search',
        DashboardBorderSurface.balanceContent => 'Balance kártyák',
        DashboardBorderSurface.mindContent => 'Mind kártya',
        DashboardBorderSurface.budgetContent => 'Budget kártya',
        DashboardBorderSurface.logBoxGroup => 'LogBox',
      };
}

/// Compact source-palette selectors. The swatch is a visual preview only; the
/// resolved foreground is consumed once by the custom-paint surface binding.
final class _DashboardLogBoxAmountPaletteSection extends StatelessWidget {
  const _DashboardLogBoxAmountPaletteSection({required this.controller});

  final DashboardLogBoxAmountPaletteController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardLogBoxAmountPaletteSettings>(
        valueListenable: controller,
        builder: (context, settings, _) {
          final profile = DashboardLogBoxAmountPaletteProfile(settings);
          return _TunerSection(
            title: 'LogBox összegszínek',
            children: <Widget>[
              _AmountPaletteDropdown<DashboardLogBoxIncomePalette>(
                key: const ValueKey<String>('dashboard-logbox-income-palette'),
                label: 'Bevétel árnyalat',
                value: settings.income,
                color: profile.income,
                items: DashboardLogBoxIncomePalette.values,
                labelFor: _incomeLabel,
                colorFor: (value) => DashboardLogBoxAmountPaletteProfile(
                  settings.copyWith(income: value),
                ).income,
                onChanged: controller.selectIncome,
              ),
              const SizedBox(height: 8),
              _AmountPaletteDropdown<DashboardLogBoxExpensePalette>(
                key: const ValueKey<String>('dashboard-logbox-expense-palette'),
                label: 'Kiadás piros / pink',
                value: settings.expense,
                color: profile.expense,
                items: DashboardLogBoxExpensePalette.values,
                labelFor: _expenseLabel,
                colorFor: (value) => DashboardLogBoxAmountPaletteProfile(
                  settings.copyWith(expense: value),
                ).expense,
                onChanged: controller.selectExpense,
              ),
            ],
          );
        },
      );

  static String _incomeLabel(
    DashboardLogBoxIncomePalette value,
  ) => switch (value) {
    DashboardLogBoxIncomePalette.current => 'Jelenlegi',
    DashboardLogBoxIncomePalette.fluviCategoryGreen07 => 'Fluvi kategória 07',
    DashboardLogBoxIncomePalette.fluviCategoryGreen08 => 'Fluvi kategória 08',
    DashboardLogBoxIncomePalette.fluviCategoryGreen09 => 'Fluvi kategória 09',
    DashboardLogBoxIncomePalette.fluviCategoryGreen10 => 'Fluvi kategória 10',
    DashboardLogBoxIncomePalette.budgetReference => 'Budget referencia',
    DashboardLogBoxIncomePalette.balanceReference => 'Balance referencia',
  };

  static String _expenseLabel(
    DashboardLogBoxExpensePalette value,
  ) => switch (value) {
    DashboardLogBoxExpensePalette.current => 'Jelenlegi',
    DashboardLogBoxExpensePalette.fluviCategoryRed01 => 'Fluvi kategória 01',
    DashboardLogBoxExpensePalette.fluviCategoryPink20 => 'Fluvi kategória 20',
    DashboardLogBoxExpensePalette.fluviCategoryPink21 => 'Fluvi kategória 21',
    DashboardLogBoxExpensePalette.budgetReference => 'Budget referencia',
    DashboardLogBoxExpensePalette.balanceReference => 'Balance referencia',
  };
}

final class _AmountPaletteDropdown<T> extends StatelessWidget {
  const _AmountPaletteDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.items,
    required this.labelFor,
    required this.colorFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Color color;
  final List<T> items;
  final String Function(T value) labelFor;
  final Color Function(T value) colorFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${labelFor(value)}',
    child: Row(
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        DropdownButton<T>(
          value: value,
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          items: <DropdownMenuItem<T>>[
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorFor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(labelFor(item)),
                  ],
                ),
              ),
          ],
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

/// Connects one named tuner topic to the dashboard-lifetime collapse-state
/// owner. It does not own or mutate the visual setting rendered in [children].
final class _DashboardHeaderTunerTopic extends StatelessWidget {
  const _DashboardHeaderTunerTopic({
    super.key,
    required this.controller,
    required this.section,
    required this.title,
    required this.children,
  });

  final DashboardHeaderVisualController controller;
  final DashboardHeaderTunerSection section;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Set<DashboardHeaderTunerSection>>(
        valueListenable: controller.expandedTunerSections,
        builder: (context, expandedSections, child) => _CollapsibleTunerSection(
          title: title,
          expanded: expandedSections.contains(section),
          onToggle: () => controller.toggleTunerSection(section),
          children: children,
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
    this.suppressChildTunerHeading = true,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final bool suppressChildTunerHeading;

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
            child: _TunerSectionHeadingScope(
              hidesChildHeading: suppressChildTunerHeading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
      ],
    ),
  );
}
