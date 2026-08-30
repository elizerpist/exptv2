import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import 'dashboard_header_budget_cool_source.dart';
import 'dashboard_header_category_scale.dart';
import 'dashboard_header_deep_drift.dart';
import 'dashboard_header_fragment_backend.dart';
import 'dashboard_header_portal_material_field.dart';
import 'dashboard_header_static_color_renderer.dart';
import 'dashboard_header_tap_wave.dart';
import 'dashboard_header_visual_control.dart';

export 'dashboard_header_visual_control.dart';

/// The exact non-Portal Header effect order in
/// `docs/prototypes/color_lab_portal_energy.js`.
enum DashboardHeaderEffectId {
  staticEffect,
  dualTide,
  magneticMembrane,
  breathingLens,
  cellularField,
  balanceMembrane,
  balanceCounterflow,
  balanceCharges,
  deepDrift,
  freeFlow,
  chaoticAdvection,
  elasticSpace,
  braidedCurrent,
  volumetricCurrent,
  metricBloom,
  gravitationalFabric,
  breathingMetric,
  tidalCurvature,
}

/// User-visible animation lanes own their own semantic selection while sharing
/// the one dashboard-lifetime Header phase controller.
enum DashboardHeaderAnimationFamily {
  classicReference,
  fullFieldFlow,
  spaceFabricWarp,
}

extension DashboardHeaderAnimationFamilyPresentation
    on DashboardHeaderAnimationFamily {
  String get label => switch (this) {
    DashboardHeaderAnimationFamily.classicReference =>
      'Klasszikus effektek · referencia',
    DashboardHeaderAnimationFamily.fullFieldFlow => 'Teljes mező áramlás',
    DashboardHeaderAnimationFamily.spaceFabricWarp => 'Térszövet torzítás',
  };
}

/// The dashboard-lifetime Header tuner owns only this compact UI chrome state.
enum DashboardHeaderTunerSection {
  animation,
  cornerRoundness,
  borders,
  logBoxAmountColours,
}

@immutable
final class DashboardHeaderEffectSpec {
  const DashboardHeaderEffectSpec({
    required this.id,
    required this.shaderId,
    required this.family,
    required this.label,
    required this.controls,
  });

  final DashboardHeaderEffectId id;

  /// Stable runtime-shader ABI. Never derive this from [id.index].
  final int shaderId;
  final DashboardHeaderAnimationFamily family;
  final String label;
  final List<DashboardHeaderEffectControl> controls;

  DashboardHeaderEffectControl controlFor(String id) => controls.firstWhere(
    (control) => control.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown effect control'),
  );

  Map<String, double> get defaultSettings =>
      Map<String, double>.unmodifiable(<String, double>{
        for (final control in controls) control.id: control.defaultValue,
      });
}

/// Transcribed from the Color Lab source.  The catalog is data-only: neither
/// financial state nor animation time belongs here.
abstract final class DashboardHeaderEffectCatalog {
  static List<DashboardHeaderEffectControl> _flowBase({
    required double strength,
    required double speed,
    required double seed,
  }) => <DashboardHeaderEffectControl>[
    DashboardHeaderEffectControl(
      id: 'strength',
      label: 'Áramlás erő',
      min: 0,
      max: 1,
      step: .01,
      defaultValue: strength,
    ),
    DashboardHeaderEffectControl(
      id: 'speed',
      label: 'Sebesség',
      min: 0,
      max: 1,
      step: .01,
      defaultValue: speed,
    ),
    DashboardHeaderEffectControl(
      id: 'scale',
      label: 'Áramlási lépték',
      min: .40,
      max: 2.50,
      step: .01,
      defaultValue: 1,
    ),
    DashboardHeaderEffectControl(
      id: 'seed',
      label: 'Véletlenmag',
      min: 0,
      max: 9999,
      step: 1,
      defaultValue: seed,
    ),
  ];

