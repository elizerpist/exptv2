import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/categories/domain/category_repository.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_editor_sheet.dart';
import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_corner_profile.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_global_appearance.dart';
import '../../dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import '../../dashboard/presentation/dashboard_corner_roundness.dart';
import '../../dashboard/presentation/dashboard_shadow_style.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../application/manual_transaction_editor_preferences.dart';
import '../data/unavailable_manual_transaction_impact_repository.dart';
import '../domain/manual_transaction_impact_repository.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import 'category_dropdown.dart';
import 'manual_transaction_budget_impact.dart';
import 'manual_transaction_editor_field_rows.dart';
import 'partner_selector.dart';

enum ManualTransactionEditorMode { create, edit }

/// One draft serves both renderings. Toggling layout rebuilds only the surface
/// around retained controllers, focus nodes, picker state and scroll position.
final class ManualTransactionEditor extends StatefulWidget {
  const ManualTransactionEditor.create({
    super.key,
    required this.repository,
    required this.categories,
    required this.direction,
    this.categoryCollection,
    this.categoryRepository,
    this.impactRepository,
    this.preferencesStore,
    this.headerVisualTuning,
    this.onSaved,
  }) : mode = ManualTransactionEditorMode.create,
       entryId = null;

  const ManualTransactionEditor.edit({
    super.key,
    required this.repository,
    required this.categories,
    required String this.entryId,
    this.categoryCollection,
    this.categoryRepository,
    this.impactRepository,
    this.preferencesStore,
    this.headerVisualTuning,
    this.onSaved,
  }) : mode = ManualTransactionEditorMode.edit,
       direction = null;

  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final ValueListenable<List<FluviCategory>>? categoryCollection;
  final CategoryRepository? categoryRepository;
  final ManualTransactionImpactRepository? impactRepository;
  final ManualTransactionEditorPreferencesStore? preferencesStore;
  final ValueListenable<DashboardHeaderVisualTuning>? headerVisualTuning;
  final ManualTransactionEditorMode mode;
  final String? entryId;
  final LedgerDirection? direction;
  final Future<void> Function(ManualTransactionSaveResult)? onSaved;

  @override
  State<ManualTransactionEditor> createState() =>
      _ManualTransactionEditorState();
}

