import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/installed_app.dart';
import '../../settings/models/notification_parser_rule.dart';
import '../../settings/widgets/app_filter_control.dart';
import '../models/recurring_rule.dart';
import '../models/transaction_category.dart';
import '../state/transaction_store.dart';
import '../slots/category_color_resolver.dart';
import 'amount_field.dart';
import 'category_scroll_picker.dart';
import 'category_selector_field.dart';
import 'slide_up_menu_card.dart';
import 'slide_up_panel_metrics.dart';

enum _TrainingMode { amount, merchant }

class RecurringManagerSheet extends StatefulWidget {
  const RecurringManagerSheet({
    super.key,
    required this.store,
    required this.visible,
    required this.onClose,
    required this.onLoadInstalledApps,
    this.openRequestedAt,
  });

  final TransactionStore store;
  final bool visible;
  final VoidCallback onClose;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;
  final DateTime? openRequestedAt;

  @override
  State<RecurringManagerSheet> createState() => _RecurringManagerSheetState();
}

class _RecurringManagerSheetState extends State<RecurringManagerSheet> {
  final _bodyKey = GlobalKey();
  final _bodyScrollController = ScrollController();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '1');
  final _sample = TextEditingController();
  final _keyword = TextEditingController();
  final _amountPattern = TextEditingController(
    text: r'(?<amount>\d[\d\s.,]*)(?:\s*(?:Ft|HUF))',
  );
  final _merchantPattern = TextEditingController(
    text: r'itt:\s*(?<merchant>.+?)(?:\.|$)',
  );
  final _dateTolerance = TextEditingController(text: '5');
  final _amountTolerancePercent = TextEditingController(text: '20');
  final _amountToleranceMin = TextEditingController(text: '5000');
  RecurringTriggerType _triggerType = RecurringTriggerType.date;
  TransactionCategory? _category;
  RecurringRule? _editing;
  var _categoryPickerOpen = false;
  var _saving = false;
  var _advancedOpen = false;
  var _trainingMode = _TrainingMode.amount;
  String _appFilterText = '';
  String _packageName = '';
  String _appLabel = '';
  String _amountSelection = '';
  String _merchantSelection = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.visible) unawaited(widget.store.loadRecurringRules());
  }

  @override
  void didUpdateWidget(covariant RecurringManagerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      unawaited(widget.store.loadRecurringRules());
      _resetForm();
    }
  }

  @override
  void dispose() {
    _bodyScrollController.dispose();
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    _sample.dispose();
    _keyword.dispose();
    _amountPattern.dispose();
    _merchantPattern.dispose();
    _dateTolerance.dispose();
    _amountTolerancePercent.dispose();
    _amountToleranceMin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final panelHeight = SlideUpPanelMetrics.fullHeight(context);
        final activeType = _editing?.transactionType ?? widget.store.activeType;
        final categories = widget.store.categories
            .where((category) => category.normalizedType == activeType)
            .toList();
        _category = _resolvedCategory(categories);
        return SlideUpMenuCard(
          cardKey: const ValueKey('recurring-manager-card'),
          debugLabel: 'RecurringManager',
          panelHeight: panelHeight,
          visible: widget.visible,
          openRequestedAt: widget.openRequestedAt,
          deferEntryAnimation: true,
          dismissThreshold: 150,
          canDragFrom: _canDragFrom,
          onDismissed: widget.onClose,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                const _SheetHandle(),
                _TitleBar(
                  title: _editing == null
                      ? 'Ismétlődő ${activeType.label.toLowerCase()}'
                      : 'Ismétlődő módosítása',
                  subtitle: _editing == null
                      ? '${activeType.label} a fő pill alapján'
                      : _editing!.transactionType.label,
                  onClose: widget.onClose,
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: _bodyKey,
                    child: SingleChildScrollView(
                      key: const ValueKey('recurring-manager-scroll'),
                      controller: _bodyScrollController,
                      padding: EdgeInsets.fromLTRB(
                        SlideUpPanelMetrics.horizontalInset,
                        8,
                        SlideUpPanelMetrics.horizontalInset,
                        MediaQuery.paddingOf(context).bottom + 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TriggerSelector(
                            selected: _triggerType,
                            onChanged: (value) {
                              setState(() => _triggerType = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _CommonForm(
                            name: _name,
                            amount: _amount,
                            day: _day,
                            category: _category,
                            categoryPickerOpen: _categoryPickerOpen,
                            categories: categories,
                            onCategoryTap: () => setState(
                              () => _categoryPickerOpen = !_categoryPickerOpen,
                            ),
                            onCategorySelected: (category) => setState(() {
                              _category = category;
                              _categoryPickerOpen = false;
                            }),
                          ),
                          if (_triggerType == RecurringTriggerType.push) ...[
                            const SizedBox(height: 12),
                            _PushTrainingForm(
                              appFilterText: _appFilterText,
                              appErrorText: _error == _appError
                                  ? 'App kiválasztása szükséges'
                                  : null,
                              onAppTextChanged: (value) => setState(() {
                                _appFilterText = value;
                              }),
                              onAppSelected: _selectInstalledApp,
                              onLoadInstalledApps: widget.onLoadInstalledApps,
                              sample: _sample,
                              keyword: _keyword,
                              amountPattern: _amountPattern,
                              merchantPattern: _merchantPattern,
                              dateTolerance: _dateTolerance,
                              amountTolerancePercent: _amountTolerancePercent,
                              amountToleranceMin: _amountToleranceMin,
                              activeType: activeType,
                              trainingMode: _trainingMode,
                              amountSelection: _amountSelection,
                              merchantSelection: _merchantSelection,
                              advancedOpen: _advancedOpen,
                              onAdvancedChanged: (value) => setState(
                                () => _advancedOpen = value,
                              ),
                              onChanged: () => setState(() {}),
                              onTrainingModeChanged: (value) => setState(
                                () => _trainingMode = value,
                              ),
                              onTokenSelected: _selectTrainingToken,
                            ),
                          ],
                          if (_error != null && _error != _appError) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              key: const ValueKey('recurring-manager-error'),
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            key: const ValueKey('recurring-manager-save'),
                            onPressed: _saving ? null : _save,
                            icon: Icon(
                              _editing == null
                                  ? Icons.add_rounded
                                  : Icons.save_outlined,
                              size: 19,
                            ),
                            label: Text(
                              _saving
                                  ? 'Mentés...'
                                  : _editing == null
                                  ? 'Szabály hozzáadása'
                                  : 'Szabály mentése',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                          if (_editing != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              key: const ValueKey('recurring-manager-cancel-edit'),
                              onPressed: _resetForm,
                              child: const Text('Szerkesztés megszakítása'),
                            ),
                          ],
                          const SizedBox(height: 22),
                          _RuleCollection(
                            rules: widget.store.recurringRules,
                            categories: widget.store.categories,
                            onEdit: _editRule,
                            onToggle: widget.store.toggleRecurringRule,
                            onDelete: widget.store.deleteRecurringRule,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canDragFrom(
    Offset globalPosition,
    Offset startGlobalPosition,
    double gestureDx,
    double gestureDy,
  ) {
    if (!_isInsideBody(startGlobalPosition)) return true;
    if (gestureDy <= 0) return false;
    if (!_bodyScrollController.hasClients) return true;
    return _bodyScrollController.position.pixels <= 0.5;
  }

  bool _isInsideBody(Offset globalPosition) {
    final context = _bodyKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return false;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).contains(globalPosition);
  }

  TransactionCategory? _resolvedCategory(List<TransactionCategory> categories) {
    if (categories.isEmpty) return null;
    final selected = _category;
    if (selected != null &&
        selected.normalizedType == (_editing?.transactionType ?? widget.store.activeType) &&
        categories.any(
          (category) =>
              category.transactionCategoryID == selected.transactionCategoryID,
        )) {
      return selected;
    }
    return categories.first;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = double.tryParse(
      _amount.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
    );
    final day = int.tryParse(_day.text.trim());
    final category = _category;
    if (name.isEmpty || amount == null || day == null || category == null) {
      setState(() => _error = 'Hiányzó vagy hibás alapadat');
      return;
    }
    if (day < 1 || day > 31) {
      setState(() => _error = 'A nap 1 és 31 közé essen');
      return;
    }
    final dateTolerance = int.tryParse(_dateTolerance.text.trim());
    final amountTolerancePercent = double.tryParse(
      _amountTolerancePercent.text.trim().replaceAll(',', '.'),
    );
    final amountToleranceMin = double.tryParse(
      _amountToleranceMin.text.trim().replaceAll(',', '.'),
    );
    if (_triggerType == RecurringTriggerType.push) {
      if (_appFilterText.trim().isEmpty) {
        setState(() => _error = _appError);
        return;
      }
      if (_amountSelection.trim().isEmpty ||
          _merchantSelection.trim().isEmpty) {
        setState(() => _error = 'Válaszd ki az összeget és a boltot');
        return;
      }
      if (dateTolerance == null ||
          amountTolerancePercent == null ||
          amountToleranceMin == null ||
          dateTolerance < 0 ||
          amountTolerancePercent < 0 ||
          amountToleranceMin < 0) {
        setState(() => _error = 'A push szórás mezők nem lehetnek hibásak');
        return;
      }
      final preview = _buildPushParserRule(
        _editing?.transactionType ?? widget.store.activeType,
      ).preview;
      if (!preview.isReady) {
        setState(
          () => _error = preview.errorText ?? 'A push minta nem értelmezhető',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.saveRecurringRule(
        id: _editing?.id,
        triggerType: _triggerType,
        transactionType: _editing?.transactionType,
        name: name,
        estimatedAmount: amount,
        expectedDayOfMonth: day,
        categoryId: category.transactionCategoryID,
        isActive: _editing?.isActive ?? true,
        appFilterText: _triggerType == RecurringTriggerType.push
            ? _appFilterText.trim()
            : '',
        packageName: _triggerType == RecurringTriggerType.push ? _packageName : '',
        appLabel: _triggerType == RecurringTriggerType.push ? _appLabel : '',
        sampleText: _triggerType == RecurringTriggerType.push ? _sample.text : '',
        includeKeyword: _triggerType == RecurringTriggerType.push
            ? _keyword.text
            : '',
        amountPattern: _triggerType == RecurringTriggerType.push
            ? _amountPattern.text
            : '',
        amountSelection: _triggerType == RecurringTriggerType.push
            ? _amountSelection
            : '',
        merchantPattern: _triggerType == RecurringTriggerType.push
            ? _merchantPattern.text
            : '',
        merchantSelection: _triggerType == RecurringTriggerType.push
            ? _merchantSelection
            : '',
        dateToleranceDays: dateTolerance ?? 5,
        amountTolerancePercent: amountTolerancePercent ?? 20,
        amountToleranceMin: amountToleranceMin ?? 5000,
      );
      if (!mounted) return;
      _resetForm();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  NotificationParserRule _buildPushParserRule(TransactionType activeType) {
    return NotificationParserRule(
      enabled: true,
      sampleText: _sample.text,
      includeKeyword: _keyword.text,
      amountPattern: _amountPattern.text,
      merchantPattern: _merchantPattern.text,
      amountSelection: _amountSelection,
      merchantSelection: _merchantSelection,
      transactionType: activeType,
    );
  }

  void _selectInstalledApp(InstalledApp app) {
    setState(() {
      _appLabel = app.displayName;
      _packageName = app.packageName;
      _appFilterText = '^${RegExp.escape(app.displayName)}\$';
    });
  }

  void _selectTrainingToken(NotificationTrainingToken token) {
    final profile = NotificationParserProfile.defaults().copyWith(
      sampleText: _sample.text,
      amountPattern: _amountPattern.text,
      merchantPattern: _merchantPattern.text,
      amountSelection: _amountSelection,
      merchantSelection: _merchantSelection,
      transactionType: _editing?.transactionType ?? widget.store.activeType,
    );
    final learned = switch (_trainingMode) {
      _TrainingMode.amount => profile.learnAmountFromSelection(token.text),
      _TrainingMode.merchant => profile.learnMerchantFromSelection(token.text),
    };
    setState(() {
      _amountPattern.text = learned.amountPattern;
      _merchantPattern.text = learned.merchantPattern;
      _amountSelection = learned.amountSelection;
      _merchantSelection = learned.merchantSelection;
    });
  }

  void _editRule(RecurringRule rule) {
    setState(() {
      _editing = rule;
      _triggerType = rule.triggerType;
      _name.text = rule.name;
      _amount.text = rule.estimatedAmount.toStringAsFixed(0);
      _day.text = rule.expectedDayOfMonth.toString();
      _category = _categoryById(rule.categoryId);
      _appFilterText = rule.appFilterText;
      _packageName = rule.packageName;
      _appLabel = rule.appLabel;
      _sample.text = rule.sampleText;
      _keyword.text = rule.includeKeyword;
      _amountPattern.text = rule.amountPattern.isEmpty
          ? r'(?<amount>\d[\d\s.,]*)(?:\s*(?:Ft|HUF))'
          : rule.amountPattern;
      _merchantPattern.text = rule.merchantPattern.isEmpty
          ? r'itt:\s*(?<merchant>.+?)(?:\.|$)'
          : rule.merchantPattern;
      _amountSelection = rule.amountSelection;
      _merchantSelection = rule.merchantSelection;
      _dateTolerance.text = rule.dateToleranceDays.toString();
      _amountTolerancePercent.text = rule.amountTolerancePercent.toStringAsFixed(
        0,
      );
      _amountToleranceMin.text = rule.amountToleranceMin.toStringAsFixed(0);
      _categoryPickerOpen = false;
      _error = null;
    });
    if (_bodyScrollController.hasClients) {
      unawaited(
        _bodyScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  TransactionCategory? _categoryById(int id) {
    for (final category in widget.store.categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  void _resetForm() {
    setState(() {
      _editing = null;
      _triggerType = RecurringTriggerType.date;
      _name.clear();
      _amount.clear();
      _day.text = '1';
      _category = null;
      _categoryPickerOpen = false;
      _sample.clear();
      _keyword.clear();
      _amountPattern.text = r'(?<amount>\d[\d\s.,]*)(?:\s*(?:Ft|HUF))';
      _merchantPattern.text = r'itt:\s*(?<merchant>.+?)(?:\.|$)';
      _dateTolerance.text = '5';
      _amountTolerancePercent.text = '20';
      _amountToleranceMin.text = '5000';
      _appFilterText = '';
      _packageName = '';
      _appLabel = '';
      _amountSelection = '';
      _merchantSelection = '';
      _trainingMode = _TrainingMode.amount;
      _advancedOpen = false;
      _error = null;
      _saving = false;
    });
  }
}

const _appError = 'APP_REQUIRED';

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('recurring-manager-close'),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Bezárás',
          ),
        ],
      ),
    );
  }
}

class _TriggerSelector extends StatelessWidget {
  const _TriggerSelector({required this.selected, required this.onChanged});

  final RecurringTriggerType selected;
  final ValueChanged<RecurringTriggerType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in RecurringTriggerType.values) ...[
          Expanded(
            child: _TriggerChoice(
              triggerType: type,
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
          ),
          if (type != RecurringTriggerType.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TriggerChoice extends StatelessWidget {
  const _TriggerChoice({
    required this.triggerType,
    required this.selected,
    required this.onTap,
  });

  final RecurringTriggerType triggerType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return InkWell(
      key: ValueKey('recurring-trigger-${triggerType.nativeValue}'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.gray100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : AppColors.gray200),
        ),
        child: Text(
          triggerType.label,
          style: TextStyle(
            color: selected ? color : AppColors.gray600,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CommonForm extends StatelessWidget {
  const _CommonForm({
    required this.name,
    required this.amount,
    required this.day,
    required this.category,
    required this.categoryPickerOpen,
    required this.categories,
    required this.onCategoryTap,
    required this.onCategorySelected,
  });

  final TextEditingController name;
  final TextEditingController amount;
  final TextEditingController day;
  final TransactionCategory? category;
  final bool categoryPickerOpen;
  final List<TransactionCategory> categories;
  final VoidCallback onCategoryTap;
  final ValueChanged<TransactionCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugTextField(
          fieldKey: const ValueKey('recurring-rule-name'),
          debugLabel: 'RecurringRule.name',
          controller: name,
          decoration: transactionFieldDecoration('Név'),
        ),
        const SizedBox(height: 12),
        AmountField(
          controller: amount,
          debugLabel: 'RecurringRule.estimatedAmount',
        ),
        const SizedBox(height: 12),
        CategorySelectorField(selected: category, onTap: onCategoryTap),
        if (categoryPickerOpen) ...[
          const SizedBox(height: 8),
          CategoryScrollPicker(
            keyPrefix: 'recurring-rule-category',
            categories: categories,
            selected: category,
            maxHeight: 170,
            onSelected: onCategorySelected,
          ),
        ],
        const SizedBox(height: 12),
        DebugTextField(
          fieldKey: const ValueKey('recurring-rule-day'),
          debugLabel: 'RecurringRule.expectedDay',
          controller: day,
          keyboardType: TextInputType.number,
          decoration: transactionFieldDecoration('Várt nap a hónapban'),
        ),
      ],
    );
  }
}

class _PushTrainingForm extends StatelessWidget {
  const _PushTrainingForm({
    required this.appFilterText,
    required this.appErrorText,
    required this.onAppTextChanged,
    required this.onAppSelected,
    required this.onLoadInstalledApps,
    required this.sample,
    required this.keyword,
    required this.amountPattern,
    required this.merchantPattern,
    required this.dateTolerance,
    required this.amountTolerancePercent,
    required this.amountToleranceMin,
    required this.activeType,
    required this.trainingMode,
    required this.amountSelection,
    required this.merchantSelection,
    required this.advancedOpen,
    required this.onAdvancedChanged,
    required this.onChanged,
    required this.onTrainingModeChanged,
    required this.onTokenSelected,
  });

  final String appFilterText;
  final String? appErrorText;
  final ValueChanged<String> onAppTextChanged;
  final ValueChanged<InstalledApp> onAppSelected;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;
  final TextEditingController sample;
  final TextEditingController keyword;
  final TextEditingController amountPattern;
  final TextEditingController merchantPattern;
  final TextEditingController dateTolerance;
  final TextEditingController amountTolerancePercent;
  final TextEditingController amountToleranceMin;
  final TransactionType activeType;
  final _TrainingMode trainingMode;
  final String amountSelection;
  final String merchantSelection;
  final bool advancedOpen;
  final ValueChanged<bool> onAdvancedChanged;
  final VoidCallback onChanged;
  final ValueChanged<_TrainingMode> onTrainingModeChanged;
  final ValueChanged<NotificationTrainingToken> onTokenSelected;

  @override
  Widget build(BuildContext context) {
    final rule = NotificationParserRule(
      enabled: true,
      sampleText: sample.text,
      includeKeyword: keyword.text,
      amountPattern: amountPattern.text,
      merchantPattern: merchantPattern.text,
      amountSelection: amountSelection,
      merchantSelection: merchantSelection,
      transactionType: activeType,
    );
    final tokens = NotificationTrainingToken.fromSample(sample.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFilterControl(
              value: appFilterText,
              errorText: appErrorText,
              onTextChanged: onAppTextChanged,
              onLoadInstalledApps: onLoadInstalledApps,
              onAppSelected: onAppSelected,
            ),
            const SizedBox(height: 12),
            DebugTextField(
              fieldKey: const ValueKey('recurring-rule-sample'),
              debugLabel: 'RecurringRule.sample',
              controller: sample,
              minLines: 3,
              maxLines: 5,
              decoration: transactionFieldDecoration('Példa push üzenet'),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('recurring-training-amount'),
                  label: const Text('Összeg'),
                  selected: trainingMode == _TrainingMode.amount,
                  onSelected: (_) => onTrainingModeChanged(_TrainingMode.amount),
                ),
                ChoiceChip(
                  key: const ValueKey('recurring-training-merchant'),
                  label: const Text('Bolt'),
                  selected: trainingMode == _TrainingMode.merchant,
                  onSelected: (_) => onTrainingModeChanged(_TrainingMode.merchant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final token in tokens)
                  _TrainingChip(
                    token: token,
                    activeMode: trainingMode,
                    selectedAsAmount:
                        NotificationParserPreview.normalizeText(token.text) ==
                        amountSelection,
                    selectedAsMerchant:
                        NotificationParserPreview.normalizeText(token.text) ==
                        merchantSelection,
                    onTap: () => onTokenSelected(token),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _RecurringParserPreview(rule: rule),
            Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const ValueKey('recurring-push-advanced'),
                  initiallyExpanded: advancedOpen,
                  tilePadding: EdgeInsets.zero,
                  onExpansionChanged: onAdvancedChanged,
                  title: const Text('Haladó push egyezés'),
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    DebugTextField(
                      fieldKey: const ValueKey('recurring-rule-keyword'),
                      debugLabel: 'RecurringRule.keyword',
                      controller: keyword,
                      decoration: transactionFieldDecoration('Kulcsszó'),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 10),
                    DebugTextField(
                      fieldKey: const ValueKey('recurring-rule-amount-pattern'),
                      debugLabel: 'RecurringRule.amountPattern',
                      controller: amountPattern,
                      decoration: transactionFieldDecoration('Összeg regex'),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 10),
                    DebugTextField(
                      fieldKey: const ValueKey('recurring-rule-merchant-pattern'),
                      debugLabel: 'RecurringRule.merchantPattern',
                      controller: merchantPattern,
                      decoration: transactionFieldDecoration('Bolt regex'),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DebugTextField(
                            debugLabel: 'RecurringRule.dateTolerance',
                            controller: dateTolerance,
                            keyboardType: TextInputType.number,
                            decoration: transactionFieldDecoration('Nap szórás'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DebugTextField(
                            debugLabel: 'RecurringRule.amountTolerancePercent',
                            controller: amountTolerancePercent,
                            keyboardType: TextInputType.number,
                            decoration: transactionFieldDecoration('% szórás'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DebugTextField(
                      debugLabel: 'RecurringRule.amountToleranceMin',
                      controller: amountToleranceMin,
                      keyboardType: TextInputType.number,
                      decoration: transactionFieldDecoration('Minimum Ft szórás'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingChip extends StatelessWidget {
  const _TrainingChip({
    required this.token,
    required this.activeMode,
    required this.selectedAsAmount,
    required this.selectedAsMerchant,
    required this.onTap,
  });

  final NotificationTrainingToken token;
  final _TrainingMode activeMode;
  final bool selectedAsAmount;
  final bool selectedAsMerchant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedAsAmount || selectedAsMerchant;
    final selectedForActiveMode = switch (activeMode) {
      _TrainingMode.amount => selectedAsAmount,
      _TrainingMode.merchant => selectedAsMerchant,
    };
    final color = selectedAsAmount
        ? AppColors.expense
        : selectedAsMerchant
        ? const Color(0xFFF97316)
        : AppColors.gray200;
    return InkWell(
      key: ValueKey('recurring-training-token-${token.text}'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color, width: selectedForActiveMode ? 2 : 1),
        ),
        child: Text(
          token.text,
          style: TextStyle(
            color: selected ? AppColors.gray800 : AppColors.gray700,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RecurringParserPreview extends StatelessWidget {
  const _RecurringParserPreview({required this.rule});

  final NotificationParserRule rule;

  @override
  Widget build(BuildContext context) {
    final preview = rule.preview;
    final error = preview.errorText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error == null ? const Color(0xFFF0FDFA) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error == null ? const Color(0xFF99F6E4) : const Color(0xFFFECACA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewRow(label: 'Összeg', value: preview.amountText ?? '-'),
            const SizedBox(height: 6),
            _PreviewRow(label: 'Bolt', value: preview.merchant ?? '-'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.gray600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleCollection extends StatelessWidget {
  const _RuleCollection({
    required this.rules,
    required this.categories,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final List<RecurringRule> rules;
  final List<TransactionCategory> categories;
  final ValueChanged<RecurringRule> onEdit;
  final ValueChanged<RecurringRule> onToggle;
  final ValueChanged<RecurringRule> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'Nincs még ismétlődő szabály',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final trigger in RecurringTriggerType.values) ...[
          _SectionHeader(trigger.label),
          for (final rule in rules.where((row) => row.triggerType == trigger))
            _RuleCard(
              rule: rule,
              category: CategoryColorResolver.findById(categories, rule.categoryId),
              onEdit: () => onEdit(rule),
              onToggle: () => onToggle(rule),
              onDelete: () => onDelete(rule),
            ),
          if (!rules.any((row) => row.triggerType == trigger))
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Nincs ilyen szabály',
                style: TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.gray800,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.category,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringRule rule;
  final TransactionCategory? category;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColorResolver.color(
      category: category,
      snapshotHex: rule.categoryColor,
    );
    return Container(
      key: ValueKey('recurring-rule-card-${rule.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${rule.transactionType.label} · ${rule.estimatedAmount.toStringAsFixed(0)} Ft · hó ${rule.expectedDayOfMonth}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                ),
                if (rule.triggerType == RecurringTriggerType.push &&
                    (rule.appLabel.isNotEmpty || rule.appFilterText.isNotEmpty))
                  Text(
                    rule.appLabel.isNotEmpty ? rule.appLabel : rule.appFilterText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('recurring-rule-toggle-${rule.id}'),
            tooltip: rule.isActive ? 'Inaktiválás' : 'Aktiválás',
            onPressed: onToggle,
            icon: Icon(
              rule.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
              color: rule.isActive ? AppColors.primary : AppColors.gray400,
            ),
          ),
          IconButton(
            key: ValueKey('recurring-rule-edit-${rule.id}'),
            tooltip: 'Szerkesztés',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.gray600),
          ),
          IconButton(
            key: ValueKey('recurring-rule-delete-${rule.id}'),
            tooltip: 'Törlés',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
