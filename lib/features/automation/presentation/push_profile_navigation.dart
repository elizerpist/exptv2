import 'package:flutter/material.dart';

import '../../../core/navigation/creation_slide_up_route.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'notification_inbox_page.dart';
import 'push_profile_details_page.dart';
import 'push_profile_wizard_page.dart';
import 'unified_push_profile_pages.dart';

/// Result returned to callers such as the recurring-rule bank-link sheet.
/// A profile alone is intentionally not advertised as a usable automation:
/// callers can distinguish a waiting profile from one with an active rule.
final class PushProfileFlowResult {
  const PushProfileFlowResult({
    required this.profileId,
    this.ruleId,
    this.ruleState,
  });

  final String profileId;
  final String? ruleId;
  final PushRuleState? ruleState;

  bool get usable => ruleState == PushRuleState.active;
}

/// One root router for both push-profile surface families. Each API receives
/// a design snapshot at opening time, preventing a dashboard preference change
/// from replacing an in-progress editor, training draft or review page.
abstract final class PushProfileNavigation {
  static Future<PushProfileFlowResult?> openCreate(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
  }) => Navigator.of(context).push<PushProfileFlowResult?>(
    creationSlideUpRoute<PushProfileFlowResult?>(
      fullscreenDialog: true,
      builder: (_) => design == PushProfileUiDesign.legacy
          ? _LegacyPushProfileCreateRoute(
              repository: repository,
              permissions: permissions,
            )
          : UnifiedPushProfileEditorPage.create(
              repository: repository,
              permissions: permissions,
            ),
    ),
  );

  static Future<void> openProfile(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
    required String profileId,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == PushProfileUiDesign.legacy
          ? PushProfileDetailsPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
            )
          : UnifiedPushProfileDetailPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
            ),
    ),
  );

  static Future<void> openInbox(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
    String? profileId,
    bool onlyReview = false,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == PushProfileUiDesign.legacy
          ? NotificationInboxPage(
              repository: repository,
              profileId: profileId,
              onlyReview: onlyReview,
            )
          : UnifiedPushInboxPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
              onlyReview: onlyReview,
            ),
    ),
  );
}

/// The legacy wizard intentionally remains the original three-step flow.
/// It has no structured completion contract, so callers refresh their shared
/// repository state after it closes just as they did before this router.
final class _LegacyPushProfileCreateRoute extends StatelessWidget {
  const _LegacyPushProfileCreateRoute({
    required this.repository,
    required this.permissions,
  });

  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;

  @override
  Widget build(BuildContext context) =>
      PushProfileWizardPage(repository: repository, permissions: permissions);
}
