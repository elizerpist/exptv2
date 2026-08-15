import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_partner_swipe.dart';

void main() {
  test(
    'RED: the canonical LogBox painter is the only active-row presentation owner',
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
      expect(renderer, contains('_paintActiveSwipeSegment('));
      expect(renderer, isNot(contains('_isTransientSwipeSource')));
      expect(renderer, contains('canvas.clipRect(_activeSwipeViewportClip'));
      expect(viewport, contains('clipBehavior: Clip.none'));
    },
  );

  test(
    'canonical swipe painter translates the one complete row segment without a raster hot path',
    () {
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_partner_swipe.dart',
      ).readAsStringSync();
      final activeSegment = renderer.substring(
        renderer.indexOf('  bool _paintActiveSwipeSegment('),
        renderer.indexOf('  void _paintRowSeparator('),
      );
      expect(
        activeSegment,
        contains('canvas.translate(swipe.translationX, 0)'),
      );
      expect(activeSegment, contains('_paintRowSeparator('));
      expect(activeSegment, contains('_paintRowContent('));
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
    'canonical active segment starts at its real surface left and can reach screen x=0',
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
          requestedTranslation: -100,
        ),
        -29,
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
    'RED: swipe kinematics reaches the real screen edge without crossing it',
    () {
      final threshold =
          DashboardLogBoxPartnerSwipeKinematics.activationThreshold(
            globalLeft: 38,
          );
      expect(threshold, 36);
      expect(
        DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
          globalLeft: 38,
          requestedTranslation: -120,
        ),
        -38,
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

  testWidgets(
    'RED: only an intentional left-horizontal row gesture acquires partner swipe',
    (tester) async {
      var acquired = 0;
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
      await left.moveBy(const Offset(-40, 4));
      await tester.pump();
      await left.up();
      expect(acquired, 1);
      expect(ended, 1);
      expect(deltas, isNotEmpty);
      expect(deltas.last, lessThan(0));

      final right = await tester.startGesture(const Offset(160, 240));
      await right.moveBy(const Offset(40, 4));
      await tester.pump();
      await right.up();
      expect(acquired, 1);
      expect(ended, 1);

      final vertical = await tester.startGesture(const Offset(160, 240));
      await vertical.moveBy(const Offset(3, -80));
      await vertical.moveBy(const Offset(0, -20));
      await tester.pump();
      await vertical.up();
      expect(acquired, 1);
      expect(ended, 1);
      expect(verticalUpdates, greaterThan(0));

      final diagonal = await tester.startGesture(const Offset(160, 240));
      await diagonal.moveBy(const Offset(-20, -40));
      await tester.pump();
      await diagonal.up();
      expect(acquired, 1);
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
  blockSegmentRole: DashboardLogBoxBlockSegmentRole.singleton,
);
