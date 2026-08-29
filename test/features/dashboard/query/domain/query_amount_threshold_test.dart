import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_threshold.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  CurrentLedgerQueryScope scope({
    Map<String, Object?> refinements = const {},
  }) => CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
    refinements: refinements,
  );

  test(
    'minimum is 1000 HUF and canonical maximum clamps a stale threshold',
    () {
      final bounds = QueryAmountThreshold.resolve(
        scope: scope(
          refinements: const <String, Object?>{
            QueryAmountThreshold.refinementKey: 900000,
          },
        ),
        amountDomain: const QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 250000,
        ),
      );

      expect(bounds.minimumScaled100, 100000);
      expect(bounds.maximumScaled100, 250000);
      expect(bounds.valueScaled100, 250000);
    },
  );

  test('threshold mutation is one immutable Query identity change', () {
    final original = scope();
    final changed = QueryAmountThreshold.apply(
      original,
      valueScaled100: 150000,
      amountDomain: const QueryMenuAmountDomain(
        minimumAmountScaled100: 0,
        maximumAmountScaled100: 300000,
      ),
    );

    expect(changed.refinements[QueryAmountThreshold.refinementKey], 150000);
    expect(changed.key, isNot(original.key));
  });

  test('a low or empty canonical domain remains a finite single minimum', () {
    final bounds = QueryAmountThreshold.resolve(
      scope: scope(),
      amountDomain: const QueryMenuAmountDomain(
        minimumAmountScaled100: 0,
        maximumAmountScaled100: 200,
      ),
    );

    expect(bounds.minimumScaled100, 100000);
    expect(bounds.maximumScaled100, 100000);
    expect(bounds.valueScaled100, 100000);
  });

  test('menu and Mind semantic commits converge on one applied Query value', () {
    final applied = CurrentQueryController(initialScope: scope());
    addTearDown(applied.dispose);
    const domain = QueryMenuAmountDomain(
      minimumAmountScaled100: 0,
      maximumAmountScaled100: 300000,
    );

    // The menu's lower range handle and the Mind slider both use the same
    // immutable mutation before the existing applied Query owner publishes it.
    final menuScope = QueryAmountThreshold.apply(
      applied.scope,
      valueScaled100: 180000,
      amountDomain: domain,
    );
    expect(applied.apply(menuScope), isTrue);
    expect(
      QueryAmountThreshold.resolve(
        scope: applied.scope,
        amountDomain: domain,
      ).valueScaled100,
      180000,
    );

    final mindScope = QueryAmountThreshold.apply(
      applied.scope,
      valueScaled100: 240000,
      amountDomain: domain,
    );
    expect(applied.apply(mindScope), isTrue);
    expect(applied.scope, mindScope);
    expect(applied.generation, 2);
    expect(
      QueryAmountThreshold.resolve(
        scope: applied.scope,
        amountDomain: const QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200000,
        ),
      ).valueScaled100,
      200000,
      reason: 'a changed canonical dynamic maximum clamps the shared value',
    );
  });
}
