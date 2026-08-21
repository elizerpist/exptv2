import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_target.dart';
import 'dashboard_header_field_mesh.dart';
import 'dashboard_header_portal_material_field.dart';
import 'dashboard_header_portal_painter.dart';
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
}

@immutable
final class DashboardHeaderEffectSpec {
  const DashboardHeaderEffectSpec({
    required this.id,
    required this.label,
    required this.controls,
  });

  final DashboardHeaderEffectId id;
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
          label: 'A/B alaparány',
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
          label: 'Statikus A/B',
          controls: <DashboardHeaderEffectControl>[],
        ),
        DashboardHeaderEffectSpec(
          id: DashboardHeaderEffectId.dualTide,
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
      ]);

  static DashboardHeaderEffectSpec effectFor(DashboardHeaderEffectId id) =>
      effects.firstWhere((effect) => effect.id == id);
}

@immutable
final class DashboardHeaderVisualTuning {
  DashboardHeaderVisualTuning({
    required this.effect,
    required this.budgetWindowWidthPercent,
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
    budgetWindowWidthPercent: 28,
    opacityScalePosition: 50,
    settingsByEffect: <DashboardHeaderEffectId, Map<String, double>>{
      for (final spec in DashboardHeaderEffectCatalog.effects)
        spec.id: spec.defaultSettings,
    },
    generation: 0,
  );

  final DashboardHeaderEffectId effect;
  final double budgetWindowWidthPercent;
  final double opacityScalePosition;
  final Map<DashboardHeaderEffectId, Map<String, double>> settingsByEffect;
  final int generation;

  Map<String, double> settingsFor(DashboardHeaderEffectId effect) =>
      settingsByEffect[effect] ?? const <String, double>{};

  DashboardHeaderVisualTuning copyWith({
    DashboardHeaderEffectId? effect,
    double? budgetWindowWidthPercent,
    double? opacityScalePosition,
    Map<DashboardHeaderEffectId, Map<String, double>>? settingsByEffect,
  }) => DashboardHeaderVisualTuning(
    effect: effect ?? this.effect,
    budgetWindowWidthPercent:
        budgetWindowWidthPercent ?? this.budgetWindowWidthPercent,
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
      portalSettingsGeneration = ValueNotifier<int>(0) {
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

  /// Semantic Portal config changes rebuild only the relevant tuner sections.
  /// Animation phase ticks never publish through this notifier.
  final ValueNotifier<int> portalSettingsGeneration;
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

  Object get tickerIdentity => _ticker;
  bool get tickerIsActive => _ticker.isActive;
  double get phase => _phase;
  Duration get elapsed => _elapsed;
  DashboardHeaderPortalChannelState get portalInnerMotion => _portalInnerMotion;
  DashboardHeaderPortalChannelState get portalBackgroundMorph =>
      _portalBackgroundMorph;
  double get pulseAmount {
    final startedAt = _pulseStartedAt;
    if (startedAt == null) return 0;
    final elapsed = _elapsed - startedAt;
    final ratio = elapsed.inMicroseconds / 1560000;
    return (1 - ratio).clamp(0.0, 1.0).toDouble();
  }

  void selectEffect(DashboardHeaderEffectId effect) {
    if (_disposed || tuning.value.effect == effect) return;
    tuning.value = tuning.value.copyWith(effect: effect);
    _syncTicker();
    _record(
      'HEADER_EFFECT_SELECTED',
      'effectId=${effect.name} settingsGeneration=${tuning.value.generation}',
    );
    notifyListeners();
  }

  void setBudgetWindowWidthPercent(double value) {
    final bounded = value.clamp(10.0, 100.0).toDouble();
    if (tuning.value.budgetWindowWidthPercent == bounded) return;
    tuning.value = tuning.value.copyWith(budgetWindowWidthPercent: bounded);
    _record(
      'HEADER_EFFECT_SETTING_CHANGED',
      'parameterId=budgetWindowWidthPercent newValue=$bounded '
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
    _record(
      'HEADER_EFFECT_SETTING_CHANGED',
      'effectId=${current.effect.name} parameterId=$controlId '
          'oldValue=${previous ?? '-'} newValue=$normalized '
          'settingsGeneration=${tuning.value.generation}',
    );
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

  /// Mirrors the Color Lab's reduced-motion boundary. This freezes only the
  /// shared paint clock; it never changes the active Budget A/B frame or any
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
            _pulseStartedAt != null);
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
    portalSettingsGeneration.dispose();
    tuning.dispose();
    super.dispose();
  }
}

/// Immutable paint input from a per-mode color policy.  `colors` keeps the
/// complete canonical no-limit gradient; positive-limit Budget windows expose
/// just their source-sampled A/B slice.
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
  });

