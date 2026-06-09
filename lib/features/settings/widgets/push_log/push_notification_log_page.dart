import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/installed_app.dart';
import '../../../../services/native_bridge.dart';
import '../../../../state/event_store.dart';
import '../../models/push_notification_log_event.dart';
import '../../state/push_notification_log_store.dart';
import 'push_notification_event_sheet.dart';
import 'push_notification_log_box.dart';

class PushNotificationLogPage extends StatefulWidget {
  const PushNotificationLogPage({
    super.key,
    required this.nativeBridge,
    required this.parserStore,
    this.onOpenTransaction,
  });

  final NativeBridge nativeBridge;
  final EventStore parserStore;
  final Future<void> Function(int transactionId)? onOpenTransaction;

  @override
  State<PushNotificationLogPage> createState() =>
      _PushNotificationLogPageState();
}

class _PushNotificationLogPageState extends State<PushNotificationLogPage> {
  late final PushNotificationLogStore _store;
  late final TextEditingController _searchController;
  List<InstalledApp> _installedApps = const <InstalledApp>[];

  @override
  void initState() {
    super.initState();
    _store = PushNotificationLogStore(
      bridge: widget.nativeBridge,
      parserStore: widget.parserStore,
    );
    _searchController = TextEditingController();
    unawaited(_store.loadFirstPage());
    unawaited(_loadInstalledApps());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return Column(
          children: [
            _FilterHeader(
              query: _store.query,
              searchController: _searchController,
              onYearChanged: (year) => unawaited(_setYear(year)),
              onMonthChanged: (month) => unawaited(_setMonth(month)),
              onSearchChanged: (query) => unawaited(_setSearch(query)),
              onStatusChanged: (status) => unawaited(_setStatus(status)),
            ),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_store.loading && _store.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_store.errorText != null && _store.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _store.errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.expense),
          ),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.vertical) {
          return false;
        }
        if (notification.metrics.extentAfter < 320 && _store.hasMore) {
          unawaited(_store.loadMore());
        }
        return false;
      },
      child: ListView.builder(
        key: const ValueKey('push-notification-log-list'),
        itemExtent: 102,
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _store.events.length + (_store.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _store.events.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final event = _store.events[index];
          return PushNotificationLogBox(
            event: event,
            app: _appFor(event.base.packageName),
            onTap: () => unawaited(_openEvent(event)),
          );
        },
      ),
    );
  }

  Future<void> _loadInstalledApps() async {
    final apps = await widget.parserStore.listInstalledApps();
    if (!mounted) return;
    setState(() => _installedApps = apps);
  }

  InstalledApp? _appFor(String packageName) {
    if (packageName.isEmpty) return null;
    for (final app in _installedApps) {
      if (app.packageName == packageName) return app;
    }
    return null;
  }

  Future<void> _setYear(int? year) {
    return _store.setFilters(year: year, month: _store.query.month);
  }

  Future<void> _setMonth(int? month) {
    return _store.setFilters(year: _store.query.year, month: month);
  }

  Future<void> _setSearch(String query) {
    return _store.setFilters(query: query.trim());
  }

  Future<void> _setStatus(PushNotificationLogStatus status) {
    return _store.setFilters(status: status);
  }

  Future<void> _openEvent(PushNotificationLogEvent event) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PushNotificationEventSheet(
        event: event,
        parserStore: widget.parserStore,
        logStore: _store,
        onOpenTransaction: widget.onOpenTransaction,
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.query,
    required this.searchController,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final PushNotificationLogQuery query;
  final TextEditingController searchController;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PushNotificationLogStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearSet = <int?>{null};
    if (query.year != null) yearSet.add(query.year);
    yearSet
      ..add(now.year)
      ..add(now.year - 1)
      ..add(now.year - 2);
    final years = yearSet.toList();

    return Material(
      color: AppColors.gray50,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.gray200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('push-log-search'),
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Keresés',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown<int>(
                    key: const ValueKey('push-log-year-filter'),
                    value: query.year,
                    items: years,
                    labelFor: (year) => year?.toString() ?? 'Év',
                    onChanged: onYearChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown<int>(
                    key: const ValueKey('push-log-month-filter'),
                    value: query.month,
                    items: const <int?>[
                      null,
                      1,
                      2,
                      3,
                      4,
                      5,
                      6,
                      7,
                      8,
                      9,
                      10,
                      11,
                      12,
                    ],
                    labelFor: (month) =>
                        month == null ? 'Hónap' : _monthLabel(month),
                    onChanged: onMonthChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'Összes',
                  status: PushNotificationLogStatus.all,
                  selected: query.status == PushNotificationLogStatus.all,
                  onSelected: onStatusChanged,
                ),
                _StatusChip(
                  label: 'Van tranzakció',
                  status: PushNotificationLogStatus.linked,
                  selected: query.status == PushNotificationLogStatus.linked,
                  onSelected: onStatusChanged,
                ),
                _StatusChip(
                  label: 'Nincs hozzárendelt log',
                  status: PushNotificationLogStatus.missing,
                  selected: query.status == PushNotificationLogStatus.missing,
                  onSelected: onStatusChanged,
                ),
                _StatusChip(
                  label: 'Rendszer',
                  status: PushNotificationLogStatus.system,
                  selected: query.status == PushNotificationLogStatus.system,
                  onSelected: onStatusChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T extends Object> extends StatelessWidget {
  const _FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  final T? value;
  final List<T?> items;
  final String Function(T? value) labelFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
            );
          }).toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.status,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final PushNotificationLogStatus status;
  final bool selected;
  final ValueChanged<PushNotificationLogStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(status),
      selectedColor: AppColors.primaryActiveBackground,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.gray700,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.gray200,
      ),
    );
  }
}

String _monthLabel(int month) {
  return switch (month) {
    1 => 'Január',
    2 => 'Február',
    3 => 'Március',
    4 => 'Április',
    5 => 'Május',
    6 => 'Június',
    7 => 'Július',
    8 => 'Augusztus',
    9 => 'Szeptember',
    10 => 'Október',
    11 => 'November',
    12 => 'December',
    _ => 'Hónap',
  };
}
