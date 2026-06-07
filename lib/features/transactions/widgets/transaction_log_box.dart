import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'category_menu/category_icon_badge.dart';

typedef TransactionLogContextCallback =
    void Function(TransactionRecord record, TransactionCategory? category);
typedef TransactionRenameCallback =
    FutureOr<void> Function(TransactionRecord record, String userAssignedName);
typedef TransactionRecordAction =
    FutureOr<void> Function(TransactionRecord record);
typedef TransactionDeleteRequest =
    FutureOr<bool> Function(TransactionRecord record);

class TransactionLogBox extends StatefulWidget {
  const TransactionLogBox({
    super.key,
    required this.record,
    required this.category,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.onFastFilter,
    this.onTap,
    this.onDeleteRequested,
    this.onCategoryFilter,
    this.onRenameMerchant,
    this.onResetMerchantName,
  });

  final TransactionRecord record;
  final TransactionCategory? category;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final TransactionLogContextCallback? onFastFilter;
  final ValueChanged<TransactionRecord>? onTap;
  final TransactionDeleteRequest? onDeleteRequested;
  final ValueChanged<TransactionCategory>? onCategoryFilter;
  final TransactionRenameCallback? onRenameMerchant;
  final TransactionRecordAction? onResetMerchantName;

  @override
  State<TransactionLogBox> createState() => _TransactionLogBoxState();
}

class _TransactionLogBoxState extends State<TransactionLogBox> {
  static const _maxVisualOffset = 44.0;

  late final ValueNotifier<_SwipeVisualState> _swipeVisual;
  double _dragDx = 0;
  bool _triggered = false;
  bool _deletePending = false;
  bool _deleteFrozen = false;

