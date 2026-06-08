import 'dart:ui';

import '../../models/calendar_menu_mode.dart';

class CalendarCanvasLayout {
  const CalendarCanvasLayout({required this.size, required this.monthRects});

  final Size size;
  final List<Rect> monthRects;

  static CalendarCanvasLayout focusedMonth({required double width}) {
    final cardHeight = (width * 0.98).clamp(300.0, 430.0).toDouble();
    final rect = Rect.fromLTWH(0, 0, width, cardHeight);
    return CalendarCanvasLayout(size: rect.size, monthRects: [rect]);
  }

  static CalendarCanvasLayout calculate({
    required double width,
    required CalendarMenuMode mode,
  }) {
    final cardGap = width * 0.04;
    final cardWidth = width * 0.48;
    const cardHeight = 200.0;
    const rowGap = 15.0;
    final rects = <Rect>[];
    for (var index = 0; index < 12; index += 1) {
      final row = index ~/ 2;
      final column = index % 2;
      final left = column == 0 ? 0.0 : cardWidth + cardGap;
      final top = row * (cardHeight + rowGap);
      rects.add(Rect.fromLTWH(left, top, cardWidth, cardHeight));
    }
    final totalHeight = 6 * cardHeight + 5 * rowGap;
    return CalendarCanvasLayout(
      size: Size(width, totalHeight),
      monthRects: rects,
    );
  }
}