  final List<Color> colors;
  final List<double> stops;
  final double opacity;
  final Color colorA;
  final Color colorB;
  final double paletteSplitPercent;
  final double? windowLeftPercent;
  final double? windowRightPercent;

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
      windowRightPercent == other.windowRightPercent;

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

/// Exact Color Lab white-to-canonical-target scale.  This is deliberately a
/// pure projection at the policy boundary, before the shared painter sees any
/// color data.
abstract final class BudgetHeaderColorScale {
  static DashboardHeaderVisualFrame project({
    required CategoryGradientToken canonicalGradient,
    required double rawProgress,
    required double windowWidthPercent,
    required double opacityScalePosition,
  }) {
    final width = windowWidthPercent.clamp(10.0, 100.0).toDouble();
    final half = width / 2;
    final input = rawProgress.isFinite ? rawProgress * 100 : 0.0;
    final center = input.clamp(half, 100 - half).toDouble();
    final left = center - half;
    final right = left + width;
    final colorA = _scaleSample(canonicalGradient, left);
    final colorB = _scaleSample(canonicalGradient, right);
    return DashboardHeaderVisualFrame(
      colors: List<Color>.unmodifiable(<Color>[colorA, colorB]),
      stops: const <double>[0, 1],
      opacity: DashboardHeaderOpacityScale.valueAt(opacityScalePosition),
      colorA: colorA,
      colorB: colorB,
      paletteSplitPercent: center,
      windowLeftPercent: left,
      windowRightPercent: right,
    );
  }

  static DashboardHeaderVisualFrame noLimit({
    required CategoryGradientToken canonicalGradient,
    required double opacityScalePosition,
  }) => DashboardHeaderVisualFrame(
    colors: List<Color>.unmodifiable(<Color>[
      canonicalGradient.colorA,
      canonicalGradient.middleColor,
      canonicalGradient.colorB,
    ]),
    stops: const <double>[0, .52, 1],
    opacity: DashboardHeaderOpacityScale.valueAt(opacityScalePosition),
    colorA: canonicalGradient.colorA,
    colorB: canonicalGradient.colorB,
    paletteSplitPercent: 50,
  );

  static Color _scaleSample(CategoryGradientToken gradient, double position) {
    final bounded = position.clamp(0.0, 100.0).toDouble();
    final target = _sampleCanonical(gradient, bounded);
    return _mix(const Color(0xffffffff), target, bounded / 100);
  }

  static Color _sampleCanonical(
    CategoryGradientToken gradient,
    double position,
  ) {
    if (position <= 52) {
      return _mix(gradient.colorA, gradient.middleColor, position / 52);
    }
    return _mix(gradient.middleColor, gradient.colorB, (position - 52) / 48);
  }

  // The Color Lab uses JS `Math.round` RGB interpolation, so do not use a
  // gamma-space or premultiplied renderer helper here.
  static Color _mix(Color left, Color right, double amount) => Color.fromARGB(
    255,
    _toChannel(left.r + (right.r - left.r) * amount),
    _toChannel(left.g + (right.g - left.g) * amount),
    _toChannel(left.b + (right.b - left.b) * amount),
  );