final class _ManualTransactionEditorState
    extends State<ManualTransactionEditor> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();
  final _scrollController = ScrollController();
  final _partnerDropdownKey = GlobalKey<PartnerDropdownState>();
  final _createdCategories = <FluviCategory>[];

  late DateTime _date;
  late TimeOfDay _time;
  late DateTime _initialCreateDate;
  late TimeOfDay _initialCreateTime;
  LedgerDirection? _direction;
  LedgerEntryDetail? _entry;
  PartnerDirectoryEntry? _partner;
  ManualPartnerSelection? _partnerSelection;
  ManualCategorySelection _categorySelection =
      const ManualCategorySelection.partnerDefault();
  ManualTransactionEditorPreferences? _preferences;
  ManualTransactionMonthImpact? _impact;
  bool _impactLoading = false;
  int _impactGeneration = 0;
  bool _loading = false;
  bool _saving = false;
  bool _revisionConflict = false;
  String? _error;

  bool get _editing => widget.mode == ManualTransactionEditorMode.edit;
  List<FluviCategory> get _categories {
    final authoritative = widget.categoryCollection?.value ?? widget.categories;
    if (_createdCategories.isEmpty) return authoritative;
    final known = authoritative.map((value) => value.id).toSet();
    return <FluviCategory>[
      ...authoritative,
      for (final value in _createdCategories)
        if (!known.contains(value.id)) value,
    ];
  }

  String? get _selectedCategoryId =>
      _categorySelection.mode == ManualCategoryAssignmentMode.entryOverride
      ? _categorySelection.categoryId
      : _partner?.defaultCategoryId;

  bool get _dirty {
    final entry = _entry;
    if (!_editing || entry == null) {
      return _amount.text.isNotEmpty ||
          _note.text.isNotEmpty ||
          _partnerSelection != null ||
          _categorySelection.mode ==
              ManualCategoryAssignmentMode.entryOverride ||
          _date != _initialCreateDate ||
          _time.hour != _initialCreateTime.hour ||
          _time.minute != _initialCreateTime.minute;
    }
    final selectedPartnerId = switch (_partnerSelection) {
      ExistingManualPartner(:final partnerId) => partnerId,
      NewManualPartner() || null => null,
    };
    return selectedPartnerId != entry.partnerId ||
        _amount.text != _formatHungarianMinor(entry.amountScaled100) ||
        _note.text != (entry.note ?? '') ||
        _date != _dateFromEpochDay(entry.bookedLocalEpochDay) ||
        _time.hour * 60 + _time.minute != entry.bookedLocalTimeMinutes ||
        _categorySelection.mode.name != entry.categoryAssignmentMode.name ||
        _categorySelection.categoryId !=
            (entry.categoryAssignmentMode ==
                    ManualCategoryAssignmentMode.entryOverride
                ? entry.categoryId
                : null);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay.fromDateTime(now);
    _initialCreateDate = _date;
    _initialCreateTime = _time;
    _direction = widget.direction;
    _amount.addListener(_onDraftTextChanged);
    _note.addListener(_onDraftTextChanged);
    _loadPreferences();
    if (_editing) {
      _load();
    } else {
      _reloadImpact();
    }
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_onDraftTextChanged)
      ..dispose();
    _note
      ..removeListener(_onDraftTextChanged)
      ..dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDraftTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPreferences() async {
    final value =
        await (widget.preferencesStore ??
                const DefaultManualTransactionEditorPreferencesStore())
            .read();
    if (mounted) setState(() => _preferences = value);
  }

  Future<void> _setPreferences(ManualTransactionEditorPreferences value) async {
    _partnerDropdownKey.currentState?.close();
    setState(() => _preferences = value);
    await (widget.preferencesStore ??
            const DefaultManualTransactionEditorPreferencesStore())
        .write(value);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _revisionConflict = false;
    });
    try {
      final entry = await widget.repository.getLedgerEntryById(widget.entryId!);
      final partner = await widget.repository.getPartnerById(entry.partnerId);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _direction = entry.direction;
        _partner = partner;
        _partnerSelection = ExistingManualPartner(
          entry.partnerId,
          directoryEntry: partner,
        );
        _categorySelection =
            entry.categoryAssignmentMode ==
                ManualCategoryAssignmentMode.entryOverride
            ? ManualCategorySelection.entryOverride(entry.categoryId)
            : const ManualCategorySelection.partnerDefault();
        _date = _dateFromEpochDay(entry.bookedLocalEpochDay);
        _time = TimeOfDay(
          hour: entry.bookedLocalTimeMinutes ~/ 60,
          minute: entry.bookedLocalTimeMinutes % 60,
        );
        _amount.text = _formatHungarianMinor(entry.amountScaled100);
        _note.text = entry.note ?? '';
      });
      _reloadImpact();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'A tranzakció nem tölthető be: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reloadImpact() async {
    final direction = _direction;
    if (direction == null) return;
    final generation = ++_impactGeneration;
    if (mounted) {
      setState(() => _impactLoading = true);
    }
    try {
      final impact =
          await (widget.impactRepository ??
                  const UnavailableManualTransactionImpactRepository())
              .loadMonthImpact(
                direction: direction,
                categoryId: _selectedCategoryId,
                year: _date.year,
                month: _date.month,
                excludedEntryId: _editing ? _entry?.entryId : null,
              );
      if (mounted && generation == _impactGeneration) {
        setState(() => _impact = impact);
      }
    } catch (_) {
      if (mounted && generation == _impactGeneration) {
        setState(() => _impact = null);
      }
    } finally {
      if (mounted && generation == _impactGeneration) {
        setState(() => _impactLoading = false);
      }
    }
  }

  Future<void> _acceptPartner(ManualPartnerSelection selected) async {
    if (selected case ExistingManualPartner(:final partnerId)) {
      final partner =
          selected.directoryEntry ??
          await widget.repository.getPartnerById(partnerId);
      if (!mounted) return;
      setState(() {
        _partnerSelection = selected;
        _partner = partner;
        _categorySelection = const ManualCategorySelection.partnerDefault();
      });
    } else if (selected case NewManualPartner(
      :final displayName,
      :final defaultCategoryId,
    )) {
      final category = _category(defaultCategoryId);
      setState(() {
        _partnerSelection = selected;
        _partner = PartnerDirectoryEntry(
          partnerId: '',
          displayName: displayName,
          originalName: displayName,
          defaultCategoryId: defaultCategoryId,
          defaultCategoryName: category?.name ?? 'Kategorizálatlan',
          categoryColorId: category?.colorId ?? 'fallback',
          categoryIconId: category?.iconId ?? 'fallback',
          isUncategorized: category?.isSystemUncategorized ?? true,
          searchNames: [displayName],
        );
        _categorySelection = const ManualCategorySelection.partnerDefault();
      });
    }
    _reloadImpact();
  }

  Future<void> _pickPartnerFullscreen() async {
    // Opening a selector is a navigation action, not an invitation to start
    // typing. This also dismisses a previously focused amount/note keyboard
    // before the full-screen route becomes visible.
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await Navigator.of(context).push<ManualPartnerSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PartnerSelector(
          repository: widget.repository,
          categories: _categories,
        ),
      ),
    );
    if (mounted && selected != null) await _acceptPartner(selected);
  }

  Future<void> _createCategory() async {
    final repository = widget.categoryRepository;
    if (repository == null) {
      setState(
        () => _error = 'A kategórialétrehozás ezen a felületen nem érhető el.',
      );
      return;
    }
    final category = await showCategoryEditorSheet(
      context,
      repository: repository,
    );
    if (!mounted || category == null) return;
    setState(() {
      _createdCategories
        ..removeWhere((value) => value.id == category.id)
        ..add(category);
      _categorySelection = ManualCategorySelection.entryOverride(category.id);
    });
    _reloadImpact();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
      _reloadImpact();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _addQuickAmount(int major) {
    final current = _parseHungarianMinor(_amount.text) ?? 0;
    final addition = major * 100;
    if (current > _maxStoredMinor - addition) return;
    final text = _formatHungarianMinor(current + addition);
    _amount.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<bool> _confirmClose() async {
    if (!_dirty || _saving) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Változtatások elvetése?'),
            content: const Text(
              'A még nem mentett tranzakcióadatok elvesznek.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Maradok'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elvetés'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cancel() async {
    if (_saving || !await _confirmClose() || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final partner = _partnerSelection;
    final direction = _direction;
    final scaled = _parseHungarianMinor(_amount.text);
    if (partner == null ||
        _partner == null ||
        direction == null ||
        scaled == null ||
        scaled <= 0) {
      setState(() => _error = 'Adj meg pozitív összeget és partnert.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _revisionConflict = false;
    });
    try {
      final day = _epochDay(_date);
      final minutes = _time.hour * 60 + _time.minute;
      final occurred = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ).millisecondsSinceEpoch;
      final saved = _editing
          ? await widget.repository.updateTransaction(
              entryId: _entry!.entryId,
              expectedRevision: _entry!.revision,
              partner: partner,
              categorySelection: _categorySelection,
              amountScaled100: scaled,
              bookedLocalEpochDay: day,
              bookedLocalTimeMinutes: minutes,
              occurredAtUtcMs: _entry!.originKind == 'manual'
                  ? occurred
                  : _entry!.occurredAtUtcMs,
              note: _note.text,
            )
          : await widget.repository.createManualTransaction(
              partner: partner,
              categorySelection: _categorySelection,
              direction: direction,
              amountScaled100: scaled,
              bookedLocalEpochDay: day,
              bookedLocalTimeMinutes: minutes,
              occurredAtUtcMs: occurred,
              note: _note.text,
            );
      final result = ManualTransactionSaveResult(
        entry: saved,
        partner: _partner!,
        effectiveCategory: _category(saved.categoryId),
        globalCoreRevision: saved.coreRevision,
      );
      if (widget.onSaved case final onSaved?) {
        await onSaved(result);
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _revisionConflict = error.code == 'revision_conflict';
          _error = _revisionConflict
              ? 'A tranzakció időközben megváltozott. Töltsd újra a mentés előtt.'
              : 'A mentés nem sikerült: ${error.message ?? error.code}';
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'A mentés nem sikerült: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  FluviCategory? _category(String? id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      ?widget.categoryCollection,
      ?widget.headerVisualTuning,
    ];
    if (listenables.isEmpty) return _buildEditor(context);
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) => _buildEditor(context),
    );
  }

  Widget _buildEditor(BuildContext context) {
    if (_loading || _preferences == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final islands =
        _preferences!.layout == ManualTransactionEditorLayout.islands;
    return RepaintBoundary(
      key: const ValueKey('manual-editor-visual-boundary'),
      child: PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || !await _confirmClose() || !context.mounted) return;
          Navigator.of(context).pop();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: islands
              ? FluviVisualTokens.pageBackground
              : Colors.white,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (islands)
                      _islandHeader(context)
                    else
                      _heroHeader(context),
                    _quickAmounts(islands: islands),
                    if (islands) ...[
                      _island(_partnerAndCategory(context)),
                      _island(_dateAndNote(context)),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: _partnerAndCategory(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _dateAndNote(context),
                      ),
                    ],
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      if (islands)
                        _island(_impactPreview(context))
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                          child: _impactPreview(context),
                        ),
                    if (_error != null) _errorBlock(context, islands: islands),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
              _ctaBar(context),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient get _heroGradient {
    final source = FluviDirectionColorPaletteCatalog.income(
      _directionColorProfile,
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        for (final color in source.colors)
          Color.lerp(color, Colors.white, .86)!,
      ],
      stops: source.stops,
    );
  }

  FluviDirectionColorProfile get _directionColorProfile =>
      widget.headerVisualTuning?.value.globalAppearance.directionColorProfile ??
      FluviDirectionColorProfile.original;

  Widget _heroHeader(BuildContext context) => DecoratedBox(
    key: const ValueKey('manual-editor-hero'),
    decoration: BoxDecoration(gradient: _heroGradient),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      child: _headerContent(context),
    ),
  );

  Widget _islandHeader(BuildContext context) => Padding(
    key: const ValueKey('manual-editor-islands'),
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 14,
      16,
      0,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: _heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: FluviVisualTokens.cardSurfaceShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: _headerContent(context),
      ),
    ),
  );

  Widget _headerContent(BuildContext context) {
    final direction = _direction ?? LedgerDirection.expense;
    final title = _editing
        ? direction == LedgerDirection.expense
              ? 'Kiadás szerkesztése'
              : 'Bevétel szerkesztése'
        : direction == LedgerDirection.expense
        ? 'Új kiadás'
        : 'Új bevétel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FluviVisualTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
            ),
            _headerToggle(
              key: const ValueKey('manual-partner-presentation-toggle'),
              tooltip:
                  _preferences!.partnerPickerPresentation ==
                      ManualPartnerPickerPresentation.fullScreen
                  ? 'Partnerlista: teljes oldal'
                  : 'Partnerlista: legördülő lista',
              icon:
                  _preferences!.partnerPickerPresentation ==
                      ManualPartnerPickerPresentation.fullScreen
                  ? Icons.open_in_full_rounded
                  : Icons.arrow_drop_down_circle_outlined,
              onTap: _saving
                  ? null
                  : () => _setPreferences(
                      _preferences!.copyWith(
                        partnerPickerPresentation:
                            _preferences!.partnerPickerPresentation ==
                                ManualPartnerPickerPresentation.fullScreen
                            ? ManualPartnerPickerPresentation.dropdown
                            : ManualPartnerPickerPresentation.fullScreen,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            _headerToggle(
              key: const ValueKey('manual-layout-toggle'),
              tooltip:
                  _preferences!.layout == ManualTransactionEditorLayout.hero
                  ? 'Szerkesztő elrendezés: Hero'
                  : 'Szerkesztő elrendezés: szigetes',
              icon: _preferences!.layout == ManualTransactionEditorLayout.hero
                  ? Icons.dashboard_outlined
                  : Icons.view_agenda_outlined,
              onTap: _saving
                  ? null
                  : () => _setPreferences(
                      _preferences!.copyWith(
                        layout:
                            _preferences!.layout ==
                                ManualTransactionEditorLayout.hero
                            ? ManualTransactionEditorLayout.islands
                            : ManualTransactionEditorLayout.hero,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Összeg',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: FluviVisualTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        _amountEditor(context),
      ],
    );
  }

  Widget _amountEditor(BuildContext context) {
    final amountStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: FluviVisualTokens.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w900,
      letterSpacing: -.8,
      height: 1.08,
    );
    final displayed = _amount.text.isEmpty ? '0' : _amount.text;
    final painter = TextPainter(
      text: TextSpan(text: displayed, style: amountStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: 244);
    final fieldWidth = (painter.width + 12).clamp(52, 244).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: fieldWidth,
          child: TextField(
            key: const ValueKey('manual-amount-field'),
            controller: _amount,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\s\u00A0]')),
            ],
            maxLines: 1,
            style: amountStyle,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: amountStyle?.copyWith(
                color: FluviVisualTokens.textPrimary.withValues(alpha: .36),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Ft',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _headerToggle({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onTap,
  }) => Semantics(
    button: true,
    label: tooltip,
    child: Tooltip(
      message: tooltip,
      child: IconButton(
        key: key,
        onPressed: onTap,
        icon: Icon(icon),
        color: FluviVisualTokens.textPrimary,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .58),
          side: const BorderSide(color: Color(0x33FFFFFF)),
          minimumSize: const Size(44, 44),
        ),
      ),
    ),
  );

  Widget _quickAmounts({required bool islands}) => Padding(
    padding: EdgeInsets.fromLTRB(islands ? 16 : 20, 14, islands ? 16 : 20, 4),
    child: Row(
      children: [
        for (final (index, amount) in <int>[1000, 5000, 10000].indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              key: ValueKey('manual-quick-$amount'),
              onPressed: _saving ? null : () => _addQuickAmount(amount),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xfff1eaff),
                foregroundColor: const Color(0xff6d28d9),
                disabledBackgroundColor: const Color(0xfff1eaff),
                disabledForegroundColor: const Color(0xff6d28d9),
                elevation: 0,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              child: Text('+${_formatHungarianMinor(amount * 100)} Ft'),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _island(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: FluviVisualTokens.cardSurfaceShadows,
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );

  Widget _partnerAndCategory(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_preferences!.partnerPickerPresentation ==
          ManualPartnerPickerPresentation.dropdown)
        PartnerDropdown(
          key: _partnerDropdownKey,
          repository: widget.repository,
          categories: _categories,
          selectedPartnerId: switch (_partnerSelection) {
            ExistingManualPartner(:final partnerId) => partnerId,
            _ => null,
          },
          selectedPartner: _partner,
          enabled: !_saving,
          onSelected: _acceptPartner,
        )
      else
        ManualEditorSelectionRow(
          key: const ValueKey('manual-partner-field'),
          label: 'Partner',
          value: _partner?.displayName ?? 'Partner kiválasztása',
          leading: _partner == null
              ? const ManualEditorIconSurface(
                  icon: Icons.storefront_outlined,
                  color: Color(0xff64748b),
                  background: Color(0xfff1f5f9),
                )
              : PartnerCategoryAvatar(
                  partner: _partner!,
                  size: 40,
                  iconSize: 20,
                  roundedSquare: true,
                ),
          enabled: !_saving,
          onTap: _pickPartnerFullscreen,
        ),
      manualEditorDivider,
      CategoryDropdown(
        categories: _categories,
        selectedCategoryId: _selectedCategoryId,
        enabled: !_saving,
        onCreate: widget.categoryRepository == null ? null : _createCategory,
        onSelected: (categoryId) {
          setState(
            () => _categorySelection = ManualCategorySelection.entryOverride(
              categoryId,
            ),
          );
          _reloadImpact();
        },
      ),
      manualEditorDivider,
    ],
  );

  Widget _dateAndNote(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: _dateTimePart(
              key: const ValueKey('manual-date-field'),
              icon: Icons.calendar_month_outlined,
              label: _formatHungarianEditorDate(_date),
              onTap: _saving ? null : _pickDate,
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xffe1e6ee)),
          Expanded(
            child: _dateTimePart(
              key: const ValueKey('manual-time-field'),
              icon: Icons.schedule_outlined,
              label: _formatHungarianTime(_time),
              onTap: _saving ? null : _pickTime,
            ),
          ),
        ],
      ),
      manualEditorDivider,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ManualEditorIconSurface(
              icon: Icons.edit_outlined,
              color: FluviVisualTokens.textPrimary,
              background: Color(0xfff1f5f9),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Megjegyzés',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    key: const ValueKey('manual-note-field'),
                    controller: _note,
                    focusNode: _noteFocus,
                    minLines: 1,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Megjegyzés hozzáadása',
                      hintStyle: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: FluviVisualTokens.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      manualEditorDivider,
    ],
  );

  Widget _dateTimePart({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Row(
            children: [
              ManualEditorIconSurface(icon: icon),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FluviVisualTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _impactPreview(BuildContext context) {
    final direction = _direction ?? LedgerDirection.expense;
    final amount = _parseHungarianMinor(_amount.text);
    final impact = _impact;
    final category = _category(_selectedCategoryId);
    final period = _formatHungarianMonth(_date);
    final expenseSubtitle = '${category?.name ?? 'Kategorizálatlan'} · $period';
    if (amount == null || amount <= 0) {
      return const _ImpactSurface(
        title: 'A tranzakció hatása',
        message: 'Adj meg érvényes összeget az előnézethez.',
      );
    }
    if (_impactLoading) {
      return const _ImpactSurface(
        title: 'A tranzakció hatása',
        message: 'Előnézet frissítése…',
      );
    }
    if (impact == null) {
      return const _ImpactSurface(
        title: 'A tranzakció hatása',
        message: 'A havi előnézet most nem érhető el.',
      );
    }
    if (direction == LedgerDirection.income) {
      final before = impact.monthIncomeScaled100 - impact.monthExpenseScaled100;
      final after = before + amount;
      return _ImpactSurface(
        title: 'A tranzakció hatása',
        subtitle: 'Havi egyenleg · $period',
        headline: 'Mentés utáni havi egyenleg',
        value: _formatHungarianMinor(after),
        calculation: 'Most: ${_formatHungarianMinor(before)} Ft',
      );
    }
    final limit = impact.categoryLimitScaled100;
    if (limit == null) {
      return const _ImpactSurface(
        title: 'A tranzakció hatása',
        message: 'Ehhez a kategóriához nincs havi keret.',
      );
    }
    final budgetImpact = ManualTransactionBudgetImpactPresentation.calculate(
      limitScaled100: limit,
      spentScaled100: impact.categoryActualScaled100,
      draftScaled100: amount,
    );
    final overrun = budgetImpact.isOverrun;
    return _ImpactSurface(
      title: 'A tranzakció hatása',
      subtitle: expenseSubtitle,
      headline: overrun
          ? 'Keret túllépése mentés után'
          : budgetImpact.isExhausted
          ? 'A havi keret elfogy'
          : 'Mentés után megmarad',
      value: _formatHungarianMinor(
        overrun
            ? budgetImpact.overrunScaled100
            : budgetImpact.remainingScaled100,
      ),
      calculation:
          '${_formatHungarianMinor(impact.categoryActualScaled100)} Ft elköltve + ${_formatHungarianMinor(amount)} Ft most',
      limitLabel: overrun
          ? 'Havi keret: ${_formatHungarianMinor(limit)} Ft · Mentés után elköltve: ${_formatHungarianMinor(budgetImpact.totalScaled100)} Ft'
          : 'Havi keret: ${_formatHungarianMinor(limit)} Ft',
      budgetImpact: budgetImpact,
      overflow: overrun,
    );
  }

  Widget _errorBlock(BuildContext context, {required bool islands}) => Padding(
    padding: EdgeInsets.fromLTRB(islands ? 16 : 20, 14, islands ? 16 : 20, 0),
    child: Text(
      _error!,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );

  Widget _ctaBar(BuildContext context) {
    final gradient =
        (_direction ?? LedgerDirection.expense) == LedgerDirection.income
        ? FluviDirectionColorPaletteCatalog.income(_directionColorProfile)
        : FluviDirectionColorPaletteCatalog.expense(_directionColorProfile);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cancelWidth = _ctaButtonWidth(context, 'Mégse', 104);
              final saveWidth = _ctaButtonWidth(
                context,
                _saving ? 'Mentés…' : 'Mentés',
                120,
              );
              // A Wrap keeps the normal layout as one compact, right-aligned
              // group, while high text scales can use an extra line rather
              // than squeezing, clipping, or expanding across the whole bar.
              return Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: cancelWidth
                          .clamp(0, constraints.maxWidth)
                          .toDouble(),
                      child: _LedgerPillButton(
                        key: const ValueKey('manual-cancel-button'),
                        label: 'Mégse',
                        onPressed: _saving ? null : _cancel,
                      ),
                    ),
                    SizedBox(
                      width: saveWidth
                          .clamp(0, constraints.maxWidth)
                          .toDouble(),
                      child: _LedgerPillButton(
                        key: const ValueKey('manual-save-button'),
                        label: _saving ? 'Mentés…' : 'Mentés',
                        gradient: gradient,
                        primary: true,
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

double _ctaButtonWidth(BuildContext context, String label, double minimum) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: FluviVisualTokens.actionLabelTextStyle),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return (painter.width + 28).clamp(minimum, double.infinity).toDouble();
}

final class _ImpactSurface extends StatelessWidget {
  const _ImpactSurface({
    required this.title,
    this.message,
    this.subtitle,
    this.headline,
    this.value,
    this.calculation,
    this.limitLabel,
    this.budgetImpact,
    this.overflow = false,
  });
  final String title;
  final String? message;
  final String? subtitle;
  final String? headline;
  final String? value;
  final String? calculation;
  final String? limitLabel;
  final ManualTransactionBudgetImpactPresentation? budgetImpact;
  final bool overflow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: FluviVisualTokens.textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -.25,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
      const SizedBox(height: 9),
      if (message != null)
        Text(
          message!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        )
      else ...[
        Text(
          headline!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value Ft',
          key: const ValueKey('manual-impact-value'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: overflow
                ? Theme.of(context).colorScheme.error
                : FluviVisualTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        if (calculation != null)
          Text(
            calculation!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        if (limitLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            limitLabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ],
        if (budgetImpact case final impact?) ...[
          const SizedBox(height: 10),
          _BudgetImpactBar(impact: impact),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ImpactLegend(
                  color: const Color(0xff9786e8),
                  label: 'Elköltve',
                  value: _formatHungarianMinor(impact.spentScaled100),
                ),
              ),
              Expanded(
                child: _ImpactLegend(
                  color: const Color(0xffff999b),
                  label: 'Most',
                  value: _formatHungarianMinor(impact.draftScaled100),
                ),
              ),
              Expanded(
                child: _ImpactLegend(
                  color: impact.isOverrun
                      ? const Color(0xffe45b6a)
                      : const Color(0xffcbd5e1),
                  label: impact.isOverrun ? 'Túllépés' : 'Marad',
                  value: _formatHungarianMinor(
                    impact.isOverrun
                        ? impact.overrunScaled100
                        : impact.remainingScaled100,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ],
  );
}

final class _BudgetImpactBar extends StatelessWidget {
  const _BudgetImpactBar({required this.impact});

  final ManualTransactionBudgetImpactPresentation impact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: impact.isOverrun
        ? 'Költségkeret túllépését jelző sáv'
        : 'Költségkeret felhasználását jelző sáv',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const barTop = 20.0;
        const barHeight = 14.0;
        final markerX = width * impact.limitFraction.clamp(0.0, 1.0);
        final markerLeft = (markerX - 1).clamp(
          0.0,
          (width - 2).clamp(0.0, width),
        );
        final markerLabelLeft = (markerX - 18).clamp(
          0.0,
          (width - 36).clamp(0.0, width),
        );
        return SizedBox(
          key: const ValueKey('manual-impact-budget-bar'),
          height: impact.isOverrun ? 34 : barHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: impact.isOverrun ? barTop : 0,
                left: 0,
                right: 0,
                height: barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: LayoutBuilder(
                    builder: (context, barConstraints) {
                      final barWidth = barConstraints.maxWidth;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xffe2e8f0)),
                          if (impact.spentFraction > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: barWidth * impact.spentFraction,
                              child: const ColoredBox(color: Color(0xff9786e8)),
                            ),
                          if (impact.draftFraction > 0)
                            Positioned(
                              left: barWidth * impact.spentFraction,
                              top: 0,
                              bottom: 0,
                              width: barWidth * impact.draftFraction,
                              child: const ColoredBox(color: Color(0xffff999b)),
                            ),
                          if (impact.isOverrun)
                            Positioned.fill(
                              child: CustomPaint(
                                key: const ValueKey(
                                  'manual-impact-overrun-hatch',
                                ),
                                painter: _BudgetOverrunHatchPainter(
                                  startFraction: impact.limitFraction,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (impact.isOverrun) ...[
                Positioned(
                  key: const ValueKey('manual-impact-limit-marker'),
                  left: markerLeft,
                  top: barTop - 3,
                  width: 2,
                  height: barHeight + 6,
                  child: const ColoredBox(color: Color(0xffbe123c)),
                ),
                Positioned(
                  left: markerLabelLeft,
                  top: 0,
                  child: Text(
                    'Keret',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xff9f1239),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

final class _BudgetOverrunHatchPainter extends CustomPainter {
  const _BudgetOverrunHatchPainter({required this.startFraction});

  final double startFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = size.width * startFraction.clamp(0.0, 1.0);
    if (startX >= size.width) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(startX, 0, size.width - startX, size.height));
    final paint = Paint()
      ..color = const Color(0xffbe123c).withValues(alpha: .46)
      ..strokeWidth = 1;
    for (var x = startX - size.height; x < size.width + size.height; x += 5) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BudgetOverrunHatchPainter oldDelegate) =>
      oldDelegate.startFraction != startFraction;
}

final class _ImpactLegend extends StatelessWidget {
  const _ImpactLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 1),
      Text(
        '$value Ft',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: FluviVisualTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

/// Matches Ledger's direction-control geometry and material resolvers.
final class _LedgerPillButton extends StatelessWidget {
  const _LedgerPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final height = AppSelectorMetrics.directionControlHeight;
    final radius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.directionControl,
          size: Size(168, height),
        );
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.directionControl);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: primary
                ? null
                : (depth.surfaceColor ?? FluviVisualTokens.surface),
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: primary ? Colors.transparent : FluviVisualTokens.border,
            ),
            boxShadow: depth.shadows,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: FluviVisualTokens.actionLabelTextStyle.copyWith(
                  color: primary ? Colors.white : FluviVisualTokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int _epochDay(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(1970)).inDays;
DateTime _dateFromEpochDay(int epochDay) =>
    DateTime.utc(1970).add(Duration(days: epochDay)).toLocal();
const _maxStoredMinor = 9223372036854775807;

int? _parseHungarianMinor(String source) {
  final normalized = source
      .replaceAll(RegExp(r'[\s\u00A0.]'), '')
      .replaceAll(',', '.');
  if (normalized.isEmpty || normalized.startsWith('-')) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(normalized);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  final minor = int.tryParse((match.group(2) ?? '').padRight(2, '0'));
  if (whole == null ||
      minor == null ||
      whole > _maxStoredMinor ~/ 100 ||
      whole == _maxStoredMinor ~/ 100 &&
          minor > _maxStoredMinor.remainder(100)) {
    return null;
  }
  return whole * 100 + minor;
}

String _formatHungarianMinor(int minor) {
  final whole = minor ~/ 100;
  final fraction = minor % 100;
  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(' ');
    grouped.write(digits[index]);
  }
  return fraction == 0
      ? grouped.toString()
      : '${grouped.toString()},${fraction.toString().padLeft(2, '0')}';
}

const _hungarianMonthShort = <String>[
  'jan.',
  'febr.',
  'márc.',
  'ápr.',
  'máj.',
  'jún.',
  'júl.',
  'aug.',
  'szept.',
  'okt.',
  'nov.',
  'dec.',
];

String _formatHungarianEditorDate(DateTime date) {
  final today = DateTime.now();
  final month = _hungarianMonthShort[date.month - 1];
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Ma · $month ${date.day}.';
  }
  return '$month ${date.day}. ${date.year}';
}

String _formatHungarianMonth(DateTime date) =>
    '${_hungarianMonthShort[date.month - 1]} ${date.year}';

String _formatHungarianTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
