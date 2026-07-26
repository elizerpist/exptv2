import 'dart:ui' show BlurStyle, SemanticsAction, Tristate;

import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    Widget child, {
    double width = 378,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 892),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  group('B3M-A3 FastInfo belt', () {
    testWidgets('uses the frozen translucent surfaces and true inset light', (
      tester,
    ) async {
      final expectations =
          <SpendeeBalanceFastInfoKind, _FastSurfaceExpectation>{
            SpendeeBalanceFastInfoKind.noSpend: const _FastSurfaceExpectation(
              border: Color(0x305F55EC),
              outerShadow: Color(0x1F5F55EC),
              innerShadow: Color(0xF5FFFFFF),
            ),
            SpendeeBalanceFastInfoKind.categoryChange:
                const _FastSurfaceExpectation(
                  border: Color(0x30EF4173),
                  outerShadow: Color(0x1FEF4173),
                  innerShadow: Color(0xF5FFFFFF),
                ),
            SpendeeBalanceFastInfoKind.latestTransaction:
                const _FastSurfaceExpectation(
                  border: Color(0x305277D3),
                  outerShadow: Color(0x1F5277D3),
                  innerShadow: Color(0xF5FFFFFF),
                ),
            SpendeeBalanceFastInfoKind.trendComparison:
                const _FastSurfaceExpectation(
                  border: Color(0x1C6770B0),
                  outerShadow: Color(0x1A524B93),
                  innerShadow: Color(0xF0FFFFFF),
                ),
            SpendeeBalanceFastInfoKind.upcomingRecurring:
                const _FastSurfaceExpectation(
                  border: Color(0x308B5CF6),
                  outerShadow: Color(0x1F8B5CF6),
                  innerShadow: Color(0xF5FFFFFF),
                  gradientColors: [Color(0xFAF9F7FF), Color(0xF2FFFFFF)],
                ),
          };

      for (final model in fastInfoModels()) {
        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(model: model, onGhostChanged: (_, _) {}),
          ),
        );

        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        ValueKey(
                          'spendee-balance-fast-info-surface-${model.kind.name}',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        final expected = expectations[model.kind]!;
        expect(decoration.border, Border.all(color: expected.border));
        expect(decoration.borderRadius, BorderRadius.circular(26));
        expect(
          decoration.color,
          expected.gradientColors == null ? const Color(0xF0FFFFFF) : null,
        );
        if (expected.gradientColors == null) {
          expect(decoration.gradient, isNull);
        } else {
          expect(decoration.gradient, isA<CssLinearGradient>());
          final gradient = decoration.gradient! as CssLinearGradient;
          expect(gradient.colors, expected.gradientColors);
          expect(gradient.cssDegrees, 145);
        }
        expect(decoration.boxShadow, hasLength(2));
        expect(
          decoration.boxShadow!.first,
          BoxShadow(
            color: expected.outerShadow,
            offset: const Offset(0, 12),
            blurRadius: 25,
          ),
        );
        expect(
          decoration.boxShadow!.last,
          BoxShadow(
            color: expected.innerShadow,
            offset: const Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        );
      }
    });

    testWidgets('is 72px high and authors exactly three card slots', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoBelt(
            cards: fastInfoModels(),
            onGhostChanged: (_, _) {},
          ),
        ),
      );

      expect(
        tester.getSize(
          find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
        ),
        const Size(378, 72),
      );
      expect(
        SpendeeBalanceFastInfoBelt.cardWidthFor(378),
        closeTo((378 - 18) / 3, .001),
      );
      expect(
        SpendeeBalanceFastInfoBelt.viewportFractionFor(378),
        closeTo(((378 - 18) / 3 + 9) / 378, .001),
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-fast-info-pagination')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-balance-fast-info-ticking-viewport'),
        ),
        findsOneWidget,
      );
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('renders five distinct internal card hierarchies', (
      tester,
    ) async {
      for (final model in fastInfoModels()) {
        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(model: model, onGhostChanged: (_, _) {}),
          ),
        );

        expect(
          find.byKey(ValueKey('spendee-balance-fast-info-${model.kind.name}')),
          findsOneWidget,
        );
        expect(find.byType(Icon), findsNothing);

        switch (model) {
          case SpendeeBalanceNoSpendCardModel():
            expect(
              find.byKey(const ValueKey('spendee-balance-no-spend-moon')),
              findsOneWidget,
            );
            expect(find.byType(SvgPicture), findsOneWidget);
            expect(find.text('3 / 7 nap'), findsOneWidget);
          case SpendeeBalanceCategoryChangeCardModel():
            expect(find.byType(SvgPicture), findsNWidgets(2));
            expect(find.text('+14 200 Ft'), findsOneWidget);
            expect(
              find.text('Közlekedés · előző 30 naphoz képest'),
              findsOneWidget,
            );
            final title = tester.widget<Text>(
              find.text('Legnagyobb kategóriaváltozás'),
            );
            expect(title.maxLines, isNull);
            expect(title.overflow, isNull);
          case SpendeeBalanceLatestTransactionCardModel():
            expect(find.byType(SvgPicture), findsNWidgets(2));
            expect(find.text('-4 250 Ft'), findsOneWidget);
            expect(find.text('Lidl · ma, 11:42'), findsOneWidget);
          case SpendeeBalanceTrendComparisonCardModel():
            expect(find.byType(SvgPicture), findsNWidgets(2));
            expect(find.text('18%'), findsOneWidget);
            expect(find.text('↑'), findsOneWidget);
            expect(
              tester.getTopLeft(find.text('↑')).dx,
              lessThan(tester.getTopLeft(find.text('18%')).dx),
            );
          case SpendeeBalanceUpcomingRecurringCardModel():
            expect(find.byType(SvgPicture), findsOneWidget);
            expect(
              find.byKey(
                const ValueKey('spendee-balance-upcoming-recurring-glyph'),
              ),
              findsOneWidget,
            );
            expect(find.text('↻'), findsOneWidget);
            expect(find.text('Netflix'), findsOneWidget);
            expect(find.text('-3 490 Ft · aug. 4.'), findsOneWidget);
        }
      }
    });

    testWidgets('ghost control exposes toggled semantics and callback', (
      tester,
    ) async {
      String? changedId;
      bool? changedValue;
      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoCard(
            model: fastInfoModels().first,
            onGhostChanged: (id, value) {
              changedId = id;
              changedValue = value;
            },
          ),
        ),
      );

      final toggle = find.byKey(
        const ValueKey('spendee-balance-fast-info-ghost-no-spend'),
      );
      final semantics = tester.getSemantics(toggle);
      expect(semantics.label, 'Ghost tranzakciók beleszámítanak. Kikapcsolás.');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isToggled, isNot(Tristate.none));
      expect(semantics.flagsCollection.isToggled, Tristate.isTrue);

      await tester.tap(toggle);
      expect(changedId, 'no-spend');
      expect(changedValue, isFalse);
    });

    testWidgets(
      '0726 no-spend exposes the selected four-state view and cycle',
      (tester) async {
        var cycles = 0;
        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(
              model: const SpendeeBalanceNoSpendCardModel(
                id: 'no-spend',
                title: 'No-spend napok',
                value: '18 nap',
                secondary: '31 megfigyelt napból',
                dimension: SpendeeBalanceNoSpendDimension.month,
                dimensionLabel: 'Havi',
                includeGhostTransactions: true,
              ),
              onGhostChanged: (_, _) {},
              onNoSpendCycle: () => cycles += 1,
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('spendee-balance-no-spend-view-label')),
          findsOneWidget,
        );
        expect(find.text('Havi'), findsOneWidget);
        expect(find.text('18 nap'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('spendee-balance-no-spend-cycle')),
        );
        expect(cycles, 1);
      },
    );

    testWidgets(
      'traditional focus paints inset ghost outlines without geometry shift',
      (tester) async {
        final previousStrategy = FocusManager.instance.highlightStrategy;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy = previousStrategy,
        );

        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(
              model: fastInfoModels().first,
              onGhostChanged: (_, _) {},
            ),
          ),
        );
        final fastGhost = find.byKey(
          const ValueKey('spendee-balance-fast-info-ghost-no-spend'),
        );
        final fastGhostRect = tester.getRect(fastGhost);
        await _focusControl(tester, fastGhost);
        _expectInsetFocusOutline(
          tester,
          controlRect: fastGhostRect,
          outlineKey: const ValueKey(
            'spendee-balance-fast-info-ghost-no-spend-focus-outline',
          ),
          shape: BoxShape.circle,
        );

        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels().first,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );
        final detailGhost = find.byKey(
          const ValueKey('spendee-balance-detail-ghost-variable'),
        );
        final detailGhostRect = tester.getRect(detailGhost);
        await _focusControl(tester, detailGhost);
        _expectInsetFocusOutline(
          tester,
          controlRect: detailGhostRect,
          outlineKey: const ValueKey(
            'spendee-balance-detail-ghost-variable-focus-outline',
          ),
          borderRadius: BorderRadius.circular(5),
        );
      },
    );

    testWidgets('ghost surface matches the frozen ON and OFF materials', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoCard(
            model: fastInfoModels().first,
            onGhostChanged: (_, _) {},
          ),
        ),
      );
      var decoration = _firstContainerDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-fast-info-ghost-no-spend')),
      );
      expect(decoration.color, const Color(0xEBF0EFFF));
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);

      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoCard(
            model: const SpendeeBalanceNoSpendCardModel(
              id: 'no-spend',
              title: 'No-spend napok',
              value: '3 / 7 nap',
              secondary: 'Elmúlt 7 nap',
              includeGhostTransactions: false,
            ),
            onGhostChanged: (_, _) {},
          ),
        ),
      );
      decoration = _firstContainerDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-fast-info-ghost-no-spend')),
      );
      expect(decoration.color, const Color(0x1F94A3B8));
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets(
      'upcoming card uses the source compact shared value and metadata rows',
      (tester) async {
        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(
              model: fastInfoModels().last,
              onGhostChanged: (_, _) {},
            ),
            width: 120,
          ),
        );

        final name = tester.widget<Text>(find.text('Netflix'));
        final metadata = tester.widget<Text>(find.text('-3 490 Ft · aug. 4.'));
        expect(name.style!.fontSize, 13);
        expect(name.style!.height, 1.05);
        expect(metadata.style!.fontSize, 6.5);
        expect(metadata.style!.height, 1.1);
        expect(
          find.byKey(
            const ValueKey('spendee-balance-upcoming-recurring-avatar-slot'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('upcoming value row ellipsizes both live-data fields safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoCard(
            model: const SpendeeBalanceUpcomingRecurringCardModel(
              id: 'upcoming-recurring',
              title: 'Közelgő ismétlődés',
              name: 'Rendkívül hosszú ismétlődő szolgáltatásnév',
              amount: '-123 456 789 Ft',
              dueText: 'aug. 4.',
              categoryIconAsset: 'assets/icons/lucide/clapperboard.svg',
              categoryColor: Color(0xFF8B5CF6),
              includeGhostTransactions: true,
            ),
            onGhostChanged: (_, _) {},
          ),
          width: 120,
        ),
      );

      expect(tester.takeException(), isNull);
      for (final value in [
        'Rendkívül hosszú ismétlődő szolgáltatásnév',
        '-123 456 789 Ft · aug. 4.',
      ]) {
        final text = tester.widget<Text>(find.text(value));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('virtual pages wrap both directions without an edge', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        host(
          SpendeeBalanceFastInfoBelt(
            cards: fastInfoModels(),
            initialIndex: 0,
            onIndexChanged: selected.add,
            onGhostChanged: (_, _) {},
          ),
        ),
      );

      await tester.timedDrag(
        find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
        const Offset(100, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(selected, isNotEmpty);
      expect(selected.last, 4);

      await tester.timedDrag(
        find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
        const Offset(-100, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(selected.last, 0);
    });
  });

  group('B3M-A3 detail carousel', () {
    testWidgets('detail shell uses the frozen glass surface and inset light', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels().first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      final decoration = _firstDecoratedBoxDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-detail-page-variable')),
      );
      expect(decoration.color, const Color(0xF0FFFFFF));
      expect(decoration.border, Border.all(color: const Color(0x1C666FAB)));
      expect(decoration.borderRadius, BorderRadius.circular(26));
      expect(decoration.boxShadow, const [
        BoxShadow(
          color: Color(0x1F534B96),
          offset: Offset(0, 15),
          blurRadius: 30,
        ),
        BoxShadow(
          color: Color(0xF5FFFFFF),
          offset: Offset(0, 1),
          blurStyle: BlurStyle.inner,
        ),
      ]);
    });

    testWidgets('detail ghost OFF material keeps its exact glass treatment', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels(includeGhostTransactions: false).first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      final decoration = _firstContainerDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-detail-ghost-variable')),
      );
      expect(decoration.color, const Color(0xC7FFFFFF));
      expect(decoration.border, Border.all(color: const Color(0x338089AA)));
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.boxShadow, const [
        BoxShadow(
          color: Color(0x144C5580),
          offset: Offset(0, 3),
          blurRadius: 7,
        ),
      ]);
    });

    testWidgets('Lucide tiles and ranked avatars use real inset highlights', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels().first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );
      var decoration = _firstContainerDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-variable-budget-tile')),
      );
      expect(decoration.borderRadius, BorderRadius.circular(11));
      expect(decoration.boxShadow, const [
        BoxShadow(
          color: Color(0x3DFB3D76),
          offset: Offset(0, 8),
          blurRadius: 13,
        ),
        BoxShadow(
          color: Color(0x6BFFFFFF),
          offset: Offset(0, 1),
          blurStyle: BlurStyle.inner,
        ),
      ]);

      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels()[1],
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );
      decoration = _firstContainerDecoration(
        tester,
        find.byKey(const ValueKey('spendee-balance-top-category-row-0')),
      );
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, const [
        BoxShadow(
          color: Color(0x57FFFFFF),
          offset: Offset(0, 1),
          blurStyle: BlurStyle.inner,
        ),
      ]);
    });

    testWidgets(
      '0726 uses the approved 208px page plus 4px gap and 6px pagination',
      (tester) async {
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailCarousel(
              pages: detailModels(),
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );

        expect(
          tester.getSize(
            find.byKey(const ValueKey('spendee-balance-detail-stage')),
          ),
          const Size(378, 218),
        );
        expect(
          find.byKey(const ValueKey('spendee-balance-detail-ticking-viewport')),
          findsOneWidget,
        );
        expect(find.byType(PageView), findsNothing);
        expect(
          tester.getSize(
            find
                .byKey(const ValueKey('spendee-balance-detail-page-variable'))
                .first,
          ),
          const Size(378, 208),
        );
        expect(
          tester.getSize(
            find.byKey(const ValueKey('spendee-balance-detail-dot-0')),
          ),
          const Size.square(6),
        );
        for (var index = 1; index < 4; index += 1) {
          expect(
            tester.getSize(
              find.byKey(ValueKey('spendee-balance-detail-dot-$index')),
            ),
            const Size.square(4),
          );
        }
      },
    );

    testWidgets(
      'only the active detail page exposes focus and reduced motion removes dot animation',
      (tester) async {
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailCarousel(
              pages: detailModels(),
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
            disableAnimations: true,
          ),
        );

        final activePage = find.byKey(
          const ValueKey('spendee-balance-detail-virtual-0'),
        );
        final inactivePage = find.byKey(
          const ValueKey('spendee-balance-detail-virtual-1'),
        );
        expect(
          tester
              .widget<ExcludeFocus>(
                find.descendant(
                  of: activePage,
                  matching: find.byType(ExcludeFocus),
                ),
              )
              .excluding,
          isFalse,
        );
        expect(
          tester
              .widget<ExcludeFocus>(
                find.descendant(
                  of: inactivePage,
                  matching: find.byType(ExcludeFocus),
                ),
              )
              .excluding,
          isTrue,
        );
        expect(
          tester
              .widget<ExcludeSemantics>(
                find
                    .descendant(
                      of: inactivePage,
                      matching: find.byType(ExcludeSemantics),
                    )
                    .first,
              )
              .excluding,
          isTrue,
        );
        expect(
          tester
              .widget<AnimatedContainer>(
                find.byKey(const ValueKey('spendee-balance-detail-dot-0')),
              )
              .duration,
          Duration.zero,
        );
      },
    );

    testWidgets('variable budget keeps exact three dimensions and progress', (
      tester,
    ) async {
      SpendeeBalanceBudgetDimension? selected;
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels().first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (value) => selected = value,
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Változó keret'), findsOneWidget);
      expect(find.text('Napi'), findsOneWidget);
      expect(find.text('Heti'), findsOneWidget);
      expect(find.text('Havi'), findsOneWidget);
      expect(find.text('Mára még elkölthető'), findsOneWidget);
      expect(find.text('6 500 Ft'), findsOneWidget);
      expect(find.text('Ma elköltve'), findsOneWidget);
      expect(find.text('8 900 Ft'), findsOneWidget);
      expect(find.text('4 db'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('spendee-balance-budget-progress')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-budget-dimension-week')),
      );
      expect(selected, SpendeeBalanceBudgetDimension.week);
    });

    testWidgets('detail main rows keep the frozen amount-side gaps', (
      tester,
    ) async {
      final cases = <(int, String, List<double>)>[
        (0, '6 500 Ft', const [9, 9]),
        (1, '12 400 Ft', const [9, 9]),
        (3, '6 370 Ft / nap', const [7, 7]),
      ];

      for (final (pageIndex, amount, expectedGaps) in cases) {
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels()[pageIndex],
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );

        expect(
          _directSizedBoxWidths(_nearestRow(tester, find.text(amount))),
          expectedGaps,
          reason: 'frozen horizontal gaps around $amount',
        );
      }
    });

    testWidgets('dimension rail keeps the frozen 2px chip gap', (tester) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels().first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      final day = tester.getRect(
        find.byKey(const ValueKey('spendee-balance-budget-dimension-day')),
      );
      final week = tester.getRect(
        find.byKey(const ValueKey('spendee-balance-budget-dimension-week')),
      );
      final month = tester.getRect(
        find.byKey(const ValueKey('spendee-balance-budget-dimension-month')),
      );

      expect(week.left - day.right, 2);
      expect(month.left - week.right, 2);
    });

    testWidgets(
      'budget and merchant dimensions expose one selected button node',
      (tester) async {
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels().first,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );

        _expectDimensionSemantics(
          tester,
          find.byKey(const ValueKey('spendee-balance-budget-dimension-day')),
          label: 'Napi',
          selected: true,
        );
        _expectDimensionSemantics(
          tester,
          find.byKey(const ValueKey('spendee-balance-budget-dimension-week')),
          label: 'Heti',
          selected: false,
        );
        _expectDimensionSemantics(
          tester,
          find.byKey(const ValueKey('spendee-balance-budget-dimension-month')),
          label: 'Havi',
          selected: false,
        );

        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels()[2],
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );
        _expectDimensionSemantics(
          tester,
          find.byKey(const ValueKey('spendee-balance-merchant-dimension-year')),
          label: 'Éves',
          selected: false,
        );
        _expectDimensionSemantics(
          tester,
          find.byKey(
            const ValueKey('spendee-balance-merchant-dimension-month'),
          ),
          label: 'Havi',
          selected: true,
        );
        _expectDimensionSemantics(
          tester,
          find.byKey(const ValueKey('spendee-balance-merchant-dimension-all')),
          label: 'Összesen',
          selected: false,
        );
      },
    );

    testWidgets('dimension chips activate exactly once for Enter and Space', (
      tester,
    ) async {
      final budgetSelections = <SpendeeBalanceBudgetDimension>[];
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels().first,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: budgetSelections.add,
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      final budgetWeek = find.byKey(
        const ValueKey('spendee-balance-budget-dimension-week'),
      );
      await _focusControl(tester, budgetWeek);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(budgetSelections, [SpendeeBalanceBudgetDimension.week]);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(budgetSelections, [
        SpendeeBalanceBudgetDimension.week,
        SpendeeBalanceBudgetDimension.week,
      ]);
      await tester.pump(const Duration(milliseconds: 101));

      final merchantSelections = <SpendeeBalanceMerchantDimension>[];
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels()[2],
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: merchantSelections.add,
          ),
        ),
      );
      final merchantYear = find.byKey(
        const ValueKey('spendee-balance-merchant-dimension-year'),
      );
      await _focusControl(tester, merchantYear);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(merchantSelections, [SpendeeBalanceMerchantDimension.year]);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(merchantSelections, [
        SpendeeBalanceMerchantDimension.year,
        SpendeeBalanceMerchantDimension.year,
      ]);
      await tester.pump(const Duration(milliseconds: 101));
    });

    testWidgets(
      'dimension traversal paints a 2px inset outline and keeps chip geometry',
      (tester) async {
        final previousStrategy = FocusManager.instance.highlightStrategy;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy = previousStrategy,
        );
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels().first,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );

        final day = find.byKey(
          const ValueKey('spendee-balance-budget-dimension-day'),
        );
        final dayRect = tester.getRect(day);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        _expectInsetFocusOutline(
          tester,
          controlRect: dayRect,
          outlineKey: const ValueKey(
            'spendee-balance-budget-dimension-day-focus-outline',
          ),
          borderRadius: BorderRadius.circular(4),
        );
        expect(tester.getRect(day), dayRect);
        _expectNoDefaultMaterialInteraction(tester, day);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey(
              'spendee-balance-budget-dimension-day-focus-outline',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'spendee-balance-budget-dimension-week-focus-outline',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('category and merchant pages retain their distinct row sets', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels()[1],
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Top kategóriák'), findsOneWidget);
      expect(find.text('Ezen a héten'), findsOneWidget);
      expect(find.text('Ebben a hónapban'), findsOneWidget);
      expect(find.text('Idén eddig'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('spendee-balance-top-category-row-2')),
        findsOneWidget,
      );

      SpendeeBalanceMerchantDimension? selected;
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: detailModels()[2],
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (value) => selected = value,
          ),
        ),
      );
      expect(find.text('Top 5 kereskedő'), findsOneWidget);
      expect(find.text('Éves'), findsOneWidget);
      expect(find.text('Havi'), findsOneWidget);
      expect(find.text('Összesen'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('spendee-balance-top-merchant-row-4')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-merchant-dimension-year')),
      );
      expect(selected, SpendeeBalanceMerchantDimension.year);
    });

    testWidgets('average daily page draws the exact 30-day six-bucket chart', (
      tester,
    ) async {
      final average = detailModels().last as SpendeeBalanceAverageDailyModel;
      await tester.pumpWidget(
        host(
          SpendeeBalanceDetailPage(
            model: average,
            onGhostChanged: (_, _) {},
            onBudgetDimensionChanged: (_) {},
            onMerchantDimensionChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Átlagos napi költés'), findsOneWidget);
      expect(find.text('6 370 Ft / nap'), findsOneWidget);
      expect(find.text('Egyenleg puffer'), findsOneWidget);
      expect(find.text('58 nap'), findsOneWidget);
      expect(find.text('Legmagasabb nap'), findsOneWidget);
      expect(find.text('19 800 Ft'), findsOneWidget);
      expect(find.text('Kiugrások > 9 555 Ft'), findsOneWidget);
      expect(find.text('3 db'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey('spendee-balance-average-daily-chart'),
                    ),
                  )
                  .painter
              as SpendeeBalanceDailyChartPainter;
      final points = painter.pointsForSize(const Size(100, 64));
      expect(points, hasLength(6));
      expect(points.first, const Offset(0, 14.08));
      expect(points.last.dx, 100);
      expect(
        points.map((point) => point.dy),
        everyElement(inInclusiveRange(14.08, 49.92)),
      );
    });

    testWidgets(
      '0726 query cards expose exact source pills and replace their live rows',
      (tester) async {
        SpendeeBalanceRankDimension? categorySelection;
        SpendeeBalanceRankDimension? vendorSelection;
        SpendeeBalanceAverageDimension? averageSelection;
        final category = SpendeeBalanceTopCategoriesModel(
          id: 'top-categories',
          title: 'Top kategóriák',
          featuredCategory: 'Élelmiszer',
          featuredMeta: 'Havi · 1. hely',
          featuredAmount: '36 500 Ft',
          featuredIconAsset: 'assets/icons/lucide/utensils.svg',
          rows: const [
            SpendeeBalanceTopCategoryRowModel(
              scope: '2. hely',
              category: 'Közlekedés',
              amount: '18 200 Ft',
              iconAsset: 'assets/icons/lucide/bus-front.svg',
              color: Color(0xFF3A95E6),
            ),
            SpendeeBalanceTopCategoryRowModel(
              scope: '3. hely',
              category: 'Egészség',
              amount: '12 400 Ft',
              iconAsset: 'assets/icons/lucide/heart-pulse.svg',
              color: Color(0xFFFF4C79),
            ),
            SpendeeBalanceTopCategoryRowModel(
              scope: '4. hely',
              category: 'Otthon',
              amount: '9 900 Ft',
              iconAsset: 'assets/icons/lucide/house.svg',
              color: Color(0xFF8B7DFA),
            ),
          ],
          rankDimension: SpendeeBalanceRankDimension.month,
          includeGhostTransactions: true,
        );
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: category,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
              onCategoryRankDimensionChanged: (value) =>
                  categorySelection = value,
              onVendorRankDimensionChanged: (value) => vendorSelection = value,
              onAverageDimensionChanged: (value) => averageSelection = value,
            ),
          ),
        );

        expect(find.text('Havi'), findsOneWidget);
        expect(find.text('Éves'), findsOneWidget);
        expect(find.text('Össz.'), findsOneWidget);
        expect(find.text('Élelmiszer'), findsOneWidget);
        expect(find.text('2. hely'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('spendee-balance-top-category-row-2')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey('spendee-balance-top-category-dimension-year'),
          ),
        );
        expect(categorySelection, SpendeeBalanceRankDimension.year);

        final vendor = SpendeeBalanceTopMerchantsModel(
          id: 'top-merchants',
          title: 'Top 4 kereskedő',
          selectedDimension: SpendeeBalanceMerchantDimension.month,
          rankDimension: SpendeeBalanceRankDimension.month,
          rows: const [
            SpendeeBalanceMerchantRowModel(
              merchant: 'Lidl',
              transactionCount: '4 tranzakció',
              amount: '13 810 Ft',
              iconAsset: 'assets/icons/lucide/store.svg',
              color: Color(0xFFF24CAE),
            ),
            SpendeeBalanceMerchantRowModel(
              merchant: 'Tesco',
              transactionCount: '3 tranzakció',
              amount: '9 220 Ft',
              iconAsset: 'assets/icons/lucide/shopping-cart.svg',
              color: Color(0xFF8B7DFA),
            ),
            SpendeeBalanceMerchantRowModel(
              merchant: 'MOL',
              transactionCount: '2 tranzakció',
              amount: '8 500 Ft',
              iconAsset: 'assets/icons/lucide/fuel.svg',
              color: Color(0xFFFA8A39),
            ),
            SpendeeBalanceMerchantRowModel(
              merchant: 'Wolt',
              transactionCount: '2 tranzakció',
              amount: '6 200 Ft',
              iconAsset: 'assets/icons/lucide/utensils.svg',
              color: Color(0xFFFB3E76),
            ),
          ],
          includeGhostTransactions: true,
        );
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: vendor,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
              onCategoryRankDimensionChanged: (value) =>
                  categorySelection = value,
              onVendorRankDimensionChanged: (value) => vendorSelection = value,
              onAverageDimensionChanged: (value) => averageSelection = value,
            ),
          ),
        );
        expect(find.text('Top 4 kereskedő'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('spendee-balance-top-merchant-row-3')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey('spendee-balance-top-vendor-dimension-all'),
          ),
        );
        expect(vendorSelection, SpendeeBalanceRankDimension.all);

        final average = SpendeeBalanceAverageDailyModel(
          id: 'average-daily',
          title: 'Átlagos napi költés',
          periodLabel: 'Elmúlt 7 nap',
          rollingTotalLabel: '42 000 Ft / 7 nap',
          averageLabel: '6 000 Ft / nap',
          dailyValues: const [3200, 7400, 5100, 6800],
          facts: const [
            SpendeeBalanceDailyFactModel(
              label: 'Egyenleg puffer',
              value: '18 nap',
            ),
            SpendeeBalanceDailyFactModel(
              label: 'Legmagasabb nap',
              value: '7 400 Ft',
            ),
            SpendeeBalanceDailyFactModel(
              label: 'Kiugrások > 9 000 Ft',
              value: '0 db',
            ),
          ],
          selectedDimension: SpendeeBalanceAverageDimension.week,
          iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
          includeGhostTransactions: true,
        );
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: average,
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
              onCategoryRankDimensionChanged: (value) =>
                  categorySelection = value,
              onVendorRankDimensionChanged: (value) => vendorSelection = value,
              onAverageDimensionChanged: (value) => averageSelection = value,
            ),
          ),
        );
        expect(find.text('Napi'), findsOneWidget);
        expect(find.text('Heti'), findsOneWidget);
        expect(find.text('Havi'), findsOneWidget);
        expect(find.text('Éves'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('spendee-balance-average-dimension-year')),
        );
        expect(averageSelection, SpendeeBalanceAverageDimension.year);
      },
    );

    testWidgets('every detail page has an independent semantic ghost toggle', (
      tester,
    ) async {
      for (final page in detailModels()) {
        String? changedId;
        bool? changedValue;
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: page,
              onGhostChanged: (id, value) {
                changedId = id;
                changedValue = value;
              },
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );

        final toggle = find.byKey(
          ValueKey('spendee-balance-detail-ghost-${page.id}'),
        );
        final semantics = tester.getSemantics(toggle);
        expect(semantics.flagsCollection.isToggled, isNot(Tristate.none));
        expect(semantics.flagsCollection.isToggled, Tristate.isTrue);
        await tester.tap(toggle);
        expect(changedId, page.id);
        expect(changedValue, isFalse);
      }
    });

    testWidgets(
      'ghost toggles expose one toggled node and keyboard activation',
      (tester) async {
        final fastChanges = <(String, bool)>[];
        await tester.pumpWidget(
          host(
            SpendeeBalanceFastInfoCard(
              model: fastInfoModels().first,
              onGhostChanged: (id, included) {
                fastChanges.add((id, included));
              },
            ),
          ),
        );

        final fastToggle = find.byKey(
          const ValueKey('spendee-balance-fast-info-ghost-no-spend'),
        );
        _expectGhostSemantics(tester, fastToggle, included: true);
        await _focusControl(tester, fastToggle);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(fastChanges, [('no-spend', false)]);
        await tester.pump(const Duration(milliseconds: 101));

        final detailChanges = <(String, bool)>[];
        await tester.pumpWidget(
          host(
            SpendeeBalanceDetailPage(
              model: detailModels(includeGhostTransactions: false).first,
              onGhostChanged: (id, included) {
                detailChanges.add((id, included));
              },
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
            ),
          ),
        );
        final detailToggle = find.byKey(
          const ValueKey('spendee-balance-detail-ghost-variable'),
        );
        _expectGhostSemantics(tester, detailToggle, included: false);
        await _focusControl(tester, detailToggle);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(detailChanges, [('variable', true)]);
        await tester.pump(const Duration(milliseconds: 101));
      },
    );
  });
}

