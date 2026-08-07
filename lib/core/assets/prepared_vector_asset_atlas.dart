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

/// Bounded, device-scale raster resources used by the LogBox hot paint path.
///
/// The set cardinality is defined by the category catalogs, never by ledger
/// row count. LogBox painting composes one prepared badge background and one
/// prepared white icon without vector decode, gradient shader creation or a
/// tint saveLayer.
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
    required this.iconAtlas,
    required this.icons,
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
  final ui.Image iconAtlas;
  final List<PreparedLogBoxRasterSprite> icons;
  final ui.Image groupSurface;
  final Rect groupSurfaceCenterSlice;
  final double groupSurfaceOutset;
  final int estimatedBytes;

  int get badgeCount => badges.length;
  int get iconCount => icons.length;
  int get rasterSurfaceCount => 3;

  PreparedLogBoxRasterSprite badge(int handle) {
    if (handle < 0 || handle >= badges.length) {
      throw RangeError.range(handle, 0, badges.length - 1, 'handle');
    }
    return badges[handle];
  }

  PreparedLogBoxRasterSprite icon(int handle) {
    if (handle < 0 || handle >= icons.length) {
      throw RangeError.range(handle, 0, icons.length - 1, 'handle');
    }
    return icons[handle];
  }

  bool matches(double ratio) => (devicePixelRatio - ratio).abs() < .001;

  void dispose() {
    badgeAtlas.dispose();
    iconAtlas.dispose();
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
  static const int assetCount = 54;
  static const int uniqueAssetCount = 53;
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
  int _pictureDecodeCount = 0;
  int _prepareDurationMicros = 0;
  int _logBoxRasterBuildCount = 0;
  int _logBoxRasterPrepareDurationMicros = 0;
  bool _disposed = false;

  bool get isReady => _pictures != null && _categoryGradients != null;
  int get pictureCount => _pictures?.length ?? 0;
  int get pictureDecodeCount => _pictureDecodeCount;
  int get prepareDurationMicros => _prepareDurationMicros;
  int get logBoxRasterBuildCount => _logBoxRasterBuildCount;
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
    final iconSpecs = <_VectorAssetSpec>[
      for (final token in CategoryIconCatalog.allWithFallback)
        _VectorAssetSpec(
          path: token.compiledAssetPath,
          loader: token.bytesLoader,
        ),
      _incomeWallet,
      _expenseBag,
      _brandMark,
    ];
    assert(iconSpecs.length == assetCount);

    final uniqueSpecs = <String, _VectorAssetSpec>{};
    for (final spec in iconSpecs) {
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
      final pictures = List<PreparedVectorPicture>.generate(iconSpecs.length, (
        index,
      ) {
        final spec = iconSpecs[index];
        final info = decoded[spec.path];
        if (info == null) {
          throw StateError('Vector picture was not decoded: ${spec.path}');
        }
        return PreparedVectorPicture._(assetPath: spec.path, pictureInfo: info);
      }, growable: false);
      final gradients = <LinearGradient>[
        for (final token in CategoryColorCatalog.allWithFallback)
          token.gradient,
      ];
      _categoryGradients = List<LinearGradient>.unmodifiable(gradients);
      _pictures = List<PreparedVectorPicture>.unmodifiable(pictures);
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
    _PreparedRasterAtlasImage? icons;
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
      icons = await _rasterizeWhiteIconAtlas(<PreparedVectorPicture>[
        for (
          var handle = 0;
          handle < CategoryIconCatalog.allWithFallback.length;
          handle += 1
        )
          categoryIcon(handle),
      ], devicePixelRatio: devicePixelRatio);
      if (_disposed) {
        throw StateError('Prepared vector asset atlas was disposed.');
      }
      final badgeAtlasImage = badges.image;
      final iconAtlasImage = icons.image;
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
        iconAtlas: iconAtlasImage,
        icons: List<PreparedLogBoxRasterSprite>.unmodifiable(
          icons.sourceRects.map(
            (sourceRect) => PreparedLogBoxRasterSprite._(
              image: iconAtlasImage,
              sourceRect: sourceRect,
            ),
          ),
        ),
        groupSurface: groupSurface,
        groupSurfaceCenterSlice: Rect.fromLTWH(
          (logBoxGroupSurfaceLogicalSize / 2 - 1) * devicePixelRatio,
          (logBoxGroupSurfaceLogicalSize / 2 - 1) * devicePixelRatio,
          2 * devicePixelRatio,
          2 * devicePixelRatio,
        ),
        groupSurfaceOutset: logBoxGroupSurfaceOutset,
        estimatedBytes:
            <ui.Image>[badgeAtlasImage, iconAtlasImage, groupSurface].fold<int>(
              0,
              (total, image) => total + image.width * image.height * 4,
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
      icons?.image.dispose();
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

  static Future<_PreparedRasterAtlasImage> _rasterizeWhiteIconAtlas(
    List<PreparedVectorPicture> preparedIcons, {
    required double devicePixelRatio,
  }) async {
    if (preparedIcons.isEmpty) {
      throw StateError('The LogBox icon atlas cannot be empty.');
    }
    final cellPixels = (logBoxIconLogicalSize * devicePixelRatio).ceil();
    final columns = math.min(_logBoxRasterAtlasColumns, preparedIcons.length);
    final rows = (preparedIcons.length / columns).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio, devicePixelRatio);
    final logicalStride = cellPixels / devicePixelRatio;
    final inset = (logicalStride - logBoxIconLogicalSize) / 2;
    final sourceRects = <Rect>[];
    for (var index = 0; index < preparedIcons.length; index += 1) {
      final prepared = preparedIcons[index];
      final column = index % columns;
      final row = index ~/ columns;
      final cellOrigin = Offset(
        column * logicalStride + inset,
        row * logicalStride + inset,
      );
      final sourceSize = prepared.pictureInfo.size;
      final destinationSize = const Size.square(logBoxIconLogicalSize);
      final fitted = applyBoxFit(BoxFit.contain, sourceSize, destinationSize);
      final destination = Alignment.center.inscribe(
        fitted.destination,
        cellOrigin & destinationSize,
      );
      canvas.save();
      canvas.translate(destination.left, destination.top);
      canvas.scale(
        destination.width / sourceSize.width,
        destination.height / sourceSize.height,
      );
      canvas.saveLayer(
        Offset.zero & sourceSize,
        Paint()
          ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
      canvas.drawPicture(prepared.pictureInfo.picture);
      canvas.restore();
      canvas.restore();
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
