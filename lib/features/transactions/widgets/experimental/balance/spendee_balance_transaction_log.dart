import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/transaction_category.dart';
import '../../../models/transaction_record.dart';
import '../../../state/balance_frame.dart';
import '../../category_slot_icon.dart';
import 'spendee_balance_visual_spec.dart';

typedef SpendeeBalanceTransactionContextCallback =
    void Function(TransactionRecord record, TransactionCategory? category);
typedef SpendeeBalanceTransactionDeleteRequest =
    FutureOr<bool> Function(TransactionRecord record);

/// The B3M-A3 date-grouped log surface.
///
/// Visual properties deliberately come from `balance_latest_layout.html`.
/// Only gesture thresholds and dispatch timing are shared with the production
/// [TransactionLogBox] behavior contract.
class SpendeeBalanceTransactionLog extends StatefulWidget {
  const SpendeeBalanceTransactionLog({
    super.key,
    required this.groups,
    required this.categoriesById,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    required this.onEditTransaction,
    this.onRenameMerchantRequested,
    this.onResetMerchantName,
    this.onLoadMore,
    this.hasMore = false,
    this.queryKey,
    this.viewportHeight = 407,
    this.bottomPadding = 0,
    this.scrollController,
  });

  static const cacheExtent = 360.0;
  static const loadMoreThreshold = 320.0;
  static const rowHeight = 50.0;

  final List<BalanceLogGroup> groups;
  final Map<int, TransactionCategory> categoriesById;
  final SpendeeBalanceTransactionContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final SpendeeBalanceTransactionDeleteRequest onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final ValueChanged<TransactionRecord> onEditTransaction;
  final ValueChanged<TransactionRecord>? onRenameMerchantRequested;
  final ValueChanged<TransactionRecord>? onResetMerchantName;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final Object? queryKey;
  final double viewportHeight;
  final double bottomPadding;
  final ScrollController? scrollController;

  @override
  State<SpendeeBalanceTransactionLog> createState() =>
      _SpendeeBalanceTransactionLogState();
}

