import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../state/event_store.dart';
import '../../../transactions/widgets/slide_up_panel_metrics.dart';
import '../../../transactions/models/transaction_category.dart';
import '../../models/notification_parser_rule.dart';
import '../../models/push_notification_log_event.dart';
import '../../state/push_notification_log_store.dart';

enum _PushSheetTrainingMode { amount, merchant }

class PushNotificationEventSheet extends StatefulWidget {
  const PushNotificationEventSheet({
    super.key,
    required this.event,
    required this.parserStore,
    required this.logStore,
  });

  final PushNotificationLogEvent event;
  final EventStore parserStore;
  final PushNotificationLogStore logStore;

  @override
  State<PushNotificationEventSheet> createState() =>
      _PushNotificationEventSheetState();
}

class _PushNotificationEventSheetState
    extends State<PushNotificationEventSheet> {
  late NotificationParserProfile _profile;
  var _mode = _PushSheetTrainingMode.amount;
  var _saving = false;
  var _handleDragDy = 0.0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _profile = widget.parserStore.selectedNotificationParserProfile.copyWith(
      enabled: true,
      sampleText: widget.event.fullText,
      includeKeyword: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tokens = NotificationTrainingToken.fromSample(event.fullText);
    final preview = _profile.preview;
    final canCreate =
        !event.hasLinkedTransaction && preview.isReady && !_saving;
    return Container(
      key: const ValueKey('push-event-sheet'),
      height: SlideUpPanelMetrics.fullHeight(context),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            GestureDetector(
              key: const ValueKey('push-event-sheet-drag-handle'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _handleDragDy = 0,
              onVerticalDragUpdate: (details) {
                _handleDragDy += details.delta.dy;
              },
              onVerticalDragEnd: (_) {
                if (_handleDragDy > 120) {
                  Navigator.of(context).pop();
                }
                _handleDragDy = 0;
              },
              child: const _SheetHandle(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 6,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${event.displayApp} · ${event.statusText.toLowerCase()}',
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatTimestamp(event.timestamp)} · '
                      '${event.sourceBadge} · #${event.id}',
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SelectableText(
                      event.fullText,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!event.hasLinkedTransaction) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            key: const ValueKey('push-event-mode-amount'),
                            label: const Text('Összeg'),
                            selected: _mode == _PushSheetTrainingMode.amount,
                            onSelected: (_) => setState(
                              () => _mode = _PushSheetTrainingMode.amount,
                            ),
                          ),
                          ChoiceChip(
                            key: const ValueKey('push-event-mode-merchant'),
                            label: const Text('Bolt'),
                            selected: _mode == _PushSheetTrainingMode.merchant,
                            onSelected: (_) => setState(
                              () => _mode = _PushSheetTrainingMode.merchant,
                            ),
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
                              key: ValueKey('push-event-token-${token.text}'),
                              label: Text(token.text),
                              onPressed: () => _selectToken(token),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _PreviewBox(preview: preview),
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const ValueKey('push-event-train-create'),
                        onPressed: canCreate ? _trainAndCreate : null,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.school, size: 18),
                        label: const Text('Tanítás és log létrehozása'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('push-event-mark-system'),
                        onPressed: _saving ? null : _markSystem,
                        child: const Text('Rendszerüzenetként jelölés'),
                      ),
                    ] else ...[
                      Text(
                        'Kapcsolt log: #${event.linkedTransactionId}',
                        key: const ValueKey('push-event-linked-transaction'),
                        style: const TextStyle(
                          color: AppColors.gray700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('push-event-close'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Bezárás'),
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

  void _selectToken(NotificationTrainingToken token) {
    setState(() {
      _profile = switch (_mode) {
        _PushSheetTrainingMode.amount => _profile.learnAmountFromSelection(
          token.text,
        ),
        _PushSheetTrainingMode.merchant => _profile
            .learnMerchantFromSelection(token.text),
      };
      _errorText = null;
    });
  }

  Future<void> _trainAndCreate() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.logStore.trainAndCreateTransaction(
        event: widget.event,
        trainedProfile: _profile,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = error.toString();
      });
    }
  }

  Future<void> _markSystem() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.logStore.markSystem(widget.event);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = error.toString();
      });
    }
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
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

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.preview});

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
              valueKey: const ValueKey('push-event-preview-amount'),
            ),
            const SizedBox(height: 6),
            _PreviewRow(
              label: 'Bolt',
              value: preview.merchant ?? 'Nincs találat',
              valueKey: const ValueKey('push-event-preview-merchant'),
            ),
            const SizedBox(height: 6),
            _PreviewRow(
              label: 'Típus',
              value: preview.transactionType.label,
              valueKey: const ValueKey('push-event-preview-type'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const ValueKey('push-event-preview-error'),
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

String _formatTimestamp(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
