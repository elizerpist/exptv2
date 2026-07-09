import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import 'ambulance_header_veil.dart';
import 'transaction_header_metrics.dart';

class HeaderFastInfoSurface extends StatelessWidget {
  const HeaderFastInfoSurface({
    super.key,
    required this.visibleFastInfoExtent,
    required this.fastInfo,
    required this.header,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.ambulanceSkin = false,
  }) : visibleFastInfoExtentListenable = null;

  const HeaderFastInfoSurface.listenable({
    super.key,
    required this.visibleFastInfoExtentListenable,
    required this.fastInfo,
    required this.header,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.ambulanceSkin = false,
  }) : visibleFastInfoExtent = 0;

  final double visibleFastInfoExtent;
  final ValueListenable<double>? visibleFastInfoExtentListenable;
  final Widget fastInfo;
  final Widget header;
  final Color cardColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final bool ambulanceSkin;

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
    final resolvedCardColor = ambulanceSkin ? AppColors.white : cardColor;
    const headerBorderRadius = BorderRadius.vertical(
      bottom: Radius.circular(24),
    );
    return Positioned(
      top: -TransactionHeaderMetrics.fastInfoHeight + extent,
      left: 0,
      right: 0,
      child: ExpenseSurfaceContainer(
        surfaceKey: const ValueKey('header-fast-info-surface'),
        style: surfaceStyle,
        color: resolvedCardColor,
        borderRadius: headerBorderRadius,
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
              if (ambulanceSkin)
                const Positioned.fill(
                  child: AmbulanceHeaderVeil(
                    opacityKey: ValueKey(
                      'header-ambulance-fast-info-yellow-veil',
                    ),
                    borderRadius: headerBorderRadius,
                  ),
                ),
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
