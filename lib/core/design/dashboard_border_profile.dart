import 'package:flutter/material.dart';

import 'dashboard_mode_palette.dart';

/// Independently configurable physical dashboard contours. These are outer
/// surface *types*, never per-record state; a LogBox day group shares one
/// setting while Income and Expense retain their explicitly separate controls.
enum DashboardBorderSurface {
  header,
  budgetHeader,
  incomeDirection,
  expenseDirection,
  summary,
  searchPill,
  balanceContent,
  mindContent,
  budgetContent,
  logBoxGroup,
}

/// Immutable session presentation state for dashboard contours.
///
/// Defaults preserve the exact pre-border-control appearance: Search and the
/// authored outer content/header cards retain their existing borders; controls,
/// Summary and LogBox groups remain borderless until selected by the user.
@immutable
final class DashboardBorderSettings {
  const DashboardBorderSettings({
    this.header = true,
    this.budgetHeader = false,
    this.incomeDirection = false,
    this.expenseDirection = false,
    this.summary = false,
    this.searchPill = true,
    this.balanceContent = true,
    this.mindContent = true,
    this.budgetContent = false,
    this.logBoxGroup = false,
  });

  static const defaults = DashboardBorderSettings();

  final bool header;
  final bool budgetHeader;
  final bool incomeDirection;
  final bool expenseDirection;
  final bool summary;
  final bool searchPill;
  final bool balanceContent;
  final bool mindContent;
  final bool budgetContent;
  final bool logBoxGroup;

  bool isEnabled(DashboardBorderSurface surface) => switch (surface) {
    DashboardBorderSurface.header => header,
    DashboardBorderSurface.budgetHeader => budgetHeader,
    DashboardBorderSurface.incomeDirection => incomeDirection,
    DashboardBorderSurface.expenseDirection => expenseDirection,
    DashboardBorderSurface.summary => summary,
    DashboardBorderSurface.searchPill => searchPill,
    DashboardBorderSurface.balanceContent => balanceContent,
    DashboardBorderSurface.mindContent => mindContent,
    DashboardBorderSurface.budgetContent => budgetContent,
    DashboardBorderSurface.logBoxGroup => logBoxGroup,
  };

  DashboardBorderSettings copyWith(
    DashboardBorderSurface surface, {
    required bool enabled,
  }) => switch (surface) {
    DashboardBorderSurface.header => DashboardBorderSettings(
      header: enabled,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.budgetHeader => DashboardBorderSettings(
      header: header,
      budgetHeader: enabled,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.incomeDirection => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: enabled,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.expenseDirection => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: enabled,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.summary => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: enabled,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.searchPill => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: enabled,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.balanceContent => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: enabled,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.mindContent => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: enabled,
      budgetContent: budgetContent,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.budgetContent => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: enabled,
      logBoxGroup: logBoxGroup,
    ),
    DashboardBorderSurface.logBoxGroup => DashboardBorderSettings(
      header: header,
      budgetHeader: budgetHeader,
      incomeDirection: incomeDirection,
      expenseDirection: expenseDirection,
      summary: summary,
      searchPill: searchPill,
      balanceContent: balanceContent,
      mindContent: mindContent,
      budgetContent: budgetContent,
      logBoxGroup: enabled,
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is DashboardBorderSettings &&
      other.header == header &&
      other.budgetHeader == budgetHeader &&
      other.incomeDirection == incomeDirection &&
      other.expenseDirection == expenseDirection &&
      other.summary == summary &&
      other.searchPill == searchPill &&
      other.balanceContent == balanceContent &&
      other.mindContent == mindContent &&
      other.budgetContent == budgetContent &&
      other.logBoxGroup == logBoxGroup;

  @override
  int get hashCode => Object.hash(
    header,
    budgetHeader,
    incomeDirection,
    expenseDirection,
    summary,
    searchPill,
    balanceContent,
    mindContent,
    budgetContent,
    logBoxGroup,
  );
}

/// The precise existing SearchPill contour is the sole dashboard border
/// contract: a 1px in-bounds [BoxDecoration] border using `#E2E8F0`.
@immutable
final class DashboardBorderProfile {
  const DashboardBorderProfile(this.settings);

  static const searchPillSourceBorder = Border.fromBorderSide(
    BorderSide(color: FluviVisualTokens.border, width: 1),
  );

  final DashboardBorderSettings settings;

  BoxBorder? borderFor(DashboardBorderSurface surface) =>
      settings.isEnabled(surface) ? searchPillSourceBorder : null;
}
