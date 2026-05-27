import 'package:flutter/material.dart';

import '../../../models/installed_app.dart';
import 'installed_app_icon.dart';

class InstalledAppPickerSheet extends StatelessWidget {
  const InstalledAppPickerSheet({super.key, required this.appsFuture});

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
    );
  }
}