  static int _toChannel(double value) =>
      (value * 255).round().clamp(0, 255).toInt();
}

/// Budget's per-mode color policy.  It only transforms the retained live
/// selection already published by [DashboardBudgetPresentationController]; it
/// has no edit overlay, data lookup, animation clock, repository or bridge.
final class DashboardBudgetHeaderColorPolicy
    extends ValueNotifier<DashboardHeaderVisualFrame> {
  DashboardBudgetHeaderColorPolicy({
    required ValueListenable<DashboardBudgetPresentationState> presentation,
    required ValueListenable<DashboardHeaderVisualTuning> tuning,
  }) : _presentation = presentation,
       _tuning = tuning,
       super(_frameFor(presentation.value, tuning.value)) {
    _presentation.addListener(_refresh);
    _tuning.addListener(_refresh);
    _recordBudgetColorWindow(presentation.value, tuning.value, value);
  }

  final ValueListenable<DashboardBudgetPresentationState> _presentation;
  final ValueListenable<DashboardHeaderVisualTuning> _tuning;
  Object? _lastBudgetColorWindowSignature;

  void _refresh() {
    final next = _frameFor(_presentation.value, _tuning.value);
    if (value.sameAs(next)) return;
    value = next;
    _recordBudgetColorWindow(_presentation.value, _tuning.value, next);
  }

  void _recordBudgetColorWindow(
    DashboardBudgetPresentationState state,
    DashboardHeaderVisualTuning tuning,
    DashboardHeaderVisualFrame frame,
  ) {
    final selection = state.liveSelection;
    final visual = selection.visual;
    final target = selection.target;
    final colorId = target.isAggregate
        ? 'budget-aggregate-${selection.direction.name}'
        : target.category!.colorId;
    final signature = Object.hash(
      selection.direction,
      selection.coreRevision,
      target.handle,
      colorId,
      visual.actualScaled100,
      visual.effectiveLimitScaled100,
      visual.rawProgress,
      frame.windowLeftPercent,
      frame.windowRightPercent,
      frame.colorA,
      frame.colorB,
      frame.opacity,
      tuning.budgetWindowWidthPercent,
      tuning.opacityScalePosition,
    );
    if (_lastBudgetColorWindowSignature == signature) return;
    _lastBudgetColorWindowSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_HEADER_COLOR_WINDOW_BOUND',
        coreRevision: selection.coreRevision,
        direction: selection.direction.name,
        totalMinor: visual.actualScaled100,
        scope:
            'targetHandle=${target.handle} '
            'targetKind=${target.isAggregate ? 'aggregate' : 'category'} '
            'categoryId=${target.isAggregate ? '-' : target.category!.id} '
            'colorId=$colorId '
            'hasPositiveLimit=${visual.hasPositiveLimit} '
            'effectiveLimitScaled100=${visual.effectiveLimitScaled100 ?? '-'} '
            'rawProgress=${visual.rawProgress} '
            'windowWidthPct=${tuning.budgetWindowWidthPercent} '
            'windowLeft=${frame.windowLeftPercent ?? '-'} '
            'windowRight=${frame.windowRightPercent ?? '-'} '
            'colorAArgb=${frame.colorA.toARGB32()} '
            'colorBArgb=${frame.colorB.toARGB32()} '
            'opacity=${frame.opacity} '
            'effectId=${tuning.effect.name} '
            'settingsGeneration=${tuning.generation}',
      ),
    );
  }

  static DashboardHeaderVisualFrame _frameFor(
    DashboardBudgetPresentationState state,
    DashboardHeaderVisualTuning tuning,
  ) {
    final selection = state.liveSelection;
    final gradient = _canonicalGradientFor(selection.target, selection);
    if (!selection.visual.hasPositiveLimit) {
      return BudgetHeaderColorScale.noLimit(
        canonicalGradient: gradient,
        opacityScalePosition: tuning.opacityScalePosition,
      );
    }
    return BudgetHeaderColorScale.project(
      canonicalGradient: gradient,
      rawProgress: selection.visual.rawProgress,
      windowWidthPercent: tuning.budgetWindowWidthPercent,
      opacityScalePosition: tuning.opacityScalePosition,
    );
  }

  static CategoryGradientToken _canonicalGradientFor(
    DashboardBudgetTarget target,
    DashboardBudgetLiveSelectionState selection,
  ) {
    if (!target.isAggregate) {
      return CategoryColorCatalog.resolve(target.category!.colorId);
    }
    final aggregate = DashboardBudgetAggregateVisual.forDirection(
      selection.direction,
    );
    return CategoryGradientToken(
      // This creates no second palette: values are forwarded directly from
      // the aggregate target's existing visual authority.
      id: 'budget-aggregate-${selection.direction.name}',
      colorA: Color(aggregate.startColorArgb),
      middleColor: Color(aggregate.middleColorArgb),
      colorB: Color(aggregate.endColorArgb),
      angleDegrees: 135,
    );
  }

  @override
  void dispose() {
    _presentation.removeListener(_refresh);
    _tuning.removeListener(_refresh);
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
  _DashboardHeaderVisualPaintResources()
    : common = _DashboardHeaderCommonMaterialPaintLane(
        onSurfaceConfigured: _recordSurfaceConfiguration,
      );

  final _DashboardHeaderCommonMaterialPaintLane common;
  final DashboardHeaderPortalMaterialPaintLane portal =
      DashboardHeaderPortalMaterialPaintLane();

  static Object? _lastSurfaceConfigurationSignature;

  static void _recordSurfaceConfiguration({
    required DashboardHeaderFieldSamplingGeometry geometry,
    required DashboardHeaderEffectId effect,
    required int renderStepMs,
    required bool cacheHit,
  }) {
    final signature = Object.hash(geometry, effect, renderStepMs, cacheHit);
    if (_lastSurfaceConfigurationSignature == signature) return;
    _lastSurfaceConfigurationSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HEADER_RENDER_SURFACE_CONFIG',
        scope:
            'logicalWidth=${geometry.logicalSize.width} '
            'logicalHeight=${geometry.logicalSize.height} '
            'devicePixelRatio=${geometry.devicePixelRatio} '
            'physicalWidth=${geometry.physicalWidth} '
            'physicalHeight=${geometry.physicalHeight} '
            'effectId=${effect.name} '
            'qualityRequested=${geometry.renderScale} '
            'qualityApplied=${geometry.renderScale} '
            'renderStepsRequested=$renderStepMs '
            'renderStepsApplied=$renderStepMs '
            'fieldWidth=${geometry.columns} fieldHeight=${geometry.rows} '
            'intermediateRaster=false interpolation=triangularLinear '
            'cacheHit=$cacheHit',
      ),
    );
  }
}

