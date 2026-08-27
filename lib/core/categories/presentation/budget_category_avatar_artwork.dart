import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../assets/prepared_vector_asset_atlas.dart';
import '../../design/dashboard_mode_palette.dart';
import '../../financial_limits/domain/financial_limit.dart';
import 'category_icon_view.dart';

/// The sole visual-geometry contract for the Budget category avatar.
///
/// The shell may paint outside the fixed carousel slot, but it must never
/// change the sphere or glyph geometry. These source-space values deliberately
/// match [BudgetCategoryAvatarSvg]'s full artwork viewport.
abstract final class BudgetCategoryAvatarGeometry {
  static const avatarCanvasSize = 72.0;
  static const glyphSize = 30.0;

  static const selectionShellVisualDiameter = 112.0;
  static const selectionSourceViewport = 308.0;
  static const selectionTrackRadius = 96.0 * 1.12;
  static const selectionTrackWidth = 24.0;

  static const avatarVisibleRadius = 142.0 * avatarCanvasSize / 342.0;
  static const selectionTrackInnerRadius =
      (selectionTrackRadius - selectionTrackWidth / 2) *
      selectionShellVisualDiameter /
      selectionSourceViewport;
  static const selectionTrackClearance =
      selectionTrackInnerRadius - avatarVisibleRadius;

  static const selectionFaceColor = Color(0xffffffff);

  /// The source artwork's body centre. Normal artwork keeps its lower floor
  /// in a deliberately biased viewport; the selected core does not contain
  /// that floor and therefore recentres this point without changing scale.
  static const avatarSphereCenterX = 256.0;
  static const avatarSphereCenterY = 240.0;
  static const avatarArtworkViewportWidth = 324.0;
  static const avatarArtworkViewportHeight = 342.0;
  static const normalRailViewportTop = 78.0;
  static const centeredCoreViewportTop =
      avatarSphereCenterY - avatarArtworkViewportHeight / 2;
}

/// One hue/tone authority for every Budget target's projected shadow.
/// Geometry and opacity remain renderer-owned, but the target-derived colour
/// must never drift between the authored SVG floor and selection-shell cast.
abstract final class BudgetCategoryAvatarPalette {
  static Color shadowColor(Color categoryColor) =>
      Color.lerp(categoryColor, const Color(0xff24113f), .18)!;
}

/// Exact live-limit projection from the approved Budget reference. Monetary
/// values remain integer scaled-100 everywhere else; this tiny visual adapter
/// is the sole intentional ratio conversion for the painted arc.
@immutable
final class BudgetLimitProgressProjection {
  const BudgetLimitProgressProjection._({
    required this.rawProgress,
    required this.visualProgress,
  });

  factory BudgetLimitProgressProjection.fromAmounts({
    required int actualScaled100,
    required int? limitScaled100,
  }) {
    final hasPositiveLimit = limitScaled100 != null && limitScaled100 > 0;
    final raw = hasPositiveLimit ? actualScaled100 / limitScaled100 : 0.0;
    // This is the only intentional conversion from exact integer money to a
    // double: the painter consumes the bounded ratio directly. In particular,
    // 0 stays 0 and 99.9% must not be rounded into a full circle.
    final visual = BudgetLimitProgressProjection.boundedVisualProgress(raw);
    return BudgetLimitProgressProjection._(
      rawProgress: raw,
      visualProgress: visual,
    );
  }

  static double boundedVisualProgress(double rawProgress) =>
      !rawProgress.isFinite ? 0 : rawProgress.clamp(0.0, 1.0).toDouble();

  /// Arc coverage and semantic warning tone intentionally use different
  /// inputs: coverage is bounded, while the tone keeps the raw utilisation so
  /// an overspent target remains visibly dangerous rather than returning to
  /// its category accent at 100%.
  Color toneFor(Color targetAccent) => BudgetLimitProgressToneResolver.resolve(
    rawProgress: rawProgress,
    targetAccent: targetAccent,
  );

