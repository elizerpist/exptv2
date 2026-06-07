import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/installed_app.dart';
import 'installed_app_icon.dart';

class InstalledAppPickerSheet extends StatelessWidget {
  const InstalledAppPickerSheet({
    super.key,
    required this.appsFuture,
    required this.height,
  });

  final Future<List<InstalledApp>> appsFuture;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('installed-app-picker-sheet'),
      height: height,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _InstalledAppPickerHandle(),
            Expanded(
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
          ],
        ),
      ),
    );
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