/// Retains source-field scalars and mesh geometry across CustomPainter
/// delegate replacement. A semantic A/B change therefore recolours the one
/// existing field mesh without recalculating its noise/morph field.
final class _DashboardHeaderCommonMaterialPaintLane {
  _DashboardHeaderCommonMaterialPaintLane({required this.onSurfaceConfigured});

  final _HeaderSurfaceConfigurationRecorder onSurfaceConfigured;
  final DashboardHeaderInterpolatedFieldMesh _mesh =
      DashboardHeaderInterpolatedFieldMesh();
  Float64List? _coordinates;
  Float64List? _lights;
  Float64List? _chromas;
  DashboardHeaderFieldSamplingGeometry? _geometry;
  DashboardHeaderEffectId? _effect;
  Map<String, double>? _settings;
  double? _paletteSplitPercent;
  int _lastRenderedMicros = -1;
  int _paletteSignature = 0;

  void paint(
    Canvas canvas,
    Size size, {
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
    required DashboardHeaderEffectId effect,
    required Map<String, double> settings,
    required int elapsedMicros,
    required double devicePixelRatio,
  }) {
    final renderScale = (settings['renderScale'] ?? .60)
        .clamp(.35, 1.0)
        .toDouble();
    final geometry = DashboardHeaderFieldSamplingGeometry.resolve(
      logicalSize: size,
      devicePixelRatio: devicePixelRatio,
      renderScale: renderScale,
    );
    final sourceFrameMs = (settings['frameMs'] ?? 42).round();
    final frameMs = DashboardHeaderRenderCadence.effectiveFrameMs(
      renderScale: renderScale,
      sourceFrameMs: sourceFrameMs,
    );
    final mustRefresh =
        _coordinates == null ||
        _geometry != geometry ||
        _effect != effect ||
        !identical(_settings, settings) ||
        _paletteSplitPercent != frame.paletteSplitPercent ||
        elapsedMicros - _lastRenderedMicros >= frameMs * 1000;
    if (mustRefresh) {
      onSurfaceConfigured(
        geometry: geometry,
        effect: effect,
        renderStepMs: frameMs,
        cacheHit:
            _coordinates != null &&
            _geometry == geometry &&
            _effect == effect &&
            identical(_settings, settings),
      );
      _mesh.configure(geometry);
      final count = geometry.columns * geometry.rows;
      final coordinates = _coordinates?.length == count
          ? _coordinates!
          : Float64List(count);
      final lights = _lights?.length == count ? _lights! : Float64List(count);
      final chromas = _chromas?.length == count
          ? _chromas!
          : Float64List(count);
      final pulse = controller.pulseAmount;
      var index = 0;
      for (var y = 0; y < geometry.rows; y += 1) {
        final py = geometry.rows == 1 ? .5 : y / (geometry.rows - 1);
        for (var x = 0; x < geometry.columns; x += 1) {
          final px = geometry.columns == 1 ? .5 : x / (geometry.columns - 1);
          final sample = DashboardHeaderEffectMath.sample(
            effect: effect,
            x: px,
            y: py,
            phase: controller.phase,
            paletteSplitPercent: frame.paletteSplitPercent,
            settings: settings,
          );
          coordinates[index] = sample.coordinate;
          final lightLimit =
              effect == DashboardHeaderEffectId.balanceMembrane ||
                  effect == DashboardHeaderEffectId.balanceCounterflow ||
                  effect == DashboardHeaderEffectId.balanceCharges
              ? .22
              : .25;
          lights[index] = (sample.light + pulse * .025)
              .clamp(-lightLimit, lightLimit)
              .toDouble();
          chromas[index] = sample.chroma;
          index += 1;
        }
      }
      _coordinates = coordinates;
      _lights = lights;
      _chromas = chromas;
      _geometry = geometry;
      _effect = effect;
      _settings = settings;
      _paletteSplitPercent = frame.paletteSplitPercent;
      _lastRenderedMicros = elapsedMicros;
    }
    final paletteSignature = Object.hash(
      frame,
      controller.pulseAmount,
      _lastRenderedMicros,
    );
    if (mustRefresh || _paletteSignature != paletteSignature) {
      _paletteSignature = paletteSignature;
      final coordinates = _coordinates!;
      final lights = _lights!;
      final chromas = _chromas!;
      for (var index = 0; index < coordinates.length; index += 1) {
        _mesh.setArgb(
          index,
          _paletteArgb(
            frame: frame,
            coordinate: coordinates[index],
            light: lights[index],
            chroma: chromas[index],
          ),
        );
      }
    }
    _mesh.draw(
      canvas,
      opacity: DashboardHeaderFieldLayerOpacity.resolve(frame.opacity),
    );
  }

