import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_spending_rhythm_controller.dart';
import 'budget_category_distribution_card.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_partner_distribution_card.dart';
import 'budget_distribution_page_surface.dart';
import 'budget_target_avatar_rail_controller.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';

enum BudgetDistributionPage { category, partner }

/// Local Card2 page owner. It owns one stable Flutter [PageController] and a
/// parity-only semantic page; it deliberately knows nothing about dashboard
/// mode, time, Query, LogBox or avatar selection.
final class BudgetDistributionPageController
    extends ValueNotifier<BudgetDistributionPage> {
  BudgetDistributionPageController({int initialVirtualIndex = 1000000})
    : assert(initialVirtualIndex >= 0),
      _virtualIndex = initialVirtualIndex,
      pageController = PageController(initialPage: initialVirtualIndex),
      super(_pageFor(initialVirtualIndex));

  final PageController pageController;
  int _virtualIndex;

  static const _lowerRebaseWatermark = 1024;
  static const _rebaseAnchor = 1000000;

  int get virtualIndex => _virtualIndex;

  static BudgetDistributionPage _pageFor(int index) => index.isEven
      ? BudgetDistributionPage.category
      : BudgetDistributionPage.partner;

  void bindVirtualIndex(int virtualIndex) {
    if (virtualIndex == _virtualIndex) return;
    final from = value;
    _virtualIndex = virtualIndex;
    final next = _pageFor(virtualIndex);
    if (next != value) value = next;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_PAGE_CHANGED',
        scope:
            'from=${from.name} to=${next.name} '
            'virtualIndex=$virtualIndex semanticIndex=${virtualIndex % 2}',
      ),
    );
  }

  /// PageView has a natural zero lower bound. Rebase only after its Scrollable
  /// reports idle, preserving parity while keeping lazy children and the one
  /// PageController/ScrollPosition alive indefinitely in both directions.
  bool rebaseAtIdleIfNeeded() {
    if (_virtualIndex >= _lowerRebaseWatermark ||
        !pageController.hasClients ||
        pageController.position.isScrollingNotifier.value) {
      return false;
    }
    final target = _rebaseAnchor + _virtualIndex.remainder(2);
    _virtualIndex = target;
    pageController.jumpToPage(target);
    return true;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

/// Lazily built infinite two-page Card2 domain. Flutter owns normal page drag
/// and ballistics; no raw-pointer pager or extra ScrollController is created.
class BudgetDistributionPager extends StatefulWidget {
  const BudgetDistributionPager({
    super.key,
    required this.controller,
    required this.presentation,
    required this.drawableFrames,
    required this.avatarRailController,
    this.expandCategoryDonutToFit = false,
    this.rhythm,
    this.drilldown,
    this.upperVerticalGestures,
    this.surfaceOwner = BudgetDistributionSurfaceOwner.splitCard2,
  });

  final BudgetDistributionPageController controller;
  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;
  final BudgetTargetAvatarRailController avatarRailController;
  final bool expandCategoryDonutToFit;
  final ValueListenable<DashboardSpendingRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;
  final BudgetDistributionSurfaceOwner surfaceOwner;

  @override
  State<BudgetDistributionPager> createState() =>
      _BudgetDistributionPagerState();
}

class _BudgetDistributionPagerState extends State<BudgetDistributionPager> {
  ScrollPosition? _position;
  final GlobalKey _shellKey = GlobalKey(
    debugLabel: 'budget-distribution-shell',
  );
  int? _lastPagerMilestone;
  bool? _lastScrolling;
  bool _viewportSnapshotScheduled = false;
  String _lastViewportBounds = 'unlaidOut';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachPosition());
  }

  @override
  void didUpdateWidget(covariant BudgetDistributionPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _detachPosition();
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachPosition());
    }
  }

  @override
  void dispose() {
    _detachPosition();
    super.dispose();
  }

  void _attachPosition() {
    if (!mounted || !widget.controller.pageController.hasClients) return;
    final position = widget.controller.pageController.position;
    if (identical(_position, position)) return;
    _detachPosition();
    _position = position;
    position.isScrollingNotifier.addListener(_onScrollActivityChanged);
    position.addListener(_onPagerPositionChanged);
  }

  void _detachPosition() {
    _position?.isScrollingNotifier.removeListener(_onScrollActivityChanged);
    _position?.removeListener(_onPagerPositionChanged);
    _position = null;
  }

  void _onScrollActivityChanged() {
    final scrolling = _position?.isScrollingNotifier.value ?? false;
    if (_lastScrolling != scrolling) {
      _lastScrolling = scrolling;
      _recordPagerMilestone(
        stage: scrolling
            ? 'HOME|PAGER_GESTURE_OR_BALLISTIC'
            : 'HOME|PAGER_SETTLED',
      );
    }
    if (!scrolling) widget.controller.rebaseAtIdleIfNeeded();
  }

  void _onPagerPositionChanged() {
    final controller = widget.controller.pageController;
    if (!controller.hasClients) return;
    final page = controller.page;
    if (page == null) return;
    // Four semantically meaningful checkpoints per physical page are enough
    // to reconstruct a partial slide without emitting raw-pixel traffic.
    final milestone = (page * 4).round();
    if (_lastPagerMilestone == milestone) return;
    _lastPagerMilestone = milestone;
    _recordPagerMilestone(stage: 'HOME|PAGER_MILESTONE', page: page);
  }

  void _recordPagerMilestone({required String stage, double? page}) {
    final controller = widget.controller.pageController;
    final resolvedPage =
        page ?? (controller.hasClients ? controller.page : null);
    final lowerIndex = resolvedPage?.floor();
    final fraction = resolvedPage == null
        ? null
        : resolvedPage - resolvedPage.floor();
    // A ScrollPosition can notify while the transformed PageView is being
    // laid out. Reading localToGlobal/size from that listener violates the
    // RenderBox layout contract and can turn a diagnostic event into a
    // rendering failure. Milestones carry the last frame-safe viewport; the
    // current bounds are refreshed once after this frame below.
    final bounds = _lastViewportBounds;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        scope:
            'surfaceOwner=${widget.surfaceOwner.name} '
            'page=${resolvedPage?.toStringAsFixed(3) ?? '-'} '
            'currentVirtualIndex=${lowerIndex ?? '-'} '
            'currentSemanticPage=${lowerIndex == null ? '-' : BudgetDistributionPageController._pageFor(lowerIndex).name} '
            'nextSemanticPage=${lowerIndex == null ? '-' : BudgetDistributionPageController._pageFor(lowerIndex + 1).name} '
            'offsetFraction=${fraction?.toStringAsFixed(3) ?? '-'} '
            'scrolling=${_position?.isScrollingNotifier.value ?? false} '
            'pageControllerIdentity=${identityHashCode(controller)} '
            'scrollPositionIdentity=${_position == null ? '-' : identityHashCode(_position)} '
            'viewport=$bounds',
      ),
    );
    if (stage == 'HOME|PAGER_MILESTONE') {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'HOME|LAYER_CANDIDATES',
          scope:
              'surfaceOwner=${widget.surfaceOwner.name} '
              'physicalMaterial=${widget.surfaceOwner == BudgetDistributionSurfaceOwner.splitCard2 ? 'BudgetDistributionCardShell' : 'BudgetUnifiedContentCard'} '
              'contentClip=BudgetDistributionCardShell.ClipRRect '
              'pageViewport=PageView.clipNone repaintBoundary=perPage '
              'viewport=$bounds',
        ),
      );
    }
    _scheduleViewportSnapshot();
  }

  void _scheduleViewportSnapshot() {
    if (_viewportSnapshotScheduled) return;
    _viewportSnapshotScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportSnapshotScheduled = false;
      if (!mounted) return;
      final shell = _shellKey.currentContext?.findRenderObject();
      if (shell is! RenderBox || !shell.hasSize) return;
      final origin = shell.localToGlobal(Offset.zero);
      _lastViewportBounds =
          'left=${origin.dx.toStringAsFixed(1)} top=${origin.dy.toStringAsFixed(1)} '
          'width=${shell.size.width.toStringAsFixed(1)} '
          'height=${shell.size.height.toStringAsFixed(1)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      key: const ValueKey('budget-distribution-pager'),
      controller: widget.controller.pageController,
      // BudgetDistributionCardShell owns the one rounded Card2 interior clip.
      // Keep PageView itself overflow-transparent so it does not add a second,
      // rectangular raster boundary with a different edge from the shell.
      clipBehavior: Clip.none,
      onPageChanged: widget.controller.bindVirtualIndex,
      itemBuilder: (context, virtualIndex) {
        final page = BudgetDistributionPageController._pageFor(virtualIndex);
        return RepaintBoundary(
          child: KeyedSubtree(
            key: ValueKey('budget-distribution-page-$virtualIndex'),
            child: switch (page) {
              BudgetDistributionPage.category => BudgetCategoryDistributionCard(
                key: const ValueKey('budget-category-distribution-card'),
                presentation: widget.presentation,
                drawableFrames: widget.drawableFrames,
                avatarRailController: widget.avatarRailController,
                expandDonutToFit: widget.expandCategoryDonutToFit,
                upperVerticalGestures: widget.upperVerticalGestures,
              ),
              BudgetDistributionPage.partner => BudgetPartnerDistributionCard(
                key: const ValueKey('budget-partner-distribution-card'),
                presentation: widget.presentation,
                drawableFrames: widget.drawableFrames,
                expandDonutToFit: widget.expandCategoryDonutToFit,
                rhythm: widget.rhythm,
                drilldown: widget.drilldown,
                upperVerticalGestures: widget.upperVerticalGestures,
              ),
            },
          ),
        );
      },
    );
    // Keep one stable viewport element while only the explicit physical
    // surface owner changes. This retains the attached PageView ScrollPosition
    // through Split ↔ Unified transitions; rounded clipping is independent of
    // whether the surrounding card paints material.
    return BudgetDistributionCardShell(
      key: _shellKey,
      surfaceOwner: widget.surfaceOwner,
      child: pageView,
    );
  }
}

class BudgetDistributionPageDots extends StatelessWidget {
  const BudgetDistributionPageDots({super.key, required this.controller});

  final ValueListenable<BudgetDistributionPage> controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetDistributionPage>(
        valueListenable: controller,
        builder: (context, page, child) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _BudgetDistributionPageDot(
              key: const ValueKey('budget-distribution-dot-category'),
              active: page == BudgetDistributionPage.category,
            ),
            _BudgetDistributionPageDot(
              key: const ValueKey('budget-distribution-dot-partner'),
              active: page == BudgetDistributionPage.partner,
            ),
          ],
        ),
      );
}

class _BudgetDistributionPageDot extends StatelessWidget {
  const _BudgetDistributionPageDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: FluviVisualTokens.dotSize,
    height: FluviVisualTokens.dotSize,
    margin: const EdgeInsets.symmetric(
      horizontal: FluviVisualTokens.dotHorizontalInset,
    ),
    decoration: BoxDecoration(
      gradient: active ? FluviVisualTokens.appHighlightGradient : null,
      color: active ? null : FluviVisualTokens.placeholderDotInactive,
      shape: BoxShape.circle,
    ),
  );
}
