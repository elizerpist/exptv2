import 'package:flutter/material.dart';

/// Shared Card2 page geometry. Category and Partner supply only their exact
/// prepared donut, heading and rows; padding, flexes, list ownership and row
/// appearance stay one production contract.
class BudgetDistributionPageSurface extends StatelessWidget {
  const BudgetDistributionPageSurface({
    super.key,
    required this.heading,
    required this.donut,
    required this.rightHeading,
    required this.rows,
    required this.listKey,
    required this.emptyLabel,
    this.donutDiameter = 150,
    this.leftFooter,
  });

  final Widget heading;
  final Widget donut;
  final String rightHeading;
  final List<Widget> rows;
  final Key listKey;
  final String emptyLabel;

  /// Category analysis may reserve a local footer below a smaller donut;
  /// Partner retains the original full-height donut/list geometry.
  final double donutDiameter;
  final Widget? leftFooter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: <Widget>[
        SizedBox(height: 23, child: heading),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 188,
                child: leftFooter == null
                    ? Center(
                        child: SizedBox(
                          key: ValueKey(
                            'budget-distribution-donut-${donutDiameter.toInt()}',
                          ),
                          width: donutDiameter,
                          height: donutDiameter,
                          child: donut,
                        ),
                      )
                    : Column(
                        children: <Widget>[
                          Center(
                            child: SizedBox(
                              key: ValueKey(
                                'budget-distribution-donut-${donutDiameter.toInt()}',
                              ),
                              width: donutDiameter,
                              height: donutDiameter,
                              child: donut,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(child: leftFooter!),
                        ],
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      rightHeading,
                      style: const TextStyle(
                        color: Color(0xff51617f),
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: rows.isEmpty
                          ? Center(
                              child: Text(
                                emptyLabel,
                                style: const TextStyle(
                                  color: Color(0xff66738d),
                                  fontSize: 8,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : ListView.builder(
                              key: listKey,
                              primary: false,
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              itemBuilder: (_, index) => rows[index],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Shared readable reference-derived legend row. Selection is optional because
/// Partner distribution is intentionally read-only in this feature.
class BudgetDistributionLegendRow extends StatelessWidget {
  const BudgetDistributionLegendRow({
    super.key,
    required this.id,
    required this.title,
    required this.color,
    required this.roundedPercent,
    required this.selected,
    this.stateKey,
    this.onTap,
  });

  final String id;
  final String title;
  final Color color;
  final int roundedPercent;
  final bool selected;
  final Key? stateKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      key:
          stateKey ??
          ValueKey(
            'budget-distribution-row-${selected ? 'selected' : 'idle'}-$id',
          ),
      duration: const Duration(milliseconds: 120),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: .13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff66738d),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$roundedPercent%',
            style: const TextStyle(
              color: Color(0xff25365c),
              fontSize: 8.2,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