List<SpendeeBalanceFastInfoCardModel> fastInfoModels() {
  return const [
    SpendeeBalanceNoSpendCardModel(
      id: 'no-spend',
      title: 'No-spend napok',
      value: '3 / 7 nap',
      secondary: 'Elmúlt 7 nap',
      includeGhostTransactions: true,
    ),
    SpendeeBalanceCategoryChangeCardModel(
      id: 'category-change',
      title: 'Legnagyobb kategóriaváltozás',
      value: '+14 200 Ft',
      category: 'Közlekedés',
      secondary: 'előző 30 naphoz képest',
      iconAsset: 'assets/icons/lucide/bus-front.svg',
      includeGhostTransactions: true,
    ),
    SpendeeBalanceLatestTransactionCardModel(
      id: 'latest-transaction',
      title: 'Utolsó tranzakció',
      amount: '-4 250 Ft',
      merchantAndTime: 'Lidl · ma, 11:42',
      iconAsset: 'assets/icons/lucide/store.svg',
      includeGhostTransactions: true,
    ),
    SpendeeBalanceTrendComparisonCardModel(
      id: 'trend-comparison',
      title: '30 napos ritmus',
      percentage: '18%',
      secondary: 'Ezt megelőző 30 naphoz képest',
      direction: SpendeeBalanceTrendDirection.up,
      iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
      includeGhostTransactions: true,
    ),
    SpendeeBalanceUpcomingRecurringCardModel(
      id: 'upcoming-recurring',
      title: 'Közelgő ismétlődés',
      name: 'Netflix',
      amount: '-3 490 Ft',
      dueText: 'aug. 4.',
      categoryIconAsset: 'assets/icons/lucide/clapperboard.svg',
      categoryColor: Color(0xFF8B5CF6),
      includeGhostTransactions: true,
    ),
  ];
}