  final double rawProgress;
  final double visualProgress;
}

/// The one pure visual authority for selected Budget-target progress tones.
abstract final class BudgetLimitProgressToneResolver {
  static Color resolve({
    required double rawProgress,
    required Color targetAccent,
  }) {
    if (!rawProgress.isFinite || rawProgress < .75) return targetAccent;
    if (rawProgress <= .90) return FluviVisualTokens.budgetProgressWarning;
    return FluviVisualTokens.budgetProgressDanger;
  }
}

/// The selected avatar keeps one chrome envelope but DAY presents a derived
/// month-end forecast as a vertical gauge instead of the monthly ring.
enum BudgetLimitProgressChromeGeometry { circular, verticalProjection }

/// One atomic Budget selection value. It carries both the exact semantic
/// target and the visual arc inputs, so an old target's scalar cannot become a
/// new centre target's ring during a carousel handoff.
@immutable
final class BudgetCategoryAvatarSelectedLimitVisualState {
  const BudgetCategoryAvatarSelectedLimitVisualState._({
    required this.targetHandle,
    required this.limitKey,
    required this.displayNumeratorScaled100,
    required this.effectiveLimitScaled100,
    required this.hasPositiveLimit,
    required this.rawProgress,
    required this.visualProgress,
    required this.chromeGeometry,
    required this.breakEvenGaugeRatio,
  });

  factory BudgetCategoryAvatarSelectedLimitVisualState.unavailable({
    required int targetHandle,
  }) => BudgetCategoryAvatarSelectedLimitVisualState._(
    targetHandle: targetHandle,
    limitKey: null,
    displayNumeratorScaled100: null,
    effectiveLimitScaled100: null,
    hasPositiveLimit: false,
    rawProgress: 0,
    visualProgress: 0,
    chromeGeometry: BudgetLimitProgressChromeGeometry.circular,
    breakEvenGaugeRatio: null,
  );

  factory BudgetCategoryAvatarSelectedLimitVisualState.available({
    required int targetHandle,
    required FinancialLimitKey limitKey,
    required int displayNumeratorScaled100,
    required int? effectiveLimitScaled100,
    BudgetLimitProgressChromeGeometry chromeGeometry =
        BudgetLimitProgressChromeGeometry.circular,
  }) {
    final hasPositiveLimit =
        effectiveLimitScaled100 != null && effectiveLimitScaled100 > 0;
    final projection = BudgetLimitProgressProjection.fromAmounts(
      actualScaled100: displayNumeratorScaled100,
      limitScaled100: effectiveLimitScaled100,
    );
    final visualProgress =
        chromeGeometry == BudgetLimitProgressChromeGeometry.verticalProjection
        ? (projection.rawProgress * .75).clamp(0.0, 1.0).toDouble()
        : projection.visualProgress;
    return BudgetCategoryAvatarSelectedLimitVisualState._(
      targetHandle: targetHandle,
      limitKey: limitKey,
      displayNumeratorScaled100: displayNumeratorScaled100,
      effectiveLimitScaled100: effectiveLimitScaled100,
      hasPositiveLimit: hasPositiveLimit,
      rawProgress: projection.rawProgress,
      visualProgress: visualProgress,
      chromeGeometry: chromeGeometry,
      breakEvenGaugeRatio:
          chromeGeometry == BudgetLimitProgressChromeGeometry.verticalProjection
          ? .75
          : null,
    );
  }

  final int targetHandle;
  final FinancialLimitKey? limitKey;
  final int? displayNumeratorScaled100;
  final int? effectiveLimitScaled100;
  final bool hasPositiveLimit;
  final double rawProgress;
  final double visualProgress;
  final BudgetLimitProgressChromeGeometry chromeGeometry;
  final double? breakEvenGaugeRatio;

  bool get paintsProgressChrome => hasPositiveLimit;

