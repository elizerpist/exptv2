import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_partner_swipe.dart';

void main() {
  test(
    'hard-edged physical LogBox host contains the one local canonical swipe segment',
    () {
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_partner_swipe.dart',
      ).readAsStringSync();
      final dashboard = File(
        'lib/features/dashboard/presentation/core_dashboard.dart',
      ).readAsStringSync();
      final viewport = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_viewport.dart',
      ).readAsStringSync();

      expect(
        dashboard,
        isNot(contains('DashboardLogBoxPartnerSwipeOverlay')),
        reason:
            'A dashboard-wide overlay is a second row renderer, so it can '
            'only ever produce a clone of the canonical segment.',
      );
      expect(
        swipe,
        isNot(contains('class DashboardLogBoxPartnerSwipeOverlay')),
      );
      expect(renderer, contains('DashboardLogBoxActiveCanonicalSegmentLayer'));
      expect(renderer, contains('Transform.translate'));
      expect(renderer, contains('RepaintBoundary'));
      expect(renderer, contains('dashboard-logbox-active-canonical-segment'));
      final staticPainter = renderer.substring(
        renderer.indexOf('final class _DashboardLogBoxSurfacePainter'),
        renderer.indexOf('  void _paintCommittedViewport('),
      );
      expect(
        staticPainter,
        isNot(contains("?partnerSwipe,")),
        reason:
            "Translation ticks must not invalidate the static surface. The "
            "structural active-entry lease is the only swipe state it reads.",
      );
      expect(viewport, contains("clipBehavior: Clip.hardEdge"));
      expect(viewport, contains("dashboard-logbox-physical-scroll-host"));
      expect(viewport, contains("dashboard-logbox-static-content-inset"));
      expect(viewport, contains("SliverPadding("));
      final scrollViewportOwner = viewport.substring(
        viewport.indexOf("child: CustomScrollView("),
        viewport.indexOf("  void _onPointerDown("),
      );
      expect(scrollViewportOwner, contains("clipBehavior: Clip.hardEdge"));
      expect(scrollViewportOwner, isNot(contains("clipBehavior: Clip.none")));
      expect(scrollViewportOwner, contains("DashboardLogBoxRenderSurface("));
      final canonicalPaintStack = renderer.substring(
        renderer.indexOf("final class _DashboardLogBoxCanonicalPaintStack"),
        renderer.indexOf(
          "final class _DashboardLogBoxActiveCanonicalSegmentPresentation",
        ),
      );
      expect(canonicalPaintStack, contains("clipBehavior: Clip.none"));
      expect(
        canonicalPaintStack,
        contains("DashboardLogBoxActiveCanonicalSegmentLayer"),
      );
    },
  );

  test(
    'active canonical segment uses a retained transform without a raster hot path',
    () {
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_partner_swipe.dart',
      ).readAsStringSync();
      expect(renderer, contains('Transform.translate'));
      expect(renderer, contains('RepaintBoundary'));
      expect(renderer, contains('CustomPaint'));
      expect(renderer, contains('_paintGroupSurfaceExceptSegment('));
      for (final prohibited in <String>[
        'drawImage(',
        'drawImageRect(',
        'TextPainter(',
        'saveLayer(',
        'PictureRecorder(',
        'toImage(',
        'Dismissible',
      ]) {
        expect(swipe, isNot(contains(prohibited)), reason: prohibited);
      }
    },
  );

  test(
    'canonical active segment reaches screen x=0 then continues toward its physical offscreen cap',
    () {
      final bounds = DashboardLogBoxPartnerSwipeKinematics.rowBounds(
        surfaceGlobalOrigin: const Offset(29, 110),
        surfaceWidth: 378,
        rowTop: 55,
        rowHeight: DashboardLogBoxTokens.rowHeight,
        contentGutter: DashboardLogBoxTokens.horizontalGutter,
      );

      expect(bounds.left, 29);
      expect(bounds.top, 165);
      expect(
        DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
          globalLeft: bounds.left,
          rowWidth: bounds.width,
          requestedTranslation: -100,
        ),
        -100,
      );
    },
  );

  test('block segment morphology remains canonical while translated', () {
    const rect = Rect.fromLTWH(0, 165, 354, 55);
    final top = DashboardLogBoxBlockSegmentRole.top.bodyFor(rect);
    final middle = DashboardLogBoxBlockSegmentRole.middle.bodyFor(rect);
    final bottom = DashboardLogBoxBlockSegmentRole.bottom.bodyFor(rect);
    final singleton = DashboardLogBoxBlockSegmentRole.singleton.bodyFor(rect);

    expect(top.tlRadiusX, greaterThan(0));
    expect(top.blRadiusX, 0);
    expect(middle.tlRadiusX, 0);
    expect(middle.brRadiusX, 0);
    expect(bottom.tlRadiusX, 0);
    expect(bottom.brRadiusX, greaterThan(0));
    expect(singleton.tlRadiusX, greaterThan(0));
    expect(singleton.brRadiusX, greaterThan(0));
    expect(DashboardLogBoxBlockSegmentRole.top.ownsBottomShadow, isFalse);
    expect(DashboardLogBoxBlockSegmentRole.middle.ownsBottomShadow, isFalse);
    expect(DashboardLogBoxBlockSegmentRole.bottom.ownsBottomShadow, isTrue);
    expect(DashboardLogBoxBlockSegmentRole.singleton.ownsBottomShadow, isTrue);
  });

  test(
    'RED: swipe commit threshold and physical visual cap are independent',
    () {
      final threshold =
          DashboardLogBoxPartnerSwipeKinematics.activationThreshold(
            globalLeft: 17,
            rowWidth: 320,
          );
      expect(threshold, 36);
      expect(
        DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
          globalLeft: 17,
          rowWidth: 320,
          requestedTranslation: -120,
        ),
        -120,
      );
      expect(
        DashboardLogBoxPartnerSwipeKinematics.commits(
          translationX: -35,
          activationThreshold: threshold,
        ),
        isFalse,
      );
      expect(
        DashboardLogBoxPartnerSwipeKinematics.commits(
          translationX: -36,
          activationThreshold: threshold,
        ),
        isTrue,
      );
    },
  );

  test(
    'RED: candidate travel remains continuous through arena acquisition',
    () {
      final swipe = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_partner_swipe.dart',
      ).readAsStringSync();

      expect(swipe, contains('translationFromAcquisition('));
      expect(swipe, contains('translationFromCandidate('));
      expect(swipe, contains('onSwipeCandidate?.call(target);'));
      expect(
        DashboardLogBoxPartnerSwipeKinematics.translationFromCandidate(
          rawTranslation: -9,
        ),
        -9,
        reason:
            'A provisional horizontal segment has already followed -9px of '
            'finger movement; formal arena ownership must preserve it instead '
            'of resetting to zero or replaying a jump.',
      );
    },
  );

  test('RED: translation ticks do not notify static surface listeners', () {
    final controller = DashboardLogBoxPartnerSwipeController(
      vsync: TestVSync(),
    );
    addTearDown(controller.dispose);
    var structuralNotifications = 0;
    controller.addListener(() => structuralNotifications += 1);

    expect(controller.begin(_target()), isTrue);
    expect(structuralNotifications, 1);
    controller.update(-24);

    expect(
      structuralNotifications,
      1,
      reason:
          'Only start/end alters the static source lease; dx belongs to the '
          'isolated active-segment transform.',
    );
  });

  test('one horizontal gesture emits one aggregated compositor summary', () {
    FluviDiagnosticLogger.clear();
    final controller = DashboardLogBoxPartnerSwipeController(
      vsync: TestVSync(),
    );
    addTearDown(controller.dispose);

    controller
      ..notePointerDown()
      ..begin(_target())
      ..notePointerMove(-4)
      ..update(-4)
      ..noteAcquired()
      ..notePointerMove(-48)
      ..update(-48);
    expect(controller.finish(), isNotNull);
    controller.completeFocusPublication();

    final summary = FluviDiagnosticLogger.entries.singleWhere(
      (event) => event.stage == 'PARTNER_SWIPE_PERF_SUMMARY',
    );
    expect(summary.message, contains('rawHorizontalTravel=48'));
    expect(summary.message, contains('visualHorizontalTravel=48'));
    expect(summary.message, contains('commitThreshold=36'));
    expect(summary.message, contains('compositorTransformUpdateCount=2'));
    expect(summary.message, contains('committed=true'));
  });

  testWidgets(
    'RED: only an intentional left-horizontal row gesture acquires partner swipe',
    (tester) async {
      var acquired = 0;
      var candidates = 0;
      var ended = 0;
      var verticalUpdates = 0;
      final deltas = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                DashboardLogBoxPartnerSwipeGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      DashboardLogBoxPartnerSwipeGestureRecognizer
                    >(DashboardLogBoxPartnerSwipeGestureRecognizer.new, (
                      recognizer,
                    ) {
                      recognizer.hitTest = (_) => _target();
                      recognizer.onSwipeCandidate = (_) {
                        candidates += 1;
                      };
                      recognizer.onSwipeAcquired = (_) {
                        acquired += 1;
                      };
                      recognizer.onSwipeUpdate = deltas.add;
                      recognizer.onSwipeEnd = () {
                        ended += 1;
                      };
                    }),
                VerticalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      VerticalDragGestureRecognizer
                    >(VerticalDragGestureRecognizer.new, (recognizer) {
                      recognizer.onUpdate = (_) {
                        verticalUpdates += 1;
                      };
                    }),
              },
              child: const SizedBox(width: 320, height: 600),
            ),
          ),
        ),
      );

      final left = await tester.startGesture(const Offset(160, 240));
      await left.moveBy(const Offset(-2, 0));
      await left.moveBy(const Offset(-3, 0));
      await left.moveBy(const Offset(-35, 4));
      await left.moveBy(const Offset(-12, 0));
      await tester.pump();
      await left.up();
      expect(acquired, 1);
      expect(candidates, 1);
      expect(ended, 1);
      expect(deltas, isNotEmpty);
      expect(deltas.first, -2);
      expect(
        deltas,
        contains(-5),
        reason:
            'Candidate updates must preserve pre-acceptance finger travel '
            'instead of leaving the row motionless through touch slop.',
      );
      expect(deltas.last, lessThan(0));

      final right = await tester.startGesture(const Offset(160, 240));
      await right.moveBy(const Offset(40, 4));
      await tester.pump();
      await right.up();
      expect(acquired, 1);
      expect(candidates, 1);
      expect(ended, 1);

      final vertical = await tester.startGesture(const Offset(160, 240));
      await vertical.moveBy(const Offset(3, -80));
      await vertical.moveBy(const Offset(0, -20));
      await tester.pump();
      await vertical.up();
      expect(acquired, 1);
      expect(candidates, 1);
      expect(ended, 1);
      expect(verticalUpdates, greaterThan(0));

      final diagonal = await tester.startGesture(const Offset(160, 240));
      await diagonal.moveBy(const Offset(-20, -40));
      await tester.pump();
      await diagonal.up();
      expect(acquired, 1);
      expect(candidates, 1);
      expect(ended, 1);
    },
  );
}

DashboardLogBoxRowHitTarget _target() => DashboardLogBoxRowHitTarget(
  row: DashboardLogRowViewModel(
    entryId: 'entry-1',
    displayName: 'MVM',
    categoryDisplayName: 'Rezsi',
    formattedAmount: '-1 000 Ft',
    displayTime: '12:00',
    amountStyle: LogAmountStyle.expense,
    categoryColorId: 'color_12',
    categoryIconId: 'icon_03',
    categoryId: 'utilities',
    partnerId: 'mvm',
    partnerDisplayName: 'MVM',
    semanticLabel: 'MVM',
  ),
  globalRowBounds: const Rect.fromLTWH(36, 200, 320, 55),
  globalAvatarBounds: const Rect.fromLTWH(48, 210, 34, 34),
  localRowTop: 200,
  blockSegmentRole: DashboardLogBoxBlockSegmentRole.singleton,
);
