import 'package:flutter/material.dart';

import '../../../models/installed_app.dart';
import '../../transactions/widgets/slide_up_panel_metrics.dart';
import 'installed_app_picker_sheet.dart';

class AppFilterControl extends StatefulWidget {
  const AppFilterControl({
    super.key,
    required this.value,
    required this.errorText,
    required this.onTextChanged,
    required this.onLoadInstalledApps,
    required this.onAppSelected,
  });

  final String value;
  final String? errorText;
  final ValueChanged<String> onTextChanged;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;
  final ValueChanged<InstalledApp> onAppSelected;

  @override
  State<AppFilterControl> createState() => _AppFilterControlState();
}

class _AppFilterControlState extends State<AppFilterControl> {
  Future<void> _openAppPicker() async {
    final panelHeight = SlideUpPanelMetrics.fullHeight(context);
    final selected = await showModalBottomSheet<InstalledApp>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: panelHeight),
      builder: (context) {
        return InstalledAppPickerSheet(
          appsFuture: widget.onLoadInstalledApps(),
          height: panelHeight,
        );
      },
    );
    if (selected != null) widget.onAppSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      key: const ValueKey('notification-parser-app-picker'),
      tooltip: 'App kiválasztása',
      icon: const Icon(Icons.apps),
      onPressed: _openAppPicker,
    );
  }
}
