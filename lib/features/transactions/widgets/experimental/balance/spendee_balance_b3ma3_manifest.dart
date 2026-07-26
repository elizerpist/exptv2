import 'package:flutter/material.dart';

/// Versioned metrics extracted from the active B3M-A3 source cascade in
/// `balance_latest_layout.html` (`time-rail-compact` + `permanent`).
///
/// This is intentionally a reference artifact rather than a second visual
/// spec.  Every Balance FastInfo/detail measurement must be named here first,
/// then consumed by [SpendeeBalanceVisualSpec] or the relevant widget.
abstract final class SpendeeBalanceB3mA3Manifest {
  static const source =
      'balance_latest_layout.html#createStandaloneB3MA3Column';
  static const viewport = Size(412, 892);
  static const pageBackground = Color(0xFFF1F5F9);

  /// 412px viewport - 2 × 17px gutters = the 378px reference column.
  static const horizontalInset = 17.0;
  static const contentWidth = 378.0;
  static const stackGap = 11.0;

  static const heroTop = 104.0;
  static const heroHeight = 126.0;

  // `.stage2-redesign-insight-grid` after `time-rail-compact`.
  static const fastInfoTop = 241.0;
  static const fastInfoHeight = 72.0;
  static const fastInfoGap = 9.0;
  static const fastInfoCardRadius = 26.0;
  static const fastInfoPadding = EdgeInsets.fromLTRB(9, 7, 9, 18);
  static const fastInfoHeaderSize = 20.0;
  static const fastInfoHeaderGap = 5.0;
  static const fastInfoIconSize = 12.0;
  static const fastInfoTitleSize = 8.0;
  static const fastInfoTitleLineHeight = 1.18;
  static const fastInfoBodyValueRowHeight = 14.0;
  static const fastInfoValueSize = 13.0;
  static const fastInfoTwoLineValueSize = 17.0;
  static const fastInfoTrendValueSize = 20.0;
  static const fastInfoValueLineHeight = 1.05;
  static const fastInfoTrendGlyphSize = 17.0;
  static const fastInfoMetaSize = 6.5;
  static const fastInfoGhostSize = 17.0;
  static const fastInfoGhostIconSize = 9.0;
  static const fastInfoGhostRight = 8.0;
  static const fastInfoGhostBottom = 4.0;

  // `.stage2-redesign-detail-stage` after the permanent scope selector.
  static const detailTop = 324.0;
  static const detailStageHeight = 218.0;
  static const detailCardHeight = 208.0;
  static const detailPaginationGap = 4.0;
  static const detailPaginationHeight = 6.0;
  static const detailCardRadius = 26.0;
  static const detailPadding = EdgeInsets.fromLTRB(16, 10, 16, 7);
  static const detailTitleRowHeight = 15.0;
  static const detailMainRowHeight = 36.0;
  static const detailMainTileSize = 36.0;
  static const detailMainTileRadius = 11.0;
  static const detailMainIconSize = 19.0;
  static const detailMainGap = 9.0;
  static const detailGhostSize = 17.0;
  static const detailGhostRadius = 6.0;
  static const detailGhostIconSize = 9.0;
  static const detailGhostRight = 8.0;
  static const detailGhostBottom = 7.0;

  static const actionTop = 553.0;
  static const summaryTop = 606.0;
  static const searchTop = 676.0;
  static const timeRailTop = 726.0;
}
