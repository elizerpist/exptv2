import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  const domain = QueryMenuAmountDomain(
    minimumAmountScaled100: 0,
    maximumAmountScaled100: 900000,
  );

  CurrentLedgerQueryScope scope({
    Map<String, Object?> refinements = const {},
  }) => CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
    refinements: refinements,
  );

  test('G3: the two-ended range clamps stored bounds to its data domain', () {
    final values = QueryAmountRange.resolve(
      refinements: const <String, Object?>{
        QueryAmountRange.minimumRefinementKey: 1,
        QueryAmountRange.maximumRefinementKey: 9999999,
      },
      amountDomain: domain,
    );

    expect(values.minimumScaled100, 100000);
    expect(values.maximumScaled100, 900000);
    expect(values.lowerScaled100, 100000);
    expect(values.upperScaled100, 900000);
  });

  test(
    'G3: an open upper end remains absent while a narrow range writes both bounds',
    () {
      final allTheWayUp = QueryAmountRange.apply(
        scope(),
        values: const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 200000,
          upperScaled100: 900000,
        ),
        amountDomain: domain,
      );
      expect(allTheWayUp.refinements, const <String, Object?>{
        QueryAmountRange.minimumRefinementKey: 200000,
      });

      final narrowed = QueryAmountRange.apply(
        allTheWayUp,
        values: const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 300000,
          upperScaled100: 600000,
        ),
        amountDomain: domain,
      );
      expect(narrowed.refinements, const <String, Object?>{
        QueryAmountRange.minimumRefinementKey: 300000,
        QueryAmountRange.maximumRefinementKey: 600000,
      });
    },
  );

  test(
    'RG-G5: the one ready binding keeps cross-host domain and mutation parity',
    () {
      final query = scope(
        refinements: const <String, Object?>{
          QueryAmountRange.minimumRefinementKey: 200000,
        },
      );
      final queryMenuBinding = QueryAmountRangeBinding.ready(
        scope: query,
        amountDomain: domain,
      );
      final mindBinding = QueryAmountRangeBinding.ready(
        scope: query,
        amountDomain: domain,
      );

      expect(queryMenuBinding, isNotNull);
      expect(mindBinding, isNotNull);
      expect(queryMenuBinding!.values, mindBinding!.values);
      expect(
        mindBinding.apply(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 300000,
            upperScaled100: 600000,
          ),
        ),
        queryMenuBinding.apply(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 300000,
            upperScaled100: 600000,
          ),
        ),
      );
      expect(
        QueryAmountRangeBinding.ready(scope: query, amountDomain: null),
        isNull,
        reason:
            'A transient missing canonical domain is explicitly unavailable, '
            'not a disabled 1,000/1,000 RangeSlider.',
      );
    },
  );

  test('Mind domain identity excludes only the edited amount refinement', () {
    final applied = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      categoryIds: const <String>{'housing'},
      partnerIds: const <String>{'landlord'},
      refinements: const <String, Object?>{
        QueryAmountRange.minimumRefinementKey: 200000,
        QueryAmountRange.maximumRefinementKey: 700000,
        'noteContains': 'rent',
      },
    );

    final domainScope = QueryAmountRange.domainScope(applied);
    expect(domainScope.direction, applied.direction);
    expect(domainScope.timeScope, applied.timeScope);
    expect(domainScope.categoryIds, applied.categoryIds);
    expect(domainScope.partnerIds, applied.partnerIds);
    expect(domainScope.refinements, const <String, Object?>{
      'noteContains': 'rent',
    });
    expect(
      QueryAmountRange.hasSameDomainIdentity(applied, domainScope),
      isTrue,
    );
    expect(
      QueryAmountRange.hasSameDomainIdentity(
        applied,
        domainScope.copyWith(categoryIds: const <String>{'food'}),
      ),
      isFalse,
    );
  });
}
