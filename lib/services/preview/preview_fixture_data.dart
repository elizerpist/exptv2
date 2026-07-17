import '../../features/settings/models/app_theme_settings.dart';
import '../../features/settings/models/fast_info_config.dart';
import '../../features/settings/models/notification_parser_rule.dart';
import '../../features/settings/models/notification_settings.dart';
import '../../features/settings/models/security_settings.dart';
import '../../features/transactions/models/recurring_rule.dart';

class PreviewFixtureData {
  const PreviewFixtureData({
    required this.categories,
    required this.transactions,
    required this.limits,
    required this.recurringTransactions,
    required this.recurringRules,
    required this.recurringGhosts,
    required this.notificationCards,
    required this.notificationEvents,
    required this.pushLogEvents,
    required this.statsSnapshots,
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.pushRecurringSettings,
    required this.notificationSettings,
    required this.securitySettings,
    required this.notificationParserConfig,
  });

  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> transactions;
  final List<Map<String, Object?>> limits;
  final List<Map<String, Object?>> recurringTransactions;
  final List<Map<String, Object?>> recurringRules;
  final List<Map<String, Object?>> recurringGhosts;
  final List<Map<String, Object?>> notificationCards;
  final List<Map<String, Object?>> notificationEvents;
  final List<Map<String, Object?>> pushLogEvents;
  final List<Map<String, Object?>> statsSnapshots;
  final Map<String, Object?> themeSettings;
  final Map<String, Object?> fastInfoConfig;
  final Map<String, Object?> pushRecurringSettings;
  final Map<String, Object?> notificationSettings;
  final Map<String, Object?> securitySettings;
  final Map<String, Object?> notificationParserConfig;
}

