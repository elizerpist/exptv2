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
                      _island(_dateNoteAndMore(context)),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _partnerAndCategory(context),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 32),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _dateNoteAndMore(context),
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

  LinearGradient get _heroGradient =>
      FluviDirectionColorPaletteCatalog.income(_directionColorProfile);
  FluviDirectionColorProfile get _directionColorProfile =>
      widget.headerVisualTuning?.value.globalAppearance.directionColorProfile ??
      FluviDirectionColorProfile.original;

  Widget _heroHeader(BuildContext context) => DecoratedBox(
    key: const ValueKey('manual-editor-hero'),
    decoration: BoxDecoration(gradient: _heroGradient),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        20,
        26,
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
        padding: const EdgeInsets.all(20),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
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
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('manual-amount-field'),
          controller: _amount,
          focusNode: _amountFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\s\u00A0]')),
          ],
          maxLines: 1,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: .62)),
            suffixText: 'Ft',
            suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: .78),
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
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
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .18),
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
            child: OutlinedButton(
              key: ValueKey('manual-quick-$amount'),
              onPressed: _saving ? null : () => _addQuickAmount(amount),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
        ListTile(
          key: const ValueKey('manual-partner-field'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(_partner?.displayName ?? 'Partner kiválasztása'),
          subtitle: _partner == null
              ? null
              : Text(_partner!.defaultCategoryName),
          leading: _partner == null
              ? const Icon(Icons.storefront_outlined)
              : PartnerCategoryAvatar(partner: _partner!),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _saving ? null : _pickPartnerFullscreen,
        ),
      const SizedBox(height: 14),
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
      if (_categorySelection.mode ==
          ManualCategoryAssignmentMode.entryOverride) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.edit_outlined, size: 16),
            const SizedBox(width: 4),
            const Text('Egyedi kategória'),
            const Spacer(),
            TextButton(
              onPressed: _partner == null || _saving
                  ? null
                  : () {
                      setState(
                        () => _categorySelection =
                            const ManualCategorySelection.partnerDefault(),
                      );
                      _reloadImpact();
                    },
              child: const Text('Visszaállítás'),
            ),
          ],
        ),
      ] else if (_partner != null)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Partner alapértelmezése'),
        ),
    ],
  );

  Widget _dateNoteAndMore(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                MaterialLocalizations.of(context).formatMediumDate(_date),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _pickTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_time.format(context)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        key: const ValueKey('manual-note-field'),
        controller: _note,
        focusNode: _noteFocus,
        minLines: 1,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Megjegyzés',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 6),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('További adatok'),
        subtitle: const Text('Nincs további szerkeszthető tranzakciómező.'),
        childrenPadding: const EdgeInsets.only(bottom: 6),
        children: [
          Text(
            _editing && _entry?.originKind != 'manual'
                ? 'Az importált tétel eredeti eseményideje megmarad.'
                : 'A partner, kategória, dátum, idő és megjegyzés a fenti mezőkben szerkeszthető.',
          ),
        ],
      ),
    ],
  );

  Widget _impactPreview(BuildContext context) {
    final direction = _direction ?? LedgerDirection.expense;
    final amount = _parseHungarianMinor(_amount.text);
    final impact = _impact;
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
        headline: 'Mentés utáni havi egyenleg',
        value: _formatHungarianMinor(after),
        detail: 'Most: ${_formatHungarianMinor(before)} Ft',
      );
    }
    final limit = impact.categoryLimitScaled100;
    if (limit == null) {
      return const _ImpactSurface(
        title: 'A tranzakció hatása',
        message: 'Ehhez a kategóriához nincs havi keret.',
      );
    }
    final before = limit - impact.categoryActualScaled100;
    final after = before - amount;
    final spent = limit == 0
        ? 1.0
        : (impact.categoryActualScaled100 / limit).clamp(0.0, 1.0).toDouble();
    final draft = limit == 0
        ? 0.0
        : (amount / limit).clamp(0.0, 1.0 - spent).toDouble();
    return _ImpactSurface(
      title: 'A tranzakció hatása',
      headline: 'Mentés után megmarad',
      value: '${after < 0 ? '−' : ''}${_formatHungarianMinor(after.abs())}',
      detail: 'Most rendelkezésre áll: ${_formatHungarianMinor(before)} Ft',
      fraction: (spent, draft),
      overflow: after < 0,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: _LedgerPillButton(
                key: const ValueKey('manual-cancel-button'),
                label: 'Mégse',
                onPressed: _saving ? null : _cancel,
              ),
            ),
            const SizedBox(width: FluviVisualTokens.controlInnerGap),
            Expanded(
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
      ),
    );
  }
}

final class _ImpactSurface extends StatelessWidget {
  const _ImpactSurface({
    required this.title,
    this.message,
    this.headline,
    this.value,
    this.detail,
    this.fraction,
    this.overflow = false,
  });
  final String title;
  final String? message;
  final String? headline;
  final String? value;
  final String? detail;
  final (double spent, double draft)? fraction;
  final bool overflow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      if (message != null)
        Text(message!)
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
        const SizedBox(height: 8),
        if (fraction case final segments?)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (segments.$1 * 1000).round().clamp(0, 1000).toInt(),
                    child: const ColoredBox(color: Color(0xff94a3b8)),
                  ),
                  Expanded(
                    flex: (segments.$2 * 1000).round().clamp(0, 1000).toInt(),
                    child: const ColoredBox(color: Color(0xffe478c3)),
                  ),
                  Expanded(
                    flex: ((1 - segments.$1 - segments.$2) * 1000)
                        .round()
                        .clamp(0, 1000)
                        .toInt(),
                    child: const ColoredBox(color: Color(0xffe2e8f0)),
                  ),
                ],
              ),
            ),
          ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
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
