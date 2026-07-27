import 'package:flutter/material.dart';

@immutable
class BalanceHtmlMetric {
  const BalanceHtmlMetric({
    required this.name,
    required this.selector,
    required this.lineRange,
    required this.declarations,
    required this.finalValue,
  });

  final String name;
  final String selector;
  final ({int start, int end}) lineRange;
  final Map<String, List<String>> declarations;
  final String finalValue;
}

/// Canonical V3 semantic resolution of D's intentional compact/final conflict.
/// Raw HTML candidates remain independently verified; Flutter deliberately
/// chooses the individual 248px card override and derives 248 + 4 + 6 = 258.
abstract final class SpendeeBalanceV3DetailResolution {
  static const rawGenericCardHeight = 208.0;
  static const finalCardHeight = 248.0;
  static const paginationGap = 4.0;
  static const paginationHeight = 6.0;
  static const detailStageHeight =
      finalCardHeight + paginationGap + paginationHeight;
  static const rationale = 'D intentional explicit conflict resolution';
}

/// Versioned metrics extracted from the active B3M-A3 source cascade in
/// `balance_latest_layout.html` (`time-rail-compact` + `permanent`).
///
/// This is intentionally a reference artifact rather than a second visual
/// spec.  Every Balance FastInfo/detail measurement must be named here first,
/// then consumed by [SpendeeBalanceVisualSpec] or the relevant widget.
abstract final class SpendeeBalanceB3mA3Manifest {
  static const sourceSha256 =
      'ff7a00a7aeae8f636b08611443bd3975aec1303828ae5c80bce253ae1d29a2ed';