class _SpendeeBalanceTransactionLogState
    extends State<SpendeeBalanceTransactionLog> {
  late final ScrollController _internalScrollController;
  bool _loadMorePending = false;
  bool _loadMoreScheduled = false;
  int? _lastRequestedRowCount;
  int _queryGeneration = 0;

  ScrollController get _controller =>
      widget.scrollController ?? _internalScrollController;

  int get _rowCount =>
      widget.groups.fold<int>(0, (sum, group) => sum + group.rows.length);

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant SpendeeBalanceTransactionLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRowCount = oldWidget.groups.fold<int>(
      0,
      (sum, group) => sum + group.rows.length,
    );
    if (oldRowCount != _rowCount || oldWidget.hasMore != widget.hasMore) {
      _loadMorePending = false;
      _loadMoreScheduled = false;
      _lastRequestedRowCount = null;
    }
    if (oldWidget.queryKey != widget.queryKey) {
      _queryGeneration += 1;
      _loadMorePending = false;
      _loadMoreScheduled = false;
      _lastRequestedRowCount = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpTo(_controller.position.minScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layouts = _groupLayouts(widget.groups);
    return SizedBox(
      key: const ValueKey('spendee-balance-transaction-section'),
      height: widget.viewportHeight + 16,
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              key: ValueKey('spendee-balance-transaction-heading'),
              height: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TRANZAKCIÓK',
                  semanticsLabel: 'Tranzakciók',
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFF6975A0),
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    fontVariations: SpendeeBalanceVisualSpec.weight950,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              key: const ValueKey('spendee-balance-transaction-viewport'),
              height: widget.viewportHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: layouts.isEmpty
                    ? const _EmptyTransactionLog()
                    : NotificationListener<ScrollNotification>(
                        onNotification: _handleScrollNotification,
                        child: CustomScrollView(
                          controller: _controller,
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Flutter 3.41 still exposes only this legacy name.
                          // ignore: deprecated_member_use
                          cacheExtent: SpendeeBalanceTransactionLog.cacheExtent,
                          semanticChildCount: _rowCount,
                          slivers: [
                            for (
                              var index = 0;
                              index < layouts.length;
                              index += 1
                            )
                              _BalanceTransactionDaySliver(
                                key: ValueKey(
                                  'spendee-balance-transaction-group-${layouts[index].key}',
                                ),
                                layout: layouts[index],
                                showGroupGap: index < layouts.length - 1,
                                categoriesById: widget.categoriesById,
                                onFastFilter: widget.onFastFilter,
                                onRecordTap: widget.onRecordTap,
                                onDeleteRequested: widget.onDeleteRequested,
                                onCategoryFilter: widget.onCategoryFilter,
                                onEditTransaction: widget.onEditTransaction,
                                onRenameMerchantRequested:
                                    widget.onRenameMerchantRequested,
                                onResetMerchantName: widget.onResetMerchantName,
                              ),
                            if (widget.bottomPadding > 0)
                              SliverToBoxAdapter(
                                child: SizedBox(height: widget.bottomPadding),
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
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final rowCount = _rowCount;
    if (notification is ScrollEndNotification && _loadMorePending) {
      _scheduleLoadMore(rowCount);
      return false;
    }
    if (!_canRequestLoadMore(rowCount, notification.metrics)) return false;
    _loadMorePending = true;
    _lastRequestedRowCount = rowCount;
    if (notification is ScrollEndNotification) {
      _scheduleLoadMore(rowCount);
    }
    return false;
  }

  bool _canRequestLoadMore(int rowCount, ScrollMetrics metrics) {
    return widget.hasMore &&
        widget.onLoadMore != null &&
        metrics.extentAfter < SpendeeBalanceTransactionLog.loadMoreThreshold &&
        !_loadMoreScheduled &&
        !_loadMorePending &&
        _lastRequestedRowCount != rowCount;
  }

  void _scheduleLoadMore(int requestedRowCount) {
    if (_loadMoreScheduled) return;
    _loadMoreScheduled = true;
    final requestedGeneration = _queryGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestedGeneration != _queryGeneration) return;
      _loadMoreScheduled = false;
      _loadMorePending = false;
      if (!widget.hasMore || requestedRowCount != _rowCount) return;
      widget.onLoadMore?.call();
    });
  }
}

class _EmptyTransactionLog extends StatelessWidget {
  const _EmptyTransactionLog();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(
            color: Color(0xFF7D88A4),
            fontSize: 9,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

List<_BalanceGroupLayout> _groupLayouts(List<BalanceLogGroup> groups) {
  final layouts = <_BalanceGroupLayout>[];
  var colorIndex = 0;
  for (final group in groups) {
    if (group.rows.isEmpty) continue;
    layouts.add(
      _BalanceGroupLayout(
        group: group,
        key: _dateKey(group.date),
        firstColorIndex: colorIndex,
      ),
    );
    colorIndex += group.rows.length;
  }
  return layouts;
}

class _BalanceGroupLayout {
  const _BalanceGroupLayout({
    required this.group,
    required this.key,
    required this.firstColorIndex,
  });

  final BalanceLogGroup group;
  final String key;
  final int firstColorIndex;
}

class _BalanceTransactionDaySliver extends StatelessWidget {
  const _BalanceTransactionDaySliver({
    super.key,
    required this.layout,
    required this.showGroupGap,
    required this.categoriesById,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    required this.onEditTransaction,
    required this.onRenameMerchantRequested,
    required this.onResetMerchantName,
  });

  final _BalanceGroupLayout layout;
  final bool showGroupGap;
  final Map<int, TransactionCategory> categoriesById;
  final SpendeeBalanceTransactionContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final SpendeeBalanceTransactionDeleteRequest onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final ValueChanged<TransactionRecord> onEditTransaction;
  final ValueChanged<TransactionRecord>? onRenameMerchantRequested;
  final ValueChanged<TransactionRecord>? onResetMerchantName;

  @override
  Widget build(BuildContext context) {
    final group = layout.group;
    return SliverMainAxisGroup(
      key: ValueKey('spendee-balance-transaction-day-${layout.key}'),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: ValueKey(
                    'spendee-balance-transaction-day-title-${layout.key}',
                  ),
                  height: 15,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
                    child: _DateTitleText(group.date),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
        DecoratedSliver(
          key: ValueKey(
            'spendee-balance-transaction-day-decoration-${layout.key}',
          ),
          decoration: BoxDecoration(
            color: const Color(0xF5FFFFFF),
            border: Border.all(color: const Color(0x1A666FAB)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14524B93),
                offset: Offset(0, 9),
                blurRadius: 19,
              ),
              BoxShadow(
                color: Color(0xF5FFFFFF),
                offset: Offset(0, 1),
                blurRadius: 0,
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          sliver: SliverPadding(
            key: ValueKey('spendee-balance-transaction-day-card-${layout.key}'),
            padding: const EdgeInsets.all(1),
            sliver: SliverFixedExtentList.builder(
              itemExtent: SpendeeBalanceTransactionLog.rowHeight,
              itemCount: group.rows.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
              itemBuilder: (context, index) {
                final row = group.rows[index];
                return _BalanceTransactionRow(
                  key: ValueKey(
                    'spendee-balance-transaction-state-${_rowToken(row)}',
                  ),
                  row: row,
                  category: _categoryFor(row, categoriesById),
                  avatarColor:
                      _transactionColors[(layout.firstColorIndex + index) %
                          _transactionColors.length],
                  showSeparator: index > 0,
                  isFirst: index == 0,
                  isLast: index == group.rows.length - 1,
                  onFastFilter: onFastFilter,
                  onRecordTap: onRecordTap,
                  onDeleteRequested: onDeleteRequested,
                  onCategoryFilter: onCategoryFilter,
                  onEditTransaction: onEditTransaction,
                  onRenameMerchantRequested: onRenameMerchantRequested,
                  onResetMerchantName: onResetMerchantName,
                );
              },
            ),
          ),
        ),
        if (showGroupGap) const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    );
  }
}

class _DateTitleText extends StatelessWidget {
  const _DateTitleText(this.date);

  final String date;

  @override
  Widget build(BuildContext context) {
    return Text(
      date,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 8,
        height: 1,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BalanceTransactionRow extends StatefulWidget {
  const _BalanceTransactionRow({
    super.key,
    required this.row,
    required this.category,
    required this.avatarColor,
    required this.showSeparator,
    required this.isFirst,
    required this.isLast,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    required this.onEditTransaction,
    required this.onRenameMerchantRequested,
    required this.onResetMerchantName,
  });

  final BalanceLogRow row;
  final TransactionCategory? category;
  final Color avatarColor;
  final bool showSeparator;
  final bool isFirst;
  final bool isLast;
  final SpendeeBalanceTransactionContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final SpendeeBalanceTransactionDeleteRequest onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final ValueChanged<TransactionRecord> onEditTransaction;
  final ValueChanged<TransactionRecord>? onRenameMerchantRequested;
  final ValueChanged<TransactionRecord>? onResetMerchantName;

  @override
  State<_BalanceTransactionRow> createState() => _BalanceTransactionRowState();
}

class _BalanceTransactionRowState extends State<_BalanceTransactionRow> {
  static const _maxVisualOffset = 44.0;
  static const _filterThreshold = -80.0;
  static const _deleteThreshold = 70.0;
  static const _flingVelocityThreshold = 800.0;

  late final ValueNotifier<double> _visualOffset;
  double _dragDx = 0;
  bool _triggered = false;
  bool _deletePending = false;
  bool _deleteFrozen = false;

  TransactionRecord? get _record => widget.row.record;
  String get _token => _rowToken(widget.row);

  @override
  void initState() {
    super.initState();
    _visualOffset = ValueNotifier<double>(0);
  }

  @override
  void dispose() {
    _visualOffset.dispose();
    super.dispose();
  }

  void _startDrag() {
    if (_deletePending || _deleteFrozen) return;
    _dragDx = 0;
    _triggered = false;
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_triggered || _deletePending || _deleteFrozen) return;
    _dragDx += details.delta.dx;
    _visualOffset.value = _dragDx
        .clamp(-_maxVisualOffset, _maxVisualOffset)
        .toDouble();
    final record = _record;
    if (_dragDx < _filterThreshold && record != null) {
      _triggered = true;
      widget.onFastFilter(record, widget.category);
      return;
    }
    if (_dragDx > _deleteThreshold && record != null) {
      _triggerDelete(record);
    }
  }

  void _endDrag(DragEndDetails details) {
    if (_deleteFrozen) return;
    final record = _record;
    final velocity = details.primaryVelocity ?? 0;
    if (!_triggered && velocity <= -_flingVelocityThreshold && record != null) {
      _triggered = true;
      widget.onFastFilter(record, widget.category);
      _resetDrag();
      return;
    }
    if (!_triggered && velocity >= _flingVelocityThreshold && record != null) {
      _triggerDelete(record);
      return;
    }
    if (!_triggered && _dragDx > _deleteThreshold && record != null) {
      _triggerDelete(record);
      return;
    }
    _resetDrag();
  }

  void _triggerDelete(TransactionRecord record) {
    if (_deletePending || _deleteFrozen) return;
    _triggered = true;
    _deletePending = true;
    _deleteFrozen = true;
    _visualOffset.value = _maxVisualOffset;
    unawaited(_requestDelete(record));
  }

  Future<void> _requestDelete(TransactionRecord record) async {
    final confirmed = await widget.onDeleteRequested(record);
    if (!mounted) return;
    if (confirmed) {
      _deletePending = false;
      return;
    }
    _resetDrag();
  }

  void _resetDrag() {
    _dragDx = 0;
    _triggered = false;
    _deletePending = false;
    _deleteFrozen = false;
    if (!mounted) return;
    _visualOffset.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final merchant = widget.row.merchant;
    final categoryName =
        widget.category?.name ??
        widget.row.ghost?.categoryName ??
        'Nincs kategória';
    final amount = widget.row.amountText;
    final time =
        record?.displayTime ?? widget.row.ghost?.displayTime ?? widget.row.time;
    final semanticAmount = amount;
    final hasCustomName = record?.userAssignedName?.trim().isNotEmpty ?? false;
    final rowActions = <CustomSemanticsAction, VoidCallback>{};
    final onRecordActivate = record == null
        ? null
        : () => widget.onRecordTap(record);
    if (record != null) {
      rowActions[_fastFilterSemanticsAction] = () {
        widget.onFastFilter(record, widget.category);
      };
      rowActions[_deleteSemanticsAction] = () => _triggerDelete(record);
      _addCustomSemanticsAction(
        rowActions,
        _renameSemanticsAction,
        widget.onRenameMerchantRequested == null
            ? null
            : () => widget.onRenameMerchantRequested!(record),
      );
      _addCustomSemanticsAction(
        rowActions,
        _resetNameSemanticsAction,
        !hasCustomName || widget.onResetMerchantName == null
            ? null
            : () => widget.onResetMerchantName!(record),
      );
    }

    return _BalanceKeyboardTapTarget(
      onActivate: onRecordActivate,
      shortcuts: record == null
          ? const <ShortcutActivator, VoidCallback>{}
          : <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.delete): () =>
                  _triggerDelete(record),
              const SingleActivator(LogicalKeyboardKey.keyF): () =>
                  widget.onFastFilter(record, widget.category),
              if (widget.onRenameMerchantRequested != null)
                const SingleActivator(LogicalKeyboardKey.keyR): () =>
                    widget.onRenameMerchantRequested!(record),
              if (hasCustomName && widget.onResetMerchantName != null)
                const SingleActivator(
                  LogicalKeyboardKey.keyR,
                  shift: true,
                ): () =>
                    widget.onResetMerchantName!(record),
            },
      child: GestureDetector(
        key: ValueKey('spendee-balance-transaction-row-$_token'),
        behavior: HitTestBehavior.opaque,
        onTap: onRecordActivate,
        onHorizontalDragStart: (_) => _startDrag(),
        onHorizontalDragUpdate: _updateDrag,
        onHorizontalDragCancel: _deleteFrozen ? null : _resetDrag,
        onHorizontalDragEnd: _endDrag,
        child: SizedBox(
          height: SpendeeBalanceTransactionLog.rowHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: widget.isFirst ? const Radius.circular(17) : Radius.zero,
              bottom: widget.isLast ? const Radius.circular(17) : Radius.zero,
            ),
            child: ValueListenableBuilder<double>(
              valueListenable: _visualOffset,
              child: Semantics(
                key: ValueKey('spendee-balance-transaction-semantics-$_token'),
                container: true,
                explicitChildNodes: true,
                button: onRecordActivate != null,
                onTap: onRecordActivate,
                label: '$merchant, $categoryName, $semanticAmount, $time',
                customSemanticsActions: rowActions,
                child: _BalanceTransactionRowContents(
                  token: _token,
                  merchant: merchant,
                  categoryName: categoryName,
                  amount: amount,
                  time: time,
                  category: widget.category,
                  avatarColor: widget.avatarColor,
                  showSeparator: widget.showSeparator,
                  hasCustomName: hasCustomName,
                  onCategoryFilter: widget.category == null
                      ? null
                      : () => widget.onCategoryFilter(widget.category!),
                  onEdit: record == null
                      ? null
                      : () => widget.onEditTransaction(record),
                  onRename:
                      record == null || widget.onRenameMerchantRequested == null
                      ? null
                      : () => widget.onRenameMerchantRequested!(record),
                  onReset:
                      record == null ||
                          !hasCustomName ||
                          widget.onResetMerchantName == null
                      ? null
                      : () => widget.onResetMerchantName!(record),
                ),
              ),
              builder: (context, dx, child) {
                return Transform.translate(
                  key: ValueKey(
                    'spendee-balance-transaction-transform-$_token',
                  ),
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceTransactionRowContents extends StatelessWidget {
  const _BalanceTransactionRowContents({
    required this.token,
    required this.merchant,
    required this.categoryName,
    required this.amount,
    required this.time,
    required this.category,
    required this.avatarColor,
    required this.showSeparator,
    required this.hasCustomName,
    required this.onCategoryFilter,
    required this.onEdit,
    required this.onRename,
    required this.onReset,
  });

  final String token;
  final String merchant;
  final String categoryName;
  final String amount;
  final String time;
  final TransactionCategory? category;
  final Color avatarColor;
  final bool showSeparator;
  final bool hasCustomName;
  final VoidCallback? onCategoryFilter;
  final VoidCallback? onEdit;
  final VoidCallback? onRename;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showSeparator)
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: ValueKey('spendee-balance-transaction-separator-$token'),
              width: double.infinity,
              height: 1,
              child: const ColoredBox(color: Color(0xFFEFF1F7)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              _BalanceTransactionAvatar(
                token: token,
                category: category,
                color: avatarColor,
                onTap: onCategoryFilter,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _BalanceTransactionCopy(
                  token: token,
                  merchant: merchant,
                  categoryName: categoryName,
                  hasCustomName: hasCustomName,
                  onRename: onRename,
                  onReset: onReset,
                ),
              ),
              const SizedBox(width: 9),
              _BalanceTransactionValue(amount: amount, time: time),
              const SizedBox(width: 9),
              _BalanceEditButton(
                token: token,
                merchant: merchant,
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceTransactionAvatar extends StatelessWidget {
  const _BalanceTransactionAvatar({
    required this.token,
    required this.category,
    required this.color,
    required this.onTap,
  });

  final String token;
  final TransactionCategory? category;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconSlot = category?.iconSlot ?? 0;
    return Semantics(
      button: onTap != null,
      label: category == null ? 'Nincs kategória' : '${category!.name} szűrése',
      onTap: onTap,
      excludeSemantics: true,
      child: _BalanceKeyboardTapTarget(
        onActivate: onTap,
        child: GestureDetector(
          key: ValueKey('spendee-balance-transaction-avatar-$token'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x61FFFFFF),
                  offset: Offset(0, 1),
                  blurRadius: 0,
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: Color(0x1A524B93),
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: 31,
              child: Center(
                child: CategorySlotIcon(
                  slot: iconSlot,
                  color: Colors.white,
                  size: 16,
                  listenForSlotChanges: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceTransactionCopy extends StatelessWidget {
  const _BalanceTransactionCopy({
    required this.token,
    required this.merchant,
    required this.categoryName,
    required this.hasCustomName,
    required this.onRename,
    required this.onReset,
  });

  final String token;
  final String merchant;
  final String categoryName;
  final bool hasCustomName;
  final VoidCallback? onRename;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final reset = hasCustomName ? onReset : null;
    return SizedBox(
      height: 21,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: reset == null ? 0 : 16,
            top: 0,
            height: 9,
            child: _BalanceMerchantRenameTarget(
              token: token,
              merchant: merchant,
              onPressed: onRename,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 14,
            height: 7,
            child: ExcludeSemantics(
              child: GestureDetector(
                key: ValueKey('spendee-balance-transaction-category-$token'),
                behavior: HitTestBehavior.opaque,
                onLongPress: reset,
                child: Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D88A4),
                    fontSize: 7,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    fontVariations: SpendeeBalanceVisualSpec.weight750,
                  ),
                ),
              ),
            ),
          ),
          if (reset != null)
            Positioned(
              right: 0,
              top: 0,
              width: 14,
              height: 14,
              child: _BalanceMerchantResetButton(
                token: token,
                merchant: merchant,
                onPressed: reset,
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceMerchantRenameTarget extends StatefulWidget {
  const _BalanceMerchantRenameTarget({
    required this.token,
    required this.merchant,
    required this.onPressed,
  });

  final String token;
  final String merchant;
  final VoidCallback? onPressed;

  @override
  State<_BalanceMerchantRenameTarget> createState() =>
      _BalanceMerchantRenameTargetState();
}

class _BalanceMerchantRenameTargetState
    extends State<_BalanceMerchantRenameTarget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    final name = widget.merchant;
    final copy = Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1D2B50),
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (onPressed != null) ...[
          const SizedBox(width: 2),
          SvgPicture.asset(
            'assets/icons/lucide/pencil.svg',
            key: ValueKey(
              'spendee-balance-transaction-rename-glyph-${widget.token}',
            ),
            width: 7,
            height: 7,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFF7D8798),
              BlendMode.srcIn,
            ),
          ),
        ],
      ],
    );
    if (onPressed == null) {
      return ExcludeSemantics(
        child: GestureDetector(
          key: ValueKey('spendee-balance-transaction-merchant-${widget.token}'),
          behavior: HitTestBehavior.opaque,
          child: copy,
        ),
      );
    }
    final label = '$name kereskedő átnevezése';
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: _BalanceKeyboardTapTarget(
        onActivate: onPressed,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Semantics(
          key: ValueKey('spendee-balance-transaction-rename-${widget.token}'),
          button: true,
          enabled: true,
          label: label,
          onTap: onPressed,
          excludeSemantics: true,
          child: GestureDetector(
            key: ValueKey(
              'spendee-balance-transaction-merchant-${widget.token}',
            ),
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            onLongPress: onPressed,
            child: CustomPaint(
              foregroundPainter: _focused
                  ? const _BalanceInlineActionFocusOutlinePainter()
                  : null,
              child: copy,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceMerchantResetButton extends StatefulWidget {
  const _BalanceMerchantResetButton({
    required this.token,
    required this.merchant,
    required this.onPressed,
  });

  final String token;
  final String merchant;
  final VoidCallback onPressed;

  @override
  State<_BalanceMerchantResetButton> createState() =>
      _BalanceMerchantResetButtonState();
}

class _BalanceMerchantResetButtonState
    extends State<_BalanceMerchantResetButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final label = '${widget.merchant} eredeti nevének visszaállítása';
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: _BalanceKeyboardTapTarget(
        onActivate: widget.onPressed,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Semantics(
          key: ValueKey('spendee-balance-transaction-reset-${widget.token}'),
          button: true,
          enabled: true,
          label: label,
          onTap: widget.onPressed,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: CustomPaint(
              foregroundPainter: _focused
                  ? const _BalanceInlineActionFocusOutlinePainter()
                  : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x147D8798),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SizedBox.square(
                  dimension: 14,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/lucide/rotate-ccw.svg',
                      key: ValueKey(
                        'spendee-balance-transaction-reset-glyph-${widget.token}',
                      ),
                      width: 10,
                      height: 10,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7D8798),
                        BlendMode.srcIn,
                      ),
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

class _BalanceInlineActionFocusOutlinePainter extends CustomPainter {
  const _BalanceInlineActionFocusOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0x6B7D8798)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-1, -1, size.width + 1, size.height + 1),
        const Radius.circular(4),
      ),
      outline,
    );
  }

  @override
  bool shouldRepaint(
    covariant _BalanceInlineActionFocusOutlinePainter oldDelegate,
  ) => false;
}

class _BalanceTransactionValue extends StatelessWidget {
  const _BalanceTransactionValue({required this.amount, required this.time});

  final String amount;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 9,
            child: Text(
              amount,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFFF3E73),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w900,
                fontVariations: SpendeeBalanceVisualSpec.weight950,
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 7,
            child: Text(
              time,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF7D88A4),
                fontSize: 7,
                height: 1,
                fontWeight: FontWeight.w800,
                fontVariations: SpendeeBalanceVisualSpec.weight750,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceEditButton extends StatefulWidget {
  const _BalanceEditButton({
    required this.token,
    required this.merchant,
    required this.onPressed,
  });

  final String token;
  final String merchant;
  final VoidCallback? onPressed;

  @override
  State<_BalanceEditButton> createState() => _BalanceEditButtonState();
}

class _BalanceEditButtonState extends State<_BalanceEditButton> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${widget.merchant} tranzakció szerkesztése',
      child: Semantics(
        button: true,
        enabled: widget.onPressed != null,
        label: '${widget.merchant} tranzakció szerkesztése',
        onTap: widget.onPressed,
        excludeSemantics: true,
        child: _BalanceKeyboardTapTarget(
          onActivate: widget.onPressed,
          onFocusChange: (value) => setState(() => _focused = value),
          child: Listener(
            key: ValueKey('spendee-balance-transaction-edit-${widget.token}'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.onPressed == null
                ? null
                : (_) => _setPressed(true),
            onPointerUp: widget.onPressed == null
                ? null
                : (_) => _setPressed(false),
            onPointerCancel: widget.onPressed == null
                ? null
                : (_) => _setPressed(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: Transform.scale(
                key: ValueKey(
                  'spendee-balance-transaction-edit-transform-${widget.token}',
                ),
                scale: _pressed ? .92 : 1,
                child: CustomPaint(
                  key: ValueKey(
                    'spendee-balance-transaction-edit-focus-${widget.token}',
                  ),
                  foregroundPainter: _focused
                      ? const _BalanceEditFocusOutlinePainter()
                      : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x1A7D8798),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: SizedBox.square(
                      dimension: 22,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/lucide/pencil.svg',
                          width: 12,
                          height: 12,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF7D8798),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
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

class _BalanceEditFocusOutlinePainter extends CustomPainter {
  const _BalanceEditFocusOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0x6B7D8798)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-2, -2, size.width + 2, size.height + 2),
        const Radius.circular(9),
      ),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceEditFocusOutlinePainter oldDelegate) =>
      false;
}

class _BalanceKeyboardTapTarget extends StatelessWidget {
  const _BalanceKeyboardTapTarget({
    required this.onActivate,
    required this.child,
    this.onFocusChange,
    this.shortcuts = const <ShortcutActivator, VoidCallback>{},
  });

  final VoidCallback? onActivate;
  final ValueChanged<bool>? onFocusChange;
  final Map<ShortcutActivator, VoidCallback> shortcuts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final callback = onActivate;
    final bindings = <ShortcutActivator, VoidCallback>{
      if (callback != null) ...<ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): callback,
        const SingleActivator(LogicalKeyboardKey.space): callback,
      },
      ...shortcuts,
    };
    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        canRequestFocus: bindings.isNotEmpty,
        skipTraversal: bindings.isEmpty,
        onFocusChange: onFocusChange,
        child: child,
      ),
    );
  }
}

const _transactionColors = <Color>[
  Color(0xFFFF4B78),
  Color(0xFF42CF82),
  Color(0xFF7858F4),
  Color(0xFFF49B36),
  Color(0xFF16B9D4),
];

const _fastFilterSemanticsAction = CustomSemanticsAction(
  label: 'Kereskedő gyorsszűrése',
);
const _deleteSemanticsAction = CustomSemanticsAction(
  label: 'Tranzakció törlése',
);
const _renameSemanticsAction = CustomSemanticsAction(
  label: 'Kereskedő átnevezése',
);
const _resetNameSemanticsAction = CustomSemanticsAction(
  label: 'Eredeti név visszaállítása',
);

TransactionCategory? _categoryFor(
  BalanceLogRow row,
  Map<int, TransactionCategory> categoriesById,
) {
  final categoryId = row.record?.transactionCategoryID ?? row.ghost?.categoryId;
  return categoryId == null ? null : categoriesById[categoryId];
}

String _rowToken(BalanceLogRow row) =>
    '${row.isGhost ? 'ghost' : 'record'}-${row.sortId}';

String _dateKey(String date) {
  return date
      .trim()
      .replaceAll(RegExp(r'[./]+'), '-')
      .replaceAll(RegExp(r'-+$'), '');
}

void _addCustomSemanticsAction(
  Map<CustomSemanticsAction, VoidCallback> actions,
  CustomSemanticsAction action,
  VoidCallback? callback,
) {
  if (callback != null) actions[action] = callback;
}