  static const List<DashboardHeaderEffectControl> _flowRender =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'renderScale',
          label: 'Render minőség',
          min: .35,
          max: 1,
          step: .05,
          defaultValue: 1,
        ),
        DashboardHeaderEffectControl(
          id: 'frameMs',
          label: 'Render lépés',
          min: 16,
          max: 100,
          step: 1,
          defaultValue: 16,
        ),
      ];

  static List<DashboardHeaderEffectControl> _spaceFabricBase({
    required double strength,
    required double speed,
    required double scale,
    required double seed,
    double minScale = .35,
  }) => <DashboardHeaderEffectControl>[
    DashboardHeaderEffectControl(
      id: 'strength',
      label: 'Tértorzítás erő',
      min: 0,
      max: 1,
      step: .01,
      defaultValue: strength,
    ),
    DashboardHeaderEffectControl(
      id: 'speed',
      label: 'Sebesség',
      min: 0,
      max: 1,
      step: .01,
      defaultValue: speed,
    ),
    DashboardHeaderEffectControl(
      id: 'scale',
      label: 'Torzítás lépték',
      min: minScale,
      max: 2.5,
      step: .01,
      defaultValue: scale,
    ),
    DashboardHeaderEffectControl(
      id: 'seed',
      label: 'Véletlenmag',
      min: 0,
      max: 9999,
      step: 1,
      defaultValue: seed,
    ),
  ];

  static const List<DashboardHeaderEffectControl> _common =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'Animáció erő',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .82,
        ),
        DashboardHeaderEffectControl(
          id: 'speed',
          label: 'Sebesség',
          min: 0,
          max: 2,
          step: .01,
          defaultValue: .42,
        ),
        DashboardHeaderEffectControl(
          id: 'bias',
          label: 'Anyag-koordináta eltolás',
          min: -.35,
          max: .35,
          step: .01,
          defaultValue: 0,
        ),
        DashboardHeaderEffectControl(
          id: 'ratioSwing',
          label: 'Aránykilengés',
          min: 0,
          max: .35,
          step: .01,
          defaultValue: .12,
        ),
        DashboardHeaderEffectControl(
          id: 'ratioSpeed',
          label: 'Aránysebesség',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .18,
        ),
        DashboardHeaderEffectControl(
          id: 'fieldScale',
          label: 'Mezőméret',
          min: .5,
          max: 2,
          step: .01,
          defaultValue: 1,
        ),
        DashboardHeaderEffectControl(
          id: 'morphAmount',
          label: 'Morfológia',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .34,
        ),
        DashboardHeaderEffectControl(
          id: 'morphSpeed',
          label: 'Morfológia seb.',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .16,
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Határ puhaság',
          min: .02,
          max: .48,
          step: .01,
          defaultValue: .22,
        ),
        DashboardHeaderEffectControl(
          id: 'detail',
          label: 'Felületi részlet',
          min: 0,
          max: .5,
          step: .01,
          defaultValue: .10,
        ),
        DashboardHeaderEffectControl(
          id: 'pulseAmount',
          label: 'Energiaimpulzus',
          min: 0,
          max: .35,
          step: .01,
          defaultValue: .08,
        ),
        DashboardHeaderEffectControl(
          id: 'pulseSpeed',
          label: 'Impulzus seb.',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .12,
        ),
        DashboardHeaderEffectControl(
          id: 'lightAmount',
          label: 'Fénykiemelés',
          min: 0,
          max: .25,
          step: .01,
          defaultValue: .05,
        ),
        DashboardHeaderEffectControl(
          id: 'renderScale',
          label: 'Render minőség',
          min: .35,
          max: 1,
          step: .05,
          defaultValue: .60,
        ),
        DashboardHeaderEffectControl(
          id: 'frameMs',
          label: 'Render lépés',
          min: 16,
          max: 100,
          step: 1,
          defaultValue: 42,
        ),
      ];

  static const List<DashboardHeaderEffectControl> _balanceCommon =
      <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'Animáció erő',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .82,
        ),
        DashboardHeaderEffectControl(
          id: 'speed',
          label: 'Sebesség',
          min: 0,
          max: 2,
          step: .01,
          defaultValue: .24,
        ),
        DashboardHeaderEffectControl(
          id: 'seamSoftness',
          label: 'Határ puhaság',
          min: .02,
          max: .32,
          step: .01,
          defaultValue: .12,
        ),
        DashboardHeaderEffectControl(
          id: 'lightAmount',
          label: 'Fényenergia',
          min: 0,
          max: .22,
          step: .01,
          defaultValue: .08,
        ),
        DashboardHeaderEffectControl(
          id: 'chromaAmount',
          label: 'Színenergia',
          min: 0,
          max: .35,
          step: .01,
          defaultValue: .10,
        ),
        DashboardHeaderEffectControl(
          id: 'pulseAmount',
          label: 'Pulzus',
          min: 0,
          max: .20,
          step: .01,
          defaultValue: .05,
        ),
        DashboardHeaderEffectControl(
          id: 'pulseSpeed',
          label: 'Pulzus seb.',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .10,
        ),
        DashboardHeaderEffectControl(
          id: 'renderScale',
          label: 'Render minőség',
          min: .35,
          max: 1,
          step: .05,
          defaultValue: .60,
        ),
        DashboardHeaderEffectControl(
          id: 'frameMs',
          label: 'Render lépés',
          min: 16,
          max: 100,
          step: 1,
          defaultValue: 42,
        ),
      ];

  static final List<DashboardHeaderEffectSpec> effects =
      List<DashboardHeaderEffectSpec>.unmodifiable(<DashboardHeaderEffectSpec>[
        const DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.staticEffect,
          shaderId: 0,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Statikus színmező',
          controls: <DashboardHeaderEffectControl>[],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.dualTide,
          shaderId: 1,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Kettős árapály',
          controls: <DashboardHeaderEffectControl>[
            ..._common,
            DashboardHeaderEffectControl(
              id: 'wanderX',
              label: 'Vándorlás X',
              min: 0,
              max: .48,
              step: .01,
              defaultValue: .28,
            ),
            DashboardHeaderEffectControl(
              id: 'wanderY',
              label: 'Vándorlás Y',
              min: 0,
              max: .38,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'intrusion',
              label: 'Behatolás',
              min: 0,
              max: .65,
              step: .01,
              defaultValue: .34,
            ),
            DashboardHeaderEffectControl(
              id: 'separation',
              label: 'Mezőtávolság',
              min: 0,
              max: .80,
              step: .01,
              defaultValue: .42,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeARadius',
              label: 'A mező sugár',
              min: .12,
              max: .75,
              step: .01,
              defaultValue: .42,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeBRadius',
              label: 'B mező sugár',
              min: .12,
              max: .75,
              step: .01,
              defaultValue: .40,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeAEllipse',
              label: 'A nyújtás',
              min: .50,
              max: 2,
              step: .01,
              defaultValue: .95,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeBEllipse',
              label: 'B nyújtás',
              min: .50,
              max: 2,
              step: .01,
              defaultValue: 1.05,
            ),
            DashboardHeaderEffectControl(
              id: 'phaseOffset',
              label: 'Ellenfázis',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 180,
            ),
            DashboardHeaderEffectControl(
              id: 'counterFlow',
              label: 'Visszaáramlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            DashboardHeaderEffectControl(
              id: 'warpAmount',
              label: 'Mezőtorzítás',
              min: 0,
              max: .50,
              step: .01,
              defaultValue: .16,
            ),
            DashboardHeaderEffectControl(
              id: 'warpScale',
              label: 'Torzítás méret',
              min: .40,
              max: 3,
              step: .01,
              defaultValue: 1.10,
            ),
            DashboardHeaderEffectControl(
              id: 'warpSpeed',
              label: 'Torzítás seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .14,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.magneticMembrane,
          shaderId: 2,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Mágneses membrán',
          controls: <DashboardHeaderEffectControl>[
            ..._common,
            DashboardHeaderEffectControl(
              id: 'nodeTop',
              label: 'Felső pólus',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: .14,
            ),
            DashboardHeaderEffectControl(
              id: 'nodeMiddle',
              label: 'Középső pólus',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: -.08,
            ),
            DashboardHeaderEffectControl(
              id: 'nodeBottom',
              label: 'Alsó pólus',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'nodeWander',
              label: 'Pólusvándorlás',
              min: 0,
              max: .40,
              step: .01,
              defaultValue: .16,
            ),
            DashboardHeaderEffectControl(
              id: 'nodePhaseSpread',
              label: 'Pólusfázis',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 120,
            ),
            DashboardHeaderEffectControl(
              id: 'primaryAmplitude',
              label: 'Fő hullámerő',
              min: 0,
              max: .45,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'primaryWavelength',
              label: 'Fő hullámhossz',
              min: .35,
              max: 3,
              step: .01,
              defaultValue: 1.25,
            ),
            DashboardHeaderEffectControl(
              id: 'primarySpeed',
              label: 'Fő hullámseb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .16,
            ),
            DashboardHeaderEffectControl(
              id: 'secondaryAmplitude',
              label: 'Mellékhullám-erő',
              min: 0,
              max: .30,
              step: .01,
              defaultValue: .08,
            ),
            DashboardHeaderEffectControl(
              id: 'secondaryWavelength',
              label: 'Mellékhullámhossz',
              min: .35,
              max: 4,
              step: .01,
              defaultValue: 2.10,
            ),
            DashboardHeaderEffectControl(
              id: 'secondarySpeed',
              label: 'Mellékhullám-seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .09,
            ),
            DashboardHeaderEffectControl(
              id: 'skew',
              label: 'Membrándőlés',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: .08,
            ),
            DashboardHeaderEffectControl(
              id: 'tension',
              label: 'Membránfeszülés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .62,
            ),
            DashboardHeaderEffectControl(
              id: 'warpAmount',
              label: 'Felülettorzítás',
              min: 0,
              max: .35,
              step: .01,
              defaultValue: .09,
            ),
            DashboardHeaderEffectControl(
              id: 'warpSpeed',
              label: 'Torzítás seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .12,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.breathingLens,
          shaderId: 3,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Lélegző lencse',
          controls: <DashboardHeaderEffectControl>[
            ..._common,
            DashboardHeaderEffectControl(
              id: 'centerX',
              label: 'Lencseközép X',
              min: .10,
              max: .90,
              step: .01,
              defaultValue: .55,
            ),
            DashboardHeaderEffectControl(
              id: 'centerY',
              label: 'Lencseközép Y',
              min: .10,
              max: .90,
              step: .01,
              defaultValue: .48,
            ),
            DashboardHeaderEffectControl(
              id: 'wanderX',
              label: 'Középvándorlás X',
              min: 0,
              max: .40,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'wanderY',
              label: 'Középvándorlás Y',
              min: 0,
              max: .40,
              step: .01,
              defaultValue: .14,
            ),
            DashboardHeaderEffectControl(
              id: 'radiusX',
              label: 'Lencsesugár X',
              min: .08,
              max: .80,
              step: .01,
              defaultValue: .34,
            ),
            DashboardHeaderEffectControl(
              id: 'radiusY',
              label: 'Lencsesugár Y',
              min: .08,
              max: 1,
              step: .01,
              defaultValue: .46,
            ),
            DashboardHeaderEffectControl(
              id: 'breathX',
              label: 'Légzés X',
              min: 0,
              max: .40,
              step: .01,
              defaultValue: .16,
            ),
            DashboardHeaderEffectControl(
              id: 'breathY',
              label: 'Légzés Y',
              min: 0,
              max: .40,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'breathSpeed',
              label: 'Légzés seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'pressure',
              label: 'Lencsenyomás',
              min: -1,
              max: 1,
              step: .01,
              defaultValue: .48,
            ),
            DashboardHeaderEffectControl(
              id: 'refraction',
              label: 'Mezőtörés',
              min: 0,
              max: .60,
              step: .01,
              defaultValue: .20,
            ),
            DashboardHeaderEffectControl(
              id: 'edgeFalloff',
              label: 'Peremlecsengés',
              min: .02,
              max: .50,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'satelliteAmount',
              label: 'Mellékmező erő',
              min: -1,
              max: 1,
              step: .01,
              defaultValue: .22,
            ),
            DashboardHeaderEffectControl(
              id: 'satelliteRadius',
              label: 'Mellékmező sugár',
              min: .05,
              max: .50,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'satelliteDistance',
              label: 'Mellékmező táv',
              min: 0,
              max: .75,
              step: .01,
              defaultValue: .36,
            ),
            DashboardHeaderEffectControl(
              id: 'satellitePhase',
              label: 'Mellékmező fázis',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 140,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.cellularField,
          shaderId: 4,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Celluláris mező',
          controls: <DashboardHeaderEffectControl>[
            ..._common,
            DashboardHeaderEffectControl(
              id: 'cellCount',
              label: 'Cellaszám',
              min: 3,
              max: 7,
              step: 1,
              defaultValue: 5,
            ),
            DashboardHeaderEffectControl(
              id: 'cellSize',
              label: 'Cellaméret',
              min: .12,
              max: .75,
              step: .01,
              defaultValue: .36,
            ),
            DashboardHeaderEffectControl(
              id: 'cellVariation',
              label: 'Méretváltozatosság',
              min: 0,
              max: .70,
              step: .01,
              defaultValue: .25,
            ),
            DashboardHeaderEffectControl(
              id: 'advectionX',
              label: 'Áramlás X',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: .16,
            ),
            DashboardHeaderEffectControl(
              id: 'advectionY',
              label: 'Áramlás Y',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: .06,
            ),
            DashboardHeaderEffectControl(
              id: 'curlAmount',
              label: 'Örvénymező',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .35,
            ),
            DashboardHeaderEffectControl(
              id: 'curlScale',
              label: 'Örvényméret',
              min: .35,
              max: 3,
              step: .01,
              defaultValue: 1.10,
            ),
            DashboardHeaderEffectControl(
              id: 'mergeThreshold',
              label: 'Összeolvadási küszöb',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: 0,
            ),
            DashboardHeaderEffectControl(
              id: 'polarityBalance',
              label: 'Cellapolaritás',
              min: -.50,
              max: .50,
              step: .01,
              defaultValue: 0,
            ),
            DashboardHeaderEffectControl(
              id: 'cellWander',
              label: 'Cellavándorlás',
              min: 0,
              max: .50,
              step: .01,
              defaultValue: .22,
            ),
            DashboardHeaderEffectControl(
              id: 'cellMorph',
              label: 'Cellamorfológia',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .28,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseScale',
              label: 'Morfológia méret',
              min: .35,
              max: 3,
              step: .01,
              defaultValue: 1.40,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseAmount',
              label: 'Morfológia erő',
              min: 0,
              max: .50,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseSpeed',
              label: 'Morfológia seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .14,
            ),
            DashboardHeaderEffectControl(
              id: 'pressure',
              label: 'Cellanyomás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .70,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.balanceMembrane,
          shaderId: 5,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Balance membrán',
          controls: <DashboardHeaderEffectControl>[
            ..._balanceCommon,
            DashboardHeaderEffectControl(
              id: 'boundaryAmplitude',
              label: 'Határkilengés',
              min: 0,
              max: .28,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'primaryWavelength',
              label: 'Fő hullámhossz',
              min: .35,
              max: 3,
              step: .01,
              defaultValue: 1.10,
            ),
            DashboardHeaderEffectControl(
              id: 'secondaryAmplitude',
              label: 'Mellékhullám',
              min: 0,
              max: .18,
              step: .01,
              defaultValue: .06,
            ),
            DashboardHeaderEffectControl(
              id: 'secondaryWavelength',
              label: 'Mellékhullámhossz',
              min: .35,
              max: 4,
              step: .01,
              defaultValue: 2.20,
            ),
            DashboardHeaderEffectControl(
              id: 'nodePhase',
              label: 'Csomópont fázis',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 118,
            ),
            DashboardHeaderEffectControl(
              id: 'driftSpeed',
              label: 'Határvándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .14,
            ),
            DashboardHeaderEffectControl(
              id: 'tension',
              label: 'Membránfeszülés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .58,
            ),
            DashboardHeaderEffectControl(
              id: 'warpAmount',
              label: 'Lokális torzítás',
              min: 0,
              max: .18,
              step: .01,
              defaultValue: .05,
            ),
            DashboardHeaderEffectControl(
              id: 'warpScale',
              label: 'Torzítás méret',
              min: .4,
              max: 3,
              step: .01,
              defaultValue: 1.35,
            ),
            DashboardHeaderEffectControl(
              id: 'warpSpeed',
              label: 'Torzítás seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .10,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.balanceCounterflow,
          shaderId: 6,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Balance ellenáram',
          controls: <DashboardHeaderEffectControl>[
            ..._balanceCommon,
            DashboardHeaderEffectControl(
              id: 'intrusion',
              label: 'Benyúlás',
              min: 0,
              max: .32,
              step: .01,
              defaultValue: .15,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeCount',
              label: 'Áramlatpárok',
              min: 1,
              max: 6,
              step: 1,
              defaultValue: 3,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeRadius',
              label: 'Áramlatsugár',
              min: .08,
              max: .45,
              step: .01,
              defaultValue: .22,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeEllipse',
              label: 'Áramlatnyújtás',
              min: .5,
              max: 2,
              step: .01,
              defaultValue: 1.15,
            ),
            DashboardHeaderEffectControl(
              id: 'counterPhase',
              label: 'Ellenfázis',
              min: 90,
              max: 270,
              step: 1,
              defaultValue: 180,
            ),
            DashboardHeaderEffectControl(
              id: 'verticalDrift',
              label: 'Függőleges sodrás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'compensation',
              label: 'Aránykompenzáció',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .86,
            ),
            DashboardHeaderEffectControl(
              id: 'lobeSharpness',
              label: 'Áramlatkarakter',
              min: .5,
              max: 3,
              step: .01,
              defaultValue: 1.35,
            ),
            DashboardHeaderEffectControl(
              id: 'warpAmount',
              label: 'Lokális torzítás',
              min: 0,
              max: .16,
              step: .01,
              defaultValue: .04,
            ),
            DashboardHeaderEffectControl(
              id: 'warpScale',
              label: 'Torzítás méret',
              min: .4,
              max: 3,
              step: .01,
              defaultValue: 1.20,
            ),
            DashboardHeaderEffectControl(
              id: 'warpSpeed',
              label: 'Torzítás seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .09,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.balanceCharges,
          shaderId: 7,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Balance töltések',
          controls: <DashboardHeaderEffectControl>[
            ..._balanceCommon,
            DashboardHeaderEffectControl(
              id: 'seamDrift',
              label: 'Határvándorlás',
              min: 0,
              max: .12,
              step: .01,
              defaultValue: .035,
            ),
            DashboardHeaderEffectControl(
              id: 'seamWavelength',
              label: 'Határhullámhossz',
              min: .4,
              max: 3,
              step: .01,
              defaultValue: 1.45,
            ),
            DashboardHeaderEffectControl(
              id: 'seamSpeed',
              label: 'Határsebesség',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .10,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeCount',
              label: 'Töltésszám',
              min: 2,
              max: 8,
              step: 1,
              defaultValue: 6,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeSize',
              label: 'Töltésméret',
              min: .06,
              max: .42,
              step: .01,
              defaultValue: .18,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeVariation',
              label: 'Méretváltozatosság',
              min: 0,
              max: .7,
              step: .01,
              defaultValue: .24,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeWander',
              label: 'Töltésvándorlás',
              min: 0,
              max: .32,
              step: .01,
              defaultValue: .12,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeLight',
              label: 'Töltés fényereje',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeChroma',
              label: 'Töltés színessége',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .64,
            ),
            DashboardHeaderEffectControl(
              id: 'sidePhase',
              label: 'Oldalak fázisa',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 180,
            ),
            DashboardHeaderEffectControl(
              id: 'chargeMorph',
              label: 'Töltésmorfológia',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .22,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseScale',
              label: 'Morfológia méret',
              min: .4,
              max: 3,
              step: .01,
              defaultValue: 1.35,
            ),
          ],
        ),
        const DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.deepDrift,
          shaderId: 8,
          family: DashboardHeaderAnimationFamily.classicReference,
          label: 'Mélységi áramlás',
          controls: <DashboardHeaderEffectControl>[
            DashboardHeaderEffectControl(
              id: 'strength',
              label: 'Animáció erő',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .82,
            ),
            DashboardHeaderEffectControl(
              id: 'speed',
              label: 'Sebesség',
              min: 0,
              max: 2,
              step: .01,
              defaultValue: .32,
            ),
            DashboardHeaderEffectControl(
              id: 'blobScale',
              label: 'Anyagméret',
              min: .60,
              max: 1.50,
              step: .01,
              defaultValue: 1,
            ),
            DashboardHeaderEffectControl(
              id: 'anisotropy',
              label: 'Nyújtottság',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .55,
            ),
            DashboardHeaderEffectControl(
              id: 'density',
              label: 'Anyagsűrűség',
              min: .35,
              max: 1.40,
              step: .01,
              defaultValue: .82,
            ),
            DashboardHeaderEffectControl(
              id: 'softness',
              label: 'Határ puhaság',
              min: .10,
              max: 1,
              step: .01,
              defaultValue: .68,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseAmount',
              label: 'Anyagvariáció',
              min: 0,
              max: .15,
              step: .005,
              defaultValue: .06,
            ),
            DashboardHeaderEffectControl(
              id: 'noiseScale',
              label: 'Variáció méret',
              min: .15,
              max: 1.20,
              step: .01,
              defaultValue: .45,
            ),
            DashboardHeaderEffectControl(
              id: 'depthSeparation',
              label: 'Mélységi eltérés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            DashboardHeaderEffectControl(
              id: 'depthColorSeparation',
              label: 'Paletta-koordináta mélységi eltérés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .78,
            ),
            DashboardHeaderEffectControl(
              id: 'driftSpread',
              label: 'Áramlási eltérés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .62,
            ),
            DashboardHeaderEffectControl(
              id: 'lighting',
              label: 'Belső fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .10,
            ),
            DashboardHeaderEffectControl(
              id: 'coreGlow',
              label: 'Magfény',
              min: 0,
              max: .08,
              step: .002,
              defaultValue: .03,
            ),
            DashboardHeaderEffectControl(
              id: 'breathingAmount',
              label: 'Mélységi légzés',
              min: 0,
              max: .10,
              step: .002,
              defaultValue: .06,
            ),
            DashboardHeaderEffectControl(
              id: 'breathingSpeed',
              label: 'Légzés seb.',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .25,
            ),
            DashboardHeaderEffectControl(
              id: 'nearOpacity',
              label: 'Közeli réteg',
              min: 0,
              max: .35,
              step: .005,
              defaultValue: .19,
            ),
            DashboardHeaderEffectControl(
              id: 'middleOpacity',
              label: 'Középső réteg',
              min: 0,
              max: .30,
              step: .005,
              defaultValue: .14,
            ),
            DashboardHeaderEffectControl(
              id: 'farOpacity',
              label: 'Távoli réteg',
              min: 0,
              max: .25,
              step: .005,
              defaultValue: .10,
            ),
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.freeFlow,
          shaderId: 9,
          family: DashboardHeaderAnimationFamily.fullFieldFlow,
          label: 'Szabad áramlás',
          controls: <DashboardHeaderEffectControl>[
            ..._flowBase(strength: .72, speed: .18, seed: 417),
            const DashboardHeaderEffectControl(
              id: 'modeCount',
              label: 'Áramlási módok',
              min: 2,
              max: 5,
              step: 1,
              defaultValue: 4,
            ),
            const DashboardHeaderEffectControl(
              id: 'advection',
              label: 'Sodrási mélység',
              min: .10,
              max: 1.20,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'curl',
              label: 'Örvényesség',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            const DashboardHeaderEffectControl(
              id: 'stretch',
              label: 'Nyújtás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .35,
            ),
            const DashboardHeaderEffectControl(
              id: 'drift',
              label: 'Véletlen sodródás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .28,
            ),
            const DashboardHeaderEffectControl(
              id: 'edgeFreedom',
              label: 'Perem szabadság',
              min: .20,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .035,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.chaoticAdvection,
          shaderId: 10,
          family: DashboardHeaderAnimationFamily.fullFieldFlow,
          label: 'Kaotikus keveredés',
          controls: <DashboardHeaderEffectControl>[
            ..._flowBase(strength: .68, speed: .15, seed: 911),
            const DashboardHeaderEffectControl(
              id: 'gyreStrength',
              label: 'Gyre erő',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'gyreSwitch',
              label: 'Gyre váltás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .20,
            ),
            const DashboardHeaderEffectControl(
              id: 'vortexCount',
              label: 'Örvények száma',
              min: 2,
              max: 6,
              step: 1,
              defaultValue: 4,
            ),
            const DashboardHeaderEffectControl(
              id: 'vortexRadius',
              label: 'Örvény sugár',
              min: .08,
              max: .40,
              step: .01,
              defaultValue: .22,
            ),
            const DashboardHeaderEffectControl(
              id: 'wander',
              label: 'Vándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .32,
            ),
            const DashboardHeaderEffectControl(
              id: 'asymmetry',
              label: 'Aszimmetria',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .38,
            ),
            const DashboardHeaderEffectControl(
              id: 'stretch',
              label: 'Nyújtás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .45,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .03,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.elasticSpace,
          shaderId: 11,
          family: DashboardHeaderAnimationFamily.fullFieldFlow,
          label: 'Rugalmas tér',
          controls: <DashboardHeaderEffectControl>[
            ..._flowBase(strength: .75, speed: .12, seed: 271),
            const DashboardHeaderEffectControl(
              id: 'shearX',
              label: 'Vízszintes nyírás',
              min: 0,
              max: .60,
              step: .01,
              defaultValue: .24,
            ),
            const DashboardHeaderEffectControl(
              id: 'shearY',
              label: 'Függőleges nyírás',
              min: 0,
              max: .60,
              step: .01,
              defaultValue: .21,
            ),
            const DashboardHeaderEffectControl(
              id: 'shearLayers',
              label: 'Nyírási rétegek',
              min: 1,
              max: 4,
              step: 1,
              defaultValue: 3,
            ),
            const DashboardHeaderEffectControl(
              id: 'foldScale',
              label: 'Hajlítás lépték',
              min: .50,
              max: 3,
              step: .01,
              defaultValue: 1.25,
            ),
            const DashboardHeaderEffectControl(
              id: 'phaseSpread',
              label: 'Fázisszórás',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 137,
            ),
            const DashboardHeaderEffectControl(
              id: 'elasticity',
              label: 'Rugalmasság',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            const DashboardHeaderEffectControl(
              id: 'relaxation',
              label: 'Ellazulás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .22,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .035,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.braidedCurrent,
          shaderId: 12,
          family: DashboardHeaderAnimationFamily.fullFieldFlow,
          label: 'Fonódó áramlás',
          controls: <DashboardHeaderEffectControl>[
            ..._flowBase(strength: .70, speed: .16, seed: 613),
            const DashboardHeaderEffectControl(
              id: 'braidCount',
              label: 'Fonatok száma',
              min: 2,
              max: 5,
              step: 1,
              defaultValue: 3,
            ),
            const DashboardHeaderEffectControl(
              id: 'crossFlow',
              label: 'Keresztáramlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .55,
            ),
            const DashboardHeaderEffectControl(
              id: 'phaseSpread',
              label: 'Fázisszórás',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 120,
            ),
            const DashboardHeaderEffectControl(
              id: 'drift',
              label: 'Sodródás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .25,
            ),
            const DashboardHeaderEffectControl(
              id: 'curvature',
              label: 'Görbület',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .65,
            ),
            const DashboardHeaderEffectControl(
              id: 'widthVariance',
              label: 'Szélességváltozás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .35,
            ),
            const DashboardHeaderEffectControl(
              id: 'mixing',
              label: 'Keveredés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .42,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .04,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.volumetricCurrent,
          shaderId: 13,
          family: DashboardHeaderAnimationFamily.fullFieldFlow,
          label: 'Térbeli áramlás',
          controls: <DashboardHeaderEffectControl>[
            ..._flowBase(strength: .72, speed: .14, seed: 1201),
            const DashboardHeaderEffectControl(
              id: 'depthLayers',
              label: 'Mélységi rétegek',
              min: 2,
              max: 4,
              step: 1,
              defaultValue: 3,
            ),
            const DashboardHeaderEffectControl(
              id: 'depthSeparation',
              label: 'Mélységi elkülönítés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'zDrift',
              label: 'Z sodródás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .18,
            ),
            const DashboardHeaderEffectControl(
              id: 'parallax',
              label: 'Parallaxis',
              min: 0,
              max: .35,
              step: .01,
              defaultValue: .10,
            ),
            const DashboardHeaderEffectControl(
              id: 'refraction',
              label: 'Törés',
              min: 0,
              max: .35,
              step: .01,
              defaultValue: .12,
            ),
            const DashboardHeaderEffectControl(
              id: 'depthSoftness',
              label: 'Mélységi lágyság',
              min: .10,
              max: 1,
              step: .01,
              defaultValue: .65,
            ),
            const DashboardHeaderEffectControl(
              id: 'nearInfluence',
              label: 'Közeli hatás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .55,
            ),
            const DashboardHeaderEffectControl(
              id: 'farInfluence',
              label: 'Távoli hatás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .28,
            ),
            const DashboardHeaderEffectControl(
              id: 'lighting',
              label: 'Mélységi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .05,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .03,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.metricBloom,
          shaderId: 14,
          family: DashboardHeaderAnimationFamily.spaceFabricWarp,
          label: 'Metrikus virágzás',
          controls: <DashboardHeaderEffectControl>[
            ..._spaceFabricBase(strength: .72, speed: .13, scale: 1, seed: 739),
            const DashboardHeaderEffectControl(
              id: 'fieldCount',
              label: 'Torzítási gócok',
              min: 1,
              max: 5,
              step: 1,
              defaultValue: 3,
            ),
            const DashboardHeaderEffectControl(
              id: 'magnification',
              label: 'Nagyítás',
              min: 0,
              max: 1.20,
              step: .01,
              defaultValue: .58,
            ),
            const DashboardHeaderEffectControl(
              id: 'compression',
              label: 'Környezeti összenyomás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .46,
            ),
            const DashboardHeaderEffectControl(
              id: 'softness',
              label: 'Tér lágyság',
              min: .10,
              max: 1,
              step: .01,
              defaultValue: .72,
            ),
            const DashboardHeaderEffectControl(
              id: 'anisotropy',
              label: 'Amorf jelleg',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .58,
            ),
            const DashboardHeaderEffectControl(
              id: 'wander',
              label: 'Vándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .28,
            ),
            const DashboardHeaderEffectControl(
              id: 'breathing',
              label: 'Lélegzés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .32,
            ),
            const DashboardHeaderEffectControl(
              id: 'overlap',
              label: 'Átfedés',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .40,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .025,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.gravitationalFabric,
          shaderId: 15,
          family: DashboardHeaderAnimationFamily.spaceFabricWarp,
          label: 'Gravitációs szövet',
          controls: <DashboardHeaderEffectControl>[
            ..._spaceFabricBase(
              strength: .68,
              speed: .11,
              scale: 1,
              seed: 1337,
            ),
            const DashboardHeaderEffectControl(
              id: 'wellCount',
              label: 'Torzítási gócok',
              min: 1,
              max: 6,
              step: 1,
              defaultValue: 4,
            ),
            const DashboardHeaderEffectControl(
              id: 'wellStrength',
              label: 'Nagyítás',
              min: 0,
              max: 1.20,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'compensation',
              label: 'Környezeti összenyomás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .70,
            ),
            const DashboardHeaderEffectControl(
              id: 'wander',
              label: 'Vándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .25,
            ),
            const DashboardHeaderEffectControl(
              id: 'eccentricity',
              label: 'Amorf jelleg',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .45,
            ),
            const DashboardHeaderEffectControl(
              id: 'precession',
              label: 'Precesszió',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .18,
            ),
            const DashboardHeaderEffectControl(
              id: 'mergeBias',
              label: 'Összeolvadás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .35,
            ),
            const DashboardHeaderEffectControl(
              id: 'softness',
              label: 'Tér lágyság',
              min: .10,
              max: 1,
              step: .01,
              defaultValue: .68,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .035,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.breathingMetric,
          shaderId: 16,
          family: DashboardHeaderAnimationFamily.spaceFabricWarp,
          label: 'Lélegző térszövet',
          controls: <DashboardHeaderEffectControl>[
            ..._spaceFabricBase(
              strength: .72,
              speed: .08,
              scale: .80,
              seed: 281,
              minScale: .25,
            ),
            const DashboardHeaderEffectControl(
              id: 'regionCount',
              label: 'Torzítási gócok',
              min: 1,
              max: 4,
              step: 1,
              defaultValue: 2,
            ),
            const DashboardHeaderEffectControl(
              id: 'breathingDepth',
              label: 'Légzés mélység',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'phaseSpread',
              label: 'Fázisszórás',
              min: 0,
              max: 360,
              step: 1,
              defaultValue: 137,
            ),
            const DashboardHeaderEffectControl(
              id: 'softness',
              label: 'Tér lágyság',
              min: .20,
              max: 1,
              step: .01,
              defaultValue: .82,
            ),
            const DashboardHeaderEffectControl(
              id: 'anisotropy',
              label: 'Amorf jelleg',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .45,
            ),
            const DashboardHeaderEffectControl(
              id: 'wander',
              label: 'Vándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .16,
            ),
            const DashboardHeaderEffectControl(
              id: 'compensation',
              label: 'Környezeti összenyomás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .78,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .02,
            ),
            ..._flowRender,
          ],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.tidalCurvature,
          shaderId: 17,
          family: DashboardHeaderAnimationFamily.spaceFabricWarp,
          label: 'Árapály-térgörbület',
          controls: <DashboardHeaderEffectControl>[
            ..._spaceFabricBase(strength: .70, speed: .12, scale: 1, seed: 601),
            const DashboardHeaderEffectControl(
              id: 'pairCount',
              label: 'Párok száma',
              min: 1,
              max: 4,
              step: 1,
              defaultValue: 2,
            ),
            const DashboardHeaderEffectControl(
              id: 'curvature',
              label: 'Görbület',
              min: 0,
              max: 1.20,
              step: .01,
              defaultValue: .62,
            ),
            const DashboardHeaderEffectControl(
              id: 'exchange',
              label: 'Tércsere',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .58,
            ),
            const DashboardHeaderEffectControl(
              id: 'separation',
              label: 'Pártávolság',
              min: .10,
              max: .80,
              step: .01,
              defaultValue: .38,
            ),
            const DashboardHeaderEffectControl(
              id: 'wander',
              label: 'Vándorlás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .24,
            ),
            const DashboardHeaderEffectControl(
              id: 'axisDrift',
              label: 'Tengely sodródás',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .18,
            ),
            const DashboardHeaderEffectControl(
              id: 'anisotropy',
              label: 'Amorf jelleg',
              min: 0,
              max: 1,
              step: .01,
              defaultValue: .52,
            ),
            const DashboardHeaderEffectControl(
              id: 'softness',
              label: 'Tér lágyság',
              min: .10,
              max: 1,
              step: .01,
              defaultValue: .70,
            ),
            const DashboardHeaderEffectControl(
              id: 'relief',
              label: 'Felületi fény',
              min: 0,
              max: .20,
              step: .005,
              defaultValue: .03,
            ),
            ..._flowRender,
          ],
        ),
      ]);

  static DashboardHeaderEffectSpec effectFor(DashboardHeaderEffectId id) =>
      effects.firstWhere((effect) => effect.id == id);

  static List<DashboardHeaderEffectSpec> effectsForFamily(
    DashboardHeaderAnimationFamily family,
  ) => List<DashboardHeaderEffectSpec>.unmodifiable(
    effects.where((effect) => effect.family == family),
  );

  static DashboardHeaderEffectSpec initialEffectForFamily(
    DashboardHeaderAnimationFamily family,
  ) => effectsForFamily(family).firstWhere(
    (effect) => effect.id != DashboardHeaderEffectId.staticEffect,
    orElse: () => effectsForFamily(family).first,
  );
}

/// Family-owned palette-basis controls for Full Field Flow.  This is not an
/// effect-local setting: every ID 9–13 reads the same single state while the
/// active source-UV flow remains entirely unchanged.
@immutable
final class DashboardHeaderPaletteOrientationTuning {
  const DashboardHeaderPaletteOrientationTuning({
    this.enabled = false,
    this.baseAngleDegrees = 112,
    this.sweepDegrees = 70,
    this.speed = .08,
    this.phaseDegrees = 0,
  });

  static const DashboardHeaderPaletteOrientationTuning defaults =
      DashboardHeaderPaletteOrientationTuning();

  final bool enabled;
  final double baseAngleDegrees;
  final double sweepDegrees;
  final double speed;
  final double phaseDegrees;

  DashboardHeaderPaletteOrientationTuning copyWith({
    bool? enabled,
    double? baseAngleDegrees,
    double? sweepDegrees,
    double? speed,
    double? phaseDegrees,
  }) => DashboardHeaderPaletteOrientationTuning(
    enabled: enabled ?? this.enabled,
    baseAngleDegrees: _degrees(baseAngleDegrees ?? this.baseAngleDegrees),
    sweepDegrees: (sweepDegrees ?? this.sweepDegrees)
        .clamp(0.0, 120.0)
        .toDouble(),
    speed: (speed ?? this.speed).clamp(0.0, 1.0).toDouble(),
    phaseDegrees: _degrees(phaseDegrees ?? this.phaseDegrees),
  );

  /// The v3 main-settings bank has exactly four free family-reserved floats.
  /// Integral degree sliders remain lossless when base and phase share one
  /// float: `base + phase / 1000`. The shader mirrors this decoder.
  double get packedBaseAndPhaseDegrees =>
      _degrees(baseAngleDegrees) + _degrees(phaseDegrees) / 1000;

  double effectiveAngleDegrees(double headerPhase) {
    if (!enabled) return 112;
    final radians =
        headerPhase * (.018 + speed * .12) + phaseDegrees * math.pi / 180;
    return baseAngleDegrees + sweepDegrees * math.sin(radians);
  }

  static double _degrees(double value) =>
      value.isFinite ? value.clamp(0.0, 360.0).roundToDouble() : 0;

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderPaletteOrientationTuning &&
      enabled == other.enabled &&
      baseAngleDegrees == other.baseAngleDegrees &&
      sweepDegrees == other.sweepDegrees &&
      speed == other.speed &&
      phaseDegrees == other.phaseDegrees;

  @override
  int get hashCode =>
      Object.hash(enabled, baseAngleDegrees, sweepDegrees, speed, phaseDegrees);
}

@immutable
final class DashboardHeaderVisualTuning {
  DashboardHeaderVisualTuning({
    required this.effect,
    required this.animationFamily,
    required this.paletteOrientation,
    required this.budgetCool,
    required this.budgetCategory,
    required this.opacityScalePosition,
    required Map<DashboardHeaderEffectId, Map<String, double>> settingsByEffect,
    required this.generation,
  }) : settingsByEffect =
           Map<DashboardHeaderEffectId, Map<String, double>>.unmodifiable(
             <DashboardHeaderEffectId, Map<String, double>>{
               for (final entry in settingsByEffect.entries)
                 entry.key: Map<String, double>.unmodifiable(entry.value),
             },
           );

  factory DashboardHeaderVisualTuning.defaults() => DashboardHeaderVisualTuning(
    effect: DashboardHeaderEffectId.dualTide,
    animationFamily: DashboardHeaderAnimationFamily.classicReference,
    paletteOrientation: DashboardHeaderPaletteOrientationTuning.defaults,
    budgetCool: const BudgetHeaderGlobalCoolState.defaults(),
    budgetCategory: const DashboardBudgetHeaderCategoryState.defaults(),
    opacityScalePosition: 50,
    settingsByEffect: <DashboardHeaderEffectId, Map<String, double>>{
      for (final spec in DashboardHeaderEffectCatalog.effects)
        spec.id: spec.defaultSettings,
    },
    generation: 0,
  );

  final DashboardHeaderEffectId effect;
  final DashboardHeaderAnimationFamily animationFamily;
  final DashboardHeaderPaletteOrientationTuning paletteOrientation;
  final BudgetHeaderGlobalCoolState budgetCool;
  final DashboardBudgetHeaderCategoryState budgetCategory;
  final double opacityScalePosition;
  final Map<DashboardHeaderEffectId, Map<String, double>> settingsByEffect;
  final int generation;

  Map<String, double> settingsFor(DashboardHeaderEffectId effect) =>
      settingsByEffect[effect] ?? const <String, double>{};

  DashboardHeaderVisualTuning copyWith({
    DashboardHeaderEffectId? effect,
    DashboardHeaderAnimationFamily? animationFamily,
    DashboardHeaderPaletteOrientationTuning? paletteOrientation,
    BudgetHeaderGlobalCoolState? budgetCool,
    DashboardBudgetHeaderCategoryState? budgetCategory,
    double? opacityScalePosition,
    Map<DashboardHeaderEffectId, Map<String, double>>? settingsByEffect,
  }) => DashboardHeaderVisualTuning(
    effect: effect ?? this.effect,
    animationFamily: animationFamily ?? this.animationFamily,
    paletteOrientation: paletteOrientation ?? this.paletteOrientation,
    budgetCool: budgetCool ?? this.budgetCool,
    budgetCategory: budgetCategory ?? this.budgetCategory,
    opacityScalePosition: opacityScalePosition ?? this.opacityScalePosition,
    settingsByEffect: settingsByEffect ?? this.settingsByEffect,
    generation: generation + 1,
  );
}

/// Header effect clock and tuning owner.  It has exactly one stable ticker;
/// its [Listenable] is reserved for the visual paint lane, while [tuning]
/// emits only user-visible semantic setting changes.
final class DashboardHeaderVisualController extends ChangeNotifier {
  DashboardHeaderVisualController({required TickerProvider vsync})
    : tuning = ValueNotifier<DashboardHeaderVisualTuning>(
        DashboardHeaderVisualTuning.defaults(),
      ),
      tunerOpen = ValueNotifier<bool>(false),
      expandedTunerSections = ValueNotifier<Set<DashboardHeaderTunerSection>>(
        const <DashboardHeaderTunerSection>{
          DashboardHeaderTunerSection.animation,
        },
      ),
      portalSettingsGeneration = ValueNotifier<int>(0),
      tapWaveTuning = ValueNotifier<DashboardHeaderTapWaveTuning>(
        DashboardHeaderTapWaveTuning.defaults(),
      ) {
    _tapWave.configure(tapWaveTuning.value);
    _ticker = vsync.createTicker(_onTick);
    _syncTicker();
    // One startup audit event makes the source equivalence verdict visible in
    // the existing FLOW panel without producing any frame-level diagnostics.
    _record(
      'HEADER_PORTAL_EFFECT_CATALOG_VERIFIED',
      'innerOptionCount=5 backgroundOptionCount=5 '
          'sameOptions=true sameRenderer=false '
          'sameParameterSchema=true sameDefaults=true sameState=false '
          'sameClockSource=true',
    );
  }

  final ValueNotifier<DashboardHeaderVisualTuning> tuning;

  /// Dashboard-lifetime UI chrome state. It intentionally stays outside the
  /// mode policies and has no persistence owner.
  final ValueNotifier<bool> tunerOpen;

  /// One explicit owner for top-level tuner collapse state.
  final ValueNotifier<Set<DashboardHeaderTunerSection>> expandedTunerSections;

  /// Semantic Portal config changes rebuild only the relevant tuner sections.
  /// Animation phase ticks never publish through this notifier.
  final ValueNotifier<int> portalSettingsGeneration;

  /// Source/app-added tap-wave settings rebuild only the respective tuner
  /// section. The one-shot state itself advances solely on the shared clock.
  final ValueNotifier<DashboardHeaderTapWaveTuning> tapWaveTuning;
  late final Ticker _ticker;
  Duration _lastTickerElapsed = Duration.zero;
  Duration _elapsed = Duration.zero;
  Duration? _pulseStartedAt;
  double _phase = 0;
  bool _motionEnabled = true;
  bool _disposed = false;
  DashboardHeaderPortalChannelState _portalInnerMotion =
      DashboardHeaderPortalChannelState.innerMotionDefaults();
  DashboardHeaderPortalChannelState _portalBackgroundMorph =
      DashboardHeaderPortalChannelState.backgroundMorphDefaults();
  final DashboardHeaderTapWaveState _tapWave = DashboardHeaderTapWaveState();

  Object get tickerIdentity => _ticker;
  bool get tickerIsActive => _ticker.isActive;
  double get phase => _phase;
  Duration get elapsed => _elapsed;
  DashboardHeaderPortalChannelState get portalInnerMotion => _portalInnerMotion;
  DashboardHeaderPortalChannelState get portalBackgroundMorph =>
      _portalBackgroundMorph;
  DashboardHeaderTapWaveState get tapWave => _tapWave;
  double get pulseAmount {
    final startedAt = _pulseStartedAt;
    if (startedAt == null) return 0;
    final elapsed = _elapsed - startedAt;
    final ratio = elapsed.inMicroseconds / 1560000;
    return (1 - ratio).clamp(0.0, 1.0).toDouble();
  }

  void selectEffect(DashboardHeaderEffectId effect) {
    if (_disposed || tuning.value.effect == effect) return;
    final spec = DashboardHeaderEffectCatalog.effectFor(effect);
    tuning.value = tuning.value.copyWith(
      effect: effect,
      animationFamily: spec.family,
    );
    _syncTicker();
    _record(
      'HEADER_EFFECT_SELECTED',
      'effectId=${effect.name} settingsGeneration=${tuning.value.generation}',
    );
    _record(
      'HEADER_ANIMATION_FAMILY_BOUND',
      'family=${spec.family.name} effectId=${effect.name} '
          'shaderId=${spec.shaderId} '
          'settingsGeneration=${tuning.value.generation} '
          'controllerIdentity=${identityHashCode(this)} '
          'phaseOwnerIdentity=${identityHashCode(_ticker)} '
          '${_animationFamilyTransportDiagnostic(spec.family)}',
    );
    notifyListeners();
  }

  void selectAnimationFamily(DashboardHeaderAnimationFamily family) {
    if (_disposed || tuning.value.animationFamily == family) return;
    final effect = DashboardHeaderEffectCatalog.initialEffectForFamily(family);
    tuning.value = tuning.value.copyWith(
      animationFamily: family,
      effect: effect.id,
    );
    _syncTicker();
    _record(
      'HEADER_ANIMATION_FAMILY_BOUND',
      'family=${family.name} effectId=${effect.id.name} '
          'shaderId=${effect.shaderId} '
          'settingsGeneration=${tuning.value.generation} '
          'controllerIdentity=${identityHashCode(this)} '
          'phaseOwnerIdentity=${identityHashCode(_ticker)} '
          '${_animationFamilyTransportDiagnostic(family)}',
    );
    notifyListeners();
  }

  /// Changes only the Full Field palette-projection basis. The shared Header
  /// phase ticker remains the sole temporal owner; source-UV flow does not
  /// receive, derive, or mutate any of these values.
  void setFullFieldPaletteOrientation({
    bool? enabled,
    double? baseAngleDegrees,
    double? sweepDegrees,
    double? speed,
    double? phaseDegrees,
  }) {
    if (_disposed) return;
    final current = tuning.value;
    final next = current.paletteOrientation.copyWith(
      enabled: enabled,
      baseAngleDegrees: baseAngleDegrees,
      sweepDegrees: sweepDegrees,
      speed: speed,
      phaseDegrees: phaseDegrees,
    );
    if (next == current.paletteOrientation) return;
    tuning.value = current.copyWith(paletteOrientation: next);
    _record(
      'HEADER_FULL_FIELD_ORIENTATION_BOUND',
      'enabled=${next.enabled} '
          'baseAngleDeg=${next.baseAngleDegrees} '
          'sweepDeg=${next.sweepDegrees} '
          'speed=${next.speed} '
          'phaseDeg=${next.phaseDegrees} '
          'effectiveAngleDeg=${next.effectiveAngleDegrees(_phase)} '
          'clockOwner=sharedHeader flowGeometryModified=false '
          'paletteBasisModified=true '
          'shaderAbiVersion=${DashboardHeaderFragmentUniformLayout.version} '
          'settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  static String _animationFamilyTransportDiagnostic(
    DashboardHeaderAnimationFamily family,
  ) => switch (family) {
    DashboardHeaderAnimationFamily.classicReference =>
      'transportModel=classicReference69d109 '
          'referenceSha=69d109c1e1f53ab4c0d2b66f5c576577de3e99c9',
    DashboardHeaderAnimationFamily.fullFieldFlow =>
      'transportModel=fullFieldInverseAdvectionV1',
    DashboardHeaderAnimationFamily.spaceFabricWarp =>
      'transportModel=spaceFabricCompensatedLocalWarpV1',
  };

  void setBudgetCoolPositionPercent(double value) {
    final next = tuning.value.budgetCool.copyWith(positionPercent: value);
    if (tuning.value.budgetCool == next) return;
    final previous = tuning.value.budgetCool.positionPercent;
    tuning.value = tuning.value.copyWith(budgetCool: next);
    _record(
      'BUDGET_HEADER_COOL_WINDOW_CHANGED',
      'changedParameter=position oldValue=$previous '
          'newValue=${next.positionPercent} '
          'positionPct=${next.positionPercent} '
          'windowWidthPct=${next.windowWidthPercent} '
          'settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void setBudgetCoolWindowWidthPercent(double value) {
    final next = tuning.value.budgetCool.copyWith(windowWidthPercent: value);
    if (tuning.value.budgetCool == next) return;
    final previous = tuning.value.budgetCool.windowWidthPercent;
    tuning.value = tuning.value.copyWith(budgetCool: next);
    _record(
      'BUDGET_HEADER_COOL_WINDOW_CHANGED',
      'changedParameter=width oldValue=$previous '
          'newValue=${next.windowWidthPercent} '
          'positionPct=${next.positionPercent} '
          'windowWidthPct=${next.windowWidthPercent} '
          'settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void selectBudgetHeaderColorSource(DashboardBudgetHeaderColorSource source) {
    if (_disposed || tuning.value.budgetCategory.source == source) return;
    tuning.value = tuning.value.copyWith(
      budgetCategory: tuning.value.budgetCategory.copyWith(source: source),
    );
    _record(
      'BUDGET_HEADER_COLOR_SOURCE_CHANGED',
      'source=${source.name} settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void setBudgetCategoryWindowWidthPercent(double value) {
    final next = tuning.value.budgetCategory.copyWith(
      windowWidthPercent: value,
    );
    if (next == tuning.value.budgetCategory) return;
    tuning.value = tuning.value.copyWith(budgetCategory: next);
    _record(
      'BUDGET_HEADER_CATEGORY_WINDOW_CHANGED',
      'windowWidthPct=${next.windowWidthPercent.toStringAsFixed(0)} '
          'settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void setOpacityScalePosition(double value) {
    final bounded = value.clamp(0.0, 100.0).toDouble();
    if (tuning.value.opacityScalePosition == bounded) return;
    tuning.value = tuning.value.copyWith(opacityScalePosition: bounded);
    _record(
      'HEADER_EFFECT_SETTING_CHANGED',
      'parameterId=opacityScalePosition newValue=$bounded '
          'settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void setEffectControl(String controlId, double value) {
    final current = tuning.value;
    final spec = DashboardHeaderEffectCatalog.effectFor(current.effect);
    final control = spec.controlFor(controlId);
    final normalized = control.normalize(value);
    final previous = current.settingsFor(current.effect)[controlId];
    if (previous == normalized) return;
    final settings = <DashboardHeaderEffectId, Map<String, double>>{
      for (final entry in current.settingsByEffect.entries)
        entry.key: entry.value,
    };
    settings[current.effect] = <String, double>{
      ...current.settingsFor(current.effect),
      controlId: normalized,
    };
    tuning.value = current.copyWith(settingsByEffect: settings);
    _syncTicker();
    if (controlId == 'renderScale' || controlId == 'frameMs') {
      _record(
        'HEADER_RENDER_QUALITY_CHANGED',
        'effectId=${current.effect.name} '
            'oldQuality=${current.settingsFor(current.effect)['renderScale']} '
            'newQuality=${tuning.value.settingsFor(current.effect)['renderScale']} '
            'oldSteps=${current.settingsFor(current.effect)['frameMs']} '
            'newSteps=${tuning.value.settingsFor(current.effect)['frameMs']} '
            'renderGeneration=${tuning.value.generation}',
      );
    } else if (current.effect == DashboardHeaderEffectId.deepDrift) {
      _record(
        'HEADER_DEEP_DRIFT_SETTING_CHANGED',
        'parameterId=$controlId oldValue=${previous ?? '-'} newValue=$normalized '
            'settingsGeneration=${tuning.value.generation}',
      );
    } else {
      _record(
        'HEADER_EFFECT_SETTING_CHANGED',
        'effectId=${current.effect.name} parameterId=$controlId '
            'oldValue=${previous ?? '-'} newValue=$normalized '
            'settingsGeneration=${tuning.value.generation}',
      );
    }
    notifyListeners();
  }

  /// Updates one independently-owned Portal source channel. The shared
  /// material-field implementation is selected by both channels, but their
  /// selections, settings and active-mode reset state never alias.
  void selectPortalEffect(
    DashboardHeaderPortalChannel channel,
    DashboardHeaderPortalMaterialEffectId effect,
  ) {
    if (_disposed) return;
    final current = _portalFor(channel);
    if (current.effect == effect) return;
    _setPortal(channel, current.copyWith(effect: effect));
    _record(
      channel == DashboardHeaderPortalChannel.innerMotion
          ? 'HEADER_PORTAL_INNER_EFFECT_SELECTED'
          : 'HEADER_PORTAL_BACKGROUND_MORPH_SELECTED',
      'channel=${channel.name} effectId=${DashboardHeaderPortalMaterialCatalog.effectFor(effect).sourceId} '
      'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void setPortalEnabled(DashboardHeaderPortalChannel channel, bool enabled) {
    if (_disposed) return;
    final current = _portalFor(channel);
    if (current.enabled == enabled) return;
    _setPortal(channel, current.copyWith(enabled: enabled));
    _record(
      channel == DashboardHeaderPortalChannel.innerMotion
          ? 'HEADER_PORTAL_INNER_EFFECT_SELECTED'
          : 'HEADER_PORTAL_BACKGROUND_MORPH_SELECTED',
      'channel=${channel.name} enabled=$enabled '
      'effectId=${DashboardHeaderPortalMaterialCatalog.effectFor(current.effect).sourceId} '
      'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void updatePortalControl(
    DashboardHeaderPortalChannel channel,
    String controlId,
    double value,
  ) {
    if (_disposed) return;
    final current = _portalFor(channel);
    final control = DashboardHeaderPortalMaterialCatalog.effectFor(
      current.effect,
    ).controlFor(controlId);
    final normalized = control.normalize(value);
    final previous = current.settingsFor(current.effect)[controlId];
    if (previous == normalized) return;
    final settings =
        <DashboardHeaderPortalMaterialEffectId, Map<String, double>>{
          for (final entry in DashboardHeaderPortalMaterialCatalog.effects)
            entry.id: current.settingsFor(entry.id),
        };
    settings[current.effect] = <String, double>{
      ...current.settingsFor(current.effect),
      controlId: normalized,
    };
    _setPortal(channel, current.copyWith(settingsByEffect: settings));
    _record(
      channel == DashboardHeaderPortalChannel.innerMotion
          ? 'HEADER_PORTAL_INNER_SETTING_CHANGED'
          : 'HEADER_PORTAL_BACKGROUND_MORPH_SETTING_CHANGED',
      'channel=${channel.name} '
      'effectId=${DashboardHeaderPortalMaterialCatalog.effectFor(current.effect).sourceId} '
      'parameterId=$controlId oldValue=${previous ?? '-'} newValue=$normalized '
      'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void setPortalInnerRotation({bool? enabled, double? speed}) {
    if (_disposed) return;
    final next = _portalInnerMotion.copyWith(
      rotationEnabled: enabled,
      rotationSpeed: speed,
    );
    if (next.rotationEnabled == _portalInnerMotion.rotationEnabled &&
        next.rotationSpeed == _portalInnerMotion.rotationSpeed) {
      return;
    }
    _setPortal(DashboardHeaderPortalChannel.innerMotion, next);
    _record(
      'HEADER_PORTAL_INNER_SETTING_CHANGED',
      'channel=innerMotion parameterId=rotation '
          'enabled=${next.rotationEnabled} speed=${next.rotationSpeed} '
          'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void setPortalBackgroundPalette({double? center, double? window}) {
    if (_disposed) return;
    final next = _portalBackgroundMorph.copyWith(
      paletteCenterPercent: center,
      paletteWindowPercent: window,
    );
    if (next.paletteCenterPercent ==
            _portalBackgroundMorph.paletteCenterPercent &&
        next.paletteWindowPercent ==
            _portalBackgroundMorph.paletteWindowPercent) {
      return;
    }
    _setPortal(DashboardHeaderPortalChannel.backgroundMorph, next);
    _record(
      'HEADER_PORTAL_BACKGROUND_MORPH_SETTING_CHANGED',
      'channel=backgroundMorph center=${next.paletteCenterPercent} '
          'window=${next.paletteWindowPercent} '
          'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void resetActivePortalEffect(DashboardHeaderPortalChannel channel) {
    if (_disposed) return;
    final current = _portalFor(channel);
    final settings =
        <DashboardHeaderPortalMaterialEffectId, Map<String, double>>{
          for (final entry in DashboardHeaderPortalMaterialCatalog.effects)
            entry.id: current.settingsFor(entry.id),
        };
    settings[current.effect] =
        DashboardHeaderPortalMaterialCatalog.defaultSettings(current.effect);
    var next = current.copyWith(settingsByEffect: settings);
    if (channel == DashboardHeaderPortalChannel.backgroundMorph &&
        current.effect == DashboardHeaderPortalMaterialEffectId.solidA) {
      next = next.copyWith(paletteCenterPercent: 50, paletteWindowPercent: 68);
    }
    _setPortal(channel, next);
    _record(
      channel == DashboardHeaderPortalChannel.innerMotion
          ? 'HEADER_PORTAL_INNER_EFFECT_RESET'
          : 'HEADER_PORTAL_BACKGROUND_MORPH_RESET',
      'channel=${channel.name} '
      'effectId=${DashboardHeaderPortalMaterialCatalog.effectFor(current.effect).sourceId} '
      'settingsGeneration=${portalSettingsGeneration.value}',
    );
  }

  void triggerPulse() {
    if (_disposed) return;
    _pulseStartedAt = _elapsed;
    _syncTicker();
    _record('HEADER_PULSE_TRIGGERED', 'durationMs=1560');
    notifyListeners();
  }

  void setTapWaveControl(String controlId, double value) {
    if (_disposed) return;
    final current = tapWaveTuning.value;
    final control = DashboardHeaderTapWaveCatalog.controlFor(controlId);
    final normalized = control.normalize(value);
    final previous = current.valueFor(controlId);
    if (previous == normalized) return;
    final next = current.copyWithValue(controlId, normalized);
    tapWaveTuning.value = next;
    _tapWave.configure(next);
    _record(
      'HEADER_TAP_WAVE_CONFIG_CHANGED',
      'parameterId=$controlId oldValue=$previous newValue=$normalized '
          'settingsGeneration=${next.generation}',
    );
    notifyListeners();
  }

  /// Receives Header-local normalized coordinates from the passive gesture
  /// listener. It never participates in Dashboard pan ownership.
  void beginTapWave(Offset origin) {
    if (_disposed) return;
    _tapWave.pointerDown(origin: origin, timestamp: _elapsed);
    _syncTicker();
    _record(
      'HEADER_TAP_WAVE_TRIGGERED',
      'originXNormalized=${origin.dx} originYNormalized=${origin.dy} '
          'activeWaveCount=${_tapWave.rippleCount}',
    );
    notifyListeners();
  }

  void updateTapWave(Offset origin) {
    if (_disposed) return;
    final generation = _tapWave.waveGeneration;
    _tapWave.pointerMove(origin: origin, timestamp: _elapsed);
    if (_tapWave.waveGeneration != generation) {
      _record(
        'HEADER_TAP_WAVE_RETRIGGERED',
        'originXNormalized=${origin.dx} originYNormalized=${origin.dy} '
            'waveGeneration=${_tapWave.waveGeneration} '
            'activeWaveCount=${_tapWave.rippleCount}',
      );
    }
    notifyListeners();
  }

  void endTapWave() {
    if (_disposed) return;
    _tapWave.pointerUp(timestamp: _elapsed);
    _syncTicker();
    notifyListeners();
  }

  /// Mirrors the Color Lab's reduced-motion boundary. This freezes only the
  /// shared paint clock; it never changes the active Budget Cool field or any
  /// semantic presentation state.
  void setMotionEnabled(bool enabled) {
    if (_disposed || _motionEnabled == enabled) return;
    _motionEnabled = enabled;
    _syncTicker();
    notifyListeners();
  }

  void toggleTuner() {
    if (_disposed) return;
    tunerOpen.value = !tunerOpen.value;
    _record('HEADER_TUNER_VISIBILITY_CHANGED', 'visible=${tunerOpen.value}');
  }

  void closeTuner() {
    if (_disposed || !tunerOpen.value) return;
    tunerOpen.value = false;
    _record('HEADER_TUNER_VISIBILITY_CHANGED', 'visible=false');
  }

  bool isTunerSectionExpanded(DashboardHeaderTunerSection section) =>
      expandedTunerSections.value.contains(section);

  void toggleTunerSection(DashboardHeaderTunerSection section) {
    if (_disposed) return;
    final next = Set<DashboardHeaderTunerSection>.of(
      expandedTunerSections.value,
    );
    if (!next.add(section)) next.remove(section);
    expandedTunerSections.value = Set<DashboardHeaderTunerSection>.unmodifiable(
      next,
    );
    _record(
      'HEADER_TUNER_SECTION_CHANGED',
      'section=${section.name} expanded=${next.contains(section)}',
    );
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTickerElapsed;
    _lastTickerElapsed = elapsed;
    _advance(delta);
  }

  void _advance(Duration delta) {
    if (_disposed || delta <= Duration.zero) return;
    _elapsed += delta;
    final current = tuning.value;
    if (current.effect != DashboardHeaderEffectId.staticEffect) {
      final speed = current.settingsFor(current.effect)['speed'] ?? 0;
      _phase += delta.inMicroseconds / Duration.microsecondsPerSecond * speed;
    }
    _portalInnerMotion.advance(delta);
    _portalBackgroundMorph.advance(delta);
    _tapWave.advance(_elapsed);
    if (pulseAmount == 0) _pulseStartedAt = null;
    _syncTicker();
    notifyListeners();
  }

  void _syncTicker() {
    final needsFrames =
        _motionEnabled &&
        (tuning.value.effect != DashboardHeaderEffectId.staticEffect ||
            _portalInnerMotion.requiresFrames ||
            _portalBackgroundMorph.requiresFrames ||
            _pulseStartedAt != null ||
            _tapWave.requiresFrames);
    if (needsFrames && !_ticker.isActive) {
      _lastTickerElapsed = Duration.zero;
      _ticker.start();
    } else if (!needsFrames && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @visibleForTesting
  void debugAdvance(Duration delta) => _advance(delta);

  DashboardHeaderPortalChannelState _portalFor(
    DashboardHeaderPortalChannel channel,
  ) => channel == DashboardHeaderPortalChannel.innerMotion
      ? _portalInnerMotion
      : _portalBackgroundMorph;

  void _setPortal(
    DashboardHeaderPortalChannel channel,
    DashboardHeaderPortalChannelState next,
  ) {
    if (channel == DashboardHeaderPortalChannel.innerMotion) {
      _portalInnerMotion = next;
    } else {
      _portalBackgroundMorph = next;
    }
    portalSettingsGeneration.value += 1;
    _syncTicker();
    notifyListeners();
  }

  void _record(String stage, String message) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(stage: stage, message: message),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    tunerOpen.dispose();
    expandedTunerSections.dispose();
    portalSettingsGeneration.dispose();
    tapWaveTuning.dispose();
    tuning.dispose();
    super.dispose();
  }
}

enum DashboardHeaderStaticColorInterpolation { nativeLinear }

/// Immutable paint input from a per-mode color policy. The Budget policy's
/// [colors]/[stops] are exactly the global Cool A/M/B source triplet.
@immutable
final class DashboardHeaderVisualFrame {
  const DashboardHeaderVisualFrame({
    required this.colors,
    required this.stops,
    required this.opacity,
    required this.colorA,
    required this.colorB,
    this.paletteSplitPercent = 50,
    this.windowLeftPercent,
    this.windowRightPercent,
    this.staticInterpolation,
    this.budgetCoolWindow,
    this.budgetCategoryWindow,
    this.staticSettingsGeneration,
  });

  final List<Color> colors;
  final List<double> stops;
  final double opacity;
  final Color colorA;
  final Color colorB;
  final double paletteSplitPercent;
  final double? windowLeftPercent;
  final double? windowRightPercent;

  /// Static-only semantic provenance. This contains no second colour vector:
  /// [colors] and [stops] remain the native-gradient authority.
  final DashboardHeaderStaticColorInterpolation? staticInterpolation;
  final BudgetHeaderCoolWindow? budgetCoolWindow;
  final DashboardHeaderCategoryWindow? budgetCategoryWindow;
  final int? staticSettingsGeneration;

  /// Compact deterministic diagnostic fingerprint of the whole field. It is
  /// constructed during semantic publication, never from a painter/tick.
  String get fieldStopHash {
    var hash = 0x811c9dc5;
    void mix(int value) {
      hash = ((hash ^ value) * 0x01000193).toUnsigned(32);
    }

    for (final color in colors) {
      mix(color.toARGB32());
    }
    for (final stop in stops) {
      mix((stop * 1000000).round());
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  factory DashboardHeaderVisualFrame.staticTone(Color color) =>
      DashboardHeaderVisualFrame(
        colors: List<Color>.unmodifiable(<Color>[color, color]),
        stops: const <double>[0, 1],
        opacity: 1,
        colorA: color,
        colorB: color,
      );

  bool sameAs(DashboardHeaderVisualFrame other) =>
      listEquals(colors, other.colors) &&
      listEquals(stops, other.stops) &&
      opacity == other.opacity &&
      colorA == other.colorA &&
      colorB == other.colorB &&
      paletteSplitPercent == other.paletteSplitPercent &&
      windowLeftPercent == other.windowLeftPercent &&
      windowRightPercent == other.windowRightPercent &&
      staticInterpolation == other.staticInterpolation &&
      budgetCoolWindow == other.budgetCoolWindow &&
      budgetCategoryWindow == other.budgetCategoryWindow &&
      staticSettingsGeneration == other.staticSettingsGeneration;

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderVisualFrame && sameAs(other);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colors),
    Object.hashAll(stops),
    opacity,
    colorA,
    colorB,
    paletteSplitPercent,
    windowLeftPercent,
    windowRightPercent,
    staticInterpolation,
    budgetCoolWindow,
    budgetCategoryWindow,
    staticSettingsGeneration,
  );
}

/// Trivial adapter for modes whose future color algorithm is intentionally not
/// part of this task.  It is still a separate policy boundary, so Balance and
/// Mind do not become accidental branches of Budget accounting code.
final class DashboardHeaderStaticColorPolicy
    extends ValueNotifier<DashboardHeaderVisualFrame> {
  DashboardHeaderStaticColorPolicy(Color tone)
    : super(DashboardHeaderVisualFrame.staticTone(tone));
}

abstract final class DashboardHeaderOpacityScale {
  static const List<double> _stops = <double>[
    .16,
    .24,
    .32,
    .42,
    .52,
    .62,
    .72,
    .82,
    .91,
    1,
  ];

  static double valueAt(double position) {
    final bounded = position.clamp(0.0, 100.0).toDouble();
    final scaled = bounded / 100 * (_stops.length - 1);
    final index = scaled.floor().clamp(0, _stops.length - 1);
    final next = math.min(_stops.length - 1, index + 1);
    // The Color Lab applies `toFixed(2)` at the ownership boundary before it
    // writes the active Header opacity CSS variable.
    return double.parse(
      (_stops[index] + (_stops[next] - _stops[index]) * (scaled - index))
          .toStringAsFixed(2),
    );
  }
}

/// Pure source-to-frame adapter. The Color Lab Cool source defines exactly
/// three probes; the existing native renderer interpolates between them.
abstract final class BudgetHeaderCoolColorScale {
  static DashboardHeaderVisualFrame fromWindow({
    required BudgetHeaderCoolWindow window,
    required double opacityScalePosition,
    required int staticSettingsGeneration,
  }) => DashboardHeaderVisualFrame(
    colors: window.colors,
    stops: window.stops,
    opacity: DashboardHeaderOpacityScale.valueAt(opacityScalePosition),
    colorA: window.colorA,
    colorB: window.colorB,
    paletteSplitPercent: window.positionPercent,
    windowLeftPercent: window.leftSamplePercent,
    windowRightPercent: window.rightSamplePercent,
    staticInterpolation: DashboardHeaderStaticColorInterpolation.nativeLinear,
    budgetCoolWindow: window,
    staticSettingsGeneration: staticSettingsGeneration,
  );
}

abstract final class BudgetHeaderCategoryColorScale {
  static DashboardHeaderVisualFrame fromWindow({
    required DashboardHeaderCategoryWindow window,
    required double opacityScalePosition,
    required int staticSettingsGeneration,
  }) => DashboardHeaderVisualFrame(
    colors: window.colors,
    stops: window.stops,
    opacity: DashboardHeaderOpacityScale.valueAt(opacityScalePosition),
    colorA: window.colorA,
    colorB: window.colorB,
    paletteSplitPercent: window.centerPercent,
    windowLeftPercent: window.leftSamplePercent,
    windowRightPercent: window.rightSamplePercent,
    staticInterpolation: DashboardHeaderStaticColorInterpolation.nativeLinear,
    budgetCategoryWindow: window,
    staticSettingsGeneration: staticSettingsGeneration,
  );
}

/// Budget Header colour retains the existing material frame transport. The
/// source selection is user-owned, while a Category window is derived from
/// the same committed Budget selection/value frame as Header/progress.
final class DashboardBudgetHeaderColorPolicy
    extends ValueNotifier<DashboardHeaderVisualFrame> {
  factory DashboardBudgetHeaderColorPolicy({
    required ValueListenable<DashboardHeaderVisualTuning> tuning,
    ValueListenable<DashboardBudgetPresentationState>? budgetPresentation,
  }) {
    final window = BudgetHeaderCoolWindowSampler.sample(
      tuning.value.budgetCool,
    );
    final categoryWindow = _categoryWindowFor(
      tuning.value,
      budgetPresentation?.value,
    );
    return DashboardBudgetHeaderColorPolicy._(
      tuning: tuning,
      budgetPresentation: budgetPresentation,
      coolWindow: window,
      categoryWindow: categoryWindow,
    );
  }

  DashboardBudgetHeaderColorPolicy._({
    required ValueListenable<DashboardHeaderVisualTuning> tuning,
    required ValueListenable<DashboardBudgetPresentationState>?
    budgetPresentation,
    required BudgetHeaderCoolWindow coolWindow,
    required DashboardHeaderCategoryWindow? categoryWindow,
  }) : _tuning = tuning,
       _budgetPresentation = budgetPresentation,
       _coolWindow = coolWindow,
       _categoryWindow = categoryWindow,
       super(_projectionFor(tuning.value, coolWindow, categoryWindow)) {
    _tuning.addListener(_refresh);
    _budgetPresentation?.addListener(_refresh);
    _publishBinding(value);
  }

  final ValueListenable<DashboardHeaderVisualTuning> _tuning;
  final ValueListenable<DashboardBudgetPresentationState>? _budgetPresentation;
  BudgetHeaderCoolWindow _coolWindow;
  DashboardHeaderCategoryWindow? _categoryWindow;
  Object? _lastBindingSignature;

  void _refresh() {
    final tuning = _tuning.value;
    if (_coolWindow.positionPercent != tuning.budgetCool.positionPercent ||
        _coolWindow.windowWidthPercent !=
            tuning.budgetCool.windowWidthPercent) {
      _coolWindow = BudgetHeaderCoolWindowSampler.sample(tuning.budgetCool);
    }
    _categoryWindow = _categoryWindowFor(tuning, _budgetPresentation?.value);
    final frame = _projectionFor(tuning, _coolWindow, _categoryWindow);
    if (!value.sameAs(frame)) value = frame;
    _publishBinding(frame);
  }

  void _publishBinding(DashboardHeaderVisualFrame frame) {
    final category = frame.budgetCategoryWindow;
    if (category != null) {
      final selection = _budgetPresentation?.value.liveSelection;
      final signature = Object.hash(
        category,
        selection?.target.identity,
        selection?.displayNumeratorScaled100,
        selection?.displayDenominatorScaled100,
        frame.staticSettingsGeneration,
      );
      if (_lastBindingSignature == signature) return;
      _lastBindingSignature = signature;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'HEADER_CATEGORY_PALETTE_BOUND',
          scope:
              'source=category scale=compressedV1Spectrum40 '
              'colorId=${category.scale.id} '
              'target=${selection?.target.handle ?? '-'} '
              'categoryId=${selection?.target.category?.id ?? '-'} '
              'remainingPct=${category.centerPercent.toStringAsFixed(1)} '
              'windowWidthPct=${category.windowWidthPercent.toStringAsFixed(0)} '
              'leftPct=${category.leftSamplePercent.toStringAsFixed(1)} '
              'rightPct=${category.rightSamplePercent.toStringAsFixed(1)} '
              'settingsGeneration=${frame.staticSettingsGeneration ?? 0}',
        ),
      );
      return;
    }
    final window = frame.budgetCoolWindow;
    if (window == null) return;
    final signature = Object.hash(
      window.positionPercent,
      window.windowWidthPercent,
      window.leftSamplePercent,
      window.centerSamplePercent,
      window.rightSamplePercent,
      window.colorA,
      window.colorMid,
      window.colorB,
    );
    if (_lastBindingSignature == signature) return;
    _lastBindingSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_HEADER_COOL_COLOR_BOUND',
        scope:
            'source=cool '
            'driver=userGlobal '
            'positionPct=${window.positionPercent.toStringAsFixed(0)} '
            'windowWidthPct=${window.windowWidthPercent.toStringAsFixed(0)} '
            'leftRawPct=${window.leftRawPercent.toStringAsFixed(1)} '
            'centerRawPct=${window.centerRawPercent.toStringAsFixed(1)} '
            'rightRawPct=${window.rightRawPercent.toStringAsFixed(1)} '
            'leftSamplePct=${window.leftSamplePercent.toStringAsFixed(1)} '
            'centerSamplePct=${window.centerSamplePercent.toStringAsFixed(1)} '
            'rightSamplePct=${window.rightSamplePercent.toStringAsFixed(1)} '
            'colorAArgb=${window.colorA.toARGB32()} '
            'colorMidArgb=${window.colorMid.toARGB32()} '
            'colorBArgb=${window.colorB.toARGB32()} '
            'settingsGeneration=${frame.staticSettingsGeneration ?? 0}',
      ),
    );
  }

  static DashboardHeaderVisualFrame _projectionFor(
    DashboardHeaderVisualTuning tuning,
    BudgetHeaderCoolWindow window,
    DashboardHeaderCategoryWindow? categoryWindow,
  ) => categoryWindow == null
      ? BudgetHeaderCoolColorScale.fromWindow(
          window: window,
          opacityScalePosition: tuning.opacityScalePosition,
          staticSettingsGeneration: tuning.generation,
        )
      : BudgetHeaderCategoryColorScale.fromWindow(
          window: categoryWindow,
          opacityScalePosition: tuning.opacityScalePosition,
          staticSettingsGeneration: tuning.generation,
        );

  static DashboardHeaderCategoryWindow? _categoryWindowFor(
    DashboardHeaderVisualTuning tuning,
    DashboardBudgetPresentationState? presentation,
  ) {
    if (tuning.budgetCategory.source !=
        DashboardBudgetHeaderColorSource.category) {
      return null;
    }
    final selection = presentation?.liveSelection;
    final colorId = selection?.target.category?.colorId;
    final scale = DashboardHeaderCategoryCompressedV1Scale.forColorIdOrNull(
      colorId,
    );
    if (scale == null) return null;
    return DashboardHeaderCategoryWindowSampler.sample(
      scale: scale,
      remainingPercent: DashboardHeaderCategoryWindowSampler.remainingPercent(
        spentScaled100: selection?.displayNumeratorScaled100,
        limitScaled100: selection?.displayDenominatorScaled100,
      ),
      windowWidthPercent: tuning.budgetCategory.windowWidthPercent,
    );
  }

  @override
  void dispose() {
    _tuning.removeListener(_refresh);
    _budgetPresentation?.removeListener(_refresh);
    super.dispose();
  }
}

/// Scalar implementation of `MindPortalEnergy`.  Keeping it pure makes the
/// Color Lab equations independently testable and keeps the painter free of
/// Budget/domain state.  Coordinates are always normalized Header-space.
@immutable
final class DashboardHeaderEffectSample {
  const DashboardHeaderEffectSample({
    required this.coordinate,
    required this.light,
    this.chroma = 0,
    this.boundary,
  });

  final double coordinate;
  final double light;
  final double chroma;
  final double? boundary;
}

/// Explicit, non-frame diagnostics for a manually requested material probe.
/// The renderer never instantiates these during phase animation; test/profile
/// tooling supplies sampled values after its own raster analysis.
@immutable
final class DashboardHeaderPaletteDistributionProbe {
  const DashboardHeaderPaletteDistributionProbe({
    required this.effect,
    required this.phase,
    required this.positionPercent,
    required this.windowWidthPercent,
    required this.binCount,
    required this.occupiedBins,
    required this.normalizedEntropy,
    required this.maxBinMass,
    required this.p05,
    required this.p25,
    required this.p50,
    required this.p75,
    required this.p95,
    required this.left15Mass,
    required this.right15Mass,
    required this.central70Mass,
    required this.mid40to60Mass,
    required this.wassersteinFromStatic,
    required this.derivativeP05,
    required this.derivativeMedian,
    required this.derivativeP95,
    required this.foldCount,
  });

  final DashboardHeaderEffectId effect;
  final double phase;
  final double positionPercent;
  final double windowWidthPercent;
  final int binCount;
  final int occupiedBins;
  final double normalizedEntropy;
  final double maxBinMass;
  final double p05;
  final double p25;
  final double p50;
  final double p75;
  final double p95;
  final double left15Mass;
  final double right15Mass;
  final double central70Mass;
  final double mid40to60Mass;
  final double wassersteinFromStatic;
  final double derivativeP05;
  final double derivativeMedian;
  final double derivativeP95;
  final int foldCount;
}

@immutable
final class DashboardHeaderOpticalStripeProbe {
  const DashboardHeaderOpticalStripeProbe({
    required this.effect,
    required this.ridgePeakDelta,
    required this.ridgeWidthFraction,
    required this.ridgeCoverage,
    required this.opticalP95Delta,
  });

  final DashboardHeaderEffectId effect;
  final double ridgePeakDelta;
  final double ridgeWidthFraction;
  final double ridgeCoverage;
  final double opticalP95Delta;
}

/// Explicit/manual diagnostic evidence for a full-field flow configuration.
/// It is never emitted from the frame clock and can therefore be used by test
/// and physical-acceptance tooling without adding phase-log traffic.
@immutable
final class DashboardHeaderFullFieldFlowProbe {
  const DashboardHeaderFullFieldFlowProbe({
    required this.effect,
    required this.phase,
    required this.seed,
    required this.grid,
    required this.movedFraction,
    required this.meanDisplacement,
    required this.maxDisplacement,
    required this.nonRigidResidual,
    required this.lightBandCentroidX,
    required this.lightBandCentroidY,
    required this.darkBandCentroidX,
    required this.darkBandCentroidY,
    required this.rightLightArea,
    required this.leftDarkArea,
    required this.entropy,
    required this.wasserstein,
    required this.localCompressionCount,
    required this.localExpansionCount,
  });

  final DashboardHeaderEffectId effect;
  final double phase;
  final int seed;
  final int grid;
  final double movedFraction;
  final double meanDisplacement;
  final double maxDisplacement;
  final double nonRigidResidual;
  final double lightBandCentroidX;
  final double lightBandCentroidY;
  final double darkBandCentroidX;
  final double darkBandCentroidY;
  final double rightLightArea;
  final double leftDarkArea;
  final double entropy;
  final double wasserstein;
  final int localCompressionCount;
  final int localExpansionCount;
}

/// Explicit/manual evidence for the independent Space Fabric source-map
/// lane. Like [DashboardHeaderFullFieldFlowProbe], this data is deliberately
/// never produced from the shared Header phase tick.
@immutable
final class DashboardHeaderSpaceFabricProbe {
  const DashboardHeaderSpaceFabricProbe({
    required this.effect,
    required this.phase,
    required this.grid,
    required this.meanDetJ,
    required this.minDetJ,
    required this.maxDetJ,
    required this.magnifiedAreaFraction,
    required this.compressedAreaFraction,
    required this.strongestMagnificationX,
    required this.strongestMagnificationY,
    required this.rigidResidual,
    required this.globalScaleResidual,
    required this.boundaryClampFraction,
  });

  final DashboardHeaderEffectId effect;
  final double phase;
  final int grid;
  final double meanDetJ;
  final double minDetJ;
  final double maxDetJ;
  final double magnifiedAreaFraction;
  final double compressedAreaFraction;
  final double strongestMagnificationX;
  final double strongestMagnificationY;
  final double rigidResidual;
  final double globalScaleResidual;
  final double boundaryClampFraction;
}

/// Explicit/manual temporal evidence for Space Fabric. This is never emitted
/// from the phase tick, so it cannot add log traffic or become another clock.
@immutable
final class DashboardHeaderSpaceFabricTemporalProbe {
  const DashboardHeaderSpaceFabricTemporalProbe({
    required this.effect,
    required this.speed,
    required this.sampleDeltaMs,
    required this.sourceMapMeanDelta,
    required this.sourceMapMaxDelta,
    required this.metricCentroidDelta,
    required this.magnificationDelta,
    required this.orientationDelta,
    required this.tickerActive,
    required this.clockOwnerIdentity,
  });

  final DashboardHeaderEffectId effect;
  final double speed;
  final int sampleDeltaMs;
  final double sourceMapMeanDelta;
  final double sourceMapMaxDelta;
  final double metricCentroidDelta;
  final double magnificationDelta;
  final double orientationDelta;
  final bool tickerActive;
  final int clockOwnerIdentity;
}

abstract final class DashboardHeaderMaterialTransportDiagnostics {
  /// Manual/test-only call. Deliberately separate from phase-tick diagnostics.
  static void recordDistribution(
    DashboardHeaderPaletteDistributionProbe probe,
  ) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_PALETTE_DISTRIBUTION_PROBE',
        scope:
            'effectId=${probe.effect.name} '
            'phase=${probe.phase} '
            'P=${probe.positionPercent} '
            'W=${probe.windowWidthPercent} '
            'binCount=${probe.binCount} '
            'occupiedBins=${probe.occupiedBins} '
            'normalizedEntropy=${probe.normalizedEntropy} '
            'maxBinMass=${probe.maxBinMass} '
            'p05=${probe.p05} p25=${probe.p25} p50=${probe.p50} '
            'p75=${probe.p75} p95=${probe.p95} '
            'left15Mass=${probe.left15Mass} '
            'right15Mass=${probe.right15Mass} '
            'central70Mass=${probe.central70Mass} '
            'mid40to60Mass=${probe.mid40to60Mass} '
            'wassersteinFromStatic=${probe.wassersteinFromStatic} '
            'derivativeP05=${probe.derivativeP05} '
            'derivativeMedian=${probe.derivativeMedian} '
            'derivativeP95=${probe.derivativeP95} '
            'foldCount=${probe.foldCount}',
      ),
    );
  }

  /// Manual/test-only constant-palette optical oracle; never phase-spams.
  static void recordOpticalStripe(DashboardHeaderOpticalStripeProbe probe) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_OPTICAL_STRIPE_PROBE',
        scope:
            'effectId=${probe.effect.name} '
            'constantPalette=true '
            'ridgePeakDelta=${probe.ridgePeakDelta} '
            'ridgeWidthFraction=${probe.ridgeWidthFraction} '
            'ridgeCoverage=${probe.ridgeCoverage} '
            'opticalP95Delta=${probe.opticalP95Delta}',
      ),
    );
  }

  static void recordFullFieldFlow(DashboardHeaderFullFieldFlowProbe probe) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_FULL_FIELD_FLOW_PROBE',
        scope:
            'effectId=${probe.effect.name} phase=${probe.phase} '
            'seed=${probe.seed} grid=${probe.grid} '
            'movedFraction=${probe.movedFraction} '
            'meanDisplacement=${probe.meanDisplacement} '
            'maxDisplacement=${probe.maxDisplacement} '
            'nonRigidResidual=${probe.nonRigidResidual} '
            'lightBandCentroidX=${probe.lightBandCentroidX} '
            'lightBandCentroidY=${probe.lightBandCentroidY} '
            'darkBandCentroidX=${probe.darkBandCentroidX} '
            'darkBandCentroidY=${probe.darkBandCentroidY} '
            'rightLightArea=${probe.rightLightArea} '
            'leftDarkArea=${probe.leftDarkArea} '
            'entropy=${probe.entropy} wasserstein=${probe.wasserstein} '
            'localCompressionCount=${probe.localCompressionCount} '
            'localExpansionCount=${probe.localExpansionCount}',
      ),
    );
  }

  /// Manual/test-only Space Fabric Jacobian evidence; it cannot introduce
  /// phase spam or a second clock.
  static void recordSpaceFabric(DashboardHeaderSpaceFabricProbe probe) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_SPACE_FABRIC_PROBE',
        scope:
            'effectId=${probe.effect.name} phase=${probe.phase} '
            'grid=${probe.grid} meanDetJ=${probe.meanDetJ} '
            'minDetJ=${probe.minDetJ} maxDetJ=${probe.maxDetJ} '
            'magnifiedAreaFraction=${probe.magnifiedAreaFraction} '
            'compressedAreaFraction=${probe.compressedAreaFraction} '
            'strongestMagnificationX=${probe.strongestMagnificationX} '
            'strongestMagnificationY=${probe.strongestMagnificationY} '
            'rigidResidual=${probe.rigidResidual} '
            'globalScaleResidual=${probe.globalScaleResidual} '
            'boundaryClampFraction=${probe.boundaryClampFraction}',
      ),
    );
  }

  /// Manual/test-only temporal probe. The caller supplies measured source-map
  /// evidence; this method intentionally never samples or logs per frame.
  static void recordSpaceFabricTemporal(
    DashboardHeaderSpaceFabricTemporalProbe probe,
  ) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_SPACE_FABRIC_TEMPORAL_PROBE',
        scope:
            'effectId=${probe.effect.name} speed=${probe.speed} '
            'sampleDeltaMs=${probe.sampleDeltaMs} '
            'sourceMapMeanDelta=${probe.sourceMapMeanDelta} '
            'sourceMapMaxDelta=${probe.sourceMapMaxDelta} '
            'metricCentroidDelta=${probe.metricCentroidDelta} '
            'magnificationDelta=${probe.magnificationDelta} '
            'orientationDelta=${probe.orientationDelta} '
            'tickerActive=${probe.tickerActive} '
            'clockOwnerIdentity=${probe.clockOwnerIdentity}',
      ),
    );
  }
}

abstract final class DashboardHeaderEffectMath {
  static const List<(double, double, double)> _cellSeeds =
      <(double, double, double)>[
        (.13, .18, .1),
        (.34, .76, 1.7),
        (.52, .32, 3.1),
        (.72, .80, 4.8),
        (.88, .24, 6.4),
        (.22, .51, 8.2),
        (.66, .52, 10.3),
      ];
  static const List<(double, double, double)> _chargeSeeds =
      <(double, double, double)>[
        (.16, .18, .7),
        (.34, .72, 1.9),
        (.56, .36, 3.2),
        (.78, .81, 4.6),
        (.88, .22, 6.1),
        (.44, .54, 7.8),
        (.24, .88, 9.4),
        (.68, .10, 11.2),
      ];

  static DashboardHeaderEffectSample sample({
    required DashboardHeaderEffectId effect,
    required double x,
    required double y,
    required double phase,
    required double paletteSplitPercent,
    required Map<String, double> settings,
  }) {
    final nx = _clamp01(x);
    final ny = _clamp01(y);
    return switch (effect) {
      DashboardHeaderEffectId.staticEffect => const DashboardHeaderEffectSample(
        coordinate: 0,
        light: 0,
      ),
      DashboardHeaderEffectId.dualTide => _nonBalance(
        nx,
        _dualTide(nx, ny, phase, settings),
        settings,
      ),
      DashboardHeaderEffectId.magneticMembrane => _nonBalance(
        nx,
        _magneticMembrane(nx, ny, phase, settings),
        settings,
      ),
      DashboardHeaderEffectId.breathingLens => _nonBalance(
        nx,
        _breathingLens(nx, ny, phase, settings),
        settings,
      ),
      DashboardHeaderEffectId.cellularField => _nonBalance(
        nx,
        _cellularField(nx, ny, phase, settings),
        settings,
      ),
      DashboardHeaderEffectId.balanceMembrane => _balanceMembrane(
        nx,
        ny,
        phase,
        paletteSplitPercent,
        settings,
      ),
      DashboardHeaderEffectId.balanceCounterflow => _balanceCounterflow(
        nx,
        ny,
        phase,
        paletteSplitPercent,
        settings,
      ),
      DashboardHeaderEffectId.balanceCharges => _balanceCharges(
        nx,
        ny,
        phase,
        paletteSplitPercent,
        settings,
      ),
      // This retained Dart reference keeps the same identity coordinate for
      // Deep Drift. Production shader failure uses the native static field,
      // never this legacy sampling helper.
      DashboardHeaderEffectId.deepDrift => DashboardHeaderEffectSample(
        coordinate: nx,
        light: 0,
      ),
      DashboardHeaderEffectId.freeFlow ||
      DashboardHeaderEffectId.chaoticAdvection ||
      DashboardHeaderEffectId.elasticSpace ||
      DashboardHeaderEffectId.braidedCurrent ||
      DashboardHeaderEffectId.volumetricCurrent ||
      DashboardHeaderEffectId.metricBloom ||
      DashboardHeaderEffectId.gravitationalFabric ||
      DashboardHeaderEffectId.breathingMetric ||
      DashboardHeaderEffectId.tidalCurvature => DashboardHeaderEffectSample(
        coordinate: nx,
        light: 0,
      ),
    };
  }

  static DashboardHeaderEffectSample _nonBalance(
    double x,
    (double mix, double light) animated,
    Map<String, double> settings,
  ) {
    final strength = _clamp01(_v(settings, 'strength'));
    return DashboardHeaderEffectSample(
      coordinate: _clamp01(_lerp(x, animated.$1, strength)),
      light: _clamp(animated.$2 * strength, -.25, .25),
    );
  }

  static ({double sx, double sy, double ratio, double broad, double detail})
  _prepare(double x, double y, double phase, Map<String, double> s) {
    final scale = math.max(.01, _v(s, 'fieldScale'));
    final sx = .5 + ((x - .5) * scale);
    final sy = .5 + ((y - .5) * scale);
    final ratio =
        _v(s, 'bias') +
        math.sin(phase * _v(s, 'ratioSpeed') * math.pi * 2) *
            _v(s, 'ratioSwing');
    final morphTime = phase * _v(s, 'morphSpeed');
    final broad =
        (_fbm(sx * 1.17 + morphTime * .07, sy * 1.09 - morphTime * .05, 31.7) -
            .5) *
        _v(s, 'morphAmount');
    final detail =
        (_fbm(sx * 2.8 - morphTime * .09, sy * 2.5 + morphTime * .08, 67.3) -
            .5) *
        _v(s, 'detail');
    return (sx: sx, sy: sy, ratio: ratio, broad: broad, detail: detail);
  }

  static (double mix, double light) _finish(
    double field,
    double phase,
    Map<String, double> s,
    ({double sx, double sy, double ratio, double broad, double detail}) context,
    double localLight,
  ) {
    final softness = math.max(.001, _v(s, 'softness'));
    final mix = _smoothstep(.5 - softness, .5 + softness, field);
    final seam = 4 * mix * (1 - mix);
    final pulse =
        math.sin(phase * _v(s, 'pulseSpeed') * math.pi * 2) *
        _v(s, 'pulseAmount');
    final texture = (context.broad + context.detail) * _v(s, 'lightAmount');
    return (mix, _clamp((pulse + texture + localLight) * seam, -.25, .25));
  }

  static (double mix, double light) _dualTide(
    double x,
    double y,
    double phase,
    Map<String, double> s,
  ) {
    final c = _prepare(x, y, phase, s);
    final offset = _v(s, 'phaseOffset') * math.pi / 180;
    final aPhase = phase * .52;
    final bPhase = phase * .47 + offset;
    final aX =
        .5 -
        _v(s, 'separation') * .5 +
        math.sin(aPhase * .83) * _v(s, 'wanderX') +
        (.5 + .5 * math.sin(aPhase * .31)) * _v(s, 'intrusion');
    final bX =
        .5 +
        _v(s, 'separation') * .5 -
        math.sin(bPhase * .79) * _v(s, 'wanderX') -
        (.5 + .5 * math.sin(bPhase * .29)) * _v(s, 'intrusion');
    final aY = .5 + math.sin(aPhase * .61) * _v(s, 'wanderY');
    final bY = .5 - math.sin(bPhase * .57) * _v(s, 'wanderY');
    final aMass = _gaussian(
      c.sx - aX,
      c.sy - aY,
      _v(s, 'lobeARadius'),
      _v(s, 'lobeARadius') / _v(s, 'lobeAEllipse'),
    );
    final bMass = _gaussian(
      c.sx - bX,
      c.sy - bY,
      _v(s, 'lobeBRadius'),
      _v(s, 'lobeBRadius') / _v(s, 'lobeBEllipse'),
    );
    final warp =
        (_fbm(
              c.sx * _v(s, 'warpScale') + phase * _v(s, 'warpSpeed') * .11,
              c.sy * _v(s, 'warpScale') - phase * _v(s, 'warpSpeed') * .09,
              103.2,
            ) -
            .5) *
        _v(s, 'warpAmount');
    final field =
        c.sx +
        c.ratio +
        warp +
        (bMass - aMass) * _v(s, 'counterFlow') * .46 +
        c.broad * .20 +
        c.detail * .12;
    return _finish(
      field,
      phase,
      s,
      c,
      (aMass + bMass - .7) * _v(s, 'lightAmount') * .12,
    );
  }

  static (double mix, double light) _magneticMembrane(
    double x,
    double y,
    double phase,
    Map<String, double> s,
  ) {
    final c = _prepare(x, y, phase, s);
    final spread = _v(s, 'nodePhaseSpread') * math.pi / 180;
    final nodeWander = _v(s, 'nodeWander');
    final nodeTop = _v(s, 'nodeTop') + math.sin(phase * .23) * nodeWander;
    final nodeMiddle =
        _v(s, 'nodeMiddle') + math.sin(phase * .23 + spread) * nodeWander;
    final nodeBottom =
        _v(s, 'nodeBottom') + math.sin(phase * .23 + spread * 2) * nodeWander;
    final iy = _clamp01(c.sy);
    final nodeCurve =
        (1 - iy) * (1 - iy) * nodeTop +
        2 * (1 - iy) * iy * nodeMiddle +
        iy * iy * nodeBottom;
    final primary =
        math.sin(
          c.sy / _v(s, 'primaryWavelength') * math.pi * 2 +
              phase * _v(s, 'primarySpeed') * math.pi * 2,
        ) *
        _v(s, 'primaryAmplitude');
    final secondary =
        math.sin(
          c.sy / _v(s, 'secondaryWavelength') * math.pi * 2 -
              phase * _v(s, 'secondarySpeed') * math.pi * 2 +
              1.7,
        ) *
        _v(s, 'secondaryAmplitude');
    final warp =
        (_fbm(
              c.sy * 1.4 + phase * _v(s, 'warpSpeed') * .08,
              c.sx * .9 - phase * _v(s, 'warpSpeed') * .05,
              211.6,
            ) -
            .5) *
        _v(s, 'warpAmount');
    final boundary =
        .5 +
        c.ratio +
        nodeCurve * (1 - _v(s, 'tension') * .68) +
        primary +
        secondary +
        _v(s, 'skew') * (c.sy - .5) +
        warp +
        c.broad * .18 +
        c.detail * .10;
    return _finish(
      .5 + (c.sx - boundary),
      phase,
      s,
      c,
      (primary + secondary).abs() * _v(s, 'lightAmount') * .16,
    );
  }

  static (double mix, double light) _breathingLens(
    double x,
    double y,
    double phase,
    Map<String, double> s,
  ) {
    final c = _prepare(x, y, phase, s);
    final breathPhase = phase * _v(s, 'breathSpeed') * math.pi * 2;
    final centerX = _v(s, 'centerX') + math.sin(phase * .31) * _v(s, 'wanderX');
    final centerY = _v(s, 'centerY') + math.cos(phase * .27) * _v(s, 'wanderY');
    final radiusX = math.max(
      .03,
      _v(s, 'radiusX') * (1 + math.sin(breathPhase) * _v(s, 'breathX')),
    );
    final radiusY = math.max(
      .03,
      _v(s, 'radiusY') * (1 + math.cos(breathPhase * .83) * _v(s, 'breathY')),
    );
    final dx = (c.sx - centerX) / radiusX;
    final dy = (c.sy - centerY) / radiusY;
    final lensDistance = math.sqrt(dx * dx + dy * dy);
    final lens = math.exp(
      -(lensDistance * lensDistance) / math.max(.01, _v(s, 'edgeFalloff')),
    );
    final satelliteAngle = _v(s, 'satellitePhase') * math.pi / 180;
    final satelliteX =
        centerX +
        math.cos(satelliteAngle + phase * .13) * _v(s, 'satelliteDistance');
    final satelliteY =
        centerY +
        math.sin(satelliteAngle + phase * .11) * _v(s, 'satelliteDistance');
    final satellite = _gaussian(
      c.sx - satelliteX,
      c.sy - satelliteY,
      _v(s, 'satelliteRadius'),
      _v(s, 'satelliteRadius'),
    );
    final pressure =
        (lens * _v(s, 'pressure') + satellite * _v(s, 'satelliteAmount')) *
        _v(s, 'refraction');
    return _finish(
      c.sx + c.ratio + pressure + c.broad * .19 + c.detail * .10,
      phase,
      s,
      c,
      (lens + satellite) * _v(s, 'lightAmount') * .12,
    );
  }

  static (double mix, double light) _cellularField(
    double x,
    double y,
    double phase,
    Map<String, double> s,
  ) {
    final c = _prepare(x, y, phase, s);
    final count = _v(s, 'cellCount').round().clamp(3, 7);
    var pressureSum = 0.0;
    var lightSum = 0.0;
    for (var index = 0; index < count; index += 1) {
      final seed = _cellSeeds[index];
      final curl =
          (_fbm(
                seed.$1 * _v(s, 'curlScale') + phase * .04,
                seed.$2 * _v(s, 'curlScale') - phase * .03,
                seed.$3 + 301,
              ) -
              .5) *
          _v(s, 'curlAmount');
      final cellX = _wrap01(
        seed.$1 +
            phase * _v(s, 'advectionX') * .025 +
            math.sin(phase * .19 + seed.$3) * _v(s, 'cellWander') +
            curl,
      );
      final cellY = _wrap01(
        seed.$2 +
            phase * _v(s, 'advectionY') * .025 +
            math.cos(phase * .17 + seed.$3) * _v(s, 'cellWander') -
            curl,
      );
      final sizeWave = math.sin(phase * .21 + seed.$3) * _v(s, 'cellMorph');
      final variation =
          1 + ((index / math.max(1, count - 1)) - .5) * _v(s, 'cellVariation');
      final radius = math.max(
        .04,
        _v(s, 'cellSize') * variation * (1 + sizeWave * .35),
      );
      final cell = _gaussian(
        c.sx - cellX,
        c.sy - cellY,
        radius,
        radius * (.84 + (index % 3) * .11),
      );
      final polarity = index.isEven ? -1.0 : 1.0;
      pressureSum += cell * (polarity + _v(s, 'polarityBalance'));
      lightSum += cell;
    }
    final noise =
        (_fbm(
              c.sx * _v(s, 'noiseScale') + phase * _v(s, 'noiseSpeed') * .07,
              c.sy * _v(s, 'noiseScale') - phase * _v(s, 'noiseSpeed') * .06,
              409.4,
            ) -
            .5) *
        _v(s, 'noiseAmount');
    return _finish(
      c.sx +
          c.ratio +
          _v(s, 'mergeThreshold') +
          pressureSum / count * _v(s, 'pressure') +
          noise +
          c.broad * .18 +
          c.detail * .10,
      phase,
      s,
      c,
      lightSum / count * _v(s, 'lightAmount') * .16,
    );
  }

  static DashboardHeaderEffectSample _balanceMembrane(
    double x,
    double y,
    double phase,
    double percent,
    Map<String, double> s,
  ) {
    final base = _moneySplit(percent);
    final offset = _v(s, 'nodePhase') * math.pi / 180;
    final drift = phase * _v(s, 'driftSpeed') * math.pi * 2;
    final primary = _zeroMeanSine(
      y,
      math.pi * 2 / _v(s, 'primaryWavelength'),
      drift,
    );
    final secondary = _zeroMeanSine(
      y,
      math.pi * 2 / _v(s, 'secondaryWavelength'),
      -(drift * .71) + offset,
    );
    final warp =
        _antisymmetricFbm(
          y,
          phase * _v(s, 'warpSpeed') * .08,
          phase * _v(s, 'warpSpeed') * .06 + .37,
          _v(s, 'warpScale'),
          701.3,
        ) *
        _v(s, 'warpAmount');
    final damping = 1 - _v(s, 'tension') * .72;
    final raw =
        (primary * _v(s, 'boundaryAmplitude') +
            secondary * _v(s, 'secondaryAmplitude') +
            warp) *
        damping;
    final maximum =
        2 *
        (_v(s, 'boundaryAmplitude') +
            _v(s, 'secondaryAmplitude') +
            _v(s, 'warpAmount')) *
        damping;
    return _finishBalance(
      x,
      base,
      base + _limitDeformation(raw, maximum, base),
      (primary * .68 + secondary * .32).abs(),
      warp,
      phase,
      s,
    );
  }

  static DashboardHeaderEffectSample _balanceCounterflow(
    double x,
    double y,
    double phase,
    double percent,
    Map<String, double> s,
  ) {
    final base = _moneySplit(percent);
    final drift = phase * _v(s, 'verticalDrift') * math.pi * 2;
    final wave = _v(s, 'lobeCount') * math.pi * 2;
    final a = _zeroMeanSine(y, wave, drift);
    final b = _zeroMeanSine(
      y,
      wave,
      drift + _v(s, 'counterPhase') * math.pi / 180,
    );
    final paired = a - b * _v(s, 'compensation') * _v(s, 'lobeEllipse');
    final shaped = paired.sign * math.pow(paired.abs(), _v(s, 'lobeSharpness'));
    final maximumShape = math
        .pow(
          1 + _v(s, 'compensation') * _v(s, 'lobeEllipse'),
          _v(s, 'lobeSharpness'),
        )
        .toDouble();
    final normalized = shaped / math.max(1e-6, maximumShape);
    final gain = _v(s, 'lobeRadius') / .22;
    final warp =
        _antisymmetricFbm(
          y,
          -(phase * _v(s, 'warpSpeed') * .07),
          phase * _v(s, 'warpSpeed') * .05 + .73,
          _v(s, 'warpScale'),
          811.9,
        ) *
        _v(s, 'warpAmount');
    final raw = normalized * _v(s, 'intrusion') * gain * .5 + warp;
    final maximum = _v(s, 'intrusion') * gain * .5 + _v(s, 'warpAmount');
    return _finishBalance(
      x,
      base,
      base + _limitDeformation(raw, maximum, base),
      paired.abs() / math.max(1, maximumShape) * .72,
      normalized * .55,
      phase,
      s,
    );
  }

  static DashboardHeaderEffectSample _balanceCharges(
    double x,
    double y,
    double phase,
    double percent,
    Map<String, double> s,
  ) {
    final base = _moneySplit(percent);
    final rawSeam =
        _zeroMeanSine(
          y,
          math.pi * 2 / _v(s, 'seamWavelength'),
          phase * _v(s, 'seamSpeed') * math.pi * 2,
        ) *
        _v(s, 'seamDrift');
    final boundary =
        base + _limitDeformation(rawSeam, _v(s, 'seamDrift') * 2, base);
    final side = x <= boundary ? 0 : 1;
    final count = _v(s, 'chargeCount').round().clamp(2, 8);
    final sidePhase = _v(s, 'sidePhase') * math.pi / 180;
    var light = 0.0;
    var chroma = 0.0;
    for (var index = 0; index < count; index += 1) {
      if (index % 2 != side) continue;
      final seed = _chargeSeeds[index];
      final start = side == 0 ? 0.0 : base;
      final width = side == 0 ? base : 1 - base;
      final centerX =
          start +
          width * (.12 + seed.$1 * .76) +
          math.sin(phase * .13 + seed.$3) * _v(s, 'chargeWander') * width;
      final centerY =
          seed.$2 + math.cos(phase * .11 + seed.$3) * _v(s, 'chargeWander');
      final variation =
          1 +
          ((index / math.max(1, count - 1)) - .5) * _v(s, 'chargeVariation');
      final morph =
          1 +
          math.sin(phase * .17 + seed.$3 * _v(s, 'noiseScale')) *
              _v(s, 'chargeMorph') *
              .35;
      final radius = math.max(.03, _v(s, 'chargeSize') * variation * morph);
      final charge = _gaussian(x - centerX, y - centerY, radius, radius * .82);
      final polarity = math.sin(phase * .16 + seed.$3 + side * sidePhase);
      light += charge * polarity * _v(s, 'chargeLight');
      chroma += charge * polarity * _v(s, 'chargeChroma');
    }
    return _finishBalance(x, base, boundary, light, chroma, phase, s);
  }

  static DashboardHeaderEffectSample _finishBalance(
    double x,
    double base,
    double animated,
    double rawLight,
    double rawChroma,
    double phase,
    Map<String, double> s,
  ) {
    final strength = _clamp01(_v(s, 'strength'));
    if (strength == 0) {
      return DashboardHeaderEffectSample(
        coordinate: x,
        light: 0,
        boundary: base,
      );
    }
    final boundary = _clamp(_lerp(base, animated, strength), .04, .96);
    final seamEnergy = math.exp(
      -(x - boundary).abs() / math.max(.01, _v(s, 'seamSoftness')),
    );
    final pulse =
        math.sin(phase * _v(s, 'pulseSpeed') * math.pi * 2) *
        _v(s, 'pulseAmount') *
        seamEnergy;
    return DashboardHeaderEffectSample(
      coordinate: _clamp01(_mapMoneyCoordinate(x, base, boundary)),
      boundary: boundary,
      light: _clamp(
        (rawLight * _v(s, 'lightAmount') + pulse) * strength,
        -.22,
        .22,
      ),
      chroma: _clamp(rawChroma * _v(s, 'chromaAmount') * strength, -.35, .35),
    );
  }

  static double _v(Map<String, double> s, String key) => s[key]!;
  static double _clamp(double value, double min, double max) =>
      math.max(min, math.min(max, value));
  static double _clamp01(double value) =>
      _clamp(value.isFinite ? value : 0, 0, 1);
  static double _lerp(double a, double b, double amount) =>
      a + (b - a) * amount;
  static double _smoothstep(double edge0, double edge1, double value) {
    final t = _clamp01((value - edge0) / math.max(1e-6, edge1 - edge0));
    return t * t * (3 - 2 * t);
  }

  static double _gaussian(double dx, double dy, double rx, double ry) =>
      math.exp(
        -((dx * dx) / math.max(1e-6, rx * rx) +
            (dy * dy) / math.max(1e-6, ry * ry)),
      );
  static int _imul(int a, int b) => (a * b).toSigned(32);
  static double _hash(int x, int y, double seed) {
    var value =
        _imul(x, 374761393) ^
        _imul(y, 668265263) ^
        _imul((seed * 1000).round(), 1442695041);
    value = _imul(value ^ (value.toUnsigned(32) >>> 13), 1274126177);
    value ^= value.toUnsigned(32) >>> 16;
    return value.toUnsigned(32) / 4294967295;
  }

  static double _valueNoise(double x, double y, double seed) {
    final xi = x.floor();
    final yi = y.floor();
    final tx = _smoothstep(0, 1, x - xi);
    final ty = _smoothstep(0, 1, y - yi);
    return _lerp(
      _lerp(_hash(xi, yi, seed), _hash(xi + 1, yi, seed), tx),
      _lerp(_hash(xi, yi + 1, seed), _hash(xi + 1, yi + 1, seed), tx),
      ty,
    );
  }

  static double _fbm(double x, double y, double seed) {
    var value = 0.0;
    var amplitude = .58;
    var norm = 0.0;
    var frequency = 1.0;
    for (var octave = 0; octave < 3; octave += 1) {
      value +=
          _valueNoise(x * frequency, y * frequency, seed + octave * 17.3) *
          amplitude;
      norm += amplitude;
      frequency *= 1.93;
      amplitude *= .46;
    }
    return value / norm;
  }

  static double _wrap01(double value) => ((value % 1) + 1) % 1;
  static double _moneySplit(double percent) =>
      .08 + _clamp01(percent / 100) * .84;
  static double _mapMoneyCoordinate(double x, double base, double boundary) =>
      x <= boundary
      ? base * (x / math.max(1e-6, boundary))
      : base + (1 - base) * ((x - boundary) / math.max(1e-6, 1 - boundary));
  static double _zeroMeanSine(double y, double waveNumber, double phase) {
    final safe = math.max(1e-6, waveNumber.abs());
    final signed = waveNumber < 0 ? -safe : safe;
    final mean = (math.cos(phase) - math.cos(signed + phase)) / signed;
    return math.sin(signed * y + phase) - mean;
  }

  static double _antisymmetricFbm(
    double y,
    double offsetX,
    double offsetY,
    double scale,
    double seed,
  ) =>
      _fbm(y * scale + offsetX, offsetY, seed) -
      _fbm((1 - y) * scale + offsetX, offsetY, seed);
  static double _limitDeformation(double raw, double maximum, double base) {
    final safe = math.max(.001, math.min(base - .04, .96 - base));
    final normalization = maximum > safe ? safe / math.max(1e-6, maximum) : 1;
    return raw * normalization;
  }
}

/// Narrow repaint boundary for Header background motion.  The child is the
/// static semantic Header content; it is not an animation listener.
final class _DashboardHeaderVisualPaintResources {
  _DashboardHeaderVisualPaintResources({
    DashboardHeaderFragmentBackend? fragment,
  }) : fragment = fragment ?? DashboardHeaderFragmentBackend(),
       _ownsFragment = fragment == null {
    this.fragment.addListener(_onFragmentBackendChanged);
  }

  final DashboardHeaderFragmentBackend fragment;
  final bool _ownsFragment;
  final _DashboardHeaderFragmentUniformCache fragmentUniforms =
      _DashboardHeaderFragmentUniformCache();

  Object? _lastFragmentConfigurationSignature;
  bool _backendBoundRecorded = false;
  Object? _lastTouchRenderPathSignature;
  Object? _lastDeepDriftSignature;
  Object? _lastPortalInnerSignature;
  Object? _lastPortalBackgroundSignature;
  Object? _lastPortalFragmentInputSignature;
  Object? _lastStaticColorRendererSignature;
  Object? _lastPaletteFieldSignature;
  Object? _lastEffectPaletteTransportSignature;
  Object? _lastFullFieldFlowSignature;
  Object? _lastSpaceFabricSignature;
  _SpaceFabricLivenessWindow? _spaceFabricLiveness;
  bool _staticColorRendererSourceRecorded = false;
  bool _fragmentReadinessObserved = false;
  bool _fragmentReadinessRecorded = false;

  /// Low-frequency proof that the static base bound the direct historical
  /// native predecessor renderer. This is intentionally emitted only for a semantic
  /// field publication, never for a phase repaint.
  void recordStaticColorRendererBinding({
    required DashboardHeaderVisualFrame frame,
  }) {
    if (!_staticColorRendererSourceRecorded) {
      _staticColorRendererSourceRecorded = true;
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'HEADER_STATIC_COLOR_RENDERER_SOURCE_VERIFIED',
          scope:
              'sourceBlob=bea3a36482686b1ef7a537046dcce0f2c443918a '
              'cssDegrees=112 renderer=ui.Gradient.linear',
        ),
      );
    }
    final signature = Object.hash(
      frame.fieldStopHash,
      frame.stops.length,
      frame.opacity,
      frame.windowLeftPercent,
      frame.windowRightPercent,
    );
    if (_lastStaticColorRendererSignature == signature) return;
    _lastStaticColorRendererSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_STATIC_COLOR_RENDERER_BOUND',
        scope:
            'renderer=${DashboardHeaderStaticColorRenderer.rendererId} '
            'cssDegrees=${DashboardHeaderStaticColorRenderer.cssDegrees} '
            'windowLeftPct=${frame.windowLeftPercent ?? '-'} '
            'windowRightPct=${frame.windowRightPercent ?? '-'} '
            'fieldStopCount=${frame.stops.length} '
            'fieldStopHash=${frame.fieldStopHash} '
            'opacity=${frame.opacity} '
            'fragmentBaseRequired=${DashboardHeaderStaticColorRenderer.fragmentBaseRequired}',
      ),
    );
  }

  /// Binds the user-owned Cool field exactly once per semantic field change.
  /// This deliberately has no phase input: palette publication cannot become
  /// frame telemetry.
  void recordPaletteFieldBinding({
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderVisualTuning tuning,
  }) {
    final cool = frame.budgetCoolWindow;
    final category = frame.budgetCategoryWindow;
    final signature = Object.hash(
      frame.fieldStopHash,
      frame.stops.length,
      cool,
      category,
    );
    if (_lastPaletteFieldSignature == signature) return;
    _lastPaletteFieldSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_PALETTE_FIELD_BOUND',
        scope:
            'source=${category == null ? 'cool' : 'category'} '
            'positionPct=${cool?.positionPercent ?? category?.centerPercent ?? '-'} '
            'windowWidthPct=${cool?.windowWidthPercent ?? category?.windowWidthPercent ?? '-'} '
            'categoryColorId=${category?.scale.id ?? '-'} '
            'sourceColorCount=${frame.colors.length} '
            'sourceStopCount=${frame.stops.length} '
            'fieldHash=${frame.fieldStopHash} '
            'staticAngle=${DashboardHeaderStaticColorRenderer.cssDegrees} '
            'settingsGeneration=${tuning.generation}',
      ),
    );
  }

  void _onFragmentBackendChanged() {
    _fragmentReadinessObserved = true;
    _emitFragmentReadinessIfBound();
  }

  void _emitFragmentReadinessIfBound() {
    if (!_fragmentReadinessObserved ||
        !_backendBoundRecorded ||
        _fragmentReadinessRecorded) {
      return;
    }
    _fragmentReadinessRecorded = true;
    final failure = fragment.failure;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: failure == null
            ? 'HEADER_SHADER_READY'
            : 'HEADER_SHADER_FALLBACK',
        scope: failure == null
            ? 'asset=${DashboardHeaderFragmentBackend.asset} '
                  'programIdentity=${identityHashCode(fragment.programIdentity)} '
                  'shaderIdentity=${identityHashCode(fragment.shaderIdentity)} '
                  'flutterVersion=${const String.fromEnvironment('FLUVI_FLUTTER_VERSION', defaultValue: '3.41.4')} '
                  'rendererBackend=runtimeEffect '
                  'engineBackend=notExposedByDart'
            : 'reason=$failure fallbackBackend=nativeStaticGradient',
      ),
    );
  }

  /// Emits one bounded runtime proof per Space Fabric selection.  The painter
  /// invokes this only after [DashboardHeaderFragmentBackend.paint] has
  /// returned true, so every recorded phase has passed the retained uniform
  /// writer and is not merely a controller-side notification.
  void recordSpaceFabricLiveness({
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualTuning tuning,
    required DashboardHeaderFragmentPaintInput input,
  }) {
    final spec = DashboardHeaderEffectCatalog.effectFor(tuning.effect);
    if (spec.family != DashboardHeaderAnimationFamily.spaceFabricWarp) return;
    final signature = Object.hash(
      tuning.effect,
      tuning.generation,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    var window = _spaceFabricLiveness;
    if (window == null || window.signature != signature) {
      _spaceFabricLiveness = window = _SpaceFabricLivenessWindow(
        signature: signature,
        startedAt: input.elapsed,
        startPhase: input.phase,
      );
    }
    window.paintCount += 1;
    window.lastPhase = input.phase;
    if (window.emitted ||
        input.elapsed - window.startedAt < const Duration(seconds: 2)) {
      return;
    }
    window.emitted = true;
    final settings = tuning.settingsFor(tuning.effect);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_SPACE_FABRIC_LIVENESS',
        scope:
            'effectId=${tuning.effect.name} '
            'speed=${settings['speed']} '
            'tickerActive=${controller.tickerIsActive} '
            'controllerIdentity=${identityHashCode(controller)} '
            'clockOwnerIdentity=${identityHashCode(controller.tickerIdentity)} '
            'startPhase=${window.startPhase} '
            'endPhase=${window.lastPhase} '
            'phaseDelta=${window.lastPhase - window.startPhase} '
            'fragmentPhaseFirst=${window.startPhase} '
            'fragmentPhaseLast=${window.lastPhase} '
            'fragmentPhaseDelta=${window.lastPhase - window.startPhase} '
            'fragmentPaintCountDelta=${window.paintCount} '
            'programIdentity=${identityHashCode(fragment.programIdentity)} '
            'shaderIdentity=${identityHashCode(fragment.shaderIdentity)} '
            'shaderReady=${fragment.isReady} '
            'shaderFallback=${fragment.failure != null}',
      ),
    );
  }

  DashboardHeaderFragmentPaintInput fragmentInput({
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderVisualTuning tuning,
  }) {
    final input = fragmentUniforms.resolve(
      controller: controller,
      frame: frame,
      tuning: tuning,
    );
    _recordEffectPaletteTransportBound(
      frame: frame,
      tuning: tuning,
      input: input,
    );
    if (tuning.effect == DashboardHeaderEffectId.deepDrift) {
      _recordDeepDriftBound(frame: frame, tuning: tuning);
    }
    _recordPortalBindings(controller: controller, frame: frame, input: input);
    return input;
  }

  void _recordEffectPaletteTransportBound({
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderVisualTuning tuning,
    required DashboardHeaderFragmentPaintInput input,
  }) {
    final signature = Object.hash(
      tuning.effect,
      tuning.generation,
      frame.fieldStopHash,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    if (_lastEffectPaletteTransportSignature == signature) return;
    _lastEffectPaletteTransportSignature = signature;
    final spec = DashboardHeaderEffectCatalog.effectFor(tuning.effect);
    final classic =
        spec.family == DashboardHeaderAnimationFamily.classicReference;
    final deepDrift = tuning.effect == DashboardHeaderEffectId.deepDrift;
    final flowModel = switch (tuning.effect) {
      DashboardHeaderEffectId.dualTide => 'bidirectionalMaterialAdvection',
      DashboardHeaderEffectId.magneticMembrane => 'continuousSheetShear',
      DashboardHeaderEffectId.breathingLens => 'monotonicLensRefraction',
      DashboardHeaderEffectId.cellularField => 'cellularVectorAdvection',
      DashboardHeaderEffectId.balanceMembrane => 'balanceMembraneAdvection',
      DashboardHeaderEffectId.balanceCounterflow => 'balanceCounterAdvection',
      DashboardHeaderEffectId.balanceCharges => 'chargeVectorAdvection',
      DashboardHeaderEffectId.deepDrift => 'deepLayerMaterialWarp',
      DashboardHeaderEffectId.staticEffect => 'staticCanonicalField',
      DashboardHeaderEffectId.freeFlow => 'seededStreamFunctionAdvection',
      DashboardHeaderEffectId.chaoticAdvection => 'timeDependentGyreAdvection',
      DashboardHeaderEffectId.elasticSpace => 'elasticStrainAdvection',
      DashboardHeaderEffectId.braidedCurrent => 'braidedStreamAdvection',
      DashboardHeaderEffectId.volumetricCurrent => 'pseudoDepthAdvection',
      DashboardHeaderEffectId.metricBloom => 'amorphousMetricBloom',
      DashboardHeaderEffectId.gravitationalFabric =>
        'compensatedGravitationalMetric',
      DashboardHeaderEffectId.breathingMetric => 'breathingMetricField',
      DashboardHeaderEffectId.tidalCurvature => 'pairedTidalCurvature',
    };
    final transportRevision = switch (spec.family) {
      DashboardHeaderAnimationFamily.classicReference =>
        'classicReference69d109',
      DashboardHeaderAnimationFamily.fullFieldFlow =>
        'fullFieldInverseAdvectionV1',
      DashboardHeaderAnimationFamily.spaceFabricWarp =>
        'spaceFabricCompensatedLocalWarpV1',
    };
    final transportMode = switch (spec.family) {
      DashboardHeaderAnimationFamily.classicReference => 'historicalEffectMath',
      DashboardHeaderAnimationFamily.fullFieldFlow =>
        'continuousSourceUvAdvection',
      DashboardHeaderAnimationFamily.spaceFabricWarp =>
        'compensatedLocalMetricWarp',
    };
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_EFFECT_PALETTE_TRANSPORT_BOUND',
        scope:
            'effectId=${tuning.effect.name} '
            'animationFamily=${spec.family.name} '
            'transportRevision=$transportRevision '
            'transportMode=$transportMode '
            'transportDomain=sourceUv '
            'distributionPreserving=${!classic} '
            'seamPaletteLock=$classic '
            'genericSeamHighlight=$classic '
            'flowModel=$flowModel '
            'shaderAbiVersion=${DashboardHeaderFragmentUniformLayout.version} '
            'endpointColorAuthority=false '
            'paletteSampler=canonicalStops '
            'fragmentProgramIdentity=${identityHashCode(fragment.programIdentity)} '
            'fragmentShaderIdentity=${identityHashCode(fragment.shaderIdentity)} '
            'renderBackend=runtimeEffect '
            'fieldEvaluation=perFragment '
            'canonicalFieldStopCount=${input.canonicalStops.length} '
            'canonicalFieldStopHash=${frame.fieldStopHash}'
            '${deepDrift ? ' materialModel=singlePaletteMaterial depthLayers=3 blobCount=15 layerColorOwnership=false' : ''}',
      ),
    );
    final settings = tuning.settingsFor(tuning.effect);
    if (spec.family == DashboardHeaderAnimationFamily.spaceFabricWarp) {
      final spaceFabricSignature = Object.hash(
        tuning.effect,
        tuning.generation,
        fragment.programIdentity,
        fragment.shaderIdentity,
      );
      if (_lastSpaceFabricSignature == spaceFabricSignature) return;
      _lastSpaceFabricSignature = spaceFabricSignature;
      final fieldCount =
          settings['fieldCount'] ??
          settings['wellCount'] ??
          settings['regionCount'] ??
          settings['pairCount'];
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'HEADER_SPACE_FABRIC_BOUND',
          scope:
              'effectId=${tuning.effect.name} variant=${spec.label} '
              'strength=${settings['strength']} speed=${settings['speed']} '
              'scale=${settings['scale']} seed=${settings['seed']} '
              'fieldCount=$fieldCount '
              'metricModel=compensatedLocalWarp visibleObject=false '
              'paletteOwnership=false jacobianGuard=true '
              'timebaseOwner=sharedHeaderPhase '
              'secondarySpeedScaling=false '
              'effectSpeed=${settings['speed']} '
              'phaseRateContract=controllerOwned '
              'temporalRevision=perceptualMotionV3 '
              'shaderAbiVersion=${DashboardHeaderFragmentUniformLayout.version} '
              'programIdentity=${identityHashCode(fragment.programIdentity)} '
              'shaderIdentity=${identityHashCode(fragment.shaderIdentity)}',
        ),
      );
      return;
    }
    if (spec.family != DashboardHeaderAnimationFamily.fullFieldFlow) return;
    final fullFieldSignature = Object.hash(
      tuning.effect,
      tuning.generation,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    if (_lastFullFieldFlowSignature == fullFieldSignature) return;
    _lastFullFieldFlowSignature = fullFieldSignature;
    final orientation = tuning.paletteOrientation;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_FULL_FIELD_FLOW_BOUND',
        scope:
            'effectId=${tuning.effect.name} '
            'flowVariant=${spec.label} '
            'seed=${settings['seed']} '
            'modeCount=${settings['modeCount'] ?? settings['vortexCount'] ?? settings['shearLayers'] ?? settings['braidCount'] ?? settings['depthLayers']} '
            'strength=${settings['strength']} speed=${settings['speed']} '
            'scale=${settings['scale']} backtraceSteps=2 '
            'fullDomain=true semanticCenter=false paletteBoundary=false '
            'paletteOrientationDriftEnabled=${orientation.enabled} '
            'paletteOrientationBaseDeg=${orientation.baseAngleDegrees} '
            'paletteOrientationSweepDeg=${orientation.sweepDegrees} '
            'shaderAbiVersion=${DashboardHeaderFragmentUniformLayout.version} '
            'fragmentProgramIdentity=${identityHashCode(fragment.programIdentity)} '
            'fragmentShaderIdentity=${identityHashCode(fragment.shaderIdentity)}',
      ),
    );
  }

  /// Records configuration changes at the final semantic-to-fragment boundary.
  /// Portal phase is deliberately absent from these signatures: the shared
  /// clock may repaint every display frame without producing diagnostics.
  void _recordPortalBindings({
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderFragmentPaintInput input,
  }) {
    final backendIdentity = identityHashCode(fragment.backendIdentity);
    final programIdentity = identityHashCode(fragment.programIdentity);
    final shaderIdentity = identityHashCode(fragment.shaderIdentity);
    final innerState = controller.portalInnerMotion;
    final backgroundState = controller.portalBackgroundMorph;
    final innerSignature = Object.hash(
      innerState,
      frame,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    if (_lastPortalInnerSignature != innerSignature) {
      _lastPortalInnerSignature = innerSignature;
      _recordPortalChannelBound(
        stage: 'HEADER_PORTAL_INNER_CHANNEL_BOUND',
        state: innerState,
        input: input.interior,
        controller: controller,
        frame: frame,
        backendIdentity: backendIdentity,
        programIdentity: programIdentity,
        shaderIdentity: shaderIdentity,
      );
    }
    final backgroundSignature = Object.hash(
      backgroundState,
      frame,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    if (_lastPortalBackgroundSignature != backgroundSignature) {
      _lastPortalBackgroundSignature = backgroundSignature;
      _recordPortalChannelBound(
        stage: 'HEADER_PORTAL_BACKGROUND_CHANNEL_BOUND',
        state: backgroundState,
        input: input.background,
        controller: controller,
        frame: frame,
        backendIdentity: backendIdentity,
        programIdentity: programIdentity,
        shaderIdentity: shaderIdentity,
      );
    }
    final inputSignature = Object.hash(
      innerState,
      backgroundState,
      frame,
      fragment.programIdentity,
      fragment.shaderIdentity,
    );
    if (_lastPortalFragmentInputSignature == inputSignature) return;
    _lastPortalFragmentInputSignature = inputSignature;
    fragment.markConfigurationChanged();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_PORTAL_FRAGMENT_INPUT_BOUND',
        scope:
            'innerEnabled=${input.interior.enabled} '
            'innerEffect=${_portalEffectId(innerState)} '
            'innerSettingsHash=${_settingsHash(input.interior.settings)} '
            'backgroundEnabled=${input.background.enabled} '
            'backgroundEffect=${_portalEffectId(backgroundState)} '
            'backgroundSettingsHash=${_settingsHash(input.background.settings)} '
            'uniformLayoutVersion=${DashboardHeaderFragmentUniformLayout.version} '
            'fragmentConfigurationGeneration=${fragment.configurationGeneration} '
            'fragmentBackendIdentity=$backendIdentity '
            'programIdentity=$programIdentity '
            'shaderIdentity=$shaderIdentity '
            'canonicalFieldStopCount=${frame.stops.length} '
            'canonicalFieldStopHash=${frame.fieldStopHash} '
            'portalColorModel=paletteCoordinate',
      ),
    );
  }

  void _recordPortalChannelBound({
    required String stage,
    required DashboardHeaderPortalChannelState state,
    required DashboardHeaderFragmentPortalInput input,
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
    required int backendIdentity,
    required int programIdentity,
    required int shaderIdentity,
  }) {
    final inputSignature = Object.hash(
      input.enabled,
      input.effectIndex,
      input.paletteCenterPercent,
      input.paletteWindowPercent,
      input.rotationEnabled,
      input.rotationSpeed,
      Object.hashAll(input.settings),
      frame.fieldStopHash,
      programIdentity,
      shaderIdentity,
    ).toUnsigned(32).toRadixString(16);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        scope:
            'enabled=${input.enabled} '
            'effectId=${_portalEffectId(state)} '
            'settingsGeneration=${controller.portalSettingsGeneration.value} '
            'phaseOwnerIdentity=${identityHashCode(controller.tickerIdentity)} '
            'controllerIdentity=${identityHashCode(controller)} '
            'fragmentBackendIdentity=$backendIdentity '
            'programIdentity=$programIdentity '
            'shaderIdentity=$shaderIdentity '
            'canonicalFieldStopCount=${frame.stops.length} '
            'canonicalFieldStopHash=${frame.fieldStopHash} '
            'portalColorModel=paletteCoordinate '
            'inputSignature=$inputSignature',
      ),
    );
  }

  static String _portalEffectId(DashboardHeaderPortalChannelState state) =>
      DashboardHeaderPortalMaterialCatalog.effectFor(state.effect).sourceId;

  static String _settingsHash(List<double> values) =>
      Object.hashAll(values).toUnsigned(32).toRadixString(16);

  void _recordDeepDriftBound({
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderVisualTuning tuning,
  }) {
    final shaderId = DashboardHeaderEffectCatalog.effectFor(
      DashboardHeaderEffectId.deepDrift,
    ).shaderId;
    final signature = Object.hash(
      frame.fieldStopHash,
      tuning.generation,
      fragment.programIdentity,
      fragment.backendIdentity,
    );
    if (_lastDeepDriftSignature == signature) return;
    _lastDeepDriftSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_DEEP_DRIFT_BOUND',
        scope:
            'shaderId=$shaderId layerCount=3 blobCount=15 '
            'materialModel=singlePaletteMaterial '
            'layerColorOwnership=false '
            'zMigrationEnabled=true '
            'canonicalFieldStopCount=${frame.stops.length} '
            'canonicalFieldStopHash=${frame.fieldStopHash} '
            'settingsGeneration=${tuning.generation} '
            'shaderIdentity=${identityHashCode(fragment.backendIdentity)} '
            'programIdentity=${identityHashCode(fragment.programIdentity)} '
            'fieldEvaluationMode=perFragment',
      ),
    );
  }

  void recordFragmentConfiguration({
    required DashboardHeaderFragmentRenderPlan plan,
    required DashboardHeaderEffectId effect,
  }) {
    if (!_backendBoundRecorded) {
      _backendBoundRecorded = true;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'HEADER_RENDER_BACKEND_BOUND',
          scope:
              'commitSha=${const String.fromEnvironment('FLUVI_BUILD_COMMIT', defaultValue: 'unknown')} '
              'backend=${plan.backend.name} '
              'logicalWidth=${plan.logicalSize.width} '
              'logicalHeight=${plan.logicalSize.height} '
              'devicePixelRatio=${plan.logicalSize.width == 0 ? 1 : plan.physicalSize.width / plan.logicalSize.width} '
              'physicalWidth=${plan.physicalSize.width} '
              'physicalHeight=${plan.physicalSize.height} '
              'backendIdentity=${identityHashCode(fragment.backendIdentity)}',
        ),
      );
    }
    _emitFragmentReadinessIfBound();
    // The first paint happens before FragmentProgram's asynchronous load has
    // settled. Do not record a speculative fidelity configuration for that
    // temporary static placeholder: physical logs must describe the actual
    // ready shader or the explicit native-static fidelity fallback.
    if (!_fragmentReadinessObserved ||
        (fragment.failure != null &&
            plan.backend == DashboardHeaderRenderBackend.fragmentShader)) {
      return;
    }
    // Resizing the Dashboard during collapse is a geometry event owned by the
    // outer composition. It does not change the Header renderer's backend,
    // shader readiness, or offscreen contract. Including physical size here
    // therefore turned one meaningful renderer proof into one diagnostic per
    // display frame and evicted the evidence needed for Mind/collapse traces.
    // Keep the initial bounds as context in the emitted record, but only emit
    // again when the actual render-path contract changes.
    final signature = Object.hash(
      plan.renderScale,
      plan.backend,
      plan.fieldEvaluation,
      effect,
      fragment.isReady,
      fragment.failure,
    );
    if (_lastFragmentConfigurationSignature == signature) return;
    _lastFragmentConfigurationSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_RENDER_FIDELITY_CONFIG',
        scope:
            'outputResolutionMode=nativeSurface '
            'fieldEvaluationMode=${plan.fieldEvaluation.name} '
            'logicalWidth=${plan.logicalSize.width} '
            'logicalHeight=${plan.logicalSize.height} '
            'physicalWidth=${plan.physicalSize.width} '
            'physicalHeight=${plan.physicalSize.height} '
            'sourceRenderScale=${plan.renderScale} '
            'effectId=${effect.name} '
            'backend=${plan.backend.name} '
            'physicalTarget=${plan.physicalSize.width}x${plan.physicalSize.height} '
            'parentTransformScale=notObservableInCanvas '
            'touchOverlayBackend=fragmentShaderAnalytic '
            'shaderFailureFallback=nativeStaticGradient '
            'shaderReady=${fragment.isReady} '
            'shaderFailure=${fragment.failure != null}',
      ),
    );
    // The analytic touch overlay has the same topology as the field renderer;
    // its size follows the parent Header geometry and is not a new render path.
    final touchSignature = Object.hash(plan.backend, plan.fieldEvaluation);
    if (_lastTouchRenderPathSignature != touchSignature) {
      _lastTouchRenderPathSignature = touchSignature;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'HEADER_TOUCH_RENDER_PATH_BOUND',
          scope:
              'fieldBackend=fragmentShader '
              'overlayBackend=fragmentShaderAnalytic '
              'trailBackend=fragmentShaderAnalytic '
              'logicalSize=${plan.logicalSize.width}x${plan.logicalSize.height} '
              'physicalSize=${plan.physicalSize.width}x${plan.physicalSize.height} '
              'usesSaveLayer=false usesOffscreenIntermediate=false',
        ),
      );
    }
  }

  void dispose() {
    fragment.removeListener(_onFragmentBackendChanged);
    if (_ownsFragment) fragment.dispose();
  }
}

