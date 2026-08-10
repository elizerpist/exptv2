import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/current_ledger_query_scope_wire_codec.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'one scope wire codec preserves a restrictive filter and navigation',
    () {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>[
          QueryPeriodSelection.month(2026, 2),
          QueryPeriodSelection.month(2026, 8),
        ]),
        categoryIds: const <String>{'food'},
        refinements: const <String, Object?>{'noteContains': 'Tesco'},
      );

      final encoded = CurrentLedgerQueryScopeWireCodec.encodeNavigatedScope(
        scope,
      );
      final decoded = CurrentLedgerQueryScopeWireCodec.decodeSavedScope(
        <Object?, Object?>{
          ...encoded,
          'periodGroups': CurrentLedgerQueryScopeWireCodec.encodeTemporalFilter(
            scope.temporalFilter,
          ),
        },
      );

      expect(decoded.direction, LedgerDirection.expense);
      expect(decoded.temporalFilter, scope.temporalFilter);
      expect(decoded.categoryIds, <String>{'food'});
      expect(decoded.refinements['noteContains'], 'Tesco');
    },
  );
}
