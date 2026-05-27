import 'package:flutter/material.dart';

import '../models/installed_app.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({
    super.key,
    required this.value,
    required this.enabled,
    required this.errorText,
    required this.onTextChanged,
    required this.onEnabledChanged,
    required this.onLoadInstalledApps,
    required this.onAppSelected,
  });

  final String value;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onEnabledChanged;
  final Future<List<InstalledApp>> Function() onLoadInstalledApps;
  final ValueChanged<InstalledApp> onAppSelected;

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant FilterBar oldWidget) {
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
    final selected = await showModalBottomSheet<InstalledApp>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _InstalledAppPickerSheet(appsFuture: widget.onLoadInstalledApps());
      },
    );
    if (selected != null) widget.onAppSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'App regex',
                    errorText: widget.errorText,
                    border: const OutlineInputBorder(),
                    isDense: true,
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
              const SizedBox(width: 4),
              Switch(value: widget.enabled, onChanged: widget.onEnabledChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstalledAppPickerSheet extends StatelessWidget {
  const _InstalledAppPickerSheet({required this.appsFuture});

  final Future<List<InstalledApp>> appsFuture;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: FutureBuilder<List<InstalledApp>>(
          future: appsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final apps = snapshot.data ?? <InstalledApp>[];
            if (apps.isEmpty) {
              return const Center(child: Text('No installed apps found'));
            }
            return ListView.separated(
              itemCount: apps.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final app = apps[index];
                return ListTile(
                  leading: const Icon(Icons.android),
                  title: Text(app.displayName),
                  subtitle: Text(app.packageName),
                  onTap: () => Navigator.of(context).pop(app),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
