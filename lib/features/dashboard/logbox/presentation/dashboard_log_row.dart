import 'package:flutter/material.dart';

import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../application/dashboard_log_view_models.dart';

class DashboardLogRow extends StatelessWidget {
  const DashboardLogRow({
    required this.model,
    required this.onTap,
    this.showSeparator = false,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final DashboardLogRowViewModel model;
  final VoidCallback onTap;
  final bool showSeparator;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final amountColor = model.amountStyle == LogAmountStyle.expense
        ? FluviVisualTokens.logBoxExpenseAmount
        : FluviVisualTokens.logBoxIncomeAmount;
    return SizedBox(
      height: DashboardLogBoxTokens.rowHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showSeparator)
            const Positioned(
              top: 0,
              left:
                  DashboardLogBoxTokens.rowHorizontalInset +
                  DashboardLogBoxTokens.avatarSize +
                  DashboardLogBoxTokens.rowGap,
              right: DashboardLogBoxTokens.rowHorizontalInset,
              child: SizedBox(
                height: DashboardLogBoxTokens.dividerHeight,
                child: ColoredBox(color: FluviVisualTokens.border),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: Semantics(
              label: model.semanticLabel,
              button: true,
              child: InkWell(
                key: ValueKey('dashboard-log-row-${model.entryId}'),
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst
                        ? FluviVisualTokens.logBoxGroupRadius.topLeft
                        : Radius.zero,
                    topRight: isFirst
                        ? FluviVisualTokens.logBoxGroupRadius.topRight
                        : Radius.zero,
                    bottomLeft: isLast
                        ? FluviVisualTokens.logBoxGroupRadius.bottomLeft
                        : Radius.zero,
                    bottomRight: isLast
                        ? FluviVisualTokens.logBoxGroupRadius.bottomRight
                        : Radius.zero,
                  ),
                ),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashboardLogBoxTokens.rowHorizontalInset,
                    vertical: DashboardLogBoxTokens.rowVerticalInset,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: CategoryVisualBadge(
                          colorId: model.categoryColorId,
                          iconId: model.categoryIconId,
                          size: DashboardLogBoxTokens.avatarSize,
                          iconSize: DashboardLogBoxTokens.avatarIconSize,
                        ),
                      ),
                      const SizedBox(width: DashboardLogBoxTokens.rowGap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FluviVisualTokens.logBoxRowTitleTextStyle,
                            ),
                            Text(
                              model.categoryDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  FluviVisualTokens.logBoxRowSecondaryTextStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DashboardLogBoxTokens.rowGap),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            model.formattedAmount,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.right,
                            style: FluviVisualTokens.logBoxRowAmountTextStyle
                                .copyWith(color: amountColor),
                          ),
                          Text(
                            model.displayTime,
                            maxLines: 1,
                            style:
                                FluviVisualTokens.logBoxRowSecondaryTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
