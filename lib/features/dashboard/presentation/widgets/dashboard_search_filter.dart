import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// Inert search/filter row for the data-free dashboard slice.
class DashboardSearchFilter extends StatelessWidget {
  const DashboardSearchFilter({super.key, required this.bounds});

  final DashboardBounds bounds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Row(
        children: [
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FluviVisualTokens.surface,
                borderRadius: FluviVisualTokens.pillRadius,
              ),
              child: Row(
                children: [
                  SizedBox(width: FluviVisualTokens.controlHorizontalInset),
                  Icon(
                    Icons.search_rounded,
                    color: FluviVisualTokens.textSecondary,
                    size: FluviVisualTokens.iconSize,
                  ),
                  SizedBox(width: FluviVisualTokens.controlInnerGap),
                  Text(
                    'Keresés tranzakciók között…',
                    style: FluviVisualTokens.searchHintTextStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: FluviVisualTokens.controlInnerGap),
          const AspectRatio(
            aspectRatio: FluviVisualTokens.filterControlAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FluviVisualTokens.surface,
                borderRadius: FluviVisualTokens.pillRadius,
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: FluviVisualTokens.textSecondary,
                size: FluviVisualTokens.iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
