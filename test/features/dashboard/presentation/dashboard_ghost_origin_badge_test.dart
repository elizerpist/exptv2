import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the common Ghost-origin painter is reached by preview, committed, and swipe row paths',
    () {
      final source = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final helperStart = source.indexOf('  void _paintGhostOriginBadge(');
      final helper = source.substring(
        helperStart,
        source.indexOf('  void _drawPreparedVectorResource(', helperStart),
      );

      expect(helper, contains('rasters.ghostOriginGlyph'));
      expect(helper, contains('timeBounds.left - 4 - size / 2'));
      expect(helper, contains('const size = 14.0'));
      expect(
        RegExp(r'_paintGhostOriginBadge\(').allMatches(source).length,
        5,
        reason:
            'Four row paint paths use the one helper; the fifth occurrence '
            'is its declaration.',
      );
    },
  );
}
