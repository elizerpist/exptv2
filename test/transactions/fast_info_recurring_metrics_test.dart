import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric_snapshot.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolves upcoming and monthly fixed expenses from recurring ghosts',
    () {
      final metrics = FastInfoMetricsResolver.resolve(
        FastInfoMetricSnapshot(
          now: DateTime(2026, 6, 3, 12),
          balance: 0,
          limits: const <CategoryLimit>[_monthlyLimit],
          recurringGhosts: const <RecurringGhostRecord>[
            _rent,
            _phone,
            _insurance,
            _salary,
            _nextMonth,
          ],
        ),
      );

      expect(metrics['kovetkezo_ismetlo_kiadas']?.primaryValue, 'Telefon');
      expect(
        metrics['kovetkezo_ismetlo_kiadas']?.secondaryValues,
        contains('8 000 Ft · 2 nap múlva'),
      );
      expect(
        metrics['kovetkezo_ismetlo_kiadas']?.secondaryValues,
        contains('7 nap: 2 tétel · 28 000 Ft'),
      );
      expect(metrics['kovetkezo_ismetlo_kiadas']?.avatar, isNotNull);
      expect(metrics['havi_fix_koltseg_osszesen']?.primaryValue, '128 000 Ft');
      expect(metrics['havi_fix_koltseg_osszesen']?.secondaryValues, [
        'levonva 100k · hátra 28k',
        '128k fixből',
        'Lakbér 100k',
      ]);
      expect(
        metrics['havi_fix_koltseg_osszesen']?.progress,
        closeTo(.64, .001),
      );
    },
  );
}

const _monthlyLimit = CategoryLimit(
  id: 1,
  targetType: LimitTargetType.overview,
  targetId: 0,
  transactionType: 'expense',
  window: LimitWindow.monthly,
  periodKey: '2026-06',
  hasLimit: true,
  limitAmount: 200000,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

const _rent = RecurringGhostRecord(
  id: 1,
  recurringTransactionId: 1,
  periodKey: '2026-06',
  name: 'Lakbér',
  amount: 100000,
  transactionType: 'expense',
  date: '2026.06.01',
  time: '08:00',
  categoryId: 1,
  categoryName: 'Lakhatás',
  categoryColor: '#336699',
  categoryIconSlot: 1,
  triggerMillis: 0,
  isActivated: true,
  activatedTransactionId: 10,
  createdAt: 0,
  updatedAt: 0,
);

const _phone = RecurringGhostRecord(
  id: 2,
  recurringTransactionId: 2,
  periodKey: '2026-06',
  name: 'Telefon',
  amount: 8000,
  transactionType: 'expense',
  date: '2026.06.05',
  time: '08:00',
  categoryId: 2,
  categoryName: 'Számlák',
  categoryColor: '#663399',
  categoryIconSlot: 2,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);

const _insurance = RecurringGhostRecord(
  id: 3,
  recurringTransactionId: 3,
  periodKey: '2026-06',
  name: 'Biztosítás',
  amount: 20000,
  transactionType: 'expense',
  date: '2026.06.09',
  time: '08:00',
  categoryId: 2,
  categoryName: 'Számlák',
  categoryColor: '#663399',
  categoryIconSlot: 2,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);

const _salary = RecurringGhostRecord(
  id: 5,
  recurringTransactionId: 5,
  periodKey: '2026-06',
  name: 'Fizetés',
  amount: 300000,
  transactionType: 'income',
  date: '2026.06.04',
  time: '08:00',
  categoryId: 5,
  categoryName: 'Bevétel',
  categoryColor: '#16a34a',
  categoryIconSlot: 5,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);

const _nextMonth = RecurringGhostRecord(
  id: 4,
  recurringTransactionId: 4,
  periodKey: '2026-07',
  name: 'Júliusi',
  amount: 9000,
  transactionType: 'expense',
  date: '2026.07.01',
  time: '08:00',
  categoryId: 2,
  categoryName: 'Számlák',
  categoryColor: '#663399',
  categoryIconSlot: 2,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);
