import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/installed_app.dart';
import '../../transactions/models/transaction_category.dart';
import '../models/notification_parser_rule.dart';
import 'app_filter_control.dart';
import 'installed_app_icon.dart';

enum _TrainingMode { amount, merchant }

const _merchantSelectionColor = Color(0xFFF97316);

class NotificationParserProfilesPanel extends StatelessWidget {
  const NotificationParserProfilesPanel({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.preview,
    required this.installedApps,
    required this.onProfileSelected,
    required this.onAddProfile,
    required this.onDeleteProfile,
    required this.onProfileEnabledChanged,
    required this.onProfileChanged,
    required this.onSaveProfile,
    required this.onLoadInstalledApps,
  });

  final List<NotificationParserProfile> profiles;
  final NotificationParserProfile selectedProfile;
  final NotificationParserPreview preview;
  final List<InstalledApp> installedApps;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onAddProfile;
  final ValueChanged<String> onDeleteProfile;
  final void Function(String id, bool enabled) onProfileEnabledChanged;
  final ValueChanged<NotificationParserProfile> onProfileChanged;
  final VoidCallback onSaveProfile;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Profilok',
                style: TextStyle(
                  color: AppColors.gray800,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('notification-parser-add-profile'),
              onPressed: onAddProfile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Új profil'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final profile in profiles) ...[
          _ProfileListTile(
            profile: profile,
            app: _appFor(profile),
            selected: profile.id == selectedProfile.id,
            onTap: () => onProfileSelected(profile.id),
            onDelete: () => _confirmDelete(context, profile),
            onEnabledChanged: (enabled) =>
                onProfileEnabledChanged(profile.id, enabled),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        NotificationParserRuleEditor(
          profile: selectedProfile,
          preview: preview,
          onChanged: onProfileChanged,
          onSave: onSaveProfile,
          onLoadInstalledApps: onLoadInstalledApps,
        ),
      ],
    );
  }

  InstalledApp? _appFor(NotificationParserProfile profile) {
    if (profile.packageName.isEmpty) return null;
    for (final app in installedApps) {
      if (app.packageName == profile.packageName) return app;
    }
    return null;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NotificationParserProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil törlése'),
        content: Text('Törlöd ezt a profilt? ${profile.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-profile'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDeleteProfile(profile.id);
  }
}

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.profile,
    required this.app,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.onEnabledChanged,
  });

  final NotificationParserProfile profile;
  final InstalledApp? app;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('notification-parser-profile-${profile.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF60A5FA) : AppColors.gray200,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                key: ValueKey('notification-parser-profile-icon-${profile.id}'),
                width: 42,
                child: Center(
                  child: app == null
                      ? const Icon(
                          Icons.apps,
                          color: AppColors.gray500,
                          size: 28,
                        )
                      : InstalledAppIcon(app: app!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.appLabel.isNotEmpty
                          ? profile.appLabel
                          : profile.appFilterText.isNotEmpty
                          ? profile.appFilterText
                          : 'Nincs app kiválasztva',
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: ValueKey(
                  'notification-parser-profile-enabled-${profile.id}',
                ),
                value: profile.enabled,
                onChanged: onEnabledChanged,
              ),
              IconButton(
                key: ValueKey('notification-parser-delete-profile-${profile.id}'),
                tooltip: 'Profil törlése',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationParserRuleEditor extends StatefulWidget {
  const NotificationParserRuleEditor({
    super.key,
    required this.profile,
    required this.preview,
    required this.onChanged,
    required this.onSave,
    required this.onLoadInstalledApps,
  });

  final NotificationParserProfile profile;
  final NotificationParserPreview preview;
  final ValueChanged<NotificationParserProfile> onChanged;
  final VoidCallback onSave;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;

  @override
  State<NotificationParserRuleEditor> createState() =>
      _NotificationParserRuleEditorState();
}

class _NotificationParserRuleEditorState
    extends State<NotificationParserRuleEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _sampleController;
  late final TextEditingController _keywordController;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  var _trainingMode = _TrainingMode.amount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _sampleController = TextEditingController(text: widget.profile.sampleText);
    _keywordController = TextEditingController(
      text: widget.profile.includeKeyword,
    );
    _amountController = TextEditingController(
      text: widget.profile.amountPattern,
    );
    _merchantController = TextEditingController(
      text: widget.profile.merchantPattern,
    );
  }

  @override
  void didUpdateWidget(covariant NotificationParserRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_nameController, widget.profile.name);
    _syncController(_sampleController, widget.profile.sampleText);
    _syncController(_keywordController, widget.profile.includeKeyword);
    _syncController(_amountController, widget.profile.amountPattern);
    _syncController(_merchantController, widget.profile.merchantPattern);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sampleController.dispose();
    _keywordController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _emit(NotificationParserProfile profile) {
    widget.onChanged(profile);
  }

  void _selectToken(NotificationTrainingToken token) {
    final profile = switch (_trainingMode) {
      _TrainingMode.amount => widget.profile.learnAmountFromSelection(
        token.text,
      ),
      _TrainingMode.merchant => widget.profile.learnMerchantFromSelection(
        token.text,
      ),
    };
    _emit(profile);
  }

  void _selectInstalledApp(InstalledApp app) {
    _emit(
      widget.profile.copyWith(
        appLabel: app.displayName,
        packageName: app.packageName,
        appFilterText: '^${RegExp.escape(app.displayName)}\$',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final tokens = NotificationTrainingToken.fromSample(
      widget.profile.sampleText,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DebugTextFormField(
                    fieldKey: const ValueKey(
                      'notification-parser-profile-name',
                    ),
                    debugLabel: 'NotificationParser.profileName',
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Profil neve'),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(name: value)),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppFilterControl(
                    value: widget.profile.appFilterText,
                    errorText: null,
                    onTextChanged: (_) {},
                    onLoadInstalledApps: widget.onLoadInstalledApps,
                    onAppSelected: _selectInstalledApp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Tranzakció típusa',
              style: TextStyle(
                color: AppColors.gray800,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('notification-parser-type-expense'),
                  label: Text(TransactionType.expense.label),
                  selected:
                      widget.profile.transactionType == TransactionType.expense,
                  selectedColor: AppColors.expense.withValues(alpha: 0.12),
                  onSelected: (_) => _emit(
                    widget.profile.copyWith(
                      transactionType: TransactionType.expense,
                    ),
                  ),
                ),
                ChoiceChip(
                  key: const ValueKey('notification-parser-type-income'),
                  label: Text(TransactionType.income.label),
                  selected:
                      widget.profile.transactionType == TransactionType.income,
                  selectedColor: AppColors.income.withValues(alpha: 0.12),
                  onSelected: (_) => _emit(
                    widget.profile.copyWith(
                      transactionType: TransactionType.income,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Tanító mód',
              style: TextStyle(
                color: AppColors.gray800,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            DebugTextFormField(
              fieldKey: const ValueKey('notification-parser-sample'),
              debugLabel: 'NotificationParser.sample',
              controller: _sampleController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Teszt értesítés',
                alignLabelWithHint: true,
              ),
              onChanged: (value) => _emit(
                widget.profile.copyWith(sampleText: value, includeKeyword: ''),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('notification-parser-mode-amount'),
                  label: const Text('Összeg'),
                  selected: _trainingMode == _TrainingMode.amount,
                  onSelected: (_) =>
                      setState(() => _trainingMode = _TrainingMode.amount),
                ),
                ChoiceChip(
                  key: const ValueKey('notification-parser-mode-merchant'),
                  label: const Text('Bolt'),
                  selected: _trainingMode == _TrainingMode.merchant,
                  onSelected: (_) =>
                      setState(() => _trainingMode = _TrainingMode.merchant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final token in tokens)
                  _TrainingTokenChip(
                    token: token,
                    selectedAsAmount:
                        NotificationParserPreview.normalizeText(token.text) ==
                        widget.profile.amountSelection,
                    selectedAsMerchant:
                        NotificationParserPreview.normalizeText(token.text) ==
                        widget.profile.merchantSelection,
                    transactionType: widget.profile.transactionType,
                    activeMode: _trainingMode,
                    onPressed: () => _selectToken(token),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ParserPreviewBox(preview: preview),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Haladó beállítások'),
                childrenPadding: EdgeInsets.zero,
                children: [
                  DebugTextFormField(
                    fieldKey: const ValueKey(
                      'notification-parser-include-keyword',
                    ),
                    debugLabel: 'NotificationParser.includeKeyword',
                    controller: _keywordController,
                    decoration: const InputDecoration(labelText: 'Kulcsszó'),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(includeKeyword: value)),
                  ),
                  const SizedBox(height: 10),
                  DebugTextFormField(
                    fieldKey: const ValueKey(
                      'notification-parser-amount-pattern',
                    ),
                    debugLabel: 'NotificationParser.amountPattern',
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Összeg regex',
                    ),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(amountPattern: value)),
                  ),
                  const SizedBox(height: 10),
                  DebugTextFormField(
                    fieldKey: const ValueKey(
                      'notification-parser-merchant-pattern',
                    ),
                    debugLabel: 'NotificationParser.merchantPattern',
                    controller: _merchantController,
                    decoration: const InputDecoration(labelText: 'Bolt regex'),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(merchantPattern: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('notification-parser-save-profile'),
              onPressed: preview.isReady ? widget.onSave : null,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Profil mentése'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingTokenChip extends StatelessWidget {
  const _TrainingTokenChip({
    required this.token,
    required this.selectedAsAmount,
    required this.selectedAsMerchant,
    required this.transactionType,
    required this.activeMode,
    required this.onPressed,
  });

  final NotificationTrainingToken token;
  final bool selectedAsAmount;
  final bool selectedAsMerchant;
  final TransactionType transactionType;
  final _TrainingMode activeMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = selectedAsAmount || selectedAsMerchant;
    final selectedForActiveMode = switch (activeMode) {
      _TrainingMode.amount => selectedAsAmount,
      _TrainingMode.merchant => selectedAsMerchant,
    };
    final amountSelectionColor = transactionType == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    final borderColor = selectedAsAmount
        ? amountSelectionColor
        : selectedAsMerchant
        ? _merchantSelectionColor
        : AppColors.gray200;
    final backgroundColor = selected
        ? borderColor.withValues(alpha: 0.08)
        : AppColors.gray50;
    return InkWell(
      key: ValueKey('notification-parser-token-${token.text}'),
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        key: ValueKey('notification-parser-token-frame-${token.text}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
            width: selectedForActiveMode ? 2 : 1,
          ),
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

class _ParserPreviewBox extends StatelessWidget {
  const _ParserPreviewBox({required this.preview});

  final NotificationParserPreview preview;

  @override
  Widget build(BuildContext context) {
    final error = preview.errorText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: error == null
            ? const Color(0xFFF0FDFA)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error == null
              ? const Color(0xFF99F6E4)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                color: AppColors.gray700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _PreviewRow(
              label: 'Összeg',
              value: preview.amountText ?? 'Nincs találat',
              valueKey: const ValueKey('notification-parser-preview-amount'),
            ),
            const SizedBox(height: 6),
            _PreviewRow(
              label: 'Bolt',
              value: preview.merchant ?? 'Nincs találat',
              valueKey: const ValueKey('notification-parser-preview-merchant'),
            ),
            const SizedBox(height: 6),
            _PreviewRow(
              label: 'Típus',
              value: preview.transactionType.label,
              valueKey: const ValueKey('notification-parser-preview-type'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const ValueKey('notification-parser-preview-error'),
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
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

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
            key: valueKey,
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