List<SpendeeBalanceDetailPageModel> detailModels({
  bool includeGhostTransactions = true,
}) {
  return [
    SpendeeBalanceVariableBudgetModel(
      id: 'variable',
      title: 'Változó keret',
      selectedDimension: SpendeeBalanceBudgetDimension.day,
      dimensions: {
        SpendeeBalanceBudgetDimension.day:
            const SpendeeBalanceBudgetDimensionModel(
              dimension: SpendeeBalanceBudgetDimension.day,
              remainingLabel: 'Mára még elkölthető',
              remaining: '6 500 Ft',
              spentLabel: 'Ma elköltve',
              spent: '8 900 Ft',
              transactionLabel: 'Mai kiadási tételek',
              transactionCount: '4 db',
              thresholdLabel: 'Mai költés a kerethez képest',
              budgetLabel: 'Keret: 15 400 Ft',
              referenceLabel: '30 napos napi átlag: 10 100 Ft',
              progress: 8900 / 15400,
            ),
        SpendeeBalanceBudgetDimension.week:
            const SpendeeBalanceBudgetDimensionModel(
              dimension: SpendeeBalanceBudgetDimension.week,
              remainingLabel: 'A héten még elkölthető',
              remaining: '18 200 Ft',
              spentLabel: 'Héten elköltve',
              spent: '46 800 Ft',
              transactionLabel: 'Heti kiadási tételek',
              transactionCount: '17 db',
              thresholdLabel: 'Heti költés a kerethez képest',
              budgetLabel: 'Keret: 65 000 Ft',
              referenceLabel: 'Felhasználva: 72%',
              progress: .72,
            ),
        SpendeeBalanceBudgetDimension.month:
            const SpendeeBalanceBudgetDimensionModel(
              dimension: SpendeeBalanceBudgetDimension.month,
              remainingLabel: 'Ebben a hónapban még elkölthető',
              remaining: '98 800 Ft',
              spentLabel: 'Hónapban elköltve',
              spent: '151 200 Ft',
              transactionLabel: 'Havi kiadási tételek',
              transactionCount: '79 db',
              thresholdLabel: 'Havi költés a kerethez képest',
              budgetLabel: 'Keret: 250 000 Ft',
              referenceLabel: 'Felhasználva: 61%',
              progress: .6048,
            ),
      },
      includeGhostTransactions: includeGhostTransactions,
    ),
    SpendeeBalanceTopCategoriesModel(
      id: 'top-categories',
      title: 'Top kategóriák',
      featuredCategory: 'Élelmiszer',
      featuredMeta: 'Ma vezető kategóriája',
      featuredAmount: '12 400 Ft',
      featuredIconAsset: 'assets/icons/lucide/utensils.svg',
      rows: [
        SpendeeBalanceTopCategoryRowModel(
          scope: 'Ezen a héten',
          category: 'Élelmiszer',
          amount: '36 500 Ft',
          iconAsset: 'assets/icons/lucide/utensils.svg',
          color: Color(0xFF24C889),
        ),
        SpendeeBalanceTopCategoryRowModel(
          scope: 'Ebben a hónapban',
          category: 'Lakás',
          amount: '112 000 Ft',
          iconAsset: 'assets/icons/lucide/house.svg',
          color: Color(0xFFD932C9),
        ),
        SpendeeBalanceTopCategoryRowModel(
          scope: 'Idén eddig',
          category: 'Lakás',
          amount: '1 344 000 Ft',
          iconAsset: 'assets/icons/lucide/house.svg',
          color: Color(0xFFD932C9),
        ),
      ],
      includeGhostTransactions: includeGhostTransactions,
    ),
    SpendeeBalanceTopMerchantsModel(
      id: 'top-merchants',
      title: 'Top 5 kereskedő',
      selectedDimension: SpendeeBalanceMerchantDimension.month,
      rows: const [
        SpendeeBalanceMerchantRowModel(
          merchant: 'Lidl',
          transactionCount: '4 tranzakció',
          amount: '13 810 Ft',
          iconAsset: 'assets/icons/lucide/store.svg',
          color: Color(0xFF1FBF86),
        ),
        SpendeeBalanceMerchantRowModel(
          merchant: 'Tesco',
          transactionCount: '3 tranzakció',
          amount: '9 220 Ft',
          iconAsset: 'assets/icons/lucide/shopping-cart.svg',
          color: Color(0xFF8B7DFA),
        ),
        SpendeeBalanceMerchantRowModel(
          merchant: 'MOL',
          transactionCount: '2 tranzakció',
          amount: '15 210 Ft',
          iconAsset: 'assets/icons/lucide/fuel.svg',
          color: Color(0xFFFA8A39),
        ),
        SpendeeBalanceMerchantRowModel(
          merchant: 'Wolt',
          transactionCount: '2 tranzakció',
          amount: '9 700 Ft',
          iconAsset: 'assets/icons/lucide/utensils.svg',
          color: Color(0xFFFB3E76),
        ),
        SpendeeBalanceMerchantRowModel(
          merchant: 'BKK',
          transactionCount: '1 tranzakció',
          amount: '450 Ft',
          iconAsset: 'assets/icons/lucide/bus-front.svg',
          color: Color(0xFF3A95E6),
        ),
      ],
      includeGhostTransactions: includeGhostTransactions,
    ),
    SpendeeBalanceAverageDailyModel(
      id: 'average-daily',
      title: 'Átlagos napi költés',
      periodLabel: 'Elmúlt 30 nap',
      rollingTotalLabel: '191 100 Ft / 30 nap',
      averageLabel: '6 370 Ft / nap',
      dailyValues: [
        0,
        5500,
        6800,
        19800,
        7900,
        0,
        9000,
        9300,
        7000,
        9500,
        0,
        8200,
        9400,
        5500,
        15000,
        9000,
        0,
        6500,
        9200,
        3500,
        6400,
        0,
        5500,
        7300,
        4100,
        11000,
        8800,
        0,
        6900,
        0,
      ],
      facts: [
        SpendeeBalanceDailyFactModel(label: 'Egyenleg puffer', value: '58 nap'),
        SpendeeBalanceDailyFactModel(
          label: 'Legmagasabb nap',
          value: '19 800 Ft',
        ),
        SpendeeBalanceDailyFactModel(
          label: 'Kiugrások > 9 555 Ft',
          value: '3 db',
        ),
      ],
      iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
      includeGhostTransactions: includeGhostTransactions,
    ),
  ];
}

