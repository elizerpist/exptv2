import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_distribution_svg_resources.dart';

/// One immutable renderer-ready Partner donut bank for one exact Budget target.
/// Variant zero is the unselected overview; every positive Partner receives a
/// lifted selection variant before the frame becomes drawable.
@immutable
final class DashboardBudgetPartnerDistributionVisualFrame {
  DashboardBudgetPartnerDistributionVisualFrame({
    required this.semanticFrame,
    required List<String> svgVariants,
    required List<int> variantIndexByPartnerHandle,
    required Map<String, int> partnerHandleById,
  }) : svgVariants = List<String>.unmodifiable(svgVariants),
       variantIndexByPartnerHandle = List<int>.unmodifiable(
         variantIndexByPartnerHandle,
       ),
       partnerHandleById = Map<String, int>.unmodifiable(partnerHandleById);

  final DashboardBudgetPartnerDistributionDirectionFrame semanticFrame;
  final List<String> svgVariants;
  final List<int> variantIndexByPartnerHandle;
  final Map<String, int> partnerHandleById;

  String get svg => svgVariants.first;

  String svgForPartnerHandle(String? partnerId) {
    if (partnerId == null) return svg;
    final handle = partnerHandleById[partnerId];
    if (handle == null) return svg;
    return svgVariants[variantIndexByPartnerHandle[handle]];
  }

  int variantIndexForPartnerHandle(int partnerHandle) =>
      partnerHandle >= 0 && partnerHandle < variantIndexByPartnerHandle.length
      ? variantIndexByPartnerHandle[partnerHandle]
      : 0;
}

/// Both direction-local dense target banks for one exact period. Every category
/// target source is built/prewarmed with the drawable period so an avatar tick
/// becomes only a target-handle list lookup.
@immutable
final class DashboardBudgetPartnerDistributionVisualBank {
  DashboardBudgetPartnerDistributionVisualBank({
    required this.semanticBundle,
    required List<DashboardBudgetPartnerDistributionVisualFrame> incomeFrames,
    required List<DashboardBudgetPartnerDistributionVisualFrame> expenseFrames,
    required this.sourceBytes,
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
  final int sourceBytes;

  int get variantCount =>
      incomeFrames.fold<int>(
        0,
        (total, frame) => total + frame.svgVariants.length,
      ) +
      expenseFrames.fold<int>(
        0,
        (total, frame) => total + frame.svgVariants.length,
      );
  int get estimatedRetainedBytes => sourceBytes;

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

  Iterable<String> get allSources sync* {
    for (final frame in incomeFrames) {
      yield* frame.svgVariants;
    }
    for (final frame in expenseFrames) {
      yield* frame.svgVariants;
    }
  }

  factory DashboardBudgetPartnerDistributionVisualBank.prepare({
    required DashboardBudgetPartnerDistributionBundle semanticBundle,
    required BudgetDistributionSvgSourceGenerator sourceGenerator,
  }) {
    DashboardBudgetPartnerDistributionVisualFrame buildFrame(
      DashboardBudgetPartnerDistributionDirectionFrame frame,
    ) {
      final slices = List<BudgetCategoryDistributionSvgSlice>.unmodifiable([
        for (final entry in frame.entries)
          BudgetCategoryDistributionSvgSlice(
            label: entry.title,
            value: entry.actualScaled100,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
          ),
      ]);
      final variants = <String>[
        sourceGenerator.generate(slices: slices, selectedIndex: null),
        for (var index = 0; index < frame.entries.length; index += 1)
          sourceGenerator.generate(slices: slices, selectedIndex: index),
      ];
      final variantsByPartnerHandle = List<int>.filled(frame.partnerCount, 0);
      for (var index = 0; index < frame.entries.length; index += 1) {
        variantsByPartnerHandle[frame.entries[index].partnerHandle] = index + 1;
      }
      return DashboardBudgetPartnerDistributionVisualFrame(
        semanticFrame: frame,
        svgVariants: variants,
        variantIndexByPartnerHandle: variantsByPartnerHandle,
        partnerHandleById: <String, int>{
          for (final entry in frame.entries)
            entry.partnerId: entry.partnerHandle,
        },
      );
    }

    final incomeFrames = <DashboardBudgetPartnerDistributionVisualFrame>[
      for (final frame in semanticBundle.incomeTargetFrames) buildFrame(frame),
    ];
    final expenseFrames = <DashboardBudgetPartnerDistributionVisualFrame>[
      for (final frame in semanticBundle.expenseTargetFrames) buildFrame(frame),
    ];
    return DashboardBudgetPartnerDistributionVisualBank(
      semanticBundle: semanticBundle,
      incomeFrames: incomeFrames,
      expenseFrames: expenseFrames,
      sourceBytes:
          incomeFrames.fold<int>(
            0,
            (total, frame) =>
                total +
                frame.svgVariants.fold<int>(
                  0,
                  (bytes, source) => bytes + utf8.encode(source).length,
                ),
          ) +
          expenseFrames.fold<int>(
            0,
            (total, frame) =>
                total +
                frame.svgVariants.fold<int>(
                  0,
                  (bytes, source) => bytes + utf8.encode(source).length,
                ),
          ),
    );
  }
}
