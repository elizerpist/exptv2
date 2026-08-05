import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> toggleFullscreen() async {
  final document = web.document;
  if (document.fullscreenElement != null) {
    await document.exitFullscreen().toDart;
    return;
  }
  await document.documentElement?.requestFullscreen().toDart;
}
