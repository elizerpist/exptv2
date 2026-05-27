import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/installed_app.dart';

class InstalledAppIcon extends StatelessWidget {
  const InstalledAppIcon({super.key, required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    if (!app.hasIcon) return const Icon(Icons.android);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(app.iconBase64),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}
