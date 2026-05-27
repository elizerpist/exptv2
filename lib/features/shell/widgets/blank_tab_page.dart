import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../app_tab.dart';

class BlankTabPage extends StatelessWidget {
  const BlankTabPage({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: SizedBox.expand(key: ValueKey('blank-page-${tab.id}')),
    );
  }
}
