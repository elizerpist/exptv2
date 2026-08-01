import 'dart:html' as html;

Future<void> toggleFullscreen() async {
  final document = html.document;
  if (document.fullscreenElement != null) {
    document.exitFullscreen();
    return;
  }
  await document.documentElement?.requestFullscreen();
}
