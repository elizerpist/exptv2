import 'dart:ui' show BlurStyle, SemanticsAction, Tristate;

import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_card_painters.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_b3ma3_manifest.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  testWidgets(
    'V3-008/012 production FastInfo uses the F1 shell and each F2-F6 hue in both ghost states',
    (tester) async {
      await pumpBalanceProductionHost(
        tester,
        recoverKnownDetailCardOverflows: true,
      );

      final belt = find.byKey(const ValueKey('spendee-balance-fast-info-belt'));
      expect(tester.getSize(belt), const Size(378, 72));
      expect(
        coloredAncestorsOf(
          tester,
          belt,
        ).where((color) => color != balanceProductionPageColor),
        isEmpty,
      );

      const contracts = <_FastInfoProductionContract>[
        _FastInfoProductionContract(
          kind: SpendeeBalanceFastInfoKind.noSpend,
          id: 'no-spend',
          hue: Color(0xFF5F55EC),
          iconBackground: Color(0xFFF0EFFF),
        ),
        _FastInfoProductionContract(
          kind: SpendeeBalanceFastInfoKind.categoryChange,
          id: 'category-change',
          hue: Color(0xFFEF4173),
          iconBackground: Color(0xFFFFF0F4),
        ),
        _FastInfoProductionContract(
          kind: SpendeeBalanceFastInfoKind.latestTransaction,
          id: 'latest-transaction',
          hue: Color(0xFF5277D3),
          iconBackground: Color(0xFFEDF3FF),
        ),
        _FastInfoProductionContract(
          kind: SpendeeBalanceFastInfoKind.trendComparison,
          id: 'trend-comparison',
          hue: Color(0xFF7657D9),
          iconBackground: Color(0xFFEEEAFF),
          gradient: true,
        ),
        _FastInfoProductionContract(
          kind: SpendeeBalanceFastInfoKind.upcomingRecurring,
          id: 'upcoming-recurring',
          hue: Color(0xFF8B5CF6),
          iconBackground: Color(0xFFF0EFFF),
          gradient: true,
        ),
      ];

      for (final contract in contracts) {
        final surface = find.byKey(
          ValueKey('spendee-balance-fast-info-surface-${contract.kind.name}'),
        );
        final card = find.byKey(
          ValueKey('spendee-balance-fast-info-${contract.kind.name}'),
        );
        final ghost = find.byKey(
          ValueKey('spendee-balance-fast-info-ghost-${contract.id}'),
        );

        expect(surface, findsOneWidget);
        expect(card, findsOneWidget);
        expect(tester.getSize(surface), const Size(120, 72));
        final decoration =
            tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
        expect(
          decoration.border,
          Border.all(color: contract.hue.withValues(alpha: 0x30 / 0xFF)),
        );
        expect(decoration.borderRadius, BorderRadius.circular(26));
        expect(decoration.boxShadow, hasLength(2));
        expect(
          decoration.boxShadow!.first,
          BoxShadow(
            color: contract.hue.withValues(alpha: 0x1F / 0xFF),
            offset: const Offset(0, 12),
            blurRadius: 25,
          ),
        );
        expect(
          decoration.boxShadow!.last,
          const BoxShadow(
            color: Color(0xF5FFFFFF),
            offset: Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        );
        if (contract.gradient) {
          expect(decoration.gradient, isA<CssLinearGradient>());
          final gradient = decoration.gradient! as CssLinearGradient;
          expect(gradient.cssDegrees, 145);
          expect(
            gradient.colors,
            contract.kind == SpendeeBalanceFastInfoKind.trendComparison
                ? const [Color(0xFFFAF8F6), Color(0xFFFFFFFF)]
                : const [Color(0xFFFAF9F7), Color(0xFFFFFFFF)],
          );
        } else {
          expect(decoration.color, const Color(0xFFFEFEFF));
          expect(decoration.gradient, isNull);
        }

        final contentPadding = find.descendant(
          of: surface,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Padding &&
                widget.padding == const EdgeInsets.fromLTRB(9, 7, 9, 18),
          ),
        );
        expect(contentPadding, findsOneWidget);
        final headerDisc = find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints?.maxWidth == 20 &&
                widget.constraints?.maxHeight == 20,
          ),
        );
        expect(headerDisc, findsOneWidget);
        expect(tester.getSize(headerDisc), const Size.square(20));
        expect(tester.getSize(ghost), const Size.square(17));
        expect(
          tester.getRect(ghost).right,
          closeTo(tester.getRect(surface).right - 8, .01),
        );
        expect(
          tester.getRect(ghost).bottom,
          closeTo(tester.getRect(surface).bottom - 4, .01),
        );
        final onGhostDecoration = decorationOf(tester, ghost);
        expect(onGhostDecoration.color, const Color(0xEBF0EFFF));
        expect(onGhostDecoration.border, isNull);
        expect(onGhostDecoration.boxShadow, isNull);

        switch (contract.kind) {
          case SpendeeBalanceFastInfoKind.noSpend:
            final moon = tester.widget<CustomPaint>(
              find.byKey(const ValueKey('spendee-balance-no-spend-moon')),
            );
            expect(
              (moon.painter! as SpendeeBalanceMoonPainter).moonColor,
              contract.hue,
            );
            final label = find.byKey(
              const ValueKey('spendee-balance-no-spend-view-label'),
            );
            expect(
              tester.getRect(label).left,
              closeTo(tester.getRect(surface).left + 9, .01),
            );
            expect(
              tester.getRect(label).bottom,
              closeTo(tester.getRect(ghost).top - 2, .01),
            );
          case SpendeeBalanceFastInfoKind.categoryChange:
            final value = tester.widget<Text>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('spendee-balance-category-change-value'),
                ),
                matching: find.byType(Text),
              ),
            );
            expect(value.style!.color, contract.hue);
            expect(value.style!.fontSize, 13);
            expect(SpendeeBalanceB3mA3Manifest.fastInfoBodyValueRowHeight, 14);
            expect(
              find.descendant(
                of: card,
                matching: find.byWidgetPredicate(
                  (widget) => widget is SizedBox && widget.height == 14,
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(of: card, matching: find.byType(SvgPicture)),
              findsOneWidget,
            );
          case SpendeeBalanceFastInfoKind.latestTransaction:
            expect(
              find.descendant(of: card, matching: find.byType(SvgPicture)),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<Text>(
                    find.descendant(
                      of: find.byKey(
                        const ValueKey(
                          'spendee-balance-latest-transaction-value',
                        ),
                      ),
                      matching: find.byType(Text),
                    ),
                  )
                  .style!
                  .fontSize,
              13,
            );
          case SpendeeBalanceFastInfoKind.trendComparison:
            final percentage = tester.widget<Text>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('spendee-balance-trend-comparison-value'),
                ),
                matching: find.byWidgetPredicate(
                  (widget) => widget is Text && widget.style?.fontSize == 20,
                ),
              ),
            );
            expect(percentage.style!.fontSize, 20);
            expect(percentage.style!.height, 1);
            final direction = tester.widget<Text>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('spendee-balance-trend-comparison-value'),
                ),
                matching: find.byWidgetPredicate(
                  (widget) => widget is Text && widget.style?.fontSize == 17,
                ),
              ),
            );
            expect(direction.style!.height, 1);
            expect(direction.data, anyOf('↑', '↓', '→'));
          case SpendeeBalanceFastInfoKind.upcomingRecurring:
            final glyph = tester.widget<Text>(
              find.byKey(
                const ValueKey('spendee-balance-upcoming-recurring-glyph'),
              ),
            );
            expect(glyph.style!.color, contract.hue);
            expect(glyph.style!.fontSize, 17);
            expect(
              find.descendant(of: card, matching: find.byType(SvgPicture)),
              findsNothing,
            );
        }

        final ghostNode = tester.getSemantics(ghost);
        expect(
          ghostNode.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        ghostNode.owner!.performAction(ghostNode.id, SemanticsAction.tap);
        await tester.pump();
        final offGhostDecoration = decorationOf(tester, ghost);
        expect(offGhostDecoration.color, const Color(0x1F94A3B8));
        expect(offGhostDecoration.border, isNull);
        expect(offGhostDecoration.boxShadow, isNull);
        await tester.drag(belt, const Offset(-100, 0));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('V3-001 inactive action is opaque FEFEFF directly over page', (
    tester,
  ) async {
    await pumpBalanceProductionHost(
      tester,
      recoverKnownDetailCardOverflows: true,
    );

    final action = find.byKey(const ValueKey('spendee-balance-income-action'));
    expect(decorationOf(tester, action).color, const Color(0xFFFEFEFF));
    final ancestorColors = coloredAncestorsOf(tester, action);
    final pageIndex = ancestorColors.indexOf(balanceProductionPageColor);
    expect(pageIndex, greaterThanOrEqualTo(0));
    expect(ancestorColors.take(pageIndex), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'V3-002 focused SearchPill has one outer blue border and no input border',
    (tester) async {
      await pumpBalanceProductionHost(
        tester,
        recoverKnownDetailCardOverflows: true,
      );

      final outer = find.byKey(const ValueKey('spendee-balance-search-field'));
      final row = find.byKey(const ValueKey('spendee-balance-search-row'));
      final editable = find.byKey(
        const ValueKey('spendee-balance-search-editable'),
      );
      final glyph = find.byKey(const ValueKey('spendee-balance-search-glyph'));
      expect(tester.getRect(row), const Rect.fromLTWH(17, 676, 378, 39));
      expect(tester.getSize(outer), const Size(329, 39));
      expect(tester.getSize(editable).height, 34);
      expect(
        decorationOf(tester, outer).borderRadius,
        BorderRadius.circular(21),
      );
      final textField = tester.widget<TextField>(editable);
      expect(textField.style!.fontSize, 14);
      expect(textField.decoration!.hintStyle!.fontSize, 14);
      expect(textField.textAlignVertical, TextAlignVertical.center);
      expect(
        textField.decoration!.contentPadding,
        const EdgeInsets.only(top: 10, bottom: 8),
      );
      final contentPadding = find.descendant(
        of: outer,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding == const EdgeInsets.symmetric(horizontal: 14),
        ),
      );
      expect(contentPadding, findsOneWidget);
      expect(centerDelta(tester, glyph, editable), lessThanOrEqualTo(.5));

      await tester.enterText(editable, 'Keresés');
      await tester.pump();
      final renderEditable = tester.allRenderObjects
          .whereType<RenderEditable>()
          .single;
      final caret = renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 1),
      );
      expect(
        renderEditable.localToGlobal(caret.center).dy,
        closeTo(tester.getRect(editable).center.dy, .5),
      );

      await tester.tap(editable);
      await tester.pump();
      final decoration = effectiveInputDecoration(tester);
      final border = decorationOf(tester, outer).border! as Border;
      expect(border.top, const BorderSide(color: Color(0xFF06B6D4)));
      expect(border.right, border.top);
      expect(border.bottom, border.top);
      expect(border.left, border.top);
      expect(
        find.byKey(
          const ValueKey('spendee-balance-search-field-focus-outline'),
        ),
        findsNothing,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey('spendee-balance-search-focus-semantics'),
              ),
            )
            .getSemanticsData()
            .flagsCollection
            .isFocused,
        Tristate.isTrue,
      );
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.errorBorder, InputBorder.none);
      expect(decoration.focusedErrorBorder, InputBorder.none);
      expect(decoration.disabledBorder, InputBorder.none);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('V3-007 base cards are directly over the page surface', (
    tester,
  ) async {
    await pumpBalanceProductionHost(
      tester,
      recoverKnownDetailCardOverflows: true,
    );

    for (final finder in <Finder>[
      find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
      find.byKey(const ValueKey('spendee-balance-detail-stage')),
    ]) {
      expect(finder, findsOneWidget);
      final ancestorColors = coloredAncestorsOf(tester, finder);
      final pageIndex = ancestorColors.indexOf(balanceProductionPageColor);
      expect(pageIndex, greaterThanOrEqualTo(0));
      expect(ancestorColors.take(pageIndex), isEmpty);
    }
    expect(SpendeeBalanceVisualSpec.pageBackground, balanceProductionPageColor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete production host has no framework exceptions', (
    tester,
  ) async {
    await pumpBalanceProductionHost(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'V3-009 production detail pages retain their final D1-D5 dimensions',
    (tester) async {
      await pumpBalanceProductionHost(tester);

      expect(
        tester.getSize(
          find.byKey(const ValueKey('spendee-balance-detail-stage')),
        ),
        const Size(378, 218),
      );
      for (final id in const [
        'variable-budget',
        'top-categories',
        'top-merchants',
        'average-daily',
      ]) {
        expect(
          tester.getSize(
            find.byKey(ValueKey('spendee-balance-detail-page-$id')).first,
          ),
          const Size(378, 208),
        );
        expect(
          tester.getSize(
            find.byKey(ValueKey('spendee-balance-detail-header-$id')),
          ),
          const Size(346, 21),
        );
      }
      expect(
        tester.getSize(
          find.byKey(const ValueKey('spendee-balance-variable-budget-tile')),
        ),
        const Size.square(46),
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('spendee-balance-budget-dimension-day'),
              ),
            )
            .height,
        20,
      );
      final progress = find.byKey(
        const ValueKey('spendee-balance-budget-progress'),
      );
      expect(tester.getSize(progress), const Size(321, 22));
      final painter =
          tester.widget<CustomPaint>(progress).painter!
              as SpendeeBalanceBudgetProgressPainter;
      final geometry = painter.geometryForSize(tester.getSize(progress));
      expect(geometry.trackRect.height, 12);
      expect(geometry.markerOuterRect.size, const Size.square(22));
      expect(
        geometry.markerOuterRect.width - geometry.markerInnerRect.width,
        10,
      );
      expect(
        tester
            .widget<Text>(find.text('Mai költés a kerethez képest'))
            .style!
            .fontSize,
        10,
      );
      final budgetLabel = find.byWidgetPredicate(
        (widget) =>
            widget is Text && (widget.data?.startsWith('Keret: ') ?? false),
        description: 'the production D2 budget label',
      );
      final referenceLabel = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.startsWith('30 napos napi átlag: ') ?? false),
        description: 'the production D2 reference label',
      );
      expect(budgetLabel, findsOneWidget);
      expect(referenceLabel, findsOneWidget);
      expect(tester.widget<Text>(budgetLabel).style!.fontSize, 7.6);
      expect(tester.widget<Text>(referenceLabel).style!.fontSize, 7.6);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('V3-006/007 production rail and card surfaces stay on F1', (
    tester,
  ) async {
    await pumpBalanceProductionHost(tester);
    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-summary-chevron')),
    );
    await tester.pumpAndSettle();

    final rail = find.byKey(const ValueKey('spendee-balance-time-rail'));
    expect(rail, findsOneWidget);
    final railColors = coloredAncestorsOf(tester, rail);
    final pageIndex = railColors.indexOf(balanceProductionPageColor);
    expect(pageIndex, greaterThanOrEqualTo(0));
    expect(railColors.take(pageIndex), isEmpty);
    final pill = find.byKey(const ValueKey('spendee-balance-year-pill-2026'));
    expect(pill, findsOneWidget);
    final railRect = tester.getRect(rail);
    final pillRect = tester.getRect(pill);
    // The selected maximum pill deliberately lifts one pixel above its
    // layout box; the rail paint bounds include that authored transform.
    final railPaintTop = railRect.top - 1;
    expect(pillRect.left, greaterThanOrEqualTo(railRect.left));
    expect(pillRect.top, greaterThanOrEqualTo(railPaintTop));
    expect(pillRect.right, lessThanOrEqualTo(railRect.right));
    expect(pillRect.bottom, lessThanOrEqualTo(railRect.bottom));

    void expectCardAncestorsOnF1() {
      for (final finder in <Finder>[
        find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
        for (final id in const <String>[
          'variable-budget',
          'top-categories',
          'top-merchants',
          'average-daily',
        ])
          find.byKey(ValueKey('spendee-balance-detail-page-$id')).first,
      ]) {
        final colors = coloredAncestorsOf(tester, finder);
        final index = colors.indexOf(balanceProductionPageColor);
        expect(index, greaterThanOrEqualTo(0));
        expect(colors.take(index), isEmpty);
      }
    }

    expectCardAncestorsOnF1();
    await tester.drag(
      find.byKey(const ValueKey('spendee-balance-collapse-handle')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expectCardAncestorsOnF1();
    expect(tester.takeException(), isNull);
  });
}

@immutable
class _FastInfoProductionContract {
  const _FastInfoProductionContract({
    required this.kind,
    required this.id,
    required this.hue,
    required this.iconBackground,
    this.gradient = false,
  });

  final SpendeeBalanceFastInfoKind kind;
  final String id;
  final Color hue;
  final Color iconBackground;
  final bool gradient;
}
