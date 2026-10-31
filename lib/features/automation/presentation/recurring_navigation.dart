import 'package:flutter/material.dart';

import '../../../core/categories/domain/category_repository.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/design/fluvi_global_appearance.dart';
import '../../../core/navigation/creation_slide_up_route.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/application/manual_transaction_editor_preferences.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'ghost_manager_page.dart';
import 'recurring_rule_manager_page.dart';
import 'recurring_transaction_wizard_page.dart';
import 'unified_recurring_pages.dart';

/// One entry point for every recurring surface. Each call receives a concrete
/// [design] snapshot, so changing the dashboard preference later cannot swap
/// an already-open editor or discard its draft.
abstract final class RecurringNavigation {
  static Future<bool?> openCreate(
    BuildContext context, {
    required RecurringUiDesign design,
    required AutomationRepository repository,
    required ManualTransactionRepository manualRepository,
    required List<FluviCategory> categories,
    required LedgerDirection direction,
    CategoryRepository? categoryRepository,
    ManualTransactionEditorPreferencesStore? preferencesStore,
    AutomationPermissionRepository? permissions,
    FluviDirectionColorProfile directionColorProfile =
        FluviDirectionColorProfile.original,
    PushProfileUiDesign pushProfileUiDesign = PushProfileUiDesign.unified,
  }) => Navigator.of(context).push<bool>(
    creationSlideUpRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => design == RecurringUiDesign.legacy
          ? RecurringTransactionWizardPage(
              repository: repository,
              manualRepository: manualRepository,
              categories: categories,
              initialDirection: direction,
            )
          : UnifiedRecurringTransactionEditorPage.create(
              repository: repository,
              manualRepository: manualRepository,
              categories: categories,
              categoryRepository: categoryRepository,
              preferencesStore: preferencesStore,
              permissions: permissions,
              initialDirection: direction,
              directionColorProfile: directionColorProfile,
              pushProfileUiDesign: pushProfileUiDesign,
            ),
    ),
  );

  static Future<void> openManager(
    BuildContext context, {
    required RecurringUiDesign design,
    required AutomationRepository repository,
    required ManualTransactionRepository manualRepository,
    required List<FluviCategory> categories,
    required LedgerDirection direction,
    CategoryRepository? categoryRepository,
    ManualTransactionEditorPreferencesStore? preferencesStore,
    AutomationPermissionRepository? permissions,
    Future<void> Function(String entryId)? onOpenLedgerEntry,
    bool initialRulesTab = true,
    RecurrenceOccurrenceStatus? initialOccurrenceFilter,
    int? initialOccurrenceFromUtcMs,
    int? initialOccurrenceToUtcMs,
    FluviDirectionColorProfile directionColorProfile =
        FluviDirectionColorProfile.original,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == RecurringUiDesign.legacy
          ? (initialRulesTab
                ? RecurringRuleManagerPage(
                    repository: repository,
                    manualRepository: manualRepository,
                    categories: categories,
                    onOpenLedgerEntry: onOpenLedgerEntry,
                  )
                : GhostManagerPage(
                    repository: repository,
                    manualRepository: manualRepository,
                    categories: categories,
                    onOpenLedgerEntry: onOpenLedgerEntry,
                  ))
          : UnifiedRecurringManagerPage(
              repository: repository,
              manualRepository: manualRepository,
              categories: categories,
              direction: direction,
              categoryRepository: categoryRepository,
              preferencesStore: preferencesStore,
              permissions: permissions,
              onOpenLedgerEntry: onOpenLedgerEntry,
              initialRulesTab: initialRulesTab,
              initialOccurrenceFilter: initialOccurrenceFilter,
              initialOccurrenceFromUtcMs: initialOccurrenceFromUtcMs,
              initialOccurrenceToUtcMs: initialOccurrenceToUtcMs,
              directionColorProfile: directionColorProfile,
            ),
    ),
  );

  static Future<void> openOccurrence(
    BuildContext context, {
    required RecurringUiDesign design,
    required AutomationRepository repository,
    required ManualTransactionRepository manualRepository,
    required List<FluviCategory> categories,
    required String occurrenceId,
    Future<void> Function(String entryId)? onOpenLedgerEntry,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == RecurringUiDesign.legacy
          ? GhostManagerPage(
              repository: repository,
              manualRepository: manualRepository,
              categories: categories,
              initialOccurrenceId: occurrenceId,
              onOpenLedgerEntry: onOpenLedgerEntry,
            )
          : UnifiedRecurringOccurrenceDetailPage(
              repository: repository,
              manualRepository: manualRepository,
              categories: categories,
              occurrenceId: occurrenceId,
              onOpenLedgerEntry: onOpenLedgerEntry,
            ),
    ),
  );
}
