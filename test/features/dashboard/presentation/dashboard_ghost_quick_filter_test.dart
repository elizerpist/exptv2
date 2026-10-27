import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_ghost_quick_filter.dart';
import 'package:fluvi/features/dashboard/query/domain/ghost_filter_mode.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets(
    'quick filter cycles every ghost membership state with one control',
    (tester) async {
      var mode = GhostFilterMode.nonGhost;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: DashboardGhostQuickFilter(
                mode: mode,
                onTap: () => setState(() => mode = mode.next),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
        findsOneWidget,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
        ),
        const Size(48, 48),
        reason: 'the whole icon-and-dots control retains its 48dp hit target',
      );
      expect(find.byTooltip('Nem ghost eredetű tranzakciók'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
      );
      await tester.pump();
      expect(mode, GhostFilterMode.onlyGhost);

      await tester.tap(
        find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
      );
      await tester.pump();
      expect(mode, GhostFilterMode.both);

      await tester.tap(
        find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
      );
      await tester.pump();
      expect(mode, GhostFilterMode.nonGhost);
    },
  );
}
