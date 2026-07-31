import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// The locally owned Fluvi mark, wordmark, and motto as one reusable unit.
class FluviBrandLockup extends StatelessWidget {
  const FluviBrandLockup({super.key, required this.bounds});

  final DashboardBounds bounds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/fluvi/brand/fluvi_mark.svg',
            key: const ValueKey('fluvi-brand-mark'),
            width: FluviVisualTokens.brandMarkSize,
            height: FluviVisualTokens.brandMarkSize,
          ),
          const SizedBox(width: FluviVisualTokens.brandGap),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fluvi',
                    key: const ValueKey('fluvi-wordmark'),
                    style: FluviVisualTokens.brandWordmarkTextStyle,
                  ),
                  Text(
                    'your personal financial trainer',
                    key: const ValueKey('fluvi-motto'),
                    style: FluviVisualTokens.brandMottoTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