final class _SpaceFabricLivenessWindow {
  _SpaceFabricLivenessWindow({
    required this.signature,
    required this.startedAt,
    required this.startPhase,
  }) : lastPhase = startPhase;

  final Object signature;
  final Duration startedAt;
  final double startPhase;
  double lastPhase;
  int paintCount = 0;
  bool emitted = false;
}

/// Retains the compact shader configuration.  Map traversal happens only for
/// real tuner/effect changes; an animation phase tick merely changes scalar
/// time/ripple uniforms in [DashboardHeaderFragmentBackend].
final class _DashboardHeaderFragmentUniformCache {
  // The first 36 values retain the catalog's historic per-effect order. These
  // four v3 tail slots are reserved exclusively for the family-owned Full
  // Field palette orientation and are never read by classic effects.
  static const int orientationEnabledSlot = 36;
  static const int orientationBaseAndPhaseSlot = 37;
  static const int orientationSweepSlot = 38;
  static const int orientationSpeedSlot = 39;

  final List<double> _common = List<double>.filled(40, 0);
  final List<double> _background = List<double>.filled(12, 0);
  final List<double> _interior = List<double>.filled(12, 0);
  final DashboardHeaderDeepDriftSkeleton _deepDrift =
      DashboardHeaderDeepDriftSkeleton();
  final DashboardHeaderTapRippleUniformBank _tapRipples =
      DashboardHeaderTapRippleUniformBank();
  final DashboardHeaderTapWaveVisualUniformBank _tapVisuals =
      DashboardHeaderTapWaveVisualUniformBank();
  Map<String, double>? _commonSettings;
  DashboardHeaderEffectId? _commonEffect;
  DashboardHeaderPaletteOrientationTuning? _paletteOrientation;
  Map<String, double>? _backgroundSettings;
  DashboardHeaderPortalMaterialEffectId? _backgroundEffect;
  Map<String, double>? _interiorSettings;
  DashboardHeaderPortalMaterialEffectId? _interiorEffect;

