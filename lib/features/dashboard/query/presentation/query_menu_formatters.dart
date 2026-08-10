import '../domain/current_ledger_query_scope.dart';
import '../domain/query_temporal_filter.dart';
import '../domain/query_menu_data.dart';

final class QueryMenuSummary {
  const QueryMenuSummary({
    required this.time,
    required this.category,
    required this.partner,
    required this.amount,
  });

  final String time;
  final String? category;
  final String? partner;
  final String? amount;

  List<String> get compactParts => <String>[time, ?category, ?partner, ?amount];
}

abstract final class QueryMenuFormatters {
  static QueryMenuSummary summary({
    required CurrentLedgerQueryScope scope,
    required QueryMenuData? data,
  }) {
    final categories =
        data?.categories
            .where((item) => scope.categoryIds.contains(item.id))
            .toList(growable: false) ??
        const <QueryMenuCategoryFacet>[];
    final partners =
        data?.partners
            .where((item) => scope.partnerIds.contains(item.id))
            .toList(growable: false) ??
        const <QueryMenuPartnerFacet>[];
    final min = _amount(scope.refinements['minimumAmountScaled100']);
    final max = _amount(scope.refinements['maximumAmountScaled100']);
    return QueryMenuSummary(
      time: time(scope.temporalFilter),
      category: _facet(categories.map((item) => item.displayName)),
      partner: _facet(partners.map((item) => item.displayName)),
      amount: min == null && max == null
          ? null
          : '${min == null ? '0 Ft' : money(min)}–${max == null ? '∞' : money(max)}',
    );
  }

  static String time(QueryTemporalFilter filter) {
    if (!filter.isRestrictive) {
      return 'Összes idő';
    }
    final selections =
        filter.groups
            .where((group) => group.key == 'time')
            .expand((group) => group.selections)
            .toList()
          ..sort();
    if (selections.isEmpty) {
      return 'Összes idő';
    }
    final years =
        selections
            .map((item) => int.parse(item.value.substring(0, 4)))
            .toSet()
            .toList()
          ..sort();
    final selectedMonthCount = selections.fold<int>(
      0,
      (sum, selection) => sum +
          switch (selection.kind) {
            QueryPeriodKind.year => 12,
            QueryPeriodKind.month => 1,
            QueryPeriodKind.day => 1,
          },
    );
    if (years.length > 1) {
      return '${years.first}–${years.last} · $selectedMonthCount hónap';
    }
    final year = years.single;
    final months =
        selections
            .where((item) => item.kind == QueryPeriodKind.month)
            .map((item) => int.parse(item.value.substring(5, 7)))
            .toList()
          ..sort();
    if (selections.length == 1 &&
        selections.single.kind == QueryPeriodKind.year) {
      return '$year · Egész év';
    }
    if (months.length == 12) {
      return '$year · Egész év';
    }
    if (months.length == 1) {
      return '$year · ${_fullMonthNames[months.single - 1]}';
    }
    if (months.isNotEmpty && _isContinuous(months)) {
      return '$year · ${_shortMonthNames[months.first - 1]}–${_shortMonthNames[months.last - 1]}';
    }
    return '$year · ${selections.length} hónap';
  }

  static String money(int amountScaled100) {
    final forints = amountScaled100 ~/ 100;
    final digits = forints.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
      buffer.write(digits[index]);
    }
    return '${buffer.toString()} Ft';
  }

  static int? _amount(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : null;

  static String? _facet(Iterable<String> names) {
    final values = names.toList(growable: false);
    if (values.isEmpty) return null;
    return values.length == 1
        ? values.single
        : '${values.first} +${values.length - 1}';
  }

  static bool _isContinuous(List<int> values) =>
      values.every((value) => value == values.first + values.indexOf(value));

  static const List<String> _shortMonthNames = <String>[
    'Jan',
    'Feb',
    'Már',
    'Ápr',
    'Máj',
    'Jún',
    'Júl',
    'Aug',
    'Szept',
    'Okt',
    'Nov',
    'Dec',
  ];
  static const List<String> _fullMonthNames = <String>[
    'Január',
    'Február',
    'Március',
    'Április',
    'Május',
    'Június',
    'Július',
    'Augusztus',
    'Szeptember',
    'Október',
    'November',
    'December',
  ];
}
