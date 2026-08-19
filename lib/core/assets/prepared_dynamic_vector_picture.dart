import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart' as vg;

/// A frame-owned, fully decoded vector display list.
///
/// Feature presentation code may borrow this resource to paint, but all SVG
/// source decoding remains in this core resource boundary. The owning bounded
/// frame must call [dispose] exactly once when it is evicted.
final class PreparedDynamicVectorPicture {
  PreparedDynamicVectorPicture({
    required this.source,
    required this.pictureInfo,
  });

  final String source;
  final vg.PictureInfo pictureInfo;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    pictureInfo.picture.dispose();
  }
}

/// Core decode boundary for bounded, dynamic vector banks.
///
/// Callers must complete preparation before publishing a frame; widgets only
/// receive [PreparedDynamicVectorPicture] values and never parse SVG sources.
abstract interface class DynamicVectorPicturePreparer {
  Future<List<PreparedDynamicVectorPicture>> prepare(Iterable<String> sources);
}

final class FlutterDynamicVectorPicturePreparer
    implements DynamicVectorPicturePreparer {
  const FlutterDynamicVectorPicturePreparer();

  @override
  Future<List<PreparedDynamicVectorPicture>> prepare(
    Iterable<String> sources,
  ) async {
    final pictures = <PreparedDynamicVectorPicture>[];
    try {
      for (final source in sources) {
        final info = await vg.vg.loadPicture(SvgStringLoader(source), null);
        pictures.add(
          PreparedDynamicVectorPicture(source: source, pictureInfo: info),
        );
      }
      return List<PreparedDynamicVectorPicture>.unmodifiable(pictures);
    } on Object {
      for (final picture in pictures) {
        picture.dispose();
      }
      rethrow;
    }
  }
}

/// Paint-only vector view. A selection is a retained-picture lookup followed
/// by one synchronous [Canvas.drawPicture] call.
final class PreparedDynamicVectorPictureView extends StatelessWidget {
  const PreparedDynamicVectorPictureView({
    super.key,
    required this.picture,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final PreparedDynamicVectorPicture picture;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PreparedDynamicVectorPicturePainter(
      picture: picture,
      fit: fit,
      alignment: alignment,
    ),
  );
}

final class _PreparedDynamicVectorPicturePainter extends CustomPainter {
  const _PreparedDynamicVectorPicturePainter({
    required this.picture,
    required this.fit,
    required this.alignment,
  });

  final PreparedDynamicVectorPicture picture;
  final BoxFit fit;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    if (picture.isDisposed || size.isEmpty) return;
    final sourceSize = picture.pictureInfo.size;
    if (sourceSize.isEmpty) return;
    final fitted = applyBoxFit(fit, sourceSize, size);
    final destination = alignment.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.save();
    canvas.translate(destination.left, destination.top);
    canvas.scale(
      destination.width / sourceSize.width,
      destination.height / sourceSize.height,
    );
    canvas.drawPicture(picture.pictureInfo.picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreparedDynamicVectorPicturePainter oldDelegate) =>
      !identical(oldDelegate.picture, picture) ||
      oldDelegate.fit != fit ||
      oldDelegate.alignment != alignment;
}
