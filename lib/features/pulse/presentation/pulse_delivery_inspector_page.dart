import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

/// Read-only E-phase diagnostics. Loading this page only asks for a decision;
/// it never reserves a header lease or changes a receipt/control.
class PulseDeliveryInspectorPage extends StatefulWidget {
  const PulseDeliveryInspectorPage({
    super.key,
    required this.repository,
    required this.scope,
  });

  final PulseRepository repository;
  final DateTime scope;

  @override
  State<PulseDeliveryInspectorPage> createState() =>
      _PulseDeliveryInspectorPageState();
}

class _PulseDeliveryInspectorPageState
    extends State<PulseDeliveryInspectorPage> {
  PulseDeliveryInspection? _inspection;
  Object? _error;

  PulseDeliverySurfaceContext get _inspectionSurface =>
      const PulseDeliverySurfaceContext(
        appActive: true,
        ledgerVisible: false,
        headerVisible: false,
        unobstructed: false,
        interactionIdle: true,
        headerLayoutSupported: true,
        hostSessionId: 'delivery-inspector',
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.repository.deliveryInspection(
        year: widget.scope.year,
        month: widget.scope.month,
        surface: _inspectionSurface,
      );
      if (mounted) setState(() => _inspection = value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Inspector'),
            Text('Header megjelenítés', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
      ),
      body: inspection == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Újrapróbálás'),
                    ),
                  )
          : ListView(
              key: const ValueKey('pulse-delivery-inspector'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Card(
                  title: 'Összefoglaló',
                  rows: [
                    (
                      'Pénzügyi prioritás',
                      inspection.decision.prioritySelectedSituationKey ??
                          'Nincs',
                    ),
                    (
                      'Header jelölt',
                      inspection.decision.deliverySelectedSituationKey ??
                          'Nincs',
                    ),
                    (
                      'Kiválasztás oka',
                      inspection.decision.deliverySelectionReason,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Card(
                  title: 'Aktuális megjelenítési kísérlet',
                  rows: inspection.activeAttempt == null
                      ? const [('Nincs aktív foglalás', 'A header szabad.')]
                      : [
                          ('Állapot', inspection.activeAttempt!.state),
                          ('Helyzet', inspection.activeAttempt!.situationKey),
                          (
                            'Foglalás érvényes eddig',
                            DateTime.fromMillisecondsSinceEpoch(
                              inspection.activeAttempt!.validUntilUtcMs,
                              isUtc: true,
                            ).toLocal().toString(),
                          ),
                          (
                            'Minősített láthatóság',
                            inspection
                                        .activeAttempt!
                                        .qualifiedExposureAtUtcMs ==
                                    null
                                ? 'Még nincs visszaigazolva'
                                : 'Visszaigazolva',
                          ),
                        ],
                ),
                const SizedBox(height: 14),
                _Card(
                  title: 'Kapuvizsgálat',
                  rows: inspection.decision.candidates
                      .map(
                        (candidate) => (
                          '· ${candidate.situationKey}',
                          '${_eligibilityLabel(candidate.eligibility)} — ${candidate.explanation}',
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: 'Beállítások és kontrollok',
                  rows: [
                    (
                      'Automatikus Pulse',
                      inspection.preferences.automaticEnabled
                          ? 'Bekapcsolva'
                          : 'Kikapcsolva',
                    ),
                    (
                      'Normál szünet',
                      '${inspection.preferences.normalCooldownMillis ~/ 60000} perc',
                    ),
                    ...inspection.controls.map(
                      (control) => (
                        control.kind,
                        control.targetScope ??
                            control.expiresAtUtcMs?.toString() ??
                            'helyzetszintű',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Card(
                  title: 'Előzmények',
                  rows: inspection.events.isEmpty
                      ? const [
                          (
                            'Nincs esemény',
                            'A megnyitás nem kézbesítési művelet.',
                          ),
                        ]
                      : inspection.events
                            .map(
                              (event) => (
                                event.kind,
                                '${event.reasonCode} · ${DateTime.fromMillisecondsSinceEpoch(event.createdAtUtcMs, isUtc: true).toLocal()}',
                              ),
                            )
                            .toList(growable: false),
                ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(row.$2, textAlign: TextAlign.right)),
              ],
            ),
          ),
      ],
    ),
  );
}

String _eligibilityLabel(PulseDeliveryEligibility value) => switch (value) {
  PulseDeliveryEligibility.eligible => 'Megjelenítésre kész',
  PulseDeliveryEligibility.alreadyShown => 'Már megmutatva',
  PulseDeliveryEligibility.waitingForSurface => 'A Ledger fejlécére vár',
  PulseDeliveryEligibility.waitingForInteractionIdle => 'Interakcióra vár',
  PulseDeliveryEligibility.waitingForCooldown => 'Megjelenítési szünet',
  PulseDeliveryEligibility.snoozed => 'Halasztva',
  PulseDeliveryEligibility.muted => 'Némítva',
  PulseDeliveryEligibility.dismissed => 'Elrejtve',
  _ => 'Nem jogosult',
};
