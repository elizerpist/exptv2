import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../categories/catalog/category_color_catalog.dart';
import '../categories/catalog/category_icon_catalog.dart';
import '../design/dashboard_mode_palette.dart';

/// A process-retained, already decoded vector picture.
///
/// Widgets only paint this object. They cannot load an asset or invoke the
/// vector codec, which keeps row creation outside the asset/decode pipeline.
@immutable
final class PreparedVectorPicture {
  const PreparedVectorPicture._({
    required this.assetPath,
    required this.pictureInfo,
  });

  final String assetPath;
  final PictureInfo pictureInfo;
}

/// A self-contained white category glyph for the LogBox hot path.
///
/// The glyph remains a [ui.Picture] until the engine rasterizes it at the
/// actual row transform. Its compiled source asset already contains the white
/// vector paint commands, so replaying this picture never depends on or
/// modifies pixels previously painted to the outer LogBox canvas. The atlas
/// owns and disposes this display list; a DPR-specific
/// [PreparedLogBoxRasterSet] only borrows it.
@immutable
final class PreparedLogBoxVectorGlyph {
  const PreparedLogBoxVectorGlyph._({
    required this.picture,
    required this.logicalSize,
  });

  final ui.Picture picture;
  final Size logicalSize;

  void dispose() => picture.dispose();
}

/// Bounded, device-scale raster resources used by the LogBox hot paint path.
///
/// The set cardinality is defined by the category catalogs, never by ledger
/// row count. LogBox painting composes one prepared badge background, one
/// prepared vector glyph and one group surface without vector decode, gradient
/// shader creation or a row-time tint saveLayer.
@immutable
final class PreparedLogBoxRasterSprite {
  const PreparedLogBoxRasterSprite._({
    required this.image,
    required this.sourceRect,
  });

  final ui.Image image;
  final Rect sourceRect;
}

@immutable
final class PreparedLogBoxRasterSet {
  const PreparedLogBoxRasterSet._({
    required this.devicePixelRatio,
    required this.logicalBadgeSize,
    required this.logicalIconSize,
    required this.badgeAtlas,
    required this.badges,
    required this.glyphs,
    required this.groupSurface,
    required this.groupSurfaceCenterSlice,
    required this.groupSurfaceOutset,
    required this.estimatedBytes,
  });

  final double devicePixelRatio;
  final double logicalBadgeSize;
  final double logicalIconSize;
  final ui.Image badgeAtlas;
  final List<PreparedLogBoxRasterSprite> badges;
  final List<PreparedLogBoxVectorGlyph> glyphs;
  final ui.Image groupSurface;
  final Rect groupSurfaceCenterSlice;
  final double groupSurfaceOutset;
  final int estimatedBytes;

  int get badgeCount => badges.length;
  int get glyphCount => glyphs.length;
  int get rasterSurfaceCount => 2;

  PreparedLogBoxRasterSprite badge(int handle) {
    if (handle < 0 || handle >= badges.length) {
      throw RangeError.range(handle, 0, badges.length - 1, 'handle');
    }
    return badges[handle];
  }

  PreparedLogBoxVectorGlyph glyph(int handle) {
    if (handle < 0 || handle >= glyphs.length) {
      throw RangeError.range(handle, 0, glyphs.length - 1, 'handle');
    }
    return glyphs[handle];
  }

  bool matches(double ratio) => (devicePixelRatio - ratio).abs() < .001;

  void dispose() {
    badgeAtlas.dispose();
    groupSurface.dispose();
  }
}

final class _PreparedRasterAtlasImage {
  const _PreparedRasterAtlasImage({
    required this.image,
    required this.sourceRects,
  });

  final ui.Image image;
  final List<Rect> sourceRects;
}

final class _VectorAssetSpec {
  const _VectorAssetSpec({required this.path, required this.loader});

  final String path;
  final AssetBytesLoader loader;
}

/// Canonical bootstrap owner for every vector used by the dashboard surface.
///
/// The atlas decodes each unique `.vec` asset once with bounded concurrency,
/// publishes the complete handle table atomically, and retains it for the
/// process lifetime. [prepare] is idempotent and coalesces concurrent callers.
final class PreparedVectorAssetAtlas {
  PreparedVectorAssetAtlas({int maximumConcurrentDecodes = 8})
    : _maximumConcurrentDecodes = maximumConcurrentDecodes {
    if (maximumConcurrentDecodes < 1 || maximumConcurrentDecodes > 16) {
      throw ArgumentError.value(
        maximumConcurrentDecodes,
        'maximumConcurrentDecodes',
        'must be between 1 and 16',
      );
    }
  }

