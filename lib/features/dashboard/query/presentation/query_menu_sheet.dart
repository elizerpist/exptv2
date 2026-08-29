import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/catalog/category_visual_resolver.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
import '../application/query_composer_controller.dart';
import '../application/query_menu_data_controller.dart';
import '../application/saved_query_controller.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/query_amount_range.dart';
import '../domain/query_menu_data.dart';
import '../domain/query_temporal_presets.dart';
import '../domain/query_temporal_filter.dart';
import 'facet_picker_morph_host.dart';
import 'query_amount_range_control.dart';
import 'query_menu_formatters.dart';
import 'query_menu_tokens.dart';

/// Query-specific content supplied to the reusable [FluviSlideUpSheet].
///
/// The widget renders immutable controller state and forwards intents through
/// callbacks. It has no Room, SQL or MethodChannel dependency.
final class QueryMenuSheet extends StatefulWidget {
  const QueryMenuSheet({
    super.key,
    required this.composer,
    required this.dataController,
    required this.savedQueries,
    required this.onDraftChanged,
    required this.onClose,
    this.onSavedPanelRequested,
  });

  final QueryComposerController composer;
  final QueryMenuDataController dataController;
  final SavedQueryController savedQueries;
  final ValueChanged<CurrentLedgerQueryScope> onDraftChanged;
  final VoidCallback onClose;
  final VoidCallback? onSavedPanelRequested;

  @override
  State<QueryMenuSheet> createState() => _QueryMenuSheetState();
}

enum _FacetPickerKind { category, partner }

