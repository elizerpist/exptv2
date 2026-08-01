import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';

/// Bounds-driven summary visual whose chevron only forwards its supplied intent.
class DashboardSummaryPill extends StatelessWidget {
  const DashboardSummaryPill({
    super.key,
    required this.bounds,
    required this.isRailVisible,
    required this.onChevronTap,
  });

  final DashboardBounds bounds;
  final bool isRailVisible;
  final VoidCallback onChevronTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: FluviRoundedBox(
        color: FluviVisualTokens.surface,
        child: Row(
          children: [
            const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
            const Icon(
              Icons.calendar_month_outlined,
              color: FluviVisualTokens.textSecondary,
              size: FluviVisualTokens.iconSize,
            ),
            const SizedBox(width: FluviVisualTokens.controlInnerGap),
            const Expanded(
              child: Text(
                'Aktuális hónap',
                style: FluviVisualTokens.summaryLabelTextStyle,
              ),
            ),
            GestureDetector(
              key: const ValueKey('dashboard-summary-chevron'),
              onTap: onChevronTap,
              child: isRailVisible
                  ? FluviHighlightMask(
                      child: Icon(
                        isRailVisible
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: FluviVisualTokens.iconSize,
                      ),
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FluviVisualTokens.textSecondary,
                      size: FluviVisualTokens.iconSize,
                    ),
            ),
            const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
          ],
        ),
      ),
    );
  }
}
