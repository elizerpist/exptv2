import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/installed_app.dart';
import '../models/notification_parser_rule.dart';
import 'app_filter_control.dart';

enum _TrainingMode { amount, merchant }

class NotificationParserProfilesPanel extends StatelessWidget {
  const NotificationParserProfilesPanel({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.preview,
    required this.onProfileSelected,
    required this.onAddProfile,
    required this.onProfileEnabledChanged,
    required this.onProfileChanged,
    required this.onSaveProfile,
    required this.onLoadInstalledApps,
  });

  final List<NotificationParserProfile> profiles;
  final NotificationParserProfile selectedProfile;
  final NotificationParserPreview preview;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onAddProfile;
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
            selected: profile.id == selectedProfile.id,
            onTap: () => onProfileSelected(profile.id),
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
}

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.profile,
    required this.selected,
    required this.onTap,
    required this.onEnabledChanged,
  });

  final NotificationParserProfile profile;
  final bool selected;
  final VoidCallback onTap;
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
  late final TextEditingController _appController;
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
    _appController = TextEditingController(text: widget.profile.appFilterText);
  }

  @override
  void didUpdateWidget(covariant NotificationParserRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_nameController, widget.profile.name);
    _syncController(_sampleController, widget.profile.sampleText);
    _syncController(_keywordController, widget.profile.includeKeyword);
    _syncController(_amountController, widget.profile.amountPattern);
    _syncController(_merchantController, widget.profile.merchantPattern);
    _syncController(_appController, widget.profile.appFilterText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sampleController.dispose();
    _keywordController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _appController.dispose();
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
            TextFormField(
              key: const ValueKey('notification-parser-profile-name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Profil neve'),
              onChanged: (value) => _emit(widget.profile.copyWith(name: value)),
            ),
            const SizedBox(height: 10),
            AppFilterControl(
              value: widget.profile.appFilterText,
              errorText: null,
              onTextChanged: (value) =>
                  _emit(widget.profile.copyWith(appFilterText: value)),
              onLoadInstalledApps: widget.onLoadInstalledApps,
              onAppSelected: _selectInstalledApp,
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
            TextFormField(
              key: const ValueKey('notification-parser-sample'),
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
                  ActionChip(
                    key: ValueKey('notification-parser-token-${token.text}'),
                    label: Text(token.text),
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
                  TextFormField(
                    key: const ValueKey('notification-parser-include-keyword'),
                    controller: _keywordController,
                    decoration: const InputDecoration(labelText: 'Kulcsszó'),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(includeKeyword: value)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const ValueKey('notification-parser-amount-pattern'),
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Összeg regex',
                    ),
                    onChanged: (value) =>
                        _emit(widget.profile.copyWith(amountPattern: value)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const ValueKey('notification-parser-merchant-pattern'),
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