  bool sameVisualAs(BudgetCategoryAvatarSelectedLimitVisualState other) =>
      targetHandle == other.targetHandle &&
      limitKey == other.limitKey &&
      displayNumeratorScaled100 == other.displayNumeratorScaled100 &&
      effectiveLimitScaled100 == other.effectiveLimitScaled100 &&
      hasPositiveLimit == other.hasPositiveLimit &&
      rawProgress == other.rawProgress &&
      visualProgress == other.visualProgress &&
      chromeGeometry == other.chromeGeometry &&
      breakEvenGaugeRatio == other.breakEvenGaugeRatio;
}

/// The approved avatar-artwork compositions in the Budget rail.
///
/// The semantic center is nested inside a selection shell that already owns a
/// projected cast shadow. Its core therefore deliberately omits the avatar's
/// own floor/blob. A selected target without a positive limit instead uses a
/// centred viewport with the exact authored floor shadow restored. Side
/// avatars retain the complete normal-rail artwork.
enum BudgetCategoryAvatarVariant { normalRail, centeredCore, centeredShadowed }

/// Optional hue-ramp authority for non-category Budget targets.
///
/// The ramp is deliberately projected into authored sphere light/main/body/
/// depth tones by [BudgetCategoryAvatarSvg]. Passing the brand ramp directly
/// to radial-gradient stops makes an aggregate look flat because a cyan or
/// purple neighbour is not intrinsically a highlight or a depth tone.
/// Ordinary categories retain their canonical category-colour rendering.
@immutable
final class BudgetCategoryAvatarFaceGradient {
  const BudgetCategoryAvatarFaceGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  final Color start;
  final Color middle;
  final Color end;
}

/// The source-authored Budget avatar body from the local visual reference's
/// `BudgetV2FluviSvg.avatarDisc` contract.
///
/// The body, its internal highlight/depth, and the lower coloured floor
/// shadow are one SVG artwork for side avatars. The centred core deliberately
/// omits only its floor/blob because the outer selection shell owns the one
/// selected-state cast shadow. [icon] is already decoded by
/// [PreparedVectorAssetAtlas].
final class BudgetCategoryAvatarArtwork extends StatelessWidget {
  const BudgetCategoryAvatarArtwork({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.svgSource,
    required this.selected,
    this.centeredCoreSvgSource,
    this.centeredShadowedSvgSource,
    this.selectedTargetHandle,
    this.selectedLimitVisualListenable,
    this.selectedLiveSelectionListenable,
    this.selectedLimitVisualForLiveSelection,
    this.onSelectionVisualIdentityMismatch,
    super.key,
  });

  final Color color;
  final PreparedVectorPicture icon;
  final String semanticsLabel;

  /// The side-avatar artwork, built when the immutable category presentation
  /// collection changes, never from a carousel tick. `flutter_svg` caches the
  /// parsed source by this value.
  final String svgSource;

  /// Prepared once alongside [svgSource]. It is selected only while the exact
  /// centre target has a positive limit and the outer chrome owns the sole
  /// selected-state projected shadow.
  final String? centeredCoreSvgSource;

  /// Prepared once alongside [svgSource]. It retains the same authored floor
  /// shadow as the normal rail artwork, but uses the centred source viewport
  /// so a no-limit centre target cannot jump vertically.
  final String? centeredShadowedSvgSource;
  final bool selected;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;

  /// The application-level live selection is authoritative. Keeping this
  /// listenable direct avoids a rail-local copied value during target handoff.
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return _BudgetCategoryAvatarSelectedComposition(
        color: color,
        icon: icon,
        semanticsLabel: semanticsLabel,
        centeredCoreSvgSource: centeredCoreSvgSource ?? svgSource,
        centeredShadowedSvgSource: centeredShadowedSvgSource ?? svgSource,
        selectedTargetHandle: selectedTargetHandle,
        selectedLimitVisualListenable: selectedLimitVisualListenable,
        selectedLiveSelectionListenable: selectedLiveSelectionListenable,
        selectedLimitVisualForLiveSelection:
            selectedLimitVisualForLiveSelection,
        onSelectionVisualIdentityMismatch: onSelectionVisualIdentityMismatch,
      );
    }
    return SizedBox.square(
      dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
      child: _BudgetCategoryAvatarDisc(
        source: svgSource,
        icon: icon,
        semanticLabel: semanticsLabel,
        canvasSize: BudgetCategoryAvatarGeometry.avatarCanvasSize,
        iconSize: BudgetCategoryAvatarGeometry.glyphSize,
      ),
    );
  }
}