Row _nearestRow(WidgetTester tester, Finder descendant) {
  Row? row;
  tester.element(descendant).visitAncestorElements((ancestor) {
    if (ancestor.widget case final Row nearestRow) {
      row = nearestRow;
      return false;
    }
    return true;
  });
  return row!;
}

List<double> _directSizedBoxWidths(Row row) {
  return row.children
      .whereType<SizedBox>()
      .map((box) => box.width)
      .whereType<double>()
      .toList(growable: false);
}

BoxDecoration _firstDecoratedBoxDecoration(
  WidgetTester tester,
  Finder ancestor,
) {
  final decoratedBox = find
      .descendant(of: ancestor, matching: find.byType(DecoratedBox))
      .first;
  return tester.widget<DecoratedBox>(decoratedBox).decoration as BoxDecoration;
}

BoxDecoration _firstContainerDecoration(WidgetTester tester, Finder ancestor) {
  final container = find
      .descendant(of: ancestor, matching: find.byType(Container))
      .first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

void _expectDimensionSemantics(
  WidgetTester tester,
  Finder control, {
  required String label,
  required bool selected,
}) {
  final node = tester.getSemantics(control);
  final semantics = node.getSemanticsData();
  expect(semantics.label, label);
  expect(semantics.flagsCollection.isButton, isTrue);
  expect(
    semantics.flagsCollection.isSelected,
    selected ? Tristate.isTrue : Tristate.isFalse,
  );
  expect(semantics.flagsCollection.isToggled, Tristate.none);
  expect(semantics.hasAction(SemanticsAction.tap), isTrue);
  expect(node.childrenCount, 0);
  _expectNoDefaultMaterialInteraction(tester, control);
}

void _expectGhostSemantics(
  WidgetTester tester,
  Finder control, {
  required bool included,
}) {
  final node = tester.getSemantics(control);
  final semantics = node.getSemanticsData();
  expect(
    semantics.label,
    included
        ? 'Ghost tranzakciók beleszámítanak. Kikapcsolás.'
        : 'Ghost tranzakciók kizárva. Bekapcsolás.',
  );
  expect(semantics.flagsCollection.isButton, isTrue);
  expect(
    semantics.flagsCollection.isToggled,
    included ? Tristate.isTrue : Tristate.isFalse,
  );
  expect(semantics.flagsCollection.isSelected, Tristate.none);
  expect(semantics.hasAction(SemanticsAction.tap), isTrue);
  expect(node.childrenCount, 0);
  _expectNoDefaultMaterialInteraction(tester, control);
}

void _expectNoDefaultMaterialInteraction(WidgetTester tester, Finder control) {
  final inkWell = tester.widget<InkWell>(
    find.descendant(of: control, matching: find.byType(InkWell)),
  );
  expect(inkWell.excludeFromSemantics, isTrue);
  expect(inkWell.splashFactory, NoSplash.splashFactory);
  expect(inkWell.overlayColor, isA<WidgetStatePropertyAll<Color>>());
  expect(
    inkWell.overlayColor!.resolve(const <WidgetState>{WidgetState.pressed}),
    Colors.transparent,
  );
}

Future<void> _focusControl(WidgetTester tester, Finder control) async {
  final inkWell = find.descendant(of: control, matching: find.byType(InkWell));
  expect(
    inkWell,
    findsOneWidget,
    reason: 'the control needs one focusable keyboard activation surface',
  );
  final focusContext = tester.element(
    find.descendant(of: inkWell, matching: find.byType(Container)).first,
  );
  Focus.of(focusContext).requestFocus();
  await tester.pump();
  expect(Focus.of(focusContext).hasPrimaryFocus, isTrue);
}

void _expectInsetFocusOutline(
  WidgetTester tester, {
  required Rect controlRect,
  required ValueKey<String> outlineKey,
  BorderRadius? borderRadius,
  BoxShape shape = BoxShape.rectangle,
}) {
  final outline = find.byKey(outlineKey);
  expect(outline, findsOneWidget);
  expect(tester.getRect(outline), controlRect.deflate(1));
  final decoration =
      tester.widget<DecoratedBox>(outline).decoration as BoxDecoration;
  expect(
    decoration.border,
    Border.all(color: const Color(0x6B7D8798), width: 2),
  );
  expect(decoration.shape, shape);
  expect(decoration.borderRadius, borderRadius);
}

class _FastSurfaceExpectation {
  const _FastSurfaceExpectation({
    required this.border,
    required this.outerShadow,
    required this.innerShadow,
    this.gradientColors,
  });

  final Color border;
  final Color outerShadow;
  final Color innerShadow;
  final List<Color>? gradientColors;
}