PreviewFixtureData buildPreviewFixtureData(DateTime now) {
  final currentMonth = DateTime(now.year, now.month);
  final adjacentMonth = DateTime(now.year, now.month - 1);
  final priorYearMonth = DateTime(now.year - 1, now.month);
  final timestamp = DateTime(
    now.year,
    now.month,
    now.day,
    12,
  ).millisecondsSinceEpoch;

  final categories = <Map<String, Object?>>[
    _category(1, 'Élelmiszer', 'kiadás', 1, 3, '#10b981'),
    _category(2, 'Közlekedés', 'kiadás', 4, 4, '#3b82f6'),
    _category(3, 'Előfizetések', 'kiadás', 5, 5, '#8b5cf6'),
    _category(4, 'Otthon', 'kiadás', 8, 6, '#f59e0b'),
    _category(5, 'Szórakozás', 'kiadás', 11, 7, '#ec4899'),
    _category(6, 'Egyéb', 'kiadás', 15, 2, '#64748b'),
    _category(7, 'Fizetés', 'bevétel', 2, 0, '#22c55e'),
    _category(8, 'Egyéb bevétel', 'bevétel', 6, 1, '#06b6d4'),
  ];

  final currentTransactions = <Map<String, Object?>>[
    _transaction(1, currentMonth, 2, 'Tesco', -18240, 1, '09:12:00'),
    _transaction(2, currentMonth, 3, 'BKK', -8950, 2, '07:30:00'),
    _transaction(3, currentMonth, 4, 'Netflix', -3490, 3, '19:20:00'),
    _transaction(4, currentMonth, 6, 'Lidl', -12680, 1, '16:45:00'),
    _transaction(5, currentMonth, 7, 'Fizetés', 645000, 7, '08:00:00'),
    _transaction(6, currentMonth, 9, 'MVM', -18450, 4, '10:10:00'),
    _transaction(7, currentMonth, 11, 'Cinema City', -7200, 5, '20:05:00'),
    _transaction(8, currentMonth, 12, 'Tesco', -9340, 1, '18:22:00'),
    _transaction(9, currentMonth, 14, 'MOL', -21500, 2, '14:15:00'),
    _transaction(10, currentMonth, 15, 'Spotify', -2190, 3, '06:40:00'),
    _transaction(11, currentMonth, 17, 'Lidl', -15760, 1, '17:18:00'),
    _transaction(12, currentMonth, 18, 'Visszatérítés', 12500, 8, '11:05:00'),
  ];
  final adjacentTransactions = <Map<String, Object?>>[
    _transaction(13, adjacentMonth, 5, 'Tesco', -15320, 1, '12:10:00'),
    _transaction(14, adjacentMonth, 10, 'BKK', -8950, 2, '07:30:00'),
    _transaction(15, adjacentMonth, 18, 'Netflix', -3490, 3, '19:20:00'),
    _transaction(16, adjacentMonth, 27, 'Fizetés', 625000, 7, '08:00:00'),
  ];
  final priorYearTransactions = <Map<String, Object?>>[
    _transaction(17, priorYearMonth, 4, 'Tesco', -14210, 1, '13:02:00'),
    _transaction(18, priorYearMonth, 9, 'BKK', -8950, 2, '07:30:00'),
    _transaction(19, priorYearMonth, 20, 'Netflix', -3490, 3, '19:20:00'),
    _transaction(20, priorYearMonth, 28, 'Fizetés', 570000, 7, '08:00:00'),
  ];

  final recurringTransactions = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'name': 'Netflix',
      'amount': 3490.0,
      'transactionType': 'expense',
      'dayOfMonth': 4,
      'categoryId': 3,
      'categoryName': 'Előfizetések',
      'categoryColor': '#8b5cf6',
      'categoryIconSlot': 5,
      'isActive': true,
      'lastProcessedPeriodKey': null,
      'lastProcessedAt': null,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    },
    <String, Object?>{
      'id': 2,
      'name': 'Fizetés',
      'amount': 645000.0,
      'transactionType': 'income',
      'dayOfMonth': 7,
      'categoryId': 7,
      'categoryName': 'Fizetés',
      'categoryColor': '#22c55e',
      'categoryIconSlot': 0,
      'isActive': true,
      'lastProcessedPeriodKey': _periodKey(adjacentMonth),
      'lastProcessedAt': timestamp,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    },
  ];

  final recurringRules = <Map<String, Object?>>[
    _recurringRule(
      id: 1,
      triggerType: 'date',
      transactionType: 'expense',
      name: 'Netflix',
      amount: 3490,
      day: 4,
      categoryId: 3,
      categoryName: 'Előfizetések',
      categoryColor: '#8b5cf6',
      categoryIconSlot: 5,
      timestamp: timestamp,
    ),
    _recurringRule(
      id: 2,
      triggerType: 'push',
      transactionType: 'expense',
      name: 'BKK bérlet',
      amount: 8950,
      day: 3,
      categoryId: 2,
      categoryName: 'Közlekedés',
      categoryColor: '#3b82f6',
      categoryIconSlot: 4,
      timestamp: timestamp,
      packageName: 'hu.bkk.futar',
      appLabel: 'BudapestGO',
      sampleText: 'Sikeres vásárlás: 8 950 Ft BKK',
      includeKeyword: 'Sikeres vásárlás',
    ),
  ];

  final triggerDate = _dateWithClampedDay(currentMonth, 22);
  final recurringGhosts = <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'recurringTransactionId': 1,
      'periodKey': _periodKey(currentMonth),
      'name': 'Netflix',
      'amount': 3490.0,
      'triggerTypeSnapshot': 'date',
      'transactionType': 'expense',
      'date': _formatDate(triggerDate),
      'time': '08:00',
      'categoryId': 3,
      'categoryName': 'Előfizetések',
      'categoryColor': '#8b5cf6',
      'categoryIconSlot': 5,
      'triggerMillis': triggerDate.millisecondsSinceEpoch,
      'isActivated': false,
      'activatedTransactionId': null,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    },
  ];

  final events = <Map<String, Object?>>[
    _event(
      1,
      timestamp - 3600000,
      'Revolut',
      'Kártyás vásárlás',
      'Tesco - 18 240 Ft',
    ),
    _event(
      2,
      timestamp - 7200000,
      'BudapestGO',
      'Sikeres vásárlás',
      'BKK - 8 950 Ft',
    ),
    _event(
      3,
      timestamp - 10800000,
      'Simple',
      'Sikeres fizetés',
      'Netflix - 3 490 Ft',
    ),
  ];
  final pushEvents = <Map<String, Object?>>[
    <String, Object?>{
      ...events[0],
      'displayText': 'Tesco - 18 240 Ft',
      'status': 'linked',
      'statusText': 'Van tranzakció',
      'linkedTransactionId': 1,
      'manualStatus': '',
    },
    <String, Object?>{
      ...events[1],
      'displayText': 'BKK - 8 950 Ft',
      'status': 'missing',
      'statusText': 'Nincs hozzárendelt log',
      'linkedTransactionId': null,
      'manualStatus': '',
    },
    <String, Object?>{
      ...events[2],
      'displayText': 'Netflix - 3 490 Ft',
      'status': 'system',
      'statusText': 'Rendszer',
      'linkedTransactionId': null,
      'manualStatus': 'system',
    },
  ];

  return PreviewFixtureData(
    categories: categories,
    transactions: <Map<String, Object?>>[
      ...currentTransactions,
      ...adjacentTransactions,
      ...priorYearTransactions,
    ],
    limits: <Map<String, Object?>>[
      _limit(
        1,
        'overview',
        0,
        'expense',
        'monthly',
        _periodKey(currentMonth),
        180000,
        timestamp,
      ),
      _limit(
        2,
        'category',
        1,
        'expense',
        'monthly',
        _periodKey(currentMonth),
        85000,
        timestamp,
      ),
      _limit(
        3,
        'overview',
        0,
        'income',
        'monthly',
        _periodKey(currentMonth),
        600000,
        timestamp,
      ),
    ],
    recurringTransactions: recurringTransactions,
    recurringRules: recurringRules,
    recurringGhosts: recurringGhosts,
    notificationCards: <Map<String, Object?>>[
      _card(
        1,
        timestamp - 1800000,
        'transaction_created',
        'Új tranzakció',
        'Tesco: 18 240 Ft',
        transactionId: 1,
        categoryId: 1,
        categoryName: 'Élelmiszer',
        categoryColor: '#10b981',
        categoryIconSlot: 3,
        amount: 18240,
      ),
      _card(
        2,
        timestamp - 5400000,
        'recurring_transaction_alert',
        'Közelgő ismétlődés',
        'A Netflix hamarosan esedékes.',
        recurringTransactionId: 1,
        categoryId: 3,
        categoryName: 'Előfizetések',
        categoryColor: '#8b5cf6',
        categoryIconSlot: 5,
        amount: 3490,
      ),
      _card(
        3,
        timestamp - 9000000,
        'limit_75',
        'Keretjelzés',
        'Az élelmiszer keret 75%-a elfogyott.',
        categoryId: 1,
        categoryName: 'Élelmiszer',
        categoryColor: '#10b981',
        categoryIconSlot: 3,
        isRead: true,
      ),
    ],
    notificationEvents: events,
    pushLogEvents: pushEvents,
    statsSnapshots: <Map<String, Object?>>[
      <String, Object?>{
        'id': 1,
        'name': 'Havi áttekintés',
        'year': now.year,
        'month': now.month,
        'transactionType': 'expense',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      },
    ],
    themeSettings: AppThemeSettings.defaults().toMap(),
    fastInfoConfig: FastInfoConfig.defaults().toMap(),
    pushRecurringSettings: PushRecurringSettings.defaults().toMap(),
    notificationSettings: NotificationSettings.defaults().toMap(),
    securitySettings: SecuritySettings.defaults().toMap(),
    notificationParserConfig: NotificationParserConfig.defaults().toMap(),
  );
}

