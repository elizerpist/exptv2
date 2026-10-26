import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';
import 'pulse_triage_inspector_page.dart';
import 'pulse_story_inspector_page.dart';

/// Explains the native C-phase ranking. This screen deliberately does not
/// offer delivery, dismiss, mute, or notification controls.
class PulsePriorityInspectorPage extends StatefulWidget {
  const PulsePriorityInspectorPage({
    super.key,
    required this.repository,
    required this.scope,
    required this.initialPriority,
    required this.initialSituations,
    required this.indicators,
  });

  final PulseRepository repository;
  final DateTime scope;
  final PulsePriorityFrame initialPriority;
  final List<PulseSituationSnapshot> initialSituations;
  final List<PulseIndicatorSnapshot> indicators;

  @override
  State<PulsePriorityInspectorPage> createState() =>
      _PulsePriorityInspectorPageState();
}

class _PulsePriorityInspectorPageState
    extends State<PulsePriorityInspectorPage> {
  PulsePriorityInspection? _inspection;
  Object? _error;
  bool _loading = true;
  int _offset = 0;
  PulseStoryInspection? _story;
  bool _storyLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _loading = !append;
      _error = null;
    });
    try {
      final value = await widget.repository.priorityInspection(
        year: widget.scope.year,
        month: widget.scope.month,
        historyOffset: append ? _offset : 0,
      );
      if (!mounted) return;
      setState(() {
        _inspection = append && _inspection != null
            ? PulsePriorityInspection(
                priority: value.priority,
                situations: value.situations,
                events: [..._inspection!.events, ...value.events],
              )
            : value;
        _offset = _inspection!.events.length;
        _loading = false;
      });
      if (!append) await _loadSelectedStory();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadSelectedStory() async {
    try {
      final story = await widget.repository.selectedStoryPreview(
        year: widget.scope.year,
        month: widget.scope.month,
      );
      if (mounted) {
        setState(() {
          _story = story;
          _storyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _storyLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;
    final priority = inspection?.priority ?? widget.initialPriority;
    final situations = inspection?.situations ?? widget.initialSituations;
    final selected = priority.selected;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fontossági sorrend'),
            Text('Pulse Priority Engine', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
      ),
      body: _loading && inspection == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && inspection == null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: const Text('Újrapróbálás'),
              ),
            )
          : ListView(
              key: const ValueKey('pulse-priority-inspector'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
              children: [
                if (priority.evaluationMode == 'historicalInspection')
                  const _Notice('Történeti fontossági kiértékelés'),
                if (selected == null)
                  const _EmptyFocus()
                else ...[
                  _SelectedSummary(
                    candidate: selected,
                    situation: _findSituation(
                      situations,
                      selected.situationKey,
                    ),
                    reason: priority.selectionReason,
                  ),
                  const SizedBox(height: 18),
                  _ScoreLedger(candidate: selected),
                  const SizedBox(height: 18),
                  _StoryPreview(
                    inspection: _story,
                    loading: _storyLoading,
                    onOpen: () => _openStory(selected),
                  ),
                  const SizedBox(height: 18),
                  _CandidateRanking(
                    candidates: priority.rankedCandidates,
                    situations: situations,
                    onOpen: _openSituation,
                    onPreview: _openStory,
                  ),
                  const SizedBox(height: 18),
                  _Comparison(
                    first: selected,
                    second: priority.rankedCandidates.length > 1
                        ? priority.rankedCandidates[1]
                        : null,
                    reason: priority.selectionReason,
                  ),
                  if (priority.selectionReason?.tieBreakApplied ?? false) ...[
                    const SizedBox(height: 18),
                    _TieBreak(
                      reason: priority.selectionReason!,
                      first: selected,
                      second: priority.rankedCandidates[1],
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                _History(
                  events: inspection?.events ?? const [],
                  onMore: (inspection?.events.length ?? 0) >= 30
                      ? () => _load(append: true)
                      : null,
                ),
              ],
            ),
    );
  }

  Future<void> _openSituation(PulsePriorityCandidate candidate) async {
    final source = _inspection?.situations ?? widget.initialSituations;
    final situation = _findSituation(source, candidate.situationKey);
    if (situation == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseTriageInspectorPage(
          repository: widget.repository,
          scope: widget.scope,
          situation: situation,
          indicators: widget.indicators,
        ),
      ),
    );
  }

  Future<void> _openStory(PulsePriorityCandidate candidate) async {
    PulseStoryInspection? preview;
    try {
      preview = candidate.situationKey == (_inspection?.priority.selectedSituationKey ?? widget.initialPriority.selectedSituationKey)
          ? _story
          : await widget.repository.candidateStoryPreview(
              year: widget.scope.year,
              month: widget.scope.month,
              situationKey: candidate.situationKey,
            );
    } catch (_) {}
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PulseStoryInspectorPage(
          repository: widget.repository,
          scope: widget.scope,
          situationKey: candidate.situationKey,
          indicators: widget.indicators,
          initial: preview,
        ),
      ),
    );
  }
}

PulseSituationSnapshot? _findSituation(
  List<PulseSituationSnapshot> situations,
  String key,
) {
  for (final situation in situations) {
    if (situation.situationKey == key) return situation;
  }
  return null;
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

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(color: FluviVisualTokens.textSecondary),
    ),
  );
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus();
  @override
  Widget build(BuildContext context) => const _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nincs kiválasztott fókuszhelyzet.',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Jelenleg nincs olyan kész pénzügyi helyzet, amelyet a Priority Engine rangsorolhatna.',
          style: TextStyle(
            fontSize: 12,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.candidate,
    required this.situation,
    required this.reason,
  });
  final PulsePriorityCandidate candidate;
  final PulseSituationSnapshot? situation;
  final PulsePrioritySelectionReason? reason;
  @override
  Widget build(BuildContext context) => _Panel(
    color: const Color(0xFFF9F8FF),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKTUÁLIS FÓKUSZ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    situation?.title ?? candidate.situationKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    situation?.periodKey ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${candidate.finalScore}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: candidate.finalScore / 100,
            minHeight: 7,
            color: const Color(0xFF8B85B5),
            backgroundColor: const Color(0xFFE7E5F0),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          reason?.explanation ?? 'Natív Priority döntés.',
          style: const TextStyle(
            fontSize: 12,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _ScoreLedger extends StatelessWidget {
  const _ScoreLedger({required this.candidate});
  final PulsePriorityCandidate candidate;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pontszám részletezése',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _ScoreLine(
          label: 'Vezető jel alapértéke',
          value: candidate.basePriority,
          detail: candidate.leadingIndicatorId,
        ),
        ...candidate.modifiers.map(
          (item) => _ScoreLine(
            label: _modifierTitle(item.id),
            value: item.value,
            detail: item.explanation,
            muted: !item.applied,
          ),
        ),
        const Divider(height: 22),
        _ScoreLine(
          label: 'Végső fontosság',
          value: candidate.finalScore,
          detail: '${candidate.rawTotal} nyers pontból · 0–100-ra korlátozva',
          strong: true,
        ),
      ],
    ),
  );
}

