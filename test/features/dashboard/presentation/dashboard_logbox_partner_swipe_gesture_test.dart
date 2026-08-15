import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_partner_swipe.dart';

void main() {
  test(
    'RED: transient row paint retains its static group chrome and direct-vector hot path',
    () {
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_partner_swipe.dart',
      ).readAsStringSync();
      final previewItem = renderer.substring(
        renderer.indexOf('  bool _paintItem('),
        renderer.indexOf('  bool _isTransientSwipeSource('),
      );
      final committedItem = renderer.substring(
        renderer.indexOf('  void _paintCommittedItem('),
        renderer.indexOf('  void _recordVerticalCacheMiss('),
      );

      for (final itemPainter in <String>[previewItem, committedItem]) {
        expect(
          itemPainter.indexOf('header.paint('),
          lessThan(itemPainter.indexOf('if (_isTransientSwipeSource')),
          reason:
              'The static painter must retain a group header while the '
              'transient overlay owns only the moving row.',
        );
        expect(
          itemPainter.indexOf('if (item.showSeparator)'),
          lessThan(itemPainter.indexOf('if (_isTransientSwipeSource')),
          reason: 'The overlay must not silently erase a prepared row divider.',
        );
      }

      expect(swipe, contains('required this.showSeparator'));
      expect(swipe, contains('if (source.showSeparator)'));
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
    'RED: a swipable LogBox row starts at the card gutter and can reach the screen edge',
    () {
      final interactionGutter =
          DashboardLogBoxPartnerSwipeKinematics.interactionGutter(
            contentGutter: DashboardLogBoxTokens.horizontalGutter,
            rowHorizontalInset: DashboardLogBoxTokens.rowHorizontalInset,
          );
      final bounds = DashboardLogBoxPartnerSwipeKinematics.rowBounds(
        surfaceGlobalOrigin: const Offset(0, 110),
        surfaceWidth: 378,
        rowTop: 55,
        rowHeight: DashboardLogBoxTokens.rowHeight,
        contentGutter: interactionGutter,
      );

      expect(interactionGutter, DashboardLogBoxTokens.rowHorizontalInset);
      expect(bounds.left, DashboardLogBoxTokens.rowHorizontalInset);
      expect(bounds.top, 165);
      expect(
        DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
          globalLeft: bounds.left,
          requestedTranslation: -100,
        ),
        -DashboardLogBoxTokens.rowHorizontalInset,
      );
    },
  );

  test(
    'RED: transient row content keeps its original surface coordinates while moving',
    () {
      final body = const Rect.fromLTWH(12, 165, 354, 55);

      expect(
        DashboardLogBoxPartnerSwipeKinematics.contentOriginX(
          globalRowBounds: body,
          contentGutter: 12,
          translationX: -12,
          coordinateSpaceOriginX: 0,
        ),
        -12,
      );
      expect(
        DashboardLogBoxPartnerSwipeKinematics.translatedToCoordinateSpace(
          globalBounds: const Rect.fromLTWH(12, 175, 34, 34),
          translationX: -12,
          coordinateSpaceOrigin: Offset.zero,
        ),
        const Rect.fromLTWH(0, 175, 34, 34),
      );
    },
  );

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
);