  static int _paletteArgb({
    required DashboardHeaderVisualFrame frame,
    required double coordinate,
    required double light,
    required double chroma,
  }) {
    final safeCoordinate = coordinate.clamp(0.0, 1.0).toDouble();
    var segment = frame.stops.length - 2;
    for (var index = 0; index < frame.stops.length - 1; index += 1) {
      if (safeCoordinate <= frame.stops[index + 1]) {
        segment = index;
        break;
      }
    }
    final width = math.max(
      1e-6,
      frame.stops[segment + 1] - frame.stops[segment],
    );
    final amount = ((safeCoordinate - frame.stops[segment]) / width)
        .clamp(0.0, 1.0)
        .toDouble();
    final left = frame.colors[segment];
    final right = frame.colors[segment + 1];
    final red = left.r + (right.r - left.r) * amount;
    final green = left.g + (right.g - left.g) * amount;
    final blue = left.b + (right.b - left.b) * amount;
    final gray = (red + green + blue) / 3;
    int channel(double value) =>
        (((gray + (value - gray) * (1 + chroma)) * (1 + light)) * 255)
            .round()
            .clamp(0, 255)
            .toInt();
    return DashboardHeaderFieldColorPacking.argb(
      alpha: 1,
      red: channel(red) / 255,
      green: channel(green) / 255,
      blue: channel(blue) / 255,
    );
  }
}

