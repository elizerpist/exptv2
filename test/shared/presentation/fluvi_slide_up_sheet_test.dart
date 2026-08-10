import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/presentation/fluvi_slide_up_sheet.dart';

void main() {
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
