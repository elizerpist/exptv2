import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../state/event_store.dart';
import 'widgets/app_filter_control.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});

  final EventStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store) return;
    oldWidget.store.removeListener(_onStoreChanged);
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('settings-page'),
      color: AppColors.gray50,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            AppDimensions.bottomNavHeight + AppDimensions.fabSize,
          ),
          children: [
            AppFilterControl(
              value: widget.store.filterText,
              errorText: widget.store.filterError,
              onTextChanged: widget.store.setFilterText,
              onLoadInstalledApps: widget.store.listInstalledApps,
              onAppSelected: widget.store.selectInstalledApp,
            ),
          ],
        ),
      ),
    );
  }
}
