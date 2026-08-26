import 'dart:async';
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

/// A self-contained vector display list for the LogBox avatar hot path.
///
/// The engine rasterizes this picture at the actual row transform. The atlas
/// owns and disposes the display list; the bounded LogBox resource handle only
/// borrows it.
@immutable
abstract class PreparedLogBoxVectorResource {
  const PreparedLogBoxVectorResource({
    required this.picture,
    required this.logicalSize,
  });

  final ui.Picture picture;
  final Size logicalSize;

  void dispose() => picture.dispose();
}

/// A self-contained white category glyph for the LogBox hot path.
@immutable
final class PreparedLogBoxVectorGlyph extends PreparedLogBoxVectorResource {
  const PreparedLogBoxVectorGlyph._({
    required super.picture,
    required super.logicalSize,
  });
}

/// A precompiled gradient avatar badge for the LogBox hot path.
///
/// The gradient shader is recorded once by [PreparedVectorAssetAtlas], then
/// replayed as vector drawing at the exact device transform for each row.
@immutable
final class PreparedLogBoxVectorBadge extends PreparedLogBoxVectorResource {
  const PreparedLogBoxVectorBadge._({
    required super.picture,
    required super.logicalSize,
  });
}

/// Bounded prepared LogBox vector resources.
///
/// The set cardinality is defined by the category catalogs, never by ledger
/// row count. LogBox painting composes one prepared vector badge and one
/// prepared vector glyph without vector decode, gradient shader creation or a
/// row-time tint saveLayer. Group-card geometry is intentionally drawn at its
/// final Canvas transform by the render surface, not held here as a raster.
@immutable
final class PreparedLogBoxRasterSet {
  const PreparedLogBoxRasterSet._({
    required this.devicePixelRatio,
    required this.logicalBadgeSize,
    required this.logicalIconSize,
    required this.badges,
    required this.glyphs,
    required this.editPlaceholderGlyph,
    required this.estimatedBytes,
  });

  final double devicePixelRatio;
  final double logicalBadgeSize;
  final double logicalIconSize;
  final List<PreparedLogBoxVectorBadge> badges;
  final List<PreparedLogBoxVectorGlyph> glyphs;
  final PreparedLogBoxVectorGlyph editPlaceholderGlyph;
  final int estimatedBytes;

  int get badgeCount => badges.length;
  int get glyphCount => glyphs.length;
  int get rasterSurfaceCount => 0;

