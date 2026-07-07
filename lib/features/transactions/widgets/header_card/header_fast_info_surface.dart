import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import 'transaction_header_metrics.dart';

class HeaderFastInfoSurface extends StatelessWidget {
  const HeaderFastInfoSurface({
    super.key,
    required this.visibleFastInfoExtent,
    required this.fastInfo,
    required this.header,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  }) : visibleFastInfoExtentListenable = null;

  const HeaderFastInfoSurface.listenable({
    super.key,
    required this.visibleFastInfoExtentListenable,
    required this.fastInfo,
    required this.header,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  }) : visibleFastInfoExtent = 0;

  final double visibleFastInfoExtent;
  final ValueListenable<double>? visibleFastInfoExtentListenable;
  final Widget fastInfo;
  final Widget header;
  final Color cardColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    final extentListenable = visibleFastInfoExtentListenable;
    if (extentListenable != null) {
      return ValueListenableBuilder<double>(
        valueListenable: extentListenable,
        builder: (context, extent, _) => _buildForExtent(extent),
      );
    }
    return _buildForExtent(visibleFastInfoExtent);
  }

  Widget _buildForExtent(double visibleFastInfoExtent) {
    final extent = visibleFastInfoExtent
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    final showFastInfo = extent > 1.0;
    return Positioned(
      top: -TransactionHeaderMetrics.fastInfoHeight + extent,
      left: 0,
      right: 0,
      child: ExpenseSurfaceContainer(
        surfaceKey: const ValueKey('header-fast-info-surface'),
        style: surfaceStyle,
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        animatePress: false,
        clipContent: false,
        neutralShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
        profile: ExpenseSurfaceProfile.headerCard,
        child: SizedBox(
          height:
              TransactionHeaderMetrics.fastInfoHeight +
              TransactionHeaderMetrics.cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: TransactionHeaderMetrics.fastInfoHeight,
                left: 0,
                right: 0,
                child: header,
              ),
              if (showFastInfo)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (extent / TransactionHeaderMetrics.fastInfoHeight)
                        .clamp(0.0, 1.0),
                    child: fastInfo,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
