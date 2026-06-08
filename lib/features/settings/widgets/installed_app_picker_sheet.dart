import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/installed_app.dart';
import 'installed_app_icon.dart';

class InstalledAppPickerSheet extends StatefulWidget {
  const InstalledAppPickerSheet({
    super.key,
    required this.appsFuture,
    required this.height,
  });

  final Future<List<InstalledApp>> appsFuture;
  final double height;

  @override
  State<InstalledAppPickerSheet> createState() =>
      _InstalledAppPickerSheetState();
}

class _InstalledAppPickerSheetState extends State<InstalledAppPickerSheet> {
  late final Future<List<InstalledApp>> _appsFuture;
  late final TextEditingController _searchController;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _appsFuture = widget.appsFuture;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('installed-app-picker-sheet'),
      height: widget.height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _InstalledAppPickerHandle(),
            Expanded(
              child: FutureBuilder<List<InstalledApp>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final apps = _filtered(snapshot.data ?? <InstalledApp>[]);
                  if (apps.isEmpty) {
                    return const Center(child: Text('Nincs találat'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: apps.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        leading: InstalledAppIcon(app: app),
                        title: Text(app.displayName),
                        subtitle: Text(app.packageName),
                        onTap: () => Navigator.of(context).pop(app),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: TextField(
                key: const ValueKey('installed-app-picker-search'),
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Keresés',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InstalledApp> _filtered(List<InstalledApp> apps) {
    if (_query.isEmpty) return apps;
    return apps.where((app) {
      return app.displayName.toLowerCase().contains(_query) ||
          app.packageName.toLowerCase().contains(_query);
    }).toList(growable: false);
  }
}

class _InstalledAppPickerHandle extends StatelessWidget {
  const _InstalledAppPickerHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      child: Center(
        child: Container(
          key: const ValueKey('installed-app-picker-drag-handle'),
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