Map<String, Object?> _category(
  int id,
  String name,
  String type,
  int colorSlot,
  int iconSlot,
  String color,
) => <String, Object?>{
  'transactionCategoryID': id,
  'name': name,
  'type': type,
  'colorSlot': colorSlot,
  'iconSlot': iconSlot,
  'backgroundColor': color,
  'icon': null,
  'notification': null,
  'hasLimit': false,
  'limitAmount': 0.0,
  'alertActive': false,
  'isCustomIcon': true,
  'originalIcon': null,
};

Map<String, Object?> _transaction(
  int id,
  DateTime month,
  int day,
  String merchant,
  num amount,
  int categoryId,
  String time,
) => <String, Object?>{
  'id': id,
  'date': _formatDate(_dateWithClampedDay(month, day)),
  'time': time,
  'latitude': null,
  'longitude': null,
  'address': null,
  'merchant': merchant,
  'amount': amount.toDouble(),
  'userAssignedName': null,
  'transactionCategoryID': categoryId,
};

Map<String, Object?> _limit(
  int id,
  String targetType,
  int targetId,
  String transactionType,
  String window,
  String periodKey,
  num amount,
  int timestamp,
) => <String, Object?>{
  'id': id,
  'targetType': targetType,
  'targetId': targetId,
  'transactionType': transactionType,
  'window': window,
  'periodKey': periodKey,
  'hasLimit': true,
  'limitAmount': amount.toDouble(),
  'alertActive': true,
  'createdAt': timestamp,
  'updatedAt': timestamp,
};

