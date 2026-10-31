import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/categories/domain/category_repository.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_editor_sheet.dart';
import '../../../core/categories/presentation/category_visual_badge.dart';
import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_corner_profile.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_global_appearance.dart';
import '../../../core/navigation/creation_slide_up_route.dart';
import '../../../core/presentation/child_editor_sheet.dart';
import '../../dashboard/presentation/dashboard_corner_roundness.dart';
import '../../dashboard/presentation/dashboard_shadow_style.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/application/manual_transaction_editor_preferences.dart';
import '../../manual_transactions/domain/manual_transaction_models.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../../manual_transactions/presentation/category_dropdown.dart';
import '../../manual_transactions/presentation/manual_transaction_editor_field_rows.dart';
import '../../manual_transactions/presentation/partner_selector.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'push_profile_navigation.dart';

const _recurringPrimary = Color(0xff19264d);
const _recurringSecondary = Color(0xff718096);
const _recurringDivider = Color(0xffe5e9f0);
const _recurringNeutral = Color(0xfff1f5f9);
const _recurringListBackground = Color(0xfff5f6fa);

/// The unified, single-session recurrence editor. The legacy multi-step
/// wizard remains separately reachable through [RecurringUiDesign.legacy].
final class UnifiedRecurringTransactionEditorPage extends StatefulWidget {
  const UnifiedRecurringTransactionEditorPage.create({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required this.initialDirection,
    this.categoryRepository,
    this.preferencesStore,
    this.permissions,
    this.directionColorProfile = FluviDirectionColorProfile.original,
    this.pushProfileUiDesign = PushProfileUiDesign.unified,
  }) : existingRule = null;

  const UnifiedRecurringTransactionEditorPage.edit({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required RecurrenceRule this.existingRule,
    this.categoryRepository,
    this.preferencesStore,
    this.permissions,
    this.directionColorProfile = FluviDirectionColorProfile.original,
    this.pushProfileUiDesign = PushProfileUiDesign.unified,
  }) : initialDirection = null;

  final AutomationRepository repository;
  final ManualTransactionRepository manualRepository;
  final List<FluviCategory> categories;
  final CategoryRepository? categoryRepository;
  final ManualTransactionEditorPreferencesStore? preferencesStore;
  final AutomationPermissionRepository? permissions;
  final FluviDirectionColorProfile directionColorProfile;
  final PushProfileUiDesign pushProfileUiDesign;
  final LedgerDirection? initialDirection;
  final RecurrenceRule? existingRule;

  @override
  State<UnifiedRecurringTransactionEditorPage> createState() =>
      _UnifiedRecurringTransactionEditorPageState();
}

