import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../categories/catalog/category_color_catalog.dart';
import '../categories/catalog/category_icon_catalog.dart';

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
  int _pictureDecodeCount = 0;
  int _prepareDurationMicros = 0;
  bool _disposed = false;

  bool get isReady => _pictures != null && _categoryGradients != null;
  int get pictureCount => _pictures?.length ?? 0;
  int get pictureDecodeCount => _pictureDecodeCount;
  int get prepareDurationMicros => _prepareDurationMicros;

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

  void dispose() {
    if (_disposed) return;
    if (_inFlight != null) {
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
    _prepareDurationMicros = 0;
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