  static final PreparedVectorAssetAtlas instance = PreparedVectorAssetAtlas();

  static const int incomeWalletHandle = 51;
  static const int expenseBagHandle = 52;
  static const int brandMarkHandle = 53;

  /// Normal dashboard icon handles plus the three non-category dashboard
  /// pictures. The fallback deliberately aliases the first catalog icon.
  static const int assetCount = 54;
  static const int logBoxGlyphAssetCount = 51;
  static const int uniqueLogBoxGlyphAssetCount = 50;

  /// All unique normal and dedicated LogBox-white source pictures are decoded
  /// once by this single atlas owner.
  static const int uniqueAssetCount = 103;
  static const double logBoxBadgeLogicalSize = 34;
  static const double logBoxIconLogicalSize = 18;
  static const double logBoxGroupSurfaceLogicalSize = 128;
  static const double logBoxGroupSurfaceOutset = 36;
  static const double logBoxGroupSurfaceCardSize = 56;
  static const int _logBoxRasterAtlasColumns = 8;

  static const _VectorAssetSpec _incomeWallet = _VectorAssetSpec(
    path: 'assets/fluvi/actions/income_wallet.svg.vec',
    loader: AssetBytesLoader('assets/fluvi/actions/income_wallet.svg.vec'),
  );
  static const _VectorAssetSpec _expenseBag = _VectorAssetSpec(
    path: 'assets/fluvi/actions/expense_bag.svg.vec',
    loader: AssetBytesLoader('assets/fluvi/actions/expense_bag.svg.vec'),
  );
  static const _VectorAssetSpec _brandMark = _VectorAssetSpec(
    path: 'assets/fluvi/brand/fluvi_mark.svg.vec',
    loader: AssetBytesLoader('assets/fluvi/brand/fluvi_mark.svg.vec'),
  );

  final int _maximumConcurrentDecodes;
  List<PreparedVectorPicture>? _pictures;
  List<LinearGradient>? _categoryGradients;
  Future<void>? _inFlight;
  Future<void>? _logBoxRasterInFlight;
  PreparedLogBoxRasterSet? _logBoxRasters;
  List<PreparedLogBoxVectorGlyph>? _logBoxGlyphs;
  int _pictureDecodeCount = 0;
  int _prepareDurationMicros = 0;
  int _logBoxRasterBuildCount = 0;
  int _logBoxGlyphBuildCount = 0;
  int _logBoxRasterPrepareDurationMicros = 0;
  bool _disposed = false;

  bool get isReady =>
      _pictures != null && _categoryGradients != null && _logBoxGlyphs != null;
  int get pictureCount => _pictures?.length ?? 0;
  int get logBoxGlyphCount => _logBoxGlyphs?.length ?? 0;
  int get pictureDecodeCount => _pictureDecodeCount;
  int get prepareDurationMicros => _prepareDurationMicros;
  int get logBoxRasterBuildCount => _logBoxRasterBuildCount;
  int get logBoxGlyphBuildCount => _logBoxGlyphBuildCount;
  int get logBoxRasterPrepareDurationMicros =>
      _logBoxRasterPrepareDurationMicros;
  int get logBoxRasterByteEstimate => _logBoxRasters?.estimatedBytes ?? 0;
  int get logBoxRasterSurfaceCount => _logBoxRasters?.rasterSurfaceCount ?? 0;
  bool get hasLogBoxRasters => _logBoxRasters != null;

