import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';

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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppFilterControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAppPicker() async {
    final panelHeight = SlideUpPanelMetrics.fullHeight(context);
    final selected = await showModalBottomSheet<InstalledApp>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DebugTextFormField(
            debugLabel: 'AppFilterControl.appRegex',
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'App regex',
              errorText: widget.errorText,
            ),
            onChanged: widget.onTextChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Pick installed app',
          icon: const Icon(Icons.apps),
          onPressed: _openAppPicker,
        ),
      ],
    );
  }
}