final class _UnifiedRecurringTransactionEditorPageState
    extends State<UnifiedRecurringTransactionEditorPage> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late List<FluviCategory> _categories;
  ManualPartnerSelection? _partner;
  PartnerDirectoryEntry? _partnerSnapshot;
  ManualCategorySelection _categorySelection =
      const ManualCategorySelection.partnerDefault();
  late RecurrenceTriggerKind _trigger;
  late RecurrenceAmountPolicy _policy;
  late DateTime _firstDate;
  late TimeOfDay _time;
  DateTime? _endDate;
  String _timezoneId = 'Europe/Budapest';
  List<PushProfile> _profiles = const [];
  List<PushRule> _pushRules = const [];
  String? _pushProfileId;
  String? _pushRuleId;
  int _toleranceScaled100 = 0;
  int _dayWindow = 2;
  List<RecurrencePreview> _preview = const [];
  bool _saving = false;
  bool _partnerExpanded = false;
  bool _categoryExpanded = false;
  bool _showMetadataSurfaces = true;
  String? _amountError;
  String? _partnerError;
  String? _nameError;
  String? _error;

  bool get _editing => widget.existingRule != null;
  LedgerDirection get _direction =>
      widget.existingRule?.direction ?? widget.initialDirection!;
  int get _epochDay => _firstDate.difference(DateTime(1970)).inDays;
  int get _minutes => _time.hour * 60 + _time.minute;
  int? get _amountScaled100 => _parseMoney(_amount.text);
  bool get _knownAmount => _policy != RecurrenceAmountPolicy.unknown;

  @override
  void initState() {
    super.initState();
    _categories = List<FluviCategory>.of(widget.categories);
    final existing = widget.existingRule;
    _trigger = existing?.triggerKind ?? RecurrenceTriggerKind.time;
    _policy = existing?.amountPolicy ?? RecurrenceAmountPolicy.fixed;
    _firstDate = DateTime.now().add(const Duration(days: 1));
    if (existing != null) {
      _name.text = existing.name;
      _amount.text = existing.amountScaled100 == null
          ? ''
          : _formatMoney(existing.amountScaled100!);
      _note.text = existing.note ?? '';
      _firstDate = DateTime(
        1970,
      ).add(Duration(days: existing.startLocalEpochDay));
      _time = TimeOfDay(
        hour: existing.localTimeMinutes ~/ 60,
        minute: existing.localTimeMinutes % 60,
      );
      _endDate = existing.endLocalEpochDay == null
          ? null
          : DateTime(1970).add(Duration(days: existing.endLocalEpochDay!));
      _timezoneId = existing.timezoneId;
      _pushProfileId = existing.pushProfileId;
      _pushRuleId = existing.pushRuleId;
      _toleranceScaled100 = existing.amountToleranceScaled100;
      _dayWindow = existing.dayWindow;
      _categorySelection = existing.categoryAssignmentMode == 'entryOverride'
          ? ManualCategorySelection.entryOverride(existing.categoryId)
          : const ManualCategorySelection.partnerDefault();
      unawaited(_loadExistingPartner(existing.partnerId));
    } else {
      _time = const TimeOfDay(hour: 8, minute: 0);
    }
    _amount.addListener(_refreshPreview);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final store = widget.preferencesStore;
    if (store != null) {
      try {
        final preferences = await store.read();
        if (mounted) {
          setState(
            () =>
                _showMetadataSurfaces = preferences.showMetadataIconBackgrounds,
          );
        }
      } catch (_) {}
    }
    try {
      final profiles = await widget.repository.listProfiles();
      if (mounted) setState(() => _profiles = profiles);
      if (_pushProfileId != null) await _loadPushRules(_pushProfileId!);
    } catch (_) {
      // An unbound push draft is valid and remains visibly "Beállításra vár".
    }
    _refreshPreview();
  }

  Future<void> _loadExistingPartner(String id) async {
    try {
      final result = await widget.manualRepository.getPartnerById(id);
      if (mounted && result != null) {
        setState(() {
          _partner = ExistingManualPartner(id, directoryEntry: result);
          _partnerSnapshot = result;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<List<PushRule>> _fetchPushRules(String profileId) async {
    try {
      final rules = await widget.repository.rules(profileId);
      if (mounted && _pushProfileId == profileId) {
        setState(() => _pushRules = rules);
      }
      return rules;
    } catch (_) {}
    return const [];
  }

  Future<void> _loadPushRules(String profileId) async {
    await _fetchPushRules(profileId);
  }

  Future<void> _refreshPreview() async {
    try {
      final preview = await widget.repository.previewRecurringOccurrences(
        dayOfMonth: _firstDate.day,
        localTimeMinutes: _minutes,
        startLocalEpochDay: _epochDay,
        endLocalEpochDay: _endDate?.difference(DateTime(1970)).inDays,
        timezoneId: _timezoneId,
      );
      if (mounted) setState(() => _preview = preview);
    } catch (_) {
      // A local, deterministic fallback keeps the editor readable in an
      // embedded host; Android uses the Core projection above.
      if (mounted) setState(() => _preview = _localPreview());
    }
  }

  List<RecurrencePreview> _localPreview() {
    final result = <RecurrencePreview>[];
    var date = DateTime(_firstDate.year, _firstDate.month, _firstDate.day);
    for (var index = 0; index < 3; index++) {
      final year = date.year;
      final month = date.month + index;
      final monthStart = DateTime(year, month, 1);
      final nextMonth = DateTime(year, month + 1, 1);
      final lastDay = nextMonth.subtract(const Duration(days: 1)).day;
      final day = _firstDate.day.clamp(1, lastDay);
      final current = DateTime(monthStart.year, monthStart.month, day);
      if (_endDate != null && current.isAfter(_endDate!)) break;
      result.add(
        RecurrencePreview(
          expectedLocalEpochDay: current.difference(DateTime(1970)).inDays,
          expectedLocalTimeMinutes: _minutes,
          expectedAtUtcMs: current
              .add(Duration(minutes: _minutes))
              .toUtc()
              .millisecondsSinceEpoch,
        ),
      );
      date = monthStart;
    }
    return result;
  }

  void _setPartner(ManualPartnerSelection selection) {
    final snapshot = switch (selection) {
      ExistingManualPartner(:final directoryEntry) => directoryEntry,
      NewManualPartner(:final displayName, :final defaultCategoryId) =>
        _newPartnerSnapshot(displayName, defaultCategoryId),
    };
    setState(() {
      _partner = selection;
      _partnerSnapshot = snapshot;
      _categorySelection = const ManualCategorySelection.partnerDefault();
      _partnerExpanded = false;
      _partnerError = null;
      if (_name.text.trim().isEmpty && snapshot != null) {
        _name.text = snapshot.displayName;
      }
    });
  }

  PartnerDirectoryEntry? _newPartnerSnapshot(String name, String categoryId) {
    final category = _categoryById(categoryId);
    if (category == null) return null;
    return PartnerDirectoryEntry(
      partnerId: '',
      displayName: name,
      originalName: name,
      defaultCategoryId: categoryId,
      defaultCategoryName: category.name,
      categoryColorId: category.colorId,
      categoryIconId: category.iconId,
      isUncategorized: category.isSystemUncategorized,
      searchNames: [name],
    );
  }

  FluviCategory? _categoryById(String? id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> _editCategory(FluviCategory category) async {
    final repository = widget.categoryRepository;
    if (repository == null) return;
    final updated = await showCategoryEditorSheet(
      context,
      repository: repository,
      category: category,
    );
    if (updated == null || !mounted) return;
    setState(() {
      _categories = [
        for (final item in _categories)
          if (item.id == updated.id) updated else item,
      ];
    });
  }

  Future<void> _createCategory() async {
    final repository = widget.categoryRepository;
    if (repository == null) return;
    final created = await showCategoryEditorSheet(
      context,
      repository: repository,
    );
    if (created == null || !mounted) return;
    setState(() => _categories = [..._categories, created]);
  }

  Future<void> _configureTiming() async {
    final result = await showFluviChildEditorSheet<_TimingDraft>(
      context,
      builder: (_) =>
          _TimingSheet(initial: _TimingDraft(_firstDate, _time, _endDate)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _firstDate = result.first;
      _time = result.time;
      _endDate = result.end;
    });
    _refreshPreview();
  }

  Future<void> _configureAmountPolicy() async {
    final result = await showFluviChildEditorSheet<RecurrenceAmountPolicy>(
      context,
      builder: (_) => _AmountPolicySheet(initial: _policy, trigger: _trigger),
    );
    if (result == null || !mounted) return;
    setState(() {
      _policy = result;
      _amountError = null;
      if (_policy == RecurrenceAmountPolicy.unknown) _amount.clear();
    });
  }

  Future<void> _configureBankLink() async {
    final result = await showFluviChildEditorSheet<_BankLinkDraft>(
      context,
      builder: (_) => _BankLinkSheet(
        profiles: _profiles,
        rules: _pushRules,
        direction: _direction,
        initial: _BankLinkDraft(
          _pushProfileId,
          _pushRuleId,
          _toleranceScaled100,
          _dayWindow,
        ),
        knownAmount: _knownAmount,
        onProfileChanged: _fetchPushRules,
        onCreateProfile: _createPushProfile,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _pushProfileId = result.profileId;
      _pushRuleId = result.ruleId;
      _toleranceScaled100 = result.toleranceScaled100;
      _dayWindow = result.dayWindow;
    });
  }

  Future<List<PushProfile>> _createPushProfile() async {
    final permissions = widget.permissions;
    if (permissions == null) return _profiles;
    await PushProfileNavigation.openCreate(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      permissions: permissions,
    );
    final profiles = await widget.repository.listProfiles();
    if (mounted) setState(() => _profiles = profiles);
    return profiles;
  }

  Future<void> _toggleMetadataSurfaces() async {
    final next = !_showMetadataSurfaces;
    setState(() => _showMetadataSurfaces = next);
    final store = widget.preferencesStore;
    if (store != null) {
      unawaited(
        store.write(
          ManualTransactionEditorPreferences(showMetadataIconBackgrounds: next),
        ),
      );
    }
  }

  bool _validate() {
    final amountInvalid =
        _trigger == RecurrenceTriggerKind.time &&
        (!_knownAmount || (_amountScaled100 ?? 0) <= 0);
    setState(() {
      _nameError = _name.text.trim().isEmpty
          ? 'Adj meg egy megnevezést.'
          : null;
      _partnerError = _partner == null ? 'Válassz partnert.' : null;
      _amountError = amountInvalid
          ? 'Időzített ismétlődéshez pozitív összeg kell.'
          : null;
    });
    return _nameError == null && _partnerError == null && _amountError == null;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final rule = _editing
          ? await widget.repository.updateRecurringRule(
              ruleId: widget.existingRule!.ruleId,
              expectedRuleVersion: widget.existingRule!.ruleVersion,
              name: _name.text.trim(),
              partnerId: switch (_partner!) {
                ExistingManualPartner(:final partnerId) => partnerId,
                NewManualPartner() => throw StateError(
                  'Meglévő ismétlődés partnerét előbb válaszd ki a listából.',
                ),
              },
              categorySelection: _categorySelection,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              triggerKind: _trigger,
              amountPolicy: _policy,
              amountScaled100: _knownAmount ? _amountScaled100 : null,
              dayOfMonth: _firstDate.day,
              localTimeMinutes: _minutes,
              startLocalEpochDay: _epochDay,
              endLocalEpochDay: _endDate?.difference(DateTime(1970)).inDays,
              timezoneId: _timezoneId,
              pushProfileId: _trigger == RecurrenceTriggerKind.push
                  ? _pushProfileId
                  : null,
              pushRuleId: _trigger == RecurrenceTriggerKind.push
                  ? _pushRuleId
                  : null,
              amountToleranceScaled100: _toleranceScaled100,
              dayWindow: _dayWindow,
            )
          : await widget.repository.createRecurringRuleWithPartner(
              name: _name.text.trim(),
              partner: _partner!,
              categorySelection: _categorySelection,
              direction: _direction,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              triggerKind: _trigger,
              amountPolicy: _policy,
              amountScaled100: _knownAmount ? _amountScaled100 : null,
              dayOfMonth: _firstDate.day,
              localTimeMinutes: _minutes,
              startLocalEpochDay: _epochDay,
              endLocalEpochDay: _endDate?.difference(DateTime(1970)).inDays,
              timezoneId: _timezoneId,
              pushProfileId: _trigger == RecurrenceTriggerKind.push
                  ? _pushProfileId
                  : null,
              pushRuleId: _trigger == RecurrenceTriggerKind.push
                  ? _pushRuleId
                  : null,
              amountToleranceScaled100: _toleranceScaled100,
              dayWindow: _dayWindow,
            );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute<bool>(
          builder: (_) => UnifiedRecurringRuleDetailPage(
            repository: widget.repository,
            manualRepository: widget.manualRepository,
            categories: _categories,
            ruleId: rule.ruleId,
            categoryRepository: widget.categoryRepository,
            preferencesStore: widget.preferencesStore,
          ),
        ),
        result: true,
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: ListView(
              key: const ValueKey('unified-recurring-editor-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              children: [
                _triggerSegment(),
                const SizedBox(height: 8),
                _form(),
                if (_error != null) _errorPanel(),
                const SizedBox(height: 22),
                _previewSection(),
              ],
            ),
          ),
          _footer(),
        ],
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    final palette = _direction == LedgerDirection.income
        ? FluviDirectionColorPaletteCatalog.income(widget.directionColorProfile)
        : FluviDirectionColorPaletteCatalog.expense(
            widget.directionColorProfile,
          );
    return DecoratedBox(
      key: const ValueKey<String>('unified-recurring-editor-hero'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: palette.begin,
          end: palette.end,
          colors: [
            for (final color in palette.colors)
              Color.lerp(color, Colors.white, .78)!,
          ],
          stops: palette.stops,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 12,
          20,
          20,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showArtwork = _canShowHeroArtwork(
              context,
              constraints.maxWidth,
            );
            final amountWidth = constraints.maxWidth - (showArtwork ? 92 : 0);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (showArtwork)
                  Positioned(
                    right: -6,
                    bottom: -8,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: Image.asset(
                            'assets/fluvi/manual_transaction_hero/'
                            '${_direction == LedgerDirection.income ? 'income' : 'expense'}_${widget.directionColorProfile.name}.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: 'Vissza',
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: _recurringPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _editing
                                ? 'Ismétlődés szerkesztése'
                                : 'Új ismétlődés',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _recurringPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.2,
                                ),
                          ),
                        ),
                        _MetadataToggle(
                          showSurface: _showMetadataSurfaces,
                          onTap: _saving ? null : _toggleMetadataSurfaces,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _policy == RecurrenceAmountPolicy.unknown
                          ? 'Várható összeg'
                          : 'Összeg',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _recurringSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    _heroAmountEditor(context, maxWidth: amountWidth),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle? _heroAmountStyle(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall?.copyWith(
        color: _recurringPrimary,
        fontWeight: FontWeight.w900,
        letterSpacing: -.8,
        height: 1.08,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  double _heroCurrencyWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ft',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _recurringPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _heroAmountWidth(
    BuildContext context,
    TextStyle? style, {
    required double maxWidth,
  }) {
    final displayed = _policy == RecurrenceAmountPolicy.unknown
        ? 'Értesítésből'
        : (_amount.text.isEmpty ? '0' : _amount.text);
    final painter = TextPainter(
      text: TextSpan(text: displayed, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: maxWidth.clamp(52, 244).toDouble());
    return (painter.width + 12).clamp(52, maxWidth.clamp(52, 244)).toDouble();
  }

  bool _canShowHeroArtwork(BuildContext context, double headerWidth) {
    final amountWidth = _heroAmountWidth(
      context,
      _heroAmountStyle(context),
      maxWidth: 244,
    );
    return amountWidth + 4 + _heroCurrencyWidth(context) <= headerWidth - 92;
  }

  Widget _heroAmountEditor(BuildContext context, {required double maxWidth}) {
    final amountStyle = _heroAmountStyle(context);
    final amountAvailable = (maxWidth - 4 - _heroCurrencyWidth(context))
        .clamp(52, 244)
        .toDouble();
    final fieldWidth = _heroAmountWidth(
      context,
      amountStyle,
      maxWidth: amountAvailable,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: fieldWidth,
          child: _policy == RecurrenceAmountPolicy.unknown
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Értesítésből', style: amountStyle),
                )
              : TextField(
                  key: const ValueKey<String>('unified-recurring-amount-field'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  maxLines: 1,
                  style: amountStyle,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: amountStyle?.copyWith(
                      color: _recurringPrimary.withValues(alpha: .36),
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
        if (_policy != RecurrenceAmountPolicy.unknown) ...[
          const SizedBox(width: 4),
          Text(
            'Ft',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _recurringPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _triggerSegment() => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xffeceef7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _SegmentOption(
            label: 'Időzítve',
            selected: _trigger == RecurrenceTriggerKind.time,
            onTap: () => setState(() {
              _trigger = RecurrenceTriggerKind.time;
              if (_policy == RecurrenceAmountPolicy.unknown) {
                _amountError = 'Adj meg összeget.';
              }
            }),
          ),
          _SegmentOption(
            label: 'Banki értesítésből',
            selected: _trigger == RecurrenceTriggerKind.push,
            onTap: () => setState(() => _trigger = RecurrenceTriggerKind.push),
          ),
        ],
      ),
    ),
  );

  Widget _form() => Column(
    children: [
      ManualEditorSelectionRow(
        label: 'Összeg jellege',
        value: switch (_policy) {
          RecurrenceAmountPolicy.fixed => 'Fix összeg',
          RecurrenceAmountPolicy.estimated => 'Becsült összeg',
          RecurrenceAmountPolicy.unknown => 'Értesítésből',
        },
        leading: const ManualEditorIconSurface(
          icon: Icons.payments_outlined,
          showBackground: true,
          background: _recurringNeutral,
        ),
        onTap: _configureAmountPolicy,
      ),
      manualEditorDivider,
      _nameRow(),
      manualEditorDivider,
      PartnerDropdown(
        repository: widget.manualRepository,
        categories: _categories,
        selectedPartnerId: switch (_partner) {
          ExistingManualPartner(:final partnerId) => partnerId,
          _ => null,
        },
        selectedPartner: _partnerSnapshot,
        expanded: _partnerExpanded,
        onExpandedChanged: (expanded) => setState(() {
          _partnerExpanded = expanded;
          if (expanded) _categoryExpanded = false;
        }),
        onSelected: _setPartner,
      ),
      if (_partnerError != null) _fieldError(_partnerError!),
      manualEditorDivider,
      CategoryDropdown(
        categories: _categories,
        selectedCategoryId:
            _categorySelection.categoryId ??
            _partnerSnapshot?.defaultCategoryId,
        inline: true,
        expanded: _categoryExpanded,
        onExpandedChanged: (expanded) => setState(() {
          _categoryExpanded = expanded;
          if (expanded) _partnerExpanded = false;
        }),
        onSelected: (id) => setState(() {
          _categorySelection = ManualCategorySelection.entryOverride(id);
          _categoryExpanded = false;
        }),
        onCreate: widget.categoryRepository == null ? null : _createCategory,
        onEdit: widget.categoryRepository == null ? null : _editCategory,
      ),
      if (_categorySelection.mode == ManualCategoryAssignmentMode.entryOverride)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(
              () => _categorySelection =
                  const ManualCategorySelection.partnerDefault(),
            ),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Partner alapértelmezésének visszaállítása'),
          ),
        ),
      manualEditorDivider,
      ManualEditorSelectionRow(
        label: 'Ismétlődés',
        value: 'Havonta, ${_firstDate.day}-én',
        leading: const ManualEditorIconSurface(
          icon: Icons.repeat_rounded,
          background: _recurringNeutral,
        ),
        onTap: _configureTiming,
      ),
      manualEditorDivider,
      Row(
        children: [
          Expanded(
            child: _datePart(
              'Első alkalom',
              _dateLabel(_firstDate),
              Icons.calendar_today_outlined,
              _pickFirstDate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _datePart(
              'Idő',
              _time.format(context),
              Icons.schedule_outlined,
              _pickTime,
            ),
          ),
        ],
      ),
      manualEditorDivider,
      ManualEditorSelectionRow(
        label: 'Befejezés',
        value: _endDate == null
            ? 'Nincs befejező dátum'
            : _dateLabel(_endDate!),
        leading: const ManualEditorIconSurface(
          icon: Icons.event_busy_outlined,
          background: _recurringNeutral,
        ),
        onTap: _configureTiming,
      ),
      if (_trigger == RecurrenceTriggerKind.push) ...[
        manualEditorDivider,
        ManualEditorSelectionRow(
          label: 'Banki összekapcsolás',
          value: _bankLinkLabel,
          leading: const ManualEditorIconSurface(
            icon: Icons.account_balance_outlined,
            background: _recurringNeutral,
          ),
          onTap: _configureBankLink,
        ),
      ],
      manualEditorDivider,
      _noteRow(),
    ],
  );

  Widget _nameRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ManualEditorIconSurface(
          icon: Icons.label_outline_rounded,
          background: _recurringNeutral,
        ),
        const SizedBox(width: ManualEditorFieldMetrics.leadingToText),
        Expanded(
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              color: _recurringPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Megnevezés',
              hintText: 'Például Netflix előfizetés',
              isDense: true,
              border: InputBorder.none,
              errorText: _nameError,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _datePart(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            ManualEditorIconSurface(
              icon: icon,
              background: _recurringNeutral,
              showBackground: _showMetadataSurfaces,
            ),
            const SizedBox(width: ManualEditorFieldMetrics.leadingToText),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _recurringSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _recurringPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _noteRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManualEditorIconSurface(
          icon: Icons.notes_rounded,
          background: _recurringNeutral,
          showBackground: _showMetadataSurfaces,
        ),
        const SizedBox(width: ManualEditorFieldMetrics.leadingToText),
        Expanded(
          child: TextField(
            controller: _note,
            minLines: 1,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Megjegyzés',
              hintText: 'Opcionális',
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _previewSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Következő alkalmak',
        style: TextStyle(
          color: _recurringPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 310;
          final children = _preview.map((item) => _previewItem(item)).toList();
          return stacked
              ? Column(children: children)
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      for (var i = 0; i < children.length; i++)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : const Border(
                                      left: BorderSide(
                                        color: _recurringDivider,
                                      ),
                                    ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: children[i],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
        },
      ),
      const SizedBox(height: 14),
      Text(
        _trigger == RecurrenceTriggerKind.time
            ? 'A megadott összeget automatikusan rögzíti.'
            : 'A tényleges összeget a megfelelő banki értesítés alapján rögzíti.',
        style: const TextStyle(color: _recurringSecondary, fontSize: 13),
      ),
    ],
  );

  Widget _previewItem(RecurrencePreview item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _shortDate(
            DateTime(1970).add(Duration(days: item.expectedLocalEpochDay)),
          ),
          style: const TextStyle(
            color: _recurringSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _amountLabel,
          style: const TextStyle(
            color: _recurringPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  String get _amountLabel => switch (_policy) {
    RecurrenceAmountPolicy.fixed =>
      _amountScaled100 == null ? '—' : '${_formatMoney(_amountScaled100!)} Ft',
    RecurrenceAmountPolicy.estimated =>
      _amountScaled100 == null
          ? 'kb. —'
          : 'kb. ${_formatMoney(_amountScaled100!)} Ft',
    RecurrenceAmountPolicy.unknown => 'Értesítésből',
  };
  String get _bankLinkLabel {
    final profile = _profiles
        .where((item) => item.profileId == _pushProfileId)
        .firstOrNull;
    final rule = _pushRules
        .where((item) => item.ruleId == _pushRuleId)
        .firstOrNull;
    return profile == null || rule == null
        ? 'Beállításra vár'
        : '${profile.displayName} · ${rule.name}';
  }

  Widget _footer() => _RecurringCtaFooter(
    direction: _direction,
    colorProfile: widget.directionColorProfile,
    actions: [
      _RecurringFooterAction(
        label: 'Mégse',
        primary: false,
        onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
      ),
      _RecurringFooterAction(
        label: _saving ? 'Mentés…' : (_editing ? 'Mentés' : 'Létrehozás'),
        primary: true,
        onPressed: _saving ? null : _save,
      ),
    ],
  );

  Widget _errorPanel() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      'Az ismétlődés nem menthető: $_error',
      style: const TextStyle(color: Color(0xffb4233c)),
    ),
  );
  Widget _fieldError(String value) => Padding(
    padding: const EdgeInsets.only(left: 53, bottom: 8),
    child: Text(
      value,
      style: const TextStyle(color: Color(0xffb4233c), fontSize: 12),
    ),
  );

  Future<void> _pickFirstDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _firstDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => _firstDate = selected);
      _refreshPreview();
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) {
      setState(() => _time = selected);
      _refreshPreview();
    }
  }
}

/// Full-screen unified manager. It keeps the rules and occurrences scroll
/// states independent through their own keyed list views.
final class UnifiedRecurringManagerPage extends StatefulWidget {
  const UnifiedRecurringManagerPage({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required this.direction,
    this.categoryRepository,
    this.preferencesStore,
    this.permissions,
    this.onOpenLedgerEntry,
    this.initialRulesTab = true,
    this.initialOccurrenceFilter = RecurrenceOccurrenceStatus.pending,
    this.initialOccurrenceFromUtcMs,
    this.initialOccurrenceToUtcMs,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository manualRepository;
  final List<FluviCategory> categories;
  final LedgerDirection direction;
  final CategoryRepository? categoryRepository;
  final ManualTransactionEditorPreferencesStore? preferencesStore;
  final AutomationPermissionRepository? permissions;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  final bool initialRulesTab;
  final RecurrenceOccurrenceStatus? initialOccurrenceFilter;
  final int? initialOccurrenceFromUtcMs, initialOccurrenceToUtcMs;
  @override
  State<UnifiedRecurringManagerPage> createState() =>
      _UnifiedRecurringManagerPageState();
}

final class _UnifiedRecurringManagerPageState
    extends State<UnifiedRecurringManagerPage> {
  static const _occurrencePageSize = 100;
  List<RecurrenceRule>? _rules;
  List<RecurrenceOccurrence>? _occurrences;
  late bool _rulesTab;
  String _query = '';
  late RecurrenceOccurrenceStatus? _filter;
  final ScrollController _occurrencesScroll = ScrollController();
  bool _loadingMoreOccurrences = false;
  bool _hasMoreOccurrences = true;
  @override
  void initState() {
    super.initState();
    _rulesTab = widget.initialRulesTab;
    _filter = widget.initialOccurrenceFilter;
    _occurrencesScroll.addListener(_onOccurrenceScroll);
    _load();
  }

  @override
  void dispose() {
    _occurrencesScroll
      ..removeListener(_onOccurrenceScroll)
      ..dispose();
    super.dispose();
  }

  void _onOccurrenceScroll() {
    if (!_occurrencesScroll.hasClients ||
        _loadingMoreOccurrences ||
        !_hasMoreOccurrences ||
        _occurrencesScroll.position.extentAfter > 240) {
      return;
    }
    unawaited(_loadMoreOccurrences());
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        widget.repository.recurringRules(),
        widget.repository.recurrenceOccurrences(
          status: _filter,
          fromUtcMs: widget.initialOccurrenceFromUtcMs,
          toUtcMs: widget.initialOccurrenceToUtcMs,
          limit: _occurrencePageSize,
        ),
      ]);
      if (mounted) {
        setState(() {
          _rules = values[0] as List<RecurrenceRule>;
          _occurrences = values[1] as List<RecurrenceOccurrence>;
          _hasMoreOccurrences = _occurrences!.length == _occurrencePageSize;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rules = const [];
          _occurrences = const [];
          _hasMoreOccurrences = false;
        });
      }
    }
  }

  Future<void> _loadMoreOccurrences() async {
    final current = _occurrences;
    if (current == null || _loadingMoreOccurrences || !_hasMoreOccurrences) {
      return;
    }
    setState(() => _loadingMoreOccurrences = true);
    try {
      final next = await widget.repository.recurrenceOccurrences(
        status: _filter,
        fromUtcMs: widget.initialOccurrenceFromUtcMs,
        toUtcMs: widget.initialOccurrenceToUtcMs,
        limit: _occurrencePageSize,
        offset: current.length,
      );
      if (!mounted) return;
      final known = current.map((item) => item.occurrenceId).toSet();
      setState(() {
        _occurrences = [
          ...current,
          ...next.where((item) => known.add(item.occurrenceId)),
        ];
        _hasMoreOccurrences = next.length == _occurrencePageSize;
      });
    } finally {
      if (mounted) setState(() => _loadingMoreOccurrences = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _recurringListBackground,
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              20,
              8,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Vissza',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Ismétlődések',
                    style: TextStyle(
                      color: _recurringPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _plusButton(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _summary(),
          ),
          const SizedBox(height: 14),
          _tabs(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Keresés',
                filled: true,
                fillColor: _recurringNeutral,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_rulesTab) _filters(),
          Expanded(
            child: _rules == null || _occurrences == null
                ? const Center(child: CircularProgressIndicator())
                : (_rulesTab ? _rulesList() : _occurrenceList()),
          ),
        ],
      ),
    ),
  );
  Widget _plusButton() => SizedBox(
    width: 44,
    height: 44,
    child: Tooltip(
      message: widget.direction == LedgerDirection.expense
          ? 'Új ismétlődő kiadás'
          : 'Új ismétlődő bevétel',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.of(context).push<bool>(
              creationSlideUpRoute<bool>(
                fullscreenDialog: true,
                builder: (_) => UnifiedRecurringTransactionEditorPage.create(
                  repository: widget.repository,
                  manualRepository: widget.manualRepository,
                  categories: widget.categories,
                  categoryRepository: widget.categoryRepository,
                  preferencesStore: widget.preferencesStore,
                  permissions: widget.permissions,
                  initialDirection: widget.direction,
                ),
              ),
            );
            _load();
          },
          child: const Icon(Icons.add_rounded, color: _recurringPrimary),
        ),
      ),
    ),
  );
  Widget _summary() {
    final rules = _rules ?? const <RecurrenceRule>[];
    final active = rules.where((item) => item.isActive).length;
    final paused = rules.length - active;
    final waiting = rules
        .where(
          (item) =>
              item.triggerKind == RecurrenceTriggerKind.push &&
              (item.pushProfileId == null || item.pushRuleId == null),
        )
        .length;
    return Text(
      '$active aktív · $waiting beállításra vár · $paused szünetel',
      style: const TextStyle(color: _recurringSecondary, fontSize: 13),
    );
  }

  Widget _tabs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffeceef7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _SegmentOption(
              label: 'Szabályok',
              selected: _rulesTab,
              onTap: () => setState(() => _rulesTab = true),
            ),
            _SegmentOption(
              label: 'Alkalmak',
              selected: !_rulesTab,
              onTap: () => setState(() => _rulesTab = false),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _filters() => SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final item in <(String, RecurrenceOccurrenceStatus?)>[
          ('Várható', RecurrenceOccurrenceStatus.pending),
          ('Ellenőrzendő', RecurrenceOccurrenceStatus.review),
          ('Előzmények', RecurrenceOccurrenceStatus.realized),
          ('Összes', null),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$1),
              selected: _filter == item.$2,
              onSelected: (_) {
                setState(() => _filter = item.$2);
                _load();
              },
            ),
          ),
      ],
    ),
  );
  List<RecurrenceRule> get _visibleRules => (_rules ?? const [])
      .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
      .toList();
  Widget _rulesList() {
    final active = _visibleRules
        .where((item) => item.isActive && !_needsSetup(item))
        .toList();
    final waiting = _visibleRules.where(_needsSetup).toList();
    final paused = _visibleRules.where((item) => !item.isActive).toList();
    return ListView(
      key: const PageStorageKey('unified-recurring-rules'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ruleGroup('Aktív', active),
        _ruleGroup('Beállításra vár', waiting),
        _ruleGroup('Szünetel', paused),
      ],
    );
  }

  bool _needsSetup(RecurrenceRule item) =>
      item.triggerKind == RecurrenceTriggerKind.push &&
      (item.pushProfileId == null || item.pushRuleId == null);
  Widget _ruleGroup(String title, List<RecurrenceRule> rules) {
    if (rules.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _recurringPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rules.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _recurringDivider),
                  _ruleRow(rules[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(RecurrenceRule item) => ListTile(
    leading: _categoryAvatar(_categoryFor(item.categoryId), 40),
    title: Text(
      item.name,
      style: const TextStyle(
        color: _recurringPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      _needsSetup(item)
          ? 'Teendő · Banki profil összekapcsolása'
          : 'Havonta ${item.dayOfMonth}-én · ${item.triggerKind == RecurrenceTriggerKind.time ? 'Időzítve' : 'Értesítésből'}\nKövetkező: ${_dateLabel(DateTime(1970).add(Duration(days: item.startLocalEpochDay)))}',
      style: const TextStyle(color: _recurringSecondary, fontSize: 12),
    ),
    isThreeLine: true,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _ruleAmount(item),
          style: const TextStyle(
            color: _recurringPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
    onTap: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UnifiedRecurringRuleDetailPage(
            repository: widget.repository,
            manualRepository: widget.manualRepository,
            categories: widget.categories,
            categoryRepository: widget.categoryRepository,
            preferencesStore: widget.preferencesStore,
            permissions: widget.permissions,
            ruleId: item.ruleId,
            onOpenLedgerEntry: widget.onOpenLedgerEntry,
          ),
        ),
      );
      _load();
    },
  );
  Widget _occurrenceList() {
    final list = (_occurrences ?? const [])
        .where(
          (item) =>
              item.occurrenceId.contains(_query) ||
              item.ruleId.contains(_query),
        )
        .toList();
    return ListView(
      key: const PageStorageKey('unified-recurring-occurrences'),
      controller: _occurrencesScroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _recurringDivider),
                _occurrenceRow(list[i]),
              ],
            ],
          ),
        ),
        if (_loadingMoreOccurrences)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _occurrenceRow(RecurrenceOccurrence item) => ListTile(
    leading: _categoryAvatar(_categoryFor(item.categoryId), 40),
    title: Text(
      _occurrenceTitle(item),
      style: const TextStyle(
        color: _recurringPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      '${_dateLabel(DateTime(1970).add(Duration(days: item.expectedLocalEpochDay)))} · ${_clock(item.expectedLocalTimeMinutes)}\n${_occurrenceStatus(item.status)}',
      style: const TextStyle(color: _recurringSecondary, fontSize: 12),
    ),
    isThreeLine: true,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          color: _recurringSecondary,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          _occurrenceAmount(item),
          style: const TextStyle(
            color: _recurringSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnifiedRecurringOccurrenceDetailPage(
          repository: widget.repository,
          manualRepository: widget.manualRepository,
          categories: widget.categories,
          occurrenceId: item.occurrenceId,
          onOpenLedgerEntry: widget.onOpenLedgerEntry,
        ),
      ),
    ),
  );
  FluviCategory? _categoryFor(String id) => widget.categories
      .cast<FluviCategory?>()
      .firstWhere((category) => category?.id == id, orElse: () => null);
  String _ruleAmount(RecurrenceRule rule) => rule.amountScaled100 == null
      ? 'Értesítésből'
      : '${rule.amountPolicy == RecurrenceAmountPolicy.estimated ? 'kb. ' : ''}${_formatMoney(rule.amountScaled100!)} Ft';
  String _occurrenceTitle(RecurrenceOccurrence occurrence) =>
      occurrence.triggerKind == RecurrenceTriggerKind.push
      ? 'Banki értesítéses alkalom'
      : 'Időzített alkalom';
}