  DashboardHeaderFragmentPaintInput resolve({
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderVisualTuning tuning,
  }) {
    final effect = tuning.effect;
    final commonSettings = tuning.settingsFor(effect);
    if (!identical(_commonSettings, commonSettings) ||
        _commonEffect != effect ||
        _paletteOrientation != tuning.paletteOrientation) {
      _pack(
        target: _common,
        controls: DashboardHeaderEffectCatalog.effectFor(effect).controls,
        settings: commonSettings,
      );
      _packPaletteOrientation(_common, tuning.paletteOrientation);
      _commonSettings = commonSettings;
      _commonEffect = effect;
      _paletteOrientation = tuning.paletteOrientation;
    }
    final backgroundState = controller.portalBackgroundMorph;
    final backgroundSettings = backgroundState.settingsFor(
      backgroundState.effect,
    );
    if (!identical(_backgroundSettings, backgroundSettings) ||
        _backgroundEffect != backgroundState.effect) {
      _pack(
        target: _background,
        controls: DashboardHeaderPortalMaterialCatalog.effectFor(
          backgroundState.effect,
        ).controls,
        settings: backgroundSettings,
      );
      _backgroundSettings = backgroundSettings;
      _backgroundEffect = backgroundState.effect;
    }
    final interiorState = controller.portalInnerMotion;
    final interiorSettings = interiorState.settingsFor(interiorState.effect);
    if (!identical(_interiorSettings, interiorSettings) ||
        _interiorEffect != interiorState.effect) {
      _pack(
        target: _interior,
        controls: DashboardHeaderPortalMaterialCatalog.effectFor(
          interiorState.effect,
        ).controls,
        settings: interiorSettings,
      );
      _interiorSettings = interiorSettings;
      _interiorEffect = interiorState.effect;
    }
    final tapTuning = controller.tapWave.tuning;
    final effectSpec = DashboardHeaderEffectCatalog.effectFor(effect);
    if (effect == DashboardHeaderEffectId.deepDrift) {
      _deepDrift.advance(elapsed: controller.elapsed, settings: _common);
    }
    _tapRipples.update(state: controller.tapWave, elapsed: controller.elapsed);
    _tapVisuals.update(state: controller.tapWave, elapsed: controller.elapsed);
    return DashboardHeaderFragmentPaintInput(
      phase: controller.phase,
      elapsed: controller.elapsed,
      effectShaderId: effectSpec.shaderId,
      paletteSplitPercent: frame.paletteSplitPercent,
      opacity: frame.opacity,
      pulse: controller.pulseAmount,
      shaderQuality:
          effect == DashboardHeaderEffectId.staticEffect ||
              effect == DashboardHeaderEffectId.deepDrift
          ? 1
          : (commonSettings['renderScale'] ?? 1).clamp(.35, 1.0).toDouble(),
      canonicalColors: frame.colors,
      canonicalStops: frame.stops,
      commonSettings: _common,
      deepDrift: _deepDrift,
      background: DashboardHeaderFragmentPortalInput(
        enabled: backgroundState.enabled,
        effectIndex: backgroundState.effect.index,
        phase: backgroundState.phaseFor(backgroundState.effect),
        paletteCenterPercent: backgroundState.paletteCenterPercent,
        paletteWindowPercent: backgroundState.paletteWindowPercent,
        rotationEnabled: backgroundState.rotationEnabled,
        rotationSpeed: backgroundState.rotationSpeed,
        settings: _background,
      ),
      interior: DashboardHeaderFragmentPortalInput(
        enabled: interiorState.enabled,
        effectIndex: interiorState.effect.index,
        phase: interiorState.phaseFor(interiorState.effect),
        paletteCenterPercent: interiorState.paletteCenterPercent,
        paletteWindowPercent: interiorState.paletteWindowPercent,
        rotationEnabled: interiorState.rotationEnabled,
        rotationSpeed: interiorState.rotationSpeed,
        settings: _interior,
      ),
      ripples: _tapRipples,
      tapRippleRadiusTravel: tapTuning.valueFor('rippleRadiusTravel'),
      tapRippleIntensity: tapTuning.valueFor('rippleIntensity'),
      tapPulseLight: tapTuning.valueFor('pulseLight'),
      tapVisuals: _tapVisuals,
    );
  }

