import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_budget_rhythm_controller.dart';
import 'budget_category_distribution_card.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_partner_distribution_card.dart';
import 'budget_distribution_page_surface.dart';
import 'budget_target_avatar_rail_controller.dart';

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
  });

  final BudgetDistributionPageController controller;
  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;
  final BudgetTargetAvatarRailController avatarRailController;
  final bool expandCategoryDonutToFit;
  final ValueListenable<DashboardBudgetRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;

  @override
  State<BudgetDistributionPager> createState() =>
      _BudgetDistributionPagerState();
}

class _BudgetDistributionPagerState extends State<BudgetDistributionPager> {
  ScrollPosition? _position;

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
  }

  void _detachPosition() {
    _position?.isScrollingNotifier.removeListener(_onScrollActivityChanged);
    _position = null;
  }

  void _onScrollActivityChanged() {
    if (_position?.isScrollingNotifier.value ?? true) return;
    widget.controller.rebaseAtIdleIfNeeded();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    key: const ValueKey('budget-distribution-pager'),
    controller: widget.controller.pageController,
    // Card2's page item owns a FluviRoundedBox whose authored elevation and
    // foot shadows intentionally paint outside its exact child bounds. The
    // moving card therefore needs an overflow-transparent pager viewport; the
    // cascade parent already supplies the non-clipping dashboard composition.
    clipBehavior: Clip.none,
    onPageChanged: widget.controller.bindVirtualIndex,
    itemBuilder: (context, virtualIndex) {
      final page = BudgetDistributionPageController._pageFor(virtualIndex);
      return RepaintBoundary(
        child: KeyedSubtree(
          key: ValueKey('budget-distribution-page-$virtualIndex'),
          child: switch (page) {
            BudgetDistributionPage.category => BudgetDistributionPageCard(
              cardKey: const ValueKey('budget-category-distribution-card'),
              child: BudgetCategoryDistributionCard(
                presentation: widget.presentation,
                drawableFrames: widget.drawableFrames,
                avatarRailController: widget.avatarRailController,
                expandDonutToFit: widget.expandCategoryDonutToFit,
              ),
            ),
            BudgetDistributionPage.partner => BudgetDistributionPageCard(
              cardKey: const ValueKey('budget-partner-distribution-card'),
              child: BudgetPartnerDistributionCard(
                presentation: widget.presentation,
                drawableFrames: widget.drawableFrames,
                expandDonutToFit: widget.expandCategoryDonutToFit,
                rhythm: widget.rhythm,
                drilldown: widget.drilldown,
              ),
            ),
          },
        ),
      );
    },
  );
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