/// The selected cell keeps its static avatar body separate from the live
/// chrome painter. The state listens to the existing selection publication
/// only to switch body ownership at a positive-limit boundary; ordinary
/// progress ticks rebuild the narrow chrome lane alone.
final class _BudgetCategoryAvatarSelectedComposition extends StatefulWidget {
  const _BudgetCategoryAvatarSelectedComposition({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.centeredCoreSvgSource,
    required this.centeredShadowedSvgSource,
    required this.selectedTargetHandle,
    required this.selectedLimitVisualListenable,
    required this.selectedLiveSelectionListenable,
    required this.selectedLimitVisualForLiveSelection,
    required this.onSelectionVisualIdentityMismatch,
  });

  final Color color;
  final PreparedVectorPicture icon;
  final String semanticsLabel;
  final String centeredCoreSvgSource;
  final String centeredShadowedSvgSource;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  State<_BudgetCategoryAvatarSelectedComposition> createState() =>
      _BudgetCategoryAvatarSelectedCompositionState();
}

final class _BudgetCategoryAvatarSelectedCompositionState
    extends State<_BudgetCategoryAvatarSelectedComposition> {
  late bool _usesCenteredCore;

  @override
  void initState() {
    super.initState();
    _usesCenteredCore = _usesCenteredCoreFor(_currentVisual());
    _currentVisualListenable?.addListener(_onVisualChanged);
  }

  @override
  void didUpdateWidget(
    covariant _BudgetCategoryAvatarSelectedComposition oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final oldListenable = _visualListenableOf(oldWidget);
    final nextListenable = _currentVisualListenable;
    if (!identical(oldListenable, nextListenable)) {
      oldListenable?.removeListener(_onVisualChanged);
      nextListenable?.addListener(_onVisualChanged);
    }
    _usesCenteredCore = _usesCenteredCoreFor(_currentVisual());
  }

  @override
  void dispose() {
    _currentVisualListenable?.removeListener(_onVisualChanged);
    super.dispose();
  }

  Listenable? get _currentVisualListenable => _visualListenableOf(widget);

  static Listenable? _visualListenableOf(
    _BudgetCategoryAvatarSelectedComposition candidate,
  ) =>
      candidate.selectedLiveSelectionListenable ??
      candidate.selectedLimitVisualListenable;

  BudgetCategoryAvatarSelectedLimitVisualState? _currentVisual() {
    final liveVisual = widget.selectedLimitVisualForLiveSelection;
    final visual = liveVisual == null
        ? widget.selectedLimitVisualListenable?.value
        : liveVisual();
    final targetHandle = widget.selectedTargetHandle;
    if (visual == null ||
        targetHandle == null ||
        visual.targetHandle != targetHandle) {
      return null;
    }
    return visual;
  }

  bool _usesCenteredCoreFor(
    BudgetCategoryAvatarSelectedLimitVisualState? visual,
  ) => visual?.paintsProgressChrome ?? false;

  void _onVisualChanged() {
    final next = _usesCenteredCoreFor(_currentVisual());
    if (next == _usesCenteredCore || !mounted) return;
    setState(() => _usesCenteredCore = next);
  }

  @override
  Widget build(BuildContext context) {
    final source = _usesCenteredCore
        ? widget.centeredCoreSvgSource
        : widget.centeredShadowedSvgSource;
    return SizedBox.square(
      dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          _BudgetCategoryAvatarSelectionChromeLayer(
            color: widget.color,
            selectedTargetHandle: widget.selectedTargetHandle,
            selectedLimitVisualListenable: widget.selectedLimitVisualListenable,
            selectedLiveSelectionListenable:
                widget.selectedLiveSelectionListenable,
            selectedLimitVisualForLiveSelection:
                widget.selectedLimitVisualForLiveSelection,
            onSelectionVisualIdentityMismatch:
                widget.onSelectionVisualIdentityMismatch,
          ),
          _BudgetCategoryAvatarDisc(
            source: source,
            icon: widget.icon,
            semanticLabel: widget.semanticsLabel,
            canvasSize: BudgetCategoryAvatarGeometry.avatarCanvasSize,
            iconSize: BudgetCategoryAvatarGeometry.glyphSize,
          ),
        ],
      ),
    );
  }
}