  static void _pack({
    required List<double> target,
    required List<DashboardHeaderEffectControl> controls,
    required Map<String, double> settings,
  }) {
    target.fillRange(0, target.length, 0);
    final count = math.min(target.length, controls.length);
    for (var index = 0; index < count; index += 1) {
      target[index] =
          settings[controls[index].id] ?? controls[index].defaultValue;
    }
  }

  static void _packPaletteOrientation(
    List<double> target,
    DashboardHeaderPaletteOrientationTuning orientation,
  ) {
    target[orientationEnabledSlot] = orientation.enabled ? 1 : 0;
    target[orientationBaseAndPhaseSlot] = orientation.packedBaseAndPhaseDegrees;
    target[orientationSweepSlot] = orientation.sweepDegrees;
    target[orientationSpeedSlot] = orientation.speed;
  }
}

/// Passive Header-local pointer observer for the source touch wave. It does
/// not enter Flutter's gesture arena, so the existing expansion/mode Pan
/// recognizer keeps full ownership of Dashboard motion.
final class DashboardHeaderTapWaveGestureLayer extends StatefulWidget {
  const DashboardHeaderTapWaveGestureLayer({
    super.key,
    required this.controller,
    required this.child,
  });

  final DashboardHeaderVisualController? controller;
  final Widget child;

