import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart' as vg;

import 'budget_category_distribution_svg.dart';

/// Renderer-cache owner shared by every Budget Card2 donut page. It uses only
/// flutter_svg's public loader/cache API, so first user exposure never needs
/// to parse a just-created source.
abstract interface class BudgetDistributionSvgPrewarmer {
  Future<void> prewarm(Iterable<String> sources);
}

final class FlutterBudgetDistributionSvgPrewarmer
    implements BudgetDistributionSvgPrewarmer {
  const FlutterBudgetDistributionSvgPrewarmer();

  @override
  Future<void> prewarm(Iterable<String> sources) async {
    for (final source in sources) {
      await SvgStringLoader(source).loadBytes(null);
    }
  }
}

/// Frame-owned, fully decoded dynamic vector resource. Unlike the source cache
/// above, this retains the exact display list that [CustomPaint] draws during a
/// Budget semantic selection. The bounded drawable-frame cache owns disposal.
final class BudgetDistributionPreparedPicture {
  BudgetDistributionPreparedPicture({
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

/// Decoder boundary for dynamic Budget SVG banks. Tests can observe this
/// single pre-publication seam without putting vector decoding in a widget.
abstract interface class BudgetDistributionPicturePreparer {
  Future<List<BudgetDistributionPreparedPicture>> prepare(
    Iterable<String> sources,
  );
}

final class FlutterBudgetDistributionPicturePreparer
    implements BudgetDistributionPicturePreparer {
  const FlutterBudgetDistributionPicturePreparer();

  @override
  Future<List<BudgetDistributionPreparedPicture>> prepare(
    Iterable<String> sources,
  ) async {
    final pictures = <BudgetDistributionPreparedPicture>[];
    try {
      for (final source in sources) {
        final info = await vg.vg.loadPicture(SvgStringLoader(source), null);
        pictures.add(
          BudgetDistributionPreparedPicture(source: source, pictureInfo: info),
        );
      }
      return List<BudgetDistributionPreparedPicture>.unmodifiable(pictures);
    } on Object {
      for (final picture in pictures) {
        picture.dispose();
      }
      rethrow;
    }
  }
}

/// Paint-only view for a dynamic Budget donut. It deliberately has no loader,
/// source string or asynchronous state: a selection is a retained-picture
/// lookup followed by one synchronous `canvas.drawPicture` call.
final class BudgetDistributionPreparedPictureView extends StatelessWidget {
  const BudgetDistributionPreparedPictureView({
    super.key,
    required this.picture,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final BudgetDistributionPreparedPicture picture;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BudgetDistributionPreparedPicturePainter(
      picture: picture,
      fit: fit,
      alignment: alignment,
    ),
  );
}

final class _BudgetDistributionPreparedPicturePainter extends CustomPainter {
  const _BudgetDistributionPreparedPicturePainter({
    required this.picture,
    required this.fit,
    required this.alignment,
  });

  final BudgetDistributionPreparedPicture picture;
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
  bool shouldRepaint(_BudgetDistributionPreparedPicturePainter oldDelegate) =>
      !identical(oldDelegate.picture, picture) ||
      oldDelegate.fit != fit ||
      oldDelegate.alignment != alignment;
}

/// Production SVG source authority shared by category and partner. The
/// selected index is null for the read-only Partner page.
abstract interface class BudgetDistributionSvgSourceGenerator {
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  });
}

final class FluviBudgetDistributionSvgSourceGenerator
    implements BudgetDistributionSvgSourceGenerator {
  const FluviBudgetDistributionSvgSourceGenerator();

  @override
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) => BudgetCategoryDistributionSvg.flutterRenderable(
    BudgetCategoryDistributionSvg.clayDonut(
      slices: slices,
      selectedIndex: selectedIndex,
    ),
  );
}

/// Compatibility names retained for the existing category visual-bank public
/// API. Both aliases resolve to the single production implementation above.
typedef BudgetCategoryDistributionSvgPrewarmer = BudgetDistributionSvgPrewarmer;
typedef FlutterSvgBudgetCategoryDistributionPrewarmer =
    FlutterBudgetDistributionSvgPrewarmer;
typedef BudgetCategoryDistributionSvgSourceGenerator =
    BudgetDistributionSvgSourceGenerator;
typedef FluviBudgetCategoryDistributionSvgSourceGenerator =
    FluviBudgetDistributionSvgSourceGenerator;
