import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_console.dart';
import '../data/notification_repository.dart';
import '../models/expense_notification_card.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final now = _clock();
    _selectedMonth = DateTime(now.year, now.month);
  }

  final NotificationRepositoryContract _repository;
  final DateTime Function() _clock;
  late DateTime _selectedMonth;
  var _loading = false;
  String? _error;
  List<ExpenseNotificationCard> _cards = [];

  bool get loading => _loading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  String get selectedMonthKey =>
      '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  List<ExpenseNotificationCard> get cards => List.unmodifiable(_cards);

  List<ExpenseNotificationCard> get visibleCards {
    return _cards
        .where((card) => card.isActive && card.monthKey == selectedMonthKey)
        .toList();
  }

  Map<String, List<ExpenseNotificationCard>> get groupedCards {
    final groups = <String, List<ExpenseNotificationCard>>{};
    for (final card in visibleCards) {
      final key =
          '${card.timestamp.year.toString().padLeft(4, '0')}.${card.timestamp.month.toString().padLeft(2, '0')}.${card.timestamp.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => <ExpenseNotificationCard>[]).add(card);
    }
    return groups;
  }

  Future<void> start() async => _reload();

  Future<void> refresh() async => _reload();

  void shiftMonth(int direction) {
    if (direction == 0) return;
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + direction,
    );
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    await _repository.markRead(id);
    await _reload();
  }

  Future<void> deleteCard(int id) async {
    await _repository.deleteCard(id);
    await _reload();
  }

  Future<void> clearVisibleMonth() async {
    await _repository.clearCards(monthKey: selectedMonthKey);
    await _reload();
  }

  Future<void> _reload() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _repository.listCards();
      rows.sort((left, right) {
        final byTime = right.timestamp.compareTo(left.timestamp);
        return byTime != 0 ? byTime : right.id.compareTo(left.id);
      });
      _cards = rows;
      DebugConsole.log(
        '[Notification] cards reloaded count=${rows.length} '
        'visible=${visibleCards.length} month=$selectedMonthKey',
      );
    } catch (error) {
      _error = error.toString();
      DebugConsole.log('[Notification] cards reload failed: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