Map<String, Object?> _recurringRule({
  required int id,
  required String triggerType,
  required String transactionType,
  required String name,
  required num amount,
  required int day,
  required int categoryId,
  required String categoryName,
  required String categoryColor,
  required int categoryIconSlot,
  required int timestamp,
  String packageName = '',
  String appLabel = '',
  String sampleText = '',
  String includeKeyword = '',
}) => <String, Object?>{
  'id': id,
  'triggerType': triggerType,
  'transactionType': transactionType,
  'name': name,
  'estimatedAmount': amount.toDouble(),
  'expectedDayOfMonth': day,
  'expectedTime': '08:00',
  'categoryId': categoryId,
  'categoryName': categoryName,
  'categoryColor': categoryColor,
  'categoryIconSlot': categoryIconSlot,
  'isActive': true,
  'appFilterText': appLabel,
  'packageName': packageName,
  'appLabel': appLabel,
  'sampleText': sampleText,
  'includeKeyword': includeKeyword,
  'amountPattern': '',
  'amountSelection': '',
  'merchantPattern': '',
  'merchantSelection': '',
  'dateToleranceDays': 5,
  'amountTolerancePercent': 20.0,
  'amountToleranceMin': 5000.0,
  'createdAt': timestamp,
  'updatedAt': timestamp,
};

Map<String, Object?> _event(
  int id,
  int timestamp,
  String appLabel,
  String title,
  String text,
) => <String, Object?>{
  'id': id,
  'timestamp': timestamp,
  'source': 'notification_listener',
  'packageName': 'preview.${appLabel.toLowerCase()}',
  'appLabel': appLabel,
  'title': title,
  'text': text,
  'bigText': '',
  'subText': '',
  'category': 'transaction',
  'notificationKey': 'preview-$id',
  'accessibilityEventType': '',
  'hash': 'preview-hash-$id',
  'isDuplicate': false,
};

Map<String, Object?> _card(
  int id,
  int timestamp,
  String type,
  String title,
  String message, {
  bool isRead = false,
  int? categoryId,
  String? categoryName,
  String? categoryColor,
  int? categoryIconSlot,
  int? recurringTransactionId,
  int? transactionId,
  num? amount,
}) => <String, Object?>{
  'id': id,
  'type': type,
  'title': title,
  'message': message,
  'timestamp': timestamp,
  'isRead': isRead,
  'isActive': true,
  'priority': 'normal',
  'categoryId': categoryId,
  'categoryName': categoryName,
  'categoryColor': categoryColor,
  'categoryIconSlot': categoryIconSlot,
  'recurringTransactionId': recurringTransactionId,
  'transactionId': transactionId,
  'amount': amount?.toDouble(),
  'triggerDate': null,
  'nextDueDate': null,
  'createdAt': timestamp,
  'updatedAt': timestamp,
};

DateTime _dateWithClampedDay(DateTime month, int day) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(month.year, month.month, day.clamp(1, lastDay));
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

String _periodKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
