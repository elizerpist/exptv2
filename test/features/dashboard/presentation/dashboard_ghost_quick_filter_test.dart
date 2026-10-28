import 'dart:async';

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

  testWidgets(
    'SearchPill fling uses the SearchPill surface without a second lavender chip',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 48,
              height: 40,
              child: DashboardGhostSearchPillFling(
                mode: GhostFilterMode.both,
                onModeSelected: _accept,
              ),
            ),
          ),
        ),
      );

      final selector = find.byKey(
        const ValueKey<String>('dashboard-ghost-searchpill-fling-semantics'),
      );
      final icon = find.byKey(
        const ValueKey<String>('dashboard-ghost-searchpill-fling-icon-both'),
      );
      expect(
        find.descendant(
          of: selector,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    const Color(0xFFEDE9FE),
          ),
        ),
        findsNothing,
        reason: 'The carousel clips its belt but does not paint its own chip.',
      );
      expect(
        tester.getRect(icon).center.dx,
        tester.getRect(selector).center.dx,
      );
      expect(tester.getSize(selector), const Size(48, 40));
    },
  );

  testWidgets(
    'SearchPill fling applies a semantic crossing before motion becomes idle',
    (tester) async {
      var mode = GhostFilterMode.both;
      final selected = <GhostFilterMode>[];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 48,
                  height: 40,
                  child: DashboardGhostSearchPillFling(
                    mode: mode,
                    onModeSelected: (next) async {
                      selected.add(next);
                      setState(() => mode = next);
                      return true;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final selector = find.byKey(
        const ValueKey<String>('dashboard-ghost-searchpill-fling-viewport'),
      );
      expect(selector, findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-ghost-searchpill-fling-icon-both'),
        ),
        findsOneWidget,
      );

      await tester.fling(selector, const Offset(0, -72), 900);
      await tester.pump(const Duration(milliseconds: 16));

      expect(selected, isNotEmpty);
      expect(
        selected.first,
        GhostFilterMode.nonGhost,
        reason:
            'The first Core selection is sent at the first carousel crossing, '
            'before the fling has reached its idle callback.',
      );
      expect(mode, selected.last);
    },
  );

  testWidgets('SearchPill fling keeps a later return-to-current intent', (
    tester,
  ) async {
    final mode = GhostFilterMode.both;
    final completions = <Completer<bool>>[];
    final requested = <GhostFilterMode>[];
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 48,
              height: 40,
              child: DashboardGhostSearchPillFling(
                mode: mode,
                onModeSelected: (next) {
                  requested.add(next);
                  final completion = Completer<bool>();
                  completions.add(completion);
                  return completion.future;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final selector = find.byKey(
      const ValueKey<String>('dashboard-ghost-searchpill-fling-viewport'),
    );

    await tester.drag(selector, const Offset(0, -48));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.drag(selector, const Offset(0, 48));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      requested,
      <GhostFilterMode>[GhostFilterMode.nonGhost, GhostFilterMode.both],
      reason:
          'A still-canonical both mode must not erase the later both intent.',
    );
    // A late failure from the first request is stale and must not undo the
    // second physical target.
    completions.first.complete(false);
    await tester.pump();
    expect(mode, GhostFilterMode.both);
  });

  testWidgets('SearchPill fling restores the accepted Core mode on rejection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 48,
            height: 40,
            child: _RejectingSearchPillFling(),
          ),
        ),
      ),
    );
    await tester.pump();
    final selector = find.byKey(
      const ValueKey<String>('dashboard-ghost-searchpill-fling-viewport'),
    );

    await tester.drag(selector, const Offset(0, -48));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('dashboard-ghost-searchpill-fling-icon-both'),
      ),
      findsOneWidget,
      reason: 'A rejected Core request must not leave a local optimistic icon.',
    );
  });

  testWidgets('SearchPill fling adopts an external accepted mode while idle', (
    tester,
  ) async {
    final mode = ValueNotifier<GhostFilterMode>(GhostFilterMode.both);
    addTearDown(mode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 48,
            height: 40,
            child: ValueListenableBuilder<GhostFilterMode>(
              valueListenable: mode,
              builder: (context, value, _) => DashboardGhostSearchPillFling(
                mode: value,
                onModeSelected: (_) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    mode.value = GhostFilterMode.onlyGhost;
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>(
          'dashboard-ghost-searchpill-fling-icon-onlyGhost',
        ),
      ),
      findsOneWidget,
    );
  });
}

final class _RejectingSearchPillFling extends StatelessWidget {
  const _RejectingSearchPillFling();

  @override
  Widget build(BuildContext context) => DashboardGhostSearchPillFling(
    mode: GhostFilterMode.both,
    onModeSelected: (_) async => false,
  );
}

void _noop() {}

Future<bool> _accept(GhostFilterMode _) async => true;