final class UnifiedRecurringRuleDetailPage extends StatefulWidget {
  const UnifiedRecurringRuleDetailPage({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required this.ruleId,
    this.categoryRepository,
    this.preferencesStore,
    this.permissions,
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository manualRepository;
  final List<FluviCategory> categories;
  final String ruleId;
  final CategoryRepository? categoryRepository;
  final ManualTransactionEditorPreferencesStore? preferencesStore;
  final AutomationPermissionRepository? permissions;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  @override
  State<UnifiedRecurringRuleDetailPage> createState() =>
      _UnifiedRecurringRuleDetailPageState();
}

final class _UnifiedRecurringRuleDetailPageState
    extends State<UnifiedRecurringRuleDetailPage> {
  RecurrenceRule? _rule;
  List<RecurrenceOccurrence> _occurrences = const [];
  PartnerDirectoryEntry? _partner;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rule = await widget.repository.recurringRule(widget.ruleId);
      final values = await widget.repository.recurrenceOccurrences(
        ruleId: rule.ruleId,
        limit: 200,
      );
      final partner = await widget.manualRepository.getPartnerById(
        rule.partnerId,
      );
      if (mounted) {
        setState(() {
          _rule = rule;
          _occurrences = values;
          _partner = partner;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final rule = _rule;
    if (rule == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _detailHero(rule),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  _detailRows(rule),
                  const SizedBox(height: 22),
                  _nextOccurrences(),
                  const SizedBox(height: 20),
                  const Text(
                    'Előzmények',
                    style: TextStyle(
                      color: _recurringPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_occurrences
                      .where(
                        (item) =>
                            item.status == RecurrenceOccurrenceStatus.realized,
                      )
                      .isEmpty)
                    const Text(
                      'Még nincs rögzített alkalom.',
                      style: TextStyle(color: _recurringSecondary),
                    ),
                ],
              ),
            ),
            _detailFooter(rule),
          ],
        ),
      ),
    );
  }

  Widget _detailHero(RecurrenceRule rule) => DecoratedBox(
    decoration: BoxDecoration(color: _heroColor(rule.direction)),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: _recurringPrimary,
                ),
              ),
              const Expanded(
                child: Text(
                  'Ismétlődés',
                  style: TextStyle(
                    color: _recurringPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'archive') _archive(rule);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'archive', child: Text('Archiválás')),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _partner == null
                  ? _categoryAvatar(_categoryFor(rule.categoryId), 56)
                  : PartnerCategoryAvatar(
                      partner: _partner!,
                      size: 56,
                      iconSize: 26,
                      roundedSquare: true,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: const TextStyle(
                        color: _recurringPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _statusChip(rule),
                    const SizedBox(height: 8),
                    Text(
                      _ruleAmount(rule),
                      style: const TextStyle(
                        color: _recurringPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'havonta · Minden hónap ${rule.dayOfMonth}-én',
                      style: const TextStyle(color: _recurringSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _statusChip(RecurrenceRule rule) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        !rule.isActive
            ? 'Szünetel'
            : (rule.triggerKind == RecurrenceTriggerKind.push &&
                      (rule.pushProfileId == null || rule.pushRuleId == null)
                  ? 'Beállításra vár'
                  : 'Aktív'),
        style: const TextStyle(
          color: _recurringPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
  Widget _detailRows(RecurrenceRule rule) => Column(
    children: [
      _info('Partner', _partner?.displayName ?? 'Partner betöltése'),
      _info(
        'Kategória',
        _categoryFor(rule.categoryId)?.name ?? 'Kategória',
        suffix: rule.categoryAssignmentMode == 'partnerDefault'
            ? 'Partner alapértelmezése'
            : 'Egyedi kategória',
      ),
      _info(
        'Rögzítés módja',
        rule.triggerKind == RecurrenceTriggerKind.time
            ? 'Időzítve'
            : 'Banki értesítésből',
      ),
      _info(
        'Első alkalom',
        _dateLabel(DateTime(1970).add(Duration(days: rule.startLocalEpochDay))),
        trailingValue: rule.endLocalEpochDay == null
            ? 'Nincs befejezés'
            : _dateLabel(
                DateTime(1970).add(Duration(days: rule.endLocalEpochDay!)),
              ),
      ),
      if (rule.triggerKind == RecurrenceTriggerKind.push)
        _info(
          'Banki összekapcsolás',
          rule.pushProfileId == null
              ? 'Beállításra vár'
              : 'Profil és felismerési szabály kiválasztva',
        ),
      if ((rule.note ?? '').isNotEmpty) _info('Megjegyzés', rule.note!),
    ],
  );
  Widget _info(
    String label,
    String value, {
    String? suffix,
    String? trailingValue,
  }) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _recurringDivider)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _recurringSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _recurringPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (suffix != null)
                  Text(
                    suffix,
                    style: const TextStyle(
                      color: _recurringSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (trailingValue != null)
            Text(
              trailingValue,
              style: const TextStyle(
                color: _recurringPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ),
  );
  Widget _nextOccurrences() {
    final next = _occurrences
        .where(
          (item) =>
              item.status == RecurrenceOccurrenceStatus.pending ||
              item.status == RecurrenceOccurrenceStatus.review,
        )
        .take(3)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Következő alkalmak',
                style: TextStyle(
                  color: _recurringPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UnifiedRecurringManagerPage(
                    repository: widget.repository,
                    manualRepository: widget.manualRepository,
                    categories: widget.categories,
                    direction: _rule!.direction,
                    categoryRepository: widget.categoryRepository,
                    preferencesStore: widget.preferencesStore,
                    permissions: widget.permissions,
                  ),
                ),
              ),
              child: const Text('Összes'),
            ),
          ],
        ),
        for (final item in next)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(
              _dateLabel(
                DateTime(1970).add(Duration(days: item.expectedLocalEpochDay)),
              ),
            ),
            subtitle: Text(
              '${_clock(item.expectedLocalTimeMinutes)} · ${_occurrenceStatus(item.status)}',
            ),
            trailing: Text(
              _occurrenceAmount(item),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UnifiedRecurringOccurrenceDetailPage(
                  repository: widget.repository,
                  manualRepository: widget.manualRepository,
                  categories: widget.categories,
                  occurrenceId: item.occurrenceId,
                  onOpenLedgerEntry: widget.onOpenLedgerEntry,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailFooter(RecurrenceRule rule) => _RecurringCtaFooter(
    direction: rule.direction,
    actions: [
      _RecurringFooterAction(
        label: _busy
            ? 'Művelet…'
            : (rule.isActive ? 'Szüneteltetés' : 'Folytatás'),
        primary: false,
        onPressed: _busy ? null : () => _setActive(rule, !rule.isActive),
      ),
      _RecurringFooterAction(
        label: 'Szerkesztés',
        primary: true,
        onPressed: _busy
            ? null
            : () async {
                await Navigator.of(context).push(
                  creationSlideUpRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => UnifiedRecurringTransactionEditorPage.edit(
                      repository: widget.repository,
                      manualRepository: widget.manualRepository,
                      categories: widget.categories,
                      existingRule: rule,
                      categoryRepository: widget.categoryRepository,
                      preferencesStore: widget.preferencesStore,
                      permissions: widget.permissions,
                    ),
                  ),
                );
                _load();
              },
      ),
    ],
  );
  Future<void> _setActive(RecurrenceRule rule, bool active) async {
    setState(() => _busy = true);
    try {
      await widget.repository.setRecurringRuleActive(rule.ruleId, active);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive(RecurrenceRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ismétlődés archiválása?'),
        content: const Text(
          'A már rögzített tranzakciók megmaradnak, a nyitott alkalmak leállnak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archiválás'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.archiveRecurringRule(rule.ruleId);
    if (mounted) Navigator.of(context).pop(true);
  }

  FluviCategory? _categoryFor(String id) => widget.categories
      .cast<FluviCategory?>()
      .firstWhere((category) => category?.id == id, orElse: () => null);
  String _ruleAmount(RecurrenceRule rule) => rule.amountScaled100 == null
      ? 'Értesítésből'
      : '${rule.amountPolicy == RecurrenceAmountPolicy.estimated ? 'kb. ' : ''}${_formatMoney(rule.amountScaled100!)} Ft';
}

final class UnifiedRecurringOccurrenceDetailPage extends StatefulWidget {
  const UnifiedRecurringOccurrenceDetailPage({
    super.key,
    required this.repository,
    required this.manualRepository,
    required this.categories,
    required this.occurrenceId,
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final ManualTransactionRepository manualRepository;
  final List<FluviCategory> categories;
  final String occurrenceId;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;
  @override
  State<UnifiedRecurringOccurrenceDetailPage> createState() =>
      _UnifiedRecurringOccurrenceDetailPageState();
}

final class _UnifiedRecurringOccurrenceDetailPageState
    extends State<UnifiedRecurringOccurrenceDetailPage> {
  RecurrenceOccurrence? _occurrence;
  RecurrenceRule? _rule;
  PartnerDirectoryEntry? _partner;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final occurrence = await widget.repository.recurrenceOccurrence(
        widget.occurrenceId,
      );
      final values = await Future.wait<Object?>([
        widget.repository.recurringRule(occurrence.ruleId),
        widget.manualRepository.getPartnerById(occurrence.partnerId),
      ]);
      if (mounted) {
        setState(() {
          _occurrence = occurrence;
          _rule = values[0] as RecurrenceRule;
          _partner = values[1] as PartnerDirectoryEntry?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = _occurrence;
    if (occurrence == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final recorded = occurrence.status == RecurrenceOccurrenceStatus.realized;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _hero(occurrence),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  _details(occurrence),
                  const SizedBox(height: 14),
                  _ruleLink(),
                  if (!recorded)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Text(
                        'A módosítás csak ezt az alkalmat érinti.',
                        style: TextStyle(color: _recurringSecondary),
                      ),
                    ),
                ],
              ),
            ),
            _footer(occurrence, recorded),
          ],
        ),
      ),
    );
  }

  Widget _hero(RecurrenceOccurrence item) => DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xfff4f6fb)),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  item.status == RecurrenceOccurrenceStatus.pending
                      ? 'Várható alkalom'
                      : _occurrenceStatus(item.status),
                  style: const TextStyle(
                    color: _recurringPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _partner == null
                  ? _categoryAvatar(_categoryFor(item.categoryId), 56)
                  : PartnerCategoryAvatar(
                      partner: _partner!,
                      size: 56,
                      iconSize: 26,
                      roundedSquare: true,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partner?.displayName ?? 'Partner',
                      style: const TextStyle(
                        color: _recurringPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _monthLabel(
                        DateTime(
                          1970,
                        ).add(Duration(days: item.expectedLocalEpochDay)),
                      ),
                      style: const TextStyle(color: _recurringSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _occurrenceAmount(item),
                      style: const TextStyle(
                        color: _recurringPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '✦ ${_occurrenceStatus(item.status)}',
                      style: const TextStyle(color: _recurringSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _details(RecurrenceOccurrence item) => Column(
    children: [
      _two(
        'Dátum',
        _dateLabel(
          DateTime(1970).add(Duration(days: item.expectedLocalEpochDay)),
        ),
        'Idő',
        _clock(item.expectedLocalTimeMinutes),
      ),
      _info('Partner', _partner?.displayName ?? 'Partner'),
      _info('Kategória', _categoryFor(item.categoryId)?.name ?? 'Kategória'),
      if ((item.note ?? '').isNotEmpty) _info('Megjegyzés', item.note!),
      _info(
        'Rögzítés módja',
        item.triggerKind == RecurrenceTriggerKind.time
            ? 'Időzítve'
            : 'Banki értesítésből',
      ),
    ],
  );
  Widget _two(String a, String av, String b, String bv) => Row(
    children: [
      Expanded(child: _info(a, av)),
      const SizedBox(width: 18),
      Expanded(child: _info(b, bv)),
    ],
  );
  Widget _info(String label, String value) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _recurringDivider)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _recurringSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: _recurringPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _ruleLink() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _rule == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UnifiedRecurringRuleDetailPage(
                  repository: widget.repository,
                  manualRepository: widget.manualRepository,
                  categories: widget.categories,
                  ruleId: _rule!.ruleId,
                  onOpenLedgerEntry: widget.onOpenLedgerEntry,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.repeat_rounded, color: _recurringSecondary),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ehhez az ismétlődéshez tartozik',
                    style: TextStyle(color: _recurringSecondary, fontSize: 12),
                  ),
                  Text(
                    _rule == null
                        ? 'Ismétlődés'
                        : '${_rule!.name} · Havonta ${_rule!.dayOfMonth}-én',
                    style: const TextStyle(
                      color: _recurringPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
  Widget _footer(RecurrenceOccurrence occurrence, bool recorded) =>
      _RecurringCtaFooter(
        direction: _rule?.direction ?? LedgerDirection.expense,
        actions: recorded
            ? [
                _RecurringFooterAction(
                  label: 'Kapcsolódó tranzakció megnyitása',
                  primary: true,
                  onPressed: _busy ? null : () => _openLinked(occurrence),
                ),
              ]
            : [
                _RecurringFooterAction(
                  label: 'Kihagyás',
                  primary: false,
                  onPressed: _busy ? null : () => _skip(occurrence),
                ),
                _RecurringFooterAction(
                  label: 'Módosítás',
                  primary: true,
                  onPressed: _busy ? null : () => _edit(occurrence),
                ),
              ],
      );
  Future<void> _openLinked(RecurrenceOccurrence item) async {
    final entry = await widget.repository.realizedRecurrenceLedgerEntryId(
      item.occurrenceId,
    );
    if (entry != null) await widget.onOpenLedgerEntry?.call(entry);
  }

  Future<void> _skip(RecurrenceOccurrence item) async {
    setState(() => _busy = true);
    try {
      await widget.repository.skipRecurrenceOccurrence(item.occurrenceId);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(RecurrenceOccurrence item) async {
    final result = await showModalBottomSheet<_OccurrenceDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OccurrenceEditorSheet(
        occurrence: item,
        categories: widget.categories,
        repository: widget.manualRepository,
      ),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await widget.repository.updateRecurrenceOccurrence(
        occurrenceId: item.occurrenceId,
        expectedAmountScaled100: result.amount,
        expectedLocalEpochDay: result.day,
        expectedLocalTimeMinutes: result.minutes,
        partnerId: result.partner?.partnerId,
        categorySelection: result.category,
        noteChanged: result.noteChanged,
        note: result.note,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  FluviCategory? _categoryFor(String id) => widget.categories
      .cast<FluviCategory?>()
      .firstWhere((category) => category?.id == id, orElse: () => null);
}

final class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? _recurringPrimary : _recurringSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _MetadataToggle extends StatelessWidget {
  const _MetadataToggle({required this.showSurface, required this.onTap});
  final bool showSurface;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: showSurface,
    label: showSurface
        ? 'Ikonhátterek elrejtése'
        : 'Ikonhátterek megjelenítése',
    child: Tooltip(
      message: showSurface
          ? 'Ikonhátterek elrejtése'
          : 'Ikonhátterek megjelenítése',
      child: Material(
        color: Colors.white.withValues(alpha: .62),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              showSurface
                  ? Icons.dashboard_customize_outlined
                  : Icons.grid_view_rounded,
              color: _recurringPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _RecurringFooterAction {
  const _RecurringFooterAction({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;
}

/// Matches the manual editor's single-inset CTA geometry. The action widths
/// are resolved before the row is laid out, so `Center` never turns a button
/// into a full-width Wrap child and moves the next action to a new line.
final class _RecurringCtaFooter extends StatelessWidget {
  const _RecurringCtaFooter({
    required this.direction,
    required this.actions,
    this.colorProfile = FluviDirectionColorProfile.original,
  });

  final LedgerDirection direction;
  final FluviDirectionColorProfile colorProfile;
  final List<_RecurringFooterAction> actions;

  @override
  Widget build(BuildContext context) {
    final gradient = direction == LedgerDirection.income
        ? FluviDirectionColorPaletteCatalog.income(colorProfile)
        : FluviDirectionColorPaletteCatalog.expense(colorProfile);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          // SafeArea owns the bottom inset once. The controls end where it
          // begins; their external DecoratedBox shadow paints over the white
          // safe-area surface without creating a second bottom gap.
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _recurringActionWidths(
                context,
                actions,
                constraints.maxWidth,
              );
              return Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0) const SizedBox(width: 12),
                      SizedBox(
                        width: widths[index],
                        child: _RecurringActionButton(
                          key: ValueKey<String>(
                            'unified-recurring-cta-${actions[index].primary ? 'primary' : 'secondary'}',
                          ),
                          label: actions[index].label,
                          primary: actions[index].primary,
                          gradient: actions[index].primary ? gradient : null,
                          onPressed: actions[index].onPressed,
                        ),
                      ),
                    ],
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

List<double> _recurringActionWidths(
  BuildContext context,
  List<_RecurringFooterAction> actions,
  double maxWidth,
) {
  final desired = [
    for (final action in actions)
      _recurringActionWidth(context, action.label, action.primary ? 120 : 104),
  ];
  if (desired.length < 2) {
    return [math.min(desired.single, maxWidth)];
  }
  const gap = 12.0;
  final available = math.max(0, maxWidth - gap);
  final total = desired.fold<double>(0, (sum, value) => sum + value);
  if (total <= available) return desired;

  // A phone-width footer still stays one compact line. At extreme text
  // scaling the labels scale down inside their explicit slots rather than
  // creating a second action row or clipping the footer shadow.
  final secondary = math
      .min(desired.first, math.max(88, available * .44))
      .toDouble();
  final primary = math.max(0, available - secondary).toDouble();
  return [secondary, primary];
}

double _recurringActionWidth(
  BuildContext context,
  String label,
  double minimum,
) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: FluviVisualTokens.actionLabelTextStyle),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return math.max(minimum, painter.width + 28);
}

final class _RecurringActionButton extends StatelessWidget {
  const _RecurringActionButton({
    super.key,
    required this.label,
    required this.primary,
    required this.onPressed,
    this.gradient,
  });
  final String label;
  final bool primary;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: depth.outerShadows,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
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
              boxShadow: depth.innerShadows,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: FluviVisualTokens.actionLabelTextStyle.copyWith(
                      color: primary
                          ? Colors.white
                          : FluviVisualTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TimingDraft {
  const _TimingDraft(this.first, this.time, this.end);
  final DateTime first;
  final TimeOfDay time;
  final DateTime? end;
}

final class _TimingSheet extends StatefulWidget {
  const _TimingSheet({required this.initial});
  final _TimingDraft initial;
  @override
  State<_TimingSheet> createState() => _TimingSheetState();
}

final class _TimingSheetState extends State<_TimingSheet> {
  late DateTime _first;
  late TimeOfDay _time;
  DateTime? _end;
  @override
  void initState() {
    super.initState();
    _first = widget.initial.first;
    _time = widget.initial.time;
    _end = widget.initial.end;
  }

  @override
  Widget build(BuildContext context) => ChildEditorSheetScaffold(
    title: 'Ismétlődés beállítása',
    applying: false,
    onCancel: () => Navigator.pop(context),
    onApply: () => Navigator.pop(context, _TimingDraft(_first, _time, _end)),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gyakoriság',
          style: TextStyle(
            color: _recurringSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Havonta',
          style: TextStyle(
            color: _recurringPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Divider(color: _recurringDivider),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hónap napja'),
          trailing: Text(
            '${_first.day}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          onTap: _pickFirst,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Első alkalom'),
          trailing: Text(
            _dateLabel(_first),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          onTap: _pickFirst,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Időpont'),
          trailing: Text(
            _time.format(context),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          onTap: _pickTime,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Befejezés'),
          subtitle: Text(_end == null ? 'Nincs' : _dateLabel(_end!)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _pickEnd,
        ),
        const SizedBox(height: 8),
        Text(
          'Minden hónap ${_first.day}-én, ${_time.format(context)}-kor. Rövidebb hónapban az utolsó napon.',
          style: const TextStyle(color: _recurringSecondary, fontSize: 12),
        ),
      ],
    ),
  );
  Future<void> _pickFirst() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _first,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _first = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }

  Future<void> _pickEnd() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _end ?? _first,
      firstDate: _first,
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _end = value);
  }
}

final class _AmountPolicySheet extends StatefulWidget {
  const _AmountPolicySheet({required this.initial, required this.trigger});
  final RecurrenceAmountPolicy initial;
  final RecurrenceTriggerKind trigger;
  @override
  State<_AmountPolicySheet> createState() => _AmountPolicySheetState();
}

final class _AmountPolicySheetState extends State<_AmountPolicySheet> {
  late RecurrenceAmountPolicy _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.trigger == RecurrenceTriggerKind.time
        ? [RecurrenceAmountPolicy.fixed, RecurrenceAmountPolicy.estimated]
        : RecurrenceAmountPolicy.values;
    return ChildEditorSheetScaffold(
      title: 'Összeg jellege',
      applying: false,
      onCancel: () => Navigator.pop(context),
      onApply: () => Navigator.pop(context, _value),
      body: RadioGroup<RecurrenceAmountPolicy>(
        groupValue: _value,
        onChanged: (value) {
          if (value != null) setState(() => _value = value);
        },
        child: Column(
          children: [
            for (final item in allowed)
              RadioListTile<RecurrenceAmountPolicy>(
                contentPadding: EdgeInsets.zero,
                value: item,
                title: Text(switch (item) {
                  RecurrenceAmountPolicy.fixed => 'Fix összeg',
                  RecurrenceAmountPolicy.estimated => 'Becsült összeg',
                  RecurrenceAmountPolicy.unknown => 'Értesítésből',
                }),
                subtitle: Text(switch (item) {
                  RecurrenceAmountPolicy.fixed =>
                    'A megadott összeget használja.',
                  RecurrenceAmountPolicy.estimated =>
                    'A tényleges összeget az értesítés hozza.',
                  RecurrenceAmountPolicy.unknown =>
                    'Nincs előre ismert összeg.',
                }),
              ),
          ],
        ),
      ),
    );
  }
}

final class _BankLinkDraft {
  const _BankLinkDraft(
    this.profileId,
    this.ruleId,
    this.toleranceScaled100,
    this.dayWindow,
  );
  final String? profileId, ruleId;
  final int toleranceScaled100, dayWindow;
}

final class _BankLinkSheet extends StatefulWidget {
  const _BankLinkSheet({
    required this.profiles,
    required this.rules,
    required this.direction,
    required this.initial,
    required this.knownAmount,
    required this.onProfileChanged,
    required this.onCreateProfile,
  });
  final List<PushProfile> profiles;
  final List<PushRule> rules;
  final LedgerDirection direction;
  final _BankLinkDraft initial;
  final bool knownAmount;
  final Future<List<PushRule>> Function(String) onProfileChanged;
  final Future<List<PushProfile>> Function() onCreateProfile;
  @override
  State<_BankLinkSheet> createState() => _BankLinkSheetState();
}

final class _BankLinkSheetState extends State<_BankLinkSheet> {
  late String? _profileId;
  late String? _ruleId;
  late int _dayWindow;
  late final TextEditingController _tolerance;
  late List<PushProfile> _profiles;
  List<PushRule> _rules = const [];
  @override
  void initState() {
    super.initState();
    _profileId = widget.initial.profileId;
    _ruleId = widget.initial.ruleId;
    _dayWindow = widget.initial.dayWindow;
    _tolerance = TextEditingController(
      text: _formatMoney(widget.initial.toleranceScaled100),
    );
    _profiles = widget.profiles;
    _rules = widget.rules;
  }

  @override
  void dispose() {
    _tolerance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChildEditorSheetScaffold(
    title: 'Banki értesítés összekapcsolása',
    applying: false,
    onCancel: () => Navigator.pop(context),
    onApply: () => Navigator.pop(
      context,
      _BankLinkDraft(
        _profileId,
        _ruleId,
        widget.knownAmount ? (_parseMoney(_tolerance.text) ?? 0) : 0,
        _dayWindow,
      ),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey<String?>('bank-profile-$_profileId'),
          initialValue: _profileId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Profil'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Beállításra vár')),
            ..._profiles.map(
              (item) => DropdownMenuItem(
                value: item.profileId,
                child: Text(item.displayName),
              ),
            ),
          ],
          onChanged: (value) async {
            setState(() {
              _profileId = value;
              _ruleId = null;
              _rules = const [];
            });
            if (value != null) {
              final rules = await widget.onProfileChanged(value);
              if (mounted && _profileId == value) {
                setState(() => _rules = rules);
              }
            }
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final profiles = await widget.onCreateProfile();
              if (mounted) setState(() => _profiles = profiles);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Új profil létrehozása'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>('bank-rule-$_ruleId'),
          initialValue: _ruleId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Felismerési szabály'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Beállításra vár')),
            ..._rules
                .where((item) => item.direction == widget.direction)
                .map(
                  (item) => DropdownMenuItem(
                    value: item.ruleId,
                    child: Text(item.name),
                  ),
                ),
          ],
          onChanged: _profileId == null
              ? null
              : (value) => setState(() => _ruleId = value),
        ),
        if (widget.knownAmount) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _tolerance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Megengedett összegeltérés (Ft)',
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey<String>('bank-window-$_dayWindow'),
          initialValue: _dayWindow,
          decoration: const InputDecoration(
            labelText: 'Megengedett napeltérés',
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Csak aznap')),
            DropdownMenuItem(value: 1, child: Text('± 1 nap')),
            DropdownMenuItem(value: 2, child: Text('± 2 nap')),
          ],
          onChanged: (value) => setState(() => _dayWindow = value ?? 0),
        ),
        const SizedBox(height: 12),
        const Text(
          'Összekapcsolás nélkül a szabály Beállításra vár állapotban marad.',
          style: TextStyle(color: _recurringSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

final class _OccurrenceDraft {
  const _OccurrenceDraft({
    required this.amount,
    required this.day,
    required this.minutes,
    required this.partner,
    required this.category,
    required this.noteChanged,
    required this.note,
  });
  final int? amount;
  final int? day;
  final int? minutes;
  final ExistingManualPartner? partner;
  final ManualCategorySelection? category;
  final bool noteChanged;
  final String? note;
}

final class _OccurrenceEditorSheet extends StatefulWidget {
  const _OccurrenceEditorSheet({
    required this.occurrence,
    required this.categories,
    required this.repository,
  });
  final RecurrenceOccurrence occurrence;
  final List<FluviCategory> categories;
  final ManualTransactionRepository repository;
  @override
  State<_OccurrenceEditorSheet> createState() => _OccurrenceEditorSheetState();
}

final class _OccurrenceEditorSheetState extends State<_OccurrenceEditorSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  late TimeOfDay _time;
  PartnerDirectoryEntry? _partner;
  late ManualCategorySelection _category;
  bool _partnerExpanded = false;
  bool _categoryExpanded = false;
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.occurrence.expectedAmountScaled100 == null
          ? ''
          : _formatMoney(widget.occurrence.expectedAmountScaled100!),
    );
    _note = TextEditingController(text: widget.occurrence.note ?? '');
    _date = DateTime(
      1970,
    ).add(Duration(days: widget.occurrence.expectedLocalEpochDay));
    _time = TimeOfDay(
      hour: widget.occurrence.expectedLocalTimeMinutes ~/ 60,
      minute: widget.occurrence.expectedLocalTimeMinutes % 60,
    );
    _category =
        widget.occurrence.categoryAssignmentMode ==
            ManualCategoryAssignmentMode.entryOverride
        ? ManualCategorySelection.entryOverride(widget.occurrence.categoryId)
        : const ManualCategorySelection.partnerDefault();
    unawaited(_loadPartner());
  }

  Future<void> _loadPartner() async {
    try {
      final partner = await widget.repository.getPartnerById(
        widget.occurrence.partnerId,
      );
      if (mounted) setState(() => _partner = partner);
    } catch (_) {
      // The existing occurrence stays editable even if a historical partner
      // has since been removed from the directory.
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChildEditorSheetScaffold(
    title: 'Alkalom módosítása',
    applying: false,
    onCancel: () => Navigator.pop(context),
    onApply: () => Navigator.pop(
      context,
      _OccurrenceDraft(
        amount: _parseMoney(_amount.text),
        day: _date.difference(DateTime(1970)).inDays,
        minutes: _time.hour * 60 + _time.minute,
        partner: _partner == null
            ? null
            : ExistingManualPartner(
                _partner!.partnerId,
                directoryEntry: _partner!,
              ),
        category: _category,
        noteChanged: _note.text != (widget.occurrence.note ?? ''),
        note: _note.text,
      ),
    ),
    body: Column(
      children: [
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Összeg (Ft)'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dátum'),
          trailing: Text(_dateLabel(_date)),
          onTap: _pickDate,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Idő'),
          trailing: Text(_time.format(context)),
          onTap: _pickTime,
        ),
        PartnerDropdown(
          repository: widget.repository,
          categories: widget.categories,
          selectedPartnerId: _partner?.partnerId ?? widget.occurrence.partnerId,
          selectedPartner: _partner,
          expanded: _partnerExpanded,
          onExpandedChanged: (expanded) => setState(() {
            _partnerExpanded = expanded;
            if (expanded) _categoryExpanded = false;
          }),
          onSelected: (selection) {
            if (selection case ExistingManualPartner(:final directoryEntry)) {
              setState(() {
                _partner = directoryEntry;
                _partnerExpanded = false;
                _category = const ManualCategorySelection.partnerDefault();
              });
            }
          },
        ),
        CategoryDropdown(
          categories: widget.categories,
          selectedCategoryId:
              _category.mode == ManualCategoryAssignmentMode.entryOverride
              ? _category.categoryId
              : _partner?.defaultCategoryId ?? widget.occurrence.categoryId,
          inline: true,
          expanded: _categoryExpanded,
          onExpandedChanged: (expanded) => setState(() {
            _categoryExpanded = expanded;
            if (expanded) _partnerExpanded = false;
          }),
          onSelected: (categoryId) => setState(() {
            _category = ManualCategorySelection.entryOverride(categoryId);
            _categoryExpanded = false;
          }),
        ),
        TextField(
          controller: _note,
          minLines: 1,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Megjegyzés'),
        ),
      ],
    ),
  );
  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }
}

Widget _categoryAvatar(FluviCategory? category, double size) => category == null
    ? const ManualEditorIconSurface(
        icon: Icons.category_outlined,
        background: _recurringNeutral,
      )
    : CategoryVisualBadge(
        colorHandle: CategoryColorCatalog.handleOf(category.colorId),
        iconHandle: CategoryIconCatalog.handleOf(category.iconId),
        size: size,
        iconSize: size * .43,
      );
Color _heroColor(LedgerDirection direction) =>
    direction == LedgerDirection.income
    ? const Color(0xffe8f8f1)
    : const Color(0xfffff0e9);
int? _parseMoney(String value) {
  final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final parsed = double.tryParse(normalized);
  return parsed == null ? null : (parsed * 100).round();
}

String _formatMoney(int amount) {
  final value = amount / 100;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
}

String _dateLabel(DateTime date) =>
    '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
String _shortDate(DateTime date) {
  const months = [
    'JAN.',
    'FEBR.',
    'MÁRC.',
    'ÁPR.',
    'MÁJ.',
    'JÚN.',
    'JÚL.',
    'AUG.',
    'SZEPT.',
    'OKT.',
    'NOV.',
    'DEC.',
  ];
  return '${months[date.month - 1]} ${date.day}.';
}

String _monthLabel(DateTime date) {
  const months = [
    'január',
    'február',
    'március',
    'április',
    'május',
    'június',
    'július',
    'augusztus',
    'szeptember',
    'október',
    'november',
    'december',
  ];
  return '${date.year}. ${months[date.month - 1]}';
}

String _clock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
String _occurrenceAmount(RecurrenceOccurrence item) =>
    item.expectedAmountScaled100 == null
    ? 'Értesítésből'
    : '${item.amountPolicy == RecurrenceAmountPolicy.estimated ? 'kb. ' : ''}${_formatMoney(item.expectedAmountScaled100!)} Ft';
String _occurrenceStatus(RecurrenceOccurrenceStatus status) => switch (status) {
  RecurrenceOccurrenceStatus.pending => 'Várható',
  RecurrenceOccurrenceStatus.review => 'Ellenőrzést igényel',
  RecurrenceOccurrenceStatus.realized => 'Rögzítve',
  RecurrenceOccurrenceStatus.skipped => 'Kihagyva',
  RecurrenceOccurrenceStatus.cancelled => 'Leállítva',
  RecurrenceOccurrenceStatus.voided => 'Érvénytelenítve',
};

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
