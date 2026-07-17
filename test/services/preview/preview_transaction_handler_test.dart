import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:exptv2/services/preview/preview_transaction_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PreviewNativeState state;
  late PreviewTransactionHandler handler;

  setUp(() {
    state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    handler = PreviewTransactionHandler(state);
  });

  tearDown(() => state.dispose());

  test('adds, filters, updates, and deletes a transaction', () async {
    final added =
        await handler.invoke('expenseAddTransaction', <String, Object?>{
              'date': '2026.07.18',
              'time': '12:30',
              'merchant': 'Design Coffee',
              'amount': 1890,
              'type': 'expense',
              'transactionCategoryID': 1,
            })
            as Map<String, Object?>;
    expect(added['amount'], -1890.0);

    final page =
        await handler.invoke('expenseListTransactionPage', <String, Object?>{
              'searchQuery': 'design',
              'limit': 20,
              'offset': 0,
            })
            as Map<String, Object?>;
    expect(page['totalCount'], 1);
    expect(page['limit'], 20);

    await handler.invoke('expenseUpdateTransaction', <String, Object?>{
      'id': added['id'],
      'merchant': 'Design Cafe',
      'amount': 2200,
      'type': 'expense',
    });
    expect(
      state.transactions.singleWhere(
        (row) => row['id'] == added['id'],
      )['merchant'],
      'Design Cafe',
    );

    expect(
      await handler.invoke('expenseDeleteTransaction', <String, Object?>{
        'id': added['id'],
      }),
      isTrue,
    );
  });

  test(
    'category CRUD protects referenced categories and reports counts',
    () async {
      final added =
          await handler.invoke('expenseAddCategory', <String, Object?>{
                'name': 'Design',
                'type': 'kiadás',
                'colorSlot': 9,
                'iconSlot': 4,
              })
              as Map<String, Object?>;
      final id = added['transactionCategoryID']! as int;

      final updated =
          await handler.invoke('expenseUpdateCategory', <String, Object?>{
                'id': id,
                'name': 'Design eszközök',
              })
              as Map<String, Object?>;
      expect(updated['name'], 'Design eszközök');

      final counts = await handler.invoke('expenseCategoryCounts', null) as Map;
      expect(counts[1], greaterThan(0));
      expect(await handler.invoke('expenseDeleteCategory', {'id': 1}), isFalse);
      expect(await handler.invoke('expenseDeleteCategory', {'id': id}), isTrue);
    },
  );

  test('limit upsert uses its natural key and list filters', () async {
    final payload = <String, Object?>{
      'targetType': 'category',
      'targetId': 2,
      'transactionType': 'expense',
      'window': 'monthly',
      'periodKey': '2026-07',
      'hasLimit': true,
      'limitAmount': 45000,
      'alertActive': true,
    };
    final created =
        await handler.invoke('expenseUpsertCategoryLimit', payload)
            as Map<String, Object?>;
    final updated =
        await handler.invoke('expenseUpsertCategoryLimit', {
              ...payload,
              'limitAmount': 52000,
            })
            as Map<String, Object?>;

    expect(updated['id'], created['id']);
    expect(updated['limitAmount'], 52000.0);
    final filtered =
        await handler.invoke('expenseListCategoryLimits', <String, Object?>{
              'transactionType': 'expense',
              'window': 'monthly',
              'periodKey': '2026-07',
            })
            as List;
    expect(filtered, isNotEmpty);
  });

  test('stats snapshots and merchant aliases update shared state', () async {
    final snapshot = <String, Object?>{
      'id': 'design-focus',
      'name': 'Design focus',
      'createdAt': 1000,
      'updatedAt': 1000,
      'includeCategoryScope': true,
      'includeVendorScope': false,
      'includeActiveType': true,
      'includeThreshold': true,
      'includeLayoutMode': true,
      'includePageIndex': true,
      'categoryScopeIds': <int>[1],
      'vendorScopeNames': <String>[],
      'activeType': 'expense',
      'threshold': 5000.0,
      'layoutMode': 'month',
      'activeYear': 2026,
      'activeMonth': 7,
      'pageIndex': 0,
    };
    await handler.invoke('expenseUpsertStatsSnapshot', snapshot);
    await handler.invoke('expenseUpsertStatsSnapshot', {
      ...snapshot,
      'name': 'Updated focus',
      'updatedAt': 2000,
    });
    expect(
      state.statsSnapshots.singleWhere(
        (row) => row['id'] == 'design-focus',
      )['name'],
      'Updated focus',
    );

    final renamed = await handler.invoke(
      'expenseRenameTransactionsByMerchant',
      <String, Object?>{
        'originalMerchant': 'Tesco',
        'userAssignedName': 'Heti bevásárlás',
      },
    );
    expect(renamed, 4);
    final reset = await handler.invoke(
      'expenseResetTransactionNamesByMerchant',
      <String, Object?>{'originalMerchant': 'Tesco'},
    );
    expect(reset, 4);
  });

  test('selection and bootstrap reads return defensive copies', () async {
    final selection =
        await handler.invoke('expensePickYearMonth', <String, Object?>{
              'year': 2024,
              'month': 13,
            })
            as Map<String, Object?>;
    expect(selection, <String, Object?>{'year': 2024, 'month': 12});

    final bootstrap =
        await handler.invoke('expenseLoadBootstrap', null)
            as Map<String, Object?>;
    final rows = bootstrap['transactions']! as List;
    (rows.first as Map)['merchant'] = 'Mutated';
    expect(state.transactions.first['merchant'], isNot('Mutated'));

    final ghosts =
        await handler.invoke('expenseEnsureRecurringGhostTransactions', null)
            as List;
    expect(ghosts, isNotEmpty);
  });
}
