import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/presentation/fluvi_slide_up_sheet.dart';

void main() {
  testWidgets(
    'reports reverse completion only after the sheet layer is removed',
    (tester) async {
      var open = true;
      final lifecycle = <String>[];
      bool? sheetWasRemovedAtCompletion;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                FluviSlideUpSheet(
                  isOpen: open,
                  duration: const Duration(milliseconds: 200),
                  onDismissTransitionStarted: () => lifecycle.add('started'),
                  onDismissTransitionCompleted: () {
                    sheetWasRemovedAtCompletion = find
                        .byKey(FluviSlideUpSheet.sheetKey)
                        .evaluate()
                        .isEmpty;
                    lifecycle.add('done');
                  },
                  child: const SizedBox.expand(),
                ),
                TextButton(
                  onPressed: () => setState(() => open = false),
                  child: const Text('close'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('close'));
      await tester.pump();

      expect(lifecycle, <String>['started']);
      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsOneWidget);

      await tester.pumpAndSettle();

      expect(lifecycle, <String>['started', 'done']);
      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsNothing);
      expect(
        sheetWasRemovedAtCompletion,
        isTrue,
        reason:
            'Route-sensitive background work may resume only after the sheet '
            'layer has left the widget tree.',
      );
    },
  );

  testWidgets(
    'uses one slide-up layer with a sticky footer and releases hits after close',
    (tester) async {
      var open = true;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                const SizedBox.expand(child: ColoredBox(color: Colors.white)),
                FluviSlideUpSheet(
                  isOpen: open,
                  onDismiss: () => setState(() => open = false),
                  stickyFooter: const Text('26 tranzakció mutatása'),
                  child: const Text('Query content'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsOneWidget);
      expect(find.text('Query content'), findsOneWidget);
      expect(find.text('26 tranzakció mutatása'), findsOneWidget);

      await tester.tapAt(const Offset(12, 12));
      await tester.pumpAndSettle();

      expect(find.byKey(FluviSlideUpSheet.sheetKey), findsNothing);
    },
  );
}