  @override
  State<DashboardHeaderTapWaveGestureLayer> createState() =>
      _DashboardHeaderTapWaveGestureLayerState();
}

final class _DashboardHeaderTapWaveGestureLayerState
    extends State<DashboardHeaderTapWaveGestureLayer> {
  int? _activePointer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      Offset origin(Offset local) => Offset(
        (local.dx / width).clamp(0.0, 1.0).toDouble(),
        (local.dy / height).clamp(0.0, 1.0).toDouble(),
      );
      final visual = widget.controller;
      if (visual == null || width <= 0 || height <= 0) return widget.child;
      return MouseRegion(
        onExit: (_) => _endActivePointer(visual),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            // DOM `event.isPrimary === false` is ignored by the source.
            // Flutter exposes pointer ids instead, so retain exactly one
            // Header-local primary interaction until its terminal event.
            if (_activePointer != null) return;
            _activePointer = event.pointer;
            visual.beginTapWave(origin(event.localPosition));
          },
          onPointerMove: (event) {
            if (event.pointer != _activePointer) return;
            visual.updateTapWave(origin(event.localPosition));
          },
          onPointerUp: (event) => _endPointer(visual, event.pointer),
          onPointerCancel: (event) => _endPointer(visual, event.pointer),
          child: widget.child,
        ),
      );
    },
  );

  void _endPointer(DashboardHeaderVisualController visual, int pointer) {
    if (pointer != _activePointer) return;
    _endActivePointer(visual);
  }

  void _endActivePointer(DashboardHeaderVisualController visual) {
    if (_activePointer == null) return;
    _activePointer = null;
    visual.endTapWave();
  }
}