  bool get _hasCustomName =>
      widget.record.userAssignedName?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _swipeVisual = ValueNotifier<_SwipeVisualState>(
      _SwipeVisualState.idle,
    );
  }

  @override
  void dispose() {
    _swipeVisual.dispose();
    super.dispose();
  }

  void _resetDrag() {
    _dragDx = 0;
    _triggered = false;
    _deletePending = false;
    _deleteFrozen = false;
    if (!mounted) return;
    _swipeVisual.value = _SwipeVisualState.idle;
  }

  void _startDrag() {
    if (_deletePending || _deleteFrozen) return;
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered || _deletePending || _deleteFrozen) return;
    _dragDx += details.delta.dx;
    _syncSwipeVisual();
    if (_dragDx < -80) {
      _triggered = true;
      widget.onFastFilter?.call(widget.record, widget.category);
      return;
    }
    if (_dragDx > 70 && widget.onDeleteRequested != null) {
      _triggerDeleteRequest();
    }
  }

  void _triggerDeleteRequest() {
    _triggered = true;
    setState(() {
      _deletePending = true;
      _deleteFrozen = true;
    });
    _swipeVisual.value = const _SwipeVisualState(
      dx: _maxVisualOffset,
      deleteOpacity: 1,
      filterOpacity: 0,
    );
    unawaited(_requestDelete());
  }

  Future<void> _requestDelete() async {
    final confirmed = await widget.onDeleteRequested!(widget.record);
    if (!mounted) return;
    if (confirmed) {
      setState(() => _deletePending = false);
      return;
    }
    _resetDrag();
  }

  Future<void> _openNameEditor() async {
    final rename = widget.onRenameMerchant;
    if (rename == null) return;
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return _TransactionNameDialog(
          initialValue: widget.record.displayMerchant,
        );
      },
    );
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await rename(widget.record, trimmed);
  }

  Future<void> _resetName() async {
    await widget.onResetMerchantName?.call(widget.record);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = widget.record.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return GestureDetector(
      key: ValueKey('transaction-logbox-${widget.record.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap?.call(widget.record),
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragCancel: _deleteFrozen ? null : _resetDrag,
      onHorizontalDragEnd: (_) {
        if (_deleteFrozen) return;
        if (!_triggered && _dragDx > 70 && widget.onDeleteRequested != null) {
          _triggerDeleteRequest();
          return;
        }
        _resetDrag();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: ValueListenableBuilder<_SwipeVisualState>(
          valueListenable: _swipeVisual,
          builder: (context, visual, child) {
            return Transform.translate(
              key: ValueKey('transaction-logbox-card-${widget.record.id}'),
              offset: Offset(visual.dx, 0),
              child: SizedBox(
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExpensePressable(
                      enabled: widget.surfaceStyle.hasPressEffect,
                      builder: (context, pressed) {
                        return Container(
                          key: ValueKey(
                            'transaction-logbox-content-${widget.record.id}',
                          ),
                          constraints: const BoxConstraints(minHeight: 70),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: ExpenseSurface.decoration(
                            style: widget.surfaceStyle,
                            color: widget.surfaceColor,
                            borderRadius: BorderRadius.circular(25),
                            pressed: pressed,
                            neutralBorder: Border.all(
                              color: AppColors.gray200,
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                key: ValueKey(
                                  'transaction-logbox-avatar-${widget.record.id}',
                                ),
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    widget.category == null ||
                                        widget.onCategoryFilter == null
                                    ? null
                                    : () => widget.onCategoryFilter!(
                                        widget.category!,
                                      ),
                                child: ExpensePressable(
                                  enabled:
                                      widget
                                          .avatarSurfaceStyle
                                          .hasPressEffect &&
                                      widget.category != null &&
                                      widget.onCategoryFilter != null,
                                  builder: (context, avatarPressed) {
                                    return DecoratedBox(
                                      key: ValueKey(
                                        'transaction-logbox-avatar-surface-${widget.record.id}',
                                      ),
                                      decoration: ExpenseSurface.decoration(
                                        style: widget.avatarSurfaceStyle,
                                        color: widget.category?.slotColor ??
                                            AppColors.gray500,
                                        borderRadius: BorderRadius.circular(23),
                                        pressed: avatarPressed,
                                      ),
                                      child: CategoryIconBadge(
                                        category: widget.category,
                                        backgroundColor:
                                            widget.category?.slotColor ??
                                            AppColors.gray500,
                                        size: 46,
                                        iconSize: 28,
                                        showShadow: false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _nameBlock()),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.record.displayAmount,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: amountColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.record.displayTime,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (visual.deleteOpacity > 0)
                      _SwipeBorder(
                        borderKey: ValueKey(
                          'transaction-logbox-delete-border-${widget.record.id}',
                        ),
                        opacity: visual.deleteOpacity,
                        color: AppColors.expense,
                      ),
                    if (visual.filterOpacity > 0)
                      _SwipeBorder(
                        borderKey: ValueKey(
                          'transaction-logbox-filter-border-${widget.record.id}',
                        ),
                        opacity: visual.filterOpacity,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _nameBlock() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            key: ValueKey('transaction-logbox-name-${widget.record.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: _openNameEditor,
            child: Text(
              widget.record.displayMerchant,
              key: ValueKey('transaction-logbox-name-text-${widget.record.id}'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _hasCustomName ? AppColors.gray800 : AppColors.gray500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_hasCustomName && widget.onResetMerchantName != null)
          IconButton(
            key: ValueKey('transaction-name-reset-${widget.record.id}'),
            onPressed: _resetName,
            icon: const Icon(Icons.restart_alt, size: 16),
            color: AppColors.gray500,
            tooltip: 'Eredeti név visszaállítása',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  void _syncSwipeVisual() {
    _swipeVisual.value = _SwipeVisualState(
      dx: _dragDx.clamp(-_maxVisualOffset, _maxVisualOffset).toDouble(),
      deleteOpacity: _borderOpacity(_dragDx > 0 ? _dragDx : 0),
      filterOpacity: _borderOpacity(_dragDx < 0 ? -_dragDx : 0),
    );
  }

  double _borderOpacity(double distance) {
    if (distance <= 0) return 0;
    return (distance / 80).clamp(0.0, 1.0).toDouble();
  }
}

class _SwipeVisualState {
  const _SwipeVisualState({
    required this.dx,
    required this.deleteOpacity,
    required this.filterOpacity,
  });

  static const idle = _SwipeVisualState(
    dx: 0,
    deleteOpacity: 0,
    filterOpacity: 0,
  );

  final double dx;
  final double deleteOpacity;
  final double filterOpacity;
}

class _TransactionNameDialog extends StatefulWidget {
  const _TransactionNameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_TransactionNameDialog> createState() => _TransactionNameDialogState();
}

class _TransactionNameDialogState extends State<_TransactionNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tranzakció név'),
      content: DebugTextField(
        fieldKey: const ValueKey('transaction-name-editor-field'),
        debugLabel: 'TransactionNameDialog.name',
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Megjelenített név',
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        FilledButton(
          key: const ValueKey('transaction-name-editor-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Mentés'),
        ),
      ],
    );
  }
}

class _SwipeBorder extends StatelessWidget {
  const _SwipeBorder({
    required this.borderKey,
    required this.opacity,
    required this.color,
  });

  final Key borderKey;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          key: borderKey,
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}