final class _BudgetCategoryAvatarSelectionChromeLayer extends StatelessWidget {
  const _BudgetCategoryAvatarSelectionChromeLayer({
    required this.color,
    required this.selectedTargetHandle,
    required this.selectedLimitVisualListenable,
    required this.selectedLiveSelectionListenable,
    required this.selectedLimitVisualForLiveSelection,
    required this.onSelectionVisualIdentityMismatch,
  });

  final Color color;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  Widget build(BuildContext context) {
    final targetHandle = selectedTargetHandle;
    if (targetHandle == null) return const SizedBox();
    Widget chromeForVisual(
      BudgetCategoryAvatarSelectedLimitVisualState visual,
    ) {
      if (visual.targetHandle != targetHandle) {
        onSelectionVisualIdentityMismatch?.call();
        return const SizedBox();
      }
      if (!visual.paintsProgressChrome) return const SizedBox();
      return OverflowBox(
        alignment: Alignment.center,
        minWidth: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        maxWidth: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        minHeight: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        maxHeight: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        child: BudgetCategoryAvatarSelectionChrome(
          key: const ValueKey('budget-category-avatar-selection-chrome'),
          categoryColor: color,
          progressColor: BudgetLimitProgressToneResolver.resolve(
            rawProgress: visual.rawProgress,
            targetAccent: color,
          ),
          sourceProgress: visual.visualProgress,
          geometry: visual.chromeGeometry,
          breakEvenGaugeRatio: visual.breakEvenGaugeRatio,
        ),
      );
    }

    final liveListenable = selectedLiveSelectionListenable;
    final visualForLiveSelection = selectedLimitVisualForLiveSelection;
    if (liveListenable != null && visualForLiveSelection != null) {
      return AnimatedBuilder(
        animation: liveListenable,
        builder: (context, child) => chromeForVisual(visualForLiveSelection()),
      );
    }
    final visualListenable = selectedLimitVisualListenable;
    if (visualListenable == null) return const SizedBox();
    return ValueListenableBuilder<BudgetCategoryAvatarSelectedLimitVisualState>(
      valueListenable: visualListenable,
      builder: (context, visual, child) => chromeForVisual(visual),
    );
  }
}

final class _BudgetCategoryAvatarDisc extends StatelessWidget {
  const _BudgetCategoryAvatarDisc({
    required this.source,
    required this.icon,
    required this.semanticLabel,
    required this.canvasSize,
    required this.iconSize,
  });

  final String source;
  final PreparedVectorPicture icon;
  final String semanticLabel;
  final double canvasSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: canvasSize,
    child: Semantics(
      image: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                source,
                fit: BoxFit.contain,
                clipBehavior: Clip.hardEdge,
              ),
            ),
          ),
          CategoryIconView(picture: icon, size: iconSize, color: Colors.white),
        ],
      ),
    ),
  );
}

/// The exact reference selection chrome around the centre core. It is kept
/// separate from the SVG avatar body so no Flutter shadow/gradient can be
/// mistaken for intrinsic category artwork.
final class BudgetCategoryAvatarSelectionChrome extends StatelessWidget {
  const BudgetCategoryAvatarSelectionChrome({
    required this.categoryColor,
    this.progressColor,
    this.sourceProgress = 0,
    this.geometry = BudgetLimitProgressChromeGeometry.circular,
    this.breakEvenGaugeRatio,
    super.key,
  }) : faceColor = BudgetCategoryAvatarGeometry.selectionFaceColor;

