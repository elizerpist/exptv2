import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_clay_donut_scene.dart';

/// One retained Partner scene for one exact analysis scope, direction and
/// selected Budget target. Partner selection only resolves a slice index; it
/// never creates a renderer resource.
@immutable
final class DashboardBudgetPartnerDistributionVisualFrame {
  DashboardBudgetPartnerDistributionVisualFrame({
    required this.semanticFrame,
    required this.scene,
    required List<int> sliceIndexByPartnerHandle,
    required Map<String, int> partnerHandleById,
  }) : sliceIndexByPartnerHandle = List<int>.unmodifiable(
         sliceIndexByPartnerHandle,
       ),
       partnerHandleById = Map<String, int>.unmodifiable(partnerHandleById);

  final DashboardBudgetPartnerDistributionDirectionFrame semanticFrame;
  final BudgetClayDonutScene scene;
  final List<int> sliceIndexByPartnerHandle;
  final Map<String, int> partnerHandleById;

  int selectedSliceIndexForPartnerId(String? partnerId) {
    final handle = partnerId == null ? null : partnerHandleById[partnerId];
    return handle == null ||
            handle < 0 ||
            handle >= sliceIndexByPartnerHandle.length
        ? -1
        : sliceIndexByPartnerHandle[handle];
  }
}

/// Both direction-local target scene banks for one exact [LedgerTimeScope].
/// The only retained multiplicative dimension is Budget target because it
/// changes partner values; Partner selection is deliberately excluded.
@immutable
final class DashboardBudgetPartnerDistributionVisualBank {
  DashboardBudgetPartnerDistributionVisualBank({
    required this.semanticBundle,
    required List<DashboardBudgetPartnerDistributionVisualFrame> incomeFrames,
    required List<DashboardBudgetPartnerDistributionVisualFrame> expenseFrames,
  }) : incomeFrames =
           List<DashboardBudgetPartnerDistributionVisualFrame>.unmodifiable(
             incomeFrames,
           ),
       expenseFrames =
           List<DashboardBudgetPartnerDistributionVisualFrame>.unmodifiable(
             expenseFrames,
           );

  final DashboardBudgetPartnerDistributionBundle semanticBundle;
  final List<DashboardBudgetPartnerDistributionVisualFrame> incomeFrames;
  final List<DashboardBudgetPartnerDistributionVisualFrame> expenseFrames;

  int get sceneCount => incomeFrames.length + expenseFrames.length;
  int get totalSliceCount => <DashboardBudgetPartnerDistributionVisualFrame>[
    ...incomeFrames,
    ...expenseFrames,
  ].fold<int>(0, (sum, frame) => sum + frame.scene.slices.length);
  int get estimatedRetainedBytes => totalSliceCount * 384;

  DashboardBudgetPartnerDistributionVisualFrame frameFor(
    LedgerDirection direction, {
    int targetHandle = 0,
  }) {
    final frames = switch (direction) {
      LedgerDirection.income => incomeFrames,
      LedgerDirection.expense => expenseFrames,
    };
    if (targetHandle < 0 || targetHandle >= frames.length) {
      throw RangeError.range(
        targetHandle,
        0,
        frames.length - 1,
        'targetHandle',
      );
    }
    return frames[targetHandle];
  }

  factory DashboardBudgetPartnerDistributionVisualBank.prepare({
    required DashboardBudgetPartnerDistributionBundle semanticBundle,
  }) {
    DashboardBudgetPartnerDistributionVisualFrame buildFrame(
      DashboardBudgetPartnerDistributionDirectionFrame frame,
    ) {
      final scene = BudgetClayDonutScene.fromSlices(<BudgetClayDonutSliceInput>[
        for (final entry in frame.entries)
          BudgetClayDonutSliceInput(
            stableId: entry.partnerId,
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      final byHandle = List<int>.filled(frame.partnerCount, -1);
      for (var index = 0; index < frame.entries.length; index += 1) {
        byHandle[frame.entries[index].partnerHandle] = index;
      }
      return DashboardBudgetPartnerDistributionVisualFrame(
        semanticFrame: frame,
        scene: scene,
        sliceIndexByPartnerHandle: byHandle,
        partnerHandleById: <String, int>{
          for (final entry in frame.entries)
            entry.partnerId: entry.partnerHandle,
        },
      );
    }

    return DashboardBudgetPartnerDistributionVisualBank(
      semanticBundle: semanticBundle,
      incomeFrames: <DashboardBudgetPartnerDistributionVisualFrame>[
        for (final frame in semanticBundle.incomeTargetFrames)
          buildFrame(frame),
      ],
      expenseFrames: <DashboardBudgetPartnerDistributionVisualFrame>[
        for (final frame in semanticBundle.expenseTargetFrames)
          buildFrame(frame),
      ],
    );
  }
}
