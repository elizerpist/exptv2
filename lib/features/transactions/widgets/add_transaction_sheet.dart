import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/keyboard/keyboard_inset_follower.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../../settings/theme/expense_theme.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../state/transaction_store.dart';
import 'amount_field.dart';
import 'category_selector_field.dart';
import 'category_scroll_picker.dart';
import 'date_time_fields.dart';
import 'slide_up_menu_card.dart';
import 'slide_up_panel_metrics.dart';
import 'themed_pill_field.dart';
import 'transaction_menu_metrics.dart';

const _transactionFormFieldGap = 12.0;

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.store,
    this.initialTransaction,
    this.onClose,
    this.openRequestedAt,
    this.visible = true,
    this.expenseTheme,
    this.resolveNotificationEventId,
    this.onOpenNotificationEvent,
    this.nativeHostMode = false,
    this.onSaved,
    this.reloadAfterSave = true,
  });

  final TransactionStore store;
  final TransactionRecord? initialTransaction;
  final VoidCallback? onClose;
  final DateTime? openRequestedAt;
  final bool visible;
  final ExpenseTheme? expenseTheme;
  final Future<int?> Function(int transactionId)? resolveNotificationEventId;
  final Future<void> Function(int eventId)? onOpenNotificationEvent;
  final bool nativeHostMode;
  final FutureOr<void> Function()? onSaved;
  final bool reloadAfterSave;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _categoryPickerBoundaryKey = GlobalKey();
  final _dateFieldKey = GlobalKey();
  final _timeFieldKey = GlobalKey();
  final _saveFooterProbeKey = GlobalKey();
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _dateFocus = FocusNode();
  final _timeFocus = FocusNode();
  TransactionCategory? _category;
  String? _error;
  var _saving = false;
  var _categoryPickerOpen = false;
  bool? _lastLoggedPickerOpen;
  int? _lastLoggedCategoryCount;
  double? _lastLoggedPanelHeight;
  double? _lastLoggedContentHeight;
  double? _lastLoggedKeyboardInset;
  String? _lastLoggedKeyboardSource;
  double? _lastLoggedActionBottomInset;
  String? _lastLayoutProbeSignature;
  double? _stablePanelHeight;
  String? _stablePanelSignature;
  String? _focusedField;
  DateTime? _focusStartedAt;
  var _firstBuildLogged = false;
  int? _linkedNotificationEventId;
  var _notificationLinkLoading = false;

  bool get _editing => widget.initialTransaction != null;
  String get _hostLogPrefix =>
      widget.nativeHostMode ? '[NativeImeSheet]' : '[SlideUpMenu]';

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => _handleFocusChanged('name', _nameFocus));
    _amountFocus.addListener(() => _handleFocusChanged('amount', _amountFocus));
    _dateFocus.addListener(() => _handleFocusChanged('date', _dateFocus));
    _timeFocus.addListener(() => _handleFocusChanged('time', _timeFocus));
    _resetFields();
    unawaited(_resolveNotificationLink());
    if (widget.visible) _logSheetInit();
  }

  @override
  void didUpdateWidget(AddTransactionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTransaction?.id != widget.initialTransaction?.id ||
        oldWidget.openRequestedAt != widget.openRequestedAt) {
      _resetFields();
      _firstBuildLogged = false;
      _lastLoggedPickerOpen = null;
      _lastLoggedCategoryCount = null;
      _lastLoggedPanelHeight = null;
      _lastLoggedContentHeight = null;
      _lastLoggedKeyboardInset = null;
      _lastLoggedKeyboardSource = null;
      _lastLoggedActionBottomInset = null;
      _lastLayoutProbeSignature = null;
      _stablePanelHeight = null;
      _stablePanelSignature = null;
      _linkedNotificationEventId = null;
      unawaited(_resolveNotificationLink());
    }
    if (!oldWidget.visible && widget.visible) {
      _logSheetInit();
    }
  }

  void _logSheetInit() {
    final label = _editing ? 'EditTransaction' : 'AddTransaction';
    DebugConsole.log(
      '$_hostLogPrefix $label sheet init '
      'requestElapsed=${_elapsedMs(widget.openRequestedAt)}ms',
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _amountFocus.dispose();
    _dateFocus.dispose();
    _timeFocus.dispose();
    _name.dispose();
    _amount.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final type = widget.initialTransaction?.type ?? widget.store.activeType;
        final debugLabel = _editing ? 'EditTransaction' : 'AddTransaction';
        final expenseTheme =
            widget.expenseTheme ??
            ExpenseTheme.fromSettings(AppThemeSettings.defaults());
        final categories = widget.store.categories
            .where((category) => category.normalizedType == type)
            .toList();
        _category = _resolvedCategory(categories);
        final panelHeight = _panelHeightFor(context);
        if (widget.visible) {
          _logFirstBuild(panelHeight, categories.length);
          _logBuildMetrics(panelHeight, categories.length);
        }

        final content = SafeArea(
          top: false,
          bottom: false,
          child: Builder(
            builder: (context) {
              final actionBottomInset =
                  MediaQuery.viewPaddingOf(context).bottom + 8;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SlideUpPanelMetrics.horizontalInset,
                        14,
                        SlideUpPanelMetrics.horizontalInset,
                        0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (widget.visible) {
                            final keyboard = KeyboardInsetReader.snapshotOf(
                              context,
                            );
                            _logContentMetrics(
                              availableHeight: constraints.maxHeight,
                              panelHeight: panelHeight,
                              keyboardInset: keyboard.inset,
                              keyboardSource: keyboard.source,
                              keyboardPhase: keyboard.phase,
                              keyboardSequence: keyboard.sequence,
                              keyboardAgeMs: keyboard.ageMs,
                              keyboardFallbackInset: keyboard.fallbackInset,
                              actionBottomInset: actionBottomInset,
                            );
                          }
                          return SizedBox.expand(
                            key: const ValueKey(
                              'transaction-editor-scroll-body',
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray200,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _title(type),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray800,
                                  ),
                                ),
                                if (_editing &&
                                    _linkedNotificationEventId != null) ...[
                                  const SizedBox(height: 6),
                                  Center(
                                    child: TextButton.icon(
                                      key: const ValueKey(
                                        'transaction-open-notification-event',
                                      ),
                                      onPressed: _saving
                                          ? null
                                          : _openLinkedNotificationEvent,
                                      icon: const Icon(
                                        Icons.notifications_active_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Ugrás az üzenethez'),
                                    ),
                                  ),
                                ] else if (_editing &&
                                    _notificationLinkLoading) ...[
                                  const SizedBox(height: 6),
                                  const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                ThemedPillField(
                                  debugLabel: '$debugLabel.name',
                                  controller: _name,
                                  focusNode: _nameFocus,
                                  label: 'Tranzakció neve',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  surfaceColor: expenseTheme.fieldSurface,
                                  surfaceStyle:
                                      expenseTheme.contentSurfaceStyle,
                                ),
                                const SizedBox(
                                  height: _transactionFormFieldGap,
                                ),
                                AmountField(
                                  controller: _amount,
                                  focusNode: _amountFocus,
                                  debugLabel: '$debugLabel.amount',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                  surfaceColor: expenseTheme.fieldSurface,
                                  surfaceStyle:
                                      expenseTheme.contentSurfaceStyle,
                                ),
                                const SizedBox(
                                  height: _transactionFormFieldGap,
                                ),
                                CategorySelectorField(
                                  selected: _category,
                                  onTap: _openCategoryPicker,
                                  surfaceColor: expenseTheme.fieldSurface,
                                  surfaceStyle:
                                      expenseTheme.contentSurfaceStyle,
                                ),
                                if (_categoryPickerOpen) ...[
                                  const SizedBox(height: 8),
                                  CategoryScrollPicker(
                                    key: _categoryPickerBoundaryKey,
                                    keyPrefix: 'transaction-category',
                                    categories: categories,
                                    selected: _category,
                                    onSelected: _selectCategory,
                                  ),
                                ],
                                if (_categoryPickerOpen)
                                  const Spacer()
                                else
                                  const SizedBox(
                                    height: _transactionFormFieldGap,
                                  ),
                                DateTimeFields(
                                  dateFieldKey: _dateFieldKey,
                                  timeFieldKey: _timeFieldKey,
                                  dateController: _date,
                                  timeController: _time,
                                  onPickDate: _pickDate,
                                  onPickTime: _pickTime,
                                  dateFocusNode: _dateFocus,
                                  timeFocusNode: _timeFocus,
                                  debugLabelPrefix: debugLabel,
                                  surfaceColor: expenseTheme.fieldSurface,
                                  surfaceStyle:
                                      expenseTheme.contentSurfaceStyle,
                                ),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.expense,
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
                  const SizedBox(height: _transactionFormFieldGap),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      SlideUpPanelMetrics.horizontalInset,
                      0,
                      SlideUpPanelMetrics.horizontalInset,
                      actionBottomInset,
                    ),
                    child: KeyedSubtree(
                      key: _saveFooterProbeKey,
                      child: SizedBox(
                        key: const ValueKey('transaction-save-footer'),
                        width: double.infinity,
                        child: ExpenseSurfaceButton(
                          buttonKey: const ValueKey('transaction-save-button'),
                          label: 'Mentés',
                          onPressed: _saving ? null : _save,
                          saving: _saving,
                          surfaceStyle: expenseTheme.buttonSurfaceStyle,
                          color: expenseTheme.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        if (widget.nativeHostMode) {
          return Material(
            color: Colors.transparent,
            child: Container(
              key: const ValueKey('native-transaction-editor-card'),
              height: panelHeight,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: content,
            ),
          );
        }

        return SlideUpMenuCard(
          cardKey: const ValueKey('transaction-editor-card'),
          debugLabel: _editing ? 'EditTransaction' : 'AddTransaction',
          panelHeight: panelHeight,
          visible: widget.visible,
          openRequestedAt: widget.openRequestedAt,
          deferEntryAnimation: true,
          focusVeilPassthroughTop: TransactionMenuMetrics.overlayTop,
          dragExclusionKeys: _categoryPickerOpen
              ? [_categoryPickerBoundaryKey]
              : const <GlobalKey>[],
          onDismissed: _close,
          child: content,
        );
      },
    );
  }

  double _panelHeightFor(BuildContext context) {
    final baseHeight = SlideUpPanelMetrics.transactionHeight(
      context,
      pickerOpen: _categoryPickerOpen,
    );
    final hasNotificationLinkRow =
        _notificationLinkLoading || _linkedNotificationEventId != null;
    final requestedHeight = _categoryPickerOpen || !hasNotificationLinkRow
        ? baseHeight
        : (baseHeight + 22.0).clamp(0.0, MediaQuery.sizeOf(context).height);
    final signature = [
      _categoryPickerOpen,
      hasNotificationLinkRow,
      MediaQuery.sizeOf(context).width.toStringAsFixed(1),
    ].join('|');
    final keyboardInset = KeyboardInsetReader.rawOf(context);
    if (_stablePanelHeight == null ||
        _stablePanelSignature != signature ||
        keyboardInset <= 0.5) {
      _stablePanelHeight = requestedHeight;
      _stablePanelSignature = signature;
    }
    return _stablePanelHeight!;
  }

  void _logFirstBuild(double panelHeight, int categoryCount) {
    if (_firstBuildLogged) return;
    _firstBuildLogged = true;
    final label = _editing ? 'EditTransaction' : 'AddTransaction';
    final requestElapsed = _elapsedMs(widget.openRequestedAt);
    DebugConsole.log(
      '$_hostLogPrefix $label first build '
      'requestElapsed=${requestElapsed}ms picker=$_categoryPickerOpen '
      'categories=$categoryCount panel=${panelHeight.toStringAsFixed(1)}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '$_hostLogPrefix $label first frame '
        'requestElapsed=${_elapsedMs(widget.openRequestedAt)}ms',
      );
    });
  }

  void _logBuildMetrics(double panelHeight, int categoryCount) {
    if (_lastLoggedPickerOpen == _categoryPickerOpen &&
        _lastLoggedCategoryCount == categoryCount &&
        _lastLoggedPanelHeight == panelHeight) {
      return;
    }
    _lastLoggedPickerOpen = _categoryPickerOpen;
    _lastLoggedCategoryCount = categoryCount;
    _lastLoggedPanelHeight = panelHeight;
    final editing = _editing;
    final pickerOpen = _categoryPickerOpen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '$_hostLogPrefix ${editing ? 'EditTransaction' : 'AddTransaction'} sheet build '
        'editing=$editing picker=$pickerOpen categories=$categoryCount '
        'requestedPanel=${panelHeight.toStringAsFixed(1)}',
      );
    });
  }

  void _handleFocusChanged(String field, FocusNode node) {
    final label = _editing ? 'EditTransaction' : 'AddTransaction';
    if (node.hasFocus) {
      _focusedField = field;
      _focusStartedAt = DateTime.now();
      DebugConsole.log('[Perf] $label focus field=$field active=true');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _focusedField != field) return;
        DebugConsole.log(
          '[Perf] $label focus frame field=$field elapsed=${_elapsedMs(_focusStartedAt)}ms',
        );
      });
      return;
    }
    if (_focusedField == field) {
      DebugConsole.log(
        '[Perf] $label focus field=$field active=false elapsed=${_elapsedMs(_focusStartedAt)}ms',
      );
      _focusedField = null;
      _focusStartedAt = null;
    }
  }

  void _logContentMetrics({
    required double availableHeight,
    required double panelHeight,
    required double keyboardInset,
    required String keyboardSource,
    required String? keyboardPhase,
    required int? keyboardSequence,
    required int? keyboardAgeMs,
    required double keyboardFallbackInset,
    required double actionBottomInset,
  }) {
    if (_lastLoggedContentHeight == availableHeight &&
        _lastLoggedKeyboardInset == keyboardInset &&
        _lastLoggedKeyboardSource == keyboardSource &&
        _lastLoggedActionBottomInset == actionBottomInset) {
      return;
    }
    _lastLoggedContentHeight = availableHeight;
    _lastLoggedKeyboardInset = keyboardInset;
    _lastLoggedKeyboardSource = keyboardSource;
    _lastLoggedActionBottomInset = actionBottomInset;
    final editing = _editing;
    final pickerOpen = _categoryPickerOpen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[Perf] ${editing ? 'EditTransaction' : 'AddTransaction'} layout '
        'panel=${panelHeight.toStringAsFixed(1)} '
        'content=${availableHeight.toStringAsFixed(1)} '
        'keyboard=${keyboardInset.toStringAsFixed(1)} picker=$pickerOpen '
        'actionBottom=${actionBottomInset.toStringAsFixed(1)} '
        'source=$keyboardSource '
        'phase=${keyboardPhase ?? 'none'} '
        'seq=${keyboardSequence?.toString() ?? 'n/a'} '
        'ageMs=${keyboardAgeMs?.toString() ?? 'n/a'} '
        'fallback=${keyboardFallbackInset.toStringAsFixed(1)} '
        'focus=${_focusedField ?? 'none'} focusElapsed=${_elapsedMs(_focusStartedAt)}ms',
      );
      _logLayoutProbe(
        panelHeight: panelHeight,
        availableHeight: availableHeight,
        keyboardInset: keyboardInset,
        keyboardSource: keyboardSource,
        keyboardPhase: keyboardPhase,
        keyboardSequence: keyboardSequence,
        keyboardAgeMs: keyboardAgeMs,
        keyboardFallbackInset: keyboardFallbackInset,
        actionBottomInset: actionBottomInset,
      );
    });
  }

  void _logLayoutProbe({
    required double panelHeight,
    required double availableHeight,
    required double keyboardInset,
    required String keyboardSource,
    required String? keyboardPhase,
    required int? keyboardSequence,
    required int? keyboardAgeMs,
    required double keyboardFallbackInset,
    required double actionBottomInset,
  }) {
    final dateBox = _renderBoxFor(_dateFieldKey);
    final timeBox = _renderBoxFor(_timeFieldKey);
    final saveBox = _renderBoxFor(_saveFooterProbeKey);
    if (dateBox == null || timeBox == null || saveBox == null) return;
    final dateRect = dateBox.localToGlobal(Offset.zero) & dateBox.size;
    final timeRect = timeBox.localToGlobal(Offset.zero) & timeBox.size;
    final saveRect = saveBox.localToGlobal(Offset.zero) & saveBox.size;
    final dateTimeBottom = dateRect.bottom > timeRect.bottom
        ? dateRect.bottom
        : timeRect.bottom;
    final saveGap = saveRect.top - dateTimeBottom;
    final signature = [
      panelHeight.toStringAsFixed(1),
      availableHeight.toStringAsFixed(1),
      keyboardInset.toStringAsFixed(1),
      actionBottomInset.toStringAsFixed(1),
      keyboardSource,
      dateTimeBottom.toStringAsFixed(1),
      saveRect.top.toStringAsFixed(1),
      saveGap.toStringAsFixed(1),
    ].join('|');
    if (_lastLayoutProbeSignature == signature) return;
    _lastLayoutProbeSignature = signature;
    DebugConsole.log(
      '[Perf] ${_editing ? 'EditTransaction' : 'AddTransaction'} layout-probe '
      'panel=${panelHeight.toStringAsFixed(1)} '
      'content=${availableHeight.toStringAsFixed(1)} '
      'keyboard=${keyboardInset.toStringAsFixed(1)} '
      'actionBottom=${actionBottomInset.toStringAsFixed(1)} '
      'source=$keyboardSource '
      'phase=${keyboardPhase ?? 'none'} '
      'seq=${keyboardSequence?.toString() ?? 'n/a'} '
      'ageMs=${keyboardAgeMs?.toString() ?? 'n/a'} '
      'fallback=${keyboardFallbackInset.toStringAsFixed(1)} '
      'dateBottom=${dateRect.bottom.toStringAsFixed(1)} '
      'timeBottom=${timeRect.bottom.toStringAsFixed(1)} '
      'saveTop=${saveRect.top.toStringAsFixed(1)} '
      'saveGap=${saveGap.toStringAsFixed(1)} '
      'stablePanel=${_stablePanelHeight?.toStringAsFixed(1) ?? 'n/a'} '
      'focus=${_focusedField ?? 'none'}',
    );
  }

  RenderBox? _renderBoxFor(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject;
  }

  Future<void> _resolveNotificationLink() async {
    final transaction = widget.initialTransaction;
    final resolver = widget.resolveNotificationEventId;
    if (transaction == null || resolver == null) {
      _linkedNotificationEventId = null;
      _notificationLinkLoading = false;
      return;
    }
    if (mounted) setState(() => _notificationLinkLoading = true);
    try {
      final eventId = await resolver(transaction.id);
      if (!mounted || widget.initialTransaction?.id != transaction.id) return;
      setState(() {
        _linkedNotificationEventId = eventId;
        _notificationLinkLoading = false;
      });
      DebugConsole.log(
        '[PushLink] transaction=${transaction.id} notificationEvent=$eventId',
      );
    } catch (error) {
      if (!mounted || widget.initialTransaction?.id != transaction.id) return;
      setState(() {
        _linkedNotificationEventId = null;
        _notificationLinkLoading = false;
      });
      DebugConsole.log(
        '[PushLink] transaction=${transaction.id} notification lookup failed: $error',
      );
    }
  }

  Future<void> _openLinkedNotificationEvent() async {
    final eventId = _linkedNotificationEventId;
    final opener = widget.onOpenNotificationEvent;
    if (eventId == null || opener == null) return;
    _close();
    await opener(eventId);
  }

  void _resetFields() {
    final transaction = widget.initialTransaction;
    if (transaction == null) {
      final now = DateTime.now();
      _name.clear();
      _amount.clear();
      _date.text = _formatDate(now);
      _time.text = _formatTime(now);
      _category = _firstActiveCategory();
    } else {
      _name.text = transaction.displayMerchant;
      _amount.text = transaction.amount.abs().toStringAsFixed(0);
      _date.text = transaction.normalizedDate;
      _time.text = transaction.displayTime;
      _category = _categoryById(transaction.transactionCategoryID);
    }
    _error = null;
    _saving = false;
    _categoryPickerOpen = false;
  }

  String _title(TransactionType type) {
    if (_editing) {
      return type == TransactionType.income
          ? 'Bevételi tranzakció módosítása'
          : 'Kiadási tranzakció módosítása';
    }
    return type == TransactionType.income
        ? 'Új bevételi tranzakció'
        : 'Új kiadási tranzakció';
  }

  TransactionCategory? _firstActiveCategory() {
    final categories = widget.store.activeCategories;
    return categories.isEmpty ? null : categories.first;
  }

  TransactionCategory? _categoryById(int? id) {
    if (id == null) return null;
    for (final category in widget.store.categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  TransactionCategory? _resolvedCategory(List<TransactionCategory> categories) {
    if (categories.isEmpty) return null;
    final selectedId = _category?.transactionCategoryID;
    if (selectedId != null) {
      for (final category in categories) {
        if (category.transactionCategoryID == selectedId) return category;
      }
    }
    return categories.first;
  }

  void _openCategoryPicker() {
    final next = !_categoryPickerOpen;
    DebugConsole.log(
      '$_hostLogPrefix ${_editing ? 'EditTransaction' : 'AddTransaction'} '
      'category inline ${next ? 'open' : 'close'} requested',
    );
    setState(() {
      _categoryPickerOpen = next;
      _stablePanelHeight = null;
      _stablePanelSignature = null;
    });
  }

  void _selectCategory(TransactionCategory category) {
    DebugConsole.log(
      '$_hostLogPrefix ${_editing ? 'EditTransaction' : 'AddTransaction'} '
      'category selected id=${category.transactionCategoryID}',
    );
    setState(() {
      _category = category;
      _categoryPickerOpen = false;
      _stablePanelHeight = null;
      _stablePanelSignature = null;
    });
  }

  Future<void> _pickDate() async {
    final initialDate = _parseDate(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date.text = _formatDate(picked));
  }

  Future<void> _pickTime() async {
    final initialTime = _parseTime(_time.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _time.text = _formatTimeOfDay(picked));
  }

  Future<void> _save() async {
    final merchant = _name.text.trim();
    final amount = double.tryParse(_amount.text.trim().replaceAll(' ', ''));
    final category = _category;
    final type = widget.initialTransaction?.type ?? widget.store.activeType;
    final date = _normalizeDate(_date.text);
    final time = _normalizeTime(_time.text);
    if (merchant.isEmpty ||
        amount == null ||
        category == null ||
        date == null ||
        time == null) {
      setState(() => _error = 'Hiányzó vagy hibás adat');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final initial = widget.initialTransaction;
      if (initial == null) {
        await widget.store.addTransaction(
          merchant: merchant,
          amount: amount,
          type: type,
          categoryId: category.transactionCategoryID,
          date: date,
          time: time,
          reloadAfterSave: widget.reloadAfterSave,
        );
      } else {
        final originalMerchant = initial.merchant.trim();
        await widget.store.updateTransaction(
          initial,
          merchant: originalMerchant,
          amount: amount,
          type: type,
          categoryId: category.transactionCategoryID,
          date: date,
          time: time,
          userAssignedName: merchant == originalMerchant ? null : merchant,
        );
      }
      await Future<void>.value(widget.onSaved?.call());
      if (mounted) _close();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  String? _normalizeDate(String value) {
    final parsed = _parseDate(value);
    return parsed == null ? null : _formatDate(parsed);
  }

  String? _normalizeTime(String value) {
    final parsed = _parseTime(value);
    return parsed == null ? null : _formatTimeOfDay(parsed);
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[./]'), '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
