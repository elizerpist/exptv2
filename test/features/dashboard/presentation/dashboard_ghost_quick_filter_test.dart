import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/presentation/category_icon_view.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_ghost_quick_filter.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
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

  testWidgets('receipt and ghost pack changes only the control composition', (
    tester,
  ) async {
    for (final mode in GhostFilterMode.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardGhostQuickFilter(
              mode: mode,
              iconPack: DashboardGhostQuickFilterIconPack.receiptGhost,
              onTap: _noop,
            ),
          ),
        ),
      );

      expect(
        find.byIcon(Icons.receipt_long_outlined),
        mode == GhostFilterMode.onlyGhost ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(CategoryIconView),
        mode == GhostFilterMode.nonGhost ? findsNothing : findsOneWidget,
        reason:
            'The receipt package keeps the existing ghost silhouette for '
            'only-ghost and renders it as the both-state badge.',
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('dashboard-ghost-quick-filter')),
        ),
        const Size(48, 48),
      );
    }
  });

  testWidgets('dropdown selects directly while rail keeps exactly one active', (
    tester,
  ) async {
    final selected = <GhostFilterMode>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardGhostQuickFilter(
            mode: GhostFilterMode.both,
            presentation: DashboardGhostQuickFilterPresentation.dropdown,
            onTap: _noop,
            onModeSelected: (mode) async {
              selected.add(mode);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('dashboard-ghost-quick-filter-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dashboard-ghost-dropdown-onlyGhost')),
    );
    await tester.pump();
    expect(selected, <GhostFilterMode>[GhostFilterMode.onlyGhost]);

    var railCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardGhostQuickFilter(
            mode: GhostFilterMode.onlyGhost,
            presentation: DashboardGhostQuickFilterPresentation.rail,
            onTap: _noop,
            onModeSelected: (_) async {
              railCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('dashboard-ghost-rail-onlyGhost')),
          )
          .onTap,
      isNull,
      reason: 'only the selected pill is a no-op',
    );
    await tester.tap(
      find.byKey(const ValueKey('dashboard-ghost-rail-onlyGhost')),
    );
    await tester.pump();
    expect(railCalls, 0, reason: 'an active rail pill is an intentional no-op');
  });
}

void _noop() {}