  /// Typed, immutable provenance for the frozen FastInfo, detail, and LogBox
  /// source cascades. The test-only parser verifies these against the HTML.
  static const v3Metrics = <BalanceHtmlMetric>[
    BalanceHtmlMetric(
      name: 'fast-info belt',
      selector: '.stage2-redesign-insight-grid',
      lineRange: (start: 3559, end: 3568),
      declarations: {
        'height': ['128px'],
        'min-height': ['128px'],
      },
      finalValue: '128px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info card',
      selector: '.stage2-redesign-insight-card',
      lineRange: (start: 1953, end: 1970),
      declarations: {
        'min-height': ['128px'],
        'padding': ['14px 13px 30px'],
      },
      finalValue: '128px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info header',
      selector: '.stage2-redesign-insight-head',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'grid-template-columns': ['27px minmax(0, 1fr)'],
        'column-gap': ['7px'],
      },
      finalValue: '27px minmax(0, 1fr)',
    ),
    BalanceHtmlMetric(
      name: 'fast-info icon',
      selector: '.stage2-redesign-insight-icon',
      lineRange: (start: 2002, end: 2012),
      declarations: {
        'width': ['27px'],
        'height': ['27px'],
        'border-radius': ['50%'],
      },
      finalValue: '27px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info title',
      selector: '.stage2-redesign-insight-title',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'color': ['#1b294d'],
        'font-size': ['8px'],
        'line-height': ['1.18'],
      },
      finalValue: '#1b294d',
    ),
    BalanceHtmlMetric(
      name: 'fast-info meta',
      selector: '.stage2-redesign-insight-meta',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'color': ['#65718e'],
        'font-size': ['7.8px'],
        'line-height': ['1.2'],
      },
      finalValue: '#65718e',
    ),
    BalanceHtmlMetric(
      name: 'fast-info ghost',
      selector: '.stage2-redesign-insight-ghost-toggle',
      lineRange: (start: 2149, end: 2162),
      declarations: {
        'right': ['9px'],
        'bottom': ['8px'],
        'width': ['22px'],
        'height': ['22px'],
      },
      finalValue: '9px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info no-spend label',
      selector: '.stage2-redesign-no-spend-view-label',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'right': ['31px'],
        'bottom': ['7px'],
        'left': ['9px'],
        'font-size': ['6.5px'],
      },
      finalValue: '31px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info category metrics',
      selector: '.stage2-redesign-category-change-metrics',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'gap': ['4px'],
        'margin-top': ['5px'],
      },
      finalValue: '4px',
    ),
    BalanceHtmlMetric(
      name: 'fast-info category amount',
      selector: '.stage2-redesign-category-change-amount',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'color': ['#ef4173'],
        'font-size': ['14px'],
      },
      finalValue: '#ef4173',
    ),
    BalanceHtmlMetric(
      name: 'fast-info trend icon',
      selector: '.stage2-redesign-trend-icon',
      lineRange: (start: 1936, end: 2239),
      declarations: {
        'background': ['#eeeaff'],
      },
      finalValue: '#eeeaff',
    ),
    BalanceHtmlMetric(
      name: 'detail stage source',
      selector: '.stage2-redesign-detail-stage',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'height': ['218px'],
        'gap': ['4px'],
      },
      finalValue: '218px',
    ),
    BalanceHtmlMetric(
      name: 'generic permanent top-categories card source',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-detail-carousel > .stage2-redesign-top-categories-detail',
      lineRange: (start: 3871, end: 3877),
      declarations: {
        'height': ['208px'],
        'min-height': ['208px'],
      },
      finalValue: '208px',
    ),
    BalanceHtmlMetric(
      name: 'detail pagination',
      selector: '.stage2-redesign-detail-pagination',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'height': ['6px'],
        'gap': ['4px'],
      },
      finalValue: '6px',
    ),
    BalanceHtmlMetric(
      name: 'detail active dot',
      selector: '.stage2-redesign-detail-page-dot.is-active',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'width': ['6px'],
        'height': ['6px'],
        'background': ['#e84cae'],
      },
      finalValue: '6px',
    ),
    BalanceHtmlMetric(
      name: 'detail ghost',
      selector: '.stage2-redesign-detail-ghost-toggle',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'right': ['8px'],
        'bottom': ['7px'],
        'width': ['17px'],
        'height': ['17px'],
      },
      finalValue: '8px',
    ),
    BalanceHtmlMetric(
      name: 'variable budget rail',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-today-detail .stage2-redesign-variable-budget-dimensions',
      lineRange: (start: 3925, end: 3929),
      declarations: {
        'gap': ['3px'],
        'padding': ['2px'],
        'border-radius': ['9px'],
      },
      finalValue: '3px',
    ),
    BalanceHtmlMetric(
      name: 'top categories rail',
      selector: '.stage2-redesign-top-categories-dimensions',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'gap': ['3px'],
        'padding': ['2px'],
        'border-radius': ['9px'],
      },
      finalValue: '3px',
    ),
    BalanceHtmlMetric(
      name: 'top categories main',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-top-categories-main',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'grid-template-columns': ['46px minmax(0, 1fr) auto'],
        'gap': ['11px'],
      },
      finalValue: '46px minmax(0, 1fr) auto',
    ),
    BalanceHtmlMetric(
      name: 'top merchants rail',
      selector: '.stage2-redesign-top-merchants-dimensions',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'gap': ['3px'],
        'padding': ['2px'],
        'border-radius': ['9px'],
      },
      finalValue: '3px',
    ),
    BalanceHtmlMetric(
      name: 'top merchants main',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-top-merchants-main',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'grid-template-columns': ['46px minmax(0, 1fr) auto'],
        'gap': ['11px'],
      },
      finalValue: '46px minmax(0, 1fr) auto',
    ),
    BalanceHtmlMetric(
      name: 'average daily rail',
      selector: '.stage2-redesign-average-daily-dimensions',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'gap': ['2px'],
        'padding': ['2px'],
        'border-radius': ['9px'],
      },
      finalValue: '2px',
    ),
    BalanceHtmlMetric(
      name: 'average daily main',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-average-daily-main',
      lineRange: (start: 3853, end: 4436),
      declarations: {
        'grid-template-columns': ['46px minmax(0, 1fr) auto'],
        'gap': ['11px'],
      },
      finalValue: '46px minmax(0, 1fr) auto',
    ),
    BalanceHtmlMetric(
      name: 'variable budget detail',
      selector: '.stage2-redesign-detail-stage .stage2-redesign-today-detail',
      lineRange: (start: 3914, end: 3919),
      declarations: {
        'height': ['248px'],
        'min-height': ['248px'],
      },
      finalValue: '248px',
    ),
    BalanceHtmlMetric(
      name: 'top categories detail',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-top-categories-detail',
      lineRange: (start: 4154, end: 4159),
      declarations: {
        'height': ['248px'],
        'min-height': ['248px'],
      },
      finalValue: '248px',
    ),
    BalanceHtmlMetric(
      name: 'top merchants detail',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-top-merchants-detail',
      lineRange: (start: 4239, end: 4244),
      declarations: {
        'height': ['248px'],
        'min-height': ['248px'],
      },
      finalValue: '248px',
    ),
    BalanceHtmlMetric(
      name: 'average daily detail',
      selector:
          '.stage2-redesign-detail-stage .stage2-redesign-average-daily-detail',
      lineRange: (start: 4361, end: 4366),
      declarations: {
        'height': ['248px'],
        'min-height': ['248px'],
      },
      finalValue: '248px',
    ),
    BalanceHtmlMetric(
      name: 'transaction viewport',
      selector: '.stage2-redesign-transaction-viewport',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'height': ['calc(var(--screen-h) - 470px)'],
        'padding': ['0 2px'],
      },
      finalValue: 'calc(var(--screen-h) - 470px)',
    ),
    BalanceHtmlMetric(
      name: 'transaction day card',
      selector: '.stage2-redesign-transaction-day-card',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'border-radius': ['18px'],
      },
      finalValue: '18px',
    ),
    BalanceHtmlMetric(
      name: 'transaction days',
      selector: '.stage2-redesign-transaction-days',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'gap': ['10px'],
      },
      finalValue: '10px',
    ),
    BalanceHtmlMetric(
      name: 'transaction day',
      selector: '.stage2-redesign-transaction-day',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'gap': ['5px'],
      },
      finalValue: '5px',
    ),
    BalanceHtmlMetric(
      name: 'transaction day title',
      selector: '.stage2-redesign-transaction-day-title',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'padding': ['7px 2px 0'],
        'color': ['#64748b'],
        'font-size': ['10px'],
      },
      finalValue: '7px 2px 0',
    ),
    BalanceHtmlMetric(
      name: 'transaction row',
      selector: '.stage2-redesign-transaction-row',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'min-height': ['55px'],
        'grid-template-columns': ['34px minmax(0, 1fr) auto 24px'],
      },
      finalValue: '55px',
    ),
    BalanceHtmlMetric(
      name: 'transaction avatar',
      selector: '.stage2-redesign-transaction-avatar',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'width': ['34px'],
        'height': ['34px'],
      },
      finalValue: '34px',
    ),
    BalanceHtmlMetric(
      name: 'transaction avatar icon',
      selector: '.stage2-redesign-transaction-avatar .slot-icon',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'width': ['18px'],
        'height': ['18px'],
      },
      finalValue: '18px',
    ),
    BalanceHtmlMetric(
      name: 'transaction merchant',
      selector: '.stage2-redesign-transaction-copy strong',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'color': ['#1d2b50'],
        'font-size': ['13px'],
        'font-weight': ['900'],
      },
      finalValue: '#1d2b50',
    ),
    BalanceHtmlMetric(
      name: 'transaction category',
      selector: '.stage2-redesign-transaction-copy span',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'margin-top': ['6px'],
        'color': ['#7d88a4'],
        'font-size': ['10px'],
      },
      finalValue: '6px',
    ),
    BalanceHtmlMetric(
      name: 'transaction amount',
      selector: '.stage2-redesign-transaction-value strong',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'color': ['#ff3e73'],
        'font-size': ['13px'],
        'font-weight': ['950'],
      },
      finalValue: '#ff3e73',
    ),
    BalanceHtmlMetric(
      name: 'transaction edit',
      selector: '.stage2-redesign-transaction-edit',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'width': ['24px'],
        'height': ['24px'],
      },
      finalValue: '24px',
    ),
    BalanceHtmlMetric(
      name: 'transaction edit icon',
      selector: '.stage2-redesign-transaction-edit .slot-icon',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'width': ['13px'],
        'height': ['13px'],
      },
      finalValue: '13px',
    ),
    BalanceHtmlMetric(
      name: 'transaction edit focus',
      selector: '.stage2-redesign-transaction-edit:focus-visible',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'outline': ['2px solid rgba(125, 135, 152, .42)'],
        'outline-offset': ['1px'],
      },
      finalValue: '2px solid rgba(125, 135, 152, .42)',
    ),
    BalanceHtmlMetric(
      name: 'transaction edit active',
      selector: '.stage2-redesign-transaction-edit:active',
      lineRange: (start: 4854, end: 5003),
      declarations: {
        'transform': ['scale(.92)'],
      },
      finalValue: 'scale(.92)',
    ),
  ];
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
  static const fastInfoHeight = 128.0;
  static const fastInfoGap = 9.0;
  static const fastInfoCardRadius = 26.0;
  static const fastInfoPadding = EdgeInsets.fromLTRB(9, 7, 9, 18);
  static const fastInfoHeaderSize = 20.0;
  static const fastInfoHeaderGap = 5.0;
  static const fastInfoIconSize = 12.0;
  static const fastInfoTitleSize = 8.0;
  static const fastInfoTitleLineHeight = 1.18;
  static const fastInfoBodyValueRowHeight = 22.0;
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
  static const detailStageHeight =
      SpendeeBalanceV3DetailResolution.detailStageHeight;
  static const detailCardHeight =
      SpendeeBalanceV3DetailResolution.finalCardHeight;
  static const detailPaginationGap = 4.0;
  static const detailPaginationHeight = 6.0;
  static const detailCardRadius = 26.0;
  static const detailPadding = EdgeInsets.fromLTRB(16, 12, 16, 10);
  static const detailTitleRowHeight = 21.0;
  static const detailMainRowHeight = 52.0;
  static const detailMainTileSize = 46.0;
  static const detailMainTileRadius = 14.0;
  static const detailMainIconSize = 24.0;
  static const detailMainGap = 11.0;
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
