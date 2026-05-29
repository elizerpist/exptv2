import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class ExptFab extends StatelessWidget {
  const ExptFab({
    super.key,
    required this.onPressed,
    this.onLongPress,
  });

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('expt-fab'),
      dimension: AppDimensions.fabSize,
      child: Material(
        color: AppColors.primary,
        elevation: 5,
        shadowColor: AppColors.fabShadow,
        shape: const CircleBorder(),
        child: InkResponse(
          containedInkWell: true,
          customBorder: const CircleBorder(),
          highlightColor: Colors.white30,
          onTap: onPressed,
          onLongPress: onLongPress,
          child: Icon(
            Icons.add,
            color: AppColors.white,
            size: AppDimensions.fabSize * AppDimensions.fabIconScale,
          ),
        ),
      ),
    );
  }
}