  final Color categoryColor;
  final Color? progressColor;
  final double sourceProgress;
  final BudgetLimitProgressChromeGeometry geometry;
  final double? breakEvenGaugeRatio;
  final Color faceColor;

  /// Exposed as a small visual contract so the shell and authored SVG floor
  /// can be regression-tested against the same hue authority.
  Color get castShadowColor =>
      BudgetCategoryAvatarPalette.shadowColor(categoryColor);

  /// The live paint contract, shared with [_SelectionChromePainter]. It keeps
  /// the exact continuous visual ratio testable without quantising it into a
  /// display percentage.
  static double sweepRadiansForVisualProgress(double visualProgress) =>
      math.pi *
      2 *
      BudgetLimitProgressProjection.boundedVisualProgress(visualProgress);

  @override
  Widget build(BuildContext context) {
    final gradient = _SelectionArcGradient.fromCategoryColor(
      progressColor ?? categoryColor,
    );
    final shadowColor = castShadowColor;
    return SizedBox.square(
      key: const ValueKey('budget-category-avatar-selection-shell'),
      dimension: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size.square(
            BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
          ),
          painter: _SelectionChromePainter(
            startColor: gradient.start,
            middleColor: gradient.middle,
            endColor: gradient.end,
            faceColor: faceColor,
            shadowColor: shadowColor,
            sourceProgress: sourceProgress,
            geometry: geometry,
            breakEvenGaugeRatio: breakEvenGaugeRatio,
          ),
        ),
      ),
    );
  }
}

final class _SelectionArcGradient {
  const _SelectionArcGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  factory _SelectionArcGradient.fromCategoryColor(Color start) {
    final hsl = HSLColor.fromColor(start);
    final end = hsl
        .withHue((hsl.hue - 46 + 360) % 360)
        .withSaturation((hsl.saturation * .9).clamp(0, 1).toDouble())
        .withLightness((hsl.lightness * .92).clamp(0, 1).toDouble())
        .toColor();
    return _SelectionArcGradient(
      start: start,
      middle: Color.lerp(start, end, .45)!,
      end: end,
    );
  }

  final Color start;
  final Color middle;
  final Color end;
}

/// Ported exactly from the reference's `BudgetV2LimitProgressPainter` for the
/// no-data centre state. It is selection chrome only; the category body's
/// authored depth and floor blob stay inside [BudgetCategoryAvatarSvg].
final class _SelectionChromePainter extends CustomPainter {
  const _SelectionChromePainter({
    required this.startColor,
    required this.middleColor,
    required this.endColor,
    required this.faceColor,
    required this.shadowColor,
    required this.sourceProgress,
    required this.geometry,
    required this.breakEvenGaugeRatio,
  });

  static const _sourceViewport = Size.square(
    BudgetCategoryAvatarGeometry.selectionSourceViewport,
  );
  static const _sourceCenter = Offset(154, 154);
  static const _sourceFaceRadius = 122.0;
  static const _sourceTrackRadius =
      BudgetCategoryAvatarGeometry.selectionTrackRadius;
  static const _sourceTrackWidth =
      BudgetCategoryAvatarGeometry.selectionTrackWidth;
  static const _sourceGlossFraction = .24;

