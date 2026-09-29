import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ALT-BOUNDARY: Havi 2 and Éves bind only the existing linked presentation',
    () {
      final adapter = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_alternative_scope_presentation.dart',
      ).readAsStringSync();
      final renderer = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_dashboard_core_surface.dart',
      ).readAsStringSync();

      expect(adapter, contains('DashboardBalanceLinkedPresentation linked'));
      expect(
        adapter,
        contains('BalanceAlternativeScopePresentation.fromLinked'),
      );
      expect(
        adapter,
        isNot(contains('DashboardBalanceLinkedProjection.build')),
      );
      expect(adapter, isNot(contains('DashboardLedgerEntry')));
      expect(
        renderer,
        contains('BalanceAlternativeScopePresentation.fromLinked'),
      );
      expect(renderer, isNot(contains('Repository')));
    },
  );

  test('MOM-01/REG-01: seamless Mother Card bounds have one shared owner', () {
    String source(String file) => File(
      'lib/features/dashboard/presentation/core_modes/$file',
    ).readAsStringSync();

    final primitives = source('dashboard_core_mode_surface_primitives.dart');
    final mind = source('mind_dashboard_core_surface.dart');
    final balance = source('balance_dashboard_core_surface.dart');
    final budget = source('budget_dashboard_core_surface.dart');

    expect(primitives, contains('DashboardHeaderContentMotherCardBounds'));
    expect(mind, contains('DashboardHeaderContentMotherCardBounds.resolve'));
    expect(balance, contains('DashboardHeaderContentMotherCardBounds.resolve'));
    expect(budget, contains('DashboardHeaderContentMotherCardBounds.resolve'));
    expect(
      balance,
      isNot(
        contains(
          'height: geometry.modeContentBounds.bottom - geometry.headerBounds.top',
        ),
      ),
    );
    expect(
      budget,
      isNot(
        contains(
          'height: geometry.modeContentBounds.bottom - geometry.headerBounds.top',
        ),
      ),
    );
  });

  test(
    'CCH-01/03/05/07: one geometry policy fixes Mother Card height and Budget has no dots',
    () {
      final coreDashboard = File(
        'lib/features/dashboard/presentation/core_dashboard.dart',
      ).readAsStringSync();
      final policy = File(
        'lib/core/design/dashboard_content_card_height_policy.dart',
      ).readAsStringSync();
      final frame = File(
        'lib/core/design/dashboard_layout_frame.dart',
      ).readAsStringSync();
      final primitives = File(
        'lib/features/dashboard/presentation/core_modes/'
        'dashboard_core_mode_surface_primitives.dart',
      ).readAsStringSync();
      final visualTokens = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_alternative_visual_tokens.dart',
      ).readAsStringSync();
      final budget = File(
        'lib/features/dashboard/presentation/core_modes/'
        'budget_dashboard_core_surface.dart',
      ).readAsStringSync();

      expect(policy, contains('DashboardContentCardHeightPolicy'));
      expect(frame, contains('canonicalMotherCardContentHeight'));
      expect(primitives, contains('canonicalMotherCardContentHeight'));
      expect(
        coreDashboard,
        isNot(
          contains(
            '_balanceAlternativeExtendedSheetPrincipalContentExtraHeightFor',
          ),
        ),
      );
      expect(
        visualTokens,
        isNot(contains('extendedSheetPrincipalModeContentExtraHeight')),
      );
      expect(budget, isNot(contains('dashboard-core-mode-budget-dots')));
      expect(budget, isNot(contains('BudgetDistributionPageDots')));
    },
  );

  test(
    'RBL-02/06: Balance extended sheet owns the HTML child grammar without a local height policy',
    () {
      final layout = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_extended_sheet_layout.dart',
      ).readAsStringSync();
      final visualTokens = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_alternative_visual_tokens.dart',
      ).readAsStringSync();

      expect(layout, contains('final halfRightHeight = topHeight / 2;'));
      expect(
        layout,
        contains(
          'bodyRect.left + card3Width,\n'
          '        bodyRect.top + halfRightHeight,\n'
          '        rightWidth,\n'
          '        halfRightHeight',
        ),
      );
      expect(
        layout,
        contains(
          'bodyRect.left,\n'
          '        bodyRect.top + topHeight,\n'
          '        bodyRect.width,\n'
          '        bottomHeight',
        ),
      );
      expect(
        layout,
        isNot(contains('final bottomWidth = bodyRect.width * .50;')),
      );
      expect(
        visualTokens,
        isNot(contains('extendedSheetPrincipalModeContentExtraHeight')),
      );
    },
  );
}
