import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/notification_parser_rule.dart';

class NotificationParserRuleEditor extends StatefulWidget {
  const NotificationParserRuleEditor({
    super.key,
    required this.rule,
    required this.preview,
    required this.onChanged,
  });

  final NotificationParserRule rule;
  final NotificationParserPreview preview;
  final ValueChanged<NotificationParserRule> onChanged;

  @override
  State<NotificationParserRuleEditor> createState() =>
      _NotificationParserRuleEditorState();
}

class _NotificationParserRuleEditorState
    extends State<NotificationParserRuleEditor> {
  late final TextEditingController _sampleController;
  late final TextEditingController _keywordController;
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;

  @override
  void initState() {
    super.initState();
    _sampleController = TextEditingController(text: widget.rule.sampleText);
    _keywordController = TextEditingController(
      text: widget.rule.includeKeyword,
    );
    _amountController = TextEditingController(text: widget.rule.amountPattern);
    _merchantController = TextEditingController(
      text: widget.rule.merchantPattern,
    );
  }

  @override
  void didUpdateWidget(covariant NotificationParserRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_sampleController, widget.rule.sampleText);
    _syncController(_keywordController, widget.rule.includeKeyword);
    _syncController(_amountController, widget.rule.amountPattern);
    _syncController(_merchantController, widget.rule.merchantPattern);
  }

  @override
  void dispose() {
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

  void _emit(NotificationParserRule rule) {
    widget.onChanged(rule);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
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
              children: [
                const Expanded(
                  child: Text(
                    'Push parser szabály',
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: widget.rule.enabled,
                  onChanged: (value) =>
                      _emit(widget.rule.copyWith(enabled: value)),
                ),
              ],
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
              onChanged: (value) =>
                  _emit(widget.rule.copyWith(sampleText: value)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('notification-parser-include-keyword'),
              controller: _keywordController,
              decoration: const InputDecoration(labelText: 'Kulcsszó'),
              onChanged: (value) =>
                  _emit(widget.rule.copyWith(includeKeyword: value)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('notification-parser-amount-pattern'),
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Összeg regex'),
              onChanged: (value) =>
                  _emit(widget.rule.copyWith(amountPattern: value)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey('notification-parser-merchant-pattern'),
              controller: _merchantController,
              decoration: const InputDecoration(labelText: 'Bolt regex'),
              onChanged: (value) =>
                  _emit(widget.rule.copyWith(merchantPattern: value)),
            ),
            const SizedBox(height: 12),
            _ParserPreviewBox(preview: preview),
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
