import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../application/dashboard_log_area_state.dart';
import 'dashboard_day_log_group.dart';

/// The dashboard's only vertical transaction scroll host.
///
/// It receives a narrow presentation state/API: no DAO, platform channel,
/// query controller, Room entity or raw cursor is reachable from this layer.
class DashboardLogArea extends StatelessWidget {
  const DashboardLogArea({
    required this.state,
    required this.onLoadNextPage,
    required this.onRetry,
    required this.onEntryTap,
    super.key,
  });

  final DashboardLogAreaState state;
  final VoidCallback onLoadNextPage;
  final VoidCallback onRetry;
  final ValueChanged<String> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-area-repaint-boundary'),
      child: switch (state) {
        DashboardLogInitialLoading() => _LogScrollHost(
          onLoadNextPage: onLoadNextPage,
          slivers: const [
            _LogHeader(count: '—'),
            _LogLoadingSliver(),
          ],
        ),
        DashboardLogData(
          :final snapshot,
          :final viewGroups,
          :final hasNextPage,
          :final isLoadingNextPage,
        ) =>
          _LogScrollHost(
            onLoadNextPage: hasNextPage ? onLoadNextPage : null,
            slivers: [
              _LogHeader(count: '${snapshot.summaryMetrics.entryCount ?? 0}'),
              for (var index = 0; index < viewGroups.length; index += 1)
                DashboardDayLogGroupSliver(
                  model: viewGroups[index],
                  onEntryTap: onEntryTap,
                  showGroupGap: index < viewGroups.length - 1,
                ),
              if (isLoadingNextPage) const _LogNextPageLoadingSliver(),
            ],
          ),
        DashboardLogEmpty(:final snapshot) => _LogScrollHost(
          onLoadNextPage: null,
          slivers: [
            _LogHeader(count: '${snapshot.summaryMetrics.entryCount ?? 0}'),
            const _LogEmptySliver(),
          ],
        ),
        DashboardLogError(:final previousData) => _LogScrollHost(
          onLoadNextPage: previousData?.hasNextPage == true
              ? onLoadNextPage
              : null,
          slivers: [
            _LogHeader(
              count:
                  '${previousData?.snapshot.summaryMetrics.entryCount ?? '—'}',
            ),
            _LogErrorSliver(onRetry: onRetry),
          ],
        ),
      },
    );
  }
}

class _LogScrollHost extends StatelessWidget {
  const _LogScrollHost({required this.slivers, required this.onLoadNextPage});

  final List<Widget> slivers;
  final VoidCallback? onLoadNextPage;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 360) onLoadNextPage?.call();
        return false;
      },
      child: CustomScrollView(
        key: const ValueKey('dashboard-logbox-scroll-view'),
        cacheExtent: DashboardLogBoxTokens.cacheExtent,
        slivers: slivers,
      ),
    );
  }
}

class _LogHeader extends StatelessWidget {
  const _LogHeader({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(
      height: DashboardLogBoxTokens.summaryHeaderHeight,
      child: Center(
        child: Text(
          '$count tranzakció listázva',
          key: const ValueKey('dashboard-logbox-entry-count'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FluviVisualTokens.logBoxHeaderTextStyle,
        ),
      ),
    ),
  );
}

class _LogLoadingSliver extends StatelessWidget {
  const _LogLoadingSliver();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(
      horizontal: DashboardLogBoxTokens.horizontalGutter,
    ),
    sliver: SliverList.builder(
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: DashboardLogBoxTokens.dayGroupGap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surfaceMuted,
            borderRadius: FluviVisualTokens.logBoxGroupRadius,
          ),
          child: SizedBox(height: DashboardLogBoxTokens.rowHeight * 2),
        ),
      ),
    ),
  );
}

class _LogNextPageLoadingSliver extends StatelessWidget {
  const _LogNextPageLoadingSliver();

  @override
  Widget build(BuildContext context) => const SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ),
  );
}

class _LogEmptySliver extends StatelessWidget {
  const _LogEmptySliver();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Text(
        'Nincs tranzakció ebben az időszakban.',
        key: ValueKey('dashboard-logbox-empty'),
        textAlign: TextAlign.center,
        style: FluviVisualTokens.logBoxHeaderTextStyle,
      ),
    ),
  );
}

class _LogErrorSliver extends StatelessWidget {
  const _LogErrorSliver({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: TextButton(
        key: const ValueKey('dashboard-logbox-retry'),
        onPressed: onRetry,
        child: const Text('A tranzakciók betöltése sikertelen. Újrapróbálás'),
      ),
    ),
  );
}