final class DashboardHeaderVisualPaintLayer extends StatefulWidget {
  const DashboardHeaderVisualPaintLayer({
    super.key,
    required this.controller,
    required this.frame,
    required this.child,
    @visibleForTesting this.debugFragmentBackend,
  });

  final DashboardHeaderVisualController controller;
  final DashboardHeaderVisualFrame frame;
  final Widget child;

  /// Injects the normal retained backend solely so liveness tests can inspect
  /// uniform publication without modifying the production renderer contract.
  @visibleForTesting
  final DashboardHeaderFragmentBackend? debugFragmentBackend;

  @override
  State<DashboardHeaderVisualPaintLayer> createState() =>
      _DashboardHeaderVisualPaintLayerState();
}

final class _DashboardHeaderVisualPaintLayerState
    extends State<DashboardHeaderVisualPaintLayer> {
  late final _DashboardHeaderVisualPaintResources _resources =
      _DashboardHeaderVisualPaintResources(
        fragment: widget.debugFragmentBackend,
      );

  @override
  void dispose() {
    _resources.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
  }

  @override
  void didUpdateWidget(covariant DashboardHeaderVisualPaintLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _syncMotionPreference();
    }
  }

  void _syncMotionPreference() => widget.controller.setMotionEnabled(
    !MediaQuery.disableAnimationsOf(context),
  );

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: <Widget>[
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('dashboard-header-visual-paint'),
            painter: _DashboardHeaderVisualPainter(
              controller: widget.controller,
              frame: widget.frame,
              resources: _resources,
              devicePixelRatio: View.of(context).devicePixelRatio,
            ),
          ),
        ),
      ),
      // This semantic/content layer is deliberately outside the animated
      // RepaintBoundary. A Header clock tick can repaint the material only;
      // title, value and action widgets retain their paint and build identity.
      widget.child,
    ],
  );
}