final class _QueryMenuSheetState extends State<QueryMenuSheet> {
  final GlobalKey _categoryAddKey = GlobalKey();
  final GlobalKey _partnerAddKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  _FacetPickerKind? _picker;
  bool _showSaved = false;
  bool _showTimeDetail = false;
  bool _showAdvanced = false;
  bool _showSaveEditor = false;
  int _shownYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    widget.composer.addListener(_listen);
    widget.dataController.addListener(_listen);
    widget.savedQueries.addListener(_listen);
    _searchController.text = _note(widget.composer.draft);
  }

  @override
  void didUpdateWidget(covariant QueryMenuSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.composer != widget.composer) {
      oldWidget.composer.removeListener(_listen);
      widget.composer.addListener(_listen);
    }
    if (oldWidget.dataController != widget.dataController) {
      oldWidget.dataController.removeListener(_listen);
      widget.dataController.addListener(_listen);
    }
    if (oldWidget.savedQueries != widget.savedQueries) {
      oldWidget.savedQueries.removeListener(_listen);
      widget.savedQueries.addListener(_listen);
    }
  }

  void _listen() {
    if (!mounted) {
      return;
    }
    final note = _note(widget.composer.draft);
    if (_searchController.text != note) {
      _searchController.value = TextEditingValue(text: note);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.composer.removeListener(_listen);
    widget.dataController.removeListener(_listen);
    widget.savedQueries.removeListener(_listen);
    _searchController.dispose();
    super.dispose();
  }

  CurrentLedgerQueryScope get _draft => widget.composer.draft;
  QueryMenuData? get _data => widget.dataController.data;

  int get _effectiveShownYear {
    final availableYears =
        _data?.availableMonths.map((month) => month.year).toSet().toList()
          ?..sort();
    if (availableYears == null || availableYears.isEmpty) return _shownYear;
    if (availableYears.contains(_shownYear)) return _shownYear;
    for (final group in _draft.temporalFilter.groups) {
      for (final selection in group.selections) {
        final selectedYear = int.parse(selection.value.substring(0, 4));
        if (availableYears.contains(selectedYear)) return selectedYear;
      }
    }
    return availableYears.last;
  }

  void _edit(CurrentLedgerQueryScope next, {bool refresh = true}) {
    widget.composer.updateDraft(scope: next);
    if (refresh) widget.onDraftChanged(next);
  }

  void _setCategories(Set<String> values) =>
      _edit(_draft.copyWith(categoryIds: values));

  void _setPartners(Set<String> values) =>
      _edit(_draft.copyWith(partnerIds: values));

  void _setTemporal(QueryTemporalFilter filter) =>
      _edit(_draft.copyWith(temporalFilter: filter));

  void _toggleCategory(String id) {
    final next = <String>{..._draft.categoryIds};
    if (!next.add(id)) next.remove(id);
    _setCategories(next);
  }

  void _togglePartner(String id) {
    final next = <String>{..._draft.partnerIds};
    if (!next.add(id)) next.remove(id);
    _setPartners(next);
  }

  void _setRefinement(String key, Object? value, {bool refresh = true}) {
    final refinements = <String, Object?>{..._draft.refinements};
    if (value == null || value == '') {
      refinements.remove(key);
    } else {
      refinements[key] = value;
    }
    _edit(_draft.copyWith(refinements: refinements), refresh: refresh);
  }

  void _toggleSaved() {
    setState(() => _showSaved = !_showSaved);
    if (_showSaved) widget.onSavedPanelRequested?.call();
  }

  @override
  Widget build(BuildContext context) {
    final summary = QueryMenuFormatters.summary(scope: _draft, data: _data);
    final result = _data?.result.entryCount ?? 0;
    final categoryFacets =
        _data?.categories ?? const <QueryMenuCategoryFacet>[];
    final partnerFacets = _data?.partners ?? const <QueryMenuPartnerFacet>[];
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Column(
          children: [
            _Header(
              summary: summary,
              resultCount: result,
              savedOpen: _showSaved,
              activeSaved: widget.savedQueries.activeSavedQueryId != null,
              onSaved: _toggleSaved,
              onClose: widget.onClose,
            ),
            Expanded(
              child: CustomScrollView(
                key: const ValueKey('query-menu-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        if (_showSaved) ...[
                          _SavedQueriesPanel(
                            savedQueries: widget.savedQueries,
                            composer: widget.composer,
                            onDraftChanged: widget.onDraftChanged,
                            showEditor: _showSaveEditor,
                            onToggleEditor: () => setState(
                              () => _showSaveEditor = !_showSaveEditor,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SearchPill(
                          controller: _searchController,
                          onChanged: (value) =>
                              _setRefinement('noteContains', value),
                        ),
                        const SizedBox(height: QueryMenuTokens.sectionGap),
                        _SectionHeader(
                          icon: Icons.calendar_today_outlined,
                          title: 'Mikor?',
                          action: TextButton(
                            onPressed: () => setState(
                              () => _showTimeDetail = !_showTimeDetail,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _showTimeDetail
                                  ? 'Bezárás'
                                  : 'Időszak beállítása ›',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TimePresets(
                          filter: _draft.temporalFilter,
                          onChanged: _setTemporal,
                        ),
                        if (_showTimeDetail) ...[
                          const SizedBox(height: 10),
                          _DetailedTimeSelector(
                            filter: _draft.temporalFilter,
                            availableMonths:
                                _data?.availableMonths ??
                                const <QueryMenuAvailableMonth>[],
                            shownYear: _effectiveShownYear,
                            onShownYearChanged: (year) =>
                                setState(() => _shownYear = year),
                            onChanged: _setTemporal,
                          ),
                        ],
                        const SizedBox(height: QueryMenuTokens.sectionGap),
                        const _SectionHeader(
                          icon: Icons.category_outlined,
                          title: 'Mire költöttél?',
                        ),
                        const SizedBox(height: 10),
                        _CategoryPreviewRail(
                          addKey: _categoryAddKey,
                          facets: categoryFacets,
                          selected: _draft.categoryIds,
                          onToggle: _toggleCategory,
                          onOpen: () => setState(
                            () => _picker = _FacetPickerKind.category,
                          ),
                        ),
                        const SizedBox(height: QueryMenuTokens.sectionGap),
                        const _SectionHeader(
                          icon: Icons.people_alt_outlined,
                          title: 'Kinél?',
                        ),
                        const SizedBox(height: 10),
                        _PartnerPreviewRail(
                          addKey: _partnerAddKey,
                          facets: partnerFacets,
                          selected: _draft.partnerIds,
                          onToggle: _togglePartner,
                          onOpen: () => setState(
                            () => _picker = _FacetPickerKind.partner,
                          ),
                        ),
                        const SizedBox(height: QueryMenuTokens.sectionGap),
                        _AdvancedDisclosure(
                          open: _showAdvanced,
                          data: _data,
                          draft: _draft,
                          onToggle: () =>
                              setState(() => _showAdvanced = !_showAdvanced),
                          onRangeChanged: (values, commit) {
                            final binding = QueryAmountRangeBinding.ready(
                              scope: _draft,
                              amountDomain: _data?.amountDomain,
                            );
                            if (binding == null) return;
                            final next = binding.apply(values);
                            _edit(next, refresh: commit);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        FacetPickerMorphHost<QueryMenuCategoryFacet>(
          isOpen: _picker == _FacetPickerKind.category,
          sourceKey: _categoryAddKey,
          title: 'Kategóriák',
          caption:
              'Az időszakban előforduló kategóriák. A kiválasztott kategóriákhoz tartozó partnerek később tovább szűkíthetők.',
          selectionLabel: _draft.categoryIds.isEmpty
              ? 'Több kategória is kiválasztható'
              : '${_draft.categoryIds.length} kiválasztva',
          items: categoryFacets,
          onClose: () => setState(() => _picker = null),
          rowBuilder: (context, facet, index) => _FacetRow(
            key: ValueKey('category-picker-${facet.id}'),
            name: facet.displayName,
            detail: '${facet.entryCount} tranzakció',
            colorId: facet.colorId,
            iconId: facet.iconId,
            selected: _draft.categoryIds.contains(facet.id),
            onTap: () => _toggleCategory(facet.id),
          ),
        ),
        FacetPickerMorphHost<QueryMenuPartnerFacet>(
          isOpen: _picker == _FacetPickerKind.partner,
          sourceKey: _partnerAddKey,
          title: 'Partnerek',
          caption:
              'Az időszakban előforduló partnerek. A kategóriával együtt tovább szűkíthetők.',
          selectionLabel: _draft.partnerIds.isEmpty
              ? 'Több partner is kiválasztható'
              : '${_draft.partnerIds.length} kiválasztva',
          items: partnerFacets,
          onClose: () => setState(() => _picker = null),
          rowBuilder: (context, facet, index) => _FacetRow(
            key: ValueKey('partner-picker-${facet.id}'),
            name: facet.displayName,
            detail: '${facet.entryCount} tranzakció',
            colorId: facet.categoryColorId,
            iconId: facet.categoryIconId,
            selected: _draft.partnerIds.contains(facet.id),
            onTap: () => _togglePartner(facet.id),
          ),
        ),
      ],
    );
  }
}

/// Sticky slot content passed to [FluviSlideUpSheet.stickyFooter].
final class QueryMenuStickyFooter extends StatelessWidget {
  const QueryMenuStickyFooter({
    super.key,
    required this.composer,
    required this.dataController,
    required this.onApply,
    required this.onClear,
    this.applying = false,
  });

  final QueryComposerController composer;
  final QueryMenuDataController dataController;
  final Future<void> Function(CurrentLedgerQueryScope draft) onApply;
  final VoidCallback onClear;
  final bool applying;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[composer, dataController]),
    builder: (context, _) {
      final count = dataController.confirmedEntryCount;
      final draftResultPending =
          dataController.lastScope != composer.draft ||
          dataController.isLoading;
      final label = count == null
          ? 'Tranzakciók mutatása'
          : '$count tranzakció mutatása';
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: QueryMenuTokens.sheet,
          border: Border(top: BorderSide(color: QueryMenuTokens.borderSoft)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: QueryMenuTokens.actionGradient,
                      borderRadius: BorderRadius.all(Radius.circular(19)),
                    ),
                    child: TextButton(
                      key: const ValueKey('query-menu-apply'),
                      onPressed: applying
                          ? null
                          : () => onApply(composer.draft),
                      child: Semantics(
                        label: draftResultPending
                            ? 'Eredmény frissül, $label'
                            : label,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('query-menu-clear'),
                  onPressed: onClear,
                  child: const Text('Összes törlése'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

final class _Header extends StatelessWidget {
  const _Header({
    required this.summary,
    required this.resultCount,
    required this.savedOpen,
    required this.activeSaved,
    required this.onSaved,
    required this.onClose,
  });

  final QueryMenuSummary summary;
  final int resultCount;
  final bool savedOpen;
  final bool activeSaved;
  final VoidCallback onSaved;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Keresés és szűrők',
                style: TextStyle(
                  color: QueryMenuTokens.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.45,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('query-menu-saved-toggle'),
              tooltip: 'Mentett szűrők',
              onPressed: onSaved,
              icon: Icon(
                savedOpen
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              color: QueryMenuTokens.selectionEnd,
              style: IconButton.styleFrom(
                backgroundColor: savedOpen
                    ? const Color(0xFFEFF1FF)
                    : Colors.transparent,
              ),
            ),
            if (activeSaved)
              const SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: QueryMenuTokens.selectionEnd,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            IconButton(
              key: const ValueKey('query-menu-close'),
              tooltip: 'Bezárás',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: QueryMenuTokens.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            summary.compactParts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: QueryMenuTokens.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$resultCount tranzakció',
            style: const TextStyle(
              color: QueryMenuTokens.selectionEnd,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 45,
    decoration: const BoxDecoration(
      color: QueryMenuTokens.controlSurface,
      borderRadius: BorderRadius.all(Radius.circular(13)),
    ),
    alignment: Alignment.center,
    child: TextField(
      key: const ValueKey('query-menu-search'),
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: QueryMenuTokens.textSecondary,
        ),
        hintText: 'Partner, kategória vagy megjegyzés',
        hintStyle: TextStyle(color: Color(0xFF8994A8), fontSize: 12),
        contentPadding: EdgeInsets.symmetric(vertical: 13),
      ),
      style: const TextStyle(color: QueryMenuTokens.textPrimary, fontSize: 12),
    ),
  );
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: QueryMenuTokens.textAccent),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: QueryMenuTokens.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null) ...[const SizedBox(width: 8), action!],
    ],
  );
}

final class _TimePresets extends StatelessWidget {
  const _TimePresets({required this.filter, required this.onChanged});

  final QueryTemporalFilter filter;
  final ValueChanged<QueryTemporalFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final choices = <(String, QueryTemporalFilter)>[
      ('Összes idő', const QueryTemporalFilter.allTime()),
      ('Aktuális hónap', QueryTemporalPresets.currentMonth(now)),
      ('Utolsó 3 hónap', QueryTemporalPresets.lastThreeMonths(now)),
      ('Ez év idáig', QueryTemporalPresets.yearToDate(now)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final choice in choices) ...[
            _TimeChip(
              text: choice.$1,
              selected: choice.$2 == filter,
              onPressed: () => onChanged(choice.$2),
            ),
            const SizedBox(width: 8),
          ],
          _TimeChip(
            text: 'Egyedi',
            selected:
                filter.isRestrictive &&
                !choices.any((choice) => choice.$2 == filter),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

final class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: selected ? QueryMenuTokens.selectionGradient : null,
      color: selected ? null : QueryMenuTokens.controlSurface,
      borderRadius: const BorderRadius.all(
        Radius.circular(QueryMenuTokens.chipRadius),
      ),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        foregroundColor: selected ? Colors.white : const Color(0xFF5E6D83),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

final class _DetailedTimeSelector extends StatelessWidget {
  const _DetailedTimeSelector({
    required this.filter,
    required this.availableMonths,
    required this.shownYear,
    required this.onShownYearChanged,
    required this.onChanged,
  });

  final QueryTemporalFilter filter;
  final List<QueryMenuAvailableMonth> availableMonths;
  final int shownYear;
  final ValueChanged<int> onShownYearChanged;
  final ValueChanged<QueryTemporalFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final years = <int>{
      shownYear,
      ...availableMonths.map((month) => month.year),
    };
    for (final group in filter.groups) {
      for (final selection in group.selections) {
        years.add(int.parse(selection.value.substring(0, 4)));
      }
    }
    final ordered = years.toList()..sort();
    final availableInShownYear = availableMonths
        .where((month) => month.year == shownYear)
        .map((month) => month.month)
        .toSet();
    final hasWholeYear = _yearSelected(filter, shownYear);
    final selectedMonths = hasWholeYear
        ? availableInShownYear
        : _monthSelections(filter, shownYear);
    final allYear =
        hasWholeYear ||
        (availableInShownYear.isNotEmpty &&
            availableInShownYear.every(selectedMonths.contains));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: QueryMenuTokens.sectionSurface,
        borderRadius: BorderRadius.all(
          Radius.circular(QueryMenuTokens.sectionRadius),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: QueryMenuTokens.borderSoft),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final year in ordered) ...[
                  _YearControl(
                    year: year,
                    selected: year == shownYear,
                    onPressed: () => onShownYearChanged(year),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$shownYear',
                style: const TextStyle(
                  color: QueryMenuTokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _TimeChip(
                text: allYear
                    ? 'Egész év'
                    : 'Egész év ${selectedMonths.length}/${availableInShownYear.length}',
                selected: allYear,
                onPressed: () => onChanged(_toggleWholeYear(filter, shownYear)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final month in availableInShownYear.toList()..sort()) ...[
                  _MonthControl(
                    text: _monthShortNames[month - 1],
                    selected: selectedMonths.contains(month),
                    onPressed: () =>
                        onChanged(_toggleMonth(filter, shownYear, month)),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Set<int> _monthSelections(QueryTemporalFilter filter, int year) =>
      filter.groups
          .where((group) => group.key == 'time')
          .expand((group) => group.selections)
          .where(
            (selection) =>
                selection.kind == QueryPeriodKind.month &&
                selection.value.startsWith('$year-'),
          )
          .map((selection) => int.parse(selection.value.substring(5, 7)))
          .toSet();

  static bool _yearSelected(QueryTemporalFilter filter, int year) => filter
      .groups
      .where((group) => group.key == 'time')
      .expand((group) => group.selections)
      .any(
        (selection) =>
            selection.kind == QueryPeriodKind.year &&
            selection.value == year.toString().padLeft(4, '0'),
      );

  static QueryTemporalFilter _toggleWholeYear(
    QueryTemporalFilter filter,
    int year,
  ) {
    final next = _selections(filter);
    final wholeYear = QueryPeriodSelection.year(year);
    if (next.contains(wholeYear)) {
      next.remove(QueryPeriodSelection.year(year));
    } else {
      next.removeWhere(
        (selection) =>
            selection.value.startsWith('$year-') ||
            selection == QueryPeriodSelection.year(year),
      );
      next.add(wholeYear);
    }
    return next.isEmpty
        ? const QueryTemporalFilter.allTime()
        : QueryTemporalFilter.periods(next);
  }

  static QueryTemporalFilter _toggleMonth(
    QueryTemporalFilter filter,
    int year,
    int month,
  ) {
    final next = _selections(filter);
    final selection = QueryPeriodSelection.month(year, month);
    if (!next.add(selection)) next.remove(selection);
    next.remove(QueryPeriodSelection.year(year));
    return next.isEmpty
        ? const QueryTemporalFilter.allTime()
        : QueryTemporalFilter.periods(next);
  }

  static Set<QueryPeriodSelection> _selections(QueryTemporalFilter filter) =>
      filter.groups
          .where((group) => group.key == 'time')
          .expand((group) => group.selections)
          .toSet();

  static const List<String> _monthShortNames = <String>[
    'Jan',
    'Feb',
    'Már',
    'Ápr',
    'Máj',
    'Jún',
    'Júl',
    'Aug',
    'Szept',
    'Okt',
    'Nov',
    'Dec',
  ];
}

final class _YearControl extends StatelessWidget {
  const _YearControl({
    required this.year,
    required this.selected,
    required this.onPressed,
  });

  final int year;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: selected ? QueryMenuTokens.selectionGradient : null,
      color: selected ? null : QueryMenuTokens.controlSurface,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: selected
            ? Colors.white
            : QueryMenuTokens.textSecondary,
      ),
      child: Text(
        '$year',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

final class _MonthControl extends StatelessWidget {
  const _MonthControl({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: selected ? QueryMenuTokens.selectionGradient : null,
      color: selected ? null : Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      border: selected
          ? null
          : const Border.fromBorderSide(
              BorderSide(color: QueryMenuTokens.borderSoft),
            ),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        foregroundColor: selected
            ? Colors.white
            : QueryMenuTokens.textSecondary,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

final class _CategoryPreviewRail extends StatelessWidget {
  const _CategoryPreviewRail({
    required this.addKey,
    required this.facets,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final GlobalKey addKey;
  final List<QueryMenuCategoryFacet> facets;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final chosen = facets
        .where((facet) => selected.contains(facet.id))
        .toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final facet in chosen) ...[
            _CategoryTile(
              facet: facet,
              selected: true,
              onTap: () => onToggle(facet.id),
            ),
            const SizedBox(width: 8),
          ],
          _CategoryAddTile(key: addKey, onTap: onOpen),
        ],
      ),
    );
  }
}

final class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.facet,
    required this.selected,
    required this.onTap,
  });

  final QueryMenuCategoryFacet facet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    height: 76,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: QueryMenuTokens.textPrimary,
      ),
      child: Column(
        children: [
          _CategoryVisualObject(
            colorId: facet.colorId,
            iconId: facet.iconId,
            selected: selected,
          ),
          const SizedBox(height: 5),
          Text(
            facet.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

final class _CategoryAddTile extends StatelessWidget {
  const _CategoryAddTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    height: 76,
    child: TextButton(
      key: const ValueKey('query-menu-add-category'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: QueryMenuTokens.textAccent,
      ),
      child: const Column(
        children: [
          _AddObject(),
          SizedBox(height: 5),
          Text(
            'Kategória hozzáadása',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

final class _AddObject extends StatelessWidget {
  const _AddObject();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 44,
    height: 44,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: QueryMenuTokens.controlSurface,
        borderRadius: BorderRadius.all(Radius.circular(17)),
      ),
      child: Icon(Icons.add_rounded, color: QueryMenuTokens.textAccent),
    ),
  );
}

final class _PartnerPreviewRail extends StatelessWidget {
  const _PartnerPreviewRail({
    required this.addKey,
    required this.facets,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final GlobalKey addKey;
  final List<QueryMenuPartnerFacet> facets;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final chosen = facets
        .where((facet) => selected.contains(facet.id))
        .toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final facet in chosen) ...[
            _PartnerChip(facet: facet, onTap: () => onToggle(facet.id)),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            key: addKey,
            onPressed: onOpen,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Partner hozzáadása'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: QueryMenuTokens.textAccent,
              backgroundColor: QueryMenuTokens.controlSurface,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.facet, required this.onTap});

  final QueryMenuPartnerFacet facet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisualResolver.resolve(
      colorId: facet.categoryColorId,
      iconId: facet.categoryIconId,
    );
    final tint = visual.gradient.middleColor;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: tint,
        backgroundColor: tint.withValues(alpha: .12),
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: const SizedBox(width: 5, height: 5),
          ),
          const SizedBox(width: 6),
          Text(
            facet.displayName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, size: 14),
        ],
      ),
    );
  }
}

final class _AdvancedDisclosure extends StatelessWidget {
  const _AdvancedDisclosure({
    required this.open,
    required this.data,
    required this.draft,
    required this.onToggle,
    required this.onRangeChanged,
  });

  final bool open;
  final QueryMenuData? data;
  final CurrentLedgerQueryScope draft;
  final VoidCallback onToggle;
  final void Function(QueryAmountRangeValues values, bool commit)
  onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final binding = QueryAmountRangeBinding.ready(
      scope: draft,
      amountDomain: data?.amountDomain,
    );
    return Container(
      decoration: const BoxDecoration(
        color: QueryMenuTokens.sectionSurface,
        borderRadius: BorderRadius.all(
          Radius.circular(QueryMenuTokens.sectionRadius),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: QueryMenuTokens.borderSoft),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.all(
              Radius.circular(QueryMenuTokens.sectionRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: QueryMenuTokens.selectionEnd,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'További szűrők',
                          style: TextStyle(
                            color: QueryMenuTokens.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Összeg és egyéb feltételek',
                          style: TextStyle(
                            color: QueryMenuTokens.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: QueryMenuTokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (open && binding != null)
            QueryAmountRangeControl(
              values: binding.values,
              onRangeCommitted: (values) => onRangeChanged(values, true),
            ),
        ],
      ),
    );
  }
}

final class _SavedQueriesPanel extends StatefulWidget {
  const _SavedQueriesPanel({
    required this.savedQueries,
    required this.composer,
    required this.onDraftChanged,
    required this.showEditor,
    required this.onToggleEditor,
  });

  final SavedQueryController savedQueries;
  final QueryComposerController composer;
  final ValueChanged<CurrentLedgerQueryScope> onDraftChanged;
  final bool showEditor;
  final VoidCallback onToggleEditor;

  @override
  State<_SavedQueriesPanel> createState() => _SavedQueriesPanelState();
}

final class _SavedQueriesPanelState extends State<_SavedQueriesPanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _renameName = TextEditingController();
  String? _renamingId;

  @override
  void dispose() {
    _name.dispose();
    _renameName.dispose();
    super.dispose();
  }

  Future<void> _saveNew() async {
    final name = _name.text.trim().isEmpty
        ? 'Mentett szűrő'
        : _name.text.trim();
    await widget.savedQueries.saveAsNew(
      name: name,
      scope: widget.composer.draft,
    );
    if (mounted) widget.onToggleEditor();
  }

  void _beginRename(SavedLedgerQuery entry) {
    setState(() {
      _renamingId = entry.id;
      _renameName.text = entry.name;
    });
  }

  Future<void> _commitRename(String id) async {
    final name = _renameName.text.trim();
    if (name.isEmpty) return;
    await widget.savedQueries.rename(id: id, name: name);
    if (mounted) setState(() => _renamingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.savedQueries.savedQueries;
    final activeId = widget.savedQueries.activeSavedQueryId;
    final dirty = widget.savedQueries.isDirty(widget.composer.draft);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: QueryMenuTokens.sectionSurface,
        borderRadius: BorderRadius.all(
          Radius.circular(QueryMenuTokens.sectionRadius),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: QueryMenuTokens.borderSoft),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GYORS VISSZATÉRÉS',
                      style: TextStyle(
                        color: QueryMenuTokens.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mentett szűrők',
                      style: TextStyle(
                        color: QueryMenuTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: widget.onToggleEditor,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Új mentés'),
              ),
            ],
          ),
          if (widget.showEditor) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Mentett szűrő neve',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _saveNew,
                child: const Text('Mentés'),
              ),
            ),
          ],
          if (activeId != null && dirty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Módosítva',
                    style: TextStyle(
                      color: QueryMenuTokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final current = saved
                          .where((entry) => entry.id == activeId)
                          .firstOrNull;
                      if (current != null) {
                        await widget.savedQueries.updateActive(
                          name: current.name,
                          scope: widget.composer.draft,
                        );
                      }
                    },
                    child: const Text('Frissítés'),
                  ),
                  TextButton(
                    onPressed: widget.onToggleEditor,
                    child: const Text('Mentés újként'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (saved.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Még nincs mentett szűrőd. Ments el egy gyakori lekérdezést.',
                style: TextStyle(
                  color: QueryMenuTokens.textSecondary,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            )
          else
            for (final entry in saved)
              if (_renamingId == entry.id)
                _SavedQueryRenameRow(
                  controller: _renameName,
                  onCancel: () => setState(() => _renamingId = null),
                  onSave: () => _commitRename(entry.id),
                )
              else
                _SavedQueryRow(
                  entry: entry,
                  active: entry.id == activeId,
                  onLoad: () async {
                    final loaded = await widget.savedQueries.loadIntoDraft(
                      id: entry.id,
                      composer: widget.composer,
                    );
                    widget.onDraftChanged(loaded.scope);
                  },
                  onRename: () => _beginRename(entry),
                  onDelete: () => widget.savedQueries.delete(entry.id),
                ),
        ],
      ),
    );
  }
}

final class _SavedQueryRow extends StatelessWidget {
  const _SavedQueryRow({
    required this.entry,
    required this.active,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final SavedLedgerQuery entry;
  final bool active;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(17)),
      border: active
          ? const Border.fromBorderSide(BorderSide(color: Color(0x297659F1)))
          : null,
    ),
    child: Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onLoad,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: QueryMenuTokens.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  QueryMenuFormatters.time(entry.scope.temporalFilter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: QueryMenuTokens.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem(value: 'rename', child: Text('Átnevezés')),
            PopupMenuItem(value: 'delete', child: Text('Törlés')),
          ],
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: QueryMenuTokens.textSecondary,
            size: 18,
          ),
        ),
      ],
    ),
  );
}

final class _SavedQueryRenameRow extends StatelessWidget {
  const _SavedQueryRenameRow({
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(17)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Mentett szűrő neve',
              border: InputBorder.none,
            ),
            style: const TextStyle(
              color: QueryMenuTokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(onPressed: onCancel, child: const Text('Mégse')),
        TextButton(onPressed: onSave, child: const Text('Mentés')),
      ],
    ),
  );
}

final class _FacetRow extends StatelessWidget {
  const _FacetRow({
    super.key,
    required this.name,
    required this.detail,
    required this.colorId,
    required this.iconId,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String detail;
  final String colorId;
  final String iconId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Material(
      color: selected ? const Color(0x0A247EF3) : Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: QueryMenuTokens.borderSoft)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            _CategoryVisualObject(
              colorId: colorId,
              iconId: iconId,
              selected: selected,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: QueryMenuTokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: QueryMenuTokens.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            _SelectionCheck(selected: selected),
          ],
        ),
      ),
    ),
  );
}

final class _SelectionCheck extends StatelessWidget {
  const _SelectionCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      gradient: selected ? QueryMenuTokens.selectionGradient : null,
      border: selected
          ? null
          : Border.all(color: const Color(0xFFCAD5E4), width: 1.5),
      borderRadius: const BorderRadius.all(Radius.circular(9)),
    ),
    alignment: Alignment.center,
    child: selected
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
        : null,
  );
}

final class _CategoryVisualObject extends StatelessWidget {
  const _CategoryVisualObject({
    required this.colorId,
    required this.iconId,
    required this.selected,
  });

  final String colorId;
  final String iconId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisualResolver.resolve(
      colorId: colorId,
      iconId: iconId,
    );
    final tint = visual.gradient.middleColor;
    final atlas = PreparedVectorAssetAtlas.instance;
    final picture = atlas.isReady
        ? atlas.categoryIcon(CategoryIconCatalog.handleOf(visual.icon.id))
        : null;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: selected ? visual.gradient.gradient : null,
        color: selected ? null : tint.withValues(alpha: .13),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: selected
            ? null
            : Border.all(color: tint.withValues(alpha: .24)),
      ),
      alignment: Alignment.center,
      child: picture == null
          ? Icon(
              Icons.category_outlined,
              color: selected ? Colors.white : tint,
              size: 20,
            )
          : CategoryIconView(
              picture: picture,
              size: 20,
              color: selected ? Colors.white : tint,
            ),
    );
  }
}

String _note(CurrentLedgerQueryScope scope) =>
    scope.refinements['noteContains'] as String? ?? '';

extension on Iterable<SavedLedgerQuery> {
  SavedLedgerQuery? get firstOrNull => isEmpty ? null : first;
}