  final Color startColor;
  final Color middleColor;
  final Color endColor;
  final Color faceColor;
  final Color shadowColor;
  final double sourceProgress;
  final BudgetLimitProgressChromeGeometry geometry;
  final double? breakEvenGaugeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _sourceViewport.width,
      size.height / _sourceViewport.height,
    );
    final offset = Offset(
      (size.width - _sourceViewport.width * scale) / 2,
      (size.height - _sourceViewport.height * scale) / 2,
    );
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);

    final trackRect = Rect.fromCircle(
      center: _sourceCenter,
      radius: _sourceTrackRadius,
    );
    const startAngle = -math.pi / 2;
    final sweep =
        BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(
          sourceProgress,
        );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(154, 266), width: 252, height: 68),
      Paint()
        ..color = shadowColor.withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      const Offset(154, 166),
      _sourceFaceRadius,
      Paint()
        ..color = shadowColor.withValues(alpha: .20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final faceRect = Rect.fromCircle(
      center: _sourceCenter,
      radius: _sourceFaceRadius,
    );
    canvas.drawCircle(
      _sourceCenter,
      _sourceFaceRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.32, -.44),
          radius: .78,
          colors: <Color>[
            faceColor,
            const Color(0xfffbf9ff),
            const Color(0xffefeaf8),
          ],
          stops: const <double>[0, .48, 1],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      _sourceCenter,
      _sourceFaceRadius,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final shellHighlight = Path()
      ..moveTo(72, 86)
      ..cubicTo(114, 48, 189, 42, 236, 84);
    canvas.drawPath(
      shellHighlight,
      Paint()
        ..color = const Color(0x8CFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    if (geometry == BudgetLimitProgressChromeGeometry.circular) {
      _paintCircularProgress(canvas, trackRect, startAngle, sweep);
    } else {
      _paintVerticalProjection(canvas);
    }
    canvas.restore();
  }

  void _paintCircularProgress(
    Canvas canvas,
    Rect trackRect,
    double startAngle,
    double sweep,
  ) {
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0x73CFC7DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth + 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F4FF),
            Color(0xFFECE8F8),
            Color(0xFFDCD6EC),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _sourceTrackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2 * _sourceGlossFraction,
      false,
      Paint()
        ..color = const Color(0x85FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    if (sweep > 0) {
      canvas.drawArc(
        trackRect.shift(const Offset(0, 5)),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = endColor.withValues(alpha: .30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _sourceTrackWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      canvas.drawArc(
        trackRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[startColor, middleColor, endColor],
            stops: const <double>[0, .45, 1],
          ).createShader(trackRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _sourceTrackWidth
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        trackRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = const Color(0x3DFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintVerticalProjection(Canvas canvas) {
    final gauge = RRect.fromRectAndRadius(
      Rect.fromLTWH(264, 58, 24, 192),
      Radius.circular(12),
    );
    canvas.drawRRect(gauge, Paint()..color = const Color(0x73CFC7DF));
    final fillHeight = gauge.height * sourceProgress;
    if (fillHeight > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          gauge.left,
          gauge.bottom - fillHeight,
          gauge.width,
          fillHeight,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[endColor, middleColor, startColor],
            stops: const <double>[0, .55, 1],
          ).createShader(gauge.outerRect),
      );
    }
    final markerRatio = breakEvenGaugeRatio;
    if (markerRatio != null) {
      final markerY = gauge.bottom - gauge.height * markerRatio;
      canvas.drawLine(
        Offset(gauge.left - 5, markerY),
        Offset(gauge.right + 5, markerY),
        Paint()
          ..color = const Color(0xFF8D849F)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionChromePainter oldDelegate) =>
      oldDelegate.startColor != startColor ||
      oldDelegate.middleColor != middleColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.sourceProgress != sourceProgress ||
      oldDelegate.geometry != geometry ||
      oldDelegate.breakEvenGaugeRatio != breakEvenGaugeRatio;
}

/// Literal source vector contract from the local visual reference.
/// `flutter_svg` does not support SVG filters, so retain the exact reference
/// compatibility transform: filters are removed but the approved authored
/// geometry and face gradient remain in the artwork.
abstract final class BudgetCategoryAvatarSvg {
  static String flutterRenderable(String source) => source
      .replaceAll(RegExp(r'<filter\b[^>]*>.*?</filter>', dotAll: true), '')
      .replaceAll(RegExp(r'\sfilter="url\(#[^)]+\)"'), '');

  static String avatarDisc(
    Color color,
    int identity, {
    BudgetCategoryAvatarVariant variant =
        BudgetCategoryAvatarVariant.normalRail,
    BudgetCategoryAvatarFaceGradient? faceGradient,
  }) {
    final hex = _hex(color).toLowerCase();
    final id = 'budgetAvatarDisc$identity';
    final gradient = faceGradient;
    final light = gradient == null
        ? _mixColor(hex, '#ffffff', .78)
        : _mixColor(_hex(gradient.start), '#ffffff', .78);
    final main = gradient == null
        ? _mixColor(hex, '#ffffff', .18)
        : _mixColor(_hex(gradient.middle), '#ffffff', .18);
    final body = gradient == null ? hex : _hex(gradient.middle);
    final depth = gradient == null
        ? _mixColor(hex, '#24113f', .32)
        : _mixColor(_hex(gradient.end), '#24113f', .32);
    final shadow = _hex(BudgetCategoryAvatarPalette.shadowColor(color));
    final viewport = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail =>
        '94 ${BudgetCategoryAvatarGeometry.normalRailViewportTop.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportWidth.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportHeight.toStringAsFixed(0)}',
      BudgetCategoryAvatarVariant.centeredCore ||
      BudgetCategoryAvatarVariant.centeredShadowed =>
        '94 ${BudgetCategoryAvatarGeometry.centeredCoreViewportTop.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportWidth.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportHeight.toStringAsFixed(0)}',
    };
    final variantName = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail => 'normal-rail',
      BudgetCategoryAvatarVariant.centeredCore => 'centered-core',
      BudgetCategoryAvatarVariant.centeredShadowed => 'centered-shadowed',
    };
    final shadowFilter =
        '<filter id="${id}Shadow" x="-70%" y="-70%" width="240%" height="240%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="18" result="b"/><feOffset in="b" dx="0" dy="22" result="o"/><feFlood flood-color="$shadow" flood-opacity=".28" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>';
    final bodyFilter = ' filter="url(#${id}Shadow)"';
    final floorShadow = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail ||
      BudgetCategoryAvatarVariant.centeredShadowed =>
        '<ellipse cx="256" cy="382" rx="126" ry="34" fill="$shadow" opacity=".10" filter="url(#${id}SoftBlur)"/>',
      BudgetCategoryAvatarVariant.centeredCore => '',
    };
    return '''<svg class="budget-fluvi-avatar-disc" viewBox="$viewport" preserveAspectRatio="xMidYMid meet" aria-hidden="true" focusable="false" data-fluvi-avatar-disc="true" data-budget-avatar-disc-variant="$variantName" data-budget-avatar-disc-color="$hex"><defs><radialGradient id="${id}Face" cx="32%" cy="26%" r="82%"><stop offset="0" stop-color="$light"/><stop offset=".38" stop-color="$main"/><stop offset=".72" stop-color="$body"/><stop offset="1" stop-color="$depth"/></radialGradient><linearGradient id="${id}Rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".92"/><stop offset=".42" stop-color="#ffffff" stop-opacity=".38"/><stop offset="1" stop-color="$depth" stop-opacity=".55"/></linearGradient>$shadowFilter<filter id="${id}SoftBlur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter></defs><g data-fluvi-avatar-disc-body="true"$bodyFilter>$floorShadow<circle cx="256" cy="240" r="142" fill="url(#${id}Face)" stroke="url(#${id}Rim)" stroke-width="8"/></g></svg>''';
  }
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

String _mixColor(String source, String target, double amount) {
  final ratio = amount.clamp(0.0, 1.0);
  final channels = List<int>.generate(3, (index) {
    final start = int.parse(
      source.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    final end = int.parse(
      target.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    return (start + (end - start) * ratio).round();
  });
  return '#${channels.map((channel) => channel.toRadixString(16).padLeft(2, '0')).join()}';
}