  Future<void> prepare() {
    if (_disposed) {
      throw StateError('Prepared vector asset atlas has been disposed.');
    }
    if (isReady) return Future<void>.value();
    final existing = _inFlight;
    if (existing != null) return existing;
    late final Future<void> operation;
    operation = _prepare().whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> prepareLogBoxRasters({required double devicePixelRatio}) {
    if (_disposed) {
      throw StateError('Prepared vector asset atlas has been disposed.');
    }
    if (devicePixelRatio <= 0 || !devicePixelRatio.isFinite) {
      throw ArgumentError.value(
        devicePixelRatio,
        'devicePixelRatio',
        'must be finite and greater than zero',
      );
    }
    final current = _logBoxRasters;
    if (current != null && current.matches(devicePixelRatio)) {
      return Future<void>.value();
    }
    final existing = _logBoxRasterInFlight;
    if (existing != null) return existing;
    late final Future<void> operation;
    operation = _prepareLogBoxRasters(devicePixelRatio).whenComplete(() {
      if (identical(_logBoxRasterInFlight, operation)) {
        _logBoxRasterInFlight = null;
      }
    });
    _logBoxRasterInFlight = operation;
    return operation;
  }

  PreparedLogBoxRasterSet logBoxRastersFor(double devicePixelRatio) {
    final result = _logBoxRasters;
    if (result == null || !result.matches(devicePixelRatio)) {
      throw StateError(
        'LogBox raster resources are not prepared for DPR '
        '$devicePixelRatio.',
      );
    }
    return result;
  }

  PreparedVectorPicture categoryIcon(int handle) {
    if (handle < 0 || handle > CategoryIconCatalog.values.length) {
      throw RangeError.range(
        handle,
        0,
        CategoryIconCatalog.values.length,
        'handle',
      );
    }
    return picture(handle);
  }

  LinearGradient categoryGradient(int handle) {
    final gradients = _categoryGradients;
    if (gradients == null) {
      throw StateError('Prepared vector asset atlas is not ready.');
    }
    if (handle < 0 || handle >= gradients.length) {
      throw RangeError.range(handle, 0, gradients.length - 1, 'handle');
    }
    return gradients[handle];
  }

  PreparedVectorPicture picture(int handle) {
    final pictures = _pictures;
    if (pictures == null) {
      throw StateError('Prepared vector asset atlas is not ready.');
    }
    if (handle < 0 || handle >= pictures.length) {
      throw RangeError.range(handle, 0, pictures.length - 1, 'handle');
    }
    return pictures[handle];
  }

  Future<void> _prepare() async {
    final prepareTimer = Stopwatch()..start();
    final normalPictureSpecs = <_VectorAssetSpec>[
      for (final token in CategoryIconCatalog.allWithFallback)
        _VectorAssetSpec(
          path: token.compiledAssetPath,
          loader: token.bytesLoader,
        ),
      _incomeWallet,
      _expenseBag,
      _brandMark,
    ];
    final logBoxGlyphSpecs = <_VectorAssetSpec>[
      for (final token in CategoryIconCatalog.allWithFallback)
        _VectorAssetSpec(
          path: token.logBoxCompiledAssetPath,
          loader: token.logBoxBytesLoader,
        ),
    ];
    assert(normalPictureSpecs.length == assetCount);
    assert(logBoxGlyphSpecs.length == logBoxGlyphAssetCount);
    if (logBoxGlyphSpecs.map((spec) => spec.path).toSet().length !=
        uniqueLogBoxGlyphAssetCount) {
      throw StateError('Prepared LogBox glyph catalog identity changed.');
    }
    final allSpecs = <_VectorAssetSpec>[
      ...normalPictureSpecs,
      ...logBoxGlyphSpecs,
    ];

    final uniqueSpecs = <String, _VectorAssetSpec>{};
    for (final spec in allSpecs) {
      uniqueSpecs.putIfAbsent(spec.path, () => spec);
    }
    if (uniqueSpecs.length != uniqueAssetCount) {
      throw StateError('Prepared vector asset catalog identity changed.');
    }

    final entries = uniqueSpecs.entries.toList(growable: false);
    final decoded = <String, PictureInfo>{};
    var cursor = 0;

    Future<void> worker() async {
      while (cursor < entries.length) {
        final entry = entries[cursor];
        cursor += 1;
        final info = await vg.loadPicture(entry.value.loader, null);
        decoded[entry.key] = info;
        _pictureDecodeCount += 1;
      }
    }

    try {
      final workerCount = entries.length < _maximumConcurrentDecodes
          ? entries.length
          : _maximumConcurrentDecodes;
      await Future.wait<void>(
        List<Future<void>>.generate(workerCount, (_) => worker()),
      );
      if (_disposed) {
        throw StateError('Prepared vector asset atlas was disposed.');
      }
      PictureInfo decodedInfo(_VectorAssetSpec spec) {
        final info = decoded[spec.path];
        if (info == null) {
          throw StateError('Vector picture was not decoded: ${spec.path}');
        }
        return info;
      }

      final pictures = List<PreparedVectorPicture>.generate(
        normalPictureSpecs.length,
        (index) {
          final spec = normalPictureSpecs[index];
          return PreparedVectorPicture._(
            assetPath: spec.path,
            pictureInfo: decodedInfo(spec),
          );
        },
        growable: false,
      );
      final glyphs = List<PreparedLogBoxVectorGlyph>.generate(
        logBoxGlyphSpecs.length,
        (index) {
          final spec = logBoxGlyphSpecs[index];
          final info = decodedInfo(spec);
          if (info.size.isEmpty) {
            throw StateError('The prepared LogBox category glyph is empty.');
          }
          return PreparedLogBoxVectorGlyph._(
            picture: info.picture,
            logicalSize: info.size,
          );
        },
        growable: false,
      );
      final gradients = <LinearGradient>[
        for (final token in CategoryColorCatalog.allWithFallback)
          token.gradient,
      ];
      _categoryGradients = List<LinearGradient>.unmodifiable(gradients);
      _pictures = List<PreparedVectorPicture>.unmodifiable(pictures);
      _logBoxGlyphs = List<PreparedLogBoxVectorGlyph>.unmodifiable(glyphs);
      _logBoxGlyphBuildCount += 1;
      prepareTimer.stop();
      _prepareDurationMicros = prepareTimer.elapsedMicroseconds;
    } on Object {
      prepareTimer.stop();
      for (final info in decoded.values) {
        info.picture.dispose();
      }
      rethrow;
    }
  }

  Future<void> _prepareLogBoxRasters(double devicePixelRatio) async {
    await prepare();
    final timer = Stopwatch()..start();
    _PreparedRasterAtlasImage? badges;
    ui.Image? groupSurface;
    try {
      badges = await _rasterizeBadgeAtlas(<LinearGradient>[
        for (
          var handle = 0;
          handle < CategoryColorCatalog.allWithFallback.length;
          handle += 1
        )
          categoryGradient(handle),
      ], devicePixelRatio: devicePixelRatio);
      groupSurface = await _rasterizeGroupSurface(
        devicePixelRatio: devicePixelRatio,
      );
      final glyphs = _logBoxGlyphs;
      if (glyphs == null) {
        throw StateError('Prepared LogBox vector glyphs are not ready.');
      }
      if (_disposed) {
        throw StateError('Prepared vector asset atlas was disposed.');
      }
      final badgeAtlasImage = badges.image;
      final result = PreparedLogBoxRasterSet._(
        devicePixelRatio: devicePixelRatio,
        logicalBadgeSize: logBoxBadgeLogicalSize,
        logicalIconSize: logBoxIconLogicalSize,
        badgeAtlas: badgeAtlasImage,
        badges: List<PreparedLogBoxRasterSprite>.unmodifiable(
          badges.sourceRects.map(
            (sourceRect) => PreparedLogBoxRasterSprite._(
              image: badgeAtlasImage,
              sourceRect: sourceRect,
            ),
          ),
        ),
        glyphs: glyphs,
        groupSurface: groupSurface,
        groupSurfaceCenterSlice: Rect.fromLTWH(
          (logBoxGroupSurfaceLogicalSize / 2 - 1) * devicePixelRatio,
          (logBoxGroupSurfaceLogicalSize / 2 - 1) * devicePixelRatio,
          2 * devicePixelRatio,
          2 * devicePixelRatio,
        ),
        groupSurfaceOutset: logBoxGroupSurfaceOutset,
        estimatedBytes:
            <ui.Image>[badgeAtlasImage, groupSurface].fold<int>(
              0,
              (total, image) => total + image.width * image.height * 4,
            ) +
            glyphs.fold<int>(
              0,
              (total, glyph) => total + glyph.picture.approximateBytesUsed,
            ),
      );
      final previous = _logBoxRasters;
      _logBoxRasters = result;
      previous?.dispose();
      timer.stop();
      _logBoxRasterBuildCount += 1;
      _logBoxRasterPrepareDurationMicros = timer.elapsedMicroseconds;
    } on Object {
      timer.stop();
      badges?.image.dispose();
      groupSurface?.dispose();
      rethrow;
    }
  }

  static Future<ui.Image> _rasterizeGroupSurface({
    required double devicePixelRatio,
  }) async {
    final pixelSize = (logBoxGroupSurfaceLogicalSize * devicePixelRatio).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio, devicePixelRatio);
    final cardRect = Rect.fromLTWH(
      logBoxGroupSurfaceOutset,
      logBoxGroupSurfaceOutset,
      logBoxGroupSurfaceCardSize,
      logBoxGroupSurfaceCardSize,
    );
    final painter = const BoxDecoration(
      color: FluviVisualTokens.surface,
      borderRadius: FluviVisualTokens.logBoxGroupRadius,
      boxShadow: FluviVisualTokens.cardSurfaceShadows,
    ).createBoxPainter();
    try {
      painter.paint(
        canvas,
        cardRect.topLeft,
        ImageConfiguration(size: cardRect.size),
      );
    } finally {
      painter.dispose();
    }
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(pixelSize, pixelSize);
    } finally {
      picture.dispose();
    }
  }

  static Future<_PreparedRasterAtlasImage> _rasterizeBadgeAtlas(
    List<LinearGradient> gradients, {
    required double devicePixelRatio,
  }) async {
    if (gradients.isEmpty) {
      throw StateError('The LogBox badge atlas cannot be empty.');
    }
    final cellPixels = (logBoxBadgeLogicalSize * devicePixelRatio).ceil();
    final columns = math.min(_logBoxRasterAtlasColumns, gradients.length);
    final rows = (gradients.length / columns).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio, devicePixelRatio);
    final logicalStride = cellPixels / devicePixelRatio;
    final inset = (logicalStride - logBoxBadgeLogicalSize) / 2;
    final sourceRects = <Rect>[];
    for (var index = 0; index < gradients.length; index += 1) {
      final column = index % columns;
      final row = index ~/ columns;
      final rect = Rect.fromLTWH(
        column * logicalStride + inset,
        row * logicalStride + inset,
        logBoxBadgeLogicalSize,
        logBoxBadgeLogicalSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(logBoxBadgeLogicalSize * .28),
        ),
        Paint()..shader = gradients[index].createShader(rect),
      );
      sourceRects.add(
        Rect.fromLTWH(
          (column * cellPixels).toDouble(),
          (row * cellPixels).toDouble(),
          cellPixels.toDouble(),
          cellPixels.toDouble(),
        ),
      );
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
        columns * cellPixels,
        rows * cellPixels,
      );
      return _PreparedRasterAtlasImage(
        image: image,
        sourceRects: List<Rect>.unmodifiable(sourceRects),
      );
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    if (_disposed) return;
    if (_inFlight != null || _logBoxRasterInFlight != null) {
      throw StateError('Cannot dispose an atlas while it is preparing.');
    }
    _disposed = true;
    final disposedPictures = <ui.Picture>{};
    for (final prepared in _pictures ?? const <PreparedVectorPicture>[]) {
      if (disposedPictures.add(prepared.pictureInfo.picture)) {
        prepared.pictureInfo.picture.dispose();
      }
    }
    _pictures = null;
    _categoryGradients = null;
    _logBoxRasters?.dispose();
    _logBoxRasters = null;
    for (final glyph in _logBoxGlyphs ?? const <PreparedLogBoxVectorGlyph>[]) {
      if (disposedPictures.add(glyph.picture)) glyph.dispose();
    }
    _logBoxGlyphs = null;
    _prepareDurationMicros = 0;
    _logBoxRasterPrepareDurationMicros = 0;
  }
}