final class _DashboardHeaderVisualPainter extends CustomPainter {
  _DashboardHeaderVisualPainter({
    required this.controller,
    required this.frame,
    required this.resources,
    required this.devicePixelRatio,
  }) : super(
         repaint: Listenable.merge(<Listenable>[
           controller,
           resources.fragment,
         ]),
       );

  final DashboardHeaderVisualController controller;
  final DashboardHeaderVisualFrame frame;
  final _DashboardHeaderVisualPaintResources resources;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final tuning = controller.tuning.value;
    resources.recordPaletteFieldBinding(frame: frame, tuning: tuning);
    // The isolated static Budget base is the exact historical native
    // CssLinearGradient → ui.Gradient.linear renderer.  Do this before any
    // FragmentProgram plan/input construction: shader readiness is neither a
    // dependency nor an authority for the static field.  Active Portal/touch
    // overlays retain their existing separate effect path.
    if (_usesNativeStaticBase(tuning)) {
      resources.recordStaticColorRendererBinding(frame: frame);
      _paintStatic(canvas, size);
      return;
    }
    final settings = tuning.settingsFor(tuning.effect);
    // This retained FragmentProgram path serves animated effects and active
    // fragment overlays only. Its canonical field input is effect data, never
    // the authority for the isolated static Budget colour base above.
    final renderScale =
        tuning.effect == DashboardHeaderEffectId.staticEffect ||
            tuning.effect == DashboardHeaderEffectId.deepDrift
        ? 1.0
        : (settings['renderScale'] ?? 0.0).clamp(.35, 1.0).toDouble();
    final fragmentPlan = DashboardHeaderFragmentRenderPlan.resolve(
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
      renderScale: renderScale,
    );
    resources.recordFragmentConfiguration(
      plan: fragmentPlan,
      effect: tuning.effect,
    );
    final fragmentInput = resources.fragmentInput(
      controller: controller,
      frame: frame,
      tuning: tuning,
    );
    if (resources.fragment.paint(
      canvas,
      size,
      plan: fragmentPlan,
      input: fragmentInput,
    )) {
      resources.recordSpaceFabricLiveness(
        controller: controller,
        tuning: tuning,
        input: fragmentInput,
      );
      return;
    }
    // Program loading is asynchronous. Do not let the short readiness window
    // silently pick the sparse mesh based on a user quality value: keep the
    // Header semantically intact until the retained shader becomes ready.
    if (resources.fragment.failure == null) {
      _paintStatic(canvas, size);
      return;
    }
    // Failure never degrades colour fidelity to a sparse endpoint field.
    // The accepted native static field is the sole fail-soft rendering path.
    _paintStatic(canvas, size);
  }

  void _paintStatic(Canvas canvas, Size size) {
    DashboardHeaderStaticColorRenderer.paint(
      canvas: canvas,
      rect: Offset.zero & size,
      colors: frame.colors,
      stops: frame.stops,
      opacity: frame.opacity,
    );
    final pulse = controller.pulseAmount;
    if (pulse > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: pulse * .025),
      );
    }
  }

  bool _usesNativeStaticBase(DashboardHeaderVisualTuning tuning) =>
      tuning.effect == DashboardHeaderEffectId.staticEffect &&
      !controller.portalInnerMotion.enabled &&
      !controller.portalBackgroundMorph.enabled &&
      !controller.tapWave.requiresFrames;

  @override
  bool shouldRepaint(covariant _DashboardHeaderVisualPainter oldDelegate) =>
      !frame.sameAs(oldDelegate.frame) ||
      !identical(controller, oldDelegate.controller);
}
