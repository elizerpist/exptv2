import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> toggleFullscreen() async {
  final document = web.document;
  if (document.fullscreenElement != null) {
    await document.exitFullscreen().toDart;
    return;
  }
  final documentElement = document.documentElement;
  if (documentElement != null) {
    await documentElement.requestFullscreen().toDart;
  }
}
