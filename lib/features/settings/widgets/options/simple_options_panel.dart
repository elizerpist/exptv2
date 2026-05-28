import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'settings_option_widgets.dart';

class SimpleOptionsPanel extends StatelessWidget {
  const SimpleOptionsPanel({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: title,
          children: [
            for (var index = 0; index < children.length; index += 1)
              SettingsOptionItem(
                title: children[index],
                trailing: const SizedBox.shrink(),
                isLast: index == children.length - 1,
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Az eredeti app szöveges beállítási tartalma Flutterben.',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
      ],
    );
  }
}
