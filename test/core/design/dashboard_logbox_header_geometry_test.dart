import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_logbox_search_pill_visibility.dart';

void main() {
  test(
    'the current handle-to-count gap is halved again into the ledger lane',
    () {
      expect(
        DashboardLogBoxTokens.ledgerHeaderTopInset,
        2.75,
        reason:
            'CURRENT HEAD had a 5.5px authored handle-to-count gap; this '
            'follow-up returns its exact 2.75px half to the viewport.',
      );
      expect(DashboardLayoutMetrics.referenceLogBoxHeaderHeight, 87.75);
    },
  );

  test('hiding SearchPill returns its complete owned footprint once', () {
    const shown = DashboardLogBoxHeaderLayout(
      DashboardLogBoxSearchPillSettings(),
    );
    const hidden = DashboardLogBoxHeaderLayout(
      DashboardLogBoxSearchPillSettings(
        visibility: DashboardLogBoxSearchPillVisibility.hidden,
      ),
    );

    expect(shown.reclaimedViewportHeight, 0);
    expect(
      shown.heightForScale(1) - hidden.heightForScale(1),
      DashboardLogBoxHeaderLayout.searchPillFootprint,
    );
    expect(
      hidden.reclaimedViewportHeight,
      DashboardLogBoxHeaderLayout.searchPillFootprint,
    );
  });
}