class _StoryPreview extends StatelessWidget {
  const _StoryPreview({required this.inspection, required this.loading, required this.onOpen});
  final PulseStoryInspection? inspection;
  final bool loading;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final result = inspection?.result;
    final draft = result?.draft;
    return _Panel(
      color: const Color(0xFFF9F8FF),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Üzenet előnézete', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            Text(draft == null ? 'Nem összeállítható' : 'Előkészített', style: const TextStyle(fontSize: 11, color: FluviVisualTokens.textSecondary)),
          ]),
          const SizedBox(height: 9),
          if (loading && inspection == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (draft == null)
            Text(result?.explanation ?? 'Az üzenet előnézete jelenleg nem állítható össze.', style: const TextStyle(fontSize: 13, color: FluviVisualTokens.textSecondary))
          else ...[
            if (draft.evaluationMode == 'historicalInspection') const Text('Történeti szöveg-előnézet', style: TextStyle(fontSize: 11, color: FluviVisualTokens.textSecondary)),
            Text(draft.headline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (draft.detail != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(draft.detail!, style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 8),
            Text('${draft.fragments.length} felhasznált mondatrész', style: const TextStyle(fontSize: 11, color: FluviVisualTokens.textSecondary)),
          ],
          const SizedBox(height: 5),
          const Row(children: [Text('Teljes Copy Map', style: TextStyle(fontWeight: FontWeight.w700)), Spacer(), Icon(Icons.chevron_right, size: 18)]),
        ]),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.value,
    required this.detail,
    this.muted = false,
    this.strong = false,
  });
  final String label;
  final int value;
  final String detail;
  final bool muted;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  color: muted
                      ? FluviVisualTokens.textSecondary
                      : FluviVisualTokens.textPrimary,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value > 0 ? '+$value' : '$value',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: muted
                ? FluviVisualTokens.textSecondary
                : FluviVisualTokens.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _CandidateRanking extends StatelessWidget {
  const _CandidateRanking({
    required this.candidates,
    required this.situations,
    required this.onOpen,
    required this.onPreview,
  });
  final List<PulsePriorityCandidate> candidates;
  final List<PulseSituationSnapshot> situations;
  final ValueChanged<PulsePriorityCandidate> onOpen;
  final ValueChanged<PulsePriorityCandidate> onPreview;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Versenyző helyzetek',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...candidates.map((candidate) {
          final situation = _findSituation(situations, candidate.situationKey);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onOpen(candidate),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${candidate.rank}.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        situation?.title ?? candidate.situationKey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${candidate.finalScore}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Üzenet előnézete',
                      onPressed: () => onPreview(candidate),
                      icon: const Icon(Icons.article_outlined, size: 18),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.first,
    required this.second,
    required this.reason,
  });
  final PulsePriorityCandidate first;
  final PulsePriorityCandidate? second;
  final PulsePrioritySelectionReason? reason;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Miért előzte meg?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (second == null)
          const Text(
            'Nincs másik kész helyzet az összehasonlításhoz.',
            style: TextStyle(
              fontSize: 12,
              color: FluviVisualTokens.textSecondary,
            ),
          )
        else ...[
          _CompareRow('Alapérték', first.basePriority, second!.basePriority),
          _CompareRow(
            'Pénzügyi hatás',
            _modifierValue(first, 'material-impact'),
            _modifierValue(second!, 'material-impact'),
          ),
          _CompareRow(
            'Esedékesség',
            _modifierValue(first, 'due-soon'),
            _modifierValue(second!, 'due-soon'),
          ),
          _CompareRow(
            'Bizonyíték',
            _modifierValue(first, 'independent-evidence'),
            _modifierValue(second!, 'independent-evidence'),
          ),
          const Divider(),
          _CompareRow(
            'Végső pont',
            first.finalScore,
            second!.finalScore,
            strong: true,
          ),
          const SizedBox(height: 6),
          Text(
            reason?.explanation ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.first, this.second, {this.strong = false});
  final String label;
  final int first;
  final int second;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$first',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$second',
            textAlign: TextAlign.end,
            style: const TextStyle(color: FluviVisualTokens.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _TieBreak extends StatelessWidget {
  const _TieBreak({
    required this.reason,
    required this.first,
    required this.second,
  });
  final PulsePrioritySelectionReason reason;
  final PulsePriorityCandidate first;
  final PulsePriorityCandidate second;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Döntetlen feloldása',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          reason.tieBreakExplanation ?? reason.explanation,
          style: const TextStyle(
            fontSize: 12,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Esedékesség: ${_tieDate(first.tieBreakFacts.dueLocalEpochDay)} · ${_tieDate(second.tieBreakFacts.dueLocalEpochDay)}\n'
          'Súlyossági zóna: ${first.tieBreakFacts.severityRank} · ${second.tieBreakFacts.severityRank}\n'
          'Összehasonlítható hatás: ${_minor(first.tieBreakFacts.comparableImpactMinor)} · ${_minor(second.tieBreakFacts.comparableImpactMinor)}',
          style: const TextStyle(
            fontSize: 11,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _History extends StatelessWidget {
  const _History({required this.events, required this.onMore});
  final List<PulsePriorityEvent> events;
  final VoidCallback? onMore;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Korábbi fókuszváltások',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          const Text(
            'Még nincs perzisztált fókuszváltás.',
            style: TextStyle(
              fontSize: 12,
              color: FluviVisualTokens.textSecondary,
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                '${_date(event.createdAtUtcMs)} · ${event.kind}\n${event.nextSelectedSituationKey ?? 'Nincs kiválasztott helyzet'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (onMore != null)
          TextButton(onPressed: onMore, child: const Text('Korábbi események')),
      ],
    ),
  );
}

int _modifierValue(PulsePriorityCandidate candidate, String id) =>
    candidate.modifiers.where((item) => item.id == id).firstOrNull?.value ?? 0;

String _modifierTitle(String id) => switch (id) {
  'material-impact' => 'Jelentős pénzügyi hatás',
  'due-soon' => 'Közeli esedékesség',
  'independent-evidence' => 'Független alátámasztás',
  _ => id,
};

String _date(int ms) => DateTime.fromMillisecondsSinceEpoch(
  ms,
).toLocal().toString().substring(0, 16);

String _tieDate(int? epochDay) => epochDay == null
    ? 'nincs adat'
    : DateTime.fromMillisecondsSinceEpoch(
        epochDay * Duration.millisecondsPerDay,
      ).toLocal().toString().substring(0, 10);

String _minor(int? value) =>
    value == null ? 'nincs adat' : '${value ~/ 100} Ft';

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