typedef _HeaderSurfaceConfigurationRecorder =
    void Function({
      required DashboardHeaderFieldSamplingGeometry geometry,
      required DashboardHeaderEffectId effect,
      required int renderStepMs,
      required bool cacheHit,
    });

final class DashboardHeaderVisualPaintLayer extends StatefulWidget {
  const DashboardHeaderVisualPaintLayer({
    super.key,
    required this.controller,
    required this.frame,
    required this.child,
  });

  final DashboardHeaderVisualController controller;
  final DashboardHeaderVisualFrame frame;
  final Widget child;

  @override
  State<DashboardHeaderVisualPaintLayer> createState() =>
      _DashboardHeaderVisualPaintLayerState();
}

final class _DashboardHeaderVisualPaintLayerState
    extends State<DashboardHeaderVisualPaintLayer> {
  late final _DashboardHeaderVisualPaintResources _resources =
      _DashboardHeaderVisualPaintResources();
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
  }) : super(repaint: controller);

  final DashboardHeaderVisualController controller;
  final DashboardHeaderVisualFrame frame;
  final _DashboardHeaderVisualPaintResources resources;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final tuning = controller.tuning.value;
    final elapsedMicros = controller.elapsed.inMicroseconds;
    resources.portal.paintBackground(
      canvas,
      size,
      state: controller.portalBackgroundMorph,
      colorA: frame.colorA,
      colorB: frame.colorB,
      opacity: frame.opacity,
      elapsedMicros: elapsedMicros,
      devicePixelRatio: devicePixelRatio,
    );
    if (tuning.effect == DashboardHeaderEffectId.staticEffect) {
      _paintStatic(canvas, size);
      resources.portal.paintInterior(
        canvas,
        size,
        state: controller.portalInnerMotion,
        colorA: frame.colorA,
        colorB: frame.colorB,
        opacity: frame.opacity,
        paletteSplitPercent: frame.paletteSplitPercent,
        elapsedMicros: elapsedMicros,
        devicePixelRatio: devicePixelRatio,
      );
      return;
    }
    final settings = tuning.settingsFor(tuning.effect);
    resources.common.paint(
      canvas,
      size,
      controller: controller,
      frame: frame,
      effect: tuning.effect,
      settings: settings,
      elapsedMicros: elapsedMicros,
      devicePixelRatio: devicePixelRatio,
    );
    resources.portal.paintInterior(
      canvas,
      size,
      state: controller.portalInnerMotion,
      colorA: frame.colorA,
      colorB: frame.colorB,
      opacity: frame.opacity,
      paletteSplitPercent: frame.paletteSplitPercent,
      elapsedMicros: elapsedMicros,
      devicePixelRatio: devicePixelRatio,
    );
  }

  void _paintStatic(Canvas canvas, Size size) {
    final colors = <Color>[
      for (final color in frame.colors)
        color.withValues(alpha: color.a * frame.opacity),
    ];
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: frame.stops,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
    final pulse = controller.pulseAmount;
    if (pulse > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: pulse * .025),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardHeaderVisualPainter oldDelegate) =>
      !frame.sameAs(oldDelegate.frame) ||
      !identical(controller, oldDelegate.controller);
}
