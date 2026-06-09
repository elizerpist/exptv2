import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/ghost_logbox_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ghost logbox panel updates border style independently', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: GhostLogboxOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: (settings) => updated = settings,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ghost-logbox-border-normal')));
    await tester.pumpAndSettle();

    expect(
      updated?.ghostLogboxSettings.borderStyle,
      GhostLogboxBorderStyle.normal,
    );
    expect(
      updated?.ghostLogboxSurfaceStyle,
      AppThemeSettings.defaults().ghostLogboxSurfaceStyle,
    );
  });

  testWidgets('ghost logbox panel updates text tone independently', (
    tester,
  ) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: GhostLogboxOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: (settings) => updated = settings,
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('ghost-logbox-text-gray')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ghost-logbox-text-gray')));
    await tester.pumpAndSettle();

    expect(updated?.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
    expect(
      updated?.ghostLogboxSurfaceStyle,
      AppThemeSettings.defaults().ghostLogboxSurfaceStyle,
    );
  });
}
