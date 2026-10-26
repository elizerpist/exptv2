import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_signal_detail_page.dart';
import 'pulse_triage_inspector_page.dart';

/// D-phase diagnostic surface. It renders the native Copy Map without
/// composing, translating, or inferring any financial text in Dart.
class PulseStoryInspectorPage extends StatefulWidget {
  const PulseStoryInspectorPage({
    super.key,
    required this.repository,
    required this.scope,
    required this.situationKey,
    required this.indicators,
    this.initial,
  });

  final PulseRepository repository;
  final DateTime scope;
  final String situationKey;
  final List<PulseIndicatorSnapshot> indicators;
  final PulseStoryInspection? initial;

  @override
  State<PulseStoryInspectorPage> createState() => _PulseStoryInspectorPageState();
}

class _PulseStoryInspectorPageState extends State<PulseStoryInspectorPage> {
  PulseStoryInspection? _inspection;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _inspection = widget.initial;
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.repository.storyInspection(
        year: widget.scope.year,
        month: widget.scope.month,
        situationKey: widget.situationKey,
      );
      if (mounted) setState(() => _inspection = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _openSource(PulseStoryFragment fragment) async {
    final indicatorId = fragment.sourceSignalKeys
        .map((item) => item.split('/').first)
        .firstWhere((item) => item.startsWith('PULSE-'), orElse: () => '');
    final indicator = widget.indicators.where((item) => item.id == indicatorId).firstOrNull;
    if (indicator != null) {
      await Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => PulseSignalDetailPage(
          indicator: indicator,
          repository: widget.repository,
          scope: widget.scope,
        ),
      ));
      return;
    }
    final situation = await widget.repository.triageInspection(
      year: widget.scope.year,
      month: widget.scope.month,
      situationKey: widget.situationKey,
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => PulseTriageInspectorPage(
        repository: widget.repository,
        scope: widget.scope,
        situation: situation.situation,
        indicators: widget.indicators,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;
    final result = inspection?.result;
    final draft = result?.draft;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Story Inspector'),
            Text('Üzenet és bizonyítékok', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: inspection == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const ValueKey('pulse-story-inspector'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
              children: [
                if (draft == null)
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Az üzenet előnézete jelenleg nem állítható össze.', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(result?.explanation ?? 'A Story forrásai nem érhetők el.', style: const TextStyle(color: FluviVisualTokens.textSecondary)),
                      ],
                    ),
                  )
                else ...[
                  _Panel(
                    color: const Color(0xFFF9F8FF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (draft.evaluationMode == 'historicalInspection')
                          const Padding(padding: EdgeInsets.only(bottom: 7), child: Text('Történeti szöveg-előnézet', style: TextStyle(fontSize: 12, color: FluviVisualTokens.textSecondary))),
                        Text(draft.headline, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                        if (draft.detail != null) ...[
                          const SizedBox(height: 8),
                          Text(draft.detail!, style: const TextStyle(fontSize: 14, height: 1.35)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Story adatai', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 8),
                      _Meta('Helyzet', draft.situationKey),
                      _Meta('Story típus', draft.claimType),
                      _Meta('Template', draft.fragments.first.templateId),
                      _Meta('Snapshot', '${draft.sourceCoreRevision}'),
                      const _Meta('Státusz', 'Előkészített'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mondatrészek és források', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...draft.fragments.map((fragment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FragmentCard(fragment: fragment, onOpen: () => _openSource(fragment)),
                  )),
                  if (draft.exclusions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _Exclusions(exclusions: draft.exclusions),
                  ],
                  const SizedBox(height: 16),
                  _Fingerprint(draft: draft),
                ],
              ],
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FluviVisualTokens.border),
      boxShadow: FluviVisualTokens.cardSurfaceShadows,
    ),
    child: child,
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12, color: FluviVisualTokens.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

class _FragmentCard extends StatelessWidget {
  const _FragmentCard({required this.fragment, required this.onOpen});
  final PulseStoryFragment fragment;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_roleTitle(fragment.role), style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(fragment.renderedText),
      const SizedBox(height: 8),
      Text('Template: ${fragment.templateId}\nBizonyosság: ${fragment.certainty.name}\nForrás: ${fragment.sourceSignalKeys.join(', ')}', style: const TextStyle(fontSize: 11, color: FluviVisualTokens.textSecondary)),
      Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: onOpen, child: const Text('Forrás megtekintése'))),
    ]),
  );
}

class _Exclusions extends StatelessWidget {
  const _Exclusions({required this.exclusions});
  final List<PulseStoryExclusion> exclusions;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Miért maradtak ki más adatok?', style: TextStyle(fontWeight: FontWeight.w800)),
    children: exclusions.map((item) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.factKey),
      subtitle: Text(item.explanation),
    )).toList(growable: false),
  );
}

class _Fingerprint extends StatelessWidget {
  const _Fingerprint({required this.draft});
  final PulseStoryDraft draft;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Azonosság és változáskövetés', style: TextStyle(fontWeight: FontWeight.w800)),
    children: [
      _Meta('Story Key', draft.storyKey),
      _Meta('Content', draft.contentFingerprint),
      _Meta('Material', draft.materialFingerprint),
      _Meta('Template', '${draft.templateVersion}'),
    ],
  );
}

String _roleTitle(PulseStoryFragmentRole role) => switch (role) {
  PulseStoryFragmentRole.headline => 'Headline',
  PulseStoryFragmentRole.evidence => 'Bizonyíték',
  PulseStoryFragmentRole.timeCause => 'Idő vagy ok',
  PulseStoryFragmentRole.qualification => 'Minősítés',
  PulseStoryFragmentRole.recovery => 'Javulás',
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
