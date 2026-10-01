import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_temporal_content_header.dart';

void main() {
  testWidgets(
    'MIND-TEMPORAL-HEADER-01 RED: one fixed two-line chrome defines title and subtitle geometry',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: MindTemporalContentHeader(
                title: 'SUM aktivitás',
                subtitle: '2025–2026 · 24 hónap',
              ),
            ),
          ),
        ),
      );

      expect(find.text('SUM aktivitás'), findsOneWidget);
      expect(find.text('2025–2026 · 24 hónap'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MindTemporalContentHeader)).height,
        mindTemporalContentHeaderHeight,
      );
      final title = tester.widget<Text>(find.text('SUM aktivitás'));
      final subtitle = tester.widget<Text>(find.text('2025–2026 · 24 hónap'));
      expect(title.style!.fontSize, 11);
      expect(subtitle.style!.fontSize, 8);
    },
  );
}
