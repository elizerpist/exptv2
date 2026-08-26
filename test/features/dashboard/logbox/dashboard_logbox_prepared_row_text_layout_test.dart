import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/presentation/dashboard_logbox_prepared_row_text_layout.dart';

void main() {
  test(
    'RED: cooperative row layout yields between distinct paragraph layouts',
    () async {
      var checkpoints = 0;

      final layout =
          await DashboardPreparedLogBoxRowTextLayout.prepareCooperatively(
            row: _row(),
            surfaceWidth: 378,
            contentIdentity: 1,
            shouldCheckpoint: () => true,
            checkpoint: () async {
              checkpoints += 1;
            },
          );
      addTearDown(layout.dispose);

      // One row owns four independent paragraphs.  The scene cache may keep
      // the completed row atomic, but no one work unit may synchronously lay
      // out all four before it gives the foreground scheduler a chance.
      expect(checkpoints, 3);
      expect(layout.title.width, greaterThan(0));
      expect(layout.secondary.width, greaterThan(0));
      expect(layout.amount.width, greaterThan(0));
      expect(layout.time.width, greaterThan(0));
    },
  );

  test(
    'amount palette tint records once and stays out of repeat paint work',
    () {
      final layout = DashboardPreparedLogBoxRowTextLayout.prepare(
        row: _row(),
        surfaceWidth: 378,
        contentIdentity: 1,
      );
      addTearDown(layout.dispose);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      layout.paint(
        canvas,
        0,
        rowHeight: 55,
        amountForeground: const Color(0xFFB42318),
      );
      expect(layout.amountTintPictureBuildCount, 0);

      layout.paint(
        canvas,
        55,
        rowHeight: 55,
        amountForeground: const Color(0xFFFF3E73),
      );
      layout.paint(
        canvas,
        110,
        rowHeight: 55,
        amountForeground: const Color(0xFFFF3E73),
      );

      expect(layout.amountTintPictureBuildCount, 1);
      recorder.endRecording().dispose();
    },
  );
}

DashboardLogRowViewModel _row() => DashboardLogRowViewModel(
  entryId: 'row-1',
  displayName: 'Élelmiszerbolt vásárlás',
  categoryDisplayName: 'Élelmiszer',
  formattedAmount: '12 345 Ft',
  displayTime: '12:34',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'orange',
  categoryIconId: 'shopping_bag',
  semanticLabel: 'Élelmiszerbolt vásárlás, 12 345 forint',
);