/// Synchronous painter for one bootstrap-prepared vector picture.
final class PreparedVectorPictureView extends StatelessWidget {
  const PreparedVectorPictureView({
    required this.picture,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  final PreparedVectorPicture picture;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final view = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PreparedVectorPicturePainter(
          picture: picture,
          fit: fit,
          alignment: alignment,
          color: color,
        ),
      ),
    );
    final label = semanticsLabel;
    return label == null
        ? view
        : Semantics(label: label, image: true, child: view);
  }
}

final class _PreparedVectorPicturePainter extends CustomPainter {
  const _PreparedVectorPicturePainter({
    required this.picture,
    required this.fit,
    required this.alignment,
    required this.color,
  });

  final PreparedVectorPicture picture;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final sourceSize = picture.pictureInfo.size;
    if (sourceSize.isEmpty || size.isEmpty) return;
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
    final tint = color;
    if (tint != null) {
      canvas.saveLayer(
        Offset.zero & sourceSize,
        Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.srcIn),
      );
    }
    canvas.drawPicture(picture.pictureInfo.picture);
    if (tint != null) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreparedVectorPicturePainter oldDelegate) =>
      !identical(oldDelegate.picture, picture) ||
      oldDelegate.fit != fit ||
      oldDelegate.alignment != alignment ||
      oldDelegate.color != color;
}
