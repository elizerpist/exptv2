import 'package:flutter/material.dart';

final class BalanceHeaderPartitionLabels extends StatelessWidget {
  const BalanceHeaderPartitionLabels({
    super.key,
    required this.incomeRatio,
    required this.hasActivity,
    required this.foreground,
  });
  final double incomeRatio;
  final bool hasActivity;
  final Color foreground;
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: foreground,
      fontSize: 9,
      height: 1,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            'Bevétel ${hasActivity ? (incomeRatio * 100).round() : 0}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Expanded(
          child: Text(
            'Kiadás ${hasActivity ? ((1 - incomeRatio) * 100).round() : 0}%',
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