  PreparedLogBoxVectorBadge badge(int handle) {
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

  /// Avatar pictures are owned by the atlas, not by this DPR-keyed handle.
  void dispose() {}
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
  static const int budgetIncomeGoalBanknoteHandle = 54;

  /// Normal dashboard icon handles plus the four non-category dashboard
  /// pictures. The fallback deliberately aliases the first catalog icon.
  static const int assetCount = 55;
  static const int logBoxGlyphAssetCount = 51;
  static const int uniqueLogBoxGlyphAssetCount = 50;

  /// All unique normal and dedicated LogBox-white source pictures are decoded
  /// once by this single atlas owner.
  static const int uniqueAssetCount = 105;
  static const double logBoxBadgeLogicalSize = 34;
  static const double logBoxIconLogicalSize = 18;

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
  static const _VectorAssetSpec _budgetIncomeGoalBanknote = _VectorAssetSpec(
    path: 'assets/fluvi/budget/banknote.svg.vec',
    loader: AssetBytesLoader('assets/fluvi/budget/banknote.svg.vec'),
  );
  static const _VectorAssetSpec _logBoxEditPlaceholder = _VectorAssetSpec(
    path: 'assets/icons/lucide/pencil.svg.vec',
    loader: AssetBytesLoader('assets/icons/lucide/pencil.svg.vec'),
  );

  final int _maximumConcurrentDecodes;
  List<PreparedVectorPicture>? _pictures;
  List<LinearGradient>? _categoryGradients;
  Future<void>? _inFlight;
  Future<void>? _logBoxRasterInFlight;
  PreparedLogBoxRasterSet? _logBoxRasters;
  List<PreparedLogBoxVectorBadge>? _logBoxBadges;
  List<PreparedLogBoxVectorGlyph>? _logBoxGlyphs;
  PreparedLogBoxVectorGlyph? _logBoxEditPlaceholderGlyph;
  int _pictureDecodeCount = 0;
  int _prepareDurationMicros = 0;
  int _logBoxRasterBuildCount = 0;
  int _logBoxBadgeBuildCount = 0;
  int _logBoxGlyphBuildCount = 0;
  int _logBoxRasterPrepareDurationMicros = 0;
  bool _disposed = false;

  bool get isReady =>
      _pictures != null &&
      _categoryGradients != null &&
      _logBoxBadges != null &&
      _logBoxGlyphs != null &&
      _logBoxEditPlaceholderGlyph != null;
  int get pictureCount => _pictures?.length ?? 0;
  int get logBoxGlyphCount => _logBoxGlyphs?.length ?? 0;
  int get pictureDecodeCount => _pictureDecodeCount;
  int get prepareDurationMicros => _prepareDurationMicros;
  int get logBoxRasterBuildCount => _logBoxRasterBuildCount;
  int get logBoxBadgeBuildCount => _logBoxBadgeBuildCount;
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
      _budgetIncomeGoalBanknote,
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
      _logBoxEditPlaceholder,
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

    final createdBadges = <PreparedLogBoxVectorBadge>[];
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
      for (final gradient in gradients) {
        createdBadges.add(_recordLogBoxBadge(gradient));
      }
      _categoryGradients = List<LinearGradient>.unmodifiable(gradients);
      _pictures = List<PreparedVectorPicture>.unmodifiable(pictures);
      _logBoxBadges = List<PreparedLogBoxVectorBadge>.unmodifiable(
        createdBadges,
      );
      _logBoxGlyphs = List<PreparedLogBoxVectorGlyph>.unmodifiable(glyphs);
      final editPlaceholderInfo = decodedInfo(_logBoxEditPlaceholder);
      if (editPlaceholderInfo.size.isEmpty) {
        throw StateError('The prepared LogBox edit placeholder is empty.');
      }
      _logBoxEditPlaceholderGlyph = _recordTintedLogBoxGlyph(
        editPlaceholderInfo.picture,
        logicalSize: editPlaceholderInfo.size,
        color: DashboardLogBoxTokens.editPlaceholderGlyphColor,
      );
      editPlaceholderInfo.picture.dispose();
      _logBoxBadgeBuildCount += 1;
      _logBoxGlyphBuildCount += 1;
      prepareTimer.stop();
      _prepareDurationMicros = prepareTimer.elapsedMicroseconds;
    } on Object {
      prepareTimer.stop();
      for (final badge in createdBadges) {
        badge.dispose();
      }
      for (final info in decoded.values) {
        info.picture.dispose();
      }
      rethrow;
    }
  }

  Future<void> _prepareLogBoxRasters(double devicePixelRatio) async {
    await prepare();
    final timer = Stopwatch()..start();
    try {
      final badges = _logBoxBadges;
      final glyphs = _logBoxGlyphs;
      final editPlaceholderGlyph = _logBoxEditPlaceholderGlyph;
      if (badges == null || glyphs == null || editPlaceholderGlyph == null) {
        throw StateError('Prepared LogBox vector avatars are not ready.');
      }
      if (_disposed) {
        throw StateError('Prepared vector asset atlas was disposed.');
      }
      final result = PreparedLogBoxRasterSet._(
        devicePixelRatio: devicePixelRatio,
        logicalBadgeSize: logBoxBadgeLogicalSize,
        logicalIconSize: logBoxIconLogicalSize,
        badges: badges,
        glyphs: glyphs,
        editPlaceholderGlyph: editPlaceholderGlyph,
        estimatedBytes:
            badges.fold<int>(
              0,
              (total, badge) => total + badge.picture.approximateBytesUsed,
            ) +
            glyphs.fold<int>(
              0,
              (total, glyph) => total + glyph.picture.approximateBytesUsed,
            ) +
            editPlaceholderGlyph.picture.approximateBytesUsed,
      );
      final previous = _logBoxRasters;
      _logBoxRasters = result;
      previous?.dispose();
      timer.stop();
      _logBoxRasterBuildCount += 1;
      _logBoxRasterPrepareDurationMicros = timer.elapsedMicroseconds;
    } on Object {
      timer.stop();
      rethrow;
    }
  }

  static PreparedLogBoxVectorBadge _recordLogBoxBadge(LinearGradient gradient) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Offset.zero & Size.square(logBoxBadgeLogicalSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(logBoxBadgeLogicalSize * .28),
      ),
      Paint()..shader = gradient.createShader(rect),
    );
    return PreparedLogBoxVectorBadge._(
      picture: recorder.endRecording(),
      logicalSize: rect.size,
    );
  }

  static PreparedLogBoxVectorGlyph _recordTintedLogBoxGlyph(
    ui.Picture source, {
    required Size logicalSize,
    required Color color,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Offset.zero & logicalSize;
    canvas.saveLayer(
      rect,
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    canvas.drawPicture(source);
    canvas.restore();
    return PreparedLogBoxVectorGlyph._(
      picture: recorder.endRecording(),
      logicalSize: logicalSize,
    );
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
    for (final badge in _logBoxBadges ?? const <PreparedLogBoxVectorBadge>[]) {
      if (disposedPictures.add(badge.picture)) badge.dispose();
    }
    _logBoxBadges = null;
    for (final glyph in _logBoxGlyphs ?? const <PreparedLogBoxVectorGlyph>[]) {
      if (disposedPictures.add(glyph.picture)) glyph.dispose();
    }
    _logBoxGlyphs = null;
    final editPlaceholderGlyph = _logBoxEditPlaceholderGlyph;
    if (editPlaceholderGlyph != null &&
        disposedPictures.add(editPlaceholderGlyph.picture)) {
      editPlaceholderGlyph.dispose();
    }
    _logBoxEditPlaceholderGlyph = null;
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
