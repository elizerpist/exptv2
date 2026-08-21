const fs = require('fs');
const path = require('path');
const assert = require('assert');
const crypto = require('crypto');

const htmlPath = path.join(__dirname, 'color_lab.html');
assert(fs.existsSync(htmlPath), 'Missing docs/prototypes/color_lab.html');
const html = fs.readFileSync(htmlPath, 'utf8');
const schedeeOutfitFontPath = path.join(__dirname, 'schedee_outfit_variable.ttf');
assert(
  fs.existsSync(schedeeOutfitFontPath),
  'Missing copied Schedee Outfit font asset for the D1 brand-font test',
);
const focusHeaderNotePath = path.join(
  __dirname,
  '../superpowers/specs/2026-07-13-focus-mode-header-notes.md',
);
assert(
  fs.existsSync(focusHeaderNotePath),
  'Missing focus mode header notes file for the current B/C/D app direction',
);
const focusHeaderNote = fs.readFileSync(focusHeaderNotePath, 'utf8');

const required = [
  'data-source="lib/features/transactions/widgets/header_card/transaction_header_metrics.dart"',
  '--screen-w: 412px',
  '--header-h: 188px',
  '--spendee-header-top: 104px',
  '--spendee-header-h: 104px',
  '--spendee-content-top: 212px',
  '--spendee-logo-size: 42px',
  '--spendee-logo-icon-size: 56px',
  '--spendee-brand-top: 48px',
  '--spendee-type-row-h: 66px',
  '--spendee-type-pill-h: 42px',
  '--spendee-logbox-h: 64.8px',
  '--spendee-log-area-top: 216px',
  '--spendee-date-header-h: 24px',
  '--spendee-bottom-nav-h: 70px',
  '--spendee-bottom-nav-bottom: 18px',
  '--spendee-bottom-nav-side: 8px',
  '--spendee-status-bar-h: 24px',
  '--spendee-status-glow-edge: 72px',
  '--spendee-status-glow-fade-h: 48px',
  '--spendee-header-glow-h: 264px',
  '--spendee-soft-card-shadow: 0 8px 20px rgba(31, 45, 70, .08), 0 1px 3px rgba(31, 45, 70, .04)',
  '--spendee-header-glow: var(--spendee-header-bg)',
  '--spendee-backheader-glow: var(--spendee-backheader-category-color)',
  '--spendee-header-opacity: 1',
  '--spendee-balance-ink: #14213a',
  '--spendee-balance-ink-shadow: 0 1px 0 rgba(255,255,255,.42), 0 2px 8px rgba(255,255,255,.22)',
  '--spendee-balance-ink-stroke: rgba(255,255,255,.20)',
  'function updateSpendeeHeaderGlow',
  'function updateSpendeeBackheaderGlow',
  'function updateSpendeeBalanceInk',
  "target.dataset.colorTarget === 'header-card'",
  'updateSpendeeHeaderGlow(selectionState.selectedColor)',
  'updateSpendeeBalanceInk();',
  '--content-top: 192px',
  '--type-pill-h: 52px',
  '--summary-pill-h: 70px',
  '--search-pill-h: 46px',
  '--logbox-h: 72px',
  '--sheet-card-h: 150px',
  '--query-sheet-h: 430px',
  '--bottom-nav-h: 80px',
  '--fab-size: 66px',
  'id="selectedPaletteRow"',
  'data-palette-group="selected-source"',
  'data-selected-source-slot="B6"',
  'data-selected-source-slot="N3"',
  'data-selected-source-slot="D1"',
  'function toggleColorSelection',
  'function applySelectedColor',
  'function applySelectedTextColor',
  'id="zoomHost"',
  'id="zoomSurface"',
  'id="zoomReadout"',
  'function setCanvasZoom',
  'min: 0.3,',
  'function handlePinchMove',
  'function handleWheelZoom',
  'data-color-target="app-background"',
  'data-color-target="add-transaction-sheet-background"',
  'data-color-target="header-card"',
  'data-color-target="logbox-background"',
  'data-color-target="vendor-card-background"',
  'data-color-target="category-card-background"',
  'data-color-target="bottom-nav-background"',
  'data-color-target="bottom-nav-button"',
  'data-color-target="bottom-action-button"',
  'data-color-target="fab-button"',
  'data-color-target="text-pill"',
  'data-color-target="vendor-search-pill"',
  'data-color-target="category-menu-button"',
  'data-color-target="income-type-button"',
  'data-color-target="expense-type-button"',
  'data-color-target="home-summary-pill"',
  'data-color-target="home-search-pill"',
  'data-color-target="header-balance-value-text"',
  'data-color-mode="text"',
  '--category-menu-button-bg',
  '--income-button-bg',
  '--expense-button-bg',
  '--summary-pill-bg',
  '--search-pill-bg',
  '--spendee-header-bg',
  '--spendee-income-button-bg',
  '--spendee-expense-button-bg',
  '--spendee-summary-pill-bg',
  '--spendee-search-pill-bg',
  '--spendee-category-menu-button-bg: rgba(255,255,255,.32)',
  '--spendee-category-menu-button-border: rgba(255,255,255,.48)',
  '--spendee-category-menu-button-icon: linear-gradient(180deg, rgba(255,255,255,.96) 0%, rgba(222,255,255,.72) 52%, rgba(149,229,236,.46) 100%)',
  '--spendee-category-menu-button-size: 33.6px',
  '--spendee-category-menu-button-radius: 13.6px',
  '--vendor-search-pill-bg',
  '--local-text-color',
  'function labelPaletteSlots',
  'dataset.slot = slot',
  '.color-swatch:not([data-selected-source-slot]):not([data-fixed-slot])',
  'content: attr(data-slot)',
  'data-section="alternative-design"',
  'data-section-row="main-menu"',
  'data-section-row="common-header-dashboard"',
  'data-screen="alt-common-header-stage0"',
  'data-screen="alt-common-header-stage1"',
  'data-screen="alt-common-header-stage2"',
  'data-common-header-mode="balance"',
  'data-common-header-mode="budget"',
  'data-common-header-mode="mind"',
  'data-common-header-mode-source="balance"',
  'class="common-header-mode"',
  'class="common-mode-title"',
  'Balance mode',
  'Budget mode',
  'Mind mode',
  'data-common-header-state="collapsed"',
  'data-common-header-state="context"',
  'data-common-header-state="fastinfo"',
  'data-common-header-snap="0"',
  'data-common-header-snap="1"',
  'data-common-header-snap="2"',
  'data-snap-heights="collapsed:160dp context:284dp fastinfo:520dp"',
  'data-reference="/storage/emulated/0/spendee/commonheader1.png"',
  'data-reference-secondary="/storage/emulated/0/spendee/commonheader2.png"',
  'data-context-selector="category-carousel"',
  'data-gesture-x="category-swipe"',
  'data-gesture-y="snap-expand-collapse"',
  'id="alternativeDesignReview"',
  'id="alternativePalette"',
  'id="alternativeAppPaletteRow"',
  'id="alternativeSlotPaletteRow"',
  'id="balanceHeaderScaleLab"',
  'id="budgetHeaderScaleLab"',
  'id="mindHeaderScaleLab"',
  'data-balance-scale-track',
  'data-limits-scale-track',
  'data-cool-scale-track',
  'id="backheaderOpacityScaleLab"',
  'data-backheader-opacity-scale-track',
  'data-backheader-opacity-handle',
  'data-scale-kind="limits"',
  'data-scale-kind="cool"',
  'data-balance-window',
  'data-limits-window',
  'data-cool-window',
  'data-window-drag-handle',
  'data-window-width-input',
  'id="balanceWindowInput"',
  'id="limitsWindowInput"',
  'id="coolWindowInput"',
  'data-scale-target-mode="balance"',
  'data-scale-target-mode="budget"',
  'data-scale-target-mode="mind"',
  'function initCommonHeaderModeRows',
  'function applyCommonHeaderModeGradient',
  'function createModeScaleLab',
  'function buildReactiveGlassAccent',
  'function applyCommonHeaderModeOpacity',
  'function initModeOpacityScaleController',
  'docs/superpowers/specs/2026-07-13-focus-mode-header-notes.md',
  'function buildCommonBudgetGlossyExtendedInfo',
  'function buildCommonBudgetCorePartition',
  'function syncCommonBudgetCorePartition',
  'function buildCommonBalanceInsightLine',
  'function syncCommonBalanceInsightLine',
  'function buildCommonBalanceDiagnosticsContent',
  'function syncCommonHeaderBalanceDiagnosticsLayer',
  'function buildCommonStage1AvatarStrip',
  'function buildCommonMindScoreRibbon',
  'function buildCommonMindMergedBarGraphContent',
  'function buildCommonMindDoubleGraphContent',
  'const commonMindStage1BoxGraphConfig',
  'function buildCommonMindStage1BoxGraphContent',
  'function spawnCommonHeaderMindPortalTrailPoint',
  'function initCommonHeaderMindPortalTouch',
  'function moveQueryMenuRowToTop',
  'function focusQueryMenuQ1AOnLoad',
  'function buildCommonMindHeatmapContent',
  'function buildMindHeatmapYearGrid',
  'function buildMindHeatmapMonthGrid',
  'function removeCommonHeaderBalanceStage2Residue',
  'function setCommonMindStage1ChartLayerPresentation',
  'function ensureCommonHeaderMindStage1ChartsLayer',
  'function syncCommonHeaderMindHeatmapLayer',
  'function buildCommonMindMonthlyHeatmapContent',
  'function ensureCommonMindMonthlyStage2Screen',
  'function buildCommonBudgetCategoryPieContent',
  'function syncCommonHeaderBudgetPieLayer',
  'function syncCommonHeaderStage2Stage1Layer',
  'common-budget-stage1-layer',
  'common-budget-core-partition',
  'function buildCommonHeaderHandle',
  'data-focus-mode-stage1="budget-glossy-extended-info"',
  'data-focus-mode-stage1="balance-reserve-summary"',
  'data-focus-mode-stage2="balance-income-expense"',
  'data-balance-insight-stage0',
  'data-balance-insight-line="single"',
  'data-balance-ratio-placement="reserve-progress-slot"',
  'common-balance-ratio-row',
  'common-balance-ratio-metrics',
  'common-balance-stage1-card-grid',
  'common-balance-diagnostics-layer',
  'data-stage2-extra="balance-diagnostics"',
  'data-balance-diagnostic-panel="scrollable"',
  'data-balance-diagnostic-row="reserve"',
  'data-balance-diagnostic-row="balance-ratio"',
  'data-balance-diagnostic-row="savings-rate"',
  'data-balance-diagnostic-row="buffer"',
  'data-balance-diagnostic-row="forecast"',
  'data-balance-diagnostic-row="ghost-income"',
  'data-fastinfo-card="balance-placeholder"',
  'common-balance-placeholder-card',
  'class="common-stage1-avatar-strip"',
  'data-score-ribbon-stage0',
  'data-score-ribbon-path="bad-neutral-good"',
  'data-focus-mode-stage1="mind-${kind}-double-graph"',
  'common-mind-merged-graph',
  'common-mind-half-chart',
  'buildCommonMindMergedBarGraphContent(\'expense\')',
  'buildCommonMindMergedBarGraphContent(\'income\')',
  'data-mind-merged-graph="${kind}"',
  'data-mind-double-graph="${kind}"',
  'data-mind-chart-box-size="d2-stage1"',
  'data-mind-chart-part="${part.key}"',
  "const monthlyAreaOverlay = !isIncome && part.key === 'monthly'",
  'common-mind-monthly-area-fill',
  'common-mind-monthly-area-line',
  'data-mind-monthly-area="havi-kiadas"',
  'const barHeightScale = 0.5;',
  "const monthlyTitle = isIncome ? 'Havi bevétel' : 'Havi kiadás';",
  "const patternsTitle = isIncome ? 'Bevételi minták' : 'Minták';",
  'common-mind-box-graph-layer',
  'common-mind-previous-period-kpi',
  'data-previous-period-comparison="true"',
  'data-previous-period-arrow="up"',
  'mind-boxed-graphs-d2',
  'data-mind-box-card-role="${card.key}"',
  'key: \'period-expense-bars\'',
  'key: \'expense-pattern-volume\'',
  'data-mind-box-card-count="2"',
  'data-mind-box-layout="direct-background"',
  'visual: \'line-bar\'',
  'data-mind-box-chart-style="${card.visual}"',
  'data-mind-portal-touch',
  'data-mind-portal-layer',
  'common-mind-portal-layer',
  'common-mind-portal-trail',
  'common-mind-portal-trail-dot',
  '@property --mind-header-gradient-axis',
  '@keyframes mindHeaderValueWater',
  '@keyframes mindPortalTrailFade',
  'function setMindHeaderGradientStops',
  'function applyMindPortalTestHeaderGradient',
  'data-mind-portal-test-source',
  'data-mind-portal-test-header',
  'data-mind-portal-signature-panel',
  'data-mind-portal-signature-slider="balance"',
  'data-mind-portal-signature-slider="limits"',
  'data-mind-portal-signature-slider="cool"',
  'data-mind-portal-signature-slider="meadow-green"',
  'data-mind-portal-signature-slider="soft-rainbow"',
  'data-mind-portal-signature-slider="ocean-blue-serenity"',
  'data-mind-portal-opacity-slider',
  'data-mind-portal-idle-canvas',
  'common-mind-portal-idle-canvas',
  'function buildMindPortalSignature',
  'function applyMindPortalSignature',
  'function initMindPortalTestSignatureControls',
  'function initMindPortalTestOpacityControl',
  'function drawMindPortalEnergyFrame',
  'function initMindPortalEnergyCanvas',
  'function spawnMindPortalRipple',
  'function pulseMindPortalIdleField',
  'function initMindPortalEnergyControls',
  'function initMindPortalControlScrollRouting',
  'Portal touch és üzenet teszt header',
  'data-mind-box-chart-style="line-bar"',
  'data-reference="/storage/emulated/0/spendee/scorechart.png"',
  'common-score-axis-label',
  'common-score-month-label',
  'common-score-endpoint',
  'common-stage2-heatmap-layer',
  'common-stage2-heatmap-panel',
  'data-stage2-extra="mind-heatmap"',
  'data-stage2-extra="mind-heatmap-month"',
  'data-heatmap-panel="score-glass"',
  'data-heatmap-panel="sum-glass"',
  'data-heatmap-header="compact-no-score"',
  'data-heatmap-grid="month"',
  'data-heatmap-month-view="single"',
  'alt-common-header-mind-month-heatmap-stage2',
  'data-stage2-scrollable',
  'data-stage2-extra="budget-category-pie"',
  'common-budget-pie-stage2-layer',
  'data-budget-pie-scrollable="true"',
  'CategoryDonutChart',
  'stats-category-donut',
  'data-color-target="heatmap-cell-color"',
  '--heatmap-active-color',
  'mind-heatmap-month-card',
  'mind-heatmap-card-variant',
  'data-heatmap-month-index',
  'StatsMonthCard.cardHeight',
  'StatsYearCalendar',
  'heatmapIntensity',
  'data-stage2-includes-stage1="true"',
  'common-stage2-stage1-layer',
  'data-source="lib/features/stats/widgets/stats_fast_info_graph.dart"',
  'data-source="lib/features/transactions/widgets/header_card/category_budget_stage.dart"',
  'data-focus-budget-interaction="longpress-vertical-joystick"',
  'class="common-header-expand-handle"',
  'data-mode-opacity-scale-track',
  'data-mode-opacity-handle',
  'data-scale-kind="mode-opacity"',
  '--common-header-gloss-x',
  '--common-header-gloss-y',
  '--spendee-header-gloss-accent',
  '--balance-opacity-center-pct',
  '--budget-opacity-center-pct',
  '--mind-opacity-center-pct',
  '--cool-center-pct: 50',
  '--cool-window-left-pct: 36',
  '--cool-window-width-pct: 28',
  '--cool-scale-gradient',
  '--spendee-backheader-category-color',
  '--spendee-backheader-opacity',
  '--backheader-opacity-center-pct',
  '--inline-limit-ring-deg',
  'data-screen="alt-fastinfo-stage1"',
  'data-screen="alt-fastinfo-stage1-empty"',
  'data-screen="alt-fastinfo-stage2"',
  'data-screen="alt-backheader"',
  'data-screen="alt-backheader-expanded"',
  'data-fastinfo-state="stage1"',
  'data-fastinfo-state="stage1-empty"',
  'data-fastinfo-state="stage2"',
  'data-fastinfo-limit-state="none"',
  'data-fastinfo-overlay-mode="pushdown"',
  'data-fastinfo-layout="header-stage1"',
  'data-fastinfo-layout="header-expanded"',
  'class="app-header spendee-header fastinfo-stage1-header"',
  'class="app-header spendee-header fastinfo-expanded-header"',
  'class="fastinfo-handle"',
  'class="spendee-fastinfo-panel"',
  'data-empty-state="category-limit-none"',
  'fastinfo-balance-explainer',
  'class="fastinfo-balance-progress"',
  'data-balance-progress="no-limit"',
  'data-balance-ratio="0"',
  'data-balance-direction="decreasing"',
  'data-balance-state="negative-floor"',
  'data-balance-empty-floor="true"',
  'class="fastinfo-partition-bar category-limit-partition-bar"',
  'data-source="lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart"',
  'data-limit-allocation-source="lib/features/transactions/data/limit_allocation_manager.dart"',
  'data-limit-sizing-source="lib/features/transactions/widgets/header_card/category_budget_stage.dart"',
  'data-limit-total-allocated-pct="70"',
  'data-limit-total-spent-pct="35"',
  'data-limit-free-pct="30"',
  'data-limit-category-count="5"',
  'data-limit-macro-ratio="10-20-30-10"',
  'class="fastinfo-partition-segment used"',
  'class="fastinfo-partition-segment remaining"',
  'class="fastinfo-partition-segment free"',
  'class="fastinfo-chart-card"',
  'spendee-backheader-card',
  'spendee-backheader-card-expanded',
  'class="backheader-extra-strip"',
  'class="backheader-status-line backheader-status-line-focus"',
  'data-backheader-extra-context="category-limit-partition"',
  'data-backheader-status-text="spent"',
  'data-backheader-status-text="remaining"',
  'data-inline-limit-feedback-spent',
  'data-inline-limit-feedback-remaining',
  'data-backheader-stage="browse"',
  'data-backheader-browse-state',
  'data-backheader-focus-state',
  'data-backheader-focus-trigger',
  'data-backheader-focus-back',
  'data-reference="/storage/emulated/0/spendee/category.png"',
  'class="category-selector-route"',
  'data-category-selector-mode="fullscreen"',
  'data-color-target="category-selector-background"',
  'data-color-var="--category-selector-bg"',
  'class="category-selector-search-pill"',
  'Keresés kategóriák között...',
  'data-edit-trigger="longpress"',
  'class="category-selector-action-row"',
  'data-category-action="select-all"',
  'data-category-action="select-none"',
  'data-category-action="add-new"',
  'class="category-selector-add-row"',
  'class="category-card category-selector-card',
  'class="category-selector-check selected"',
  'class="category-selector-footer"',
  'data-color-var="--category-selector-apply-bg"',
  'class="vendor-selector-route"',
  'data-vendor-selector-mode="fullscreen"',
  'class="vendor-search-pill vendor-selector-search-pill"',
  'Keresés vendorok között...',
  'data-vendor-sort="abc"',
  'data-vendor-group="A"',
  'data-vendor-group="B"',
  'class="vendor-card vendor-selector-card',
  'data-screen="alt-backheader-limit-edit-keyboard"',
  'data-backheader-stage="limit-edit"',
  'data-limit-edit-mode="floating-keyboard"',
  'data-limit-edit-source="amount-tap"',
  'data-limit-edit-entrypoints="stage1 stage2"',
  'data-keyboard-state="open"',
  'data-sheet-motion="fixed"',
  'data-background-interaction="inert"',
  'limit-amount-inline-tap',
  'backheader-edit-inert',
  'class="limit-edit-floating-card"',
  'class="limit-edit-avatar"',
  'class="limit-edit-text-input"',
  'mock-keyboard',
  'numeric-keyboard',
  'Limitösszeg',
  'data-screen="alt-add-category-editor"',
  'data-category-editor-mode="fullscreen"',
  'data-source="lib/features/transactions/widgets/category_menu/category_editor_panel.dart"',
  'data-source="lib/features/transactions/widgets/category_menu/category_slot_grid.dart"',
  'class="category-editor-route"',
  'class="category-editor-name-pill"',
  'class="category-editor-slot-section color-section"',
  'class="category-editor-slot-section icon-section"',
  'class="category-editor-color-grid"',
  'class="category-editor-icon-grid"',
  'class="category-editor-preview-pill"',
  'data-category-editor-section="colors"',
  'data-category-editor-section="icons"',
  'data-color-target="category-editor-background"',
  'data-color-target="category-editor-name-pill"',
  'data-color-target="category-editor-preview-pill"',
  'data-color-target="category-editor-save-button"',
  'data-screen="alt-vendor-editor"',
  'data-vendor-editor-mode="fullscreen"',
  'data-vendor-editor-entry="longpress"',
  'class="vendor-editor-route"',
  'class="vendor-editor-name-pill"',
  'class="vendor-editor-category-card"',
  'class="vendor-editor-insight-grid"',
  'class="vendor-editor-rule-card"',
  'class="vendor-editor-preview-card"',
  'data-screen="alt-icon-selector"',
  'data-icon-selector-mode="fullscreen"',
  'data-source="lib/features/transactions/widgets/category_menu/icon_selector_sheet.dart"',
  'class="icon-selector-route"',
  'class="icon-selector-grid"',
  'class="icon-selector-option selected"',
  'data-body-top="header-card-top"',
  'class="category-selector-footer-actions"',
  'class="category-selector-cancel',
  'data-color-target="bottom-cancel-button"',
  'data-color-var="--category-selector-cancel-bg"',
  'data-color-target="category-color-slot"',
  'data-color-target="category-icon-slot"',
  'data-color-target="category-preview-avatar"',
  'data-transaction-editor-layout="amount-hero-v1"',
  'data-source="lib/features/transactions/widgets/add_transaction_sheet.dart"',
  'class="add-transaction-card add-transaction-card-redesign"',
  'class="transaction-sheet-header"',
  'class="transaction-amount-hero"',
  'data-color-target="transaction-amount-hero"',
  'data-color-var="--transaction-amount-hero-bg"',
  'transaction-name-pill',
  'transaction-category-pill',
  'transaction-date-time-row',
  'class="transaction-sheet-footer"',
  'class="transaction-save"',
  'data-color-target="transaction-save-button"',
  'data-color-var="--transaction-save-bg"',
  'Tranzakció hozzáadása',
  'data-screen="alt-add-recurring-sheet"',
  'data-recurring-editor-layout="schedule-hero-v1"',
  'data-source="lib/features/transactions/widgets/recurring_manager_sheet.dart"',
  'data-source="lib/features/transactions/models/recurring_rule.dart"',
  'class="add-recurring-card add-recurring-card-redesign"',
  'class="recurring-sheet-header"',
  'class="recurring-trigger-row"',
  'class="recurring-schedule-hero"',
  'class="recurring-transaction-summary"',
  'class="recurring-frequency-row"',
  'class="recurring-next-run-pill"',
  'class="recurring-save"',
  'Ismétlődés hozzáadása',
  'data-screen="alt-add-recurring-push-sheet"',
  'data-recurring-editor-layout="push-learning-v1"',
  'data-recurring-sheet-height="full"',
  'data-source="lib/features/settings/models/notification_parser_rule.dart"',
  'class="add-recurring-card add-recurring-card-redesign add-recurring-push-card"',
  'class="recurring-push-hero"',
  'class="recurring-push-app-pill"',
  'class="recurring-push-training-card"',
  'class="recurring-training-mode-row"',
  'class="recurring-training-token-row"',
  'class="recurring-parser-preview"',
  'class="recurring-tolerance-row"',
  'Példa push üzenet',
  'Mindet kijelölni',
  'Egyiket se',
  'Új kategória',
  'Cancel',
  'OK',
  'data-inline-limit-summary',
  'data-inline-current',
  'data-inline-limit-value',
  'data-inline-limit-slider',
  'No limit',
  'data-color-target="backheader-category-color"',
  'data-color-var="--spendee-backheader-category-color"',
  'function initBalanceHeaderScaleLab',
  'function initReactiveScaleController',
  'function initOpacityScaleController',
  'function initBackheaderPrototype',
  'function setBackheaderFocusMode',
  'function initBackheaderOpacityScale',
  'function setBackheaderOpacityScaleState',
  'function initInlineLimitEditor',
  'function initSpendeeLogoEditor',
  'function applySelectedLogoPathColor',
  'function resolveLogoEditorColor',
  'function setLogoPathGradient',
  'function syncLogoLivePreviews',
  'function renderLogoSvgPaths',
  'function updateBalanceHeaderFromScale',
  'function updateHeaderOpacityFromScale',
  'function updateBackheaderOpacityFromScale',
  'function setOpacityScaleState',
  'function sampleBalanceScaleColor',
  'function sampleLimitsScaleColor',
  'function sampleOpacityScaleValue',
  '--balance-scale-stop-10: #0b8f54',
  '--limits-scale-stop-1: #6d28d9',
  '--limits-scale-stop-5: #fbcfe8',
  '--limits-scale-stop-10: #db2777',
  '--limits-center-pct: 50',
  '--limits-scale-gradient:',
  '--limits-window-gradient:',
  '--opacity-center-pct: 50',
  '--opacity-scale-stop-1: rgba(20,33,58,.16)',
  '--opacity-scale-stop-10: rgba(20,33,58,1)',
  '--opacity-scale-gradient:',
  'id="spendeeLogoEditor"',
  'data-logo-editor',
  'id="spendeeLogoEditorSvg"',
  'path.dataset.logoEditorPath = path.id;',
  "path.dataset.colorTarget = 'logo-path';",
  'data-palette-group="alternative-app-shades"',
  'data-palette-group="alternative-colour-slots"',
  'data-reference="/storage/emulated/0/spendee/dashboard.png"',
  'data-reference="/storage/emulated/0/spendee/fastinfo.png"',
  'data-logo-source="/storage/emulated/0/spendee/Fluvi_vector.svg"',
  'fluvi_vector.svg?v=20260716-fluvi-logo-v1',
  'id="customGradientPaletteRow"',
  'data-custom-gradient-palette',
  'data-custom-gradient-slot="1"',
  'data-custom-gradient-slot="5"',
  'data-custom-gradient-boundary-slider="1"',
  'spendee-dashboard-screen',
  'spendee-brand-lockup',
  'spendee-logo',
  'spendee-logo-live-preview',
  'data-logo-live-preview',
  'spendee-title">fluvi',
  'your personal <span>financial trainer</span>',
  'class="app-header spendee-header"',
  'logbox-avatar-icon',
  'data-icon-color="#ffffff"',
  'category-avatar-icon',
  'vendor-avatar-icon',
  'url(\'/assets/icons/lucide/',
  'data-gradient-source="/storage/emulated/0/spendee/layout  avatar colour gradient.png"',
  '--slot-gradient-0:',
  '--slot-gradient-20:',
  'data-fixed-slot="1"',
  'data-fixed-slot="21"',
  'data-palette-layout="3x7-rainbow"',
  'data-rainbow-hue="0"',
  'data-rainbow-hue="280"',
  '#alternativeSlotPaletteRow .palette-grid',
  'data-color-target="vendor-avatar-circle"',
  'data-color-target="logbox-avatar-circle"',
  'data-color-target="category-avatar-circle"',
  'data-color-var="--vendor-avatar-bg"',
  'data-color-var="--logbox-avatar-bg"',
  'data-color-var="--category-avatar-bg"',
];

for (const token of required) {
  assert(html.includes(token), `Missing required token: ${token}`);
}

const cleanupForbiddenTokens = [
  'data-section="legacy-design"',
  'id="legacyColorPalette"',
  'data-screen="home"',
  'data-screen="category-sheet"',
  'data-screen="vendor-sheet"',
  'data-screen="add-transaction-sheet"',
  'data-color-target="sheet-background"',
  'data-color-target="magnet-strip"',
  'data-color-target="header-app-title-text"',
  'data-color-target="header-balance-label-text"',
  'data-section-row="stats-menu"',
  'data-screen="alt-stats-expense-dashboard"',
  'S1 · Statisztika',
  'data-screen="alt-common-header-mind-heatmap-full"',
  'D-full ·',
  'id="previousSlotPaletteRow"',
  'id="originalSlotPaletteRow"',
  'id="fabBlueGradientPaletteRow"',
  'data-palette-group="previous-colour-slots"',
  'data-palette-group="original-colour-slots"',
  'data-palette-group="fab-blue-gradients"',
  'data-fab-base="#06b6d4"',
  '--previous-slot-gradient-',
  '--original-slot-gradient-',
  '--fab-blue-gradient-',
  'function buildMindHeatmapVariantGallery',
  'function initMindHeatmapScreens',
  'data-mind-heatmap-render-target',
  'data-mind-heatmap-variant-target',
  'data-heatmap-variant-gallery',
  'mind-heatmap-variant-gallery',
];
for (const token of cleanupForbiddenTokens) {
  assert(!html.includes(token), `Cleanup must remove legacy token: ${token}`);
}

const screenCount = (html.match(/class="phone-screen/g) || []).length;
assert.strictEqual(
  screenCount,
  35,
  'Expected cleaned lower Fluvi/dashboard/edit screens, common-header B3M mother-child preview, B/C/D rows, Query Menu Q1A category-vendor hierarchy, Query-row expense/income transaction sheets, Q3A trigger-type step, nine recurring wizard screens, and three category wizard popup screens',
);

const alternativeSection = html.match(
  /<section class="alternative-design" id="alternativeDesignReview" data-section="alternative-design">[\s\S]*?<section class="palette-area structured-palette" id="alternativePalette"/,
)?.[0];
assert(
  alternativeSection,
  'Missing alternative design section with duplicated menus above its structured palette',
);
assert(
  /\.alternative-design > \.screens > \.query-menu-row\s*\{[\s\S]*?order:\s*-100;[\s\S]*?margin:\s*0;[\s\S]*?\}/.test(html) &&
    html.includes('function moveQueryMenuRowToTop()') &&
    html.includes("const screens = document.querySelector('#alternativeDesignReview > .screens');") &&
    html.includes("const queryRow = screens?.querySelector('[data-query-menu-row]');") &&
    html.includes('screens.firstElementChild !== queryRow') &&
    html.includes('screens.insertBefore(queryRow, screens.firstElementChild);') &&
    /function focusQueryMenuQ1AOnLoad\(\) \{[\s\S]*?\[data-query-menu-row\] \[data-screen="alt-query-menu-category-vendor-hierarchy"\][\s\S]*?scrollIntoView\(\{ block: 'start', inline: 'start' \}\)[\s\S]*?queryQ1A\.focus/.test(html) &&
    /initCommonHeaderModeRows\(\);[\s\S]*?moveQueryMenuRowToTop\(\);[\s\S]*?initCommonHeaderMindPortalTouch\(\);[\s\S]*?initQueryMenuPrototype\(\);[\s\S]*?focusQueryMenuQ1AOnLoad\(\);/.test(html) &&
    !html.includes('function focusCommonHeaderMindD1OnLoad') &&
    !html.includes('focusCommonHeaderMindD1OnLoad();'),
  'Q row must be the first alternative-design row at refresh and the remaining Q1A screen must receive the post-refresh focus instead of Mind D1',
);
assert(
  alternativeSection.indexOf('id="balanceHeaderScaleLab"') > alternativeSection.indexOf('aria-label="Alternatív design app menük"') &&
    alternativeSection.indexOf('id="balanceHeaderScaleLab"') < alternativeSection.indexOf('id="alternativePalette"'),
  'The balance/header scale lab must be below the Spendee screens and above the Spendee palette',
);
assert(
  /\.balance-header-scale-lab[\s\S]*?\.reactive-scale-track \{[\s\S]*?width:\s*calc\(var\(--screen-w\) \* 1\);[\s\S]*?height:\s*24px;/.test(
    html,
  ),
  'The scoped mode scale mockups must draw compact 1x-screen-width, 24px-tall tracks',
);
const balanceScaleLab = alternativeSection.match(
  /<section class="[^"]*balance-header-scale-lab[^"]*" id="balanceHeaderScaleLab"[\s\S]*?<\/section>/,
)?.[0];
const budgetScaleLab = alternativeSection.match(
  /<section class="[^"]*balance-header-scale-lab[^"]*" id="budgetHeaderScaleLab"[\s\S]*?<\/section>/,
)?.[0];
const mindScaleLab = alternativeSection.match(
  /<section class="[^"]*balance-header-scale-lab[^"]*" id="mindHeaderScaleLab"[\s\S]*?<\/section>/,
)?.[0];
assert(balanceScaleLab && budgetScaleLab && mindScaleLab, 'Missing scoped balance/budget/mind scale lab blocks before the Spendee palette');
const allModeScaleLabs = `${balanceScaleLab}\n${budgetScaleLab}\n${mindScaleLab}`;
for (let slot = 1; slot <= 10; slot += 1) {
  assert(
    mindScaleLab.includes(`data-balance-scale-slot="${slot}"`) &&
      mindScaleLab.includes(`--balance-scale-stop-${slot}`),
    `Mind mode scale must render dedicated red-to-green stop ${slot}`,
  );
  assert(
    balanceScaleLab.includes(`data-limits-scale-slot="${slot}"`) &&
      balanceScaleLab.includes(`--limits-scale-stop-${slot}`),
    `Balance mode scale must render dedicated purple-to-pink stop ${slot}`,
  );
  assert(
    budgetScaleLab.includes(`data-cool-scale-slot="${slot}"`) &&
      budgetScaleLab.includes(`--cool-scale-stop-${slot}`),
    `Budget mode scale must render dedicated white-cyan-blue stop ${slot}`,
  );
}
assert.strictEqual(
  (mindScaleLab.match(/data-balance-scale-slot="/g) || []).length,
  10,
  'Mind mode scale must render exactly 10 red-green color segments',
);
assert.strictEqual(
  (balanceScaleLab.match(/data-limits-scale-slot="/g) || []).length,
  10,
  'Balance mode scale must render exactly 10 purple/pink color segments',
);
assert.strictEqual(
  (budgetScaleLab.match(/data-cool-scale-slot="/g) || []).length,
  10,
  'Budget mode scale must render exactly 10 white-cyan-blue color segments',
);
assert.strictEqual(
  (allModeScaleLabs.match(/data-mode-opacity-scale-track/g) || []).length,
  3,
  'Each common-header focus mode must render one scoped opacity slider under its color slider',
);
assert.strictEqual(
  (allModeScaleLabs.match(/data-mode-opacity-scale-slot="/g) || []).length,
  30,
  'The three common-header opacity sliders must each render the 10-stop opacity scale',
);
assert(
  balanceScaleLab.includes('data-limits-scale-track') &&
    !balanceScaleLab.includes('data-balance-scale-track') &&
    !balanceScaleLab.includes('data-cool-scale-track') &&
    budgetScaleLab.includes('data-cool-scale-track') &&
    !budgetScaleLab.includes('data-limits-scale-track') &&
    !budgetScaleLab.includes('data-balance-scale-track') &&
    mindScaleLab.includes('data-balance-scale-track') &&
    !mindScaleLab.includes('data-limits-scale-track') &&
    !mindScaleLab.includes('data-cool-scale-track'),
  'Each common-header mode must expose exactly one dedicated slider: balance=purple/pink, budget=white/blue, mind=red/green',
);
assert.strictEqual(
  (allModeScaleLabs.match(/data-center-input/g) || []).length,
  0,
  'Colored scales must not expose numeric center-position inputs; center/window position is drag-only',
);
assert.strictEqual(
  (allModeScaleLabs.match(/data-window-width-input/g) || []).length,
  3,
  'The balance, limits, and white-cyan-dark-blue window scales must expose numeric window-width inputs',
);
assert(
  !allModeScaleLabs.includes('id="balanceCenterInput"') &&
    !allModeScaleLabs.includes('id="limitsCenterInput"') &&
    !allModeScaleLabs.includes('id="coolCenterInput"') &&
    /id="balanceWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="100"[\s\S]*?step="1"/.test(mindScaleLab) &&
    /id="limitsWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="100"[\s\S]*?step="1"/.test(balanceScaleLab) &&
    /id="coolWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="100"[\s\S]*?step="1"/.test(budgetScaleLab) &&
    !allModeScaleLabs.includes('id="opacityWindowInput"'),
  'Scoped colored scales keep clamped numeric width fields only; center fields are removed and opacity has no window-width input',
);
assert(
  !allModeScaleLabs.includes('data-opacity-window') &&
    balanceScaleLab.includes('data-mode-opacity-scale-track') &&
    budgetScaleLab.includes('data-mode-opacity-scale-track') &&
    mindScaleLab.includes('data-mode-opacity-scale-track'),
  'The three common-header mode labs must contain scoped opacity sliders with a single handle and no opacity window',
);
assert(
  !allModeScaleLabs.includes('balance-window-label') &&
    !/<span class="balance-window-label">(?:header|limits|opacity) window<\/span>/.test(allModeScaleLabs),
  'Compact slider windows must not contain internal text labels',
);
assert(
  (allModeScaleLabs.match(/data-window-drag-handle/g) || []).length === 3 &&
    !allModeScaleLabs.includes('data-longpress-resize') &&
    !allModeScaleLabs.includes('balance-window-handle') &&
    !allModeScaleLabs.includes('balance-window-center'),
  'Colored scale windows must expose one draggable window body each and no edge/center resize handles',
);
assert(
  !allModeScaleLabs.includes('<h3>') &&
    !allModeScaleLabs.includes('<p>') &&
    !allModeScaleLabs.includes('balance-scale-readout') &&
    !allModeScaleLabs.includes('Center 50%') &&
    !allModeScaleLabs.includes('window %') &&
    !allModeScaleLabs.includes('WINDOW %') &&
    !allModeScaleLabs.includes('Balance →') &&
    !allModeScaleLabs.includes('Limits →') &&
    !allModeScaleLabs.includes('Opacity →'),
  'Reactive scale lab must remove visible title, description, readout and WINDOW text so it does not occupy app viewport space',
);
assert(
  /\.balance-scale-copy \{[\s\S]*?width:\s*calc\(var\(--screen-w\) \* 1\);[\s\S]*?margin-bottom:\s*3px;/.test(html) &&
    /\.balance-window \{[\s\S]*?top:\s*2px;[\s\S]*?bottom:\s*2px;[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.92\);[\s\S]*?cursor:\s*grab;[\s\S]*?touch-action:\s*none;/.test(html) &&
    /\.scale-window-input \{[\s\S]*?width:\s*54px;/.test(html) &&
    !html.includes('.scale-center-input'),
  'Compact 24px scale tracks must keep draggable windows and compact width-only numeric inputs',
);
assert(
  html.includes('--balance-scale-stop-9: #15bd6f') &&
    html.includes('--balance-scale-stop-10: #0b8f54') &&
    /const balanceScaleStops = \[[\s\S]*?'#15bd6f',[\s\S]*?'#0b8f54'/.test(html),
  'The green balance scale endpoint must be darker/more saturated than the previous green stop',
);
assert(
  html.includes('--limits-scale-stop-1: #6d28d9') &&
    html.includes('--limits-scale-stop-2: #8b5cf6') &&
    html.includes('--limits-scale-stop-4: #d8b4fe') &&
    html.includes('--limits-scale-stop-5: #fbcfe8') &&
    html.includes('--limits-scale-stop-10: #db2777') &&
    !html.includes('--limits-scale-stop-1: #4c1d95') &&
    !html.includes('--limits-scale-stop-10: #e11d48') &&
    /const limitsScaleStops = \[[\s\S]*?'#6d28d9',[\s\S]*?'#8b5cf6',[\s\S]*?'#a78bfa',[\s\S]*?'#d8b4fe',[\s\S]*?'#fbcfe8',[\s\S]*?'#f9a8d4',[\s\S]*?'#f472b6',[\s\S]*?'#ec4899',[\s\S]*?'#e23883',[\s\S]*?'#db2777'/.test(html),
  'Limits scale must discard the previous extremes and rescale 10 stops between the old stop 2 and old stop 9 range',
);
assert(
  html.includes('--cool-scale-stop-1: #ffffff') &&
    html.includes('--cool-scale-stop-5: #22d3ee') &&
    html.includes('--cool-scale-stop-7: #0284c7') &&
    html.includes('--cool-scale-stop-8: #0057d9') &&
    html.includes('--cool-scale-stop-9: #0030a8') &&
    html.includes('--cool-scale-stop-10: #00135f') &&
    !html.includes('--cool-scale-stop-8: #0369a1') &&
    !html.includes('--cool-scale-stop-9: #0f3d6e') &&
    !html.includes('--cool-scale-stop-10: #0b1f3a') &&
    /const coolScaleStops = \[[\s\S]*?'#ffffff',[\s\S]*?'#e6fbff',[\s\S]*?'#bdf5ff',[\s\S]*?'#75e6ff',[\s\S]*?'#22d3ee',[\s\S]*?'#06b6d4',[\s\S]*?'#0284c7',[\s\S]*?'#0057d9',[\s\S]*?'#0030a8',[\s\S]*?'#00135f'/.test(html),
  'White-cyan-dark-blue scale must keep stops 1-7 and replace the grayish tail with saturated dark blues',
);
const coolScaleTrack = budgetScaleLab.match(
  /<div class="balance-scale-track reactive-scale-track cool-scale-track"[\s\S]*?data-cool-scale-track[\s\S]*?data-scale-kind="cool"[\s\S]*?<\/div>\s*<\/div>/,
)?.[0];
assert(coolScaleTrack, 'White-cyan-dark-blue scale track must be rendered under the existing sliders');
assert.strictEqual(
  (coolScaleTrack.match(/data-cool-scale-slot=/g) || []).length,
  10,
  'White-cyan-dark-blue scale must render 10 visible numbered slots',
);
assert(
  /function initReactiveScaleController\(state, track\) \{[\s\S]*?const windowHandle = track\.querySelector\('\[data-window-drag-handle\]'\);/.test(html) &&
    /function initReactiveScaleController\(state, track\) \{[\s\S]*?const windowInput = document\.getElementById\(state\.inputId\);[\s\S]*?bindDeferredWindowNumberInput\(windowInput[\s\S]*?setReactiveScaleState\(state, state\.center, boundedWindow\);/.test(html) &&
    /function initReactiveScaleController\(state, track\) \{[\s\S]*?windowHandle\.addEventListener\('pointerdown'/.test(html),
  'Reactive colored scale controller must initialize draggable window bodies plus deferred numeric width inputs',
);
assert(
  /function initBalanceHeaderScaleLab\(\) \{[\s\S]*?getElementById\('balanceHeaderScaleLab'\)[\s\S]*?getElementById\('budgetHeaderScaleLab'\)[\s\S]*?getElementById\('mindHeaderScaleLab'\)[\s\S]*?initReactiveScaleController\(limitsScaleState, limitsTrack\);[\s\S]*?initReactiveScaleController\(coolScaleState, coolTrack\);[\s\S]*?initReactiveScaleController\(balanceScaleState, balanceTrack\);/.test(
    html,
  ),
  'Mode scale lab init must wire balance mode to limits, budget mode to cool, and mind mode to red/green balance',
);
assert(
  /function initBalanceHeaderScaleLab\(\) \{[\s\S]*?initModeOpacityScaleController\(commonHeaderOpacityStates\.balance[\s\S]*?initModeOpacityScaleController\(commonHeaderOpacityStates\.budget[\s\S]*?initModeOpacityScaleController\(commonHeaderOpacityStates\.mind/.test(
    html,
  ),
  'Mode scale lab init must wire a separate scoped opacity slider for balance, budget, and mind modes',
);
assert(
  /function updateBalanceHeaderFromScale\(\) \{[\s\S]*?applyCommonHeaderModeGradient\('mind', headerGradient\)/.test(
    html,
  ),
  'Red/green balance scale updates must live-write only the mind-mode header gradient and matching glow',
);
assert(
  /function updateBalanceHeaderFromScale\(\) \{[\s\S]*?const centerColor = sampleBalanceScaleColor[\s\S]*?updateSpendeeBalanceInk\(\)/.test(
    html,
  ),
  'Balance/header scale must refresh the fixed dark balance ink without color-switching',
);
assert(
  /function updateLimitsScalePreview\(\) \{[\s\S]*?--limits-window-gradient[\s\S]*?applyCommonHeaderModeGradient\('balance', limitsGradient\)/.test(
    html,
  ),
  'Limits scale must live-write only the balance-mode header gradient/glow when the purple/pink slider is dragged',
);
assert(
  /function updateLimitsScalePreview\(\) \{[\s\S]*?const centerColor = sampleLimitsScaleColor[\s\S]*?updateSpendeeBalanceInk\(\)/.test(
    html,
  ),
  'Limits scale must refresh the fixed dark balance ink without color-switching',
);
assert(
  /const coolScaleState = \{[\s\S]*?kind:\s*'cool'[\s\S]*?cssPrefix:\s*'cool'[\s\S]*?inputId:\s*'coolWindowInput'[\s\S]*?onUpdate:\s*updateCoolHeaderFromScale/.test(
    html,
  ) &&
    /function updateCoolHeaderFromScale\(\) \{[\s\S]*?const centerColor = sampleCoolScaleColor[\s\S]*?applyCommonHeaderModeGradient\('budget', coolGradient\)[\s\S]*?updateSpendeeBalanceInk\(\)/.test(
      html,
    ),
  'White-cyan-dark-blue scale must live-write only the budget-mode header gradient/glow through the same reactive path as the other colored scales',
);
assert(
  /function sampleOpacityScaleValue\(position\) \{[\s\S]*?return sampleScaleValue\(opacityScaleStops, position\);[\s\S]*?\}/.test(
    html,
  ) &&
    /function applyCommonHeaderModeOpacity\(mode,\s*opacity\) \{[\s\S]*?data-common-header-mode[\s\S]*?--spendee-header-opacity/.test(
      html,
    ),
  'Mode opacity scales must sample their center point and live-write the scoped Spendee header opacity variable',
);
assert(
  /function setCommonHeaderModeOpacityScaleState\(state,\s*center\) \{[\s\S]*?--mode-opacity-center-pct[\s\S]*?--\$\{state\.mode\}-opacity-center-pct[\s\S]*?applyCommonHeaderModeOpacity/.test(
    html,
  ) &&
    /function initModeOpacityScaleController\(state,\s*track\) \{[\s\S]*?data-mode-opacity-handle[\s\S]*?setCommonHeaderModeOpacityScaleState\(state,\s*percentFromEvent\(event\)\);[\s\S]*?track\.addEventListener\('pointerdown'[\s\S]*?window\.addEventListener\('pointermove', onPointerMove\);/.test(
      html,
    ),
  'Mode opacity scales must use a dedicated single-handle controller that also jumps on track tap',
);
assert(
  /function initReactiveScaleController\(state, track\) \{[\s\S]*?const windowHandle = track\.querySelector\('\[data-window-drag-handle\]'\);[\s\S]*?track\.addEventListener\('pointerdown'[\s\S]*?setReactiveScaleState\(state, percentFromEvent\(event\), state\.window\);[\s\S]*?bindDeferredWindowNumberInput\(windowInput[\s\S]*?setReactiveScaleState\(state, state\.center, boundedWindow\);/.test(
    html,
  ),
  'Reactive colored scale controller must jump on track tap, drag the center/window position, and commit typed window width into the same clamped state path only after editing is finished',
);
const reactiveScaleControllerBlock = html.match(
  /function initReactiveScaleController\(state, track\) \{[\s\S]*?\n    \}/,
)?.[0];
assert(reactiveScaleControllerBlock, 'Missing draggable reactive scale controller block');
const deferredWindowInputHelperStart = html.indexOf('function bindDeferredWindowNumberInput');
const deferredWindowInputHelperEnd =
  deferredWindowInputHelperStart >= 0
    ? html.indexOf('function sampleScaleColor', deferredWindowInputHelperStart)
    : -1;
const deferredWindowInputHelperBlock =
  deferredWindowInputHelperStart >= 0 && deferredWindowInputHelperEnd > deferredWindowInputHelperStart
    ? html.slice(deferredWindowInputHelperStart, deferredWindowInputHelperEnd)
    : '';
const reactiveScaleControllerStart = html.indexOf('function initReactiveScaleController');
const reactiveScaleControllerEnd =
  reactiveScaleControllerStart >= 0
    ? html.indexOf('function initOpacityScaleController', reactiveScaleControllerStart)
    : -1;
const reactiveScaleControllerSource =
  reactiveScaleControllerStart >= 0 && reactiveScaleControllerEnd > reactiveScaleControllerStart
    ? html.slice(reactiveScaleControllerStart, reactiveScaleControllerEnd)
    : '';
assert(
  /function commitDeferredWindowNumberInput\(input, \{ min = 10, max = 100, fallback = 28 \} = \{\}\) \{[\s\S]*?rawValue === ''[\s\S]*?input\.dataset\.lastCommittedWindow[\s\S]*?clampValue\(numericValue, min, max\)[\s\S]*?input\.value = String\(Math\.round\(boundedValue\)\);[\s\S]*?return boundedValue;/.test(
    html,
  ) &&
    /function bindDeferredWindowNumberInput\(input, onCommit, options = \{\}\) \{[\s\S]*?const commit = \(\) => \{[\s\S]*?commitDeferredWindowNumberInput\(input, options\)[\s\S]*?onCommit\(boundedWindow, input\);[\s\S]*?input\.addEventListener\('keydown'[\s\S]*?event\.key !== 'Enter'[\s\S]*?event\.preventDefault\(\);[\s\S]*?commit\(\);[\s\S]*?input\.addEventListener\('change', commit\);[\s\S]*?input\.addEventListener\('blur', commit\);/.test(
      html,
    ) &&
    !deferredWindowInputHelperBlock.includes("addEventListener('input'") &&
    !reactiveScaleControllerSource.includes("windowInput.addEventListener('input'"),
  'Window-size number inputs must allow empty/draft typing and clamp only on Enter, blur, or change, not on input',
);
assert(
  /function updateSpendeeBalanceInk\(\) \{[\s\S]*?--spendee-balance-ink',\s*'#14213a'[\s\S]*?--spendee-balance-ink-shadow[\s\S]*?--spendee-balance-ink-stroke/.test(
    html,
  ),
  'Balance ink refresh must keep the amount fixed dark and only maintain the white shadow/micro-stroke support',
);
const balanceInkFunctionBlock = html.match(/function updateSpendeeBalanceInk\(\) \{[\s\S]*?\n    \}/)?.[0];
assert(balanceInkFunctionBlock, 'Missing fixed balance ink updater');
assert(
  !balanceInkFunctionBlock.includes('readableTextColor') &&
    !balanceInkFunctionBlock.includes('#f8fffd'),
  'Balance amount ink must not switch to white or use luminance-based readableTextColor anymore',
);
assert(
  reactiveScaleControllerBlock.includes("addEventListener('pointerdown'") &&
    reactiveScaleControllerBlock.includes("window.addEventListener('pointermove', onPointerMove);") &&
    !balanceScaleLab.includes('data-drag-handle="edge-left"') &&
    !balanceScaleLab.includes('data-drag-handle="edge-right"'),
  'Balance and limits colored scale windows must drag the whole window and must not expose edge resize handles',
);

const alternativeScreenNames = [
  'data-screen="alt-home"',
  'data-screen="alt-fastinfo-stage1"',
  'data-screen="alt-fastinfo-stage1-empty"',
  'data-screen="alt-fastinfo-stage2"',
  'data-screen="alt-backheader"',
  'data-screen="alt-backheader-expanded"',
  'data-screen="alt-backheader-limit-edit-keyboard"',
  'data-screen="alt-category-sheet"',
  'data-screen="alt-vendor-sheet"',
  'data-screen="alt-vendor-editor"',
  'data-screen="alt-add-transaction-sheet"',
  'data-screen="alt-icon-selector"',
];
for (const token of alternativeScreenNames) {
  assert(alternativeSection.includes(token), `Missing alternative screen token: ${token}`);
}
assert(
  alternativeSection.indexOf('data-screen="alt-home"') <
    alternativeSection.indexOf('data-screen="alt-fastinfo-stage1"') &&
    alternativeSection.indexOf('data-screen="alt-fastinfo-stage1"') <
      alternativeSection.indexOf('data-screen="alt-fastinfo-stage1-empty"') &&
    alternativeSection.indexOf('data-screen="alt-fastinfo-stage1-empty"') <
      alternativeSection.indexOf('data-screen="alt-fastinfo-stage2"') &&
    alternativeSection.indexOf('data-screen="alt-fastinfo-stage2"') <
      alternativeSection.indexOf('data-screen="alt-backheader"') &&
    alternativeSection.indexOf('data-screen="alt-backheader"') <
      alternativeSection.indexOf('data-screen="alt-backheader-expanded"') &&
    alternativeSection.indexOf('data-screen="alt-backheader-expanded"') <
      alternativeSection.indexOf('data-screen="alt-backheader-limit-edit-keyboard"') &&
    alternativeSection.indexOf('data-screen="alt-backheader-limit-edit-keyboard"') <
      alternativeSection.indexOf('data-screen="alt-category-sheet"') &&
    alternativeSection.indexOf('data-screen="alt-category-sheet"') <
      alternativeSection.indexOf('data-screen="alt-vendor-sheet"') &&
    alternativeSection.indexOf('data-screen="alt-vendor-sheet"') <
      alternativeSection.indexOf('data-screen="alt-vendor-editor"') &&
    alternativeSection.indexOf('data-screen="alt-vendor-editor"') <
      alternativeSection.indexOf('data-screen="alt-add-category-editor"') &&
    alternativeSection.indexOf('data-screen="alt-add-category-editor"') <
      alternativeSection.indexOf('data-screen="alt-icon-selector"') &&
    alternativeSection.indexOf('data-screen="alt-icon-selector"') <
      alternativeSection.indexOf('data-screen="alt-add-transaction-sheet"'),
  'The lower screens must be ordered as main screen row, active stage 1, no-limit stage 1, stage 2, backheader reference, higher backheader, limit amount tap-edit, category selector, vendor selector, vendor editor, add category, icon selector, then add transaction',
);
assert(
  /\.alternative-design > \.screens \{[\s\S]*?flex-direction:\s*column;/.test(html) &&
    /\.main-menu-row,\s*\n\s*\.common-header-row \{[\s\S]*?display:\s*flex;[\s\S]*?gap:\s*28px;/.test(html),
  'Main menu and common-header rows must remain real horizontal rows after removing the old stats row',
);

const commonHeaderRowStart = alternativeSection.indexOf('data-section-row="common-header-dashboard"');
const balanceHeaderScaleLabStart = alternativeSection.indexOf('id="balanceHeaderScaleLab"');
const commonHeaderRow =
  commonHeaderRowStart >= 0 && balanceHeaderScaleLabStart > commonHeaderRowStart
    ? alternativeSection.slice(commonHeaderRowStart, balanceHeaderScaleLabStart)
    : '';
assert(commonHeaderRow, 'Missing B-row common expandable dashboard header row before the balance/palette labs');
const commonHeaderModeArea = alternativeSection.slice(
  alternativeSection.indexOf('data-common-header-mode="balance"'),
  alternativeSection.indexOf('id="alternativePalette"'),
);
assert(commonHeaderModeArea, 'Missing scoped common-header mode area before the palette');
assert(
  commonHeaderModeArea.indexOf('data-common-header-mode="balance"') <
    commonHeaderModeArea.indexOf('id="balanceHeaderScaleLab"') &&
    commonHeaderModeArea.indexOf('id="balanceHeaderScaleLab"') <
      commonHeaderModeArea.indexOf('data-common-header-mode="budget"') &&
    commonHeaderModeArea.indexOf('data-common-header-mode="budget"') <
      commonHeaderModeArea.indexOf('id="budgetHeaderScaleLab"') &&
    commonHeaderModeArea.indexOf('id="budgetHeaderScaleLab"') <
      commonHeaderModeArea.indexOf('data-common-header-mode="mind"') &&
    commonHeaderModeArea.indexOf('data-common-header-mode="mind"') <
      commonHeaderModeArea.indexOf('id="mindHeaderScaleLab"'),
  'Common-header focus modes must be ordered as balance row + slider, budget row + slider, then mind row + slider; Query Menu is promoted to the first standalone row at refresh',
);
assert.strictEqual(
  (commonHeaderModeArea.match(/data-common-header-mode="(?:balance|budget|mind)"/g) || []).length,
  3,
  'Common-header mode area must render exactly three mode rows: balance, budget, and mind',
);
const queryMenuStart = commonHeaderModeArea.indexOf('data-query-menu-row');
const queryMenuEnd = commonHeaderModeArea.indexOf('data-common-header-mode="mind"', queryMenuStart);
const queryMenuBlock =
  queryMenuStart >= 0 && queryMenuEnd > queryMenuStart
    ? commonHeaderModeArea.slice(queryMenuStart, queryMenuEnd)
    : '';
assert(queryMenuBlock, 'Missing standalone Query Menu row');
const queryQ1ATitleStart = queryMenuBlock.indexOf('<div class="screen-title">Q1A · Kategória-vendor hierarchia</div>');
const queryQ1AScreenStart = queryMenuBlock.indexOf(
  'data-screen="alt-query-menu-category-vendor-hierarchy"',
);
const queryQ1AScreenEnd = queryMenuBlock.indexOf(
  'data-screen="alt-query-add-transaction-duplicate"',
  queryQ1AScreenStart,
);
const queryQ1AScreenBlock =
  queryQ1AScreenStart >= 0 && queryQ1AScreenEnd > queryQ1AScreenStart
    ? queryMenuBlock.slice(queryQ1AScreenStart, queryQ1AScreenEnd)
    : '';
const queryMenuScreenBlock = queryQ1AScreenBlock;
const queryMenuHeaderStart = queryMenuScreenBlock.indexOf('class="query-menu-head"');
const queryMenuHeaderEnd = queryMenuScreenBlock.indexOf('<div class="query-menu-scroll"', queryMenuHeaderStart);
const queryMenuHeaderBlock =
  queryMenuHeaderStart >= 0 && queryMenuHeaderEnd > queryMenuHeaderStart
    ? queryMenuScreenBlock.slice(queryMenuHeaderStart, queryMenuHeaderEnd)
    : '';
assert(
  !queryMenuBlock.includes('data-screen="alt-query-menu-fullscreen"') &&
    queryMenuBlock.includes('data-screen="alt-query-menu-category-vendor-hierarchy"') &&
    queryMenuBlock.includes('data-query-menu-mode="category-vendor-hierarchy"') &&
    queryMenuBlock.includes('data-reference="/storage/emulated/0/Pictures/Screenshots/Screenshot_20260716-084152.png"') &&
    queryMenuBlock.includes('class="query-menu-route"') &&
    queryMenuBlock.includes('class="query-menu-scroll"') &&
    !queryMenuBlock.includes('data-common-header-mode='),
  'Query Menu must be a standalone fullscreen phone screen row with Q1 deleted and Q1A category-vendor hierarchy retained, not another common-header mode clone',
);
assert.strictEqual(
  (queryMenuBlock.match(/<div class="screen-column"/g) || []).length,
  16,
  'Query Menu row must render Q1A, Q2, Q3, Q3A, nine Push screens, and Q13-Q15 after Q2A deletion',
);
const queryRowScreenOrder = [
  queryMenuBlock.indexOf('data-screen="alt-query-menu-category-vendor-hierarchy"'),
  queryMenuBlock.indexOf('data-screen="alt-query-add-transaction-duplicate"'),
  queryMenuBlock.indexOf('data-screen="alt-query-add-income-transaction"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-trigger-type"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-basics"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-amount"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-schedule"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-source"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-notification"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-fields"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-matching"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-behavior"'),
  queryMenuBlock.indexOf('data-screen="alt-recurring-push-summary"'),
  queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"'),
  queryMenuBlock.indexOf('data-screen="alt-category-wizard-icon-popup"'),
  queryMenuBlock.indexOf('data-screen="alt-category-wizard-name-popup"'),
];
assert(
  queryRowScreenOrder.every((index) => index >= 0) &&
    queryRowScreenOrder.every((index, indexInOrder, entries) =>
      indexInOrder === 0 || entries[indexInOrder - 1] < index,
    ) &&
    !queryMenuBlock.includes('Q2A ·') &&
    !queryMenuBlock.includes('data-screen="alt-query-category-route-sheet"') &&
    !queryMenuBlock.includes('data-transaction-category-route') &&
    !queryMenuBlock.includes('data-sheet-route-stack="category-picker-create"'),
  'Q2A category-route markup must be fully removed while the remaining Query row stays ordered',
);
assert(
  /\.query-menu-row > \.screen-column:has\(\[data-screen="alt-query-menu-category-vendor-hierarchy"\]\)\s*\{[\s\S]*?order:\s*-5;[\s\S]*?\}/.test(html) &&
    /\.query-menu-row > \.screen-column:has\(\[data-screen="alt-query-add-transaction-duplicate"\]\)\s*\{[\s\S]*?order:\s*-4;[\s\S]*?\}/.test(html) &&
    /\.query-menu-row > \.screen-column:has\(\[data-screen="alt-query-add-income-transaction"\]\)\s*\{[\s\S]*?order:\s*-3;[\s\S]*?\}/.test(html) &&
    /\.query-menu-row > \.screen-column:has\(\[data-screen="alt-recurring-trigger-type"\]\)\s*\{[\s\S]*?order:\s*-2;[\s\S]*?\}/.test(html) &&
    /\.query-menu-row > \.screen-column:has\(\[data-screen="alt-recurring-push-basics"\]\)\s*\{[\s\S]*?order:\s*-1;[\s\S]*?\}/.test(html),
  'The rendered Query row must place Q2 beside Q3, followed by Q3A and Q4',
);
const queryQ2ScreenStart = queryMenuBlock.indexOf(
  'data-screen="alt-query-add-transaction-duplicate"',
);
const queryQ3ScreenStart = queryMenuBlock.indexOf(
  'data-screen="alt-query-add-income-transaction"',
);
const queryQ2ScreenBlock =
  queryQ2ScreenStart >= 0 && queryQ3ScreenStart > queryQ2ScreenStart
    ? queryMenuBlock.slice(queryQ2ScreenStart, queryQ3ScreenStart)
    : '';
const queryQ3ScreenEnd = queryMenuBlock.indexOf(
  'data-screen="alt-recurring-trigger-type"',
  queryQ3ScreenStart,
);
const queryQ3ScreenBlock =
  queryQ3ScreenStart >= 0 && queryQ3ScreenEnd > queryQ3ScreenStart
    ? queryMenuBlock.slice(queryQ3ScreenStart, queryQ3ScreenEnd)
    : '';
const queryQ2InlineCategoryOptionCount =
  (queryQ2ScreenBlock.match(/data-category-inline-option="/g) || []).length;
const queryQ2InlineQ1ACategoryRowCount =
  (
    queryQ2ScreenBlock.match(
      /class="transaction-inline-category-row query-tree-parent query-category-vendor-parent(?: selected)?"/g,
    ) || []
  ).length;
assert(
  queryQ2ScreenBlock.includes('data-transaction-inline-category-picker') &&
    queryQ2ScreenBlock.includes('data-transaction-inline-category-window') &&
    queryQ2ScreenBlock.includes('data-category-inline-list') &&
    queryQ2ScreenBlock.includes('data-category-inline-visible-rows="4"') &&
    queryQ2ScreenBlock.includes('data-category-inline-total="8"') &&
    queryQ2InlineCategoryOptionCount === 8 &&
    queryQ2ScreenBlock.indexOf('data-transaction-inline-category-window') <
      queryQ2ScreenBlock.indexOf('data-category-inline-new-category') &&
    queryQ2ScreenBlock.includes('data-category-inline-new-category') &&
    queryQ2ScreenBlock.includes('data-popup-trigger="category-create-wizard"') &&
    queryQ2ScreenBlock.includes('class="recurring-profile-create transaction-inline-compact-create-category"') &&
    queryQ2ScreenBlock.includes('<span aria-hidden="true">＋</span>Új kategória') &&
    !queryQ2ScreenBlock.includes('popup wizard') &&
    !queryQ2ScreenBlock.includes('class="pill-field transaction-category-pill"') &&
    !queryQ2ScreenBlock.includes('transaction-category-chevron'),
  'Q2 expense sheet must replace the category dropdown pill with a scrollable inline category window showing eight test categories and a permanent new-category popup trigger below it',
);
assert(
  queryQ3ScreenBlock.includes('data-screen="alt-query-add-income-transaction"') &&
    queryQ3ScreenBlock.includes('data-transaction-inline-category-picker') &&
    queryQ3ScreenBlock.includes('data-category-inline-new-category') &&
    queryQ3ScreenBlock.includes('class="recurring-profile-create transaction-inline-compact-create-category"') &&
    queryQ3ScreenBlock.includes('<span aria-hidden="true">＋</span>Új kategória') &&
    !queryQ3ScreenBlock.includes('popup wizard'),
  'Q3 income sheet must use the same compact category-create action as Q2 and Q4',
);
assert(
  queryQ2InlineQ1ACategoryRowCount === 8 &&
    queryQ2ScreenBlock.includes('class="query-category-color-dot"') &&
    queryQ2ScreenBlock.includes('class="query-check selected"') &&
    !queryQ2ScreenBlock.includes('transaction-inline-category-icon') &&
    !queryQ2ScreenBlock.includes('transaction-inline-category-copy') &&
    /\.transaction-inline-category-picker\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*var\(--transaction-inline-category-gap\);[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-window\s*\{[\s\S]*?--transaction-inline-category-row-h:\s*38px;[\s\S]*?height:\s*calc\(var\(--transaction-inline-category-row-h\) \* 4\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?-webkit-overflow-scrolling:\s*touch;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-row\s*\{[\s\S]*?min-height:\s*var\(--transaction-inline-category-row-h\);[\s\S]*?border-bottom:\s*1px solid rgba\(226,232,240,\.64\);[\s\S]*?background:\s*rgba\(248,250,252,\.76\);[\s\S]*?grid-template-columns:\s*18px minmax\(0,\s*1fr\) auto 22px;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-row\.selected\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.78\);[\s\S]*?color:\s*#0f766e;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-row \.query-category-color-dot\s*\{[\s\S]*?margin:\s*0;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-new-category\s*\{[\s\S]*?min-height:\s*38px;[\s\S]*?position:\s*relative;[\s\S]*?\}/.test(html),
  'Q2 inline category picker rows must match the compact Q1A category list row size and design',
);
assert(
  queryQ2ScreenBlock.includes('data-transaction-editor-layout="inline-category-picker-v2"') &&
    queryQ2ScreenBlock.includes('class="transaction-amount-hero"') &&
    queryQ2ScreenBlock.includes('class="transaction-amount-prefix">−</span>') &&
    queryQ2ScreenBlock.includes('class="transaction-amount-value">-18 520 Ft</strong>') &&
    queryQ2ScreenBlock.includes('class="transaction-amount-helper">Tranzakció összege</span>') &&
    queryQ2ScreenBlock.includes('data-transaction-date-pill') &&
    queryQ2ScreenBlock.includes('2026.07.13') &&
    queryQ2ScreenBlock.includes('data-transaction-time-pill') &&
    queryQ2ScreenBlock.includes('19:42') &&
    !queryQ2ScreenBlock.includes('transaction-inline-summary') &&
    /\.transaction-inline-category-card\s*\{[\s\S]*?height:\s*var\(--query-inline-category-sheet-h\);[\s\S]*?\}/.test(html) &&
    /--query-inline-category-sheet-h:\s*570px;/.test(html) &&
    /\.transaction-inline-category-card \.transaction-form-redesign\s*\{[\s\S]*?--transaction-inline-category-gap:\s*10px;[\s\S]*?padding:\s*14px 20px 18px;[\s\S]*?gap:\s*var\(--transaction-inline-category-gap\);[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-picker\s*\{[\s\S]*?gap:\s*var\(--transaction-inline-category-gap\);[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-card \.transaction-sheet-footer\s*\{[\s\S]*?margin-top:\s*0;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-date-time-row\s*\{[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html),
  'Q2 inline category picker sheet must restore the original amount hero and date/time pills, use a taller Q2-only sheet, and keep the new-category-to-save gap equal to the dropdown-to-new-category gap',
);
assert(
  queryQ2ScreenBlock.includes('class="form-fields transaction-field-stack transaction-inline-field-stack"') &&
    queryQ2ScreenBlock.indexOf('class="form-fields transaction-field-stack transaction-inline-field-stack"') <
      queryQ2ScreenBlock.indexOf('data-transaction-inline-category-picker') &&
    queryQ2ScreenBlock.includes('class="pill-field transaction-name-pill"') &&
    queryQ2ScreenBlock.includes('class="field-row transaction-date-time-row transaction-inline-date-time-row"') &&
    /\.transaction-field-stack \.pill-field\s*\{[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);[\s\S]*?border-color:\s*rgba\(226,232,240,\.76\);[\s\S]*?background:\s*rgba\(255,255,255,\.88\);[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-card \.transaction-form-redesign\s*\{[\s\S]*?overflow:\s*hidden;[\s\S]*?padding:\s*14px 20px 18px;[\s\S]*?gap:\s*var\(--transaction-inline-category-gap\);[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-field-stack\s*\{[\s\S]*?margin-top:\s*0;[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-category-picker\s*\{[\s\S]*?flex:\s*0 0 auto;[\s\S]*?\}/.test(html) &&
    /\.transaction-inline-date-time-row\s*\{[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    !/\.transaction-inline-name-pill,\s*\n\s*\.transaction-inline-date-time-row \.pill-field\s*\{[\s\S]*?height:\s*42px;[\s\S]*?\}/.test(html),
  'Q2 inline picker must match Q3 sheet padding and pill field-stack colors',
);
assert(
  !queryMenuBlock.includes('data-screen="alt-query-menu-tabbed-groups"') &&
    !queryMenuBlock.includes('data-screen="alt-query-menu-top-snapshot-tabs"') &&
    !queryMenuBlock.includes('Q1B ·') &&
    !queryMenuBlock.includes('Q1C · Query mátrix') &&
    !queryMenuBlock.includes('Q1D · Query mondat builder') &&
    !queryMenuBlock.includes('data-screen="alt-query-menu-hajnal-layout"') &&
    !queryMenuBlock.includes('data-query-menu-mode="hajnal-final-layout"') &&
    !html.includes('hajnal-query-') &&
    !queryMenuBlock.includes('data-query-alternative=') &&
    !html.includes('initQueryAlternativePrototype'),
  'Old Q1 left variants, the accidental Q1B Hajnal screen, Q1C-Q1D alternative query-model screens, and their query-alt runtime must be removed',
);
assert(
  /\.query-menu-route\s*\{[\s\S]*?--query-menu-header-top:\s*var\(--spendee-header-top\);[\s\S]*?--query-menu-card-gap:\s*10px;[\s\S]*?--query-top-snapshot-h:\s*62px;[\s\S]*?--query-first-section-margin:\s*12px;[\s\S]*?--query-selector-section-gap:\s*var\(--query-menu-card-gap\);[\s\S]*?padding:\s*var\(--query-menu-header-top\) 20px 0;[\s\S]*?\}/.test(html) &&
    /\.common-header-stage0\s*\{[\s\S]*?height:\s*var\(--spendee-header-h\);[\s\S]*?\}/.test(html) &&
    /\.query-menu-head\s*\{[\s\S]*?height:\s*var\(--spendee-header-h\);[\s\S]*?\}/.test(html) &&
    queryMenuScreenBlock.includes('class="spendee-brand-lockup query-menu-brand-lockup"') &&
    queryMenuScreenBlock.includes('data-logo-source="/storage/emulated/0/spendee/Fluvi_vector.svg"') &&
    queryMenuScreenBlock.includes('class="spendee-logo spendee-logo-live-preview"') &&
    queryMenuScreenBlock.indexOf('class="spendee-brand-lockup query-menu-brand-lockup"') < queryMenuScreenBlock.indexOf('class="query-menu-head"') &&
    /<button class="query-top-snapshot-add" type="button" data-query-top-snapshot-add aria-label="Új snapshot fül hozzáadása">Új snapshot<\/button>/.test(queryMenuScreenBlock),
  'Q1A header must use the C1/common-header stage0 top and height, render the Fluvi logo above the header, and label the snapshot add button with visible copy',
);
assert(
  !queryMenuBlock.includes('data-screen="alt-query-menu-fullscreen"') &&
    queryQ1AScreenBlock.includes('data-screen="alt-query-menu-category-vendor-hierarchy"') &&
    queryQ1AScreenBlock.includes('data-query-menu-mode="category-vendor-hierarchy"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-container') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tabs') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tab="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tab="snapshot-2026-02-home"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-load="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-load="snapshot-2026-02-home"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-active="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-active="snapshot-2026-02-home"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-add') &&
    queryMenuScreenBlock.includes('data-query-snapshot-threshold="5000"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-threshold="12000"') &&
    queryMenuScreenBlock.indexOf('class="query-menu-head"') <
      queryMenuScreenBlock.indexOf('data-query-top-snapshot-container') &&
    queryMenuScreenBlock.indexOf('data-query-top-snapshot-container') <
      queryMenuScreenBlock.indexOf('<div class="query-menu-scroll"') &&
    !queryMenuScreenBlock.includes('data-query-section="filter-groups"') &&
    !queryMenuScreenBlock.includes('data-query-section-head-row="filter-groups"') &&
    queryMenuScreenBlock.includes('2025 Jan') &&
    queryMenuScreenBlock.includes('2026 Feb'),
  'Q1 must be deleted while Q1A keeps saved snapshot tabs directly under the header, not inside a filter-group section',
);
assert(
  /\.query-menu-route\s*\{[\s\S]*?--query-menu-header-top:\s*var\(--spendee-header-top\);[\s\S]*?--query-menu-card-gap:\s*10px;[\s\S]*?--query-top-snapshot-h:\s*62px;[\s\S]*?--query-first-section-margin:\s*12px;[\s\S]*?--query-selector-section-gap:\s*var\(--query-menu-card-gap\);[\s\S]*?padding:\s*var\(--query-menu-header-top\) 20px 0;[\s\S]*?\}/.test(
    html,
  ) &&
    /\.query-top-snapshot-container\s*\{[\s\S]*?top:\s*calc\(var\(--query-menu-header-top\) \+ var\(--spendee-header-h\) \+ var\(--query-menu-card-gap\)\);[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-menu-route\[data-query-top-snapshot-route\] \.query-menu-scroll\s*\{[\s\S]*?top:\s*calc\(var\(--query-menu-header-top\) \+ var\(--spendee-header-h\) \+ var\(--query-menu-card-gap\) \+ var\(--query-top-snapshot-h\) \+ var\(--query-selector-section-gap\) - var\(--query-first-section-margin\)\);[\s\S]*?\}/.test(
      html,
    ),
  'Q1A top snapshot spacing must move the header/selector pair lower while making selector-to-Időszak padding equal the header-to-selector gap',
);
assert(
  queryQ1AScreenBlock.includes('data-screen="alt-query-menu-category-vendor-hierarchy"') &&
    queryQ1ATitleStart >= 0 &&
    queryQ1ATitleStart < queryQ1AScreenStart &&
    queryQ1AScreenBlock.includes('data-query-menu-mode="category-vendor-hierarchy"') &&
    queryQ1AScreenBlock.includes('data-query-top-snapshot-container') &&
    queryQ1AScreenBlock.includes('data-query-section="category-vendors"') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-tree') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-category="food"') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-category-toggle="food"') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-vendor="mcdonalds"') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-category="home"') &&
    queryQ1AScreenBlock.includes('data-query-category-vendor-vendor="digi"') &&
    queryQ1AScreenBlock.includes('data-query-list-search="category-vendor"') &&
    !queryQ1AScreenBlock.includes('data-query-section="categories"') &&
    !queryQ1AScreenBlock.includes('data-query-section="vendors"') &&
    /<button class="query-tree-parent query-category-vendor-parent[^"]*"[^>]*data-query-category-vendor-category="food"[^>]*data-query-category-vendor-category-toggle="food"[\s\S]*?<span class="query-category-color-dot"[\s\S]*?<strong>Élelmiszer<\/strong><em>1\/3<\/em><span class="query-check mixed">−<\/span><\/button>/.test(
      queryQ1AScreenBlock,
    ),
  'Q1A must remain as a top-tab screen with a category-parent/vendor-child hierarchy and no separate category/vendor sections',
);
assert(
  queryMenuBlock.includes('data-query-adjacent-duplicate="a5-add-transaction"') &&
    queryMenuBlock.includes('data-source-screen="alt-add-transaction-sheet"') &&
    queryMenuBlock.includes('data-transaction-editor-layout="inline-category-picker-v2"') &&
    queryMenuBlock.includes('Tranzakció hozzáadása') &&
    !queryMenuBlock.includes('data-query-adjacent-duplicate="a6-add-recurring"') &&
    !queryMenuBlock.includes('data-query-adjacent-duplicate="a7-add-recurring-push"') &&
    !queryMenuBlock.includes('data-screen="alt-query-add-recurring-duplicate"') &&
    !queryMenuBlock.includes('data-screen="alt-query-add-recurring-push-duplicate"'),
  'Query Menu row must keep the A5 duplicate as the inline category picker sheet and remove the old Q3/Q4 A6/A7 recurring duplicates',
);
const queryIncomeStart = queryMenuBlock.indexOf('Q3 · Bevételi tranzakció sheet');
const recurringWizardStart = queryMenuBlock.indexOf('data-screen="alt-recurring-trigger-type"');
const queryIncomeBlock =
  queryIncomeStart >= 0 && recurringWizardStart > queryIncomeStart
    ? queryMenuBlock.slice(queryIncomeStart, recurringWizardStart)
    : '';
const queryIncomeInlineCategoryOptionCount =
  (queryIncomeBlock.match(/data-income-category-inline-option="/g) || []).length;
const queryIncomeInlineQ1ACategoryRowCount =
  (
    queryIncomeBlock.match(
      /class="transaction-inline-category-row query-tree-parent query-category-vendor-parent(?: selected)?"/g,
    ) || []
  ).length;
assert(
  queryIncomeBlock.includes('Q3 · Bevételi tranzakció sheet') &&
    queryIncomeBlock.includes('data-transaction-kind="income"') &&
    queryIncomeBlock.includes('data-query-adjacent-sheet="q2-income-mirror"') &&
    queryIncomeBlock.includes('class="add-transaction-card add-transaction-card-redesign add-income-transaction-card transaction-inline-category-card"') &&
    queryIncomeBlock.includes('data-transaction-editor-layout="inline-category-picker-v2"') &&
    queryIncomeBlock.includes('Új bevétel') &&
    queryIncomeBlock.includes('+320 000 Ft') &&
    queryIncomeBlock.includes('Fizetés / tranzakció neve') &&
    queryIncomeBlock.includes('Munkabér') &&
    queryIncomeBlock.includes('data-transaction-date-pill') &&
    queryIncomeBlock.includes('2026.07.13') &&
    queryIncomeBlock.includes('data-transaction-time-pill') &&
    queryIncomeBlock.includes('08:15') &&
    queryIncomeBlock.includes('Bevétel hozzáadása') &&
    queryIncomeBlock.includes('data-transaction-inline-category-picker') &&
    queryIncomeBlock.includes('data-transaction-inline-category-window') &&
    queryIncomeBlock.includes('data-category-inline-list') &&
    queryIncomeBlock.includes('data-category-inline-visible-rows="4"') &&
    queryIncomeBlock.includes('data-category-inline-total="8"') &&
    queryIncomeInlineCategoryOptionCount === 8 &&
    queryIncomeInlineQ1ACategoryRowCount === 8 &&
    queryIncomeBlock.indexOf('data-transaction-inline-category-window') <
      queryIncomeBlock.indexOf('data-category-inline-new-category') &&
    queryIncomeBlock.includes('data-category-inline-new-category') &&
    queryIncomeBlock.includes('data-popup-trigger="category-create-wizard"') &&
    queryIncomeBlock.includes('Új kategória') &&
    queryIncomeBlock.includes('Bónusz') &&
    queryIncomeBlock.includes('Visszatérítés') &&
    !queryIncomeBlock.includes('class="pill-field transaction-category-pill"') &&
    !queryIncomeBlock.includes('transaction-category-chevron'),
  'Q3 must mirror Q2 inline category picker layout while retaining positive income copy, categories, and CTA styling',
);
const triggerTypeScreenStart = queryMenuBlock.indexOf(
  '<div class="screen-title">Q3A · Recurring wizard · Trigger típusa</div>',
);
const triggerTypeScreenEnd = queryMenuBlock.indexOf(
  'data-screen="alt-recurring-push-basics"',
  triggerTypeScreenStart,
);
const triggerTypeScreenBlock =
  triggerTypeScreenStart >= 0 && triggerTypeScreenEnd > triggerTypeScreenStart
    ? queryMenuBlock.slice(triggerTypeScreenStart, triggerTypeScreenEnd)
    : '';
assert(
  triggerTypeScreenBlock.includes('data-screen="alt-recurring-trigger-type"') &&
    triggerTypeScreenBlock.includes('data-recurring-wizard-screen="trigger-type"') &&
    triggerTypeScreenBlock.includes('data-recurring-trigger-step="0"') &&
    triggerTypeScreenBlock.includes('data-recurring-wizard-size="q2-inline-sheet"') &&
    (triggerTypeScreenBlock.match(/class="recurring-wizard-sheet"/g) || []).length === 1 &&
    !triggerTypeScreenBlock.includes('data-recurring-trigger-progress') &&
    !triggerTypeScreenBlock.includes('class="recurring-wizard-progress"') &&
    !triggerTypeScreenBlock.includes('0. lépés a 9-ből') &&
    triggerTypeScreenBlock.includes('data-recurring-wizard-choice-group') &&
    !triggerTypeScreenBlock.includes('class="recurring-wizard-card') &&
    triggerTypeScreenBlock.includes('class="recurring-trigger-selector-body"') &&
    !triggerTypeScreenBlock.includes('class="recurring-wizard-nav"') &&
    !triggerTypeScreenBlock.includes('class="recurring-wizard-scroll"') &&
    !triggerTypeScreenBlock.includes('recurring-wizard-footer') &&
    !triggerTypeScreenBlock.includes('Tovább') &&
    triggerTypeScreenBlock.includes('Hogyan teljesüljön a visszatérő tranzakció?') &&
    triggerTypeScreenBlock.includes('Válaszd ki, mi indítsa el a tranzakció létrejöttét.') &&
    /<button class="recurring-trigger-legend recurring-trigger-legend-push selected"[^>]*data-recurring-wizard-selectable[^>]*aria-pressed="true">[\s\S]*?class="recurring-trigger-legend-icon"[\s\S]*?<strong>Push alapú<\/strong>/.test(
      triggerTypeScreenBlock,
    ) &&
    /<button class="recurring-trigger-legend recurring-trigger-legend-time"[^>]*data-recurring-wizard-selectable[^>]*aria-pressed="false">[\s\S]*?class="recurring-trigger-legend-icon"[\s\S]*?<strong>Idő alapú<\/strong>/.test(
      triggerTypeScreenBlock,
    ) &&
    triggerTypeScreenBlock.includes('class="recurring-trigger-legend-badge">Népszerű</em>') &&
    (triggerTypeScreenBlock.match(/class="recurring-trigger-legend-chevron"/g) || []).length === 2 &&
    triggerTypeScreenBlock.includes('class="recurring-trigger-selector-tip"') &&
    triggerTypeScreenBlock.includes('Mikor melyiket érdemes használni?') &&
    triggerTypeScreenBlock.includes('Push alapú: banki értesítés, számlakivonat, levonás') &&
    triggerTypeScreenBlock.includes('Idő alapú: előfizetés, bérlet, rendszeres díjak') &&
    /\.recurring-trigger-selector-body\s*\{[\s\S]*?top:\s*42px;[\s\S]*?bottom:\s*0;[\s\S]*?overflow:\s*hidden;[\s\S]*?}/.test(html) &&
    /\.recurring-trigger-legend-list\s*\{[\s\S]*?gap:\s*20px;[\s\S]*?margin:\s*auto 0;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-legend\s*\{[\s\S]*?min-height:\s*112px;[\s\S]*?justify-content:\s*flex-start;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-legend-icon\s*\{[\s\S]*?width:\s*54px;[\s\S]*?height:\s*54px;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-legend-push\s*\{[\s\S]*?--trigger-legend-accent:\s*#06b6d4;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-legend-time\s*\{[\s\S]*?--trigger-legend-accent:\s*#8b5cf6;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-selector-tip\s*\{[\s\S]*?margin-top:\s*auto;[\s\S]*?\}/.test(html) &&
    triggerTypeScreenBlock.includes('data-recurring-wizard-selectable'),
  'Q3A must match the supplied selector-sheet reference: no nav or bottom actions, question copy, selected blue Push row with badge, purple Time row, chevrons, and a bottom tip panel',
);
const q4PushBasicsStart = queryMenuBlock.indexOf(
  '<div class="screen-title">Q4 · Push trigger · Alapadatok</div>',
);
const q4PushBasicsEnd = queryMenuBlock.indexOf(
  '<div class="screen-title">Q5 · Push trigger · Összeg beállítása</div>',
  q4PushBasicsStart,
);
const q4PushBasicsBlock =
  q4PushBasicsStart >= 0 && q4PushBasicsEnd > q4PushBasicsStart
    ? queryMenuBlock.slice(q4PushBasicsStart, q4PushBasicsEnd)
    : '';
assert(
  q4PushBasicsBlock.includes('data-screen="alt-recurring-push-basics"') &&
    (q4PushBasicsBlock.match(/class="pill-field transaction-name-pill"/g) || []).length === 1 &&
    q4PushBasicsBlock.includes('Lakbér / tranzakció neve') &&
    (q4PushBasicsBlock.match(/data-transaction-inline-category-picker/g) || []).length === 1 &&
    (q4PushBasicsBlock.match(/data-transaction-inline-category-window/g) || []).length === 1 &&
    q4PushBasicsBlock.includes('class="transaction-inline-category-window"') &&
    q4PushBasicsBlock.includes('data-category-inline-visible-rows="4"') &&
    (q4PushBasicsBlock.match(/data-category-inline-option=/g) || []).length === 8 &&
    /<button class="transaction-inline-category-row[^\"]* selected"[^>]*data-category-inline-option="home"[^>]*aria-pressed="true">/.test(
      q4PushBasicsBlock,
    ) &&
    q4PushBasicsBlock.indexOf('data-category-inline-option="home"') <
      q4PushBasicsBlock.indexOf('data-category-inline-option="food"') &&
    q4PushBasicsBlock.indexOf('data-transaction-inline-category-window') <
      q4PushBasicsBlock.indexOf('data-category-inline-new-category') &&
    q4PushBasicsBlock.includes('class="recurring-profile-create transaction-inline-compact-create-category"') &&
    q4PushBasicsBlock.includes('data-category-inline-new-category') &&
    q4PushBasicsBlock.includes('<span aria-hidden="true">＋</span>Új kategória') &&
    !q4PushBasicsBlock.includes('popup wizard') &&
    !q4PushBasicsBlock.includes('class="recurring-wizard-field"') &&
    !q4PushBasicsBlock.includes('Partner / Kedvezményezett') &&
    !q4PushBasicsBlock.includes('Megjegyzés (opcionális)') &&
    !q4PushBasicsBlock.includes('recurring-wizard-q4-category-window') &&
    !q4PushBasicsBlock.includes('recurring-wizard-q4-new-category') &&
    /\.transaction-inline-category-window\s*\{[\s\S]*?--transaction-inline-category-row-h:\s*38px;[\s\S]*?height:\s*calc\(var\(--transaction-inline-category-row-h\) \* 4\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?-webkit-overflow-scrolling:\s*touch;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.transaction-inline-compact-create-category\s*\{[\s\S]*?min-height:\s*38px;[\s\S]*?border:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?padding:\s*0;[\s\S]*?\}/.test(html) &&
    q4PushBasicsBlock.includes('data-recurring-wizard-reference="/storage/emulated/0/spendee/recurringfab.png"') &&
    q4PushBasicsBlock.includes('class="recurring-wizard-sheet transaction-inline-category-card recurring-transaction-card"') &&
    q4PushBasicsBlock.includes('class="transaction-form transaction-form-redesign"') &&
    q4PushBasicsBlock.includes('class="recurring-wizard-grabber"') &&
    q4PushBasicsBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
    q4PushBasicsBlock.includes('<h3>Push trigger</h3>') &&
    !q4PushBasicsBlock.includes('<header class="recurring-wizard-nav"><button') &&
    !q4PushBasicsBlock.includes('aria-label="bezárás"') &&
    q4PushBasicsBlock.includes('data-recurring-sheet-dismiss="slide-down"') &&
    q4PushBasicsBlock.includes('class="recurring-transaction-body"') &&
    q4PushBasicsBlock.includes('class="recurring-transaction-context"') &&
    q4PushBasicsBlock.includes('data-recurring-push-progress') &&
    q4PushBasicsBlock.includes('1. lépés a 9-ből') &&
    q4PushBasicsBlock.includes('<h3 class="recurring-wizard-title">Alapadatok</h3>') &&
    q4PushBasicsBlock.includes('Add meg, milyen tranzakciót keressen a push értesítések között.') &&
    q4PushBasicsBlock.includes('class="transaction-amount-hero recurring-trigger-hero"') &&
    q4PushBasicsBlock.includes('Új ismétlődő kiadás') &&
    q4PushBasicsBlock.includes('Push üzenet által triggerelve') &&
    !q4PushBasicsBlock.includes('Új recurring kiadás') &&
    !q4PushBasicsBlock.includes('Értesítés figyelése aktív') &&
    !q4PushBasicsBlock.includes('Várunk a következő értesítésre…') &&
    !q4PushBasicsBlock.includes('recurring-date-pill') &&
    !q4PushBasicsBlock.includes('Dátum (választható)') &&
    !q4PushBasicsBlock.includes('Válassz dátumot') &&
    q4PushBasicsBlock.includes('class="transaction-sheet-footer recurring-transaction-footer"') &&
    /<button class="recurring-wizard-back"[^>]*>Vissza<\/button>/.test(q4PushBasicsBlock) &&
    /<button class="recurring-wizard-primary"[^>]*>Tovább<\/button>/.test(q4PushBasicsBlock) &&
    !q4PushBasicsBlock.includes('class="transaction-save"') &&
    !q4PushBasicsBlock.includes('recurring-wizard-footer') &&
    /\.recurring-transaction-card\s+\.recurring-transaction-body\s*\{[\s\S]*?top:\s*62px;[\s\S]*?bottom:\s*0;[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.recurring-transaction-card\s+\.transaction-form-redesign\s*\{[\s\S]*?height:\s*100%;[\s\S]*?overflow:\s*hidden;[\s\S]*?padding:\s*0 20px 22px;[\s\S]*?\}/.test(html) &&
    /\.recurring-transaction-card\s+\.transaction-inline-category-picker\s*\{[\s\S]*?margin-top:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.recurring-trigger-hero\s*\{[\s\S]*?min-height:\s*48px;[\s\S]*?grid-template-rows:\s*auto auto;[\s\S]*?\}/.test(html) &&
    /\.recurring-transaction-card\s+\.recurring-transaction-footer\s*\{[^}]*margin-top:\s*0;[^}]*\}/s.test(html) &&
    /\.recurring-transaction-context\s+\.recurring-wizard-progress\s*\{[\s\S]*?margin:\s*3px 0 16px;[\s\S]*?\}/.test(html),
  'Q4 must use static Push-trigger chrome without header controls, a slide-down dismiss affordance, compact trigger legend, and right-aligned Vissza/Tovább footer pills',
);
assert.strictEqual(
  (html.match(/data-screen="alt-add-transaction-sheet"/g) || []).length,
  1,
  'Original A5 alt-add-transaction-sheet must remain exactly once outside the Query duplicate',
);
assert.strictEqual(
  (html.match(/data-screen="alt-add-recurring-sheet"/g) || []).length,
  1,
  'Original A6 alt-add-recurring-sheet must remain exactly once outside the Query duplicate',
);
assert.strictEqual(
  (html.match(/data-screen="alt-add-recurring-push-sheet"/g) || []).length,
  1,
  'Original A7 alt-add-recurring-push-sheet must remain exactly once outside the Query duplicate',
);
assert.strictEqual(
  (queryMenuBlock.match(/data-recurring-wizard-screen=/g) || []).length,
  10,
  'Q3A plus the recurring Push-trigger wizard must render ten side-by-side wizard sheets',
);
assert.strictEqual(
  (queryMenuBlock.match(/data-recurring-push-step="[1-9]"/g) || []).length,
  9,
  'Q4-Q12 must render exactly one Push-trigger sheet for every approved reference step',
);
assert.strictEqual(
  (queryMenuBlock.match(/data-recurring-wizard-size="q2-inline-sheet"/g) || []).length,
  10,
  'Q3A and every Push-trigger state must explicitly use the current Q2 inline-sheet geometry',
);
assert.strictEqual(
  (queryMenuBlock.match(/data-recurring-wizard-reference="\/storage\/emulated\/0\/spendee\/recurring_new\.png"/g) || []).length,
  8,
  'Q5-Q12 must continue to point directly at the approved recurring_new reference',
);
assert.strictEqual(
  (queryMenuBlock.match(/data-recurring-wizard-reference="\/storage\/emulated\/0\/spendee\/recurringfab\.png"/g) || []).length,
  1,
  'Q4 must point directly at the approved recurringfab reference',
);
assert(
  !queryMenuBlock.includes('data-recurring-push-step="0"'),
  'The trigger chooser must be a distinct pre-step, not a tenth Push-trigger step',
);
const recurringPushWizardScreens = [
  ['Q4 · Push trigger · Alapadatok', 'alt-recurring-push-basics', '1', ['1. lépés a 9-ből', 'Alapadatok', 'Add meg, milyen tranzakciót keressen a push értesítések között.', 'Új ismétlődő kiadás', 'Push üzenet által triggerelve', 'Lakbér / tranzakció neve', 'Lakás', 'Új kategória']],
  ['Q5 · Push trigger · Összeg beállítása', 'alt-recurring-push-amount', '2', ['2. LÉPÉS (9-BŐL)', 'Összeg beállítása', 'Várható összeg', 'Tartomány', '180 000 Ft', '±5 000 Ft', 'Egyezés akkor jön létre']],
  ['Q6 · Push trigger · Időzítés', 'alt-recurring-push-schedule', '3', ['3. LÉPÉS (9-BŐL)', 'Időzítés', 'Első várható dátum', '2025.08.05', 'Ismétlődés', 'Havonta', '5. napján', '−3 nap', '+5 nap']],
  ['Q7 · Push trigger · Profil kiválasztása', 'alt-recurring-push-source', '4', ['STEP 4', 'Profil kiválasztása', 'Push profilok', 'K&amp;H Mobilbank', '3 aktív minta · 5 elkapott üzenet', 'Revolut', '2 aktív minta · 1 tanítatlan üzenet', 'OTP', 'Tanításra vár · nincs még üzenet', 'Új profil létrehozása']],
  ['Q8 · Push trigger · Értesítés kiválasztása', 'alt-recurring-push-notification', '5', ['5. LÉPÉS (9-BŐL)', 'Értesítés kiválasztása', 'K&amp;H Mobilbank', 'Tanítatlan üzenetek', '180 000 Ft', 'összeget küldtél', 'Felismertek', 'Várakozás a következőre', 'Példa beillesztése']],
  ['Q9 · Push trigger · Mezők kijelölése', 'alt-recurring-push-fields', '6', ['6. LÉPÉS (9-BŐL)', 'Mezők kijelölése', '180 000 Ft', 'összeget küldtél', 'Kovács Péter', 'részére.', 'Kijelölés', 'partner (opcionális)', 'Tranzakció típusa', 'Kiadás', 'Bevétel']],
  ['Q10 · Push trigger · Egyezési szabályok', 'alt-recurring-push-matching', '7', ['7. LÉPÉS (9-BŐL)', 'Egyezési szabályok', 'Partner', 'Pontos', 'Tartalmazza', 'Tolerancia', '±5 000 Ft', 'Ghost maradjon', 'Hozzon létre normál kiadást']],
  ['Q11 · Push trigger · Összegzés', 'alt-recurring-push-behavior', '8', ['8. LÉPÉS (9-BŐL)', 'Összegzés', 'Ellenőrizd az adatokat a létrehozás előtt.', 'Trigger összefoglaló', 'K&amp;H Mobilbank', 'Egyezési szabályok']],
  ['Q12 · Push trigger · Létrehozás', 'alt-recurring-push-summary', '9', ['9. LÉPÉS (9-BŐL)', 'Létrehozás', 'Készen állunk a recurring tranzakcióra.', 'Mi fog történni?', 'A rendszer figyeli a K&amp;H Mobilbank értesítéseit', 'Létrehozás']],
];
const recurringPushScreenStarts = recurringPushWizardScreens.map(([title]) =>
  queryMenuBlock.indexOf(`<div class="screen-title">${title}</div>`),
);
assert(
  recurringPushScreenStarts.every((start) => start >= 0) &&
    recurringPushScreenStarts.every((start, index) =>
      index === 0 || recurringPushScreenStarts[index - 1] < start,
    ),
  'Q4-Q12 Push-trigger screens must be present once and in reference-step order',
);
for (const [index, [title, screenName, step, anchors]] of recurringPushWizardScreens.entries()) {
  const start = recurringPushScreenStarts[index];
  const end =
    recurringPushScreenStarts[index + 1] ??
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"');
  const screenBlock = start >= 0 && end > start ? queryMenuBlock.slice(start, end) : '';
  const progressMarkup =
    screenBlock.match(/<div class="recurring-wizard-progress"[^>]*>([\s\S]*?)<\/div>/)?.[1] ?? '';
  const usesSharedTransactionSheet = screenName === 'alt-recurring-push-basics';
  const usesProfileSelector = screenName === 'alt-recurring-push-source';
  const usesFinalReferenceLayout = [
    'alt-recurring-push-amount',
    'alt-recurring-push-schedule',
    'alt-recurring-push-notification',
    'alt-recurring-push-fields',
    'alt-recurring-push-matching',
    'alt-recurring-push-behavior',
    'alt-recurring-push-summary',
  ].includes(screenName);
  assert(
    screenBlock.includes(`data-screen="${screenName}"`) &&
      screenBlock.includes(`data-recurring-push-step="${step}"`) &&
      screenBlock.includes('data-recurring-wizard-size="q2-inline-sheet"') &&
      (screenBlock.match(/class="[^"]*\brecurring-wizard-sheet\b[^"]*"/g) || []).length === 1 &&
      (usesSharedTransactionSheet
        ? screenBlock.includes('data-recurring-push-progress') &&
          (progressMarkup.match(/<span(?: class="(?:complete|active)")?><\/span>/g) || []).length === 9 &&
          (progressMarkup.match(/<span class="complete"><\/span>/g) || []).length === 0 &&
          (progressMarkup.match(/<span class="active"><\/span>/g) || []).length === 1 &&
          screenBlock.includes('class="transaction-form transaction-form-redesign"') &&
          screenBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
          screenBlock.includes('class="recurring-transaction-body"') &&
          !screenBlock.includes('recurring-transaction-scroll')
        : usesProfileSelector
          ? !screenBlock.includes('data-recurring-push-progress')
          : usesFinalReferenceLayout
            ? screenBlock.includes('data-recurring-push-progress') &&
              (progressMarkup.match(/<span(?: class="(?:complete|active)")?><\/span>/g) || []).length === 9 &&
              (progressMarkup.match(/<span class="complete"><\/span>/g) || []).length === Number(step) - 1 &&
              (progressMarkup.match(/<span class="active"><\/span>/g) || []).length === 1 &&
              screenBlock.includes('data-recurring-reference-layout="push-final"') &&
              screenBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
              screenBlock.includes('class="recurring-transaction-context"')
          : screenBlock.includes('data-recurring-push-progress') &&
          (progressMarkup.match(/<span(?: class="(?:complete|active)")?><\/span>/g) || []).length === 9 &&
          (progressMarkup.match(/<span class="complete"><\/span>/g) || []).length === Number(step) - 1 &&
          (progressMarkup.match(/<span class="active"><\/span>/g) || []).length === 1) &&
      anchors.every((anchor) => screenBlock.includes(anchor)),
    `Missing scoped Push-trigger wizard contract for ${title}`,
  );
}
const recurringPushScreenBlocks = recurringPushScreenStarts.map((start, index) => {
  const end =
    recurringPushScreenStarts[index + 1] ??
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"');
  return start >= 0 && end > start ? queryMenuBlock.slice(start, end) : '';
});
const q7ProfileBlock = recurringPushScreenBlocks[3] ?? '';
assert(
  q7ProfileBlock.includes('class="recurring-profile-selector"') &&
    q7ProfileBlock.includes('<span class="recurring-wizard-kicker">STEP 4</span>') &&
    q7ProfileBlock.includes('<h3 class="recurring-wizard-title">Profil kiválasztása</h3>') &&
    !q7ProfileBlock.includes('Trigger forrása') &&
    !q7ProfileBlock.includes('Hogyan ismerjük fel?') &&
    !q7ProfileBlock.includes('Válassz egy elkapott értesítést') &&
    (q7ProfileBlock.match(/class="recurring-profile-divider"/g) || []).length === 3 &&
    q7ProfileBlock.includes('class="recurring-profile-list"') &&
    (q7ProfileBlock.match(/class="recurring-profile-option"/g) || []).length === 3 &&
    (q7ProfileBlock.match(/class="recurring-profile-radio"/g) || []).length === 3 &&
    q7ProfileBlock.includes('K&amp;H Mobilbank') &&
    q7ProfileBlock.includes('3 aktív minta · 5 elkapott üzenet') &&
    q7ProfileBlock.includes('Revolut') &&
    q7ProfileBlock.includes('2 aktív minta · 1 tanítatlan üzenet') &&
    q7ProfileBlock.includes('OTP') &&
    q7ProfileBlock.includes('Tanításra vár · nincs még üzenet') &&
    q7ProfileBlock.includes('class="recurring-profile-create"') &&
    q7ProfileBlock.includes('Új profil létrehozása') &&
    /\.recurring-profile-option\s*\{[\s\S]*?min-height:\s*54px;[\s\S]*?\}/.test(html) &&
    /\.recurring-profile-divider\s*\{[\s\S]*?height:\s*1px;[\s\S]*?\}/.test(html),
  'Q7 must use the supplied STEP 4 profile selector content, dividers, profile rows, and create-profile action',
);
const finalReferenceBlocks = [
  recurringPushScreenBlocks[1],
  recurringPushScreenBlocks[2],
  recurringPushScreenBlocks[4],
  recurringPushScreenBlocks[5],
  recurringPushScreenBlocks[6],
  recurringPushScreenBlocks[7],
  recurringPushScreenBlocks[8],
];
assert(
  finalReferenceBlocks.every(
    (screenBlock) =>
      screenBlock?.includes('data-recurring-reference-layout="push-final"') &&
      /class="[^"]*\brecurring-reference-wizard-scroll\b[^"]*"/.test(screenBlock) &&
      screenBlock.includes('data-recurring-push-progress') &&
      screenBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
      screenBlock.includes('class="recurring-transaction-context"'),
  ) &&
    /class="[^"]*\brecurring-reference-amount\b[^"]*"/.test(recurringPushScreenBlocks[1]) &&
    /class="[^"]*\brecurring-reference-timing\b[^"]*"/.test(recurringPushScreenBlocks[2]) &&
    /class="[^"]*\brecurring-reference-notification\b[^"]*"/.test(recurringPushScreenBlocks[4]) &&
    /class="[^"]*\brecurring-reference-fields\b[^"]*"/.test(recurringPushScreenBlocks[5]) &&
    /class="[^"]*\brecurring-reference-matching\b[^"]*"/.test(recurringPushScreenBlocks[6]) &&
    /class="[^"]*\brecurring-reference-summary\b[^"]*"/.test(recurringPushScreenBlocks[7]) &&
    /class="[^"]*\brecurring-reference-creation\b[^"]*"/.test(recurringPushScreenBlocks[8]) &&
    recurringPushScreenBlocks[8].includes('class="recurring-wizard-primary recurring-wizard-primary-create"') &&
    /\.recurring-reference-wizard-scroll\s*\{[\s\S]*?top:\s*62px;[\s\S]*?bottom:\s*72px;[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-primary-create\s*\{[\s\S]*?background:\s*#22c55e;[\s\S]*?\}/.test(html),
  'Q5, Q6, and Q8-Q12 must preserve the supplied push-final body content inside the shared Q4 Push-trigger header structure',
);
assert(
  [recurringPushScreenBlocks[0], recurringPushScreenBlocks[3]].every(
    (screenBlock) =>
      screenBlock.includes('data-recurring-sheet-dismiss="slide-down"') &&
      screenBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
      !screenBlock.includes('<header class="recurring-wizard-nav"><button') &&
      !screenBlock.includes('aria-label="vissza"') &&
      !screenBlock.includes('aria-label="bezárás"'),
  ),
  'Q4 and the explicitly specified Q7 must retain a static header without controls and reserve slide-down as the dismissal affordance',
);
assert(
  finalReferenceBlocks.every(
    (screenBlock) =>
      screenBlock.includes('data-recurring-sheet-dismiss="slide-down"') &&
      screenBlock.includes('class="recurring-wizard-nav recurring-wizard-nav-static"') &&
      !screenBlock.includes('<header class="recurring-wizard-nav"><button') &&
      !screenBlock.includes('aria-label="vissza"') &&
      !screenBlock.includes('aria-label="bezárás"'),
  ),
  'The push-final reference screens must retain Q4\'s static header while using the grabber for sheet dismissal',
);
assert(
  recurringPushScreenBlocks.slice(0, 8).every(
    (screenBlock) =>
      /<footer class="(?:transaction-sheet-footer recurring-transaction-footer|recurring-wizard-footer has-back recurring-wizard-footer-pills)">[\s\S]*?<button class="recurring-wizard-back"[^>]*>Vissza<\/button>[\s\S]*?<button class="recurring-wizard-primary"[^>]*>Tovább<\/button>[\s\S]*?<\/footer>/.test(
        screenBlock,
      ),
  ) &&
    /<footer class="recurring-wizard-footer has-back recurring-wizard-footer-pills">[\s\S]*?<button class="recurring-wizard-back"[^>]*>Vissza<\/button>[\s\S]*?<button class="recurring-wizard-primary recurring-wizard-primary-create"[^>]*>Létrehozás<\/button>[\s\S]*?<\/footer>/.test(
      recurringPushScreenBlocks[8],
    ),
  'Q4-Q11 must use right-aligned Vissza/Tovább pills, while the final reference Q12 must use Vissza/Létrehozás pills',
);
assert(
  /function initRecurringWizardDismissGesture\(\) \{[\s\S]*?\[data-recurring-sheet-dismiss="slide-down"\][\s\S]*?pointerdown[\s\S]*?pointermove[\s\S]*?pointerup[\s\S]*?\}/.test(
    html,
  ) &&
    /function initRecurringWizardDismissGesture\(\) \{[\s\S]*?recurringSheetDismissed[\s\S]*?\}/.test(html) &&
    /initRecurringWizardDismissGesture\(\);/.test(html),
  'Q4-Q12 must dismiss through the grabber slide-down gesture instead of a header cancel button',
);
assert(
  !html.includes('alt-recurring-wizard-type') &&
    !html.includes('alt-recurring-wizard-time-frequency') &&
    !html.includes('alt-recurring-wizard-time-timepoint') &&
    !html.includes('alt-recurring-wizard-time-duration') &&
    !html.includes('alt-recurring-wizard-time-review') &&
    !html.includes('alt-recurring-wizard-push-message') &&
    !html.includes('alt-recurring-wizard-push-elements') &&
    !html.includes('alt-recurring-wizard-push-selection') &&
    !html.includes('alt-recurring-wizard-push-review') &&
    !html.includes('data-recurring-wizard-branch=') &&
    !html.includes('data-recurring-type-nav') &&
    !html.includes('data-recurring-wizard-choice='),
  'The former chooser/time/push branch implementation must not remain in the prototype',
);
assert(
  /function initRecurringWizardPrototype\(\) \{[\s\S]*?data-recurring-wizard-selectable[\s\S]*?data-recurring-wizard-choice-group[\s\S]*?data-recurring-wizard-multiselect[\s\S]*?aria-pressed[\s\S]*?selected[\s\S]*?\}/.test(
    html,
  ) &&
    /initRecurringWizardPrototype\(\);/.test(html),
  'Recurring wizard selections must use isolated attribute-scoped single and multi-select behavior',
);
assert(
  /\.recurring-wizard-screen\s*\{[\s\S]*?background:\s*var\(--category-selector-bg\);[\s\S]*?\}/.test(html) &&
    /--query-inline-category-sheet-h:\s*570px;/.test(html) &&
    /\.recurring-wizard-sheet\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;[\s\S]*?bottom:\s*0;[\s\S]*?height:\s*var\(--query-inline-category-sheet-h\);[\s\S]*?border-radius:\s*26px 26px 0 0;[\s\S]*?\}/.test(html) &&
    !/\.recurring-wizard-sheet\s*\{[^}]*height:\s*var\(--query-sheet-h\);/s.test(html) &&
    !/\.recurring-wizard-sheet\s*\{[^}]*inset:\s*42px 18px 0;/s.test(html) &&
    /\.recurring-wizard-screen::after\s*\{[\s\S]*?inset:\s*0;[\s\S]*?background:\s*rgba\(0,0,0,\.28\);[\s\S]*?z-index:\s*7;[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-progress\s*\{[\s\S]*?grid-template-columns:\s*repeat\(9,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-field\s*\{[\s\S]*?min-height:\s*50px;[\s\S]*?border:\s*1px solid rgba\(226,232,240,\.76\);[\s\S]*?border-radius:\s*25px;[\s\S]*?background:\s*rgba\(255,255,255,\.88\);[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-footer\s*\{[\s\S]*?display:\s*flex;[\s\S]*?justify-content:\s*flex-end;[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-back\s*\{[\s\S]*?height:\s*40px;[\s\S]*?border-radius:\s*20px;[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-primary\s*\{[\s\S]*?height:\s*40px;[\s\S]*?border-radius:\s*20px;[\s\S]*?\}/.test(html) &&
    /\.recurring-wizard-nav-static\s*\{[\s\S]*?display:\s*flex;[\s\S]*?justify-content:\s*center;[\s\S]*?\}/.test(html),
  'Q4-Q12 must use the current 570px Q2 inline-sheet geometry, Q2-style text-input pills, nine-step progress, static headers, and right-aligned footer navigation pills',
);
assert(
  /\.add-income-transaction-card\s+\.transaction-amount-hero\s*\{[\s\S]*?background:\s*var\(--income-transaction-amount-hero-bg\);[\s\S]*?\}/.test(html) &&
    /\.add-income-transaction-card\s+\.transaction-amount-prefix\s*\{[\s\S]*?color:\s*#0f9f6e;[\s\S]*?\}/.test(html) &&
    /\.add-income-transaction-card\s+\.transaction-save\s*\{[\s\S]*?background:\s*var\(--income-transaction-save-bg\);[\s\S]*?\}/.test(html),
  'The income mirror must retain Q2 geometry while applying dedicated positive-income hero, prefix, and CTA styling',
);
assert(
  queryMenuBlock.includes('data-category-wizard-replaces="fullscreen-category-manager"') &&
    queryMenuBlock.includes('data-category-wizard-step="name"') &&
    queryMenuBlock.includes('Nevezd el') &&
    queryMenuBlock.includes('data-category-name-input') &&
    queryMenuBlock.includes('data-category-wizard-step="color"') &&
    queryMenuBlock.includes('Válassz színt') &&
    queryMenuBlock.includes('data-category-wheel-kind="color"') &&
    queryMenuBlock.includes('data-wheel-mechanic="budget-ticking-center-scale"') &&
    queryMenuBlock.includes('data-slot-logic="preserved"') &&
    queryMenuBlock.includes('data-replaces-selector="3x7-slot-color-selector"') &&
    queryMenuBlock.includes('data-category-wizard-step="icon"') &&
    queryMenuBlock.includes('Válassz ikont') &&
    queryMenuBlock.includes('data-category-wheel-kind="icon"') &&
    queryMenuBlock.includes('data-icon-scope="all-icons-carousel"') &&
    queryMenuBlock.includes('data-replaces-selector="3x7-slot-icon-selector"') &&
    queryMenuBlock.includes('data-removes-slot-icon-manager="21-user-selected-slots"'),
  'Query row must include the three-step category popup wizard replacing fullscreen category manager and 3x7 color/icon selectors',
);
const categoryColorWizardStart = queryMenuBlock.indexOf('Q13 · Category wizard · szín wheel');
const categoryIconWizardStart = queryMenuBlock.indexOf('Q14 · Category wizard · ikon wheel');
const categoryNameWizardStart = queryMenuBlock.indexOf('Q15 · Category wizard · név + preview');
const categoryColorWizardBlock =
  categoryColorWizardStart >= 0 && categoryIconWizardStart > categoryColorWizardStart
    ? queryMenuBlock.slice(categoryColorWizardStart, categoryIconWizardStart)
    : '';
const categoryIconWizardBlock =
  categoryIconWizardStart >= 0 && categoryNameWizardStart > categoryIconWizardStart
    ? queryMenuBlock.slice(categoryIconWizardStart, categoryNameWizardStart)
    : '';
const categoryNameWizardBlock =
  categoryNameWizardStart >= 0 ? queryMenuBlock.slice(categoryNameWizardStart) : '';
assert(
  categoryColorWizardBlock.includes('Q13 · Category wizard · szín wheel') &&
    categoryColorWizardBlock.includes('Válassz színt') &&
    categoryColorWizardBlock.includes('1 / 3') &&
    categoryColorWizardBlock.includes('--wizard-progress:33%'),
  'Q13 must be the first category wizard step after the recurring wizard branch screens: color wheel at 33% progress',
);
assert(
  categoryIconWizardBlock.includes('Q14 · Category wizard · ikon wheel') &&
    categoryIconWizardBlock.includes('Válassz ikont') &&
    categoryIconWizardBlock.includes('2 / 3') &&
    categoryIconWizardBlock.includes('--wizard-progress:66%'),
  'Q14 must be the second category wizard step after the recurring wizard branch screens: icon wheel at 66% progress',
);
assert(
  categoryNameWizardBlock.includes('Q15 · Category wizard · név + preview') &&
    categoryNameWizardBlock.includes('Nevezd el') &&
    categoryNameWizardBlock.includes('3 / 3') &&
    categoryNameWizardBlock.includes('--wizard-progress:100%') &&
    categoryNameWizardBlock.includes('data-category-final-preview') &&
    categoryNameWizardBlock.includes('data-category-final-preview-icon') &&
    categoryNameWizardBlock.includes('data-category-final-preview-name') &&
    categoryNameWizardBlock.includes('>Kész</button>'),
  'Q15 must be the final category-name step after the recurring wizard branch screens with a complete selected color/icon/name preview and Kész action',
);
assert(
  /\.category-wizard-screen\s*\{[\s\S]*?background:\s*var\(--category-selector-bg\);[\s\S]*?\}/.test(html) &&
    /\.category-wizard-dialog\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?border-radius:\s*30px;[\s\S]*?background:\s*rgba\(255,255,255,\s*\.9\);[\s\S]*?\}/.test(html) &&
    /\.category-wheel-track\s*\{[\s\S]*?display:\s*flex;[\s\S]*?justify-content:\s*center;[\s\S]*?\}/.test(html) &&
    /\.category-wheel-item\[data-wheel-position="center"\]\s*\{[\s\S]*?transform:\s*scale\(1\.18\);[\s\S]*?\}/.test(html) &&
    /\.category-wheel-item\[data-wheel-position="near"\]\s*\{[\s\S]*?transform:\s*scale\(\.88\);[\s\S]*?\}/.test(html) &&
    /\.category-wheel-item\[data-wheel-position="far"\]\s*\{[\s\S]*?transform:\s*scale\(\.68\);[\s\S]*?\}/.test(html),
  'Category wizard CSS must draw popup dialogs and an infinite-wheel/ticking visual with large center and smaller side items',
);
assert(
  /\.query-menu-head\s*\{[\s\S]*?height:\s*var\(--spendee-header-h\);[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);[\s\S]*?background:[\s\S]*?var\(--category-selector-bg\);[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(
    html,
  ) &&
    !queryMenuBlock.includes('class="query-menu-close"') &&
    !queryMenuBlock.includes('aria-label="Query menu bezárása"') &&
    /\.query-menu-summary\s*\{[\s\S]*?min-width:\s*0;[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-menu-summary h3\s*\{[\s\S]*?font-size:\s*23px;[\s\S]*?line-height:\s*1\.08;[\s\S]*?font-weight:\s*850;[\s\S]*?letter-spacing:\s*-\.(?:04|040)em;[\s\S]*?text-shadow:\s*var\(--spendee-balance-ink-shadow\);[\s\S]*?-webkit-text-stroke:\s*\.45px var\(--spendee-balance-ink-stroke\);[\s\S]*?paint-order:\s*stroke fill;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-preview-scope-list\s*\{[\s\S]*?display:\s*flex;[\s\S]*?flex-wrap:\s*nowrap;[\s\S]*?overflow-x:\s*auto;[\s\S]*?overflow-y:\s*hidden;[\s\S]*?scrollbar-width:\s*none;[\s\S]*?-webkit-overflow-scrolling:\s*touch;[\s\S]*?mask-image:\s*linear-gradient[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-preview-scope-list::\-webkit-scrollbar\s*\{[\s\S]*?display:\s*none;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-preview-scope-list span\s*\{[\s\S]*?flex:\s*0 0 auto;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.query-menu-scroll\s*\{[\s\S]*?top:\s*calc\(var\(--query-menu-header-top\) \+ var\(--spendee-header-h\) \+ var\(--query-menu-card-gap\)\);[\s\S]*?\}/.test(
      html,
    ) &&
    queryMenuHeaderBlock.includes('data-query-header-size="stage0"') &&
    queryMenuHeaderBlock.includes('data-query-floating-header') &&
    queryMenuHeaderBlock.includes('data-query-preview-mode="amount-scope"') &&
    queryMenuHeaderBlock.includes('-486 320 Ft') &&
    queryMenuHeaderBlock.includes('data-query-scope-list') &&
    queryMenuHeaderBlock.includes('data-query-scope-overflow="horizontal-scroll"') &&
    ['2025 Január', '2026 Február', 'Élelmiszer', 'Lakás'].every((scope) =>
      queryMenuHeaderBlock.includes(scope),
    ) &&
    !queryMenuScreenBlock.includes('query-preview-card') &&
    !queryMenuScreenBlock.includes('data-query-preview-card="stage0-header"') &&
    !queryMenuHeaderBlock.includes('query-menu-brand-logo') &&
    !queryMenuHeaderBlock.includes('spendee-logo-live-preview') &&
    !queryMenuHeaderBlock.includes('data-logo-live-preview') &&
    !queryMenuHeaderBlock.includes('Query mode') &&
    !queryMenuHeaderBlock.includes('Részletes szűrés és elemzés') &&
    !queryMenuHeaderBlock.includes('query-menu-orb') &&
    !queryMenuHeaderBlock.includes('⌕') &&
    !queryMenuHeaderBlock.includes('248 tranzakció') &&
    !queryMenuHeaderBlock.includes('<span>tranzakció</span>') &&
    !queryMenuHeaderBlock.includes('-12,4%') &&
    !queryMenuHeaderBlock.includes('vs előző hónap') &&
    !queryMenuBlock.includes('data-query-view-selector') &&
    !queryMenuBlock.includes('data-query-view=') &&
    queryMenuBlock.includes('data-query-period-picker') &&
    queryMenuBlock.includes('data-query-selected-periods="2025-01,2026-02"') &&
    queryMenuBlock.includes('data-query-period-sum-toggle') &&
    queryMenuBlock.includes('data-query-tree-dropdown="time"') &&
    !queryMenuBlock.includes('data-query-tree-trigger') &&
    !queryMenuBlock.includes('query-tree-trigger') &&
    !queryMenuBlock.includes('data-query-dropdown-open') &&
    queryMenuBlock.includes('data-query-tree-menu="time"') &&
    queryMenuBlock.includes('SUM / Összes időszak') &&
    !queryMenuBlock.includes('data-query-period-preset-selector') &&
    !queryMenuBlock.includes('data-query-period-preset=') &&
    !queryMenuBlock.includes('query-period-preset-selector') &&
    !queryMenuBlock.includes('data-query-period-selected-months') &&
    !queryMenuBlock.includes('data-query-period-preset-current') &&
    !queryMenuBlock.includes('data-query-period-year-stack') &&
    !queryMenuBlock.includes('query-period-year-block') &&
    (queryMenuScreenBlock.match(/data-query-period-item="/g) || []).length >= 8 &&
    queryMenuBlock.includes('data-query-period-year-toggle="2026"') &&
    queryMenuBlock.includes('data-query-period-year-toggle="2025"') &&
    queryMenuBlock.includes('data-query-tree-level="child"') &&
    queryMenuBlock.includes('data-query-period-item="2025-01"') &&
    queryMenuBlock.includes('data-query-period-item="2026-02"') &&
    !queryMenuBlock.includes('data-query-period-selection-list') &&
    !queryMenuScreenBlock.includes('data-query-period-remove=') &&
    queryMenuBlock.includes('data-query-selected-period') &&
    !queryMenuBlock.includes('data-query-period-summary') &&
    !queryMenuBlock.includes('query-period-summary') &&
    ['2025 Január', '2026 Február'].every((period) => queryMenuBlock.includes(period)),
  'Query Menu must use one top floating stage0-sized query-colored amount/scope header without a second preview header, icon, or slogan',
);
for (const [section, key] of [
  ['view-components', 'tabbed-view-components'],
  ['category-vendors', 'category-vendors'],
  ['refinements', 'tabbed-refinements'],
]) {
  assert(
    queryMenuBlock.includes(`data-query-section="${section}"`) &&
      queryMenuBlock.includes(`data-query-section-head-row="${key}"`) &&
      queryMenuBlock.includes(`data-query-section-head="${key}"`) &&
      queryMenuBlock.includes(`data-query-section-body="${key}"`) &&
      queryMenuBlock.includes(`data-query-collapsible="${key}"`),
    `Query Menu section ${section} must expose a one-row collapsible header and expandable body`,
  );
}
assert(
  queryMenuScreenBlock.indexOf('data-query-section="category-vendors"') <
    queryMenuScreenBlock.indexOf('data-query-section="refinements"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-container') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tabs') &&
    queryMenuScreenBlock.includes('data-query-last-loaded-group="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tab="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-tab="snapshot-2026-02-home"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-load="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-top-snapshot-active="snapshot-2025-01-food"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-periods="2025-01"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-categories="Élelmiszer"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-threshold="5000"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-amount-min="5000"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-amount-max="50000"') &&
    !queryMenuScreenBlock.includes('data-query-section="filter-groups"') &&
    !queryMenuScreenBlock.includes('data-query-saved-group-list') &&
    !queryMenuScreenBlock.includes('data-query-snapshot-detail-title') &&
    queryMenuScreenBlock.includes('2025 Jan · Élelmiszer · McDonald’s') &&
    queryMenuScreenBlock.includes('2026 Feb · Lakás · Digi'),
  'Q1A must render saved snapshot state as top tabs under the header and must not keep the old detailed filter-group snapshot section',
);
assert(
  queryMenuBlock.includes('data-query-period-picker') &&
    queryMenuBlock.includes('data-query-tree-dropdown="time"') &&
    !queryMenuBlock.includes('data-query-period-selection-list') &&
    !queryMenuBlock.includes('query-period-selected-list') &&
    queryMenuBlock.includes('data-query-tree-dropdown="category-vendors"') &&
    queryMenuBlock.includes('data-query-category-vendor-tree') &&
    queryMenuBlock.includes('data-query-list-search="category-vendor"') &&
    queryMenuBlock.indexOf('data-query-list-search="category-vendor"') < queryMenuBlock.indexOf('data-query-category-vendor-tree') &&
    queryMenuBlock.includes('data-query-category-dot') &&
    queryMenuBlock.includes('data-query-category-vendor-category-toggle="food"') &&
    queryMenuBlock.includes('data-query-category-vendor-vendor="mcdonalds"') &&
    !queryMenuBlock.includes('data-query-tree-dropdown="categories"') &&
    !queryMenuBlock.includes('data-query-tree-dropdown="vendors"') &&
    !queryMenuBlock.includes('data-query-category-list') &&
    !queryMenuBlock.includes('data-query-list-search="category"') &&
    !queryMenuBlock.includes('data-query-list-search="vendor"') &&
    !queryMenuBlock.includes('data-query-filter-all="category"') &&
    !queryMenuBlock.includes('data-query-filter-parent="category"') &&
    !queryMenuBlock.includes('cat-expense') &&
    !queryMenuBlock.includes('cat-income') &&
    !queryMenuBlock.includes('>Kiadások<') &&
    !queryMenuBlock.includes('>Bevételek<') &&
    !queryMenuBlock.includes('data-query-filter-parent="vendor"') &&
    (queryMenuBlock.includes('data-query-refinement="amount-threshold"') ||
      queryMenuBlock.includes('data-query-refinement="amount-range"')) &&
    queryMenuBlock.includes('data-query-refinement="outliers"') &&
    queryMenuBlock.includes('data-query-refinement="day-weekend"') &&
    queryMenuBlock.includes('data-query-refinement="recurring-on"') &&
    queryMenuBlock.includes('data-query-refinement="recurring-off"') &&
    !queryMenuBlock.includes('data-query-refinement="fixed"'),
  'Remaining Q1A Query Menu must combine view, category-vendor hierarchy, and the approved refinement panel in one scrollable surface with one category-vendor search pill',
);
assert(
  queryMenuBlock.includes('data-query-section-icon="time"') &&
    queryMenuBlock.includes("url('/assets/icons/lucide/chart-candlestick.svg')") &&
    queryMenuBlock.includes('data-query-section-icon="vendors"') &&
    queryMenuBlock.includes("url('/assets/icons/lucide/store.svg')") &&
    queryMenuBlock.includes('data-query-section-icon="refinements"') &&
    queryMenuBlock.includes("url('/assets/icons/lucide/wrench.svg')") &&
    !queryMenuBlock.includes('<span class="query-section-icon">▦</span>') &&
    !queryMenuBlock.includes('<span class="query-section-icon">◌</span>') &&
    !queryMenuBlock.includes('<span class="query-section-icon">⌘</span>'),
  'Query section title markers for time, category-vendor hierarchy, and refinements must use real lucide icons instead of offset glyphs',
);
assert(
  queryMenuBlock.includes('data-query-section-head-row="tabbed-view-components"') &&
    queryMenuBlock.includes('<button class="query-section-main" type="button" data-query-section-head="tabbed-view-components" aria-expanded="true">') &&
    queryMenuBlock.includes('<button class="query-section-clear" type="button" data-query-period-clear aria-label="Időszak kijelölések törlése">×</button>') &&
    queryMenuBlock.includes('data-query-section-head-row="category-vendors"') &&
    queryMenuBlock.includes('<button class="query-section-main" type="button" data-query-section-head="category-vendors" aria-expanded="true">') &&
    queryMenuBlock.includes('<button class="query-section-clear" type="button" data-query-filter-clear="vendor" aria-label="Kategória-vendor kijelölések törlése">×</button>') &&
    queryMenuBlock.includes('data-query-section-head-row="tabbed-refinements"') &&
    queryMenuBlock.includes('<button class="query-section-main" type="button" data-query-section-head="tabbed-refinements" aria-expanded="true">'),
  'Time and category-vendor section headers must own clear controls beside the expand/collapse control while refinements keep the no-clear header',
);
assert(
  /data-query-section-head-row="tabbed-view-components"[\s\S]*?<button class="query-section-main" type="button" data-query-section-head="tabbed-view-components" aria-expanded="true">[\s\S]*?<\/button>\s*<button class="query-section-clear" type="button" data-query-period-clear aria-label="Időszak kijelölések törlése">×<\/button>\s*<button class="query-section-status" type="button" data-query-section-head="tabbed-view-components" aria-expanded="true"><em data-query-selected-period>2 aktív<\/em><span class="query-section-caret">⌃<\/span><\/button>/.test(
    queryMenuBlock,
  ) &&
    /data-query-section-head-row="category-vendors"[\s\S]*?<button class="query-section-main" type="button" data-query-section-head="category-vendors" aria-expanded="true">[\s\S]*?<\/button>\s*<button class="query-section-clear" type="button" data-query-filter-clear="vendor" aria-label="Kategória-vendor kijelölések törlése">×<\/button>\s*<button class="query-section-status" type="button" data-query-section-head="category-vendors" aria-expanded="true"><em data-query-section-count="category-vendors">1 aktív<\/em><span class="query-section-caret">⌃<\/span><\/button>/.test(
      queryMenuBlock,
    ),
  'Time and category-vendor section headers must render the X clear control directly before the active-count status',
);
assert(
  queryMenuBlock.includes('data-query-period-sum-sticky') &&
    /<button class="query-tree-parent query-period-sum-row mixed"[^>]*data-query-period-sum-toggle[\s\S]*?<strong>SUM \/ Összes időszak<\/strong><em>2\/8<\/em><span class="query-check mixed">−<\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    /<button class="query-tree-parent mixed"[^>]*data-query-period-year-toggle="2026"[^>]*aria-pressed="mixed"><strong>2026<\/strong><em>1\/4<\/em><span class="query-check mixed">−<\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    /<button class="query-tree-parent mixed"[^>]*data-query-period-year-toggle="2025"[^>]*aria-pressed="mixed"><strong>2025<\/strong><em>1\/4<\/em><span class="query-check mixed">−<\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    /data-query-period-item="2025-01"[^>]*aria-pressed="true"><span>Január<\/span><span class="query-check selected">✓<\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    /data-query-period-item="2026-02"[^>]*aria-pressed="true"><span>Február<\/span><span class="query-check selected">✓<\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    /data-query-period-item="2026-03"[^>]*aria-pressed="false"><span>Március<\/span><span class="query-check"><\/span><\/button>/.test(
      queryMenuBlock,
    ) &&
    queryMenuBlock.includes('<em data-query-selected-period>2 aktív</em>') &&
    !queryMenuBlock.includes('data-query-trigger-shell="time"') &&
    queryMenuBlock.includes('data-query-period-clear') &&
    !queryMenuBlock.includes('data-query-period-summary') &&
    !queryMenuBlock.includes('query-period-summary') &&
    !queryMenuBlock.includes('data-query-period-remove') &&
    !queryMenuBlock.includes('2 hónap</em>') &&
    !queryMenuBlock.includes('2 kiválasztva') &&
    !queryMenuBlock.includes('2 hónap kiválasztva'),
  'Query time picker must use category-style right-side checkboxes for month/year rows, keep SUM sticky as the first list row, and show active-count copy',
);
assert(
  !queryMenuBlock.includes('data-query-filter-clear="category"') &&
    queryMenuBlock.includes('data-query-filter-clear="vendor"') &&
    queryMenuBlock.includes('data-query-section-head-row="category-vendors"') &&
    !queryMenuBlock.includes('data-query-trigger-shell="categories"') &&
    !queryMenuBlock.includes('data-query-tree-trigger="categories"') &&
    !queryMenuBlock.includes('data-query-tree-trigger="vendors"'),
  'Q1A category-vendor clear control must live in the section header without inner dropdown trigger pills or the deleted Q1 category clear control',
);
assert(
  queryMenuBlock.includes('data-query-category-vendor-tree') &&
    !queryMenuBlock.includes('data-query-category-all-sticky') &&
    /<button class="query-tree-parent query-category-vendor-parent[^"]*"[^>]*data-query-category-vendor-category="food"[^>]*data-query-category-vendor-category-toggle="food"[^>]*aria-pressed="mixed">[\s\S]*?<strong>Élelmiszer<\/strong><em>1\/3<\/em><span class="query-check mixed">−<\/span><\/button>/.test(
      queryMenuBlock,
    ),
  'Q1A category-vendor hierarchy must keep category parent rows as vendor-group toggles instead of the deleted Q1 category select-all row',
);
assert(
  queryMenuScreenBlock.includes('data-query-refinement-panel') &&
    queryMenuScreenBlock.includes('data-query-amount-range-editor') &&
    queryMenuScreenBlock.includes('data-query-amount-mode="threshold"') &&
    queryMenuScreenBlock.includes('data-query-refinement="amount-threshold"') &&
    queryMenuScreenBlock.includes('data-query-amount-mode-selector') &&
    queryMenuScreenBlock.includes('data-query-amount-mode-option="threshold"') &&
    queryMenuScreenBlock.includes('data-query-amount-mode-option="range"') &&
    queryMenuScreenBlock.includes('>Threshold</button>') &&
    queryMenuScreenBlock.includes('>Tól-ig</button>') &&
    queryMenuScreenBlock.includes('data-query-amount-mode-pane="threshold"') &&
    queryMenuScreenBlock.includes('data-query-amount-mode-pane="range"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-amount-mode="threshold"') &&
    queryMenuScreenBlock.includes('data-query-snapshot-refinements="amount-threshold,outliers,day-weekend,recurring-on"') &&
    queryMenuScreenBlock.includes('data-query-amount-threshold') &&
    queryMenuScreenBlock.includes('data-query-amount-threshold-slider') &&
    /<input class="query-amount-input"[^>]*data-query-amount-threshold[^>]*min="0"[^>]*max="50000"[^>]*step="500"[^>]*value="5000"/.test(
      queryMenuScreenBlock,
    ) &&
    /data-query-amount-threshold-slider[^>]*min="0"[^>]*max="50000"[^>]*step="500"[^>]*value="5000"/.test(queryMenuScreenBlock) &&
    queryMenuScreenBlock.includes('Ft felett') &&
    queryMenuScreenBlock.includes('data-query-amount-min') &&
    queryMenuScreenBlock.includes('data-query-amount-max') &&
    /<input class="query-amount-input"[^>]*data-query-amount-min[^>]*min="0"[^>]*max="50000"[^>]*step="500"[^>]*value="5000"/.test(
      queryMenuScreenBlock,
    ) &&
    /<input class="query-amount-input"[^>]*data-query-amount-max[^>]*min="0"[^>]*max="50000"[^>]*step="500"[^>]*value="50000"/.test(
      queryMenuScreenBlock,
    ) &&
    queryMenuScreenBlock.includes('data-query-amount-range-track') &&
    queryMenuScreenBlock.includes('data-query-amount-min-slider') &&
    queryMenuScreenBlock.includes('data-query-amount-max-slider') &&
    queryMenuScreenBlock.includes('data-query-refinement="outliers"') &&
    queryMenuScreenBlock.includes('Kiugró tételek') &&
    queryMenuScreenBlock.includes('data-query-refinement-segmented="day-type"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="day-any"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="day-weekday"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="day-weekend"') &&
    ['Mind', 'Hétköznap', 'Hétvége'].every((label) => queryMenuScreenBlock.includes(`>${label}</button>`)) &&
    queryMenuScreenBlock.includes('data-query-refinement-segmented="recurring"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="recurring-any"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="recurring-on"') &&
    queryMenuScreenBlock.includes('data-query-refinement-option="recurring-off"') &&
    ['Ismétlődő', 'Nem ismétlődő'].every((label) => queryMenuScreenBlock.includes(`>${label}</button>`)) &&
    !queryMenuScreenBlock.includes('data-query-threshold-editor') &&
    !queryMenuScreenBlock.includes('data-query-threshold-slider'),
  'Q1A refinements must render both threshold and min/max range amount modes, plus outliers, day type, and recurring controls',
);
assert(
  queryMenuScreenBlock.includes('data-query-refinement-condition-container') &&
    queryMenuScreenBlock.indexOf('data-query-amount-range-editor') < queryMenuScreenBlock.indexOf('data-query-refinement-condition-container') &&
    queryMenuScreenBlock.indexOf('data-query-refinement-condition-container') < queryMenuScreenBlock.indexOf('data-query-refinement="outliers"') &&
    queryMenuScreenBlock.indexOf('data-query-refinement="outliers"') < queryMenuScreenBlock.indexOf('data-query-refinement-segmented="day-type"') &&
    queryMenuScreenBlock.indexOf('data-query-refinement-segmented="day-type"') < queryMenuScreenBlock.indexOf('data-query-refinement-segmented="recurring"') &&
    /<div class="query-refinement-condition-container" data-query-refinement-condition-container>[\s\S]*?Kiugró tételek[\s\S]*?Nap típusa[\s\S]*?Ismétlődő[\s\S]*?<\/div>\s*<\/div>\s*<\/section>/.test(
      queryMenuScreenBlock,
    ),
  'Q1A must group Kiugró tételek, Nap típusa, and Ismétlődő inside one refinement condition container',
);
assert(
  !queryMenuBlock.includes('class="query-apply-bar"') &&
    !queryMenuBlock.includes('class="query-apply-pill"') &&
    queryMenuBlock.includes('class="category-selector-footer vendor-selector-footer query-selector-footer"') &&
    queryMenuBlock.includes('class="category-selector-footer-actions vendor-selector-footer-actions query-selector-footer-actions"') &&
    queryMenuBlock.includes('class="category-selector-cancel vendor-selector-cancel query-selector-cancel"') &&
    queryMenuBlock.includes('class="category-selector-apply vendor-selector-apply query-selector-apply"') &&
    queryMenuBlock.includes('5 aktív feltétel') &&
    queryMenuBlock.includes('248 találat') &&
    queryMenuBlock.includes('Cancel') &&
    queryMenuBlock.includes('OK'),
  'Query Menu must end with an A3-style sticky footer summary plus Cancel/OK actions',
);
assert(
  /\.query-menu-screen\s*\{[\s\S]*?background:\s*var\(--category-selector-bg\);[\s\S]*?\}/.test(html) &&
    /\.query-menu-route\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.query-menu-scroll\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?overflow-y:\s*auto;[\s\S]*?-webkit-overflow-scrolling:\s*touch;[\s\S]*?\}/.test(html) &&
    /\.query-section\s*\{[\s\S]*?border-radius:\s*22px;[\s\S]*?background:\s*rgba\(255,255,255,\.88\);[\s\S]*?\}/.test(html) &&
    /\.query-section-head\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) 24px auto;[\s\S]*?\}/.test(html) &&
    /\.query-section-main\s*\{[\s\S]*?grid-template-columns:\s*28px minmax\(0,\s*1fr\);[\s\S]*?\}/.test(html) &&
    /\.query-section-clear\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?\}/.test(html) &&
    /\.query-section-status\s*\{[\s\S]*?grid-template-columns:\s*auto 18px;[\s\S]*?\}/.test(html) &&
    /\.query-list-search-pill\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-group-card\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-group-add\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-saved-group-load\s*\{[\s\S]*?display:\s*grid;[\s\S]*?text-align:\s*left;[\s\S]*?\}/.test(html) &&
    /\.query-saved-group-active\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?\}/.test(html) &&
    /\.query-saved-group-detail\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-top-snapshot-container\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?border-radius:\s*22px;[\s\S]*?\}/.test(html) &&
    /\.query-menu-route\[data-query-top-snapshot-route\] \.query-menu-scroll\s*\{[\s\S]*?top:\s*calc\(var\(--query-menu-header-top\) \+ var\(--spendee-header-h\) \+ var\(--query-menu-card-gap\) \+ var\(--query-top-snapshot-h\) \+ var\(--query-selector-section-gap\) - var\(--query-first-section-margin\)\);[\s\S]*?\}/.test(html) &&
    /\.query-top-snapshot-tabs\s*\{[\s\S]*?display:\s*flex;[\s\S]*?overflow-x:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.query-top-snapshot-tab\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-top-snapshot-active\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?\}/.test(html) &&
    /\.query-top-snapshot-add\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-tabs\s*\{[\s\S]*?display:\s*flex;[\s\S]*?overflow-x:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.query-filter-tab\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-tab-remove\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-tab-add\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-filter-tab-panel\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-panel\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    /\.query-amount-range-editor\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-condition-container\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*8px;[\s\S]*?border-radius:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-condition-container :where\(\.query-refinement-toggle,\s*\.query-refinement-segment-block\)\s*\{[\s\S]*?border:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-condition-container \.query-refinement-segment-block\s*\{[\s\S]*?border-top:\s*1px solid rgba\(226,232,240,\.70\);[\s\S]*?\}/.test(html) &&
    /\.query-amount-mode-selector\s*\{[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.query-amount-mode-option\.selected\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.86\);[\s\S]*?\}/.test(html) &&
    /\.query-amount-mode-pane\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    /\.query-amount-mode-pane:not\(\.selected\)\s*\{[\s\S]*?display:\s*none;[\s\S]*?\}/.test(html) &&
    /\.query-amount-threshold-slider\s*\{[\s\S]*?width:\s*100%;[\s\S]*?accent-color:\s*#06b6d4;[\s\S]*?\}/.test(html) &&
    /\.query-amount-grid\s*\{[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.query-amount-range-track\s*\{[\s\S]*?position:\s*relative;[\s\S]*?height:\s*30px;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-toggle\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) 22px;[\s\S]*?\}/.test(html) &&
    /\.query-refinement-segmented\s*\{[\s\S]*?grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.query-refinement-option\.selected\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.86\);[\s\S]*?\}/.test(html) &&
    /\.query-period-picker\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*10px;[\s\S]*?\}/.test(html) &&
    /\.query-tree-dropdown\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    !html.includes('.query-tree-trigger') &&
    /\.query-tree-menu\s*\{[\s\S]*?max-height:\s*220px;[\s\S]*?overflow-y:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.query-period-sum-group\s*\{[\s\S]*?position:\s*sticky;[\s\S]*?top:\s*0;[\s\S]*?z-index:\s*3;[\s\S]*?\}/.test(html) &&
    /\.query-tree-parent\s*\{[\s\S]*?grid-template-columns:\s*22px minmax\(0,\s*1fr\) auto auto;[\s\S]*?\}/.test(html) &&
    /\.query-period-tree-dropdown \.query-tree-parent\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) auto auto 22px;[\s\S]*?\}/.test(html) &&
    /\.query-category-list \.query-tree-parent\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) auto auto 22px;[\s\S]*?\}/.test(html) &&
    /\.query-category-vendor-tree\s*\{[\s\S]*?display:\s*grid;[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.query-row-transaction-count\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?font-size:\s*9px;[\s\S]*?white-space:\s*nowrap;[\s\S]*?\}/.test(html) &&
    /\.query-category-vendor-parent\s*\{[\s\S]*?grid-template-columns:\s*18px minmax\(0,\s*1fr\) auto auto 22px;[\s\S]*?\}/.test(html) &&
    /\.query-period-item\.query-tree-child\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) auto 22px;[\s\S]*?\}/.test(html) &&
    /\.query-tree-child\s*\{[\s\S]*?padding-left:\s*34px;[\s\S]*?\}/.test(html) &&
    !html.includes('[data-query-dropdown-open="false"]') &&
    /\.query-period-sum-row\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.78\);[\s\S]*?\}/.test(html) &&
    /\.query-category-all-group\s*\{[\s\S]*?position:\s*sticky;[\s\S]*?top:\s*0;[\s\S]*?z-index:\s*3;[\s\S]*?\}/.test(html) &&
    /\.query-category-all-row\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.78\);[\s\S]*?\}/.test(html) &&
    /\.query-period-item\.selected\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.78\);[\s\S]*?\}/.test(html) &&
    /\.query-filter-tree-item\.selected\s*\{[\s\S]*?background:\s*rgba\(236,254,255,\.78\);[\s\S]*?border-color:\s*rgba\(226,232,240,\.48\);[\s\S]*?color:\s*#0f766e;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html) &&
    !/\.query-filter-tree-item\.selected\s*\{[^}]*background:\s*#06b6d4;[^}]*\}/.test(html) &&
    !/\.query-filter-tree-item\.selected\s*\{[^}]*color:\s*#fff;[^}]*\}/.test(html) &&
    !/\.query-period-item\.selected\s*\{[^}]*background:\s*#06b6d4;[^}]*\}/.test(html) &&
    /\.query-section-icon \.slot-icon\s*\{[\s\S]*?width:\s*var\(--icon-size,\s*16px\);[\s\S]*?height:\s*var\(--icon-size,\s*16px\);[\s\S]*?\}/.test(html) &&
    /\.query-section-copy span\s*\{[\s\S]*?margin-top:\s*5px;[\s\S]*?\}/.test(html) &&
    /\.query-category-color-dot\s*\{[\s\S]*?background:\s*var\(--category-dot-bg[\s\S]*?\}/.test(html) &&
    !html.includes('.query-period-selected-list') &&
    !html.includes('.query-period-summary') &&
    /\.query-section\[data-query-collapsed="true"\] \.query-section-body\s*\{[\s\S]*?display:\s*none;[\s\S]*?\}/.test(html) &&
    /\.query-selector-footer\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) 156px;[\s\S]*?bottom:\s*22px;[\s\S]*?\}/.test(html) &&
    /\.query-selector-footer-actions\s*\{[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    !html.includes('.query-apply-bar') &&
    !html.includes('.query-apply-pill'),
  'Query Menu CSS must create a fullscreen scrollable route with collapsible white sections and an A3-style sticky footer',
);
assert(
  /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-section-head\]'\)[\s\S]*?closest\('\[data-query-section\]'\)[\s\S]*?dataset\.queryCollapsed[\s\S]*?setAttribute\('aria-expanded'/.test(
    html,
  ) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?section\.querySelectorAll\('\[data-query-section-head\]'\)\.forEach\(\(control\) => \{[\s\S]*?control\.setAttribute\('aria-expanded'/.test(
      html,
    ) &&
    html.includes('initQueryMenuPrototype();'),
  'Query Menu section headers must toggle their expanded/collapsed state in the prototype',
);
assert(
  (queryMenuBlock.match(/data-query-selectable=/g) || []).length >= 7 &&
    (queryMenuBlock.match(/aria-pressed="/g) || []).length >= 12 &&
    queryMenuBlock.includes('data-query-active-count') &&
    !queryMenuBlock.includes('data-query-section-count="categories"') &&
    !queryMenuBlock.includes('data-query-section-count="vendors"') &&
    queryMenuBlock.includes('data-query-section-count="category-vendors"') &&
    queryMenuBlock.includes('data-query-section-count="refinements"') &&
    !queryMenuBlock.includes('data-query-filter="category"') &&
    queryMenuBlock.includes('data-query-category-vendor-category=') &&
    queryMenuBlock.includes('data-query-filter="vendor"') &&
    queryMenuBlock.includes('data-query-filter="refinement"'),
  'Remaining Q1A selectable controls must expose tappable aria-pressed state, category-vendor section counters, vendor child filters, and refinement filters',
);
assert(
  html.includes("querySelectorAll('[data-query-filter].selected')") &&
    /function syncQueryMenuSelectionSummary\(route\) \{[\s\S]*?data-query-active-count[\s\S]*?data-query-section-count/.test(
      html,
    ) &&
    /function setQuerySelectableState\(control,\s*selected\) \{[\s\S]*?aria-pressed[\s\S]*?query-check/.test(html) &&
    /function toggleQuerySelectable\(control\) \{[\s\S]*?data-query-selectable[\s\S]*?syncQueryMenuSelectionSummary/.test(html) &&
    /function parseQuerySelectedPeriods\(picker\) \{[\s\S]*?selectedPeriods/.test(html) &&
    /function getQueryPeriodLabel\(periodValue\) \{[\s\S]*?queryMonthLabels/.test(html) &&
    /function syncQueryHeaderTimeScope\(route,\s*labels\) \{[\s\S]*?data-query-scope-kind="time"/.test(
      html,
    ) &&
    /function getQueryPeriodListLabel\(selectedPeriods,\s*totalCount\) \{[\s\S]*?return `\$\{selectedPeriods\.length\} aktív`;[\s\S]*?\}/.test(html) &&
    !html.includes('function getQueryPeriodSummary') &&
    !/function getQueryHeaderPeriodLabels\(selectedPeriods,\s*totalCount\) \{[\s\S]*?Egyedi[\s\S]*?\}/.test(html) &&
    /function syncQueryPeriodPicker\(picker\) \{[\s\S]*?data-query-selected-period[\s\S]*?syncQueryHeaderTimeScope/.test(
      html,
    ) &&
    !html.includes('[data-query-period-summary]') &&
    /function syncQueryPeriodPicker\(picker\) \{[\s\S]*?button\.querySelector\('\.query-check'\)[\s\S]*?check\.textContent = selected \? '✓' : ''/.test(html) &&
    !html.includes('function toggleQueryDropdown') &&
    !html.includes('data-query-dropdown-open') &&
    !html.includes('function setQueryPeriodPreset') &&
    /function syncQueryPeriodSumRow\(picker,\s*selectedPeriods\) \{[\s\S]*?data-query-period-sum-toggle[\s\S]*?mixed/.test(html) &&
    /function toggleQueryPeriodSum\(button\) \{[\s\S]*?data-query-period-sum-toggle[\s\S]*?data-query-period-item[\s\S]*?syncQueryPeriodPicker/.test(html) &&
    /function syncQueryPeriodYearRows\(picker,\s*selectedPeriods\) \{[\s\S]*?data-query-period-year-toggle[\s\S]*?mixed/.test(
      html,
    ) &&
    /function toggleQueryPeriodYear\(button\) \{[\s\S]*?data-query-period-year-toggle[\s\S]*?data-query-period-item[\s\S]*?syncQueryPeriodPicker/.test(
      html,
    ) &&
    /function toggleQueryPeriodItem\(button\) \{[\s\S]*?data-query-period-item[\s\S]*?syncQueryPeriodPicker/.test(
      html,
    ) &&
    /function clearQueryPeriodSelection\(button\) \{[\s\S]*?closest\('\[data-query-section\]'\)[\s\S]*?querySelector\('\[data-query-period-picker\]'\)[\s\S]*?querySelectedPeriods = ''[\s\S]*?syncQueryPeriodPicker/.test(html) &&
    /function clearQueryFilterSelection\(button\) \{[\s\S]*?dataset\.queryFilterClear[\s\S]*?setQuerySelectableState\(control,\s*false\)[\s\S]*?syncQueryMenuSelectionSummary/.test(html) &&
    /function syncQueryFilterAllRows\(route\) \{[\s\S]*?data-query-filter-all[\s\S]*?updateQueryTreeParentVisual/.test(html) &&
    /function toggleQueryFilterAll\(button\) \{[\s\S]*?dataset\.queryFilterAll[\s\S]*?setQuerySelectableState\(control,\s*!allSelected\)[\s\S]*?syncQueryMenuSelectionSummary/.test(html) &&
    !html.includes('function removeQuerySelectedPeriod') &&
    !html.includes('[data-query-period-remove]') &&
    /function toggleQueryFilterTreeParent\(button\) \{[\s\S]*?data-query-filter-parent[\s\S]*?setQuerySelectableState[\s\S]*?syncQueryTreeParentStates/.test(
      html,
    ) &&
    /function syncQueryTreeParentStates\(route\) \{[\s\S]*?data-query-filter-parent[\s\S]*?mixed/.test(html) &&
    /function syncQueryCategoryVendorTree\(route\) \{[\s\S]*?data-query-category-vendor-category-toggle[\s\S]*?data-query-category-vendor-vendor[\s\S]*?updateQueryTreeParentVisual/.test(
      html,
    ) &&
    /const queryTransactionCounts = \{[\s\S]*?periods:[\s\S]*?'2026-04':\s*18[\s\S]*?categories:[\s\S]*?Élelmiszer:\s*86[\s\S]*?vendors:[\s\S]*?'McDonald’s':\s*16/.test(
      html,
    ) &&
    /function getQueryTransactionCountForRow\(row\) \{[\s\S]*?data-query-period-item[\s\S]*?data-query-period-year-toggle[\s\S]*?data-query-category-vendor-vendor[\s\S]*?return count;[\s\S]*?\}/.test(
      html,
    ) &&
    /function ensureQueryRowTransactionCounts\(route\) \{[\s\S]*?data-query-row-transaction-count[\s\S]*?tranz\.[\s\S]*?insertBefore/.test(
      html,
    ) &&
    /function toggleQueryCategoryVendorCategory\(button\) \{[\s\S]*?data-query-category-vendor-category-toggle[\s\S]*?data-query-category-vendor-vendor[\s\S]*?setQuerySelectableState[\s\S]*?syncQueryCategoryVendorTree/.test(
      html,
    ) &&
    /function syncQueryAmountRangeEditor\(editor\) \{[\s\S]*?data-query-amount-mode[\s\S]*?data-query-amount-threshold[\s\S]*?data-query-amount-threshold-slider[\s\S]*?data-query-amount-min[\s\S]*?data-query-amount-max[\s\S]*?data-query-amount-min-slider[\s\S]*?data-query-amount-max-slider[\s\S]*?syncQueryMenuSelectionSummary/.test(html) &&
    /function setQueryAmountMode\(button\) \{[\s\S]*?data-query-amount-mode-option[\s\S]*?dataset\.queryAmountMode[\s\S]*?syncQueryAmountRangeEditor/.test(html) &&
    /function setQueryRefinementSegmentedState\(group,\s*selectedOption\) \{[\s\S]*?data-query-refinement-option[\s\S]*?aria-pressed[\s\S]*?syncQueryMenuSelectionSummary/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-amount-range-editor\]'\)[\s\S]*?syncQueryAmountRangeEditor/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-amount-mode-option\]'\)[\s\S]*?setQueryAmountMode/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-refinement-option\]'\)[\s\S]*?setQueryRefinementSegmentedState/.test(html) &&
    /function selectQueryFilterGroupTab\(button\) \{[\s\S]*?data-query-filter-tab-select[\s\S]*?data-query-filter-tab-panel/.test(html) &&
    /function removeQueryFilterGroupTab\(button\) \{[\s\S]*?data-query-filter-tab-remove[\s\S]*?remove\(\)/.test(html) &&
    /function addQueryFilterGroupTab\(button\) \{[\s\S]*?data-query-filter-tab-add[\s\S]*?insertBefore/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-filter-tab-select\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-tab-remove\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-tab-add\]'\)/.test(
      html,
    ) &&
    /function applyQuerySavedGroupSnapshot\(card\) \{[\s\S]*?data-query-last-loaded-group[\s\S]*?data-query-snapshot-amount-min[\s\S]*?data-query-snapshot-amount-max[\s\S]*?syncQueryAmountRangeEditor/.test(
      html,
    ) &&
    /function loadQuerySavedGroupSnapshot\(button\) \{[\s\S]*?data-query-saved-group-load[\s\S]*?applyQuerySavedGroupSnapshot/.test(html) &&
    /function toggleQuerySavedGroupActive\(button\) \{[\s\S]*?data-query-saved-group-active[\s\S]*?applyQuerySavedGroupSnapshot/.test(html) &&
    /function addQuerySavedGroupSnapshot\(button\) \{[\s\S]*?data-query-filter-group-add[\s\S]*?data-query-saved-group-list[\s\S]*?insertBefore/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-saved-group-load\]'\)[\s\S]*?querySelectorAll\('\[data-query-saved-group-active\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-group-add\]'\)/.test(
      html,
    ) &&
    /function loadQueryTopSnapshotTab\(button\) \{[\s\S]*?data-query-top-snapshot-load[\s\S]*?applyQuerySavedGroupSnapshot/.test(html) &&
    /function toggleQueryTopSnapshotActive\(button\) \{[\s\S]*?data-query-top-snapshot-active[\s\S]*?applyQuerySavedGroupSnapshot/.test(html) &&
    /function addQueryTopSnapshotTab\(button\) \{[\s\S]*?data-query-top-snapshot-add[\s\S]*?data-query-top-snapshot-tabs[\s\S]*?insertBefore/.test(html) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-top-snapshot-load\]'\)[\s\S]*?querySelectorAll\('\[data-query-top-snapshot-active\]'\)[\s\S]*?querySelectorAll\('\[data-query-top-snapshot-add\]'\)/.test(
      html,
    ) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-category-vendor-category-toggle\]'\)[\s\S]*?toggleQueryCategoryVendorCategory/.test(
      html,
    ) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?document\.querySelectorAll\('\.query-menu-route'\)\.forEach\(\(route\) => \{[\s\S]*?ensureQueryRowTransactionCounts\(route\)[\s\S]*?syncQueryTreeParentStates/.test(
      html,
    ) &&
    /function initQueryMenuPrototype\(\) \{[\s\S]*?querySelectorAll\('\[data-query-section-head\]'\)[\s\S]*?querySelectorAll\('\[data-query-period-clear\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-clear\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-all\]'\)[\s\S]*?querySelectorAll\('\[data-query-period-sum-toggle\]'\)[\s\S]*?querySelectorAll\('\[data-query-period-year-toggle\]'\)[\s\S]*?querySelectorAll\('\[data-query-period-item\]'\)[\s\S]*?querySelectorAll\('\[data-query-filter-parent\]'\)[\s\S]*?querySelectorAll\('\[data-query-selectable\]'\)[\s\S]*?toggleQuerySelectable/.test(
      html,
    ),
  'Query Menu JS must make section expansion, parent toggles, arbitrary month chips, clear-all controls, and category/vendor tree filters tappable with summary synchronization',
);
assert(
  /function initCommonHeaderModeRows\(\) \{[\s\S]*?commonHeaderModeDefinitions[\s\S]*?budget[\s\S]*?mind[\s\S]*?createModeScaleLab\(definition\)[\s\S]*?cloneNode\(true\)/.test(html),
  'Budget and mind common-header rows must be generated from the balance source row so each mode has the same three header states',
);
assert(
  focusHeaderNote.includes('Focus mode header') &&
    focusHeaderNote.includes('Mind mode stage1') &&
    focusHeaderNote.includes('Budget mode stage1') &&
    focusHeaderNote.includes('longtap') &&
    focusHeaderNote.includes('stage2') &&
    focusHeaderNote.includes('C2 bottom-anchored budget progress') &&
    focusHeaderNote.includes('stage3 screens do not render avatar carousels'),
  'Focus mode header notes must preserve the current B/C/D instruction set outside the prototype HTML',
);
assert(
  commonHeaderModeArea.includes('data-focus-header-note="docs/superpowers/specs/2026-07-13-focus-mode-header-notes.md"'),
  'Common-header focus-mode area must link back to the separate current-app instruction note',
);
const budgetGlossyFunction = html.slice(
  html.indexOf('function buildCommonBudgetGlossyExtendedInfo'),
  html.indexOf('function buildCommonMindScoreRibbon'),
);
const stage1AvatarFunction = html.slice(
  html.indexOf('function buildCommonStage1AvatarStrip'),
  html.indexOf('function buildCommonBudgetGlossyExtendedInfo'),
);
assert(
  budgetGlossyFunction.includes('data-focus-mode-stage1="budget-glossy-extended-info"') &&
    budgetGlossyFunction.includes('common-focus-budget-stack') &&
    budgetGlossyFunction.includes('common-focus-layer common-budget-stage1-layer') &&
    budgetGlossyFunction.includes('buildCommonStage1AvatarStrip()') &&
    stage1AvatarFunction.includes('data-focus-budget-interaction="longpress-vertical-joystick"') &&
    !budgetGlossyFunction.includes('common-budget-bottom-progress') &&
    !budgetGlossyFunction.includes('common-focus-budget-meta') &&
    !budgetGlossyFunction.includes('Elköltve 51%') &&
    !budgetGlossyFunction.includes('Maradt 61 760 Ft') &&
    !budgetGlossyFunction.includes('category-limit-partition-bar') &&
    !budgetGlossyFunction.includes('data-bar-source') &&
    !budgetGlossyFunction.includes('data-model-source') &&
    !budgetGlossyFunction.includes('common-focus-budget-title') &&
    !budgetGlossyFunction.includes('common-focus-budget-value') &&
    !budgetGlossyFunction.includes('63 240 / 125 000 Ft'),
  'C2/C3 budget glossy sheet must contain only the category avatars; the partition progress bar and spent/remaining labels must be removed from the glossy container',
);
assert(
  /\.common-budget-stage1-layer\s*\{[\s\S]*?bottom:\s*auto;[\s\S]*?height:\s*130px;[\s\S]*?\}/.test(html) &&
    /\.common-context-badge\s*\{[\s\S]*?width:\s*36px;[\s\S]*?height:\s*36px;[\s\S]*?\}/.test(html) &&
    /\.common-context-badge\.near\s*\{[\s\S]*?width:\s*46px;[\s\S]*?height:\s*46px;[\s\S]*?\}/.test(html) &&
    /\.common-context-badge\.center\s*\{[\s\S]*?width:\s*66px;[\s\S]*?height:\s*66px;[\s\S]*?\}/.test(html) &&
    /\.common-stage1-avatar-strip\s*\{[\s\S]*?gap:\s*12px;[\s\S]*?min-height:\s*66px;[\s\S]*?\}/.test(html) &&
    stage1AvatarFunction.includes('--icon-size:17px') &&
    stage1AvatarFunction.includes('--icon-size:22px') &&
    stage1AvatarFunction.includes('--icon-size:30px') &&
    !stage1AvatarFunction.includes('--icon-size:20.4px') &&
    !stage1AvatarFunction.includes('--icon-size:26.4px') &&
    !stage1AvatarFunction.includes('--icon-size:36px'),
  'C2/C3 budget avatar cards must be reverted to the previous avatar geometry while giving the budget glossy layer 5% more height at 130px',
);
assert(
  /\.common-budget-avatar-area\s*\{[\s\S]*?top:\s*0;[\s\S]*?bottom:\s*0;[\s\S]*?place-items:\s*center;[\s\S]*?overflow:\s*visible;[\s\S]*?\}/.test(html) &&
    /\.common-focus-budget-stack\s*\{[\s\S]*?-webkit-mask-image:\s*linear-gradient\(to bottom,\s*#000 0%,\s*#000 75%,\s*rgba\(0,0,0,0\) 100%\);[\s\S]*?mask-image:\s*linear-gradient\(to bottom,\s*#000 0%,\s*#000 75%,\s*rgba\(0,0,0,0\) 100%\);[\s\S]*?\}/.test(html),
  'C2/C3 budget avatar area must be vertically centered in the glossy sheet, and only the lower quarter of the sheet may fade out',
);
const budgetCorePartitionFunction = html.slice(
  html.indexOf('function buildCommonBudgetCorePartition'),
  html.indexOf('function buildCommonBudgetGlossyExtendedInfo'),
);
assert(
  budgetCorePartitionFunction.includes('data-budget-core-partition') &&
    budgetCorePartitionFunction.includes('common-budget-core-partition') &&
    budgetCorePartitionFunction.includes('category-limit-partition-bar') &&
    budgetCorePartitionFunction.includes('data-focus-budget-interaction="longpress-vertical-joystick"') &&
    !budgetCorePartitionFunction.includes('common-focus-budget-meta') &&
    !budgetCorePartitionFunction.includes('Elköltve') &&
    !budgetCorePartitionFunction.includes('Maradt'),
  'Budget mode C1/C2/C3 must render a label-free partition progress bar in the shared stage0/core area',
);
assert(
  !html.includes("subValue: 'Elköltve 51%") &&
    !html.includes('Maradt 61 760 Ft'),
  'Budget mode must not keep the old spent/remaining text labels for C1/C2/C3',
);
assert(
  /\.common-header-core > \.common-budget-core-partition\.common-focus-partition\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*20px;[\s\S]*?right:\s*78px;[\s\S]*?height:\s*5px;[\s\S]*?top:\s*78px;[\s\S]*?margin-top:\s*0;[\s\S]*?z-index:\s*4;[\s\S]*?\}/.test(html) &&
    /\.common-budget-stage1-layer \.category-limit-partition-bar\s*\{[\s\S]*?display:\s*none !important;[\s\S]*?\}/.test(html) &&
    /function syncCommonBudgetCorePartition\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'budget'[\s\S]*?buildCommonBudgetCorePartition\(\)[\s\S]*?querySelectorAll\('\.common-header-core'\)/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonBudgetCorePartition\(row, definition\)/.test(html),
  'Budget mode core partition must be half-height directly under the header value, hidden from any glossy layer remnants, and synchronized during runtime row cloning',
);
const mindGraphFunction = html.slice(
  html.indexOf('function buildCommonMindScoreRibbon'),
  html.indexOf('const mindHeatmapWeekdayLabels'),
);
assert(
  [
    'data-score-ribbon-stage0',
    'data-score-ribbon-path="bad-neutral-good"',
    'data-reference="/storage/emulated/0/spendee/scorechart.png"',
    'lib/features/stats/widgets/stats_fast_info_graph.dart',
    'common-score-ribbon-svg',
    'common-score-path bad',
    'common-score-path neutral',
    'common-score-path good',
    'common-score-endpoint',
  ].every((token) => mindGraphFunction.includes(token)) &&
    !mindGraphFunction.includes('common-score-axis-label') &&
    !mindGraphFunction.includes('common-score-month-label') &&
    !mindGraphFunction.includes('data-focus-mode-stage1="mind-score-graph"'),
  'Mind mode score must be a compact stage0/core ribbon only: segmented bad-neutral-good path and endpoint, without the old axis/month score graph panel',
);
assert(
  mindGraphFunction.includes('function buildCommonMindDoubleGraphContent') &&
    mindGraphFunction.includes('function buildCommonMindMergedBarGraphContent') &&
    mindGraphFunction.includes('data-focus-mode-stage1="mind-${kind}-double-graph"') &&
    mindGraphFunction.includes('data-mind-double-graph="${kind}"') &&
    mindGraphFunction.includes('data-mind-merged-graph="${kind}"') &&
    mindGraphFunction.includes("buildCommonMindMergedBarGraphContent('expense')") &&
    mindGraphFunction.includes("buildCommonMindMergedBarGraphContent('income')") &&
    mindGraphFunction.includes('data-mind-chart-box-size="d2-stage1"') &&
	    mindGraphFunction.includes('common-mind-half-chart') &&
	    mindGraphFunction.includes('data-mind-chart-part="${part.key}"') &&
	    mindGraphFunction.includes('data-mind-chart-label="${part.title}"') &&
	    mindGraphFunction.includes("const monthlyAreaOverlay = !isIncome && part.key === 'monthly'") &&
	    mindGraphFunction.includes('common-mind-monthly-area-fill expense') &&
	    mindGraphFunction.includes('common-mind-monthly-area-line expense') &&
	    mindGraphFunction.includes('data-mind-monthly-area="havi-kiadas"') &&
	    mindGraphFunction.indexOf('${monthlyAreaOverlay}') < mindGraphFunction.indexOf('${part.bars.map') &&
	    mindGraphFunction.includes("const monthlyTitle = isIncome ? 'Havi bevétel' : 'Havi kiadás';") &&
	    mindGraphFunction.includes("const patternsTitle = isIncome ? 'Bevételi minták' : 'Minták';") &&
    mindGraphFunction.includes('const barHeightScale = 0.5;') &&
    mindGraphFunction.includes('data-mind-merged-bar-direction="up"') &&
    mindGraphFunction.includes("const colorName = isIncome ? 'green' : 'red';") &&
    mindGraphFunction.includes('_expenseHelperBars') &&
    mindGraphFunction.includes('_incomeThresholdExcessBars') &&
    !mindGraphFunction.includes('data-double-graph-part="upper-expense"') &&
    !mindGraphFunction.includes('data-double-graph-part="lower-expense"') &&
    !mindGraphFunction.includes('data-double-graph-part="upper-income"') &&
    !mindGraphFunction.includes('data-double-graph-part="lower-income"') &&
    !mindGraphFunction.includes('buildCommonStage1AvatarStrip()'),
  'D2/D3/D4 must use one D2-sized glossy box with two half-height upward chart sections, preserving both red expense and green income sides',
);
assert(
  /\.common-score-grid\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-score-axis\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-score-path\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html),
  'D2 score chart grid, axis, and trend paths must explicitly use fill:none so SVG paths cannot render a black filled polygon over the trend',
);
assert(
  /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonBudgetGlossyExtendedInfo\(\)/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonMindStage1BoxGraphContent\(\)/.test(html) &&
    !/const mindStageContent = buildCommonMindDoubleGraphContent\('expense'\);/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?stage2Header\?\.querySelector\('\.common-context-layer'\)\?\.remove\(\)/.test(html) &&
	    /function syncCommonBalanceInsightLine\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'balance'[\s\S]*?buildCommonBalanceInsightLine\(\)[\s\S]*?querySelectorAll\('\.common-header-core'\)/.test(html) &&
	    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonBalanceInsightLine\(row, definition\)/.test(html) &&
	    /function syncCommonHeaderBalanceDiagnosticsLayer\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'balance'[\s\S]*?buildCommonBalanceDiagnosticsContent\(\)[\s\S]*?insertAdjacentHTML/.test(html) &&
	    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderBalanceDiagnosticsLayer\(row, definition\)[\s\S]*?syncCommonBalanceInsightLine\(row, definition\)/.test(html) &&
	    /function syncCommonHeaderStage2Stage1Layer\(row\) \{[\s\S]*?cloneNode\(true\)[\s\S]*?common-stage2-stage1-layer[\s\S]*?dataset\.stage2IncludesStage1[\s\S]*?insertAdjacentElement/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderStage2Stage1Layer\(row\)/.test(html) &&
    !html.includes('function ensureCommonMindIncomeStage2Screen') &&
    !html.includes('ensureCommonMindIncomeStage2Screen(row, definition)') &&
    !html.includes('function ensureCommonMindBoxGraphAlternativeScreens') &&
    !html.includes('ensureCommonMindBoxGraphAlternativeScreens(row, definition)') &&
    !/function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonContextCarousel/.test(html),
  'Runtime cloned rows must use the budget and D2 box-layout mind stage1 helpers, clone the active stage1 layer into stage2, remove D4/D11 generators, and must not insert any stage3 bottom avatar carousel',
);
assert(
  [
    'const commonMindAlternativeCardScreens',
    'function buildCommonMindAlternativeCardContent',
    'function ensureCommonMindAlternativeCardScreens',
    'alt-common-header-mind-score-cards-stage2',
    'alt-common-header-mind-expense-cards-stage2',
    'alt-common-header-mind-action-cards-stage2',
    'const commonMindGlanceAlternativeScreens',
    'function buildCommonMindGlanceAlternativeContent',
    'function ensureCommonMindGlanceAlternativeScreens',
    'alt-common-header-mind-score-hero-stage2',
    'alt-common-header-mind-expense-pressure-stage2',
    'alt-common-header-mind-action-stack-stage2',
    'data-mind-alt-screen="true"',
    'data-mind-glance-screen="true"',
  ].every((token) => !html.includes(token)),
  'Old D5-D10 Mind alternative card/glance screens must stay removed while D4 income and D11 are also removed',
);
const mindBoxGraphSource = html.slice(
  html.indexOf('const commonMindStage1BoxGraphConfig'),
  html.indexOf('const mindHeatmapWeekdayLabels'),
);
assert(
  [
    'const commonMindStage1BoxGraphConfig',
    'key: \'boxed-graphs\'',
    'function buildCommonMindStage1BoxGraphContent',
    'common-focus-layer common-mind-box-graph-layer',
    'mind-boxed-graphs-d2',
    'common-mind-previous-period-kpi',
    'data-previous-period-comparison="true"',
    'data-previous-period-arrow="up"',
    'fastinfo-chart-card',
    'key: \'period-expense-bars\'',
    'key: \'expense-pattern-volume\'',
    'data-mind-box-card-count="2"',
    'data-mind-box-layout="direct-background"',
    'visual: \'line-bar\'',
    'data-mind-box-chart-style="${card.visual}"',
    'data-mind-box-chart-style="line-bar"',
    'data-mind-box-card-role="${card.key}"',
  ].every((token) => mindBoxGraphSource.includes(token)) &&
    !mindBoxGraphSource.includes('common-mind-box-graph-grid') &&
    !mindBoxGraphSource.includes('common-mind-box-graph-panel') &&
    !mindBoxGraphSource.includes('key: \'score-change\'') &&
    !mindBoxGraphSource.includes('Score változás') &&
    !mindBoxGraphSource.includes('<section') &&
    /key:\s*'period-expense-bars'[\s\S]*?visual:\s*'line-bar'/.test(mindBoxGraphSource) &&
    /function buildCommonMindBoxGraphLayerContent\(config\) \{[\s\S]*?common-focus-layer common-mind-box-graph-layer[\s\S]*?data-focus-mode-stage1="mind-boxed-graphs-d2"[\s\S]*?data-mind-box-layout="direct-background"/.test(mindBoxGraphSource) &&
    /function buildCommonMindStage1BoxGraphContent\(\) \{[\s\S]*?return buildCommonMindBoxGraphLayerContent\(commonMindStage1BoxGraphConfig\);[\s\S]*?\}/.test(mindBoxGraphSource) &&
    /function buildCommonMindBoxGraphMiniSvg\(card\) \{[\s\S]*?const lineBarMode = card\.visual === 'line-bar'[\s\S]*?mini-area line-bar[\s\S]*?mini-line line-bar[\s\S]*?mini-bar line-bar/.test(mindBoxGraphSource) &&
    /\.common-focus-layer\.common-mind-box-graph-layer\s*\{[\s\S]*?pointer-events:\s*auto;[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?grid-template-rows:\s*auto minmax\(0,\s*1fr\);[\s\S]*?background:\s*transparent;[\s\S]*?\}/.test(html) &&
    /\.common-mind-previous-period-kpi\s*\{[\s\S]*?grid-column:\s*1 \/ -1;[\s\S]*?\}/.test(html),
  'D2 must draw the previous-period KPI and exactly two wide B3-style cards directly on the stage1 background: volume and period expense, without a glossy wrapper or score card',
);
assert(
  [
    'function ensureCommonMindIncomeStage2Screen',
    'ensureCommonMindIncomeStage2Screen(row, definition)',
    'alt-common-header-mind-income-stage2',
    'data-screen="alt-common-header-mind-income-stage2"',
    'data-income-side="true"',
    'function ensureCommonMindBoxGraphAlternativeScreens',
    'ensureCommonMindBoxGraphAlternativeScreens(row, definition)',
    'function buildCommonMindBoxGraphAlternativeContent',
    'alt-common-header-mind-boxed-graphs-stage2',
    'data-mind-box-graph-screen="true"',
  ].every((token) => !html.includes(token)),
  'D4 income-side and D11 boxed-graph Mind screens must be removed while keeping the D2 box layout',
);
assert(
  !html.includes('autofocus') &&
    html.includes('function focusQueryMenuQ1AOnLoad') &&
    /function focusQueryMenuQ1AOnLoad\(\) \{[\s\S]*?\[data-query-menu-row\] \[data-screen="alt-query-menu-category-vendor-hierarchy"\][\s\S]*?scrollIntoView\(\{ block: 'start', inline: 'start'/.test(html) &&
    /initCommonHeaderModeRows\(\);[\s\S]*?moveQueryMenuRowToTop\(\);[\s\S]*?initQueryMenuPrototype\(\);[\s\S]*?focusQueryMenuQ1AOnLoad\(\);[\s\S]*?initBalanceHeaderScaleLab\(\);/.test(html) &&
    !html.includes('initMindHeatmapScreens();'),
  'Refreshing the HTML must not autofocus the keyboard mockup and must scroll/focus the remaining Q1A screen after rows are generated without the deleted D-full preview init',
);
assert(
  /function buildCommonMindDoubleGraphContent\(kind = 'expense', placement = 'stage1'\) \{[\s\S]*?buildCommonMindMergedBarGraphContent\('income', placement\)[\s\S]*?buildCommonMindMergedBarGraphContent\('expense', placement\)/.test(html) &&
    /\.common-mind-merged-graph\s*\{[\s\S]*?height:\s*100%;[\s\S]*?\}/.test(html) &&
	    /\.common-mind-merged-graph-panel\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
	    /\.common-mind-half-chart\s*\{[\s\S]*?position:\s*relative;[\s\S]*?min-height:\s*0;[\s\S]*?\}/.test(html) &&
	    /\.common-mind-monthly-area-fill\.expense\s*\{[\s\S]*?fill:\s*rgba\(239,68,68,\.18\);[\s\S]*?\}/.test(html) &&
	    /\.common-mind-monthly-area-line\.expense\s*\{[\s\S]*?fill:\s*none;[\s\S]*?stroke:\s*rgba\(239,68,68,\.58\);[\s\S]*?\}/.test(html) &&
	    /\.common-stage2-stage1-layer\s*\{[\s\S]*?height:\s*calc\(var\(--common-header-stage1-h\) - 114px\);[\s\S]*?\}/.test(html) &&
    !/\.common-mind-double-graph\s*\{[\s\S]*?grid-template-rows:\s*1fr 1fr;[\s\S]*?\}/.test(html),
  'D2/D3/D4 mind stage1 must render one D2-sized glossy graph container with two half-height chart sections instead of two stacked containers',
);
const mindHeatmapFunction = html.slice(
  html.indexOf('function buildCommonMindHeatmapContent'),
  html.indexOf('function ensureCommonHeaderHandle'),
);
const syncMindHeatmapFunction = html.slice(
  html.indexOf('function syncCommonHeaderMindHeatmapLayer'),
  html.indexOf('function ensureCommonMindMonthlyStage2Screen'),
);
const separatedGlassD3ContentStart = html.indexOf('function buildCommonMindSeparatedGlassHeatmapContent');
const separatedGlassD3ContentFunction = separatedGlassD3ContentStart >= 0
  ? html.slice(separatedGlassD3ContentStart, html.indexOf('function buildCommonMindHeatmapContent'))
  : '';
const separatedGlassD3ScreenStart = html.indexOf('function ensureCommonMindSeparatedGlassD3Screen');
const separatedGlassD3ScreenFunction = separatedGlassD3ScreenStart >= 0
  ? html.slice(separatedGlassD3ScreenStart, html.indexOf('function ensureCommonMindMonthlyStage2Screen'))
  : '';
const monthlyHeatmapStage2Function = html.slice(
  html.indexOf('function ensureCommonMindMonthlyStage2Screen'),
  html.indexOf('function ensureCommonMindSumStage2Screen'),
);
const sumHeatmapStage2Function = html.slice(
  html.indexOf('function ensureCommonMindSumStage2Screen'),
  html.indexOf('function syncCommonHeaderBudgetPieLayer'),
);
const separatedGlassD5ContentStart = html.indexOf('function buildCommonMindSeparatedGlassSumHeatmapContent');
const separatedGlassD5ContentFunction = separatedGlassD5ContentStart >= 0
  ? html.slice(separatedGlassD5ContentStart, html.indexOf('function buildCommonMindSeparatedGlassHeatmapContent'))
  : '';
const separatedGlassD5ScreenStart = html.indexOf('function ensureCommonMindSeparatedGlassD5Screen');
const separatedGlassD5ScreenFunction = separatedGlassD5ScreenStart >= 0
  ? html.slice(separatedGlassD5ScreenStart, html.indexOf('function syncCommonHeaderBudgetPieLayer'))
  : '';
const mindStage1ChartPresentationFunction = html.slice(
  html.indexOf('function setCommonMindStage1ChartLayerPresentation'),
  html.indexOf('function ensureCommonHeaderMindStage1ChartsLayer'),
);
const d4MindChartLayerRule = (html.match(/\.common-focus-layer\.common-mind-box-graph-layer\.common-stage2-mind-chart-panel\s*\{[\s\S]*?\n    \}/) || [''])[0];
const d4MindChartCardRule = (html.match(/\.common-stage2-mind-chart-panel \.common-mind-box-graph-card\.fastinfo-chart-card\s*\{[\s\S]*?\n    \}/) || [''])[0];
assert(
  [
    'data-stage2-extra="mind-heatmap"',
    'common-stage2-heatmap-layer',
    'common-stage2-heatmap-scroll',
    'buildMindHeatmapYearGrid',
    'StatsYearCalendar',
    'StatsMonthCard.cardHeight',
    'StatsYearData',
    'heatmapIntensity',
    'data-heatmap-grid="year"',
    'data-heatmap-columns="3"',
    'data-heatmap-rows="4"',
  ].every((token) => mindHeatmapFunction.includes(token)) &&
    mindHeatmapFunction.includes('common-stage2-heatmap-panel') &&
    mindHeatmapFunction.includes('data-heatmap-panel="score-glass"') &&
    !mindHeatmapFunction.includes('common-stage2-heatmap-title'),
  'D3 mind stage2 must render the yearly month heatmap inside one shared score-glass panel without a title bar',
);
assert(
  /function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?data-heatmap-header="compact-no-score"[\s\S]*?<div class="mind-heatmap-month-head">[\s\S]*?<strong>\$\{month\.name\}<\/strong>[\s\S]*?<\/div>[\s\S]*?mind-heatmap-days/.test(html) &&
    !/function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?mind-heatmap-score-badge/.test(html) &&
    !/function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?mindHeatmapScoreBadgeColor/.test(html),
  'D3/monthcard headers must be compact month-name-only headers with no score number/badge in the header',
);
assert(
  [
    'data-color-target="heatmap-cell-color"',
    'data-heatmap-color-scope',
    'data-heatmap-card-variant',
    'mind-heatmap-card-variant',
    '--heat-alpha',
  ].every((token) => html.includes(token)) &&
    !html.includes('--heat-cell:'),
  'Heatmap monthcards must expose a tap color target and use selected category color plus per-cell opacity instead of fixed per-cell colors',
);
assert(
  /\.mind-heatmap-day::before\s*\{[\s\S]*?background:\s*var\(--heatmap-active-color[\s\S]*?opacity:\s*var\(--heat-alpha[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="plain"\]\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.72\);[\s\S]*?box-shadow:\s*0 8px 18px rgba\(31,45,70,\.09\), inset 0 1px 0 rgba\(255,255,255,\.76\);[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="frost"\]\s*\{[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="aurora"\]\s*\{[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="graphite"\]\s*\{[\s\S]*?\}/.test(html),
  'Heatmap monthcard CSS must expose a plain fastinfo-style card background for D3/D4 and keep cells painted through a dynamic color overlay',
);
assert(
  /\.common-stage2-heatmap-panel \.mind-heatmap-month-card\[data-heatmap-card-variant="plain"\]\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.38\);[\s\S]*?\}/.test(html) &&
    /\.common-stage2-sum-heatmap-panel \.mind-heatmap-year-card\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.38\);[\s\S]*?\}/.test(html),
  'D3 and D5 inner heatmap cards must have reduced background opacity while their shared glass containers remain intact',
);
assert(
  /\.common-header-stage2\[data-stage2-scrollable="true"\]\s*\{[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-heatmap-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?top:\s*calc\(96px \+ \(var\(--common-header-stage1-h\) - 114px\) \+ 12px\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?overscroll-behavior:\s*contain;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-head\s*\{[\s\S]*?min-height:\s*12px;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-weekdays\s*\{[\s\S]*?margin:\s*7px 0 4px;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-grid\s*\{[\s\S]*?grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\s*\{[\s\S]*?border-radius:\s*16px;[\s\S]*?\}/.test(html),
  'D3 heatmap CSS must keep stage2 scroll while rendering compact 3-column month cards directly on the header',
);
assert(
  /function removeCommonHeaderBalanceStage2Residue\(header\)\s*\{[\s\S]*?data-focus-mode-stage1="balance-reserve-summary"[\s\S]*?data-focus-mode-stage2="balance-income-expense"[\s\S]*?data-stage2-extra="balance-diagnostics"[\s\S]*?delete header\.dataset\.balanceDiagnosticsScrollable[\s\S]*?\}/.test(html) &&
    /function setCommonMindStage1ChartLayerPresentation\(layer,\s*cloneMode\)\s*\{[\s\S]*?cloneMode === 'mind-month-heatmap' \|\| cloneMode === 'mind-separated-glass-d3'[\s\S]*?classList\.toggle\('common-stage2-mind-chart-panel', isGlassChartMode\)[\s\S]*?\}/.test(html) &&
    !mindStage1ChartPresentationFunction.includes("classList.toggle('common-stage2-heatmap-panel'") &&
    /function ensureCommonHeaderMindStage1ChartsLayer\(targetHeader,\s*sourceHeader,\s*cloneMode\)\s*\{[\s\S]*?data-stage2-includes-stage1="true"\]\[data-focus-mode-stage1="mind-boxed-graphs-d2"[\s\S]*?existingLayer[\s\S]*?setCommonMindStage1ChartLayerPresentation\(existingLayer,\s*cloneMode\)[\s\S]*?cloneNode\(true\)[\s\S]*?dataset\.stage2CloneMode = cloneMode[\s\S]*?setCommonMindStage1ChartLayerPresentation\(clonedLayer,\s*cloneMode\)[\s\S]*?insertAdjacentElement/.test(html) &&
    /function syncCommonHeaderMindHeatmapLayer\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'mind'[\s\S]*?removeCommonHeaderBalanceStage2Residue\(stage2Header\)[\s\S]*?dataset\.stage2Scrollable = 'true'[\s\S]*?buildCommonMindHeatmapContent\(\)[\s\S]*?insertAdjacentHTML/.test(html) &&
    !syncMindHeatmapFunction.includes('querySelector(\'[data-stage2-includes-stage1="true"]\')?.remove()') &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderStage2Stage1Layer\(row\)[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\)/.test(html),
  'Runtime D3 must preserve the mind stage1 two-chart clone while removing only balance residue before attaching the heatmap',
);
assert(
  separatedGlassD3ContentFunction.includes('data-stage2-extra="mind-heatmap-separated-glass"') &&
    separatedGlassD3ContentFunction.includes('common-stage2-separated-heatmap-layer') &&
    separatedGlassD3ContentFunction.includes('data-heatmap-view="separate-glass"') &&
    separatedGlassD3ContentFunction.includes("buildMindHeatmapYearGrid('separate-glass')") &&
    !separatedGlassD3ContentFunction.includes('common-stage2-heatmap-panel') &&
    /function resolveMindHeatmapCardVariant\(variant, monthIndex = 1\) \{[\s\S]*?if \(variant === 'separate-glass'\) return 'frost';/.test(html) &&
    /function setCommonMindStage1ChartLayerPresentation\(layer,\s*cloneMode\)\s*\{[\s\S]*?cloneMode === 'mind-month-heatmap' \|\| cloneMode === 'mind-separated-glass-d3'[\s\S]*?classList\.toggle\('common-stage2-mind-chart-panel', isGlassChartMode\)/.test(html) &&
    separatedGlassD3ScreenFunction.includes("data-screen', 'alt-common-header-mind-separated-glass-d3'") &&
    separatedGlassD3ScreenFunction.includes("dataset.mindSeparatedGlassD3Screen = 'true'") &&
    separatedGlassD3ScreenFunction.includes('D3G ·') &&
    separatedGlassD3ScreenFunction.includes("ensureCommonHeaderMindStage1ChartsLayer(separatedStage2Header, stage2Header, 'mind-separated-glass-d3')") &&
    separatedGlassD3ScreenFunction.includes('buildCommonMindSeparatedGlassHeatmapContent()') &&
    separatedGlassD3ScreenFunction.includes("stage2Column.insertAdjacentElement('afterend', separatedColumn)") &&
    /function ensureCommonMindMonthlyStage2Screen\(row,\s*definition\) \{[\s\S]*?const separatedGlassColumn = row\.querySelector\('\[data-mind-separated-glass-d3-column="true"\]'\) \|\| stage2Column;[\s\S]*?separatedGlassColumn\.insertAdjacentElement\('afterend', monthlyColumn\)/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\);[\s\S]*?ensureCommonMindSeparatedGlassD3Screen\(row, definition\);[\s\S]*?ensureCommonMindMonthlyStage2Screen\(row, definition\);/.test(html) &&
    /\.common-stage2-separated-heatmap-layer \.mind-heatmap-grid\s*\{[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-separated-heatmap-layer \.mind-heatmap-month-card\[data-heatmap-card-variant="frost"\]\s*\{[\s\S]*?background:\s*radial-gradient\(circle at 14% 8%, rgba\(255,255,255,\.38\), transparent 40%\),[\s\S]*?linear-gradient\(180deg, rgba\(255,255,255,\.30\), rgba\(255,255,255,\.10\)\);[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.24\);[\s\S]*?backdrop-filter:\s*blur\(16px\);[\s\S]*?\}/.test(html),
  'D3 alternate must sit beside D3 with separated glass chart cards and separated glass monthcards, without the shared score-glass collector panel',
);
assert(
  separatedGlassD5ContentFunction.includes('data-stage2-extra="mind-heatmap-sum-separated-glass"') &&
    separatedGlassD5ContentFunction.includes('common-stage2-separated-sum-heatmap-layer') &&
    separatedGlassD5ContentFunction.includes('data-heatmap-view="sum-separate-glass"') &&
    separatedGlassD5ContentFunction.includes('buildMindHeatmapSummaryYearGrid()') &&
    !separatedGlassD5ContentFunction.includes('common-stage2-heatmap-panel') &&
    /function setCommonMindStage1ChartLayerPresentation\(layer,\s*cloneMode\)\s*\{[\s\S]*?cloneMode === 'mind-month-heatmap' \|\| cloneMode === 'mind-separated-glass-d3' \|\| cloneMode === 'mind-separated-glass-d5'[\s\S]*?classList\.toggle\('common-stage2-mind-chart-panel', isGlassChartMode\)/.test(html) &&
    separatedGlassD5ScreenFunction.includes("data-screen', 'alt-common-header-mind-separated-glass-d5'") &&
    separatedGlassD5ScreenFunction.includes("dataset.mindSeparatedGlassD5Screen = 'true'") &&
    separatedGlassD5ScreenFunction.includes('D5G ·') &&
    separatedGlassD5ScreenFunction.includes("ensureCommonHeaderMindStage1ChartsLayer(separatedSumStage2Header, stage2Header, 'mind-separated-glass-d5')") &&
    separatedGlassD5ScreenFunction.includes('buildCommonMindSeparatedGlassSumHeatmapContent()') &&
    separatedGlassD5ScreenFunction.includes("sumColumn.insertAdjacentElement('afterend', separatedSumColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?ensureCommonMindSumStage2Screen\(row, definition\);[\s\S]*?ensureCommonMindSeparatedGlassD5Screen\(row, definition\);/.test(html) &&
    /\.common-stage2-separated-sum-heatmap-layer \.mind-heatmap-summary-year-grid\s*\{[\s\S]*?gap:\s*6px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-separated-sum-heatmap-layer \.mind-heatmap-year-card\s*\{[\s\S]*?background:\s*radial-gradient\(circle at 14% 8%, rgba\(255,255,255,\.38\), transparent 40%\),[\s\S]*?linear-gradient\(180deg, rgba\(255,255,255,\.30\), rgba\(255,255,255,\.10\)\);[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.24\);[\s\S]*?backdrop-filter:\s*blur\(16px\);[\s\S]*?\}/.test(html),
  'D5 alternate must sit beside D5 with separated glass chart cards and separated glass year cards, without the shared sum-glass collector panel',
);
assert(
  /function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?Array\.from\(\{\s*length:\s*month\.days\s*\}[\s\S]*?data-heatmap-day="\$\{day\}"[\s\S]*?<div class="mind-heatmap-days">\$\{dayCells\.join\(''\)\}<\/div>[\s\S]*?\}/.test(html) &&
    !/function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?blankCells/.test(html) &&
    !/function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?trailingCells/.test(html) &&
    !/function buildMindHeatmapMonthCard\(month, variant = 'compact'\) \{[\s\S]*?trailingCount/.test(html) &&
    !html.includes('mind-heatmap-day blank') &&
    !/\.mind-heatmap-day\.blank\s*\{/.test(html),
  'D-row heatmap monthcards must render only real day cells and must not create leading/trailing placeholder day cells',
);
assert(
  /\.common-focus-layer\.common-mind-box-graph-layer\.common-stage2-mind-chart-panel\s*\{[\s\S]*?padding:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html) &&
    !d4MindChartLayerRule.includes('radial-gradient') &&
    /\.common-stage2-mind-chart-panel \.common-mind-box-graph-card\.fastinfo-chart-card\s*\{[\s\S]*?background:\s*radial-gradient\(circle at 14% 8%, rgba\(255,255,255,\.38\), transparent 40%\),[\s\S]*?linear-gradient\(180deg, rgba\(255,255,255,\.30\), rgba\(255,255,255,\.10\)\);[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.24\);[\s\S]*?backdrop-filter:\s*blur\(16px\);[\s\S]*?\}/.test(html) &&
    !d4MindChartCardRule.includes('rgba(255,255,255,.66)') &&
    !d4MindChartCardRule.includes('rgba(255,255,255,.32)'),
  'D4 mind-month chart cards must be direct glass containers while the absolute chart layer keeps its original transparent layout',
);
assert(
  /function buildMindHeatmapMonthGrid\(month = mindHeatmapYearMonths\[6\], variant = 'month-single'\) \{[\s\S]*?data-heatmap-grid="month"[\s\S]*?data-heatmap-month-view="single"[\s\S]*?data-heatmap-color-scope[\s\S]*?buildMindHeatmapMonthCard\(month, variant\)/.test(html) &&
    /function buildCommonMindMonthlyHeatmapContent\(\) \{[\s\S]*?data-stage2-extra="mind-heatmap-month"[\s\S]*?common-stage2-month-heatmap-layer[\s\S]*?buildMindHeatmapMonthGrid\(mindHeatmapYearMonths\[6\], 'month-single'\)[\s\S]*?\}/.test(html) &&
    !/function buildCommonMindMonthlyHeatmapContent\(\) \{[\s\S]*?data-heatmap-panel="monthly-glass"/.test(html) &&
    !/function buildCommonMindMonthlyHeatmapContent\(\) \{[\s\S]*?common-stage2-heatmap-title/.test(html) &&
    /function ensureCommonMindMonthlyStage2Screen\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'mind'[\s\S]*?alt-common-header-mind-month-heatmap-stage2[\s\S]*?D4[\s\S]*?removeCommonHeaderBalanceStage2Residue\(monthlyStage2Header\)[\s\S]*?ensureCommonHeaderMindStage1ChartsLayer\(monthlyStage2Header,\s*stage2Header,\s*'mind-month-heatmap'\)[\s\S]*?buildCommonMindMonthlyHeatmapContent\(\)[\s\S]*?insertAdjacentElement\('afterend'/.test(html) &&
    !monthlyHeatmapStage2Function.includes('querySelector(\'[data-stage2-includes-stage1="true"]\')?.remove()') &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\);[\s\S]*?ensureCommonMindMonthlyStage2Screen\(row, definition\);/.test(html) &&
    /\.mind-heatmap-month-grid\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);[\s\S]*?\}/.test(html) &&
    /\.common-stage2-month-heatmap-layer \.mind-heatmap-days\s*\{[\s\S]*?height:\s*100%;[\s\S]*?grid-template-rows:\s*repeat\(6,\s*minmax\(0,\s*1fr\)\);[\s\S]*?align-content:\s*stretch;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-month-heatmap-layer \.mind-heatmap-day\s*\{[\s\S]*?height:\s*100%;[\s\S]*?aspect-ratio:\s*auto;[\s\S]*?\}/.test(html),
  'D4 beside D3 must show one clean monthly heatmap under the preserved mind stage1 charts without balance residue or a glass wrapper',
);
const baseHeatmapGridRuleIndex = html.indexOf('.mind-heatmap-grid {');
const focusedMonthGridRuleIndex = html.indexOf('.common-stage2-month-heatmap-layer .mind-heatmap-month-grid');
assert(
  focusedMonthGridRuleIndex > baseHeatmapGridRuleIndex &&
    /\.common-stage2-month-heatmap-layer \.mind-heatmap-month-grid\s*\{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);[\s\S]*?width:\s*100%;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-month-heatmap-layer \.mind-heatmap-month-card\s*\{[\s\S]*?width:\s*100%;[\s\S]*?\}/.test(html),
  'D4 focused monthly heatmap card must override the D3 three-column grid and span the direct header layer width',
);
assert(
  /const mindHeatmapSummaryYears\s*=\s*Array\.from\(\{\s*length:\s*24\s*\}/.test(html) &&
    /year:\s*String\(2003 \+ index\)/.test(html) &&
    /months:\s*mindHeatmapSummaryMonthTemplate\.map\(\(month,\s*monthIndex\)/.test(html) &&
    /function buildMindHeatmapYearCard\(year\)\s*\{[\s\S]*?mind-heatmap-year-card[\s\S]*?data-color-target="heatmap-cell-color"[\s\S]*?data-heatmap-color-scope[\s\S]*?mind-year-month-cells[\s\S]*?data-heatmap-month-cell="\$\{month\.key\}"[\s\S]*?--heat-alpha:\$\{mindHeatmapMonthAlpha\(month\)\}/.test(html) &&
    /function buildCommonMindSumHeatmapContent\(\)\s*\{[\s\S]*?data-stage2-extra="mind-heatmap-sum"[\s\S]*?common-stage2-sum-heatmap-layer[\s\S]*?data-heatmap-grid="sum"[\s\S]*?buildMindHeatmapSummaryYearGrid\(\)/.test(html) &&
    /function buildMindHeatmapSummaryYearGrid\(\)\s*\{[\s\S]*?data-heatmap-year-card-count="\$\{mindHeatmapSummaryYears\.length\}"[\s\S]*?data-heatmap-year-columns="4"/.test(html) &&
    /function buildCommonMindSumHeatmapContent\(\)\s*\{[\s\S]*?class="common-stage2-heatmap-panel common-stage2-sum-heatmap-panel"[\s\S]*?data-heatmap-panel="sum-glass"/.test(html) &&
    !/function buildCommonMindSumHeatmapContent\(\)\s*\{[\s\S]*?common-stage2-heatmap-title/.test(html) &&
    /function ensureCommonMindSumStage2Screen\(row,\s*definition\)\s*\{[\s\S]*?definition\.mode !== 'mind'[\s\S]*?alt-common-header-mind-sum-stage2[\s\S]*?D5[\s\S]*?removeCommonHeaderBalanceStage2Residue\(sumStage2Header\)[\s\S]*?ensureCommonHeaderMindStage1ChartsLayer\(sumStage2Header,\s*stage2Header,\s*'mind-sum-heatmap'\)[\s\S]*?buildCommonMindSumHeatmapContent\(\)[\s\S]*?insertAdjacentElement\('afterend'/.test(html) &&
    !sumHeatmapStage2Function.includes('querySelector(\'[data-stage2-includes-stage1="true"]\')?.remove()') &&
    /function updateCommonHeaderModeRow\(modeSection, definition\)\s*\{[\s\S]*?ensureCommonMindMonthlyStage2Screen\(row, definition\);[\s\S]*?ensureCommonMindSumStage2Screen\(row, definition\);/.test(html),
  'D5 beside D4 must show clean year cards under the preserved mind stage1 charts without balance residue or a glass wrapper',
);
assert(
  /\.common-stage2-sum-heatmap-layer\s*\{[\s\S]*?overflow-y:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-summary-year-grid\s*\{[\s\S]*?grid-template-columns:\s*repeat\(4,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.common-stage2-sum-heatmap-panel \.mind-heatmap-summary-year-grid\s*\{[\s\S]*?gap:\s*6px;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-year-card\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.72\);[\s\S]*?box-shadow:\s*0 8px 18px rgba\(31,45,70,\.09\), inset 0 1px 0 rgba\(255,255,255,\.76\);[\s\S]*?\}/.test(html) &&
    /\.mind-year-month-cells\s*\{[\s\S]*?grid-template-columns:\s*repeat\(4,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.mind-year-month-cell::before\s*\{[\s\S]*?background:\s*var\(--heatmap-active-color[\s\S]*?opacity:\s*var\(--heat-alpha[\s\S]*?\}/.test(html),
  'D5 sum mode CSS must arrange clean fastinfo-style year cards in 4 columns and render month cells as colorable 4x3 mini heatmap cells',
);
assert(
  /\.common-stage2-sum-heatmap-panel \.mind-heatmap-year-card\s*\{[\s\S]*?gap:\s*3px;[\s\S]*?padding:\s*5px;[\s\S]*?border-radius:\s*12px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-sum-heatmap-panel \.mind-year-card-head strong\s*\{[\s\S]*?font-size:\s*9px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-sum-heatmap-panel \.mind-year-month-cells\s*\{[\s\S]*?gap:\s*2px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-sum-heatmap-panel \.mind-year-month-cell\s*\{[\s\S]*?height:\s*10px;[\s\S]*?border-radius:\s*4px;[\s\S]*?font-size:\s*4px;[\s\S]*?\}/.test(html),
  'D5 sum year cards must be recalculated for 12 cards in 4 columns with tighter card padding, headers, month gaps, and 10px month-cell height',
);
assert(
  !/if \(variant === 'stage2-scroll'\) return 'aurora';/.test(html) &&
    /if \(variant === 'stage2-scroll'\) return 'plain';/.test(html) &&
    /if \(variant === 'month-single'\) return 'frost';/.test(html),
  'D3 heatmap monthcards must stay plain inside the glass container while D4 month-single uses the frost glass card background',
);
assert(
  !html.includes('data-heatmap-preview="full-year"') &&
    !html.includes('data-screen-height="content"') &&
    !html.includes('data-mind-heatmap-render-target'),
  'The separate D-full 12-month full-year preview screen and its render targets must be removed',
);
assert(
  /if \(target\.dataset\.colorTarget === 'heatmap-cell-color'\) \{[\s\S]*?closest\('\[data-heatmap-color-scope\]'\)[\s\S]*?style\.setProperty\('--heatmap-active-color', selectionState\.selectedColor\)[\s\S]*?dataset\.heatmapSelectedColor/.test(html),
  'Color application must support tapping a selected color onto heatmap monthcards/grids by writing --heatmap-active-color to the local heatmap scope',
);
const budgetPieFunction = html.slice(
  html.indexOf('function buildCommonBudgetCategoryPieContent'),
  html.indexOf('function syncCommonHeaderBudgetPieLayer'),
);
assert(
  [
    'data-stage2-extra="budget-category-pie"',
    'common-budget-pie-stage2-layer',
    'lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart',
    'CategoryDonutChart',
    'stats-category-donut',
    'data-category-highlight="current"',
    'common-budget-pie-donut',
    'buildBudgetCategoryPieSlices(',
    'common-budget-pie-list',
  ].every((token) => budgetPieFunction.includes(token)) &&
    html.includes('common-budget-pie-slice'),
  'C3 budget stage2 must render a scrollable category pie/donut area based on the app CategoryDonutChart/stats donut with current category highlighted',
);
assert(
  /\.common-budget-pie-stage2-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?overflow-y:\s*auto;[\s\S]*?overscroll-behavior:\s*contain;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-slice\.selected\s*\{[\s\S]*?stroke-width:\s*17;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-row\[data-category-highlight="current"\]\s*\{[\s\S]*?\}/.test(html),
  'C3 budget pie area must be internally scrollable and visually highlight the selected category both on the donut and list row',
);
const budgetPieSlicesFunction = html.slice(
  html.indexOf('function buildBudgetCategoryPieSlices'),
  html.indexOf('function buildCommonBudgetCategoryPieContent'),
);
const budget3dDonutFunction = html.slice(
  html.indexOf('function ensureCommonBudget3dDonutScreen'),
  html.indexOf('function ensureCommonHeaderHandle'),
);
const budgetAlt3dDonutFunctionStart = html.indexOf('function ensureCommonBudgetAlt3dDonutScreen');
const budgetAlt3dDonutFunction = budgetAlt3dDonutFunctionStart >= 0
  ? html.slice(budgetAlt3dDonutFunctionStart, html.indexOf('function ensureCommonHeaderHandle'))
  : '';
const budgetInteractive3dDonutFunctionStart = html.indexOf('function ensureCommonBudgetInteractive3dDonutScreen');
const budgetInteractive3dDonutFunction = budgetInteractive3dDonutFunctionStart >= 0
  ? html.slice(budgetInteractive3dDonutFunctionStart, html.indexOf('function ensureCommonHeaderHandle'))
  : '';
const budgetWhitePieFunctionStart = html.indexOf('function ensureCommonBudgetWhitePieScreen');
const budgetWhitePieFunction = budgetWhitePieFunctionStart >= 0
  ? html.slice(budgetWhitePieFunctionStart, html.indexOf('function ensureCommonHeaderHandle'))
  : '';
assert(
  budgetPieSlicesFunction.includes("layer = 'top'") &&
    budgetPieSlicesFunction.includes("layer === 'side'") &&
    budgetPieFunction.includes("donutStyle = 'flat'") &&
    budgetPieFunction.includes('data-donut-style="${donutStyle}"') &&
    budgetPieFunction.includes("donutStyle === '3d'") &&
    budgetPieFunction.includes('common-budget-pie-donut-3d') &&
    budgetPieFunction.includes('common-budget-pie-3d-shadow') &&
    budgetPieFunction.includes('common-budget-pie-3d-side') &&
    budgetPieFunction.includes('common-budget-pie-3d-top') &&
    budgetPieFunction.includes("buildBudgetCategoryPieSlices('side')") &&
    budgetPieFunction.includes('common-budget-pie-center-highlight'),
  'Budget pie builder must support a scoped 3D donut variant with side/top SVG layers while keeping flat as the default',
);
assert(
  budgetPieSlicesFunction.includes("layer === 'alt-depth'") &&
    budgetPieSlicesFunction.includes("layer === 'alt-pop'") &&
    budgetPieFunction.includes("donutStyle === '3d-alt'") &&
    budgetPieFunction.includes('common-budget-pie-donut-3d-alt') &&
    budgetPieFunction.includes('common-budget-pie-3d-alt-depth') &&
    budgetPieFunction.includes('common-budget-pie-3d-alt-top') &&
    budgetPieFunction.includes('common-budget-pie-3d-alt-pop') &&
    budgetPieFunction.includes('common-budget-pie-3d-alt-highlight') &&
    budgetPieFunction.includes("buildBudgetCategoryPieSlices('alt-depth')") &&
    budgetPieFunction.includes("buildBudgetCategoryPieSlices('alt-pop')"),
  'Budget pie builder must support a distinct C4C 3D-alt donut variant with depth, raised slice, and highlight layers',
);
assert(
  budget3dDonutFunction.includes('[data-budget-3d-donut-screen="true"]') &&
    budget3dDonutFunction.includes("definition.mode !== 'budget'") &&
    budget3dDonutFunction.includes("data-screen', 'alt-common-header-budget-stage2-3d-donut'") &&
    budget3dDonutFunction.includes("dataset.budget3dDonutScreen = 'true'") &&
    budget3dDonutFunction.includes("dataset.budgetPie3dScrollable = 'true'") &&
    budget3dDonutFunction.includes('C4B ·') &&
    budget3dDonutFunction.includes("buildCommonBudgetCategoryPieContent({ donutStyle: '3d' })") &&
    budget3dDonutFunction.includes("stage2Column.insertAdjacentElement('afterend', donut3dColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderBudgetPieLayer\(row, definition\);[\s\S]*?ensureCommonBudget3dDonutScreen\(row, definition\);/.test(html),
  'Budget mode must duplicate C4 into an adjacent C4B 3D donut screen without replacing the original C4',
);
assert(
  budgetAlt3dDonutFunction.includes('[data-budget-alt-3d-donut-screen="true"]') &&
    budgetAlt3dDonutFunction.includes("definition.mode !== 'budget'") &&
    budgetAlt3dDonutFunction.includes("data-screen', 'alt-common-header-budget-stage2-alt-3d-donut'") &&
    budgetAlt3dDonutFunction.includes("dataset.budgetAlt3dDonutScreen = 'true'") &&
    budgetAlt3dDonutFunction.includes("dataset.budgetPieAlt3dScrollable = 'true'") &&
    budgetAlt3dDonutFunction.includes('C4C ·') &&
    budgetAlt3dDonutFunction.includes("buildCommonBudgetCategoryPieContent({ donutStyle: '3d-alt' })") &&
    budgetAlt3dDonutFunction.includes("donut3dColumn.insertAdjacentElement('afterend', alt3dColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?ensureCommonBudget3dDonutScreen\(row, definition\);[\s\S]*?ensureCommonBudgetAlt3dDonutScreen\(row, definition\);/.test(html),
  'Budget mode must add a second adjacent C4C alternative 3D donut screen after C4B without replacing C4 or C4B',
);
assert(
  budgetInteractive3dDonutFunction.includes('[data-budget-interactive-3d-donut-screen="true"]') &&
    budgetInteractive3dDonutFunction.includes("definition.mode !== 'budget'") &&
    budgetInteractive3dDonutFunction.includes("data-screen', 'alt-common-header-budget-stage2-interactive-3d-donut'") &&
    budgetInteractive3dDonutFunction.includes("dataset.budgetInteractive3dDonutScreen = 'true'") &&
    budgetInteractive3dDonutFunction.includes('C4D ·') &&
    budgetInteractive3dDonutFunction.includes("buildCommonBudgetCategoryPieContent({ donutStyle: '3d-interactive', interactive: true })") &&
    budgetInteractive3dDonutFunction.includes("alt3dColumn.insertAdjacentElement('afterend', interactive3dColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?ensureCommonBudgetAlt3dDonutScreen\(row, definition\);[\s\S]*?ensureCommonBudgetInteractive3dDonutScreen\(row, definition\);/.test(html),
  'Budget mode must add an adjacent C4D interactive 3D donut after C4C without replacing the earlier variants',
);
assert(
  budgetPieSlicesFunction.includes("layer === 'interactive-depth'") &&
    budgetPieSlicesFunction.includes("layer === 'interactive-top'") &&
    budgetPieFunction.includes("donutStyle === '3d-interactive'") &&
    budgetPieFunction.includes('data-budget-pie-slice-target') &&
    budgetPieFunction.includes('data-budget-pie-center-action="all-categories"') &&
    budgetPieFunction.includes('common-budget-pie-donut-3d-interactive') &&
    budgetPieFunction.includes('common-budget-pie-interactive-depth') &&
    budgetPieFunction.includes('common-budget-pie-interactive-top') &&
    budgetPieFunction.includes('common-budget-pie-center-action-label') &&
    budgetPieFunction.includes('role="button"') &&
    budgetPieFunction.includes('tabindex="0"'),
  'C4D must expose separate, keyboard-accessible slice and all-categories centre targets on a distinct stepped 3D donut',
);
assert(
  budgetWhitePieFunction.includes('[data-budget-white-pie-screen="true"]') &&
    budgetWhitePieFunction.includes("definition.mode !== 'budget'") &&
    budgetWhitePieFunction.includes("data-screen', 'alt-common-header-budget-stage2-white-pie'") &&
    budgetWhitePieFunction.includes("dataset.budgetWhitePieScreen = 'true'") &&
    budgetWhitePieFunction.includes("dataset.budgetPieWhiteScrollable = 'true'") &&
    budgetWhitePieFunction.includes('C4W ·') &&
    budgetWhitePieFunction.includes("buildCommonBudgetCategoryPieContent({ panelSurface: 'white-translucent' })") &&
    budgetWhitePieFunction.includes("stage2Column.insertAdjacentElement('afterend', whitePieColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?ensureCommonBudgetInteractive3dDonutScreen\(row, definition\);[\s\S]*?ensureCommonBudgetWhitePieScreen\(row, definition\);/.test(html),
  'Budget mode must add C4W directly after C4, preserving the same category pie data in a distinct translucent-white chart surface',
);
assert(
  budgetPieFunction.includes("panelSurface = 'glass'") &&
    budgetPieFunction.includes('data-panel-surface="${panelSurface}"') &&
    budgetPieFunction.includes('data-donut-style="${donutStyle}"'),
  'Budget pie content must expose a scoped panel-surface option while keeping flat glass as the default C4 rendering',
);
const whitePieSurfaceRuleStart = html.indexOf('    .common-budget-pie-panel[data-panel-surface="white-translucent"]');
const whitePieSurfaceRuleEnd = html.indexOf('\n    }', whitePieSurfaceRuleStart);
const whitePieSurfaceRule = whitePieSurfaceRuleStart >= 0 && whitePieSurfaceRuleEnd >= 0
  ? html.slice(whitePieSurfaceRuleStart, whitePieSurfaceRuleEnd + 6)
  : '';
assert(
  whitePieSurfaceRule.includes('background: rgba(255,255,255,.72);') &&
    whitePieSurfaceRule.includes('border: 1px solid rgba(255,255,255,.66);') &&
    whitePieSurfaceRule.includes('box-shadow: 0 7px 18px rgba(15,23,42,.08);') &&
    whitePieSurfaceRule.includes('-webkit-backdrop-filter: none;') &&
    whitePieSurfaceRule.includes('backdrop-filter: none;') &&
    !whitePieSurfaceRule.includes('gradient') &&
    !whitePieSurfaceRule.includes('blur('),
  'C4W chart surface must be an unblurred, semi-transparent white panel instead of a glass gradient container',
);
assert(
  html.includes('function setCommonBudgetPieInteractiveSelection') &&
    html.includes('function initCommonBudgetPieInteractions') &&
    html.includes("closest('[data-budget-pie-slice-target]')") &&
    html.includes("closest('[data-budget-pie-center-action=\"all-categories\"]')") &&
    html.includes("initCommonBudgetPieInteractions();"),
  'C4D must route slice and centre taps through one local selection state updater',
);
assert(
  /\.common-budget-pie-panel\[data-donut-style="3d"\]\s+\.common-budget-pie-visual\s*\{[\s\S]*?perspective:\s*460px;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-donut-3d\s*\{[\s\S]*?transform:\s*rotateX\(58deg\);[\s\S]*?filter:\s*drop-shadow\(0 18px 18px rgba\(15,23,42,\.20\)\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-3d-side\s*\{[\s\S]*?transform:\s*translateY\(9px\) rotate\(-90deg\);[\s\S]*?opacity:\s*\.52;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-slice\.side\s*\{[\s\S]*?stroke:\s*color-mix\(in srgb,\s*var\(--slice-color\) 62%,\s*#0f172a\);[\s\S]*?stroke-width:\s*17;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-3d-shadow\s*\{[\s\S]*?fill:\s*rgba\(15,23,42,\.18\);[\s\S]*?filter:\s*blur\(4px\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-center-highlight\s*\{[\s\S]*?fill:\s*rgba\(255,255,255,\.38\);[\s\S]*?\}/.test(html),
  'Budget C4B 3D donut CSS must add perspective, side thickness, shadow, and center highlight without changing the flat C4 donut',
);
assert(
  /\.common-budget-pie-panel\[data-donut-style="3d-alt"\]\s+\.common-budget-pie-visual\s*\{[\s\S]*?perspective:\s*520px;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-donut-3d-alt\s*\{[\s\S]*?transform:\s*rotateX\(48deg\) rotateZ\(-8deg\);[\s\S]*?filter:\s*drop-shadow\(0 22px 18px rgba\(15,23,42,\.22\)\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-3d-alt-depth\s*\{[\s\S]*?transform:\s*translate\(5px,\s*11px\) rotate\(-90deg\);[\s\S]*?opacity:\s*\.60;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-slice\.alt-depth\s*\{[\s\S]*?stroke:\s*color-mix\(in srgb,\s*var\(--slice-color\) 54%,\s*#0f172a\);[\s\S]*?stroke-width:\s*19;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-3d-alt-pop\s*\{[\s\S]*?transform:\s*translate\(-6px,\s*-7px\) rotate\(-90deg\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-slice\.alt-pop\s*\{[\s\S]*?stroke-width:\s*20;[\s\S]*?filter:\s*drop-shadow\(0 0 10px var\(--slice-color\)\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-3d-alt-highlight\s*\{[\s\S]*?stroke:\s*rgba\(255,255,255,\.62\);[\s\S]*?opacity:\s*\.74;[\s\S]*?\}/.test(html),
  'Budget C4C alternative 3D donut CSS must use a distinct tilted floating raised-slice treatment',
);
assert(
  /.common-budget-pie-panel\[data-donut-style="3d-interactive"\]\s+\.common-budget-pie-visual\s*\{[\s\S]*?perspective:\s*660px;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-donut-3d-interactive\s*\{[\s\S]*?transform:\s*rotateX\(63deg\) rotateZ\(10deg\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-interactive-depth\s*\{[\s\S]*?transform:\s*translate\(-3px,\s*13px\) rotate\(-90deg\);[\s\S]*?opacity:\s*\.74;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-interactive-pop\s*\{[\s\S]*?transform:\s*translate\(-4px,\s*-8px\) rotate\(-90deg\);[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-panel\[data-donut-style="3d-interactive"\]\s+\[data-budget-pie-slice-target\]\s*\{[\s\S]*?cursor:\s*pointer;[\s\S]*?pointer-events:\s*stroke;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-panel\[data-donut-style="3d-interactive"\]\s+\[data-budget-pie-center-action\]\s*\{[\s\S]*?cursor:\s*pointer;[\s\S]*?\}/.test(html),
  'C4D CSS must use a separate stepped 3D geometry and explicit touch targets for slices and centre',
);
assert(
  /function syncCommonHeaderBudgetPieLayer\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'budget'[\s\S]*?dataset\.stage2Scrollable = 'true'[\s\S]*?dataset\.budgetPieScrollable = 'true'[\s\S]*?buildCommonBudgetCategoryPieContent\(\)[\s\S]*?insertAdjacentHTML/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\)[\s\S]*?syncCommonHeaderBudgetPieLayer\(row, definition\)/.test(html),
  'Runtime C rows must attach the pie layer only to Budget stage2 after stage1 cloning and make that stage2 area scrollable',
);
const balanceStage1GlassFunctionStart = html.indexOf('function ensureCommonBalanceStage1GlassScreen');
const balanceStage1GlassFunction = balanceStage1GlassFunctionStart >= 0
  ? html.slice(balanceStage1GlassFunctionStart, html.indexOf('function syncCommonBudgetCorePartition'))
  : '';
assert(
  balanceStage1GlassFunction.includes('[data-balance-stage1-glass-screen="true"]') &&
    balanceStage1GlassFunction.includes("definition.mode !== 'balance'") &&
    balanceStage1GlassFunction.includes('[data-screen="alt-common-header-stage1"]') &&
    balanceStage1GlassFunction.includes("data-screen', 'alt-common-header-stage1-glass-fastinfo'") &&
    balanceStage1GlassFunction.includes("dataset.balanceStage1GlassScreen = 'true'") &&
    balanceStage1GlassFunction.includes("dataset.balanceStage1GlassFastinfo = 'true'") &&
    balanceStage1GlassFunction.includes('B2G ·') &&
    balanceStage1GlassFunction.includes("stage1Column.insertAdjacentElement('afterend', glassColumn)") &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderStage2Stage1Layer\(row\);[\s\S]*?ensureCommonBalanceStage1GlassScreen\(row, definition\);[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\);/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="balance"\]\s+\[data-balance-stage1-glass-fastinfo="true"\]\s+\.common-balance-stage1-card-grid \.fastinfo-chart-card\s*\{[\s\S]*?background:\s*radial-gradient\(circle at 14% 8%, rgba\(255,255,255,\.38\), transparent 40%\),[\s\S]*?linear-gradient\(180deg, rgba\(255,255,255,\.30\), rgba\(255,255,255,\.10\)\);[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.24\);[\s\S]*?backdrop-filter:\s*blur\(16px\);[\s\S]*?\}/.test(html),
  'B2 alternate must clone B2 beside the original and scope glass material to all B2 fastinfo cards without leaking to other modes',
);
assert(
  /function syncCommonHeaderStage2Stage1Layer\(row\) \{[\s\S]*?clonedLayer\.dataset\.stage2CloneMode = row\.dataset\.commonHeaderModeRow \|\| '';[\s\S]*?if \(row\.dataset\.commonHeaderModeRow === 'budget'\) \{[\s\S]*?clonedLayer\.dataset\.stage2BudgetAvatars = 'true';[\s\S]*?\}/.test(html) &&
    /\.common-stage2-stage1-layer\.common-budget-stage1-layer\s*\{[\s\S]*?height:\s*130px;[\s\S]*?z-index:\s*4;[\s\S]*?\}/.test(html) &&
    /\.common-budget-pie-stage2-layer\s*\{[\s\S]*?z-index:\s*3;[\s\S]*?\}/.test(html),
  'C3 budget stage2 must explicitly preserve the cloned avatar glossy sheet above the pie/scroll layer',
);
assert(
  /definition\.mode === 'budget'[\s\S]*?stage1Subvalue\?\.remove\(\)[\s\S]*?insertAdjacentHTML\('beforebegin', budgetGlossyContent\)/.test(html),
  'C2 budget stage1 must move spent/remaining into the glossy container and insert that container before the handle, avoiding duplicate text outside the container',
);
assert(
  /function applyCommonHeaderModeGradient\(mode,\s*gradient\) \{[\s\S]*?querySelectorAll[\s\S]*?data-common-header-mode[\s\S]*?--spendee-header-bg[\s\S]*?--spendee-header-glow/.test(html),
  'Common-header slider updates must write scoped header background/glow variables on the target mode row only',
);
assert(
  /function updateLimitsScalePreview\(\) \{[\s\S]*?applyCommonHeaderModeGradient\('balance', limitsGradient\)[\s\S]*?updateSpendeeBalanceInk\(\)/.test(html) &&
    /function updateCoolHeaderFromScale\(\) \{[\s\S]*?applyCommonHeaderModeGradient\('budget', coolGradient\)[\s\S]*?updateSpendeeBalanceInk\(\)/.test(html) &&
    /function updateBalanceHeaderFromScale\(\) \{[\s\S]*?applyCommonHeaderModeGradient\('mind', headerGradient\)[\s\S]*?updateSpendeeBalanceInk\(\)/.test(html),
  'Purple/pink, white/blue, and red/green sliders must target balance, budget, and mind modes respectively',
);
assert(
  alternativeSection.indexOf('data-section-row="main-menu"') <
    alternativeSection.indexOf('data-section-row="common-header-dashboard"') &&
    alternativeSection.indexOf('data-section-row="common-header-dashboard"') <
      alternativeSection.indexOf('id="balanceHeaderScaleLab"') &&
    alternativeSection.indexOf('data-screen="alt-common-header-stage0"') <
      alternativeSection.indexOf('data-screen="alt-common-header-stage1"') &&
    alternativeSection.indexOf('data-screen="alt-common-header-stage1"') <
      alternativeSection.indexOf('data-screen="alt-common-header-stage2"'),
  'B row must be inserted under the A/main-menu row and before the balance/palette labs, ordered as stage 0, stage 1, stage 2',
);
const commonHeaderStage0 = commonHeaderRow.slice(
  commonHeaderRow.indexOf('data-screen="alt-common-header-stage0"'),
  commonHeaderRow.indexOf('data-screen="alt-common-header-stage1"'),
);
const commonHeaderStage1 = commonHeaderRow.slice(
  commonHeaderRow.indexOf('data-screen="alt-common-header-stage1"'),
  commonHeaderRow.indexOf('data-screen="alt-common-header-stage2"'),
);
const commonHeaderStage2MotherChildStart = commonHeaderRow.indexOf(
  'data-screen="alt-common-header-stage2-mother-child"',
);
const commonHeaderStage2 = commonHeaderRow.slice(
  commonHeaderRow.indexOf('data-screen="alt-common-header-stage2"'),
  commonHeaderStage2MotherChildStart,
);
const commonHeaderStage2MotherChild = commonHeaderRow.slice(commonHeaderStage2MotherChildStart);
assert(
  commonHeaderStage0 && commonHeaderStage1 && commonHeaderStage2 && commonHeaderStage2MotherChild,
  'B row must contain its three common-header stage blocks and the adjacent B3M mother-child preview',
);
assert(
  commonHeaderStage0.includes('data-common-header-state="collapsed"') &&
    commonHeaderStage0.includes('data-common-header-snap="0"') &&
    commonHeaderStage0.includes('data-stage-source="A1-copy"') &&
    commonHeaderStage0.includes('class="common-header-card common-header-stage0"') &&
    commonHeaderStage0.includes('data-balance-insight-stage0') &&
    commonHeaderStage0.includes('data-balance-insight-line="single"') &&
    commonHeaderStage0.includes('class="common-balance-insight-line"') &&
    commonHeaderStage0.includes('Balance') &&
    commonHeaderStage0.includes('-372 047 472 Ft') &&
    commonHeaderStage0.includes('class="type-pill active income-type-pill"') &&
    commonHeaderStage0.includes('class="summary-pill"') &&
    commonHeaderStage0.includes('class="search-pill"') &&
    !commonHeaderStage0.includes('class="common-context-carousel"') &&
    !commonHeaderStage0.includes('class="common-fastinfo-area"') &&
    !commonHeaderStage0.includes('data-focus-mode-stage2="balance-income-expense"') &&
    !commonHeaderStage0.includes('class="common-focus-income-expense-graph"'),
  'B1 stage 0 must copy the A1 collapsed dashboard shell and keep context/fastinfo layers hidden from the DOM block',
);
assert(
  commonHeaderStage1.includes('data-common-header-state="context"') &&
    commonHeaderStage1.includes('data-common-header-snap="1"') &&
    commonHeaderStage1.includes('data-context-layer="front-backheader"') &&
    commonHeaderStage1.includes('data-gesture-y="snap-expand-collapse"') &&
    commonHeaderStage1.includes('data-haptic="tick"') &&
    commonHeaderStage1.includes('data-focus-mode-stage1="balance-reserve-summary"') &&
    commonHeaderStage1.includes('class="common-balance-stage1-plain"') &&
    commonHeaderStage1.includes('data-balance-insight-stage0') &&
    commonHeaderStage1.includes('data-balance-insight-line="single"') &&
    commonHeaderStage1.includes('class="common-balance-insight-line"') &&
    commonHeaderStage1.includes('Tartalék') &&
    !commonHeaderStage1.includes('class="common-balance-reserve-progress"') &&
    !commonHeaderStage1.includes('data-balance-progress="reserve"') &&
    !commonHeaderStage1.includes('data-balance-history-visual="black"') &&
    !commonHeaderStage1.includes('class="common-balance-history-card"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-row"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-title"') &&
    commonHeaderStage1.includes('balance arány') &&
    commonHeaderStage1.includes('data-balance-ratio-placement="reserve-progress-slot"') &&
    commonHeaderStage1.indexOf('class="common-balance-reserve-label"') <
      commonHeaderStage1.indexOf('data-balance-ratio-placement="reserve-progress-slot"') &&
    commonHeaderStage1.indexOf('data-balance-ratio-placement="reserve-progress-slot"') <
      commonHeaderStage1.indexOf('class="common-balance-stage1-card-grid"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-metrics"') &&
    commonHeaderStage1.includes('data-balance-ratio-metric="income"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-value income"') &&
    commonHeaderStage1.includes('32%') &&
    commonHeaderStage1.includes('bevétel') &&
    commonHeaderStage1.includes('data-balance-ratio-metric="expense"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-value expense"') &&
    commonHeaderStage1.includes('68%') &&
    commonHeaderStage1.includes('kiadás') &&
    !commonHeaderStage1.includes('data-balance-ratio-placement="right-fastinfo-card"') &&
    !commonHeaderStage1.includes('data-fastinfo-card="balance-ratio"') &&
    commonHeaderStage1.includes('data-fastinfo-card="balance-placeholder"') &&
    commonHeaderStage1.includes('common-balance-placeholder-card') &&
    commonHeaderStage1.includes('class="common-balance-stage1-card-grid"') &&
    (commonHeaderStage1.match(/class="fastinfo-chart-card/g) || []).length === 3 &&
    commonHeaderStage1.includes('Havi kiadás') &&
    commonHeaderStage1.includes('Legnagyobb kiadás') &&
    commonHeaderStage1.includes('Balance arány') &&
    !commonHeaderStage1.includes('data-focus-mode-stage1="balance-income-expense"') &&
    !commonHeaderStage1.includes('class="common-focus-income-expense-graph"') &&
    !commonHeaderStage1.includes('class="common-income-expense-svg"') &&
    !commonHeaderStage1.includes('class="common-balance-ratio-number"') &&
    !commonHeaderStage1.includes('32 / 68') &&
    !commonHeaderStage1.includes('class="common-header-subvalue"') &&
    !commonHeaderStage1.includes('data-focus-mode-stage1="balance-avatar-gloss"') &&
    !commonHeaderStage1.includes('class="common-focus-avatar-stack"') &&
    !commonHeaderStage1.includes('class="common-stage1-avatar-strip"') &&
    (commonHeaderStage1.match(/class="common-context-badge/g) || []).length === 0 &&
    !commonHeaderStage1.includes('class="common-context-carousel"') &&
    !commonHeaderStage1.includes('class="common-fastinfo-area"'),
  'B2 stage 1 must render the balance ratio in the former white reserve-progress slot, keep the single-line insight in core, and replace the right fastinfo card content with a placeholder',
);
assert(
  commonHeaderStage2.includes('data-common-header-state="fastinfo"') &&
    commonHeaderStage2.includes('data-common-header-snap="2"') &&
    commonHeaderStage2.includes('data-header-content="balance-only"') &&
    commonHeaderStage2.includes('class="common-header-card common-header-stage2"') &&
    commonHeaderStage2.includes('Balance') &&
    commonHeaderStage2.includes('-372 047 472 Ft') &&
    !commonHeaderStage2.includes('class="common-context-carousel"') &&
    !commonHeaderStage2.includes('data-context-position="header-bottom"') &&
    !commonHeaderStage2.includes('class="common-context-badge"') &&
    !commonHeaderStage2.includes('class="common-fastinfo-area"') &&
    !commonHeaderStage2.includes('class="common-header-subvalue"') &&
    !commonHeaderStage2.includes('class="common-header-eye"') &&
    commonHeaderStage2.includes('data-stage2-includes-stage1="true"') &&
    commonHeaderStage2.includes('class="common-focus-layer common-stage2-stage1-layer"') &&
    commonHeaderStage2.includes('data-focus-mode-stage1="balance-reserve-summary"') &&
    commonHeaderStage2.includes('data-balance-insight-stage0') &&
    commonHeaderStage2.includes('data-balance-insight-line="single"') &&
    commonHeaderStage2.includes('class="common-balance-insight-line"') &&
    !commonHeaderStage2.includes('class="common-balance-reserve-progress"') &&
    !commonHeaderStage2.includes('data-balance-history-visual="black"') &&
    !commonHeaderStage2.includes('class="common-balance-history-card"') &&
    commonHeaderStage2.includes('class="common-balance-ratio-row"') &&
    commonHeaderStage2.includes('data-balance-ratio-placement="reserve-progress-slot"') &&
    !commonHeaderStage2.includes('data-balance-ratio-placement="right-fastinfo-card"') &&
    !commonHeaderStage2.includes('data-fastinfo-card="balance-ratio"') &&
    commonHeaderStage2.includes('data-fastinfo-card="balance-placeholder"') &&
    commonHeaderStage2.includes('common-balance-placeholder-card') &&
    commonHeaderStage2.includes('balance arány') &&
	    commonHeaderStage2.includes('class="common-balance-stage1-card-grid"') &&
	    (commonHeaderStage2.match(/class="fastinfo-chart-card/g) || []).length === 3 &&
	    commonHeaderStage2.includes('Havi kiadás') &&
	    commonHeaderStage2.includes('Legnagyobb kiadás') &&
	    commonHeaderStage2.includes('Balance arány') &&
	    commonHeaderStage2.includes('data-stage2-extra="balance-diagnostics"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-panel="scrollable"') &&
	    commonHeaderStage2.indexOf('data-stage2-includes-stage1="true"') <
	      commonHeaderStage2.indexOf('data-stage2-extra="balance-diagnostics"') &&
	    commonHeaderStage2.includes('Pénzügyi állapot') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="reserve"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="balance-ratio"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="savings-rate"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="buffer"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="forecast"') &&
	    commonHeaderStage2.includes('data-balance-diagnostic-row="ghost-income"') &&
	    commonHeaderStage2.includes('0,42 hó') &&
	    commonHeaderStage2.includes('0,77') &&
	    commonHeaderStage2.includes('12%') &&
	    commonHeaderStage2.includes('-18 670 Ft') &&
	    commonHeaderStage2.includes('-106 350 Ft') &&
	    commonHeaderStage2.includes('42 000 Ft') &&
	    !commonHeaderStage2.includes('data-focus-mode-stage2="balance-income-expense"') &&
	    !commonHeaderStage2.includes('class="common-stage2-income-expense-layer"') &&
	    !commonHeaderStage2.includes('common-stage2-graph-stack') &&
    !commonHeaderStage2.includes('data-graph-count="3"') &&
    !commonHeaderStage2.includes('class="common-header-menu"') &&
    commonHeaderStage2.includes('class="common-header-expand-handle"'),
	  'B3 stage 2 must keep the B2-aligned reserve/card stage1 clone and add the feasible scrollable Balance diagnostics panel below it',
	);
	assert(
	  !/\.common-balance-reserve-progress\s*\{/.test(html) &&
	    !/\.common-balance-stage1-card-grid \.common-balance-ratio-row\s*\{/.test(html) &&
	    /\.common-balance-insight-line\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?bottom:\s*13px;[\s\S]*?height:\s*24px;[\s\S]*?\}/.test(html) &&
	    /\.common-balance-insight-line-path\s*\{[\s\S]*?stroke:\s*rgba\(255,255,255,\.90\);[\s\S]*?\}/.test(html) &&
	    /\.common-balance-ratio-row\[data-balance-ratio-placement="reserve-progress-slot"\]\s*\{[\s\S]*?position:\s*static;[\s\S]*?grid-template-columns:\s*1fr auto;[\s\S]*?\}/.test(html) &&
	    /\.common-balance-diagnostics-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?top:\s*calc\(96px \+ \(var\(--common-header-stage1-h\) - 114px\) \+ 12px\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?overscroll-behavior:\s*contain;[\s\S]*?\}/.test(html) &&
	    /\.common-balance-diagnostic-panel\s*\{[\s\S]*?border-radius:\s*17px;[\s\S]*?backdrop-filter:\s*blur\(12px\);[\s\S]*?\}/.test(html) &&
	    /\.common-balance-diagnostic-row\s*\{[\s\S]*?grid-template-columns:\s*42px 1fr auto 14px;[\s\S]*?\}/.test(html) &&
	    /\.common-pattern-bar\.income\s*\{[\s\S]*?fill:\s*rgba\(34,197,94,[\s\S]*?\}/.test(html) &&
	    /\.common-pattern-bar\.expense\s*\{[\s\S]*?fill:\s*rgba\(239,68,68,[\s\S]*?\}/.test(html),
	  'B2/B3 ratio and B3 diagnostics CSS must support the feasible balance stage2 layout while split graph colors remain available for D2-D4',
	);
assert.strictEqual(
  (commonHeaderRow.match(/class="common-header-menu"/g) || []).length,
  0,
  'The three source common-header states must not render the old top-right glossy category menu button',
);
assert.strictEqual(
  (commonHeaderModeArea.match(/class="common-header-menu"/g) || []).length,
  0,
  'B/C/D common-header mode area must not contain any top-right glossy category menu buttons',
);
assert.strictEqual(
  (commonHeaderRow.match(/class="common-header-eye"/g) || []).length,
  0,
  'The common-header source states must not render a separate eye button; the single menu button is the only header control',
);
assert.strictEqual(
  [commonHeaderStage0, commonHeaderStage1, commonHeaderStage2].reduce(
    (count, screenBlock) => count + (screenBlock.match(/class="common-header-expand-handle"/g) || []).length,
    0,
  ),
  3,
  'Every source common-header state must render the small white pull handle at the card bottom',
);

function assertCommonHeaderA1ContentStack(screenBlock, label, expectedLogboxCount) {
  assert(
    screenBlock.includes('data-content-stack="a1-under-header"') &&
      screenBlock.includes('data-spacing-source="A1"') &&
      screenBlock.includes('class="type-row"') &&
      screenBlock.includes('class="summary-pill"') &&
      screenBlock.includes('class="search-pill"') &&
      screenBlock.includes('class="transaction-list-header"') &&
      screenBlock.includes('class="log-area"') &&
      screenBlock.includes('class="date-header"') &&
      screenBlock.includes('2026.07.11'),
    `${label} must render the complete A1 under-header content stack`,
  );
  assert.strictEqual(
    (screenBlock.match(/<article class="logbox"/g) || []).length,
    expectedLogboxCount,
    `${label} must render ${expectedLogboxCount} A1-style logboxes so the visible lower phone area is filled correctly`,
  );
  assert(
    screenBlock.indexOf('class="type-row"') <
      screenBlock.indexOf('class="summary-pill"') &&
      screenBlock.indexOf('class="summary-pill"') <
        screenBlock.indexOf('class="search-pill"') &&
      screenBlock.indexOf('class="search-pill"') <
        screenBlock.indexOf('class="transaction-list-header"') &&
      screenBlock.indexOf('class="transaction-list-header"') <
        screenBlock.indexOf('class="log-area"'),
    `${label} must keep the A1 component order/spacing sequence; only the common-header-home-content top changes`,
  );
}
assertCommonHeaderA1ContentStack(commonHeaderStage0, 'B1 stage 0', 7);
assertCommonHeaderA1ContentStack(commonHeaderStage1, 'B2 stage 1', 7);
assertCommonHeaderA1ContentStack(commonHeaderStage2, 'B3 stage 2', 5);
assert(
  commonHeaderStage0.includes('data-bottom-fill="transaction-log"') &&
    commonHeaderStage1.includes('data-bottom-fill="transaction-log"') &&
    !commonHeaderStage2.includes('data-bottom-fill="transaction-log"'),
  'B1/B2 must explicitly fill the old bottom-nav area with transaction logs; B3 remains safety-cropped at the search pill',
);
assert(
  commonHeaderStage0.includes('class="bottom-nav common-header-bottom-nav"') &&
    commonHeaderStage1.includes('class="bottom-nav common-header-bottom-nav"') &&
    commonHeaderStage2.includes('class="bottom-nav common-header-bottom-nav"'),
  'B row screens must render the restored common-header bottom nav',
);
assert(
  /\.common-header-stage0 \{[\s\S]*?height:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-stage1 \{[\s\S]*?height:\s*var\(--common-header-stage1-h\);/.test(html) &&
    /\.common-header-stage2 \{[\s\S]*?--common-header-h:\s*var\(--common-header-stage2-expanded-h\);[\s\S]*?height:\s*var\(--common-header-stage2-expanded-h\);/.test(html) &&
    /\.common-header-expand-handle \{[\s\S]*?bottom:\s*7px;[\s\S]*?background:\s*rgba\(255,255,255,\.86\);/.test(html) &&
    /\.spendee-dashboard-screen\.common-header-screen \.common-header-home-content \{[\s\S]*?top:\s*calc\(var\(--common-header-active-top\) \+ var\(--common-header-active-h\) \+ var\(--common-header-content-gap\)\);/.test(html),
  'B-row CSS must model the three common header snap heights, bottom handle, and pushed-down content without requiring a stage3 avatar carousel',
);
assert(
  /\.common-header-stage0-screen \.common-header-home-content,\s*\n\s*\.common-header-stage1-screen \.common-header-home-content \{[\s\S]*?bottom:\s*var\(--bottom-nav-h\);/.test(html) &&
    /\.common-header-stage0-screen \.log-area,\s*\n\s*\.common-header-stage1-screen \.log-area \{[\s\S]*?bottom:\s*0;[\s\S]*?padding-bottom:\s*16px;/.test(html),
  'B1/B2 must stop their content above the restored bottom nav while keeping the log area internally bottom-filled',
);
assert(
  /\.common-header-screen \{[\s\S]*?--common-header-content-gap:\s*calc\(var\(--spendee-content-top\) - var\(--spendee-header-top\) - var\(--spendee-header-h\)\);[\s\S]*?--common-header-active-h:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-active-top:\s*var\(--spendee-header-top\);/.test(html) &&
    /\.common-header-stage0-screen \{[\s\S]*?--common-header-active-h:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-stage1-screen \{[\s\S]*?--common-header-active-h:\s*var\(--common-header-stage1-h\);/.test(html) &&
    /\.common-header-stage2-screen \{[\s\S]*?--common-header-active-h:\s*var\(--common-header-stage2-expanded-h\);[\s\S]*?--common-header-active-top:\s*var\(--spendee-header-top\);/.test(html) &&
    !/\.common-header-stage1-screen \.common-header-home-content \{[\s\S]*?\+ 246px/.test(html) &&
    !/\.common-header-stage2-screen \.common-header-home-content \{[\s\S]*?\+ 444px/.test(html),
  'B-row content must be anchored to current header bottom plus the original A1 4px gap, not arbitrary stage offsets',
);
assert(
  /\.common-header-card \{[\s\S]*?top:\s*var\(--common-header-active-top\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-a5-submit-safe-top:\s*calc\(var\(--screen-h\) - 18px\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-bottom-anchor:\s*calc\(var\(--screen-h\) - var\(--bottom-nav-h\)\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-safety-top:\s*calc\(var\(--common-header-stage2-bottom-anchor\) - var\(--common-header-search-top-gap\)\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-visible-stack-h:\s*calc\(var\(--spendee-type-row-h\) \+ var\(--common-header-summary-visible-h\) \+ var\(--common-header-search-top-gap\) \+ var\(--common-header-search-visible-h\)\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-expanded-h:\s*calc\(var\(--common-header-stage2-safety-top\) - var\(--spendee-header-top\) - var\(--common-header-content-gap\) - var\(--common-header-stage2-visible-stack-h\)\);/.test(html) &&
    !html.includes('--common-header-stage2-lower-shift') &&
    /\.common-header-stage2-screen \.common-header-home-content \{[\s\S]*?bottom:\s*calc\(var\(--screen-h\) - var\(--common-header-stage2-safety-top\)\);[\s\S]*?overflow:\s*hidden;/.test(html),
  'B3 stage 2 must keep the header top fixed, expand header height downward to one search-gap above the restored bottom-nav top, and clip everything below the search pill',
);
assert(
  /\.common-header-screen::after \{[\s\S]*?height:\s*calc\(var\(--spendee-header-glow-h\) \+ var\(--common-header-active-h\) - var\(--spendee-header-h\)\);/.test(html) &&
    commonHeaderRow.includes('class="phone-screen spendee-dashboard-screen common-header-screen common-header-stage2-screen"') &&
    /\.common-header-card::before \{[\s\S]*?var\(--spendee-header-bg/.test(html) &&
    /\.common-header-card::before \{[\s\S]*?--common-header-gloss-x[\s\S]*?--common-header-gloss-y[\s\S]*?var\(--spendee-header-gloss-accent/.test(html) &&
    /\.common-header-card::before \{[\s\S]*?opacity:\s*var\(--spendee-header-opacity\);/.test(html) &&
    !/\.common-header-card::before \{[\s\S]*?rgba\(246,128,232,\.40\)/.test(html) &&
    !/\.common-header-card::before \{[\s\S]*?linear-gradient\(135deg, rgba\(255,111,166,\.92\)/.test(html),
  'B common headers must use a reactive glass gloss anchored to the mini-header menu position, without a hardcoded purple/old color layer',
);
assert(
  /\.common-header-mode\[data-common-header-mode="mind"\]\s+\.common-header-card\[data-mind-portal-touch="true"\]\s*\{[\s\S]*?--mind-portal-touch-x:\s*50%;[\s\S]*?--mind-portal-touch-y:\s*50%;[\s\S]*?--mind-portal-touch-opacity:\s*0;[\s\S]*?\}/.test(html) &&
    /\.common-mind-portal-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*-18px;[\s\S]*?z-index:\s*1;[\s\S]*?pointer-events:\s*none;[\s\S]*?mix-blend-mode:\s*screen;[\s\S]*?\}/.test(html) &&
    /@property --mind-header-gradient-axis\s*\{[\s\S]*?syntax:\s*"<angle>";[\s\S]*?initial-value:\s*112deg;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s*\{[\s\S]*?--mind-header-gradient-axis:\s*112deg;[\s\S]*?--mind-header-left-color:[\s\S]*?--mind-header-center-color:[\s\S]*?--mind-header-right-color:[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\.common-header-card::before\s*\{[\s\S]*?linear-gradient\(var\(--mind-header-gradient-axis\),\s*var\(--mind-header-left-color\) 0%,\s*var\(--mind-header-center-color\) 50%,\s*var\(--mind-header-right-color\) 100%\)[\s\S]*?var\(--spendee-header-bg[\s\S]*?animation:\s*mindHeaderValueWater 28s[\s\S]*?\}/.test(html) &&
    /@keyframes mindHeaderValueWater\s*\{[\s\S]*?--mind-header-gradient-axis:\s*112deg;[\s\S]*?--mind-header-gradient-axis:\s*292deg;[\s\S]*?--mind-header-gradient-axis:\s*472deg;[\s\S]*?\}/.test(html) &&
    !/@keyframes mindHeaderValueWater\s*\{[\s\S]*?transform:\s*rotate[\s\S]*?@keyframes mindPortalTrailFade/.test(html) &&
    /function setMindHeaderGradientStops\(target, gradient\) \{[\s\S]*?linear-gradient[\s\S]*?--mind-header-left-color[\s\S]*?--mind-header-center-color[\s\S]*?--mind-header-right-color[\s\S]*?\}/.test(html) &&
    /function applyCommonHeaderModeGradient\(mode,\s*gradient\) \{[\s\S]*?if \(mode === 'mind'\) \{[\s\S]*?setMindHeaderGradientStops\(modeSection, gradient\)/.test(html) &&
    /\.common-mind-portal-layer\s*\{(?:(?!background:)[\s\S])*?contain:\s*paint;[\s\S]*?\}/.test(html) &&
    /\.common-mind-portal-layer::before\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?animation:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-mind-portal-layer::after\s*\{[\s\S]*?radial-gradient\(circle at var\(--mind-portal-touch-x\) var\(--mind-portal-touch-y\),\s*rgba\(255,167,226,calc\(\.98 \* var\(--mind-portal-interaction-alpha, 1\)\)\) 0%, rgba\(255,139,218,calc\(\.86 \* var\(--mind-portal-interaction-alpha, 1\)\)\) 5%, rgba\(139,62,255,calc\(\.76 \* var\(--mind-portal-interaction-alpha, 1\)\)\) 11%, rgba\(255,255,255,calc\(\.46 \* var\(--mind-portal-interaction-alpha, 1\)\)\) 19%, transparent 25%\)[\s\S]*?opacity:\s*var\(--mind-portal-touch-opacity\)[\s\S]*?filter:\s*blur\(var\(--mind-portal-touch-blur\)\)[\s\S]*?transition:[\s\S]*?opacity[\s\S]*?\}/.test(html) &&
    !/\.common-mind-portal-layer\s*\{[\s\S]*?rgba\(67,21,146/.test(html) &&
    !/\.common-mind-portal-layer::before\s*\{[\s\S]*?rgba\(255,57,194/.test(html) &&
    /function initCommonHeaderMindPortalTouch\(\) \{[\s\S]*?querySelectorAll\('\[data-common-header-mode="mind"\] \.common-header-card'\)[\s\S]*?data-mind-portal-touch[\s\S]*?data-mind-portal-layer[\s\S]*?--mind-portal-touch-x[\s\S]*?--mind-portal-touch-y[\s\S]*?--mind-portal-touch-opacity[\s\S]*?setPointerCapture[\s\S]*?pointermove[\s\S]*?pointerup[\s\S]*?pointercancel/.test(html) &&
    /initCommonHeaderModeRows\(\);[\s\S]*?moveQueryMenuRowToTop\(\);[\s\S]*?initCommonHeaderMindPortalTouch\(\);[\s\S]*?focusQueryMenuQ1AOnLoad\(\);/.test(html) &&
    !/document\.querySelectorAll\('\.common-header-card'\)[\s\S]*?data-mind-portal-touch/.test(html),
  'D/Mind common-header cards must get a separate touch-sensitive portal layer with idle vortex motion and pointer-following pink/purple bloom without attaching it to B/C rows or changing the value-locked base gradient',
);
const genericSpendeeLogboxRuleIndex = html.indexOf('.spendee-dashboard-screen .logbox {');
const d1NeutralSoftFrostLogboxRuleIndex = html.indexOf(
  '[data-d1-glass-demo="header-strong-logbox-soft"] .logbox[data-d1-logbox-surface="neutral-soft-frost-readable"]',
  genericSpendeeLogboxRuleIndex,
);
const d1NeutralSoftFrostLogboxRule =
  d1NeutralSoftFrostLogboxRuleIndex >= 0
    ? html.slice(
        d1NeutralSoftFrostLogboxRuleIndex,
        html.indexOf('\n    }', d1NeutralSoftFrostLogboxRuleIndex) + 7,
      )
    : '';
const c2ConvexBadgeRule =
  html.match(
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.common-stage1-avatar-strip\[data-context-selector="category-carousel"\]\s+\.common-context-badge\s*\{[\s\S]*?\n    \}/,
  )?.[0] || '';
const c1c2LogboxAvatarLensRule =
  html.match(
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage0"\]\s+\.logbox-avatar-circle,\s*\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.logbox-avatar-circle\s*\{[\s\S]*?\n    \}/,
  )?.[0] || '';
assert(
  /if \(definition\.mode === 'mind' && index === 0\) \{[\s\S]*?screen\.dataset\.d1GlassDemo = 'header-strong-logbox-soft'[\s\S]*?setAttribute\('data-d1-header-surface', 'strong-glass-energy'\)/.test(
    html,
  ) &&
    /else \{[\s\S]*?delete screen\.dataset\.d1GlassDemo[\s\S]*?removeAttribute\('data-d1-header-surface'\)[\s\S]*?removeAttribute\('data-d1-logbox-surface'\)/.test(
      html,
    ) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-glass-demo="header-strong-logbox-soft"\]\s+\.common-header-card\[data-d1-header-surface="strong-glass-energy"\]\s*\{[\s\S]*?border-color:\s*rgba\(255,255,255,\.78\);[\s\S]*?-webkit-backdrop-filter:\s*blur\(26px\) saturate\(1\.36\);[\s\S]*?backdrop-filter:\s*blur\(26px\) saturate\(1\.36\);[\s\S]*?\}/.test(
      html,
    ) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-glass-demo="header-strong-logbox-soft"\]\s+\.common-header-card\[data-d1-header-surface="strong-glass-energy"\]::before\s*\{[\s\S]*?radial-gradient\(circle at 18% 18%, rgba\(255,255,255,\.72\), transparent 31%\)[\s\S]*?linear-gradient\(var\(--mind-header-gradient-axis\),\s*var\(--mind-header-left-color\) 0%,\s*var\(--mind-header-center-color\) 50%,\s*var\(--mind-header-right-color\) 100%\)[\s\S]*?\}/.test(
      html,
    ),
  'Mind D1 must keep the strong glass/energy header scoped to D1',
);
assert(
  /if \(definition\.mode === 'mind' && index === 0\) \{[\s\S]*?setAttribute\('data-d1-logbox-surface', 'neutral-soft-frost-readable'\)/.test(
    html,
  ) &&
    /else \{[\s\S]*?removeAttribute\('data-d1-logbox-surface'\)/.test(html) &&
    genericSpendeeLogboxRuleIndex >= 0 &&
    d1NeutralSoftFrostLogboxRuleIndex > genericSpendeeLogboxRuleIndex &&
    d1NeutralSoftFrostLogboxRule.includes('linear-gradient(135deg, rgba(255,255,255,.88), rgba(255,255,255,.70))') &&
    d1NeutralSoftFrostLogboxRule.includes('rgba(255,255,255,.76)') &&
    d1NeutralSoftFrostLogboxRule.includes('border: 1px solid rgba(255,255,255,.86);') &&
    d1NeutralSoftFrostLogboxRule.includes('0 12px 26px rgba(15,23,42,.075)') &&
    d1NeutralSoftFrostLogboxRule.includes('inset 0 1px 0 rgba(255,255,255,.72)') &&
    d1NeutralSoftFrostLogboxRule.includes('-webkit-backdrop-filter: blur(10px) saturate(1.08);') &&
    d1NeutralSoftFrostLogboxRule.includes('backdrop-filter: blur(10px) saturate(1.08);') &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-glass-demo="header-strong-logbox-soft"\]\s+\.logbox\[data-d1-logbox-surface="neutral-soft-frost-readable"\]::after\s*\{[\s\S]*?height:\s*42%;[\s\S]*?rgba\(255,255,255,\.34\)/.test(
      html,
    ) &&
    !d1NeutralSoftFrostLogboxRule.includes('rgba(53,199,110') &&
    !d1NeutralSoftFrostLogboxRule.includes('mask-image') &&
    !html.includes('data-d1-logbox-surface="budget-glossy-category-carousel"') &&
    !html.includes('data-d1-logbox-surface="soft-frosted-readable"'),
  'Mind D1 logboxes must return to the neutral earlier soft-frost idea without green gloss or the C2 colored-background glossy material',
);
assert(
  /@font-face\s*\{[\s\S]*?font-family:\s*'SchedeeOutfit';[\s\S]*?src:\s*url\('\.\/schedee_outfit_variable\.ttf'\)\s*format\('truetype'\);[\s\S]*?font-weight:\s*100 900;[\s\S]*?\}/.test(html) &&
    html.includes("--schedee-brand-font: 'SchedeeOutfit', 'Outfit', Inter, ui-sans-serif, system-ui, sans-serif;") &&
    /if \(definition\.mode === 'mind' && index === 0\) \{[\s\S]*?screen\.dataset\.d1SchedeeBrandFont = 'outfit'[\s\S]*?screen\.dataset\.d1SchedeeBrandFontSource = 'schedeev2-assets-fonts-outfit-variable'/.test(html) &&
    /else \{[\s\S]*?delete screen\.dataset\.d1SchedeeBrandFont[\s\S]*?delete screen\.dataset\.d1SchedeeBrandFontSource/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s*\{[\s\S]*?font-family:\s*var\(--schedee-brand-font\);[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.common-header-title,\s*\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.common-header-value,\s*\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.common-header-subvalue,\s*\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.log-name,\s*\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.log-meta,\s*\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-schedee-brand-font="outfit"\]\s+\.log-amount\s*\{[\s\S]*?font-family:\s*var\(--schedee-brand-font\);[\s\S]*?\}/.test(html),
  'Mind D1 must use the Schedee Outfit brand font, copied from schedeev2, scoped to D1 title/value/subvalue/logbox lettering only',
);
assert(
  /\.common-header-title\s*\{[\s\S]*?top:\s*28px;[\s\S]*?font-size:\s*11px;[\s\S]*?text-transform:\s*uppercase;[\s\S]*?\}/.test(html) &&
    !/data-d1-schedee-brand-font="outfit"\]\s+\.common-header-title\s*\{[\s\S]*?(font-size|top|text-transform):/.test(html),
  'Mind D1 Schedee font must inherit the same common-header title size, uppercase treatment, and top position as D2 instead of overriding title metrics',
);
const commonMindD1FontVariantRuntime = [
  extractFunctionSource('syncCommonMindD1FontVariantRow'),
  extractFunctionSource('updateCommonHeaderModeRow'),
].join('\n');
for (const [id, label] of [
  ['inter', 'Inter'],
  ['satoshi', 'Satoshi'],
  ['plus-jakarta-sans', 'Plus Jakarta Sans'],
  ['sf-pro', 'SF Pro'],
  ['manrope', 'Manrope'],
  ['poppins', 'Poppins'],
]) {
  assert(
    html.includes(`id: '${id}'`) &&
      html.includes(`label: '${label}'`) &&
      html.includes(`data-d1-font-variant="${id}"`),
    `Missing Mind D1 font variant contract for ${label}`,
  );
}
assert(
  html.includes("reference: '/storage/emulated/0/spendee/betuk.png'") &&
    html.includes('const commonMindD1FontVariants = Object.freeze([') &&
    commonMindD1FontVariantRuntime.includes("modeSection.querySelector('[data-common-mind-d1-font-row]')?.remove()") &&
    commonMindD1FontVariantRuntime.includes("fontRow.dataset.commonMindD1FontRow = 'true'") &&
    commonMindD1FontVariantRuntime.includes('const column = sourceColumn.cloneNode(true);') &&
    commonMindD1FontVariantRuntime.includes('screen.dataset.d1FontVariant = variant.id') &&
    commonMindD1FontVariantRuntime.includes("screen.dataset.d1FontReference = variant.reference") &&
    commonMindD1FontVariantRuntime.includes("screen.dataset.screen = `alt-common-header-mind-d1-font-${variant.id}`") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-font-family', variant.fontStack)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-lockup-top', variant.lockupTop)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-logo-x', variant.logoX)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-logo-y', variant.logoY)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-logo-size', variant.logoSize)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-wordmark-x', variant.wordmarkX)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-wordmark-y', variant.wordmarkY)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-wordmark-size', variant.wordmarkSize)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-tagline-gap', variant.taglineGap)") &&
    commonMindD1FontVariantRuntime.includes("screen.style.setProperty('--d1-tagline-ratio', String(variant.taglineRatio))") &&
    commonMindD1FontVariantRuntime.includes('syncCommonMindD1FontVariantRow(modeSection, definition);'),
  'Mind mode must create a six-screen D1 font variant row cloned from D1 and styled from the betuk.png reference',
);
assert(
  /\.common-header-mode\[data-common-header-mode="mind"\]\s+\.common-mind-d1-font-row\s*\{[\s\S]*?display:\s*flex;[\s\S]*?gap:\s*28px;[\s\S]*?width:\s*max-content;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-font-variant\]\s*\{[\s\S]*?font-family:\s*var\(--d1-font-family\);[\s\S]*?--d1-lockup-top:\s*33\.3px;[\s\S]*?--d1-wordmark-size:\s*30\.096px;[\s\S]*?--d1-logo-x:\s*30px;[\s\S]*?--d1-logo-y:\s*6px;[\s\S]*?--d1-logo-size:\s*47\.88px;[\s\S]*?--d1-wordmark-x:\s*82\.25px;[\s\S]*?--d1-wordmark-y:\s*10\.602px;[\s\S]*?--d1-tagline-gap:\s*1\.368px;[\s\S]*?--d1-tagline-ratio:\s*\.46;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-font-variant\]\s+\.spendee-brand-lockup\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?top:\s*var\(--d1-lockup-top\);[\s\S]*?height:\s*118px;[\s\S]*?display:\s*block;[\s\S]*?gap:\s*0;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-font-variant\]\s+\.spendee-logo\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*var\(--d1-logo-x\);[\s\S]*?top:\s*var\(--d1-logo-y\);[\s\S]*?width:\s*var\(--d1-logo-size\);[\s\S]*?height:\s*var\(--d1-logo-size\);[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-font-variant\]\s+\.spendee-copy\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*var\(--d1-wordmark-x\);[\s\S]*?top:\s*var\(--d1-wordmark-y\);[\s\S]*?\}/.test(html) &&
    (html.match(/lockupTop:\s*'33\.3px'/g) || []).length >= 6 &&
    (html.match(/wordmarkSize:\s*'30\.096px'/g) || []).length >= 6 &&
    (html.match(/taglineGap:\s*'1\.368px'/g) || []).length >= 6 &&
    (html.match(/logoSize:\s*'47\.88px'/g) || []).length >= 5 &&
    html.includes("logoSize: '45.144px'") &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\[data-d1-font-variant="sf-pro"\]\s*\{[\s\S]*?--d1-logo-size:\s*45\.144px;[\s\S]*?--d1-tagline-ratio:\s*\.43;[\s\S]*?\}/.test(html),
  'Mind D1 font variant row must render logo and labels another 5% smaller without changing motto-to-header padding',
);
const commonMindLayoutRuntime = [
  extractFunctionSource('findCommonMindLayoutSourceColumn'),
  extractFunctionSource('resolveCommonMindD1AStage0Core'),
  extractFunctionSource('syncCommonMindLayoutStage0CoreFromD1A'),
  extractFunctionSource('syncCommonMindLayoutPrototypeRow'),
  extractFunctionSource('configureCommonMindLayoutColumn'),
  extractFunctionSource('buildCommonMindYearTickerLayer'),
  extractFunctionSource('buildCommonMindYearMonthTickerLayer'),
  extractFunctionSource('buildCommonMindMonthDayTickerLayer'),
  extractFunctionSource('buildCommonMindSumHeatmapLayer'),
  extractFunctionSource('buildCommonMindSumGraphsLayer'),
  extractFunctionSource('buildCommonMindSumReferenceHeatmapLayer'),
  extractFunctionSource('buildCommonMindYearMonthPulseLayer'),
  extractFunctionSource('buildCommonMindYearGraphsLayer'),
  extractFunctionSource('buildCommonMindYearMonthFingerprintLayer'),
  extractFunctionSource('buildCommonMindYearMonthReferenceAnalyticsLayer'),
  extractFunctionSource('buildCommonMindMonthInsightLayer'),
  extractFunctionSource('buildCommonMindMonthGraphsLayer'),
  extractFunctionSource('buildCommonMindMonthDayFingerprintLayer'),
  extractFunctionSource('buildCommonMindMonthDayReferenceAnalyticsLayer'),
  extractFunctionSource('buildCommonMindMonthDaySimpleReferenceAnalyticsLayer'),
  extractFunctionSource('buildCommonMindMonthDayBareTickerLayer'),
  extractFunctionSource('buildCommonMindMonthDayBareReferenceAnalyticsLayer'),
  extractFunctionSource('updateCommonHeaderModeRow'),
].join('\n');
assert(
  commonMindLayoutRuntime.includes("layoutRow.dataset.commonMindLayoutRow = 'true'") &&
    commonMindLayoutRuntime.includes("layoutRow.id = 'mind-layout'") &&
    commonMindLayoutRuntime.includes("layoutRow.dataset.prototypePurpose = 'mind-stage1-stage2-layout-before-flutter-code'") &&
    commonMindLayoutRuntime.includes("findCommonMindLayoutSourceColumn(sourceRow, 'stage1')") &&
    commonMindLayoutRuntime.includes("findCommonMindLayoutSourceColumn(sourceRow, 'stage2')") &&
    commonMindLayoutRuntime.includes("const headerSelector = stage === 'stage1' ? '.common-header-stage1' : '.common-header-stage2';") &&
    commonMindLayoutRuntime.includes('candidate.querySelector(headerSelector)') &&
    commonMindLayoutRuntime.includes('sourceRow.querySelector(headerSelector)?.closest') &&
    commonMindLayoutRuntime.includes("const d1aStage0Core = resolveCommonMindD1AStage0Core(modeSection, sourceRow);") &&
    commonMindLayoutRuntime.includes('configureCommonMindLayoutColumn(column, config, d1aStage0Core);') &&
    commonMindLayoutRuntime.includes("const anchor = modeSection.querySelector('[data-common-mind-d1-font-row]') || sourceRow;") &&
    commonMindLayoutRuntime.includes("anchor.insertAdjacentElement('afterend', layoutRow);") &&
    commonMindLayoutRuntime.includes('syncCommonMindLayoutPrototypeRow(modeSection, definition);'),
  'Mind layout prototype row must be generated directly after the D1 font/D1A row and use stage-header source columns so it cannot disappear when generated screen ids differ',
);
assert(
  commonMindLayoutRuntime.includes('[data-d1-font-variant="inter"] .common-header-core') &&
    commonMindLayoutRuntime.includes("d1aStage0Core.querySelector('[data-score-ribbon-stage0]')") &&
    commonMindLayoutRuntime.includes("d1aStage0Core.querySelector('.common-score-ribbon-svg')") &&
    commonMindLayoutRuntime.includes('const clonedCore = d1aStage0Core.cloneNode(true);') &&
    commonMindLayoutRuntime.includes("clonedCore.dataset.stage0CoreSource = 'd1a'") &&
    commonMindLayoutRuntime.includes("clonedCore.dataset.stage0ScoreGraphSource = 'd1a'") &&
    commonMindLayoutRuntime.includes('targetCore.replaceWith(clonedCore);') &&
    commonMindLayoutRuntime.includes("screen.dataset.stage0CoreSource = 'd1a'") &&
    commonMindLayoutRuntime.includes("header.dataset.stage0ScoreGraphSource = 'd1a'"),
  'Generated Mind layout screens must replace their Stage0 core with the D1A score/ribbon graph core',
);
const mindLayoutFocusRuntime = [
  extractFunctionSource('focusMindLayoutPrototypeOnLoad'),
  html.slice(html.indexOf('initQueryMenuPrototype();'), html.indexOf('initColorLabScrollRenderSuspension();')),
].join('\n');
assert(
  mindLayoutFocusRuntime.includes("window.location.hash === '#mind-layout'") &&
    mindLayoutFocusRuntime.includes("params.get('focus') === 'mind-layout'") &&
    !mindLayoutFocusRuntime.includes("document.body.dataset.focusView = 'mind-layout'") &&
    mindLayoutFocusRuntime.includes("document.querySelector('#mind-layout')") &&
    mindLayoutFocusRuntime.includes('[data-screen="alt-common-header-mind-sum-stage1-layout"]') &&
    mindLayoutFocusRuntime.includes('requestAnimationFrame(() =>') &&
    mindLayoutFocusRuntime.includes('updateZoomHostSize();') &&
    mindLayoutFocusRuntime.includes("document.getElementById('zoomViewport')") &&
    mindLayoutFocusRuntime.includes('viewport.scrollLeft += targetRect.left - viewportRect.left - 24;') &&
    mindLayoutFocusRuntime.includes('viewport.scrollTop += targetRect.top - viewportRect.top - 24;') &&
    mindLayoutFocusRuntime.includes('if (!focusMindLayoutPrototypeOnLoad())') &&
    mindLayoutFocusRuntime.includes('focusQueryMenuQ1AOnLoad();'),
  'Mind layout prototype direct #mind-layout URL may scroll to the new row but must not hide the rest of Color Lab',
);
for (const screenId of [
  'alt-common-header-mind-sum-stage1-layout',
  'alt-common-header-mind-sum-heatmap-layout',
  'alt-common-header-mind-sum-graphs-layout',
  'alt-common-header-mind-sum-reference-heatmap-layout',
  'alt-common-header-mind-year-months-layout',
  'alt-common-header-mind-year-month-pulse-layout',
  'alt-common-header-mind-year-month-drivers-layout',
  'alt-common-header-mind-year-month-fingerprint-layout',
  'alt-common-header-mind-year-month-reference-analytics-layout',
  'alt-common-header-mind-month-stage1-layout',
  'alt-common-header-mind-month-insight-layout',
  'alt-common-header-mind-month-graphs-layout',
  'alt-common-header-mind-month-day-fingerprint-layout',
  'alt-common-header-mind-month-day-reference-analytics-layout',
  'alt-common-header-mind-month-day-simple-reference-layout',
]) {
  assert(commonMindLayoutRuntime.includes(screenId), `Missing Mind layout prototype screen ${screenId}`);
}
assert(
  !extractFunctionSource('buildCommonMindYearTickerLayer').includes('common-mind-layout-foot') &&
  commonMindLayoutRuntime.includes('data-focus-mode-stage1="mind-year-ticker"') &&
    commonMindLayoutRuntime.includes('data-ticking-axis="years"') &&
    commonMindLayoutRuntime.includes('data-stage1-parent-selector="year"') &&
    commonMindLayoutRuntime.includes("title: 'DS1 · SUM Mind · stage1 years'") &&
    commonMindLayoutRuntime.includes("title: 'DS2A · SUM Mind · heatmap'") &&
    commonMindLayoutRuntime.includes("title: 'DS2B · SUM Mind · graphs'") &&
    commonMindLayoutRuntime.includes("title: 'DS2C · SUM Mind · reference heatmap'") &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-sum-heatmap"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="year-heatmap"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-sum-graphs"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="sum-graphs"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-sum-reference-heatmap"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="year-reference-heatmap"') &&
    commonMindLayoutRuntime.includes('data-stage2-with-ticker="true"') &&
    !commonMindLayoutRuntime.includes('data-mind-stage2-pages="year-heatmap year-stats"') &&
    !commonMindLayoutRuntime.includes('data-stage2-other-page="year-stats"'),
  'SUM Mind layout row must split into DS1 pure year ticker, DS2A ticker plus heatmap, and DS2B ticker plus graph cards',
);
const sumReferenceHeatmapRuntime = extractFunctionSource('buildCommonMindSumReferenceHeatmapLayer');
assert(
  sumReferenceHeatmapRuntime.includes('/storage/emulated/0/spendee/mindstage2.png') &&
    sumReferenceHeatmapRuntime.includes('2026 – Hónapok heatmapja') &&
    sumReferenceHeatmapRuntime.includes('Élelmiszer · &gt; 2 000 Ft') &&
    sumReferenceHeatmapRuntime.includes('data-stage2-extra="mind-layout-sum-reference-heatmap"') &&
    sumReferenceHeatmapRuntime.includes('data-mind-stage2-pages="year-reference-heatmap"') &&
    sumReferenceHeatmapRuntime.includes('data-mind-reference-metric="year-month-amounts"') &&
    sumReferenceHeatmapRuntime.includes('Alacsony') &&
    sumReferenceHeatmapRuntime.includes('Magas') &&
    sumReferenceHeatmapRuntime.includes('Összesen') &&
    sumReferenceHeatmapRuntime.includes('2 207 100 Ft') &&
    sumReferenceHeatmapRuntime.includes('Tranzakciók') &&
    sumReferenceHeatmapRuntime.includes('458') &&
    sumReferenceHeatmapRuntime.includes('Átlag/hó') &&
    sumReferenceHeatmapRuntime.includes('Legmagasabb') &&
    sumReferenceHeatmapRuntime.includes('Július') &&
    sumReferenceHeatmapRuntime.includes('data-query-scoped="true"'),
  'DS2C reference heatmap must reproduce the screenshot year heatmap metrics and query-scoped labels',
);
const sumGraphsRuntime = extractFunctionSource('buildCommonMindSumGraphsLayer');
assert(
  sumGraphsRuntime.includes('common-mind-sum-graph-stack') &&
    sumGraphsRuntime.includes('data-mind-sum-bar-graph="money-flow-out"') &&
    sumGraphsRuntime.includes('data-mind-sum-bar-graph="pattern-volume"') &&
    sumGraphsRuntime.includes('Adott év kiadásai') &&
    sumGraphsRuntime.includes('Adott évben mért kiadási minták') &&
    sumGraphsRuntime.includes('money flow out') &&
    sumGraphsRuntime.includes('mintavolumen') &&
    sumGraphsRuntime.includes('common-mind-sum-bar-svg') &&
    !sumGraphsRuntime.includes('common-mind-stat-grid') &&
    !sumGraphsRuntime.includes('common-mind-stat-card'),
  'DS2B SUM graphs must be two stacked bar charts: selected-year money flow out above selected-year expense pattern volume',
);
const sumGraphs3dRuntime = extractFunctionSource('buildCommonMindSum3dGraphsLayer');
assert(
  sumGraphs3dRuntime.includes('data-stage2-extra="mind-layout-sum-graphs-3d"') &&
    sumGraphs3dRuntime.includes('data-mind-stage2-pages="sum-graphs-3d"') &&
    sumGraphs3dRuntime.includes('data-mind-sum-graphs-style="3d"') &&
    sumGraphs3dRuntime.includes('data-mind-sum-bar-graph="money-flow-out"') &&
    sumGraphs3dRuntime.includes('data-mind-sum-bar-graph="pattern-volume"') &&
    sumGraphs3dRuntime.includes('data-mind-sum-bar-depth="3d"') &&
    sumGraphs3dRuntime.includes('buildCommonMindSum3dCuboidMarkup') &&
    sumGraphs3dRuntime.includes('Adott év kiadásai') &&
    sumGraphs3dRuntime.includes('Adott évben mért kiadási minták') &&
    commonMindLayoutRuntime.includes("title: 'DS2B3D · SUM Mind · 3D graphs'") &&
    commonMindLayoutRuntime.indexOf("id: 'sum-graphs'") < commonMindLayoutRuntime.indexOf("id: 'sum-graphs-3d'") &&
    commonMindLayoutRuntime.indexOf("id: 'sum-graphs-3d'") < commonMindLayoutRuntime.indexOf("id: 'sum-reference-heatmap'"),
  'DS2B must gain an adjacent DS2B3D duplicate before DS2C without replacing the original two selected-year graph panels',
);
assert(
  /function buildCommonMindSum3dCuboidMarkup\(values\) \{[\s\S]*?common-mind-sum-3d-bar-back[\s\S]*?common-mind-sum-3d-bar-side[\s\S]*?common-mind-sum-3d-bar-front[\s\S]*?common-mind-sum-3d-bar-top/.test(html) &&
    /\.common-mind-sum-bar-panel\[data-mind-sum-bar-depth="3d"\]\s*\{[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-3d-bar-back\s*\{[\s\S]*?fill:\s*color-mix\(in srgb, var\(--mind-sum-bar-color\) 42%, #0f172a\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-3d-bar-side\s*\{[\s\S]*?fill:\s*color-mix\(in srgb, var\(--mind-sum-bar-color\) 58%, #0f172a\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-3d-bar-front\s*\{[\s\S]*?fill:\s*var\(--mind-sum-bar-color, #ef4444\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-3d-bar-top\s*\{[\s\S]*?fill:\s*color-mix\(in srgb, var\(--mind-sum-bar-color\) 72%, #ffffff\);[\s\S]*?\}/.test(html) &&
    !html.includes('common-mind-sum-cylinder-top') &&
    !html.includes('common-mind-sum-cylinder-bottom'),
  'DS2B3D must render every value as a square cuboid with flat front, back/depth, right-side and top planes, not cylinder caps',
);
assert(
  /\.common-mind-sum-graph-stack\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-bar-panel\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*auto minmax\(42px,\s*1fr\);[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.common-mind-sum-bar-svg\s*\{[\s\S]*?width:\s*100%;[\s\S]*?height:\s*100%;[\s\S]*?\}/.test(html),
  'DS2B SUM graph CSS must fit two stacked bar chart panels under the year rail',
);
assert(
  !extractFunctionSource('buildCommonMindYearMonthTickerLayer').includes('common-mind-layout-foot') &&
    commonMindLayoutRuntime.includes('data-focus-mode-stage1="mind-year-month-ticker"') &&
    commonMindLayoutRuntime.includes('data-ticking-axis="months"') &&
    commonMindLayoutRuntime.includes('data-stage1-parent-selector="month"') &&
    commonMindLayoutRuntime.includes("screen.dataset.stage1Sizing = 'shared-common-header'") &&
    commonMindLayoutRuntime.includes("header.dataset.stage1Sizing = 'shared-common-header'") &&
    !commonMindLayoutRuntime.includes('--common-header-stage1-h') &&
    commonMindLayoutRuntime.includes("title: 'DY1 · Éves Mind · stage1 months'") &&
    commonMindLayoutRuntime.includes("title: 'DY2A · Éves Mind · month pulse'") &&
    commonMindLayoutRuntime.includes("title: 'DY2B · Éves Mind · month drivers'") &&
    commonMindLayoutRuntime.includes("title: 'DY2C · Éves Mind · month fingerprint'") &&
    commonMindLayoutRuntime.includes("title: 'DY2D · Éves Mind · reference month analytics'") &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-year-month-pulse"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="month-pulse"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-year-month-drivers"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="month-drivers"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-year-month-fingerprint"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="month-fingerprint"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-year-month-reference-analytics"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="month-reference-analytics"'),
  'YEAR Mind layout row must split into DY1 month ticker, DY2A selected month pulse, and DY2B selected month drivers/graphs',
);
const yearMonthFingerprintRuntime = extractFunctionSource('buildCommonMindYearMonthFingerprintLayer');
assert(
  yearMonthFingerprintRuntime.includes('Month Fingerprint') &&
    yearMonthFingerprintRuntime.includes('data-stage2-extra="mind-layout-year-month-fingerprint"') &&
    yearMonthFingerprintRuntime.includes('data-mind-stage2-pages="month-fingerprint"') &&
    yearMonthFingerprintRuntime.includes('data-mind-fingerprint="month"') &&
    yearMonthFingerprintRuntime.includes('data-query-scoped="true"') &&
    yearMonthFingerprintRuntime.includes('Havi ritmus') &&
    yearMonthFingerprintRuntime.includes('Heti eloszlás') &&
    yearMonthFingerprintRuntime.includes('Top kategória') &&
    yearMonthFingerprintRuntime.includes('Top vendor') &&
    yearMonthFingerprintRuntime.includes('No spend') &&
    yearMonthFingerprintRuntime.includes('Peak day') &&
    yearMonthFingerprintRuntime.includes('Fastfood &gt; 5k') &&
    !yearMonthFingerprintRuntime.includes('common-mind-risk-copy'),
  'DY2C Month Fingerprint must summarize the selected month as a query-scoped visual explorer panel',
);
const yearMonthReferenceRuntime = extractFunctionSource('buildCommonMindYearMonthReferenceAnalyticsLayer');
assert(
  yearMonthReferenceRuntime.includes('/storage/emulated/0/spendee/mindstage2.png') &&
    yearMonthReferenceRuntime.includes('2026. Március') &&
    yearMonthReferenceRuntime.includes('Élelmiszer · &gt; 2 000 Ft') &&
    yearMonthReferenceRuntime.includes('data-stage2-extra="mind-layout-year-month-reference-analytics"') &&
    yearMonthReferenceRuntime.includes('data-mind-stage2-pages="month-reference-analytics"') &&
    yearMonthReferenceRuntime.includes('Heti ritmus') &&
    yearMonthReferenceRuntime.includes('Hétköznap eloszlás') &&
    yearMonthReferenceRuntime.includes('Hétköznap') &&
    yearMonthReferenceRuntime.includes('Hétvége') &&
    yearMonthReferenceRuntime.includes('Napszak szerinti aktivitás') &&
    yearMonthReferenceRuntime.includes('Összeg') &&
    yearMonthReferenceRuntime.includes('189 600 Ft') &&
    yearMonthReferenceRuntime.includes('Tranzakciók') &&
    yearMonthReferenceRuntime.includes('47') &&
    yearMonthReferenceRuntime.includes('Átlag / nap') &&
    yearMonthReferenceRuntime.includes('Mind Score') &&
    yearMonthReferenceRuntime.includes('Top kategória') &&
    yearMonthReferenceRuntime.includes('Top vendor') &&
    yearMonthReferenceRuntime.includes('data-query-scoped="true"'),
  'DY2D reference month analytics must reproduce the screenshot month rhythm, distribution, activity, metrics, and top cards',
);
assert(
  /\.common-mind-month-wheel\s*\{[\s\S]*?grid-template-columns:\s*repeat\(12,\s*minmax\(44px,\s*1fr\)\);[\s\S]*?grid-template-rows:\s*none;[\s\S]*?overflow:\s*hidden;/.test(html) &&
    !/\.common-mind-month-wheel\s*\{[\s\S]*?grid-template-columns:\s*repeat\(6,\s*minmax\(0,\s*1fr\)\);[\s\S]*?grid-template-rows:\s*repeat\(2/.test(html),
  'DY1 month ticker rail must stay one horizontal row and must not resize Stage1 into a two-row month grid',
);
const yearModeGraphsRuntime = extractFunctionSource('buildCommonMindYearGraphsLayer');
assert(
  yearModeGraphsRuntime.includes('common-mind-year-d2-graph-stack') &&
    yearModeGraphsRuntime.includes('data-source="d2-stage1-boxed-graphs"') &&
    yearModeGraphsRuntime.includes('data-mind-box-layout="stacked-stage2"') &&
    yearModeGraphsRuntime.includes('commonMindStage1BoxGraphConfig.cards.map') &&
    yearModeGraphsRuntime.includes('fastinfo-chart-card common-mind-box-graph-card') &&
    yearModeGraphsRuntime.includes('buildCommonMindBoxGraphMiniSvg(card)') &&
    !yearModeGraphsRuntime.includes('common-mind-stat-grid') &&
    !yearModeGraphsRuntime.includes('common-mind-stat-card'),
  'YEAR drivers screen must reuse the D2 boxed graph card visual language in a compact stacked layout, not generic stat cards',
);
assert(
  !extractFunctionSource('buildCommonMindMonthDayTickerLayer').includes('common-mind-layout-foot') &&
  commonMindLayoutRuntime.includes('data-focus-mode-stage1="mind-month-day-ticker"') &&
    commonMindLayoutRuntime.includes('data-ticking-axis="days"') &&
    commonMindLayoutRuntime.includes('data-stage1-parent-selector="day"') &&
    commonMindLayoutRuntime.includes("title: 'DM1 · Havi Mind · stage1 days'") &&
    commonMindLayoutRuntime.includes("title: 'DM2A · Havi Mind · day insight'") &&
    commonMindLayoutRuntime.includes("title: 'DM2B · Havi Mind · day flow'") &&
    commonMindLayoutRuntime.includes("title: 'DM2C · Havi Mind · day fingerprint'") &&
    commonMindLayoutRuntime.includes("title: 'DM2D · Havi Mind · reference day analytics'") &&
    commonMindLayoutRuntime.includes("title: 'DM2E · Havi Mind · simple day cards'") &&
    commonMindLayoutRuntime.includes("title: 'DM2F · Havi Mind · bare day data'") &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-insight"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-insight"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-graphs"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-flow"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-day-fingerprint"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-fingerprint"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-day-reference-analytics"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-reference-analytics"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-day-simple-reference"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-simple-reference"') &&
    commonMindLayoutRuntime.includes('data-stage2-extra="mind-layout-month-day-bare-reference"') &&
    commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-bare-reference"') &&
    commonMindLayoutRuntime.includes('data-stage2-with-ticker="true"') &&
    !commonMindLayoutRuntime.includes('data-mind-stage2-pages="day-insight day-flow"') &&
    !commonMindLayoutRuntime.includes('data-stage2-other-page="day-flow"'),
  'Monthly Mind layout row must split into DM1 pure day ticker, DM2A ticker plus insight card, and DM2B graph/flow cards',
);
const monthDayFingerprintRuntime = extractFunctionSource('buildCommonMindMonthDayFingerprintLayer');
assert(
  monthDayFingerprintRuntime.includes('Day Fingerprint') &&
    monthDayFingerprintRuntime.includes('data-stage2-extra="mind-layout-month-day-fingerprint"') &&
    monthDayFingerprintRuntime.includes('data-mind-stage2-pages="day-fingerprint"') &&
    monthDayFingerprintRuntime.includes('data-mind-fingerprint="day"') &&
    monthDayFingerprintRuntime.includes('data-query-scoped="true"') &&
    monthDayFingerprintRuntime.includes('24h Activity') &&
    monthDayFingerprintRuntime.includes('Transactions') &&
    monthDayFingerprintRuntime.includes('Category mix') &&
    monthDayFingerprintRuntime.includes('Largest purchase') &&
    monthDayFingerprintRuntime.includes('Pulse') &&
    monthDayFingerprintRuntime.includes('Fastfood &gt; 5k') &&
    !monthDayFingerprintRuntime.includes('common-mind-risk-copy'),
  'DM2C Day Fingerprint must summarize the selected day as a query-scoped micro visual explorer panel',
);
const monthDayReferenceRuntime = extractFunctionSource('buildCommonMindMonthDayReferenceAnalyticsLayer');
assert(
    monthDayReferenceRuntime.includes('/storage/emulated/0/spendee/mindstage2.png') &&
    monthDayReferenceRuntime.includes('data-container-depth="double"') &&
    monthDayReferenceRuntime.includes('data-layer-order="bg-stats-common-glass"') &&
    monthDayReferenceRuntime.includes('data-stage2-panel-frame="none"') &&
    monthDayReferenceRuntime.includes('data-scrollable-stage2="true"') &&
    monthDayReferenceRuntime.includes('common-mind-reference-stat-block') &&
    !monthDayReferenceRuntime.includes('common-mind-reference-mini-card') &&
    monthDayReferenceRuntime.includes('2026. Március 14. (Péntek)') &&
    monthDayReferenceRuntime.includes('Élelmiszer · &gt; 2 000 Ft') &&
    monthDayReferenceRuntime.includes('data-stage2-extra="mind-layout-month-day-reference-analytics"') &&
    monthDayReferenceRuntime.includes('data-mind-stage2-pages="day-reference-analytics"') &&
    monthDayReferenceRuntime.includes('Napi aktivitás (24h)') &&
    monthDayReferenceRuntime.includes('Összeg') &&
    monthDayReferenceRuntime.includes('8 650 Ft') &&
    monthDayReferenceRuntime.includes('Tranzakciók') &&
    monthDayReferenceRuntime.includes('3') &&
    monthDayReferenceRuntime.includes('Átlag / txn') &&
    monthDayReferenceRuntime.includes('Mind Score') &&
    monthDayReferenceRuntime.includes('88/100') &&
    monthDayReferenceRuntime.includes('Kategória mix') &&
    monthDayReferenceRuntime.includes('Legnagyobb tétel') &&
    monthDayReferenceRuntime.includes('Tranzakciós timeline') &&
    monthDayReferenceRuntime.includes('Napi pulse') &&
    monthDayReferenceRuntime.includes('Ma tudatos napod volt!') &&
    monthDayReferenceRuntime.includes('data-query-scoped="true"'),
  'DM2D reference day analytics must use double containerization, scroll vertically, and preserve the screenshot day metrics',
);
const monthDaySimpleReferenceRuntime = extractFunctionSource('buildCommonMindMonthDaySimpleReferenceAnalyticsLayer');
assert(
  monthDaySimpleReferenceRuntime.includes('/storage/emulated/0/spendee/mindstage2.png') &&
    monthDaySimpleReferenceRuntime.includes('data-container-depth="simple"') &&
    monthDaySimpleReferenceRuntime.includes('data-stage2-panel-frame="none"') &&
    monthDaySimpleReferenceRuntime.includes('data-stage2-extra="mind-layout-month-day-simple-reference"') &&
    monthDaySimpleReferenceRuntime.includes('data-mind-stage2-pages="day-simple-reference"') &&
    monthDaySimpleReferenceRuntime.includes('Napi aktivitás (24h)') &&
    monthDaySimpleReferenceRuntime.includes('Összeg') &&
    monthDaySimpleReferenceRuntime.includes('Tranzakciók') &&
    monthDaySimpleReferenceRuntime.includes('Kategória mix') &&
    monthDaySimpleReferenceRuntime.includes('Legnagyobb tétel') &&
    monthDaySimpleReferenceRuntime.includes('Tranzakciós timeline') &&
    monthDaySimpleReferenceRuntime.includes('Napi pulse') &&
    monthDaySimpleReferenceRuntime.includes('data-query-scoped="true"') &&
    !monthDaySimpleReferenceRuntime.includes('common-mind-reference-stage2-card'),
  'DM2E simple day cards must place the same glass content cards directly on the stage2 background without a large parent card',
);
const monthDayBareReferenceRuntime = extractFunctionSource('buildCommonMindMonthDayBareReferenceAnalyticsLayer');
const monthDayBareTickerRuntime = extractFunctionSource('buildCommonMindMonthDayBareTickerLayer');
assert(
  monthDayBareReferenceRuntime.includes('/storage/emulated/0/spendee/mindstage2.png') &&
    monthDayBareReferenceRuntime.includes('data-container-depth="none"') &&
    monthDayBareReferenceRuntime.includes('data-layer-order="bg-data"') &&
    monthDayBareReferenceRuntime.includes('data-stage2-panel-frame="none"') &&
    monthDayBareReferenceRuntime.includes('data-scrollable-stage2="true"') &&
    monthDayBareReferenceRuntime.includes('data-stage2-extra="mind-layout-month-day-bare-reference"') &&
    monthDayBareReferenceRuntime.includes('data-mind-stage2-pages="day-bare-reference"') &&
    monthDayBareReferenceRuntime.includes('Napi aktivitás (24h)') &&
    monthDayBareReferenceRuntime.includes('Összeg') &&
    monthDayBareReferenceRuntime.includes('Tranzakciók') &&
    monthDayBareReferenceRuntime.includes('Kategória mix') &&
    monthDayBareReferenceRuntime.includes('Legnagyobb tétel') &&
    monthDayBareReferenceRuntime.includes('Tranzakciós timeline') &&
    monthDayBareReferenceRuntime.includes('Napi pulse') &&
    monthDayBareReferenceRuntime.includes('data-query-scoped="true"') &&
    !monthDayBareReferenceRuntime.includes('common-mind-reference-mini-card') &&
    !monthDayBareReferenceRuntime.includes('common-mind-reference-stage2-card') &&
    !monthDayBareReferenceRuntime.includes('common-mind-reference-head'),
  'DM2F bare day data must render the same selected-day data directly on the Stage2 background without light glass cards or a parent analytics card',
);
assert(
  monthDayBareTickerRuntime.includes('data-bare-stage2-ticker="true"') &&
    monthDayBareTickerRuntime.includes('common-mind-bare-day-ticker') &&
    monthDayBareTickerRuntime.includes('common-mind-day-wheel') &&
    monthDayBareTickerRuntime.includes('data-ticking-axis="days"') &&
    !monthDayBareTickerRuntime.includes('common-mind-layout-panel') &&
    /\.common-mind-bare-day-ticker\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-mind-bare-day-ticker\s+\.common-mind-day-tick\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-bare-grid\s*\{[\s\S]*?display:\s*grid;[\s\S]*?overflow-y:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-bare-grid\s+\.common-mind-reference-stat-block\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html),
  'DM2F must keep the daily ticker and every metric block out of glass containers while preserving a scrollable data-only layout',
);
assert(
  (commonMindLayoutRuntime.match(/data-query-scoped="true"/g) || []).length >= 4 &&
    (commonMindLayoutRuntime.match(/data-summary-pill-mode="/g) || []).length >= 9 &&
    (commonMindLayoutRuntime.match(/data-mind-refines-summary="/g) || []).length >= 9 &&
    commonMindLayoutRuntime.includes('screen.dataset.summaryPillMode = config.summaryMode') &&
    commonMindLayoutRuntime.includes('screen.dataset.mindRefinesSummary = config.refinesSummary') &&
    commonMindLayoutRuntime.includes('Summary pill: SUM') &&
    commonMindLayoutRuntime.includes('Summary pill: ÉV') &&
    commonMindLayoutRuntime.includes('Summary pill: HÓ') &&
    commonMindLayoutRuntime.includes('Fastfood &gt; 5k') &&
    commonMindLayoutRuntime.includes('Rosszabb, mint a havi mintád') &&
    commonMindLayoutRuntime.includes('data-filter-reactive="current-filter"'),
  'Mind layout prototype must make query-scoped scoring explicit and mark Summary pill as parent scope for all nine screens',
);
assert(
  /\.common-header-mode\[data-common-header-mode="mind"\]\s+\.common-mind-layout-row\s*\{[\s\S]*?display:\s*flex;[\s\S]*?gap:\s*28px;[\s\S]*?width:\s*max-content;[\s\S]*?\}/.test(html) &&
    !/body\[data-focus-view="mind-layout"\]/.test(html) &&
    /\.common-mind-layout-panel\[data-ticker-only="true"\]\s*\{[\s\S]*?grid-template-rows:\s*auto minmax\(0,\s*1fr\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-layout-layer\[data-stage2-ticker="true"\]\s*\{[\s\S]*?bottom:\s*auto;[\s\S]*?height:\s*calc\(var\(--common-header-stage1-h\) - 114px\);[\s\S]*?\}/.test(html) &&
    !/\.common-mind-layout-layer\[data-stage2-ticker="true"\]\s*\{(?:(?!\}).)*\bheight:\s*104px;/s.test(html) &&
    !/\.common-mind-layout-layer\[data-stage2-ticker="true"\]\s+\.common-mind-layout-panel\s*\{(?:(?!\}).)*gap:\s*6px;/s.test(html) &&
    /\.common-mind-stage2-detail-layer\[data-stage2-with-ticker="true"\]\s*\{[\s\S]*?top:\s*calc\(96px \+ \(var\(--common-header-stage1-h\) - 114px\) \+ 12px\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?top:\s*112px;[\s\S]*?bottom:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-panel\[data-mind-stage2-page="year-heatmap"\]\s+\.mind-heatmap-grid\s*\{[\s\S]*?gap:\s*11px;[\s\S]*?grid-auto-rows:\s*minmax\(70px,\s*1fr\);[\s\S]*?align-content:\s*start;[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-panel\[data-mind-stage2-page="year-heatmap"\]\s+\.mind-heatmap-month-card\s*\{[\s\S]*?min-height:\s*70px;[\s\S]*?padding:\s*5px 6px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-panel\[data-mind-stage2-page="year-heatmap"\]\s+\.mind-heatmap-days\s*\{[\s\S]*?gap:\s*2px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-panel\[data-mind-stage2-page="year-heatmap"\]\s+\.mind-heatmap-day\s*\{[\s\S]*?font-size:\s*3\.9px;[\s\S]*?min-height:\s*0;[\s\S]*?\}/.test(html) &&
    /\.common-mind-year-d2-graph-stack\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*auto repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*7px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-year-d2-graph-stack\s+\.common-mind-box-graph-card\.fastinfo-chart-card\s*\{[\s\S]*?min-height:\s*0;[\s\S]*?padding:\s*7px 8px 6px;[\s\S]*?grid-template-rows:\s*auto auto minmax\(26px,\s*1fr\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-risk-meter\s*\{[\s\S]*?conic-gradient\(from -90deg[\s\S]*?var\(--risk-score,\s*76%\)[\s\S]*?\}/.test(html) &&
    /\.common-mind-day-wheel\s*\{[\s\S]*?grid-template-columns:\s*repeat\(7,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-fingerprint-grid\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-fingerprint-card\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*auto minmax\(0,\s*1fr\);[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.common-mind-fingerprint-bars\s*\{[\s\S]*?display:\s*grid;[\s\S]*?align-items:\s*end;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-stage2-card\s*\{[\s\S]*?border:\s*1px solid rgba\(148,163,184,\.24\);[\s\S]*?box-shadow:[\s\S]*?0 18px 38px rgba\(15,23,42,\.08\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-detail-panel\[data-stage2-panel-frame="none"\]\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*none;[\s\S]*?padding:\s*0;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-stage2-card\[data-scrollable-stage2="true"\]\s*\{[\s\S]*?overflow-y:\s*auto;[\s\S]*?scrollbar-width:\s*thin;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-day-body\[data-scrollable-stage2="true"\]\s*\{[\s\S]*?overflow:\s*visible;[\s\S]*?padding-bottom:\s*8px;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-stage2-card\[data-layer-order="bg-stats-common-glass"\]\s+\.common-mind-reference-day-body\s*\{[\s\S]*?grid-template-rows:\s*auto auto auto auto;[\s\S]*?align-content:\s*start;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-stat-block\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*none;[\s\S]*?overflow:\s*visible;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-stage2-card\[data-layer-order="bg-stats-common-glass"\]\s+\.common-mind-reference-metric-row\s*\{[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?grid-auto-rows:\s*minmax\(48px,\s*auto\);[\s\S]*?min-height:\s*0;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-simple-grid\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-rows:\s*auto 48px minmax\(86px,\s*1fr\) minmax\(82px,\s*1fr\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-mini-card\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.72\);[\s\S]*?backdrop-filter:\s*blur\(14px\);[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-bars\s*\{[\s\S]*?display:\s*grid;[\s\S]*?align-items:\s*end;[\s\S]*?\}/.test(html) &&
    /\.common-mind-reference-donut\s*\{[\s\S]*?border-radius:\s*999px;[\s\S]*?conic-gradient[\s\S]*?\}/.test(html) &&
    /\.common-mind-stage2-combo-body\s*\{[\s\S]*?grid-template-columns:\s*1\.08fr \.92fr;[\s\S]*?\}/.test(html),
  'Mind layout prototype CSS must define the D1A-under layout row without focus-mode hiding, plus stage2 detail area, risk meter, day ticker grid, and combined stage2 body',
);
assert(
  c2ConvexBadgeRule.includes('overflow: hidden;') &&
    c2ConvexBadgeRule.includes('radial-gradient(circle at 36% 22%, rgba(255,255,255,.26) 0%, rgba(255,255,255,.10) 25%, transparent 50%)') &&
    c2ConvexBadgeRule.includes('radial-gradient(circle at 50% 48%, rgba(255,255,255,.08), transparent 62%)') &&
    c2ConvexBadgeRule.includes('radial-gradient(circle at 58% 76%, rgba(15,23,42,.20), transparent 40%)') &&
    c2ConvexBadgeRule.includes('var(--context-color)') &&
    c2ConvexBadgeRule.includes('0 10px 18px rgba(15,23,42,.18)') &&
    c2ConvexBadgeRule.includes('inset 0 2px 5px rgba(255,255,255,.18)') &&
    c2ConvexBadgeRule.includes('inset 0 -3px 6px rgba(15,23,42,.10)') &&
    !c2ConvexBadgeRule.includes('radial-gradient(circle at 50% 54%, rgba(15,23,42,.30)') &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.common-stage1-avatar-strip\[data-context-selector="category-carousel"\]\s+\.common-context-badge::before\s*\{[\s\S]*?inset:\s*18%;[\s\S]*?rgba\(15,23,42,\.24\)[\s\S]*?mix-blend-mode:\s*multiply;[\s\S]*?\}/.test(
      html,
    ) === false &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.common-stage1-avatar-strip\[data-context-selector="category-carousel"\]\s+\.common-context-badge::before\s*\{[\s\S]*?inset:\s*5px;[\s\S]*?rgba\(255,255,255,\.22\)[\s\S]*?mix-blend-mode:\s*screen;[\s\S]*?opacity:\s*\.38;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.common-stage1-avatar-strip\[data-context-selector="category-carousel"\]\s+\.common-context-badge::after\s*\{[\s\S]*?inset:\s*0;[\s\S]*?rgba\(15,23,42,\.20\)[\s\S]*?pointer-events:\s*none;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.common-stage1-avatar-strip\[data-context-selector="category-carousel"\]\s+\.common-context-badge\.center\s*\{[\s\S]*?0 5px 10px rgba\(255,255,255,\.10\)[\s\S]*?inset 0 2px 6px rgba\(255,255,255,\.18\)[\s\S]*?inset 0 -3px 7px rgba\(15,23,42,\.12\)[\s\S]*?\}/.test(
      html,
    ),
  'Budget C2 category carousel badges must keep the outward convex lens while using softened top highlights and rim glow',
);
assert(
  c1c2LogboxAvatarLensRule.includes('position: relative;') &&
    c1c2LogboxAvatarLensRule.includes('isolation: isolate;') &&
    c1c2LogboxAvatarLensRule.includes('overflow: hidden;') &&
    c1c2LogboxAvatarLensRule.includes('radial-gradient(circle at 34% 20%, rgba(255,255,255,.24)') &&
    c1c2LogboxAvatarLensRule.includes('radial-gradient(circle at 54% 74%, rgba(15,23,42,.20)') &&
    c1c2LogboxAvatarLensRule.includes('var(--logbox-avatar-bg, var(--avatar-color, var(--gray-500)))') &&
    c1c2LogboxAvatarLensRule.includes('inset 0 2px 5px rgba(255,255,255,.18)') &&
    c1c2LogboxAvatarLensRule.includes('inset 0 -3px 6px rgba(15,23,42,.10)') &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage0"\]\s+\.logbox-avatar-circle::before,\s*\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.logbox-avatar-circle::before\s*\{[\s\S]*?mix-blend-mode:\s*screen;[\s\S]*?opacity:\s*\.40;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage0"\]\s+\.logbox-avatar-circle::after,\s*\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.logbox-avatar-circle::after\s*\{[\s\S]*?radial-gradient\(circle at 56% 78%, rgba\(15,23,42,\.18\)[\s\S]*?pointer-events:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage0"\]\s+\.logbox-avatar-circle\s+\.logbox-avatar-icon,\s*\.common-header-mode\[data-common-header-mode="budget"\]\s+\[data-screen="alt-common-header-budget-stage1"\]\s+\.logbox-avatar-circle\s+\.logbox-avatar-icon\s*\{[\s\S]*?z-index:\s*2;[\s\S]*?drop-shadow\(0 2px 3px rgba\(15,23,42,\.20\)\);[\s\S]*?\}/.test(html),
  'Budget C1/C2 logbox avatars must use a scoped softened outward convex lens effect with protected icon layer',
);
assert(
  /<div class="mind-portal-test-header-wrap" data-mind-portal-test-header[\s\S]*?<div class="mind-portal-test-row" data-portal-message-row>[\s\S]*?<header class="common-header-card mind-portal-test-header"[^>]*data-mind-portal-drag-surface="true"[^>]*data-portal-message-state="balance"[\s\S]*?data-portal-message-content="balance"[^>]*aria-hidden="false"[\s\S]*?Balance[\s\S]*?-372 047 472 Ft[\s\S]*?data-portal-message-content="message"[^>]*aria-hidden="true"[\s\S]*?Portal üzenet[\s\S]*?Új pénzügyi jel érkezett[\s\S]*?<\/header>[\s\S]*?<button[^>]*data-portal-message-trigger[^>]*aria-pressed="false"/.test(html) &&
    /\.mind-portal-test-header-wrap\s*\{[\s\S]*?margin-top:\s*18px;[\s\S]*?\}/.test(html) &&
    /\.mind-portal-test-header\s*\{[\s\S]*?position:\s*relative;[\s\S]*?touch-action:\s*none;[\s\S]*?overscroll-behavior:\s*contain;[\s\S]*?\}/.test(html) &&
    /\.common-mind-portal-trail\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?pointer-events:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-mind-portal-trail-dot\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?width:\s*var\(--mind-portal-dot-size, 82px\);[\s\S]*?height:\s*var\(--mind-portal-dot-size, 82px\);[\s\S]*?rgba\(255,167,226,calc\(\.96 \* var\(--mind-portal-interaction-alpha, 1\)\)\)[\s\S]*?rgba\(139,62,255,calc\(\.72 \* var\(--mind-portal-interaction-alpha, 1\)\)\)[\s\S]*?rgba\(255,255,255,calc\(\.42 \* var\(--mind-portal-interaction-alpha, 1\)\)\)[\s\S]*?transparent 76%\)[\s\S]*?animation:\s*mindPortalTrailFade 1350ms[\s\S]*?forwards;[\s\S]*?\}/.test(html) &&
    /@keyframes mindPortalTrailFade\s*\{[\s\S]*?opacity:\s*\.96[\s\S]*?scale\(1\)[\s\S]*?opacity:\s*0[\s\S]*?scale\(\.18\)[\s\S]*?\}/.test(html) &&
    /function spawnCommonHeaderMindPortalTrailPoint\(header, event, force = false\) \{[\s\S]*?querySelector\('\[data-mind-portal-trail\]'\)[\s\S]*?createElement\('span'\)[\s\S]*?common-mind-portal-trail-dot[\s\S]*?--mind-portal-dot-x[\s\S]*?--mind-portal-dot-y[\s\S]*?animationend[\s\S]*?remove\(\)/.test(html) &&
    /let releaseFrame = 0;[\s\S]*?const stopPortalTouch = \(\) => \{[\s\S]*?window\.cancelAnimationFrame\(releaseFrame\)[\s\S]*?releaseFrame = window\.requestAnimationFrame\(\(\) => \{[\s\S]*?--mind-portal-touch-opacity', '0'/.test(html) &&
    !/releaseTimer = window\.setTimeout\(\(\) => \{[\s\S]*?--mind-portal-touch-opacity', '0'/.test(html) &&
    /header\.addEventListener\('pointerdown'[\s\S]*?event\.preventDefault\(\)[\s\S]*?spawnCommonHeaderMindPortalTrailPoint\(header, event, true\)/.test(html) &&
    /header\.addEventListener\('pointermove'[\s\S]*?event\.preventDefault\(\)[\s\S]*?spawnCommonHeaderMindPortalTrailPoint\(header, event\)/.test(html),
  'Mind portal drag must keep the standalone relay header as the protected drag surface while its adjacent trigger stays outside the header',
);
assert(
  /\.mind-portal-test-row\s*\{[\s\S]*?width:\s*min\(360px,\s*calc\(100% - 40px\)\);[\s\S]*?display:\s*flex;[\s\S]*?gap:\s*8px;/.test(html) &&
    /\.mind-portal-message-trigger\s*\{[\s\S]*?width:\s*44px;[\s\S]*?height:\s*44px;[\s\S]*?touch-action:\s*manipulation;/.test(html) &&
    /\.mind-portal-content-viewport\s*\{[\s\S]*?overflow:\s*hidden;[\s\S]*?pointer-events:\s*none;/.test(html) &&
    /\[data-portal-message-state="balance"\]\s+\[data-portal-message-content="balance"\][\s\S]*?opacity:\s*1;/.test(html) &&
    /\[data-portal-message-state="message"\]\s+\[data-portal-message-content="message"\][\s\S]*?opacity:\s*1;/.test(html),
  'The portal relay row must stay phone-width with a 44px external trigger and contained endpoint content',
);
assert(
  html.includes('src="./color_lab_portal_message.js"') &&
    html.indexOf('src="./color_lab_portal_energy.js"') < html.indexOf('src="./color_lab_portal_message.js"') &&
    html.includes('data-portal-message-panel') &&
    html.includes('data-portal-message-mode-select') &&
    ['diffuse-focus', 'portal-aperture', 'energy-sweep', 'spectral-echo'].every((mode) =>
      html.includes(`<option value="${mode}"`)) &&
    html.includes('data-portal-message-controls-scroll'),
  'The separate portal-message controls shell must load its pure module and expose all four approved morphs',
);
assert(
  html.includes('function initPortalMessageMorphLab()') &&
    html.includes('function runPortalMessageMorph(wrap, targetState)') &&
    html.includes('function commitPortalMessageState(wrap, state, targetState)') &&
    html.includes('animation.reverse()') &&
    html.includes("window.matchMedia('(prefers-reduced-motion: reduce)')") &&
    html.includes("typeof outgoingPanel.animate !== 'function'") &&
    html.includes('header.dataset.portalMessageState = targetState') &&
    html.includes("trigger.setAttribute('aria-pressed', targetState === 'message' ? 'true' : 'false')") &&
    html.includes("targetState === 'message' ? 'Balance visszaállítása' : 'Tesztüzenet megjelenítése'"),
  'Portal message playback must toggle, reverse in flight, and commit accessible state with reduced-motion and no-WAAPI fallbacks',
);
assert(
  html.includes('function renderPortalMessageControls(wrap, mode)') &&
    html.includes('PortalMessageMorph.controlsForMode(mode)') &&
    html.includes('data-portal-message-control-range') &&
    html.includes('data-portal-message-control-number') &&
    html.includes('portalMessageMorphStates') &&
    html.includes('settingsByMode') &&
    html.includes('function resetPortalMessageMode(wrap)') &&
    html.includes('initPortalMessageMorphLab();') &&
    /document\.querySelectorAll\('\[data-mind-portal-energy-controls-scroll\], \[data-portal-message-controls-scroll\], \[data-portal-background-controls-scroll\], \[data-portal-interior-motion-controls-scroll\], \[data-portal-message-field-controls-scroll\], \[data-portal-transition-controls-scroll\]'\)/.test(html),
  'Message morph controls must render only the active schema with synchronized range/manual inputs, isolated reset, and shared vertical scroll routing',
);
const portalBackgroundHeaderBlock = html.match(
  /<header class="common-header-card mind-portal-test-header"[\s\S]*?<\/header>/,
)?.[0] || '';
const portalMessageViewportBlock = portalBackgroundHeaderBlock.match(
  /<div class="mind-portal-content-viewport" data-portal-message-viewport>[\s\S]*?data-portal-message-content="balance"[\s\S]*?<\/div>[\s\S]*?data-portal-message-content="message"[\s\S]*?<\/div>\s*<\/div>/,
)?.[0] || '';
const portalLayerOrder = [
  'data-mind-portal-idle-canvas',
  'data-portal-message-field-canvas',
  'data-portal-background-transition-canvas',
  'data-portal-background-response',
  'data-portal-message-viewport',
].map((token) => portalBackgroundHeaderBlock.indexOf(token));
assert(
  portalLayerOrder.every((index) => index >= 0) &&
    portalLayerOrder.every((index, position) => position === 0 || index > portalLayerOrder[position - 1]) &&
    portalMessageViewportBlock.includes('data-portal-message-content="balance"') &&
    portalMessageViewportBlock.includes('data-portal-message-content="message"') &&
    !/canvas|data-portal-background-response|accent/i.test(portalMessageViewportBlock) &&
    !html.includes('data-portal-message-accent') &&
    !html.includes('.mind-portal-message-accent') &&
    (html.match(/data-portal-layer-toggle="(?:text|text-background|full-background)" aria-pressed="true"/g) || []).length === 3 &&
    html.includes('textMorphEnabled: true') &&
    html.includes('textBackgroundEnabled: true') &&
    html.includes('fullBackgroundMorphEnabled: true') &&
    html.includes('function setPortalLayerEnabled(wrap, layer, enabled)'),
  'Portal delivery must use five ordered full-header paint layers and three independent accessible switches',
);
const portalBackgroundPanelStart = html.indexOf(
  '<div class="mind-portal-background-panel" data-portal-background-panel',
);
const portalBackgroundPanelEnd = portalBackgroundPanelStart >= 0
  ? html.indexOf('<div class="mind-portal-message-field-panel"', portalBackgroundPanelStart)
  : -1;
const portalBackgroundPanelBlock = portalBackgroundPanelStart >= 0
  ? html.slice(
    portalBackgroundPanelStart,
    portalBackgroundPanelEnd > portalBackgroundPanelStart ? portalBackgroundPanelEnd : undefined,
  )
  : '';
const portalBackgroundSelectBlock = portalBackgroundPanelBlock.match(
  /<select data-portal-background-mode-select[^>]*>[\s\S]*?<\/select>/,
)?.[0] || '';
const portalMessageFieldPanelStart = html.indexOf(
  '<div class="mind-portal-message-field-panel" data-portal-message-field-panel',
);
const portalMessageFieldPanelEnd = portalMessageFieldPanelStart >= 0
  ? html.indexOf('<section class="palette-area structured-palette" id="alternativePalette"', portalMessageFieldPanelStart)
  : -1;
const portalMessageFieldPanelBlock = portalMessageFieldPanelStart >= 0
  ? html.slice(
    portalMessageFieldPanelStart,
    portalMessageFieldPanelEnd > portalMessageFieldPanelStart
      ? portalMessageFieldPanelEnd
      : undefined,
  )
  : '';
const portalMessageFieldSelectBlock = portalMessageFieldPanelBlock.match(
  /<select data-portal-message-field-mode-select[^>]*>[\s\S]*?<\/select>/,
)?.[0] || '';
const portalTransitionSelectBlock = portalMessageFieldPanelBlock.match(
  /<select data-portal-transition-mode-select[^>]*>[\s\S]*?<\/select>/,
)?.[0] || '';
const balanceEnergySelectBlock = html.match(
  /<select data-mind-portal-mode-select[^>]*>[\s\S]*?<\/select>/,
)?.[0] || '';
assert(
  /<option value="solid-a">Nincs dinamikus effekt<\/option>[\s\S]*?<option value="static-matter">Statikus köd\/szigetek<\/option>[\s\S]*?<option value="wandering-mist" selected>Vándorló köd<\/option>[\s\S]*?<option value="living-archipelago">Élő szigetvilág<\/option>[\s\S]*?<option value="forming-clouds">Keletkező energiafelhők<\/option>/.test(
    portalMessageFieldSelectBlock,
  ) &&
    !/(dual-tide|magnetic-membrane|breathing-lens|cellular-field)/.test(
      portalMessageFieldSelectBlock,
    ) &&
    ['dual-tide', 'magnetic-membrane', 'breathing-lens', 'cellular-field'].every((mode) =>
      balanceEnergySelectBlock.includes(`value="${mode}"`)) &&
    html.includes('src="./color_lab_portal_message_field.js"') &&
    html.includes('src="./color_lab_portal_message_field_renderer.js"') &&
    html.includes('PortalMessageFieldRenderer.renderFrame(') &&
    html.includes('PortalMessageField.advancePhase('),
  'Portal endpoint must expose the exact A-base/B-matter modes without stealing the separate Balance energy modes',
);
assert(
  /<option value="pigment-spread" selected>Pigmentterjedés<\/option>[\s\S]*?<option value="island-takeover">Szigetes átalakulás<\/option>[\s\S]*?<option value="liquid-remap">Folyékony színátírás<\/option>/.test(
    portalTransitionSelectBlock,
  ) &&
    portalMessageFieldPanelBlock.includes('data-portal-transition-controls-scroll') &&
    portalMessageFieldPanelBlock.includes('data-portal-transition-mode-reset') &&
    html.indexOf('src="./color_lab_portal_message_field_renderer.js"') <
      html.indexOf('src="./color_lab_portal_transition.js"') &&
    html.indexOf('src="./color_lab_portal_transition.js"') <
      html.indexOf('src="./color_lab_portal_transition_renderer.js"') &&
    html.indexOf('src="./color_lab_portal_transition_renderer.js"') <
      html.indexOf('src="./color_lab_portal_transition_player.js"') &&
    html.includes('PortalTransitionPlayer.createPlayback(') &&
    html.includes("role: 'full-background'"),
  'Full-background controls must expose the three spatial transforms and join the shared reversible animation group',
);
const portalTransitionControlsRuntime = html.match(
  /function renderPortalTransitionControls\(wrap, mode\) \{[\s\S]*?function resetPortalTransitionMode\(wrap\) \{[\s\S]*?\n    \}/,
)?.[0] || '';
assert(
  html.includes('backgroundTransitionMode: PortalMessageTransition.defaults.mode') &&
    html.includes('backgroundTransitionSettingsByMode') &&
    html.includes('backgroundTransitionCanvasAvailable: false') &&
    portalTransitionControlsRuntime.includes('PortalMessageTransition.controlsForMode(mode)') &&
    portalTransitionControlsRuntime.includes('data-portal-transition-control-range') &&
    portalTransitionControlsRuntime.includes('data-portal-transition-control-number') &&
    portalTransitionControlsRuntime.includes("range.addEventListener('input'") &&
    portalTransitionControlsRuntime.includes("number.addEventListener('change'") &&
    portalTransitionControlsRuntime.includes("number.addEventListener('blur'") &&
    !portalTransitionControlsRuntime.includes("number.addEventListener('input'") &&
    /function capturePortalBalanceFrame\([\s\S]*?sampleMoneyFlowField\([\s\S]*?sampleMindPortalActivePaletteColor\([\s\S]*?sampleField\(/.test(html) &&
    /function capturePortalTargetFrames\([\s\S]*?mode:\s*'solid-a'[\s\S]*?portalTargetFrame/.test(html) &&
    /function drawPortalTransitionProgress\([\s\S]*?PortalMessageTransitionRenderer\.renderFrame\([\s\S]*?putImageData/.test(html) &&
    /function startPortalBackgroundTransition\([\s\S]*?PortalMessageTransition\.buildDescriptor\([\s\S]*?hidePortalEndpointSources\(wrap\);[\s\S]*?PortalTransitionPlayer\.createPlayback\(/.test(html) &&
    /state\.activeAnimations\.forEach\(\(\{ animation \}\) => \{\s*animation\.reverse\(\);\s*\}\);/.test(html) &&
    /layer === 'full-background'[\s\S]*?clearPortalBackgroundTransition\(wrap, state, false\);[\s\S]*?applyPortalBackgroundEndpoint/.test(html),
  'Transition runtime must preserve per-mode controls, capture both authoritative endpoints, render one canvas, reverse in place, and snap cleanly when disabled',
);
assert(
  html.includes('backgroundTransitionImageData: null') &&
    html.includes('backgroundTransitionOutputFrame: null') &&
    /function drawPortalTransitionProgress\([\s\S]*?outputFrame:\s*state\.backgroundTransitionOutputFrame/.test(html) &&
    /function drawPortalTransitionProgress\([\s\S]*?reducedMotion:\s*descriptor\.reducedMotion[\s\S]*?putImageData\(state\.backgroundTransitionImageData, 0, 0\)/.test(html),
  'Transition playback must reuse one ImageData buffer and provide a uniform reduced-motion crossfade path',
);
const portalCommitRuntime = extractFunctionSource('commitPortalMessageState');
const portalRunRuntime = extractFunctionSource('runPortalMessageMorph');
const portalOpacityRuntime = extractFunctionSource('syncPortalVisibleBackgroundOpacity');
const portalLayerToggleRuntime = extractFunctionSource('setPortalLayerEnabled');
assert(
  portalCommitRuntime.indexOf('state.animationToken += 1') >= 0 &&
    portalCommitRuntime.indexOf('cancelPortalBackgroundPreview(state)') <
      portalCommitRuntime.indexOf('state.activeAnimations.splice(0)') &&
    portalCommitRuntime.indexOf('cancelPortalMessageFieldPreview(state)') <
      portalCommitRuntime.indexOf('state.activeAnimations.splice(0)') &&
    portalCommitRuntime.indexOf('state.animationToken += 1') <
      portalCommitRuntime.indexOf('state.activeAnimations.splice(0)') &&
    portalCommitRuntime.indexOf('state.activeAnimations.splice(0)') <
      portalCommitRuntime.indexOf('applyPortalContentEndpoint(wrap, targetState)') &&
    portalCommitRuntime.indexOf('state.currentState = targetState') <
      portalCommitRuntime.indexOf('applyPortalContentEndpoint(wrap, targetState)') &&
    portalRunRuntime.includes('let animatesText = state.textMorphEnabled') &&
    portalRunRuntime.includes('let animatesTextBackground = state.textBackgroundEnabled') &&
    portalRunRuntime.includes('animatesText = false') &&
    portalRunRuntime.includes('animatesTextBackground = false') &&
    portalRunRuntime.includes('hasActiveTextMorph') &&
    portalRunRuntime.includes('hasActiveTextBackground') &&
    portalRunRuntime.includes('applyPortalContentEndpoint(wrap, targetState)') &&
    portalRunRuntime.includes('applyPortalBackgroundRestState(wrap, state, targetState)') &&
    portalRunRuntime.indexOf('state.animationToken += 1') <
      portalRunRuntime.indexOf('startPortalBackgroundTransition(wrap, state, targetState)'),
  'Portal state cleanup must invalidate stale completions before cancellation while missing WAAPI falls back per layer without suppressing the background player',
);
assert(
  portalLayerToggleRuntime.includes('state.activeAnimations.splice(index, 1)') &&
    portalLayerToggleRuntime.includes("new Set(['outgoing', 'incoming'])") &&
    portalLayerToggleRuntime.includes("clearPortalBackgroundOverlay(") &&
    portalLayerToggleRuntime.includes('clearPortalBackgroundTransition(wrap, state, false)') &&
    portalLayerToggleRuntime.includes('applyPortalBackgroundEndpoint(wrap, state, state.targetState)'),
  'Disabling one Portal layer mid-flight must remove and cancel only that layer before any later reversal',
);
assert(
  portalOpacityRuntime.includes("portalBackgroundTransitionRunning === 'true'") &&
    portalOpacityRuntime.includes('transitionCanvas.style.opacity = String(alpha)') &&
    portalOpacityRuntime.includes('applyPortalBackgroundEndpoint(wrap, state, state.currentState)') &&
    html.includes('syncPortalVisibleBackgroundOpacity(wrap, boundedValue / 100)') &&
    /function capturePortalTargetFrames\([\s\S]*?state\.messageFieldCanvasAvailable\s*\?\s*state\.messageFieldMode\s*:\s*'solid-a'/.test(html) &&
    /function schedulePortalMessageFieldFrame\([\s\S]*?typeof window\.requestAnimationFrame !== 'function'/.test(html),
  'Opacity changes and no-canvas/no-rAF fallbacks must update the one visible endpoint without exposing an invalid Portal frame',
);
assert(
  portalBackgroundHeaderBlock.indexOf('data-mind-portal-idle-canvas') >= 0 &&
    portalBackgroundHeaderBlock.indexOf('data-portal-background-response') >
      portalBackgroundHeaderBlock.indexOf('data-mind-portal-idle-canvas') &&
    portalBackgroundHeaderBlock.indexOf('data-portal-background-response') <
      portalBackgroundHeaderBlock.indexOf('data-portal-message-viewport') &&
    /\.mind-portal-message-background-response\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?border-radius:\s*inherit;[\s\S]*?z-index:\s*0;[\s\S]*?pointer-events:\s*none;[\s\S]*?overflow:\s*hidden;[\s\S]*?opacity:\s*0;[\s\S]*?\}/.test(html),
  'Portal background response must be a transparent pointer-free overlay between the energy canvas and message content',
);
assert(
  !/<div class="mind-heatmap-full-column">\s*<\/section>/.test(html),
  'The Portal lab must close its mode section without leaving a stray heatmap wrapper in the recovered browser DOM',
);
assert(
  html.includes('var(--portal-response-bloom-stop, 15.28%)') &&
    html.includes('var(--portal-response-ring-highlight, 1.92%)') &&
    html.includes('var(--portal-response-ring-color, 4.08%)') &&
    html.includes('var(--portal-response-ring-fade, 8.64%)') &&
    html.includes('var(--portal-response-seam-inner-width, 8.96%)') &&
    html.includes('var(--portal-response-center-alpha, .36)') &&
    html.includes('var(--portal-response-vignette-alpha, .2304)') &&
    html.includes('var(--portal-response-field-size, 104%)') &&
    !html.includes('var(--portal-response-bloom, 44%) *') &&
    !html.includes('var(--portal-response-ring-width, 12%) *') &&
    !html.includes('var(--portal-response-seam-width, 14%) *') &&
    !html.includes('var(--portal-response-rings, 2) *'),
  'Portal background visuals must use precomputed CSS geometry instead of unsupported custom-property multiplication',
);
assert(
  html.includes('src="./color_lab_portal_background.js"') &&
    html.indexOf('src="./color_lab_portal_message.js"') <
      html.indexOf('src="./color_lab_portal_background.js"') &&
    portalBackgroundPanelBlock.includes('Portal háttérreakció') &&
    portalBackgroundPanelBlock.includes('data-portal-background-mode-select') &&
    /<option value="energy-compression" selected>Energiakompresszió<\/option>[\s\S]*?<option value="refraction-wave">Refrakciós hullám<\/option>[\s\S]*?<option value="seam-flare">Határfény<\/option>[\s\S]*?<option value="depth-focus">Mélységi fókusz<\/option>[\s\S]*?<option value="chromatic-alert">Kromatikus riasztás<\/option>/.test(
      portalBackgroundSelectBlock,
    ) &&
    !portalBackgroundSelectBlock.includes('<option value="none"') &&
    !/data-portal-background-controls[^>]*hidden/.test(portalBackgroundPanelBlock) &&
    portalBackgroundPanelBlock.includes('data-portal-layer-toggle="text-background" aria-pressed="true"') &&
    portalBackgroundPanelBlock.includes('data-portal-background-controls-scroll') &&
    html.indexOf('data-portal-message-panel') < html.indexOf('data-portal-background-panel'),
  'Portal text-background response must expose five animated choices while its independent switch owns the no-effect state',
);
assert(
  /\.mind-portal-signature-panel,[\s\S]*?\.mind-portal-message-panel,[\s\S]*?\.mind-portal-background-panel,[\s\S]*?\.mind-portal-message-field-panel\s*\{[\s\S]*?width:\s*min\(360px,\s*calc\(100% - 40px\)\);/.test(html) &&
    /\.mind-portal-energy-controls-scroll\s*\{[\s\S]*?max-height:\s*min\(30vh, 240px\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?touch-action:\s*pan-y;/.test(html),
  'Portal background panel must share the compact phone width and scrollable active-control viewport',
);
assert(
  portalBackgroundHeaderBlock.indexOf('data-mind-portal-idle-canvas') >= 0 &&
    portalBackgroundHeaderBlock.indexOf('data-portal-message-field-canvas') >
      portalBackgroundHeaderBlock.indexOf('data-mind-portal-idle-canvas') &&
    portalBackgroundHeaderBlock.indexOf('data-portal-message-field-canvas') <
      portalBackgroundHeaderBlock.indexOf('data-portal-background-response'),
  'Settled Portal field canvas must paint between the financial field and response overlay',
);
assert(
  /@property --mind-portal-base-visual-opacity\s*\{[\s\S]*?syntax:\s*"<number>";[\s\S]*?inherits:\s*true;[\s\S]*?initial-value:\s*1;[\s\S]*?\}/.test(
    html,
  ) &&
    /\.mind-portal-message-field-canvas,\s*[\s\S]*?\.mind-portal-background-transition-canvas\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?width:\s*100%;[\s\S]*?height:\s*100%;[\s\S]*?z-index:\s*0;[\s\S]*?pointer-events:\s*none;[\s\S]*?mix-blend-mode:\s*normal;[\s\S]*?opacity:\s*0;[\s\S]*?contain:\s*paint;[\s\S]*?\}/.test(
      html,
    ),
  'Settled and transitioning backgrounds must use full-header pointer-free normal-blend canvases',
);
assert(
  portalMessageFieldPanelBlock.includes('Portal háttér-morph') &&
    portalMessageFieldPanelBlock.includes('aria-label="Portal végállapot"') &&
    !/data-portal-message-field-palette[^>]*hidden/.test(portalMessageFieldPanelBlock) &&
    !/data-portal-message-field-controls[^>]*hidden/.test(portalMessageFieldPanelBlock) &&
    /<input(?=[^>]*type="range")(?=[^>]*min="0")(?=[^>]*max="100")(?=[^>]*step="1")(?=[^>]*value="50")(?=[^>]*data-portal-message-field-center)[^>]*>/.test(
      portalMessageFieldPanelBlock,
    ) &&
    /<input(?=[^>]*type="number")(?=[^>]*min="10")(?=[^>]*max="100")(?=[^>]*step="1")(?=[^>]*value="68")(?=[^>]*data-portal-message-field-window)[^>]*>/.test(
      portalMessageFieldPanelBlock,
    ) &&
    portalMessageFieldPanelBlock.includes('data-portal-message-field-a-swatch') &&
    portalMessageFieldPanelBlock.includes('data-portal-message-field-b-swatch') &&
    portalMessageFieldPanelBlock.includes('data-portal-message-field-controls-scroll') &&
    html.includes('linear-gradient(90deg, #fffdfd 0%, #ffc4e4 50%, #8b5cf6 100%)') &&
    html.indexOf('data-portal-background-panel') <
      html.indexOf('data-portal-message-field-panel'),
  'Portal field panel must keep its palette visible and show the default wandering-mist controls',
);
assert(
  /\.mind-portal-signature-panel,[\s\S]*?\.mind-portal-background-panel,[\s\S]*?\.mind-portal-message-field-panel\s*\{[\s\S]*?width:\s*min\(360px,\s*calc\(100% - 40px\)\);/.test(
    html,
  ) &&
    /class="mind-portal-energy-controls-scroll" data-portal-message-field-controls-scroll/.test(
      portalMessageFieldPanelBlock,
    ),
  'Portal field panel must share the phone width and scrollable active-control viewport',
);
assert(
  html.includes('src="./color_lab_portal_color.js"') &&
    html.includes('src="./color_lab_portal_message_field.js"') &&
    html.includes('src="./color_lab_portal_message_field_renderer.js"') &&
    !html.includes('src="./color_lab_portal_color_renderer.js"') &&
    html.indexOf('src="./color_lab_portal_background.js"') <
      html.indexOf('src="./color_lab_portal_color.js"') &&
    html.indexOf('src="./color_lab_portal_color.js"') <
      html.indexOf('src="./color_lab_portal_message_field.js"') &&
    html.indexOf('src="./color_lab_portal_message_field.js"') <
      html.indexOf('src="./color_lab_portal_message_field_renderer.js"'),
  'Portal field model and direct-color renderer must load after their palette dependency',
);
const portalMessageFieldRuntimeStart = html.indexOf('// Portal message field runtime: start');
const portalMessageFieldRuntimeEnd = html.indexOf(
  '// Portal message field runtime: end',
  portalMessageFieldRuntimeStart,
);
const portalMessageFieldRuntimeBlock = portalMessageFieldRuntimeStart >= 0 &&
  portalMessageFieldRuntimeEnd > portalMessageFieldRuntimeStart
  ? html.slice(portalMessageFieldRuntimeStart, portalMessageFieldRuntimeEnd)
  : '';
assert(
  html.includes('messageFieldMode: PortalMessageField.defaults.mode') &&
    html.includes('messageFieldCenter: PortalMessageField.defaults.center') &&
    html.includes('messageFieldWindow: PortalMessageField.defaults.windowSize') &&
    html.includes('messageFieldSettingsByMode') &&
    html.includes('messageFieldPhaseByMode') &&
    html.includes('messageFieldFrame: 0') &&
    html.includes('messageFieldPreviewAnimation: null') &&
    /PortalMessageField\.modeOrder\.slice\(1\)\.map\(\(mode\) => \[[\s\S]*?PortalMessageField\.createModeSettings\(mode\)/.test(
      html,
    ) &&
    /PortalMessageField\.animatedModes\.map\(\(mode\) => \[mode, 0\]\)/.test(html),
  'Portal field state must own its endpoint mode, palette, per-mode settings/phases, renderer, and preview handles',
);
assert(
  portalMessageFieldRuntimeBlock.includes('function renderPortalMessageFieldControls(wrap, mode)') &&
    portalMessageFieldRuntimeBlock.includes('function setPortalMessageFieldMode(wrap, mode)') &&
    portalMessageFieldRuntimeBlock.includes('function resetPortalMessageFieldMode(wrap)') &&
    portalMessageFieldRuntimeBlock.includes('PortalMessageField.controlsForMode(activeMode)') &&
    portalMessageFieldRuntimeBlock.includes('getMindPortalActivePalette(header)') &&
    portalMessageFieldRuntimeBlock.includes('sampleMindPortalActivePaletteStop(header') &&
    portalMessageFieldRuntimeBlock.includes('--portal-message-field-scale-gradient') &&
    portalMessageFieldRuntimeBlock.includes('data-portal-message-field-control-range') &&
    portalMessageFieldRuntimeBlock.includes('data-portal-message-field-control-number') &&
    portalMessageFieldRuntimeBlock.includes('data-portal-message-field-a-swatch') &&
    portalMessageFieldRuntimeBlock.includes('data-portal-message-field-b-swatch') &&
    portalMessageFieldRuntimeBlock.includes("center.addEventListener('input'") &&
    portalMessageFieldRuntimeBlock.includes("windowInput.addEventListener('change'") &&
    portalMessageFieldRuntimeBlock.includes("windowInput.addEventListener('blur'") &&
    portalMessageFieldRuntimeBlock.includes("event.key !== 'Enter'") &&
    !portalMessageFieldRuntimeBlock.includes("windowInput.addEventListener('input'") &&
    portalMessageFieldRuntimeBlock.includes('data-last-committed-window') &&
    portalMessageFieldRuntimeBlock.includes('PortalMessageField.normalizeWindow('),
  'Portal field controls must show sampled A/B materials, update ranges immediately, and defer the deletable window number commit',
);
assert(
  portalMessageFieldRuntimeBlock.includes('function drawPortalMessageFieldFrame(wrap, now)') &&
    portalMessageFieldRuntimeBlock.includes('function initPortalMessageFieldCanvas()') &&
    portalMessageFieldRuntimeBlock.includes('function previewPortalMessageField(wrap)') &&
    portalMessageFieldRuntimeBlock.includes('function clearPortalMessageFieldCanvas(') &&
    portalMessageFieldRuntimeBlock.includes('function syncPortalMessageFieldEndpoint(') &&
    portalMessageFieldRuntimeBlock.includes('PortalMessageFieldRenderer.renderFrame(') &&
    portalMessageFieldRuntimeBlock.includes('PortalMessageField.advancePhase(') &&
    !portalMessageFieldRuntimeBlock.includes('MindPortalEnergy.advancePhase(') &&
    portalMessageFieldRuntimeBlock.includes('PortalMessageField.renderProfile(mode)') &&
    portalMessageFieldRuntimeBlock.includes('window.requestAnimationFrame(') &&
    portalMessageFieldRuntimeBlock.includes('window.cancelAnimationFrame(') &&
    portalMessageFieldRuntimeBlock.includes("'IntersectionObserver' in window") &&
    portalMessageFieldRuntimeBlock.includes('const reducedMotion = state.reducedMotionQuery?.matches === true') &&
    portalMessageFieldRuntimeBlock.includes('dynamic && reducedMotion !== true') &&
    portalMessageFieldRuntimeBlock.includes('--portal-message-solid-a') &&
    portalMessageFieldRuntimeBlock.includes("canvas?.getContext('2d', { alpha: true })") &&
    portalMessageFieldRuntimeBlock.includes('ctx ? true : false') &&
    /document\.querySelectorAll\('\[data-mind-portal-energy-controls-scroll\], \[data-portal-message-controls-scroll\], \[data-portal-background-controls-scroll\], \[data-portal-interior-motion-controls-scroll\], \[data-portal-message-field-controls-scroll\], \[data-portal-transition-controls-scroll\]'\)/.test(
      html,
    ),
  'Portal field rendering must use its own profile-driven rAF lifecycle, viewport gating, reduced-motion still, and solid-A CSS fallback',
);
assert(
  portalMessageFieldRuntimeBlock.length > 0 &&
    !portalMessageFieldRuntimeBlock.includes('setMindPortalEnergyMode(') &&
    portalMessageFieldRuntimeBlock.includes('function capturePortalBalanceFrame(') &&
    portalMessageFieldRuntimeBlock.includes('MindPortalEnergy.sampleMoneyFlowField(') &&
    portalMessageFieldRuntimeBlock.includes('MindPortalEnergy.sampleField(') &&
    !portalMessageFieldRuntimeBlock.includes('--mind-portal-touch') &&
    !portalMessageFieldRuntimeBlock.includes('--mind-portal-interaction'),
  'Portal transition capture may read authoritative Balance state but must stay isolated from accepted touch state and mode mutation',
);
assert(
  /function initMindPortalWindowOpacityControl\(\) \{[\s\S]*?syncPortalVisibleBackgroundOpacity\(wrap, boundedValue \/ 100\);/.test(
    html,
  ) &&
    /function getMindPortalBaseCanvasOpacity\(header\) \{[\s\S]*?portalMessageFieldVisible[\s\S]*?getMindPortalWindowOpacity\(header\)/.test(
      html,
    ) &&
    /canvas\.style\.opacity = getMindPortalBaseCanvasOpacity\(header\);/.test(html),
  'Window opacity and the Balance renderer must target whichever endpoint is currently visible',
);
assert(
  /function applyPortalBackgroundEndpoint\(wrap, state, targetState\) \{[\s\S]*?data-mind-portal-idle-canvas[\s\S]*?data-portal-message-field-canvas[\s\S]*?portalMessageFieldVisible[\s\S]*?--mind-portal-base-visual-opacity[\s\S]*?invalidatePortalMessageField\(wrap\);[\s\S]*?schedulePortalMessageFieldFrame\(wrap\);[\s\S]*?clearPortalMessageFieldCanvas\(wrap, state\);/.test(
    html,
  ) &&
    /\.mind-portal-message-field-canvas,[\s\S]*?background:\s*var\(--portal-message-solid-a\);/.test(html) &&
    portalMessageFieldRuntimeBlock.includes("header.style.setProperty('--portal-message-solid-a', palette.a)") &&
    !portalMessageFieldRuntimeBlock.includes('PortalMessageField.buildTransition(') &&
    /function commitPortalMessageState\(wrap, state, targetState\) \{[\s\S]*?cancelPortalMessageFieldPreview\(state\);[\s\S]*?state\.currentState = targetState;[\s\S]*?applyPortalBackgroundEndpoint\(wrap, state, targetState\);/.test(
      html,
    ),
  'Portal endpoint ownership must hide exactly one source, use a solid-A no-canvas fallback, and avoid the obsolete left/right transition model',
);
assert(
  portalMessageFieldRuntimeBlock.includes('function cancelPortalMessageFieldPreview(state)') &&
    /function previewPortalMessageField\(wrap\) \{[\s\S]*?document\.createElement\('canvas'\)[\s\S]*?mind-portal-message-field-preview-ghost[\s\S]*?drawImage\(messageFieldCanvas, 0, 0\)[\s\S]*?duration:\s*180[\s\S]*?state\.messageFieldPreviewAnimation = previewGroup/.test(
      portalMessageFieldRuntimeBlock,
    ) &&
    portalMessageFieldRuntimeBlock.includes('state.messageFieldPreviewToken += 1') &&
    portalMessageFieldRuntimeBlock.includes('ghost?.remove()') &&
    !/function previewPortalMessageField\(wrap\) \{[\s\S]*?runPortalMessageMorph\(/.test(
      portalMessageFieldRuntimeBlock,
    ) &&
    /function runPortalMessageMorph\(wrap, targetState\) \{[\s\S]*?cancelPortalMessageFieldPreview\(state\);[\s\S]*?if \(state\.activeAnimations\.length\)/.test(
      html,
    ),
  'Settled Portal field changes must use one cancelable 180ms canvas-only preview and triggers must cancel it before playback',
);
const portalBackgroundRuntimeBlock = html.match(
  /function renderPortalBackgroundControls\(wrap, mode\) \{[\s\S]*?function mindPortalEnergyColor/,
)?.[0] || '';
assert(
  html.includes("backgroundMode: 'energy-compression'") &&
    html.includes('backgroundSettingsByMode') &&
    html.includes('backgroundPreviewAnimation: null') &&
    html.includes('function configurePortalBackgroundOverlay(wrap, descriptor)') &&
    html.includes('function applyPortalBackgroundRestState(wrap, state, targetState)') &&
    html.includes('function clearPortalBackgroundOverlay(overlay)') &&
    html.includes('PortalMessageBackground.buildResponse(') &&
    /activeAnimations\.push\(\{[\s\S]*?role:\s*'text-background',[\s\S]*?responseOverlay\.animate\(backgroundDescriptor\.keyframes, backgroundOptions\)/.test(
      html,
    ) &&
    html.includes('animation.reverse()'),
  'Portal background response must share the foreground active-animation group and its in-flight reversal path',
);
assert(
  /function runPortalMessageMorph\(wrap, targetState\) \{[\s\S]*?const state = ensurePortalMessageMorphState\(wrap\);[\s\S]*?cancelPortalBackgroundPreview\(state\);[\s\S]*?if \(state\.activeAnimations\.length\)/.test(
    html,
  ) &&
    /function setPortalBackgroundMode\(wrap, mode\) \{[\s\S]*?renderPortalBackgroundControls\(wrap, mode\);[\s\S]*?if \(state\.activeAnimations\.length\) return;[\s\S]*?previewPortalBackgroundMode\(wrap\)/.test(
      html,
    ),
  'Triggering must cancel any control preview, while mode changes during an active morph must not cancel the shared response animation',
);
assert(
  /function applyPortalBackgroundRestState\(wrap, state, targetState\) \{[\s\S]*?targetState === 'message'[\s\S]*?backgroundDescriptor\.messageRest[\s\S]*?backgroundDescriptor\.balanceRest[\s\S]*?applyPortalBackgroundStyle/.test(
    html,
  ) &&
    /function clearPortalBackgroundOverlay\(overlay\) \{[\s\S]*?overlay\.removeAttribute\('style'\)[\s\S]*?overlay\.dataset\.portalBackgroundMode = 'none'/.test(
      html,
    ) &&
    /typeof responseOverlay\.animate !== 'function'[\s\S]*?commitPortalMessageState\(wrap, state, targetState\)/.test(
      html,
    ),
  'Portal background endpoints must commit message hold, clear Balance/none residue, and remain deterministic without WAAPI',
);
assert(
  portalBackgroundRuntimeBlock.includes('function renderPortalBackgroundControls(wrap, mode)') &&
    portalBackgroundRuntimeBlock.includes('PortalMessageBackground.controlsForMode(mode)') &&
    portalBackgroundRuntimeBlock.includes('data-portal-background-control-range') &&
    portalBackgroundRuntimeBlock.includes('data-portal-background-control-number') &&
    portalBackgroundRuntimeBlock.includes('function setPortalBackgroundMode(wrap, mode)') &&
    portalBackgroundRuntimeBlock.includes('function resetPortalBackgroundMode(wrap)') &&
    portalBackgroundRuntimeBlock.includes('backgroundSettingsByMode[state.backgroundMode] = PortalMessageBackground.createModeSettings(') &&
    portalBackgroundRuntimeBlock.includes('function previewPortalBackgroundMode(wrap)') &&
    portalBackgroundRuntimeBlock.includes('duration: 180') &&
    portalBackgroundRuntimeBlock.includes("number.addEventListener('change'") &&
    portalBackgroundRuntimeBlock.includes("number.addEventListener('blur'") &&
    !portalBackgroundRuntimeBlock.includes("number.addEventListener('input'") &&
    /document\.querySelectorAll\('\[data-mind-portal-energy-controls-scroll\], \[data-portal-message-controls-scroll\], \[data-portal-background-controls-scroll\], \[data-portal-interior-motion-controls-scroll\], \[data-portal-message-field-controls-scroll\], \[data-portal-transition-controls-scroll\]'\)/.test(
      html,
    ),
  'Background controls must preserve per-mode settings, reset only the active mode, defer manual commits, preview holds, and join vertical scroll routing',
);
const mindPortalSignaturePanelStart = html.indexOf(
  '<div class="mind-portal-signature-panel" data-mind-portal-signature-panel',
);
const mindPortalSignaturePanelEnd = mindPortalSignaturePanelStart >= 0
  ? html.indexOf('<div class="mind-portal-opacity-control"', mindPortalSignaturePanelStart)
  : -1;
const mindPortalSignaturePanelBlock = mindPortalSignaturePanelStart >= 0
  ? html.slice(
    mindPortalSignaturePanelStart,
    mindPortalSignaturePanelEnd > mindPortalSignaturePanelStart
      ? mindPortalSignaturePanelEnd
      : undefined,
  )
  : '';
const mindPortalTestCopyRule =
  html.match(/\.mind-portal-test-copy\s*\{[\s\S]*?\n    \}/)?.[0] || '';
assert(mindPortalSignaturePanelBlock, 'Missing standalone portal signature panel before the interaction opacity control');
const universalSignatureKinds = [
  ['balance', 'Traffic'],
  ['limits', 'Limit'],
  ['cool', 'Cool'],
  ['meadow-green', 'Meadow green'],
  ['soft-rainbow', 'Soft rainbow'],
  ['ocean-blue-serenity', 'Ocean blue serenity'],
];
assert.strictEqual(
  (mindPortalSignaturePanelBlock.match(/data-mind-portal-signature-slider=/g) || []).length,
  7,
  'Standalone portal signature panel must expose Traffic, Limit, Cool, Money flow, Meadow green, Soft rainbow, and Ocean blue serenity sliders',
);
assert.strictEqual(
  (mindPortalSignaturePanelBlock.match(/class="mind-portal-signature-window-input"/g) || []).length,
  6,
  'Every non-Money-flow signature slider must expose the same right-side 10-100 window-size input',
);
const moneyFlowSignatureRow =
  mindPortalSignaturePanelBlock.match(/<label class="mind-portal-signature-row no-window-input" data-signature-kind="money-flow">[\s\S]*?<\/label>/)?.[0] || '';
assert(
  universalSignatureKinds.every(([kind, label]) =>
    new RegExp(
      `data-signature-kind="${kind}"[\\s\\S]*?<span>${label}<\\/span>[\\s\\S]*?data-mind-portal-signature-slider="${kind}"[\\s\\S]*?<input class="mind-portal-signature-window-input"(?=[^>]*min="10")(?=[^>]*max="100")(?=[^>]*step="1")(?=[^>]*data-mind-portal-signature-window-input="${kind}")`,
    ).test(mindPortalSignaturePanelBlock),
  ) &&
    /data-signature-kind="money-flow"[\s\S]*?data-mind-portal-signature-slider="money-flow"[\s\S]*?data-mind-portal-signature-value="money-flow"/.test(
      mindPortalSignaturePanelBlock,
    ) &&
    !moneyFlowSignatureRow.includes('data-mind-portal-signature-window-input') &&
    !mindPortalSignaturePanelBlock.includes('data-mind-portal-money-flow-input') &&
    mindPortalSignaturePanelBlock.includes('data-mind-portal-window-opacity-slider') &&
    mindPortalSignaturePanelBlock.includes('data-mind-portal-window-opacity-value') &&
    /\.mind-portal-signature-row\s*\{[\s\S]*?grid-template-columns:\s*58px minmax\(0,\s*1fr\) 38px 54px;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.mind-portal-signature-row\.no-window-input,\s*\.mind-portal-window-opacity-row\s*\{[\s\S]*?grid-template-columns:\s*58px minmax\(0,\s*1fr\) 38px;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.mind-portal-signature-window-input\s*\{[\s\S]*?width:\s*54px;[\s\S]*?text-align:\s*center;[\s\S]*?\}/.test(
      html,
    ) &&
    /const mindPortalSignaturePalettes = Object\.freeze\(\{[\s\S]*?meadow-green[\s\S]*?soft-rainbow[\s\S]*?ocean-blue-serenity[\s\S]*?\}\);/.test(
      html,
    ) &&
    /function sampleMindPortalSignatureColor\(kind, position\) \{[\s\S]*?mindPortalSignaturePalettes\[kind\][\s\S]*?sampleScaleColor\(palette, position\)/.test(
      html,
    ) &&
    /function buildMindPortalSignature\(kind, center, windowSize = 28\) \{[\s\S]*?const boundedHalfWindow = clampValue\(Number\(windowSize\), 10, 100\) \/ 2;[\s\S]*?a: sampleMindPortalSignatureColor\(kind, boundedCenter - boundedHalfWindow\),[\s\S]*?b: sampleMindPortalSignatureColor\(kind, boundedCenter \+ boundedHalfWindow\),/.test(
      html,
    ) &&
    /function applyMindPortalSignature\(kind, center, windowSize = 28\) \{[\s\S]*?const boundedWindow = clampValue\(Number\(windowSize\), 10, 100\);[\s\S]*?buildMindPortalSignature\(kind, boundedCenter, boundedWindow\)[\s\S]*?data-mind-portal-signature-window-input/.test(
      html,
    ) &&
    /function initMindPortalWindowOpacityControl\(\) \{[\s\S]*?data-mind-portal-window-opacity-slider[\s\S]*?data-mind-portal-window-opacity-value[\s\S]*?--mind-portal-window-opacity/.test(
      html,
    ) &&
    /initMindPortalTestSignatureControls\(\);[\s\S]*?initMindPortalWindowOpacityControl\(\);[\s\S]*?initMindPortalEnergyControls\(\);/.test(
      html,
    ) &&
    /\.common-header-mode\[data-common-header-mode="mind"\]\s+\.common-header-card\.mind-portal-test-header::before\s*\{[\s\S]*?opacity:\s*var\(--mind-portal-base-visual-opacity,\s*var\(--mind-portal-window-opacity,\s*1\)\);[\s\S]*?\}/.test(
      html,
    ) &&
    /function getMindPortalWindowOpacity\(header\) \{[\s\S]*?--mind-portal-window-opacity[\s\S]*?\}/.test(
      html,
    ) &&
    /canvas\.style\.opacity = getMindPortalBaseCanvasOpacity\(header\);/.test(
      html,
    ) &&
    !mindPortalTestCopyRule.includes('--mind-portal-window-opacity') &&
    !/opacity\s*:\s*var\(--mind-portal-window-opacity/.test(mindPortalTestCopyRule),
  'Standalone portal signature controls must use 10-100 window inputs for every non-Money-flow source, keep Money flow slider-only, and expose a background-only portal window opacity slider',
);
for (const [paletteName, colors] of [
  ['Meadow green', ['#D9ED92', '#B5E48C', '#99D98C', '#76C893', '#52B69A', '#34A0A4', '#168AAD', '#1A759F', '#1E6091', '#184E77']],
  ['Soft rainbow', ['#FBF8CC', '#FDE4CF', '#FFCFD2', '#F1C0E8', '#CFBAF0', '#A3C4F3', '#90DBF4', '#8EECF5', '#98F5E1', '#B9FBC0']],
  ['Ocean blue serenity', ['#CAF0F8', '#ADE8F4', '#90E0EF', '#48CAE4', '#00B4D8', '#0096C7', '#0077B6']],
]) {
  for (const color of colors) {
    assert(html.includes(color), `Missing ${paletteName} test-header color: ${color}`);
  }
}
const mindPortalSignatureControlsStart = html.indexOf('function initMindPortalTestSignatureControls');
const mindPortalSignatureControlsEnd =
  mindPortalSignatureControlsStart >= 0
    ? html.indexOf('function getMindPortalWindowOpacity', mindPortalSignatureControlsStart)
    : -1;
const mindPortalSignatureControlsSource =
  mindPortalSignatureControlsStart >= 0 &&
  mindPortalSignatureControlsEnd > mindPortalSignatureControlsStart
    ? html.slice(mindPortalSignatureControlsStart, mindPortalSignatureControlsEnd)
    : '';
assert(
  /windowInputs\.forEach\(\(input\) => \{[\s\S]*?input\.dataset\.lastCommittedWindow = input\.value \|\| '28';[\s\S]*?bindDeferredWindowNumberInput\(input, \(boundedWindow\) => \{[\s\S]*?const kind = input\.dataset\.mindPortalSignatureWindowInput;[\s\S]*?applyMindPortalSignature\(kind, sliderFor\(kind\), boundedWindow\);[\s\S]*?\}, \{ min: 10, max: 100, fallback: 28 \}\);[\s\S]*?\}\);/.test(
    mindPortalSignatureControlsSource,
  ) &&
    !mindPortalSignatureControlsSource.includes("input.addEventListener('input', applyWindow") &&
    !mindPortalSignatureControlsSource.includes("input.addEventListener('change', applyWindow"),
  'Standalone portal signature window inputs must defer clamp until Enter, blur, or change while preserving the shared signature sampling path',
);
assert(
  /function buildReactiveGlassAccent\(color\) \{[\s\S]*?mixColor\(baseColor,\s*'#ffffff'[\s\S]*?return `rgba\(\$\{rgb\.r\},\$\{rgb\.g\},\$\{rgb\.b\},\.26\)`;/.test(
    html,
  ) &&
    /function applyCommonHeaderModeGradient\(mode,\s*gradient[\s\S]*?glossColor[\s\S]*?--spendee-header-gloss-accent/.test(html),
  'Reactive glass gloss must derive a lightened accent from the active header color instead of reusing a fixed purple overlay',
);

function assertAppLimitAllocationPartitionBar(screenBlock, label) {
  const partitionBar = screenBlock.match(
    /<div class="fastinfo-partition-bar category-limit-partition-bar"[\s\S]*?<\/div>/,
  )?.[0];
  assert(partitionBar, `${label} must include the app-style category limit partition bar`);
  assert(
    partitionBar.includes('data-source="lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart"') &&
      partitionBar.includes('data-limit-allocation-source="lib/features/transactions/data/limit_allocation_manager.dart"') &&
      partitionBar.includes('data-limit-sizing-source="lib/features/transactions/widgets/header_card/category_budget_stage.dart"') &&
      partitionBar.includes('data-limit-total-allocated-pct="70"') &&
      partitionBar.includes('data-limit-total-spent-pct="35"') &&
      partitionBar.includes('data-limit-free-pct="30"') &&
      partitionBar.includes('data-limit-category-count="5"') &&
      partitionBar.includes('data-limit-macro-ratio="10-20-30-10"'),
    `${label} must cite the app partition sources and expose the 70/35/30 allocation model`,
  );
  const segmentTags = [...partitionBar.matchAll(/<span class="fastinfo-partition-segment[^"]*"[^>]*>/g)].map(
    (match) => match[0],
  );
  assert.strictEqual(segmentTags.length, 11, `${label} must render 5 used + 5 remaining + 1 free allocation segments`);
  const attr = (tag, name) => tag.match(new RegExp(`${name}="([^"]+)"`))?.[1];
  assert.deepStrictEqual(
    segmentTags.map((tag) => attr(tag, 'data-limit-segment-kind')),
    ['used', 'remaining', 'used', 'remaining', 'used', 'remaining', 'used', 'remaining', 'used', 'remaining', 'free'],
    `${label} must alternate used/remaining halves for each category before the free segment`,
  );
  assert.deepStrictEqual(
    segmentTags.map((tag) => attr(tag, 'data-limit-fraction')),
    ['5', '5', '10', '10', '15', '15', '2.5', '2.5', '2.5', '2.5', '30'],
    `${label} must split 70% allocated space into half-spent category pairs and 30% free space`,
  );
  assert.deepStrictEqual(
    segmentTags.map((tag) => attr(tag, 'data-limit-slot')),
    ['3', '3', '7', '7', '19', '19', '1', '1', '18', '18', 'neutral'],
    `${label} must use selected Spendee slot colors for category pairs and neutral gray for free space`,
  );
  assert.deepStrictEqual(
    segmentTags.map((tag) => attr(tag, 'data-limit-category')),
    ['Közlekedés', 'Közlekedés', 'Élelmiszer', 'Élelmiszer', 'Lakás', 'Lakás', 'Gyorsétterem', 'Gyorsétterem', 'Rezsi', 'Rezsi', 'Szabad'],
    `${label} must label the five expense categories and the free segment`,
  );
  for (const tag of segmentTags.slice(0, 10)) {
    const slot = attr(tag, 'data-limit-slot');
    const fraction = attr(tag, 'data-limit-fraction');
    assert(
      tag.includes(`--segment-color:var(--slot-gradient-${slot})`) &&
        tag.includes(`--segment-width:${fraction}%`),
      `${label} category segment ${slot}/${fraction} must source color from the matching Spendee slot gradient and expose its width`,
    );
  }
  assert(
    /\.category-limit-partition-bar \{[\s\S]*?height:\s*9px;[\s\S]*?border-radius:\s*999px;[\s\S]*?background:\s*var\(--gray-200\);[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.66\);/.test(
      html,
    ) &&
      !/\.category-limit-partition-bar \{[^}]*?height:\s*14px;/.test(html) &&
      !/\.category-limit-partition-bar \{[^}]*?border:\s*1\.6px solid var\(--white\);/.test(html) &&
      !/\.category-limit-partition-bar \{[^}]*?border-radius:\s*0;/.test(html) &&
      !/\.category-limit-partition-bar \{[^}]*?border-top:\s*1\.6px solid var\(--white\);[^}]*?border-bottom:\s*1\.6px solid var\(--white\);/.test(html) &&
      !/\.category-limit-partition-bar \{[^}]*?clip-path:\s*inset\(0 round 0\);/.test(html) &&
      /\.fastinfo-partition-segment\.used \{[\s\S]*?opacity:\s*1;/.test(html) &&
      /\.fastinfo-partition-segment\.remaining \{[\s\S]*?opacity:\s*\.70;/.test(html) &&
      /\.fastinfo-partition-segment\.free \{[\s\S]*?background:\s*var\(--gray-200\);/.test(html),
    `${label} must follow the app's allocation model but render as a lower-profile 9px pill with a subtle 1px border`,
  );
}

function assertNoPreviousComparisonPartitionStrip(screenBlock, label) {
  assert(
    !screenBlock.includes('fastinfo-first-idea-comparison') &&
      !screenBlock.includes('fastinfo-first-idea-fill') &&
      !screenBlock.includes('first-soft-three-zone'),
    `${label} must remove the previous soft three-zone comparison strip and keep only the current app allocation pill`,
  );
  assert(
    !html.includes('.fastinfo-first-idea-comparison') &&
      !html.includes('.fastinfo-first-idea-fill'),
    'Previous soft three-zone comparison strip CSS must be removed globally',
  );
}

const lowerFastinfoStage1Screen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-fastinfo-screen spendee-fastinfo-stage1-screen" data-screen="alt-fastinfo-stage1"[\s\S]*?<div class="screen-title">A1B2/,
)?.[0];
assert(lowerFastinfoStage1Screen, 'Missing lower Spendee fastinfo stage 1 screen block');
assert(
  lowerFastinfoStage1Screen.includes('data-reference="/storage/emulated/0/spendee/fastinfo.png"') &&
    lowerFastinfoStage1Screen.includes('data-fastinfo-state="stage1"') &&
    lowerFastinfoStage1Screen.includes('data-fastinfo-overlay-mode="pushdown"') &&
    lowerFastinfoStage1Screen.includes('data-fastinfo-layout="header-stage1"'),
  'Fastinfo stage 1 screen must cite the fastinfo reference and use the sticky progress-only pushdown model',
);
assert(
  lowerFastinfoStage1Screen.includes('<span class="fastinfo-handle" aria-hidden="true"></span>') &&
    !lowerFastinfoStage1Screen.includes('<button class="fastinfo-handle"'),
  'Fastinfo handle must be only a thin strip, not a separate glossy button control',
);
assert(
  /<header class="app-header spendee-header fastinfo-stage1-header"[\s\S]*?<section class="spendee-fastinfo-panel"[\s\S]*?<\/section>\s*<\/header>/.test(
    lowerFastinfoStage1Screen,
  ) &&
    lowerFastinfoStage1Screen.includes('class="spendee-fastinfo-panel"') &&
    lowerFastinfoStage1Screen.includes('class="fastinfo-partition-bar category-limit-partition-bar"'),
  'Fastinfo stage 1 header must contain the partition progress bar inside the expanded header container',
);
assertAppLimitAllocationPartitionBar(lowerFastinfoStage1Screen, 'Fastinfo stage 1');
assertNoPreviousComparisonPartitionStrip(lowerFastinfoStage1Screen, 'Fastinfo stage 1');
assert.strictEqual(
  (lowerFastinfoStage1Screen.match(/class="fastinfo-chart-card\b/g) || []).length,
  0,
  'Fastinfo stage 1 must not include chart cards',
);
assert(
  !lowerFastinfoStage1Screen.includes('class="fastinfo-ratio-row"') &&
    !lowerFastinfoStage1Screen.includes('class="fastinfo-chart-grid"'),
  'Fastinfo stage 1 must contain only the progress partition content, not ratio or chart sections',
);
assert(
  /\.fastinfo-stage1-header \{[\s\S]*?height:\s*162px;[\s\S]*?overflow:\s*hidden;/.test(
    html,
  ) &&
    /\.fastinfo-stage1-header \.spendee-fastinfo-panel \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?top:\s*92px;[\s\S]*?bottom:\s*16px;/.test(
      html,
    ) &&
    /\.spendee-fastinfo-stage1-screen \.home-content \{[\s\S]*?top:\s*calc\(var\(--spendee-header-top\) \+ 174px\);/.test(
      html,
    ),
  'Fastinfo stage 1 header bottom must align with the original type-pill bottom and push the app content down',
);

const lowerFastinfoStage1EmptyScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-fastinfo-screen spendee-fastinfo-stage1-screen spendee-fastinfo-stage1-empty-screen" data-screen="alt-fastinfo-stage1-empty"[\s\S]*?<div class="screen-title">A1C/,
)?.[0];
assert(lowerFastinfoStage1EmptyScreen, 'Missing lower Spendee fastinfo stage 1 no-limit duplicated screen block');
assert(
  lowerFastinfoStage1EmptyScreen.includes('data-reference="/storage/emulated/0/spendee/fastinfo.png"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-fastinfo-state="stage1-empty"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-fastinfo-limit-state="none"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-fastinfo-overlay-mode="pushdown"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-fastinfo-layout="header-stage1"'),
  'Fastinfo stage 1 no-limit screen must cite the fastinfo reference and use the same sticky pushdown stage1 header model with an explicit none limit state',
);
assert(
  lowerFastinfoStage1EmptyScreen.includes('<span class="fastinfo-handle" aria-hidden="true"></span>') &&
    !lowerFastinfoStage1EmptyScreen.includes('<button class="fastinfo-handle"'),
  'Fastinfo stage 1 no-limit handle must remain only a thin strip',
);
assert(
  /<header class="app-header spendee-header fastinfo-stage1-header"[\s\S]*?<section class="spendee-fastinfo-panel fastinfo-empty-panel"[\s\S]*?<\/section>\s*<\/header>/.test(
    lowerFastinfoStage1EmptyScreen,
  ) &&
    lowerFastinfoStage1EmptyScreen.includes('data-empty-state="category-limit-none"') &&
    lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-partition-row fastinfo-balance-explainer"') &&
    lowerFastinfoStage1EmptyScreen.includes('<span>Tartalék</span>') &&
    !lowerFastinfoStage1EmptyScreen.includes('mínusznál üres') &&
    !lowerFastinfoStage1EmptyScreen.includes('negatívnál üres') &&
    !lowerFastinfoStage1EmptyScreen.includes('Balance =') &&
    !lowerFastinfoStage1EmptyScreen.includes('összbevétel − összkiadás') &&
    lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-balance-progress"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-balance-progress="no-limit"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-balance-ratio="0"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-balance-direction="decreasing"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-balance-state="negative-floor"') &&
    lowerFastinfoStage1EmptyScreen.includes('data-balance-empty-floor="true"') &&
    !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-empty-state"') &&
    !lowerFastinfoStage1EmptyScreen.includes('Nincs kategórialimit beállítva') &&
    !lowerFastinfoStage1EmptyScreen.includes('Állíts be limiteket kategóriákhoz'),
  'Fastinfo stage 1 no-limit header must use a simple one-word reserve concept above the decreasing balance progress bar',
);
assert(
  !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-partition-bar category-limit-partition-bar"') &&
    !lowerFastinfoStage1EmptyScreen.includes('data-limit-total-allocated-pct') &&
    !lowerFastinfoStage1EmptyScreen.includes('data-limit-macro-ratio') &&
    !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-partition-segment') &&
    !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-chart-card') &&
    !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-ratio-row"') &&
    !lowerFastinfoStage1EmptyScreen.includes('class="fastinfo-chart-grid"'),
  'Fastinfo stage 1 no-limit screen must not render allocation partition data, ratio row or chart cards',
);
assert(
  /\.fastinfo-empty-panel \{[\s\S]*?display:\s*block;[\s\S]*?\}/.test(html) &&
    /\.fastinfo-balance-explainer \{[\s\S]*?display:\s*block;[\s\S]*?font-size:\s*13px;[\s\S]*?line-height:\s*1\.05;/.test(html) &&
    !/\.fastinfo-balance-explainer span:last-child/.test(html) &&
    /\.fastinfo-balance-progress \{[\s\S]*?--balance-progress-pct:\s*0%;[\s\S]*?margin-top:\s*7px;[\s\S]*?width:\s*100%;[\s\S]*?height:\s*9px;[\s\S]*?border-radius:\s*999px;/.test(html) &&
    /\.fastinfo-balance-progress::before \{[\s\S]*?width:\s*var\(--balance-progress-pct\);[\s\S]*?background:\s*#fff;/.test(html) &&
    !/\.fastinfo-balance-progress::after/.test(html),
  'Fastinfo stage 1 no-limit balance progress must sit at the same vertical position as the partition bar, match its 9px height, and use a white decreasing fill without text',
);
assert(
  /\.spendee-fastinfo-stage1-empty-screen \.home-content \{[\s\S]*?top:\s*calc\(var\(--spendee-header-top\) \+ 174px\);/.test(
    html,
  ),
  'Fastinfo stage 1 no-limit screen must push the app content down the same way as the active stage1 screen',
);

const lowerFastinfoStage2Screen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-fastinfo-screen spendee-fastinfo-stage2-screen" data-screen="alt-fastinfo-stage2"[\s\S]*?<div class="screen-title">A1D/,
)?.[0];
assert(lowerFastinfoStage2Screen, 'Missing lower Spendee fastinfo stage 2 screen block');
assert(
  lowerFastinfoStage2Screen.includes('data-reference="/storage/emulated/0/spendee/fastinfo.png"') &&
    lowerFastinfoStage2Screen.includes('data-fastinfo-state="stage2"') &&
    lowerFastinfoStage2Screen.includes('data-fastinfo-overlay-mode="pushdown"') &&
    lowerFastinfoStage2Screen.includes('data-fastinfo-layout="header-expanded"'),
  'Fastinfo stage 2 screen must cite the fastinfo reference and use the expanded-header pushdown model',
);
assert(
  lowerFastinfoStage2Screen.includes('<span class="fastinfo-handle" aria-hidden="true"></span>') &&
    !lowerFastinfoStage2Screen.includes('<button class="fastinfo-handle"'),
  'Fastinfo stage 2 handle must be only a thin strip, not a separate glossy button control',
);
assert(
  /<header class="app-header spendee-header fastinfo-expanded-header"[\s\S]*?<section class="spendee-fastinfo-panel"[\s\S]*?<\/section>\s*<\/header>/.test(
    lowerFastinfoStage2Screen,
  ) &&
    lowerFastinfoStage2Screen.includes('class="spendee-fastinfo-panel"') &&
    lowerFastinfoStage2Screen.includes('class="fastinfo-partition-bar category-limit-partition-bar"'),
  'Fastinfo stage 2 header must keep the partition progress bar as the upper content',
);
assertAppLimitAllocationPartitionBar(lowerFastinfoStage2Screen, 'Fastinfo stage 2');
assertNoPreviousComparisonPartitionStrip(lowerFastinfoStage2Screen, 'Fastinfo stage 2');
assert.strictEqual(
  (lowerFastinfoStage2Screen.match(/class="fastinfo-chart-card\b/g) || []).length,
  3,
  'Fastinfo stage 2 must show the three mock chart cards under the partition progress bar',
);
assert(
  /\.fastinfo-expanded-header \{[\s\S]*?height:\s*350px;[\s\S]*?overflow:\s*hidden;/.test(
    html,
  ) &&
    /\.fastinfo-expanded-header \.spendee-fastinfo-panel \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?top:\s*126px;[\s\S]*?bottom:\s*22px;/.test(
      html,
    ) &&
    /\.spendee-fastinfo-stage2-screen \.home-content \{[\s\S]*?top:\s*calc\(var\(--spendee-header-top\) \+ 362px\);/.test(
      html,
    ),
  'Fastinfo stage 2 header must become taller, contain the full fastinfo panel, and push the app content down',
);
assert(
  !/\.spendee-fastinfo-panel \{[\s\S]*?top:\s*calc\(var\(--spendee-header-top\) \+ 70px\);/.test(
    html,
  ) &&
    !lowerFastinfoStage1Screen.includes('Fastinfo: overlayként ráprintel') &&
    !lowerFastinfoStage2Screen.includes('Fastinfo: overlayként ráprintel'),
  'Fastinfo screens must not keep the previous external overlay/print-over model',
);

const lowerBackheaderScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-backheader-screen" data-screen="alt-backheader"[\s\S]*?<div class="screen-title">A1E/,
)?.[0];
assert(lowerBackheaderScreen, 'Missing lower Spendee duplicated backheader screen block');
assert(
  lowerBackheaderScreen.includes('data-source="lib/features/transactions/widgets/header_card/backheader_style_surface.dart"') &&
    lowerBackheaderScreen.includes('data-source-editor="lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart"') &&
    lowerBackheaderScreen.includes('data-backheader-stage="browse"'),
  'Backheader screen must cite the app backheader surface and budget editor sources and start in browse state',
);
assert(
  lowerBackheaderScreen.includes('class="spendee-backheader-card"') &&
    lowerBackheaderScreen.includes('data-color-target="backheader-category-color"') &&
    lowerBackheaderScreen.includes('data-color-var="--spendee-backheader-category-color"') &&
    !/<(?:header|section)[^>]*class="[^"]*spendee-backheader-card[^"]*"[^>]*data-color-target="header-card"/.test(lowerBackheaderScreen),
  'Backheader card must be a separate category-color target, not a normal reactive header-card target',
);
assert(
  /class="backheader-browse-state"[^>]*data-backheader-browse-state/.test(lowerBackheaderScreen) &&
    /class="backheader-focus-state"[^>]*data-backheader-focus-state[^>]*hidden/.test(lowerBackheaderScreen),
  'Backheader prototype must contain separate browse and focused inline states, with focus hidden initially',
);
assert(
  /button class="backheader-center-badge"[^>]*data-backheader-focus-trigger/.test(lowerBackheaderScreen) &&
    lowerBackheaderScreen.includes('aria-label="Focus category limit"') &&
    lowerBackheaderScreen.includes('backheader-center-progress-ring') &&
    lowerBackheaderScreen.includes("url('/assets/icons/lucide/handbag.svg')"),
  'Backheader browse state must make the center category badge tappable to enter focus mode',
);
assert(
  !lowerBackheaderScreen.includes('ikonlista') &&
    !lowerBackheaderScreen.includes('tap a fókuszhoz') &&
    !lowerBackheaderScreen.includes('tap a fókiszhoz'),
  'Backheader stage1/stage2 must not show the old helper text under the focused category name',
);
assert(
  /\.backheader-belt-badge,\s*\n\s*\.backheader-center-badge,\s*\n\s*\.inline-limit-icon \{[\s\S]*?background:\s*var\(--spendee-category-menu-button-bg\);[\s\S]*?border:\s*1px solid var\(--spendee-category-menu-button-border\);[\s\S]*?box-shadow:\s*inset 0 1px 0 rgba\(255,255,255,\.68\),\s*inset 0 -1px 0 rgba\(120,220,230,\.14\);[\s\S]*?backdrop-filter:\s*blur\(12px\);/.test(
    html,
  ) &&
    !/\.backheader-belt-badge::after/.test(html) &&
    !/\.backheader-center-badge::after/.test(html) &&
    !/\.inline-limit-icon::after/.test(html),
  'Backheader/subheader avatar circles must keep glossy glass styling without drawing an internal white spot',
);
assert(
  lowerBackheaderScreen.includes('class="backheader-focus-back"') &&
    lowerBackheaderScreen.includes('data-backheader-focus-back') &&
    lowerBackheaderScreen.includes('aria-label="Back to category belt"'),
  'Focused inline limit mode must expose a small top-left glass chevron back button',
);
for (const token of [
  'class="inline-limit-icon"',
  'class="inline-limit-summary"',
  'class="inline-limit-main-row"',
  'class="inline-limit-control-stack"',
  'data-inline-limit-summary',
  'data-inline-current',
  'data-inline-limit-value',
  'data-inline-limit-slider',
]) {
  assert(lowerBackheaderScreen.includes(token), `Missing inline focus-mode limit editor token: ${token}`);
}
assert(
  !lowerBackheaderScreen.includes('data-inline-limit-reset') &&
    !lowerBackheaderScreen.includes('class="inline-limit-delete"') &&
    !lowerBackheaderScreen.includes('class="inline-limit-delete-icon"') &&
    !lowerBackheaderScreen.includes('Limit törlése'),
  'Focused stage2 inline limit editor must not render a delete/trash button; slider value 0 is the delete/no-limit state',
);
assert(
  /class="inline-limit-icon"><span class="backheader-center-progress-ring"[^>]*aria-hidden="true"><\/span>/.test(
    lowerBackheaderScreen,
  ),
  'Focused stage2 icon must keep the circular progress ring on the category avatar',
);
assert(
  /<div class="inline-limit-body">\s*<span class="inline-limit-summary"[^>]*data-inline-limit-summary>[\s\S]*?<\/span>\s*<div class="inline-limit-main-row">\s*<span class="inline-limit-icon">[\s\S]*?<\/span>\s*<div class="inline-limit-control-stack">\s*<div class="inline-limit-title-row"><span class="inline-limit-title">Élelmiszer<\/span><\/div>\s*<input class="inline-limit-slider"/.test(
    lowerBackheaderScreen,
  ),
  'Focused stage2 summary must sit at the top-right while avatar, title and slider are grouped in a vertically centered row',
);
assert(
  /\.inline-limit-body \{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*9px 14px 10px 54px;[\s\S]*?\}/.test(
    html,
  ) &&
    /\.inline-limit-summary \{[\s\S]*?position:\s*absolute;[\s\S]*?right:\s*0;[\s\S]*?top:\s*0;/.test(
      html,
    ) &&
    /\.inline-limit-main-row \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;[\s\S]*?top:\s*50%;[\s\S]*?transform:\s*translateY\(-50%\);[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*62px minmax\(0,\s*1fr\);[\s\S]*?height:\s*58px;/.test(
      html,
    ) &&
    /\.inline-limit-control-stack \{[\s\S]*?height:\s*58px;[\s\S]*?max-height:\s*58px;[\s\S]*?display:\s*flex;[\s\S]*?flex-direction:\s*column;[\s\S]*?justify-content:\s*center;/.test(
      html,
    ),
  'Focused stage2 summary must be top-right, while avatar and title+slider stack are vertically centered together, use the freed delete-button space, and stay within the avatar height',
);
assert(!html.includes('.inline-limit-delete'), 'Inline limit delete/trash CSS must be removed with the button');
assert(
  /\.backheader-center-badge,\s*\n\s*\.inline-limit-icon \{[\s\S]*?overflow:\s*visible;/.test(html) &&
    /\.backheader-center-progress-ring \{[\s\S]*?inset:\s*-5px;[\s\S]*?z-index:\s*1;/.test(html) &&
    /\.inline-limit-icon \.slot-icon \{[\s\S]*?z-index:\s*2;/.test(html),
  'Focused stage2 circular progress ring must be visibly layered around the category avatar, not clipped behind it',
);
assert(
  !lowerBackheaderScreen.includes('class="inline-limit-progress"') &&
    !html.includes('.inline-limit-progress'),
  'Focused stage2 inline limit state must remove the horizontal progress bar and keep only the icon progress ring',
);
assert(
  !lowerBackheaderScreen.includes('data-inline-limit-input') &&
    !lowerBackheaderScreen.includes('class="inline-limit-pill"') &&
    !lowerBackheaderScreen.includes('Kategória limit') &&
    /<input class="inline-limit-slider"[^>]*type="range"[^>]*min="0"[^>]*max="200000"[^>]*step="5000"[^>]*value="125000"[^>]*data-inline-limit-slider/.test(
      lowerBackheaderScreen,
    ),
  'Inline limit editor must remove the numeric input pill and use the range slider as the editable limit control',
);
assert(
  alternativeSection.indexOf('id="backheaderOpacityScaleLab"') >
    alternativeSection.indexOf('data-screen="alt-backheader"') &&
    alternativeSection.indexOf('id="backheaderOpacityScaleLab"') <
      alternativeSection.indexOf('data-screen="alt-category-sheet"'),
  'Dedicated backheader opacity slider must be rendered directly inside the backheader screen column before the next duplicated screen',
);
const lowerBackheaderColumn = alternativeSection.match(
  /<div class="screen-column">\s*<div class="screen-title">A1D · Backheader \+ inline limit<\/div>[\s\S]*?<div class="screen-title">A1E/,
)?.[0];
assert(lowerBackheaderColumn, 'Missing A1D backheader screen column block');
assert(
  /<\/section>\s*<section class="backheader-opacity-scale-lab" id="backheaderOpacityScaleLab"/.test(
    lowerBackheaderColumn,
  ) &&
    lowerBackheaderColumn.indexOf('id="backheaderOpacityScaleLab"') >
      lowerBackheaderColumn.indexOf('data-screen="alt-backheader"'),
  'Backheader opacity lab must sit immediately under the A1D backheader phone screen, not below the whole screen row',
);
const backheaderOpacityLab = alternativeSection.match(
  /<section class="backheader-opacity-scale-lab" id="backheaderOpacityScaleLab"[\s\S]*?<\/section>/,
)?.[0];
assert(backheaderOpacityLab, 'Missing backheader opacity scale lab block');
assert(
  backheaderOpacityLab.includes('data-backheader-opacity-scale-track') &&
    backheaderOpacityLab.includes('data-backheader-opacity-handle') &&
    !backheaderOpacityLab.includes('data-reactive-window'),
  'Backheader background opacity control must be a simple handle slider, not a window slider',
);
assert(
  /\.spendee-backheader-card \{[\s\S]*?top:\s*var\(--spendee-header-top\);[\s\S]*?height:\s*var\(--spendee-header-h\);[\s\S]*?border-radius:\s*20px;[\s\S]*?border:\s*1px solid rgba\(255,255,255,\.72\);/.test(html),
  'Backheader card must reuse the lower header footprint with a glass border',
);

const lowerBackheaderExpandedScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-backheader-screen spendee-backheader-expanded-screen" data-screen="alt-backheader-expanded"[\s\S]*?<div class="screen-title">A1F/,
)?.[0];
assert(lowerBackheaderExpandedScreen, 'Missing higher duplicated backheader screen block');
assert(
  lowerBackheaderExpandedScreen.includes('class="spendee-backheader-card spendee-backheader-card-expanded"') &&
    lowerBackheaderExpandedScreen.includes('data-backheader-stage="browse"') &&
    lowerBackheaderExpandedScreen.includes('data-color-target="backheader-category-color"') &&
    lowerBackheaderExpandedScreen.includes('data-color-var="--spendee-backheader-category-color"'),
  'Higher duplicated backheader must use the same category-color target and a distinct taller backheader card class',
);
assert(
  lowerBackheaderExpandedScreen.includes('class="backheader-extra-strip"') &&
    lowerBackheaderExpandedScreen.includes('data-backheader-extra-context="category-limit-partition"') &&
    lowerBackheaderExpandedScreen.indexOf('class="backheader-belt-title"') <
      lowerBackheaderExpandedScreen.indexOf('class="backheader-extra-strip"'),
  'Higher duplicated backheader must use its extra lower area for the same category partition progress under the icon belt',
);
assert(
  (lowerBackheaderExpandedScreen.match(/class="fastinfo-partition-bar category-limit-partition-bar"/g) || []).length >= 2 &&
    /<div class="backheader-extra-strip"[^>]*data-backheader-extra-context="category-limit-partition"[\s\S]*?<div class="fastinfo-partition-bar category-limit-partition-bar"[\s\S]*?data-limit-total-allocated-pct="70"/.test(
      lowerBackheaderExpandedScreen,
    ) &&
  lowerBackheaderExpandedScreen.includes('data-backheader-stage2-limit-state="active"') &&
    lowerBackheaderExpandedScreen.includes('class="backheader-stage2-limit-panel"') &&
    lowerBackheaderExpandedScreen.includes('class="fastinfo-partition-bar category-limit-partition-bar"') &&
    lowerBackheaderExpandedScreen.includes('data-limit-total-allocated-pct="70"') &&
    lowerBackheaderExpandedScreen.includes('data-limit-macro-ratio="10-20-30-10"') &&
    lowerBackheaderExpandedScreen.includes('data-backheader-stage2-limit-state="none"') &&
    lowerBackheaderExpandedScreen.includes('class="backheader-stage2-no-limit"') &&
    lowerBackheaderExpandedScreen.includes('Hozz létre limitet'),
  'Higher duplicated backheader stage1 expanded and focus/stage2 expanded areas must both show the partition progress bar when a limit exists, with a no-limit fallback message for stage2',
);
assertAppLimitAllocationPartitionBar(lowerBackheaderExpandedScreen, 'Higher backheader stage2 expanded');
assert(
  !lowerBackheaderExpandedScreen.includes('class="backheader-status-line"') &&
    !lowerBackheaderExpandedScreen.includes('data-backheader-status-text="spent"') &&
    !lowerBackheaderExpandedScreen.includes('data-backheader-status-text="remaining"') &&
    !lowerBackheaderExpandedScreen.includes('Elköltve') &&
    !lowerBackheaderExpandedScreen.includes('Maradt') &&
    !lowerBackheaderExpandedScreen.includes('Napi keret') &&
    !lowerBackheaderExpandedScreen.includes('2 058 Ft') &&
    !lowerBackheaderExpandedScreen.includes('backheader-status-chip'),
  'Higher duplicated backheader browse lower area must not keep the old spent/remaining text row once the partition progress bar is used',
);
assertNoPreviousComparisonPartitionStrip(lowerBackheaderExpandedScreen, 'Higher backheader');
assert(
  /button class="backheader-center-badge"[^>]*data-backheader-focus-trigger/.test(lowerBackheaderExpandedScreen) &&
    lowerBackheaderExpandedScreen.includes('data-backheader-focus-back') &&
    lowerBackheaderExpandedScreen.includes('data-inline-limit-slider') &&
    !lowerBackheaderExpandedScreen.includes('data-inline-limit-reset') &&
    !lowerBackheaderExpandedScreen.includes('ikonlista') &&
    !lowerBackheaderExpandedScreen.includes('tap a fókuszhoz'),
  'Higher duplicated backheader must keep focus mode and inline slider controls while removing helper text and trash/delete controls',
);
assert(
    /\.spendee-backheader-card-expanded \{[\s\S]*?height:\s*162px;[\s\S]*?\}/.test(html) &&
    /\.spendee-backheader-card-expanded \.backheader-extra-strip \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?top:\s*112px;/.test(html) &&
    /\.spendee-backheader-card-expanded \.backheader-extra-strip \.fastinfo-partition-bar \{[\s\S]*?margin-top:\s*0;/.test(html) &&
    /\.backheader-stage2-limit-panel \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?top:\s*112px;/.test(html) &&
    /\.backheader-stage2-limit-panel \.fastinfo-partition-bar \{[\s\S]*?margin-top:\s*0;/.test(html) &&
    /\.category-limit-partition-bar \{[\s\S]*?height:\s*9px;/.test(html) &&
    /\.backheader-stage2-no-limit \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?top:\s*112px;/.test(html),
  'Higher duplicated backheader CSS must make the card taller and place stage1 partition, focus partition, and no-limit fallback at the raised A1B progress Y geometry',
);
assert(
  !lowerBackheaderExpandedScreen.includes('class="backheader-status-line"') &&
    !lowerBackheaderExpandedScreen.includes('data-backheader-extra-context="plain-category-status"') &&
    !html.includes('.backheader-status-chip') &&
    !html.includes('.backheader-editor-feedback-shelf'),
  'A1E must remove the old expanded status row concept and use partition progress instead',
);
assert(
  lowerBackheaderExpandedScreen.includes('class="backheader-stage2-limit-panel"') &&
    lowerBackheaderExpandedScreen.includes('data-inline-current-amount="63240"') &&
    lowerBackheaderExpandedScreen.includes('class="fastinfo-partition-segment used"') &&
    lowerBackheaderExpandedScreen.includes('class="fastinfo-partition-segment remaining"') &&
    lowerBackheaderExpandedScreen.includes('class="fastinfo-partition-segment free"') &&
    !lowerBackheaderExpandedScreen.includes('data-inline-limit-feedback-value') &&
    !lowerBackheaderExpandedScreen.includes('data-inline-limit-feedback-daily') &&
    !lowerBackheaderExpandedScreen.includes('Új limit') &&
    !lowerBackheaderExpandedScreen.includes('Napi keret'),
  'A1E focus mode must fill the extended area with the category partition progress bar instead of the old spent/remaining feedback shelf',
);
assert(
  /\.spendee-backheader-expanded-screen \.home-content \{[\s\S]*?top:\s*calc\(var\(--spendee-header-top\) \+ 174px\);/.test(html),
  'Higher duplicated backheader screen must push home content below the taller card instead of overlapping it',
);
const backheaderBeforeRule =
  html.match(/\.spendee-backheader-card::before\s*\{[^}]*\}/)?.[0] || '';
assert(
  /background:[\s\S]*?var\(--spendee-backheader-category-color\)[\s\S]*?opacity:\s*var\(--spendee-backheader-opacity\);[\s\S]*?z-index:\s*0;/.test(
    backheaderBeforeRule,
  ) &&
    !backheaderBeforeRule.includes('#18ba78') &&
    !backheaderBeforeRule.includes('var(--spendee-header-bg'),
  'Backheader background must come from category-color variables and opacity, with no hardcoded secondary green or header scale variable',
);

const lowerBackheaderLimitEditScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-backheader-screen spendee-backheader-limit-edit-screen" data-screen="alt-backheader-limit-edit-keyboard"[\s\S]*?<div class="screen-title">A2/,
)?.[0];
assert(lowerBackheaderLimitEditScreen, 'Missing A1F backheader limit amount tap-edit keyboard screen block');
const limitAmountInlineTap = lowerBackheaderLimitEditScreen.match(
  /<button class="limit-amount-inline-tap"[^>]*>[\s\S]*?<\/button>/,
)?.[0] || '';
assert(
  html.indexOf('data-screen="alt-backheader-expanded"') <
    html.indexOf('data-screen="alt-backheader-limit-edit-keyboard"') &&
    html.indexOf('data-screen="alt-backheader-limit-edit-keyboard"') <
      html.indexOf('data-screen="alt-category-sheet"'),
  'A1F backheader limit amount edit screen must be inserted next to A1E and before A2, not beside the vendor selector',
);
assert(
  lowerBackheaderLimitEditScreen.includes('data-backheader-stage="limit-edit"') &&
    lowerBackheaderLimitEditScreen.includes('data-limit-edit-mode="floating-keyboard"') &&
    lowerBackheaderLimitEditScreen.includes('data-limit-edit-source="amount-tap"') &&
    lowerBackheaderLimitEditScreen.includes('data-limit-edit-entrypoints="stage1 stage2"') &&
    lowerBackheaderLimitEditScreen.includes('data-keyboard-state="open"') &&
    lowerBackheaderLimitEditScreen.includes('data-sheet-motion="fixed"') &&
    lowerBackheaderLimitEditScreen.includes('data-background-interaction="inert"'),
  'A1F screen must explicitly model amount-tap limit editing from both stage1 and stage2 with a fixed route and inert background',
);
assert(
  lowerBackheaderLimitEditScreen.includes('backheader-edit-inert') &&
    limitAmountInlineTap.includes('class="limit-amount-inline-tap"') &&
    limitAmountInlineTap.includes('63 240 Ft / 125 000 Ft') &&
    lowerBackheaderLimitEditScreen.includes('class="inline-limit-main-row inline-limit-main-row-no-avatar"') &&
    !lowerBackheaderLimitEditScreen.includes('limit-inline-avatar') &&
    !limitAmountInlineTap.includes('category-avatar-icon') &&
    !lowerBackheaderLimitEditScreen.includes('class="inline-limit-icon"') &&
    !lowerBackheaderLimitEditScreen.includes('limit-amount-hotspot') &&
    !lowerBackheaderLimitEditScreen.includes('stage2-limit-hotspot') &&
    !lowerBackheaderLimitEditScreen.includes('class="limit-amount-hotspot stage1-limit-hotspot"') &&
    !lowerBackheaderLimitEditScreen.includes('class="limit-edit-source-strip"') &&
    !lowerBackheaderLimitEditScreen.includes('Stage 1 összeg tap') &&
    !lowerBackheaderLimitEditScreen.includes('Stage 2 összeg tap') &&
    lowerBackheaderLimitEditScreen.includes('63 240 Ft / 125 000 Ft') &&
    lowerBackheaderLimitEditScreen.includes('data-limit-edit-entrypoints="stage1 stage2"'),
  'A1F background must keep only the real limit amount tap target as a transparent inline row with no background icon/avatar, no pill styling, and no extra stage entrypoint pills',
);
assert(
  lowerBackheaderLimitEditScreen.includes('class="limit-edit-floating-card"') &&
    lowerBackheaderLimitEditScreen.includes('data-floating-limit-edit-card') &&
    lowerBackheaderLimitEditScreen.includes('data-keyboard-safe="true"') &&
    lowerBackheaderLimitEditScreen.includes('class="limit-edit-avatar" style="--avatar-color:var(--slot-gradient-7)"') &&
    /class="limit-edit-floating-card"[\s\S]*?class="limit-edit-avatar"[\s\S]*?category-avatar-icon/.test(
      lowerBackheaderLimitEditScreen,
    ) &&
    lowerBackheaderLimitEditScreen.includes('Limitösszeg') &&
    lowerBackheaderLimitEditScreen.includes('class="limit-edit-text-input"') &&
    lowerBackheaderLimitEditScreen.includes('value="125 000"') &&
    lowerBackheaderLimitEditScreen.includes('class="limit-edit-cancel"') &&
    lowerBackheaderLimitEditScreen.includes('class="limit-edit-confirm"'),
  'A1F must float a keyboard-safe numeric limit amount editor above the keyboard when the user taps the amount',
);
assert(
  lowerBackheaderLimitEditScreen.includes('class="mock-keyboard numeric-keyboard"') &&
    lowerBackheaderLimitEditScreen.includes('data-keyboard-overlay="true"') &&
    lowerBackheaderLimitEditScreen.includes('data-keyboard-type="numeric"') &&
    lowerBackheaderLimitEditScreen.includes('class="keyboard-key">1</span>') &&
    lowerBackheaderLimitEditScreen.includes('class="keyboard-key confirm">OK</span>') &&
    !lowerBackheaderLimitEditScreen.includes('qwertyuiop') &&
    !lowerBackheaderLimitEditScreen.includes('keyboardAvoidance'),
  'A1F must use a numeric keyboard overlay and must not model text keyboard avoidance by moving the route',
);
assert(
    /\.backheader-edit-inert \{[\s\S]*?opacity:\s*\.38;[\s\S]*?filter:\s*saturate\(\.78\);[\s\S]*?pointer-events:\s*none;/.test(html) &&
    /\.limit-amount-inline-tap \{[\s\S]*?appearance:\s*none;[\s\S]*?border:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;/.test(html) &&
    /\.inline-limit-main-row-no-avatar \{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);/.test(html) &&
    /\.limit-edit-avatar \{[\s\S]*?width:\s*50px;[\s\S]*?height:\s*50px;[\s\S]*?border-radius:\s*999px;[\s\S]*?background:\s*var\(--avatar-color,\s*var\(--slot-gradient-7\)\);/.test(html) &&
    !/\.limit-inline-avatar \{/.test(html) &&
    !/\.limit-amount-hotspot \{/.test(html) &&
    !/\.limit-hotspot-avatar \{/.test(html) &&
    !/\.limit-edit-source-strip \{/.test(html) &&
    /\.limit-edit-floating-card \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*20px;[\s\S]*?right:\s*20px;[\s\S]*?bottom:\s*304px;[\s\S]*?z-index:\s*8;/.test(html) &&
    /\.limit-edit-text-input \{[\s\S]*?height:\s*44px;[\s\S]*?border-radius:\s*18px;/.test(html) &&
    /\.mock-keyboard \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;[\s\S]*?bottom:\s*0;[\s\S]*?height:\s*286px;[\s\S]*?z-index:\s*7;/.test(html) &&
    /\.numeric-keyboard \.keyboard-key \{[\s\S]*?min-width:\s*92px;[\s\S]*?height:\s*44px;/.test(html),
  'A1F CSS must dim the fixed backheader, show amount hotspots, float the amount editor above a 286px keyboard, and size the numeric keyboard keys',
);
assert(
  !alternativeSection.includes('data-screen="alt-vendor-edit-keyboard"') &&
    !alternativeSection.includes('data-vendor-edit-mode="floating-keyboard"') &&
    !alternativeSection.includes('class="vendor-edit-floating-card"') &&
    !alternativeSection.includes('class="vendor-edit-text-input"'),
  'The previous vendor-adjacent floating keyboard proof must be removed after moving the concept to A1F backheader limit editing',
);

const lowerCategorySelectorScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen category-selector-screen" data-screen="alt-category-sheet"[\s\S]*?<div class="screen-title">A3/,
)?.[0];
assert(lowerCategorySelectorScreen, 'Missing redesigned A2 fullscreen category selector screen block');
assert(
  lowerCategorySelectorScreen.includes('data-reference="/storage/emulated/0/spendee/category.png"') &&
    lowerCategorySelectorScreen.includes('data-category-selector-mode="fullscreen"') &&
    lowerCategorySelectorScreen.includes('class="category-selector-route"') &&
    lowerCategorySelectorScreen.includes('data-color-target="category-selector-background"') &&
    lowerCategorySelectorScreen.includes('data-color-var="--category-selector-bg"'),
  'A2 category selector must be a fullscreen route based on /storage/emulated/0/spendee/category.png',
);
assert(
  !lowerCategorySelectorScreen.includes('class="sheet-card"') &&
    !lowerCategorySelectorScreen.includes('class="sheet-panel"') &&
    !lowerCategorySelectorScreen.includes('class="sheet-grabber"') &&
    !lowerCategorySelectorScreen.includes('class="sheet-title"') &&
    !lowerCategorySelectorScreen.includes('Szűrőbeállítás'),
  'A2 category selector must not render the old bottom-sheet/sheet-panel structure or old Szűrőbeállítás label',
);
assert(
  lowerCategorySelectorScreen.includes('class="category-selector-header"') &&
    lowerCategorySelectorScreen.includes('<div class="category-selector-title">Kategóriák</div>') &&
    lowerCategorySelectorScreen.includes('Válaszd ki a listázandó kategóriákat') &&
    lowerCategorySelectorScreen.includes('class="category-selector-search-pill"') &&
    lowerCategorySelectorScreen.includes('data-body-top="header-card-top"') &&
    lowerCategorySelectorScreen.includes('<span class="search-placeholder">Keresés kategóriák között...</span>') &&
    !lowerCategorySelectorScreen.includes('category-filter-button') &&
    !lowerCategorySelectorScreen.includes('settings'),
  'A2 fullscreen selector must have its own lightweight title/subtitle and dashboard-style category search pill, without filter/settings controls',
);
assert(
  lowerCategorySelectorScreen.includes('class="category-selector-action-row"') &&
    lowerCategorySelectorScreen.includes('data-category-action="select-all"') &&
    lowerCategorySelectorScreen.includes('data-category-action="select-none"') &&
    /<button class="category-selector-action select-all"[^>]*data-color-target="category-card-background"[^>]*data-color-var="--category-card-bg"/.test(
      lowerCategorySelectorScreen,
    ) &&
    /<button class="category-selector-action select-none"[^>]*data-color-target="category-card-background"[^>]*data-color-var="--category-card-bg"/.test(
      lowerCategorySelectorScreen,
    ) &&
    lowerCategorySelectorScreen.includes('Mindet kijelölni') &&
    lowerCategorySelectorScreen.includes('Egyiket se') &&
    !lowerCategorySelectorScreen.includes('Minden kategória'),
  'A2 fullscreen selector top row must expose explicit Mindet kijelölni and Egyiket se bulk action cards',
);
assert(
  lowerCategorySelectorScreen.includes('class="category-selector-add-row"') &&
    lowerCategorySelectorScreen.includes('data-category-action="add-new"') &&
    /<button class="category-selector-add-action"[^>]*data-color-target="category-card-background"[^>]*data-color-var="--category-card-bg"/.test(
      lowerCategorySelectorScreen,
    ) &&
    /<span class="category-selector-action-avatar"[^>]*data-color-target="category-avatar-circle"[^>]*data-color-var="--category-avatar-bg"/.test(
      lowerCategorySelectorScreen,
    ) &&
    lowerCategorySelectorScreen.includes('Új kategória'),
  'A2 fullscreen selector must keep Új kategória as a separate dashed, fully recolorable add-row trigger, not as one of the bulk select options',
);
const selectorCards = [
  ...lowerCategorySelectorScreen.matchAll(/<article class="category-card category-selector-card[^"]*"[\s\S]*?<\/article>/g),
].map((match) => match[0]);
assert(selectorCards.length >= 16, 'A2 fullscreen selector must fill the imagined fullscreen viewport with at least sixteen compact category cards');
for (const [index, block] of selectorCards.entries()) {
  assert(
    block.includes('category-card-avatar-circle') &&
      block.includes('data-edit-trigger="longpress"') &&
      block.includes('data-color-target="category-avatar-circle"') &&
      block.includes('data-color-var="--category-avatar-bg"') &&
      block.includes('category-avatar-icon') &&
      block.includes('class="category-selector-copy"') &&
      block.includes('class="card-title"') &&
      block.includes('class="card-subtitle"') &&
      block.includes('tranzakció') &&
      block.includes('class="category-selector-check'),
    `A2 compact category card ${index + 1} must follow the simplified layout: avatar, title/count, check circle, and longpress edit trigger`,
  );
  assert(
    !block.includes('category-selector-drag-dots') && !block.includes('category-selector-color-dot'),
    `A2 compact category card ${index + 1} must not contain drag handles or transaction-count color dots`,
  );
}
assert(
  (lowerCategorySelectorScreen.match(/class="category-selector-check selected"/g) || []).length >= 4 &&
    (lowerCategorySelectorScreen.match(/class="category-selector-check\b/g) || []).length >= 16,
  'A2 compact cards must show both selected and unselected check-circle states',
);
assert(
  lowerCategorySelectorScreen.includes('class="category-selector-footer"') &&
    lowerCategorySelectorScreen.includes('4 kategória kijelölve') &&
    lowerCategorySelectorScreen.includes('Összes tranzakció: 7 378') &&
    lowerCategorySelectorScreen.includes('class="category-selector-footer-actions"') &&
    /<button class="category-selector-cancel"[^>]*data-color-target="bottom-cancel-button"[^>]*data-color-var="--category-selector-cancel-bg"[^>]*>Cancel<\/button>/.test(
      lowerCategorySelectorScreen,
    ) &&
    /<button class="category-selector-apply"[^>]*data-color-target="bottom-action-button"[^>]*data-color-var="--category-selector-apply-bg"[^>]*>OK<\/button>/.test(
      lowerCategorySelectorScreen,
    ) &&
    !lowerCategorySelectorScreen.includes('Alkalmaz'),
  'A2 fullscreen selector must end with a sticky selected-count footer and dual Cancel/OK bottom actions',
);
assert(
  /--category-selector-bg:\s*var\(--sheet-bg\);/.test(html) &&
    /--category-selector-apply-bg:\s*var\(--primary\);/.test(html) &&
    /--category-selector-cancel-bg:\s*var\(--white\);/.test(html) &&
    /body \{[\s\S]*?background:\s*linear-gradient\(135deg,\s*#dbeafe,\s*#f8fafc 42%,\s*#e2e8f0\);/.test(html) &&
    /\.category-selector-route \{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?background:\s*var\(--category-selector-bg\);/.test(html) &&
    /\.category-selector-search-pill \{[\s\S]*?margin-top:\s*21px;/.test(html) &&
    /\.category-selector-action-row \{[\s\S]*?padding:\s*0 2px;[\s\S]*?gap:\s*12px;/.test(html) &&
    /\.category-selector-action \{[\s\S]*?min-height:\s*62px;[\s\S]*?grid-template-columns:\s*38px minmax\(0,\s*1fr\) 24px;[\s\S]*?padding:\s*10px 13px;/.test(html) &&
    /\.category-selector-add-row \{[\s\S]*?margin-top:\s*8px;[\s\S]*?padding:\s*0 2px;/.test(html) &&
    /\.category-selector-add-action \{[\s\S]*?height:\s*42px;[\s\S]*?border-style:\s*dashed;/.test(html) &&
    /\.category-selector-search-pill \.search-placeholder,\s*\.vendor-selector-search-pill \.search-placeholder \{[\s\S]*?color:\s*var\(--gray-500\);[\s\S]*?font-size:\s*14px;[\s\S]*?font-weight:\s*500;/.test(html) &&
    /\.category-selector-body \{[\s\S]*?top:\s*285px;[\s\S]*?bottom:\s*106px;/.test(html) &&
    /\.category-selector-grid \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*8px 10px;/.test(html) &&
    /\.category-selector-card \{[\s\S]*?min-height:\s*56px;[\s\S]*?grid-template-columns:\s*34px minmax\(0,\s*1fr\) 22px;[\s\S]*?border-radius:\s*15px;/.test(html) &&
    /\.category-selector-footer \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*20px;[\s\S]*?right:\s*20px;[\s\S]*?bottom:\s*22px;/.test(html) &&
    /\.category-selector-footer-actions \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*8px;/.test(html) &&
    /\.category-selector-cancel,\s*\.category-selector-apply \{[\s\S]*?height:\s*48px;[\s\S]*?border-radius:\s*24px;/.test(html),
  'A2 fullscreen selector CSS must implement a light canvas fallback, recolorable fullscreen route, segmented action row, denser simplified cards and sticky dual-action footer',
);

const lowerVendorSelectorScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen vendor-selector-screen" data-screen="alt-vendor-sheet"[\s\S]*?<div class="screen-title">A3B/,
)?.[0];
assert(lowerVendorSelectorScreen, 'Missing redesigned A3 fullscreen vendor selector screen block');
assert(
  lowerVendorSelectorScreen.includes('data-vendor-selector-mode="fullscreen"') &&
    lowerVendorSelectorScreen.includes('data-vendor-sort="abc"') &&
    lowerVendorSelectorScreen.includes('class="vendor-selector-route"') &&
    lowerVendorSelectorScreen.includes('class="vendor-search-pill vendor-selector-search-pill"') &&
    lowerVendorSelectorScreen.includes('data-body-top="header-card-top"') &&
    lowerVendorSelectorScreen.includes('<span class="search-placeholder">Keresés vendorok között...</span>'),
  'A3 vendor selector must be a fullscreen ABC selector with dashboard-style vendor search',
);
assert(
  !lowerVendorSelectorScreen.includes('class="sheet-card"') &&
    !lowerVendorSelectorScreen.includes('class="sheet-panel"') &&
    !lowerVendorSelectorScreen.includes('class="sheet-grabber"') &&
    !lowerVendorSelectorScreen.includes('class="sheet-title"') &&
    !lowerVendorSelectorScreen.includes('Új vendor') &&
    !lowerVendorSelectorScreen.includes('data-category-action="add-new"'),
  'A3 vendor selector must not render the old sheet structure or any new-vendor/add-row trigger',
);
assert(
  lowerVendorSelectorScreen.includes('class="category-selector-action-row vendor-selector-action-row"') &&
    lowerVendorSelectorScreen.includes('data-vendor-action="select-all"') &&
    lowerVendorSelectorScreen.includes('data-vendor-action="select-none"') &&
    lowerVendorSelectorScreen.includes('Mindet kijelölni') &&
    lowerVendorSelectorScreen.includes('Egyiket se'),
  'A3 vendor selector must expose select-all/select-none bulk actions like A2',
);
const vendorGroupMatches = [...lowerVendorSelectorScreen.matchAll(/data-vendor-group="([^"]+)"/g)].map(
  (match) => match[1],
);
assert(
  vendorGroupMatches.length >= 4 &&
    vendorGroupMatches.join('') === [...vendorGroupMatches].sort((a, b) => a.localeCompare(b, 'hu')).join(''),
  'A3 vendor selector groups must be present and sorted alphabetically',
);
const selectorVendorCards = [
  ...lowerVendorSelectorScreen.matchAll(/<article class="vendor-card vendor-selector-card[^"]*"[\s\S]*?<\/article>/g),
].map((match) => match[0]);
assert(selectorVendorCards.length >= 10, 'A3 fullscreen vendor selector must render a dense ABC vendor card list');
const selectorVendorNames = selectorVendorCards.map((block) => block.match(/<span class="card-title">([^<]+)<\/span>/)?.[1] ?? '');
assert(
  selectorVendorNames.every(Boolean) &&
    selectorVendorNames.join('|') === [...selectorVendorNames].sort((a, b) => a.localeCompare(b, 'hu')).join('|'),
  'A3 vendor cards must be alphabetically sorted by vendor name',
);
for (const [index, block] of selectorVendorCards.entries()) {
  assert(
    block.includes('vendor-card-avatar-circle') &&
      block.includes('data-color-target="vendor-avatar-circle"') &&
      block.includes('data-color-var="--vendor-avatar-bg"') &&
      block.includes('vendor-avatar-icon') &&
      block.includes('class="category-selector-copy"') &&
      block.includes('class="card-title"') &&
      block.includes('class="card-subtitle"') &&
      block.includes('class="vendor-total"') &&
      block.includes('class="category-selector-check'),
    `A3 vendor card ${index + 1} must follow the A2 compact selector layout with vendor avatar, title/count, total, and check circle`,
  );
}
assert(
  lowerVendorSelectorScreen.includes('class="category-selector-footer vendor-selector-footer"') &&
    lowerVendorSelectorScreen.includes('vendor kijelölve') &&
    lowerVendorSelectorScreen.includes('Összes tranzakció:') &&
    lowerVendorSelectorScreen.includes('class="category-selector-footer-actions vendor-selector-footer-actions"') &&
    lowerVendorSelectorScreen.includes('<button class="category-selector-cancel vendor-selector-cancel"') &&
    lowerVendorSelectorScreen.includes('<button class="category-selector-apply vendor-selector-apply"') &&
    lowerVendorSelectorScreen.includes('Cancel') &&
    lowerVendorSelectorScreen.includes('OK') &&
    !lowerVendorSelectorScreen.includes('Alkalmaz'),
  'A3 fullscreen vendor selector must end with a sticky selected-count footer and dual Cancel/OK bottom actions',
);
assert(
  /\.vendor-selector-screen \{[\s\S]*?background:\s*var\(--category-selector-bg\);/.test(html) &&
    /\.vendor-selector-route \.vendor-selector-search-pill \{[\s\S]*?height:\s*44px;[\s\S]*?margin-top:\s*21px;[\s\S]*?border-radius:\s*22px;[\s\S]*?padding:\s*0 15px;/.test(html) &&
    /\.vendor-selector-action-row \{[\s\S]*?margin-top:\s*12px;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*12px;[\s\S]*?padding:\s*0 2px;/.test(html) &&
    /\.vendor-selector-body \{[\s\S]*?top:\s*233px;[\s\S]*?bottom:\s*106px;/.test(html) &&
    /\.vendor-selector-section-title \{[\s\S]*?font-size:\s*11px;[\s\S]*?letter-spacing:\s*\.12em;/.test(html) &&
    /\.vendor-selector-card \{[\s\S]*?min-height:\s*60px;[\s\S]*?grid-template-columns:\s*34px minmax\(0,\s*1fr\) 22px;/.test(html),
  'A3 vendor selector CSS must implement the same top-section sizing/orientation as A2, plus ABC section labels and compact vendor cards',
);

const lowerVendorEditorScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen vendor-editor-screen" data-screen="alt-vendor-editor"[\s\S]*?<div class="screen-title">A4/,
)?.[0];
assert(lowerVendorEditorScreen, 'Missing A3B fullscreen vendor editor screen after the vendor selector');
assert(
  html.indexOf('data-screen="alt-vendor-sheet"') <
    html.indexOf('data-screen="alt-vendor-editor"') &&
    html.indexOf('data-screen="alt-vendor-editor"') <
      html.indexOf('data-screen="alt-add-category-editor"'),
  'A3B vendor editor must sit directly between the vendor selector and add-category editor',
);
assert(
  lowerVendorEditorScreen.includes('data-vendor-editor-mode="fullscreen"') &&
    lowerVendorEditorScreen.includes('data-vendor-editor-entry="longpress"') &&
    lowerVendorEditorScreen.includes('data-source="vendor-card-longpress"') &&
    lowerVendorEditorScreen.includes('<div class="category-selector-title">Vendor szerkesztése</div>') &&
    lowerVendorEditorScreen.includes('class="vendor-editor-name-pill"') &&
    lowerVendorEditorScreen.includes('Lidl') &&
    lowerVendorEditorScreen.includes('class="vendor-editor-category-card"') &&
    lowerVendorEditorScreen.includes('Élelmiszer') &&
    lowerVendorEditorScreen.includes('category-card-avatar-circle'),
  'A3B vendor editor must model a longpress-opened fullscreen route with editable vendor name and assigned category',
);
assert(
  lowerVendorEditorScreen.includes('class="vendor-editor-insight-grid"') &&
    lowerVendorEditorScreen.includes('class="vendor-editor-insight-card"') &&
    lowerVendorEditorScreen.includes('Havi átlag') &&
    lowerVendorEditorScreen.includes('Utolsó tranzakció') &&
    lowerVendorEditorScreen.includes('class="vendor-editor-rule-card"') &&
    lowerVendorEditorScreen.includes('Automatikus kategória') &&
    lowerVendorEditorScreen.includes('class="vendor-editor-preview-card"') &&
    lowerVendorEditorScreen.includes('Lidl → Élelmiszer'),
  'A3B vendor editor must add useful non-empty context beyond name/category: stats, assignment rule, and preview',
);
assert(
  lowerVendorEditorScreen.includes('class="category-selector-footer vendor-editor-footer"') &&
    lowerVendorEditorScreen.includes('Vendor frissítve') &&
    lowerVendorEditorScreen.includes('class="category-selector-apply vendor-editor-save"') &&
    lowerVendorEditorScreen.includes('OK') &&
    !lowerVendorEditorScreen.includes('Új vendor') &&
    !lowerVendorEditorScreen.includes('class="sheet-card"') &&
    !lowerVendorEditorScreen.includes('class="sheet-grabber"'),
  'A3B vendor editor must use the add-category-style bottom footer and stay fullscreen, not sheet-based',
);
assert(
  /\.vendor-editor-route,\s*\n\s*\.icon-selector-route \{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?background:\s*var\(--category-editor-bg\);[\s\S]*?padding:\s*38px 20px 0;/.test(html) &&
    /\.vendor-editor-body,\s*\n\s*\.icon-selector-body \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*20px;[\s\S]*?right:\s*20px;[\s\S]*?top:\s*var\(--spendee-header-top\);[\s\S]*?bottom:\s*106px;/.test(html) &&
    /\.vendor-editor-name-pill \{[\s\S]*?height:\s*50px;[\s\S]*?border-radius:\s*25px;/.test(html) &&
    /\.vendor-editor-insight-grid \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\);/.test(html),
  'A3B vendor editor CSS must use the same fullscreen route, header-card-top body start, pill geometry, and compact two-column insight grid',
);

const lowerAddCategoryScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen category-editor-screen" data-screen="alt-add-category-editor"[\s\S]*?<div class="screen-title">A4B/,
)?.[0];
assert(lowerAddCategoryScreen, 'Missing A4 fullscreen add-new-category editor screen after the vendor selector');
assert(
  html.indexOf('data-screen="alt-vendor-editor"') <
    html.indexOf('data-screen="alt-add-category-editor"') &&
    html.indexOf('data-screen="alt-add-category-editor"') <
      html.indexOf('data-screen="alt-icon-selector"'),
  'A4 fullscreen add-new-category editor must be inserted after the vendor editor and before the icon selector screen',
);
assert(
  lowerAddCategoryScreen.includes('data-category-editor-mode="fullscreen"') &&
    lowerAddCategoryScreen.includes('data-source="lib/features/transactions/widgets/category_menu/category_editor_panel.dart"') &&
    lowerAddCategoryScreen.includes('data-source="lib/features/transactions/widgets/category_menu/category_slot_grid.dart"') &&
    lowerAddCategoryScreen.includes('<div class="category-selector-title">Új kiadási kategória</div>') &&
    lowerAddCategoryScreen.includes('Kategória neve') &&
    lowerAddCategoryScreen.includes('class="category-editor-name-pill"') &&
    lowerAddCategoryScreen.includes('data-body-top="header-card-top"') &&
    !lowerAddCategoryScreen.includes('class="sheet-card"') &&
    !lowerAddCategoryScreen.includes('class="sheet-panel"') &&
    !lowerAddCategoryScreen.includes('class="sheet-grabber"') &&
    !lowerAddCategoryScreen.includes('category-slot-toggle-button'),
  'A4 add-new-category editor must adapt the real CategoryEditorPanel into a fullscreen route without sheet/grabber/toggle-page UI',
);
assert(
  lowerAddCategoryScreen.includes('class="category-editor-slot-section color-section"') &&
    lowerAddCategoryScreen.includes('data-category-editor-section="colors"') &&
    lowerAddCategoryScreen.includes('Válassz színt') &&
    lowerAddCategoryScreen.includes('class="category-editor-slot-section icon-section"') &&
    lowerAddCategoryScreen.includes('data-category-editor-section="icons"') &&
    lowerAddCategoryScreen.includes('Válassz ikont'),
  'A4 fullscreen editor must show the color and icon slot sections one under another',
);
const addCategoryColorSlots = [
  ...lowerAddCategoryScreen.matchAll(/data-editor-color-slot="(\d+)"/g),
].map((match) => Number(match[1]));
const addCategoryIconSlots = [
  ...lowerAddCategoryScreen.matchAll(/data-editor-icon-slot="(\d+)"/g),
].map((match) => Number(match[1]));
assert.deepStrictEqual(addCategoryColorSlots, Array.from({ length: 21 }, (_, index) => index));
assert.deepStrictEqual(addCategoryIconSlots, Array.from({ length: 21 }, (_, index) => index));
for (let slot = 0; slot < 21; slot += 1) {
  assert(
    lowerAddCategoryScreen.includes(`data-editor-color-slot="${slot}"`) &&
      lowerAddCategoryScreen.includes(`--category-editor-slot-color:var(--slot-gradient-${slot})`),
    `A4 add-new-category color slot ${slot} must use the active Spendee gradient variable instead of a flat hex`,
  );
}
assert(
  !/--category-editor-slot-color:#[0-9a-fA-F]{6}/.test(lowerAddCategoryScreen),
  'A4 add-new-category color slots must not use the old flat CategoryColorManager hex swatches',
);
assert(
  lowerAddCategoryScreen.includes('class="category-editor-preview-pill"') &&
    lowerAddCategoryScreen.includes('class="category-editor-preview-avatar"') &&
    lowerAddCategoryScreen.includes('class="slot-icon category-avatar-icon"') &&
    lowerAddCategoryScreen.includes('data-icon-color="#ffffff"') &&
    lowerAddCategoryScreen.includes('Kategória neve') &&
    lowerAddCategoryScreen.includes('class="category-selector-footer category-editor-footer"') &&
    lowerAddCategoryScreen.includes('<button class="category-selector-apply category-editor-save"') &&
    lowerAddCategoryScreen.includes('OK') &&
    !lowerAddCategoryScreen.includes('Mentés') &&
    !lowerAddCategoryScreen.includes('category-editor-delete-button') &&
    !lowerAddCategoryScreen.includes('delete_outline'),
  'A4 add-new-category editor must include preview and vendor-style bottom OK affordance, white icon preview, and no edit/delete control',
);
assert(
  /\.category-editor-screen \{[\s\S]*?background:\s*var\(--category-editor-bg\);/.test(html) &&
    /\.category-editor-route \{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?background:\s*var\(--category-editor-bg\);[\s\S]*?padding:\s*38px 20px 0;/.test(html) &&
    /\.category-editor-body \{[\s\S]*?top:\s*var\(--spendee-header-top\);[\s\S]*?bottom:\s*106px;/.test(html) &&
    /\.category-editor-scroll \{[\s\S]*?height:\s*100%;[\s\S]*?align-content:\s*space-between;/.test(html) &&
    /\.category-editor-name-pill \{[\s\S]*?height:\s*50px;[\s\S]*?border-radius:\s*25px;[\s\S]*?padding:\s*0 16px;/.test(html) &&
    /\.category-editor-color-grid,\s*\.category-editor-icon-grid \{[\s\S]*?grid-template-columns:\s*repeat\(7,\s*1fr\);[\s\S]*?gap:\s*8px;/.test(html) &&
    /\.category-editor-color-slot,\s*\.category-editor-icon-slot \{[\s\S]*?height:\s*42px;[\s\S]*?border-radius:\s*999px;/.test(html) &&
    /\.category-editor-preview-pill \{[\s\S]*?min-height:\s*70px;[\s\S]*?border-radius:\s*25px;[\s\S]*?padding:\s*12px 16px;/.test(html) &&
    /\.category-editor-footer \{[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\) 132px;[\s\S]*?bottom:\s*22px;/.test(html) &&
    /\.category-editor-save \{[\s\S]*?height:\s*48px;[\s\S]*?border-radius:\s*24px;/.test(html),
  'A4 fullscreen add-new-category CSS must preserve CategoryEditorPanel dimensions, expose both slot grids, and use the vendor-style sticky OK footer',
);

const lowerIconSelectorScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen icon-selector-screen" data-screen="alt-icon-selector"[\s\S]*?<div class="screen-title">A5/,
)?.[0];
assert(lowerIconSelectorScreen, 'Missing A4B fullscreen icon selector screen after the add-category editor');
assert(
  html.indexOf('data-screen="alt-add-category-editor"') <
    html.indexOf('data-screen="alt-icon-selector"') &&
    html.indexOf('data-screen="alt-icon-selector"') <
      html.indexOf('data-screen="alt-add-transaction-sheet"'),
  'A4B icon selector must sit between the add-category editor and add-transaction screen',
);
assert(
  lowerIconSelectorScreen.includes('data-icon-selector-mode="fullscreen"') &&
    lowerIconSelectorScreen.includes('data-source="lib/features/transactions/widgets/category_menu/icon_selector_sheet.dart"') &&
    lowerIconSelectorScreen.includes('data-source-options="lib/features/transactions/slots/category_icon_manager.dart"') &&
    lowerIconSelectorScreen.includes('<div class="category-selector-title">Ikon kiválasztása</div>') &&
    lowerIconSelectorScreen.includes('data-body-top="header-card-top"') &&
    lowerIconSelectorScreen.includes('class="icon-selector-grid"') &&
    lowerIconSelectorScreen.includes('class="icon-selector-option selected"'),
  'A4B icon selector must adapt the app IconSelectorSheet into a fullscreen route with header-card-top body positioning',
);
const iconSelectorOptions = [
  ...lowerIconSelectorScreen.matchAll(/<button class="icon-selector-option[^"]*"[\s\S]*?<\/button>/g),
].map((match) => match[0]);
assert(iconSelectorOptions.length >= 40, 'A4B fullscreen icon selector must render a dense set of real CategoryIconManager options');
for (const requiredIcon of ['shirt', 'shopping-cart', 'handbag', 'fingerprint-pattern', 'hand-coins', 'banknote']) {
  assert(
    lowerIconSelectorScreen.includes(`data-icon-name="${requiredIcon}"`) &&
      lowerIconSelectorScreen.includes(`url('/assets/icons/lucide/${requiredIcon}.svg')`),
    `A4B icon selector must include real icon option ${requiredIcon}`,
  );
}
assert(
  lowerIconSelectorScreen.includes('class="category-selector-footer icon-selector-footer"') &&
    lowerIconSelectorScreen.includes('Ikon kiválasztva') &&
    lowerIconSelectorScreen.includes('<button class="category-selector-cancel icon-selector-cancel"') &&
    lowerIconSelectorScreen.includes('<button class="category-selector-apply icon-selector-apply"') &&
    lowerIconSelectorScreen.includes('Cancel') &&
    lowerIconSelectorScreen.includes('OK') &&
    !lowerIconSelectorScreen.includes('class="sheet-grabber"') &&
    !lowerIconSelectorScreen.includes('icon-selector-sheet'),
  'A4B icon selector must use fullscreen selector footer buttons, not the original bottom sheet grabber',
);
assert(
  /\.icon-selector-route \{[\s\S]*?position:\s*absolute;[\s\S]*?inset:\s*0;[\s\S]*?background:\s*var\(--category-editor-bg\);[\s\S]*?padding:\s*38px 20px 0;/.test(html) &&
    /\.icon-selector-body \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*20px;[\s\S]*?right:\s*20px;[\s\S]*?top:\s*var\(--spendee-header-top\);[\s\S]*?bottom:\s*106px;/.test(html) &&
    /\.icon-selector-grid \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(5,\s*minmax\(0,\s*1fr\)\);[\s\S]*?gap:\s*10px 8px;/.test(html) &&
    /\.icon-selector-option \{[\s\S]*?width:\s*48px;[\s\S]*?height:\s*48px;[\s\S]*?border-radius:\s*999px;/.test(html),
  'A4B icon selector CSS must keep the app 5-column/48px circular icon-option geometry in fullscreen form',
);

const lowerAddTransactionStart = alternativeSection.indexOf('data-screen="alt-add-transaction-sheet"');
const lowerAddTransactionNext = alternativeSection.indexOf('<div class="screen-title">A6', lowerAddTransactionStart);
const lowerAddTransactionEnd =
  lowerAddTransactionNext > lowerAddTransactionStart
    ? lowerAddTransactionNext
    : alternativeSection.indexOf('id="balanceHeaderScaleLab"', lowerAddTransactionStart);
const lowerAddTransactionScreen =
  lowerAddTransactionStart >= 0 && lowerAddTransactionEnd > lowerAddTransactionStart
    ? alternativeSection.slice(lowerAddTransactionStart, lowerAddTransactionEnd)
    : '';
assert(lowerAddTransactionScreen, 'Missing A5 alternative add transaction screen block');
assert(
  lowerAddTransactionScreen.includes('data-transaction-editor-layout="amount-hero-v1"') &&
    lowerAddTransactionScreen.includes('data-source="lib/features/transactions/widgets/add_transaction_sheet.dart"') &&
    lowerAddTransactionScreen.includes('class="add-transaction-card add-transaction-card-redesign"') &&
    lowerAddTransactionScreen.includes('class="transaction-sheet-header"') &&
    lowerAddTransactionScreen.includes('Új kiadás') &&
    !lowerAddTransactionScreen.includes('transaction-type-badge') &&
    !lowerAddTransactionScreen.includes('>Kiadás</button>'),
  'A5 add transaction mockup must use the compact sheet header without a separate expense/type badge',
);
assert(
  lowerAddTransactionScreen.includes('class="transaction-amount-hero"') &&
    lowerAddTransactionScreen.includes('data-color-target="transaction-amount-hero"') &&
    lowerAddTransactionScreen.includes('data-color-var="--transaction-amount-hero-bg"') &&
    lowerAddTransactionScreen.includes('-18 520 Ft') &&
    lowerAddTransactionScreen.includes('Tranzakció összege'),
  'A5 add transaction mockup must make amount the primary hero field',
);
assert(
  lowerAddTransactionScreen.includes('class="pill-field transaction-name-pill"') &&
    lowerAddTransactionScreen.includes('Lidl / tranzakció neve') &&
    lowerAddTransactionScreen.includes('class="pill-field transaction-category-pill"') &&
    lowerAddTransactionScreen.includes('Élelmiszer') &&
    lowerAddTransactionScreen.includes('category-card-avatar-circle') &&
    lowerAddTransactionScreen.includes('data-color-target="category-avatar-circle"') &&
    lowerAddTransactionScreen.includes('data-icon-color="#ffffff"') &&
    lowerAddTransactionScreen.includes('class="field-row transaction-date-time-row"') &&
    lowerAddTransactionScreen.includes('2026.07.13') &&
    lowerAddTransactionScreen.includes('19:42'),
  'A5 add transaction mockup must show name, category with glossy avatar, and compact date/time pills',
);
assert(
  lowerAddTransactionScreen.includes('class="transaction-sheet-footer"') &&
    lowerAddTransactionScreen.includes('<button class="transaction-save"') &&
    lowerAddTransactionScreen.includes('data-color-target="transaction-save-button"') &&
    lowerAddTransactionScreen.includes('data-color-var="--transaction-save-bg"') &&
    lowerAddTransactionScreen.includes('>Tranzakció hozzáadása</button>') &&
    !lowerAddTransactionScreen.includes('transaction-cancel') &&
    !lowerAddTransactionScreen.includes('>Cancel</button>') &&
    !lowerAddTransactionScreen.includes('>Mentés</button>') &&
    !lowerAddTransactionScreen.includes('class="save-footer"') &&
    !lowerAddTransactionScreen.includes('Új kiadási tranzakció'),
  'A5 add transaction mockup must use one bottom submit button; cancel is represented by swipe-down dismissal, not a visible button',
);
assert(
  /--transaction-amount-hero-bg:\s*linear-gradient/.test(html) &&
    /--transaction-save-bg:\s*var\(--primary\);/.test(html) &&
    /\.add-transaction-card-redesign \{[\s\S]*?height:\s*var\(--query-sheet-h\);[\s\S]*?border-radius:\s*26px 26px 0 0;/.test(html) &&
    /\.transaction-sheet-header \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);/.test(html) &&
    /\.transaction-amount-hero \{[\s\S]*?min-height:\s*92px;[\s\S]*?border-radius:\s*24px;/.test(html) &&
    /\.transaction-sheet-footer \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*1fr;/.test(html) &&
    /\.transaction-save \{[\s\S]*?height:\s*48px;[\s\S]*?border-radius:\s*24px;/.test(html),
  'A5 add transaction CSS must implement the amount-hero sheet geometry and single-submit footer',
);
const lowerAddRecurringStart = alternativeSection.indexOf('data-screen="alt-add-recurring-sheet"');
const lowerAddRecurringNext = alternativeSection.indexOf('<div class="screen-title">A7', lowerAddRecurringStart);
const lowerAddRecurringEnd =
  lowerAddRecurringNext > lowerAddRecurringStart
    ? lowerAddRecurringNext
    : alternativeSection.indexOf('id="balanceHeaderScaleLab"', lowerAddRecurringStart);
const lowerAddRecurringScreen =
  lowerAddRecurringStart >= 0 && lowerAddRecurringEnd > lowerAddRecurringStart
    ? alternativeSection.slice(lowerAddRecurringStart, lowerAddRecurringEnd)
    : '';
assert(lowerAddRecurringScreen, 'Missing A6 alternative add recurring screen block');
assert(
  html.indexOf('data-screen="alt-add-transaction-sheet"') <
    html.indexOf('data-screen="alt-add-recurring-sheet"') &&
    html.indexOf('data-screen="alt-add-recurring-sheet"') <
      html.indexOf('id="balanceHeaderScaleLab"'),
  'A6 add recurring screen must be inserted after A5 and before the color scale labs',
);
assert(
  lowerAddRecurringScreen.includes('data-recurring-editor-layout="schedule-hero-v1"') &&
    lowerAddRecurringScreen.includes('data-source="lib/features/transactions/widgets/recurring_manager_sheet.dart"') &&
    lowerAddRecurringScreen.includes('data-source="lib/features/transactions/models/recurring_rule.dart"') &&
    lowerAddRecurringScreen.includes('class="add-recurring-card add-recurring-card-redesign"') &&
    lowerAddRecurringScreen.includes('class="recurring-sheet-header"') &&
    lowerAddRecurringScreen.includes('Új ismétlődés') &&
    lowerAddRecurringScreen.includes('Automatikus kiadás'),
  'A6 add recurring mockup must identify itself as a redesigned recurring manager sheet based on the app recurring source',
);
assert(
  lowerAddRecurringScreen.includes('class="recurring-trigger-row"') &&
    lowerAddRecurringScreen.includes('class="recurring-trigger-choice selected"') &&
    lowerAddRecurringScreen.includes('>Idő</button>') &&
    lowerAddRecurringScreen.includes('>Push</button>') &&
    lowerAddRecurringScreen.includes('class="recurring-schedule-hero"') &&
    lowerAddRecurringScreen.includes('Havonta') &&
    lowerAddRecurringScreen.includes('Minden hónap 13. napján') &&
    lowerAddRecurringScreen.includes('class="recurring-next-run-pill"') &&
    lowerAddRecurringScreen.includes('Következő futás') &&
    lowerAddRecurringScreen.includes('2026.08.13'),
  'A6 recurring mockup must preserve the app trigger model while making the schedule the hero area',
);
assert(
  lowerAddRecurringScreen.includes('class="recurring-transaction-summary"') &&
    lowerAddRecurringScreen.includes('-18 520 Ft') &&
    lowerAddRecurringScreen.includes('Lidl') &&
    lowerAddRecurringScreen.includes('Élelmiszer') &&
    lowerAddRecurringScreen.includes('category-card-avatar-circle') &&
    lowerAddRecurringScreen.includes('data-icon-color="#ffffff"') &&
    lowerAddRecurringScreen.includes('class="recurring-frequency-row"') &&
    lowerAddRecurringScreen.includes('Hónap napja') &&
    lowerAddRecurringScreen.includes('13') &&
    lowerAddRecurringScreen.includes('Időpont') &&
    lowerAddRecurringScreen.includes('19:42') &&
    lowerAddRecurringScreen.includes('Aktív'),
  'A6 recurring mockup must show transaction identity plus day/time/status fields from RecurringRuleDraft',
);
assert(
  lowerAddRecurringScreen.includes('class="recurring-sheet-footer"') &&
    lowerAddRecurringScreen.includes('<button class="recurring-save"') &&
    lowerAddRecurringScreen.includes('data-color-target="recurring-save-button"') &&
    lowerAddRecurringScreen.includes('data-color-var="--recurring-save-bg"') &&
    lowerAddRecurringScreen.includes('>Ismétlődés hozzáadása</button>') &&
    !lowerAddRecurringScreen.includes('recurring-cancel') &&
    !lowerAddRecurringScreen.includes('>Cancel</button>'),
  'A6 recurring mockup must use one bottom submit button; cancel remains swipe-down dismissal',
);
assert(
  /--recurring-schedule-hero-bg:\s*linear-gradient/.test(html) &&
    /--recurring-save-bg:\s*var\(--primary\);/.test(html) &&
    /\.add-recurring-card-redesign \{[\s\S]*?height:\s*516px;[\s\S]*?border-radius:\s*26px 26px 0 0;/.test(html) &&
    /\.recurring-schedule-hero \{[\s\S]*?min-height:\s*108px;[\s\S]*?border-radius:\s*24px;/.test(html) &&
    /\.recurring-frequency-row \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\);/.test(html) &&
    /\.recurring-save \{[\s\S]*?height:\s*48px;[\s\S]*?border-radius:\s*24px;/.test(html),
  'A6 recurring CSS must implement a taller schedule-hero sheet with three schedule fields and one CTA',
);
const lowerAddRecurringPushStart = alternativeSection.indexOf(
  'data-screen="alt-add-recurring-push-sheet"',
);
const lowerAddRecurringPushEnd = alternativeSection.indexOf(
  'id="balanceHeaderScaleLab"',
  lowerAddRecurringPushStart,
);
const lowerAddRecurringPushScreen =
  lowerAddRecurringPushStart >= 0 && lowerAddRecurringPushEnd > lowerAddRecurringPushStart
    ? alternativeSection.slice(lowerAddRecurringPushStart, lowerAddRecurringPushEnd)
    : '';
assert(lowerAddRecurringPushScreen, 'Missing A7 alternative add recurring push screen block');
assert(
  html.indexOf('data-screen="alt-add-recurring-sheet"') <
    html.indexOf('data-screen="alt-add-recurring-push-sheet"') &&
    html.indexOf('data-screen="alt-add-recurring-push-sheet"') <
      html.indexOf('id="balanceHeaderScaleLab"'),
  'A7 push recurring screen must be inserted after A6 and before the color scale labs',
);
assert(
  lowerAddRecurringPushScreen.includes('data-recurring-editor-layout="push-learning-v1"') &&
    lowerAddRecurringPushScreen.includes('data-source="lib/features/transactions/widgets/recurring_manager_sheet.dart"') &&
    lowerAddRecurringPushScreen.includes('data-source="lib/features/transactions/models/recurring_rule.dart"') &&
    lowerAddRecurringPushScreen.includes('data-source="lib/features/settings/models/notification_parser_rule.dart"') &&
    lowerAddRecurringPushScreen.includes('data-recurring-sheet-height="full"') &&
    lowerAddRecurringPushScreen.includes('class="add-recurring-card add-recurring-card-redesign add-recurring-push-card"') &&
    lowerAddRecurringPushScreen.includes('Új ismétlődés') &&
    lowerAddRecurringPushScreen.includes('Push alapú kiadás'),
  'A7 push recurring mockup must identify itself as the push side of the app recurring manager',
);
assert(
  lowerAddRecurringPushScreen.includes('<button class="recurring-trigger-choice" type="button">Idő</button>') &&
    lowerAddRecurringPushScreen.includes('<button class="recurring-trigger-choice selected" type="button">Push</button>') &&
    lowerAddRecurringPushScreen.includes('class="recurring-push-hero"') &&
    lowerAddRecurringPushScreen.includes('Banki push felismerés') &&
    lowerAddRecurringPushScreen.includes('App + minta alapján automatikus szabály') &&
    lowerAddRecurringPushScreen.includes('class="recurring-push-app-pill"') &&
    lowerAddRecurringPushScreen.includes('George') &&
    lowerAddRecurringPushScreen.includes('Hónap napja') &&
    lowerAddRecurringPushScreen.includes('13'),
  'A7 push recurring mockup must make Push selected and show app picker plus monthly day fields from _PushScheduleRow',
);
assert(
  lowerAddRecurringPushScreen.includes('class="recurring-push-training-card"') &&
    lowerAddRecurringPushScreen.includes('Példa push üzenet') &&
    lowerAddRecurringPushScreen.includes('Lidl vásárlás 18 520 Ft') &&
    lowerAddRecurringPushScreen.includes('class="recurring-training-mode-row"') &&
    lowerAddRecurringPushScreen.includes('Összeg') &&
    lowerAddRecurringPushScreen.includes('Bolt') &&
    lowerAddRecurringPushScreen.includes('class="recurring-training-token-row"') &&
    lowerAddRecurringPushScreen.includes('18 520 Ft') &&
    lowerAddRecurringPushScreen.includes('Lidl'),
  'A7 push recurring mockup must show the push training sample, amount/merchant modes and selectable training tokens',
);
assert(
  lowerAddRecurringPushScreen.includes('class="recurring-parser-preview"') &&
    lowerAddRecurringPushScreen.includes('Parser preview') &&
    lowerAddRecurringPushScreen.includes('Kulcsszó') &&
    lowerAddRecurringPushScreen.includes('vásárlás') &&
    lowerAddRecurringPushScreen.includes('class="recurring-tolerance-row"') &&
    lowerAddRecurringPushScreen.includes('Nap szórás') &&
    lowerAddRecurringPushScreen.includes('5') &&
    lowerAddRecurringPushScreen.includes('% szórás') &&
    lowerAddRecurringPushScreen.includes('20') &&
    lowerAddRecurringPushScreen.includes('Minimum Ft szórás') &&
    lowerAddRecurringPushScreen.includes('5 000 Ft'),
  'A7 push recurring mockup must show parser preview plus the advanced push tolerance controls from _PushTrainingForm',
);
assert(
  lowerAddRecurringPushScreen.includes('class="recurring-sheet-footer"') &&
    lowerAddRecurringPushScreen.includes('<button class="recurring-save"') &&
    lowerAddRecurringPushScreen.includes('data-color-target="recurring-save-button"') &&
    lowerAddRecurringPushScreen.includes('data-color-var="--recurring-save-bg"') &&
    lowerAddRecurringPushScreen.includes('>Ismétlődés hozzáadása</button>') &&
    !lowerAddRecurringPushScreen.includes('recurring-cancel') &&
    !lowerAddRecurringPushScreen.includes('>Cancel</button>'),
  'A7 push recurring mockup must keep the same single-submit sheet dismissal model as A6',
);
assert(
  /\.add-recurring-push-card \{[\s\S]*?top:\s*34px;[\s\S]*?height:\s*auto;[\s\S]*?bottom:\s*0;/.test(html) &&
    !/\.add-recurring-push-card \{[\s\S]*?height:\s*586px;[\s\S]*?\}/.test(html) &&
    /\.recurring-push-hero \{[\s\S]*?min-height:\s*94px;[\s\S]*?border-radius:\s*24px;/.test(html) &&
    /\.recurring-push-training-card \{[\s\S]*?border-radius:\s*22px;[\s\S]*?padding:\s*12px;/.test(html) &&
    /\.recurring-training-token-row \{[\s\S]*?display:\s*flex;[\s\S]*?flex-wrap:\s*wrap;/.test(html) &&
    /\.recurring-tolerance-row \{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\);/.test(html),
  'A7 push recurring CSS must implement a taller push-learning sheet with app/training/tolerance areas',
);
assert(
  /function setBackheaderFocusMode\(card, focused\) \{[\s\S]*?card\?\.querySelector\('\[data-backheader-browse-state\]'\)[\s\S]*?data-backheader-stage[\s\S]*?focus[\s\S]*?browse[\s\S]*?browseState\.hidden[\s\S]*?focusState\.hidden/.test(
    html,
  ),
  'Backheader JS must switch a scoped card between browse and inline focus states via tap, not swipe modeling',
);
assert(
  /function initBackheaderOpacityScale\(\) \{[\s\S]*?data-backheader-opacity-scale-track[\s\S]*?data-backheader-opacity-handle[\s\S]*?setBackheaderOpacityScaleState\(percentFromEvent\(event\)\)/.test(
    html,
  ) &&
    /function updateBackheaderOpacityFromScale\(\) \{[\s\S]*?--spendee-backheader-opacity/.test(
      html,
    ),
  'Backheader opacity slider must live-write only the --spendee-backheader-opacity variable',
);
assert(
  /function initBackheaderPrototype\(\) \{[\s\S]*?document\.querySelectorAll\('\[data-backheader-card\]'\)\.forEach\(\(card\) => \{[\s\S]*?const trigger = card\.querySelector\('\[data-backheader-focus-trigger\]'\);[\s\S]*?trigger\.addEventListener\('click', \(event\) => \{[\s\S]*?event\.stopPropagation\(\);[\s\S]*?setBackheaderFocusMode\(card, true\);[\s\S]*?setBackheaderFocusMode\(card, false\);[\s\S]*?\}\);[\s\S]*?\}\);/.test(
    html,
  ),
  'Every backheader center icon tap must stop propagation and enter focus mode on its own card only',
);
const backheaderPrototypeBlock = html.match(/function initBackheaderPrototype\(\) \{[\s\S]*?function formatForint/)?.[0];
assert(backheaderPrototypeBlock, 'Missing backheader prototype click handler block');
assert(
  !backheaderPrototypeBlock.includes('selectionState.selectedColor'),
  'Backheader center icon focus trigger must not be blocked by selected palette swatches',
);
assert(
  /function applySelectedColor\(target\) \{[\s\S]*?target\.dataset\.colorTarget === 'backheader-category-color'[\s\S]*?--spendee-backheader-category-color/.test(
    html,
  ),
  'Palette application must explicitly handle the backheader category color target',
);
assert(
  /function updateSpendeeBackheaderGlow\(color\) \{[\s\S]*?--spendee-backheader-glow/.test(html) &&
    /function applySelectedColor\(target\) \{[\s\S]*?target\.dataset\.colorTarget === 'backheader-category-color'[\s\S]*?updateSpendeeBackheaderGlow\(selectionState\.selectedColor\)/.test(
      html,
    ),
  'Backheader category recolor must also update the dedicated backheader projected glow',
);
assert(
  /function initInlineLimitEditor\(\) \{[\s\S]*?data-inline-limit-slider[\s\S]*?data-inline-limit-value/.test(
    html,
  ) &&
    !/function initInlineLimitEditor\(\) \{[\s\S]*?data-inline-limit-reset/.test(html) &&
    /function formatForint\(value\) \{[\s\S]*?toLocaleString\('hu-HU'/.test(html) &&
    /limitValue\.textContent = bounded === 0 \? 'No limit' : formatForint\(bounded\);/.test(html) &&
    /const currentAmount = Number\(card\.querySelector\('\[data-inline-current-amount\]'\)\?\.dataset\.inlineCurrentAmount\) \|\| 0;/.test(html) &&
    /const feedbackSpent = card\.querySelector\('\[data-inline-limit-feedback-spent\]'\);[\s\S]*?const feedbackRemaining = card\.querySelector\('\[data-inline-limit-feedback-remaining\]'\);/.test(html) &&
    /const remaining = bounded === 0 \? 0 : Math\.max\(0, bounded - currentAmount\);[\s\S]*?const spentPercent = bounded > 0 \? Math\.round\(\(currentAmount \/ bounded\) \* 100\) : 0;[\s\S]*?feedbackSpent\.textContent = bounded === 0 \? 'No limit' : `\$\{spentPercent\}%`;[\s\S]*?feedbackRemaining\.textContent = bounded === 0 \? 'No limit' : formatForint\(remaining\);/.test(html) &&
    !html.includes('data-inline-limit-feedback-value') &&
    !html.includes('data-inline-limit-feedback-daily') &&
    !/function initInlineLimitEditor\(\) \{[\s\S]*?--inline-limit-pct/.test(html),
  'Inline limit editor JS must keep the slider, live top-right limit summary, icon ring, and A1E plain spent/remaining texts in sync while treating slider value 0 as No limit without a reset/delete button',
);

const logoAssetPath = path.join(__dirname, 'fluvi_vector.svg');
assert(fs.existsSync(logoAssetPath), 'Missing local copy of /storage/emulated/0/spendee/Fluvi_vector.svg');
const logoSvg = fs.readFileSync(logoAssetPath, 'utf8');
const logoPathBlock = (pathId) =>
  logoSvg.match(new RegExp(`<path[\\s\\S]*?id="${pathId}"[\\s\\S]*?\\/>`))?.[0] || '';
assert(
  /id="fluvi-gradient-0"[\s\S]*?#00EDF5[\s\S]*?#5385FF/.test(logoSvg) &&
    /id="fluvi-gradient-1"[\s\S]*?#CE51FA[\s\S]*?#2E6AFE/.test(logoSvg),
  'Fluvi logo SVG must define the source gradients for the two whole F curves',
);
assert(
  (logoSvg.match(/<path[\s\S]*?id="fluvi-arc-/g) || []).length === 2 &&
    !logoSvg.includes('fluvi-path-2') &&
    !logoSvg.includes('fluvi-path-4'),
  'Fluvi logo SVG must expose only two whole editable F-curve components and no internal wedge subcomponents',
);
assert(
  logoPathBlock('fluvi-arc-top').includes('fill="url(#fluvi-gradient-0)"') &&
    logoPathBlock('fluvi-arc-bottom').includes('fill="url(#fluvi-gradient-1)"'),
  'Fluvi logo arcs must keep source fills before user recoloring',
);
assert(
  !logoSvg.includes('spendee-card-blue-gradient') &&
    !logoSvg.includes('spendee-bell-gradient') &&
    !logoSvg.includes('id="path1"'),
  'The local logo asset must no longer be the previous Spendee path set',
);

const altHeaderTargetCount =
  (alternativeSection.match(/data-color-target="header-card"/g) || []).length;
assert.strictEqual(
  altHeaderTargetCount,
  13,
  'Alternative design must include header-card recolor targets for the dashboard-like lower screens, the three B-row common-header stages plus B3M, and both Query-row transaction sheets; recurring wizard states use their own common sheet frame',
);
const spendeeHeaderCount = (alternativeSection.match(/class="app-header spendee-header\b/g) || [])
  .length;
assert.strictEqual(
  spendeeHeaderCount,
  9,
  'All lower dashboard-like Fluvi screens including both Query-row transaction sheets, except the fullscreen category/vendor selectors and the common recurring wizard sheets, must use the new Fluvi glass header card',
);
const spendeeBrandCount = (
  alternativeSection.match(/class="spendee-brand-lockup(?: query-menu-brand-lockup)?"/g) || []
)
  .length;
assert.strictEqual(
  spendeeBrandCount,
  13,
  'All lower dashboard-like Fluvi screens including Q1A and both Query-row transaction sheets must show the Fluvi logo; the A2/A3 fullscreen selectors and common recurring wizard sheets have their own route headers',
);
const spendeeLogoLivePreviewCount =
  (alternativeSection.match(/class="spendee-logo spendee-logo-live-preview"[^>]*data-logo-live-preview/g) || [])
    .length;
assert.strictEqual(
  spendeeLogoLivePreviewCount,
  13,
  'All lower Fluvi mock logos, including Q1A and both Query-row transaction sheets, must be inline live SVG previews that can follow logo-editor path recolors',
);
assert.strictEqual(
  (alternativeSection.match(/<img class="spendee-logo"/g) || []).length,
  0,
  'Lower Spendee mock logos must not remain static img tags because they cannot live-sync path edits',
);
const lowerLogoSourceRefs = alternativeSection.match(/data-logo-source="[^"]+"/g) || [];
assert(
  lowerLogoSourceRefs.length >= spendeeBrandCount &&
    lowerLogoSourceRefs.every((source) =>
      source === 'data-logo-source="/storage/emulated/0/spendee/Fluvi_vector.svg"'),
  'Every lower mock logo lockup must point at the Fluvi source icon path',
);
assert.strictEqual(
  (alternativeSection.match(/class="spendee-title">fluvi<\/div>/g) || []).length,
  17,
  'Every lower brand lockup must display the Fluvi brand name',
);
assert.strictEqual(
  (alternativeSection.match(/aria-label="Fluvi live logo preview"/g) || []).length,
  17,
  'Every lower live logo preview must expose Fluvi in its accessible label',
);
assert(
  !alternativeSection.includes('class="spendee-title">spendee</div>') &&
    !alternativeSection.includes('aria-label="Spendee live logo preview"') &&
    !alternativeSection.includes('>Spendee design') &&
    !alternativeSection.includes('aria-label="Spendee logo path editor"'),
  'No visible lower brand copy may still say Spendee after the Fluvi rename',
);
const spendeeBackheaderToggleCount =
  (alternativeSection.match(/data-backheader-toggle/g) || []).length;
assert.strictEqual(
  spendeeBackheaderToggleCount,
  0,
  'Lower Spendee headers must not render the obsolete top-left backheader toggle button',
);
assert(
  !alternativeSection.includes('backheader-toggle-button') &&
    !alternativeSection.includes('backheader-toggle-icon') &&
    !alternativeSection.includes('data-color-target="backheader-toggle-button"'),
  'Lower Spendee section must remove the obsolete backheader toggle DOM and color target',
);
assert(
  !alternativeSection.includes('class="header-label"') &&
    !alternativeSection.includes('data-color-target="header-balance-label-text"'),
  'Lower Spendee headers must not keep the text-based Egyenleg label pill',
);
assert.strictEqual(
  (alternativeSection.match(/class="spendee-balance-label">Balance<\/div>/g) || []).length,
  9,
  'All dashboard-like lower Fluvi headers, including both Query-row transaction sheets, must show a small Balance label above the balance amount',
);
assert.strictEqual(
  (alternativeSection.match(/class="spendee-balance-label">Score<\/div>/g) || []).length,
  0,
  'The removed S1 statistics dashboard must leave no lower dashboard-like header that replaces Balance with Score',
);
const spendeeCategoryMenuVarCount =
  (alternativeSection.match(/data-color-var="--spendee-category-menu-button-bg"/g) || [])
    .length;
assert.strictEqual(
  spendeeCategoryMenuVarCount,
  9,
  'Only non-common-header lower Fluvi category buttons, including both Query-row transaction sheets, must keep the dedicated glass-button color variable',
);
assert(
  !html.includes('data-section="legacy-design"') &&
    !html.includes('id="legacyColorPalette"'),
  'Legacy upper section and old palette must be removed from the cleaned prototype',
);
assert(
  !alternativeSection.includes('class="magnet-strip"'),
  'Lower Spendee section must not use a separate magnet strip because the whole header is the reactive strip',
);

const headerH = Number(html.match(/--header-h:\s*(\d+)px/)?.[1]);
const spendeeHeaderTop = Number(html.match(/--spendee-header-top:\s*(\d+)px/)?.[1]);
const spendeeHeaderH = Number(html.match(/--spendee-header-h:\s*(\d+)px/)?.[1]);
assert.strictEqual(
  spendeeHeaderTop + spendeeHeaderH,
  208,
  'The larger Spendee logo and corrected spacing must keep the lower header bottom at 208px while the legacy header stays 188px',
);
assert(
  spendeeHeaderTop < 112 && headerH === 188,
  'The lower Spendee header must be pulled up from the previous 112px top while the upper legacy header height remains the original 188px baseline',
);
assert(
  /\.spendee-header \{[\s\S]*?left:\s*20px;[\s\S]*?right:\s*20px;[\s\S]*?top:\s*var\(--spendee-header-top\);[\s\S]*?height:\s*var\(--spendee-header-h\);[\s\S]*?border-radius:\s*20px;[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*1px solid #ffffff;[\s\S]*?isolation:\s*isolate;/.test(
    html,
  ),
  'Spendee header host must be an inset smaller-radius transparent glass frame with a 1px white border',
);
const spendeeHeaderHostBlock = html.match(/\.spendee-header \{[\s\S]*?\n    \}/)?.[0];
assert(spendeeHeaderHostBlock, 'Missing lower Spendee header host CSS block');
assert(
  !spendeeHeaderHostBlock.includes('opacity: var(--spendee-header-opacity);'),
  'Spendee header opacity must not be applied to the host element because that fades the label, amount and category button',
);
const spendeeHeaderBackgroundBlock = html.match(/\.spendee-header::before \{[\s\S]*?\n    \}/)?.[0];
assert(spendeeHeaderBackgroundBlock, 'Missing lower Spendee header background pseudo-layer');
assert(
  spendeeHeaderBackgroundBlock.includes('var(--spendee-header-bg') &&
    spendeeHeaderBackgroundBlock.includes('linear-gradient(112deg') &&
    spendeeHeaderBackgroundBlock.includes('opacity: var(--spendee-header-opacity);') &&
    spendeeHeaderBackgroundBlock.includes('z-index: 0;'),
  'Spendee header opacity must be applied only to the background/glass pseudo-layer',
);
const spendeeBackheaderScreenGlowBlock = html.match(/\.spendee-backheader-screen::after \{[\s\S]*?\n    \}/)?.[0];
assert(spendeeBackheaderScreenGlowBlock, 'Missing backheader projected glow CSS block');
assert(
  spendeeBackheaderScreenGlowBlock.includes('background: var(--spendee-backheader-glow);') &&
    spendeeBackheaderScreenGlowBlock.includes('opacity: .24;') &&
    !spendeeBackheaderScreenGlowBlock.includes('var(--spendee-header-glow'),
  'Backheader screen projected glow must use the dedicated backheader glow variable, not the normal header glow',
);
assert(
  !html.includes('.spendee-header .backheader-toggle-button') &&
    !html.includes('.spendee-header .backheader-toggle-icon') &&
    !html.includes('--spendee-backheader-toggle-button-bg') &&
    !html.includes('--spendee-backheader-toggle-button-border') &&
    !html.includes('--spendee-backheader-toggle-button-icon'),
  'Obsolete lower Spendee backheader toggle CSS and variables must be removed',
);
assert(
  /\.spendee-brand-lockup \{[\s\S]*?top:\s*var\(--spendee-brand-top\);[\s\S]*?left:\s*22px;[\s\S]*?height:\s*42px;/.test(html) &&
    /\.spendee-title \{[\s\S]*?font-size:\s*23px;[\s\S]*?line-height:\s*1;[\s\S]*?\}/.test(html) &&
    /\.spendee-tagline \{[\s\S]*?font-size:\s*11px;[\s\S]*?line-height:\s*1\.05;[\s\S]*?\}/.test(html),
  'Spendee brand name and motto must keep the previous 42px text-stack sizing and typography',
);
assert(
  /\.spendee-logo \{[\s\S]*?width:\s*var\(--spendee-logo-icon-size\);[\s\S]*?height:\s*var\(--spendee-logo-icon-size\);/.test(
    html,
  ),
  'Only the Fluvi SVG icon must use the 56px enlarged icon token while the brand/motto stack keeps the previous 42px sizing',
);
const spendeeHeaderBalanceBlock = html.match(/\.spendee-header \.header-balance \{[\s\S]*?\n    \}/)?.[0];
assert(spendeeHeaderBalanceBlock, 'Missing lower Spendee header balance value CSS block');
assert(
  spendeeHeaderBalanceBlock.includes('color: var(--spendee-balance-ink);') &&
    spendeeHeaderBalanceBlock.includes('text-shadow: var(--spendee-balance-ink-shadow);') &&
    spendeeHeaderBalanceBlock.includes('-webkit-text-stroke: .45px var(--spendee-balance-ink-stroke);'),
  'Lower Spendee balance amount must use adaptive ink color, shadow and micro-stroke variables',
);
assert(
  !spendeeHeaderBalanceBlock.includes('background:') &&
    !spendeeHeaderBalanceBlock.includes('border-radius:') &&
    !spendeeHeaderBalanceBlock.includes('border:'),
  'Lower Spendee balance amount must stay text-only and must not be placed inside its own pill',
);
assert(
  /\.spendee-header \.visibility-dot \{[\s\S]*?color:\s*var\(--spendee-balance-ink\);[\s\S]*?text-shadow:\s*var\(--spendee-balance-ink-shadow\);/.test(
    html,
  ),
  'Lower Spendee balance visibility icon must follow the adaptive balance ink',
);
assert(
  /\.spendee-header \.menu-button \{[\s\S]*?top:\s*55px;[\s\S]*?right:\s*22px;[\s\S]*?width:\s*var\(--spendee-category-menu-button-size\);[\s\S]*?height:\s*var\(--spendee-category-menu-button-size\);[\s\S]*?border-radius:\s*var\(--spendee-category-menu-button-radius\);[\s\S]*?background:\s*var\(--spendee-category-menu-button-bg\);[\s\S]*?border:\s*1px solid var\(--spendee-category-menu-button-border\);[\s\S]*?box-shadow:\s*inset 0 1px 0 rgba\(255,255,255,\.68\),\s*inset 0 -1px 0 rgba\(120,220,230,\.14\);[\s\S]*?backdrop-filter:\s*blur\(12px\);/.test(
    html,
  ),
  'Lower Spendee category menu button must be 20% smaller than the previous 42px glass squircle without a dirty external gray glow',
);
assert(
  !/\.spendee-header \.menu-button \{[\s\S]*?box-shadow:\s*0 6px 14px rgba\(31,45,70,\.08\);/.test(
    html,
  ),
  'Lower Spendee category menu button must not keep the previous gray/dirty external glow',
);
assert(
  /\.spendee-header \.menu-bars \{[\s\S]*?gap:\s*2\.4px;[\s\S]*?\}[\s\S]*?\.spendee-header \.menu-bars span \{[\s\S]*?position:\s*relative;[\s\S]*?width:\s*12px;[\s\S]*?height:\s*2px;[\s\S]*?background:\s*var\(--spendee-category-menu-button-icon\);[\s\S]*?box-shadow:\s*inset 0 1px 0 rgba\(255,255,255,\.74\),\s*inset 0 -1px 0 rgba\(93,198,210,\.20\);[\s\S]*?overflow:\s*hidden;/.test(
    html,
  ),
  'Lower Spendee category menu icon bars must scale down with the 20% smaller glossy glass button',
);
assert(
  /\.spendee-header \.menu-bars span::after \{[\s\S]*?content:\s*"";[\s\S]*?top:\s*\.4px;[\s\S]*?height:\s*\.7px;[\s\S]*?background:\s*rgba\(255,255,255,\.78\);/.test(
    html,
  ),
  'Lower Spendee glossy menu bars must include a fine top highlight to read as raised glass',
);
assert(
  /\.spendee-dashboard-screen \.home-content \{[\s\S]*?top:\s*var\(--spendee-content-top\);/.test(
    html,
  ),
  'Lower Spendee home content must move down independently from the upper legacy --content-top baseline',
);
assert(
  /\.spendee-dashboard-screen \.type-row \{[\s\S]*?height:\s*var\(--spendee-type-row-h\);[\s\S]*?padding:\s*12px 28px;/.test(
    html,
  ),
  'Lower Spendee type row must have its own compact row sizing after the header moves down',
);
assert(
  /\.spendee-dashboard-screen \.type-pill \{[\s\S]*?height:\s*var\(--spendee-type-pill-h\);[\s\S]*?border-radius:\s*21px;/.test(
    html,
  ),
  'Lower Spendee income/expense buttons must be reduced to a 42px pill height',
);
assert(
  /\.spendee-dashboard-screen \.type-pill\.active\.income-type-pill \{[\s\S]*?background:\s*var\(--spendee-income-button-bg\);[\s\S]*?border:\s*0;/.test(
    html,
  ),
  'Lower Spendee active income button must use the Spendee income color variable with no border',
);
assert(
  /\.spendee-dashboard-screen \.type-pill\.expense-type-pill \{[\s\S]*?background:\s*var\(--spendee-expense-button-bg\);[\s\S]*?border:\s*0;/.test(
    html,
  ),
  'Lower Spendee expense button must use the Spendee expense color variable with no border',
);
assert(
  html.indexOf('.spendee-dashboard-screen .type-pill.active.income-type-pill') <
    html.indexOf('.type-pill.income-type-pill') &&
    html.includes('.spendee-dashboard-screen .type-pill.active.income-type-pill'),
  'Lower Spendee income selector must be more specific than the later generic legacy selector so recoloring is visible',
);
assert(
  /\.spendee-dashboard-screen \.summary-pill \{[\s\S]*?border-radius:\s*20px;[\s\S]*?background:\s*var\(--spendee-summary-pill-bg\);[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);/.test(
    html,
  ),
  'Lower Spendee summary pill must be a smaller-radius borderless card with reference-like soft shadow',
);
assert(
  /\.spendee-dashboard-screen \.search-pill \{[\s\S]*?border-radius:\s*20px;[\s\S]*?background:\s*var\(--spendee-search-pill-bg\);[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);/.test(
    html,
  ),
  'Lower Spendee search pill must be a smaller-radius borderless card with reference-like soft shadow',
);
assert(
  /\.log-area \{[\s\S]*?top:\s*236px;[\s\S]*?bottom:\s*0;/.test(html),
  'Legacy/generic log area baseline must remain at 236px top with unchanged bottom',
);
assert(
  /\.spendee-dashboard-screen \.log-area \{[\s\S]*?top:\s*var\(--spendee-log-area-top\);/.test(
    html,
  ),
  'Lower Spendee log window must start higher by using the 216px top override',
);
assert(
  /\.spendee-dashboard-screen \.date-header \{[\s\S]*?height:\s*var\(--spendee-date-header-h\);[\s\S]*?padding:\s*4px 24px 0;/.test(
    html,
  ),
  'Lower Spendee date header must reduce only the top padding between transaction count and date',
);
assert(
  /\.spendee-dashboard-screen \.logbox \{[\s\S]*?height:\s*var\(--spendee-logbox-h\);[\s\S]*?margin:\s*4px 20px;[\s\S]*?border-radius:\s*18px;[\s\S]*?background:\s*var\(--white\);[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);/.test(
    html,
  ),
  'Lower Spendee transaction cards must be 10% shorter, keep 4px spacing, be white/borderless, and use the reference-like soft shadow',
);
assert(
  /\.spendee-dashboard-screen \.log-name \{[\s\S]*?color:\s*#14213a;[\s\S]*?font-weight:\s*800;[\s\S]*?letter-spacing:\s*-\.\d+em;/.test(
    html,
  ),
  'Lower Spendee logbox names must use Spendee-style dark typography and tight letter spacing',
);
assert(
  /\.spendee-dashboard-screen \.log-meta[\s\S]*?\.spendee-dashboard-screen \.time \{[\s\S]*?color:\s*#69768e;[\s\S]*?font-weight:\s*600;/.test(
    html,
  ),
  'Lower Spendee logbox meta/time text must use Spendee-style muted typography',
);
assert(
  /\.spendee-dashboard-screen \{[\s\S]*?background:\s*var\(--app-bg\);/.test(
    html,
  ),
  'Lower Spendee screen background must read only --app-bg so the app background can be colored separately',
);
assert(
  !/\.spendee-dashboard-screen \{[\s\S]*?radial-gradient\(circle at 8% 14%/.test(html) &&
    !/\.spendee-dashboard-screen \{[\s\S]*?radial-gradient\(circle at 92% 15%/.test(html),
  'Hardcoded cyan/purple Spendee screen background glows must be removed; the only glow should come from the header card',
);
assert(
  /\.spendee-dashboard-screen::after \{[\s\S]*?left:\s*-36px;[\s\S]*?right:\s*-36px;[\s\S]*?top:\s*var\(--spendee-status-bar-h\);[\s\S]*?height:\s*var\(--spendee-header-glow-h\);[\s\S]*?background:\s*var\(--spendee-header-glow\);[\s\S]*?filter:\s*blur\(34px\);/.test(
    html,
  ),
  'Lower Spendee header glow must keep the current footprint, starting at the status-bar bottom',
);
assert(
  !/\.spendee-dashboard-screen::before\s*\{/.test(html),
  'Lower Spendee glow must not use a separate status-bar cover layer, because that creates a visible edge',
);
assert(
  /\.spendee-dashboard-screen::after \{[\s\S]*?opacity:\s*\.24;[\s\S]*?-webkit-mask-image:\s*linear-gradient\(to bottom,\s*transparent 0,\s*#000 var\(--spendee-status-glow-fade-h\),\s*#000 100%\),\s*radial-gradient\(ellipse at center,\s*rgba\(0,0,0,1\) 0%,\s*rgba\(0,0,0,\.88\) 46%,\s*rgba\(0,0,0,\.56\) 72%,\s*rgba\(0,0,0,\.18\) 90%,\s*transparent 100%\);[\s\S]*?-webkit-mask-composite:\s*source-in;[\s\S]*?mask-image:\s*linear-gradient\(to bottom,\s*transparent 0,\s*#000 var\(--spendee-status-glow-fade-h\),\s*#000 100%\),\s*radial-gradient\(ellipse at center,\s*rgba\(0,0,0,1\) 0%,\s*rgba\(0,0,0,\.88\) 46%,\s*rgba\(0,0,0,\.56\) 72%,\s*rgba\(0,0,0,\.18\) 90%,\s*transparent 100%\);[\s\S]*?mask-composite:\s*intersect;/.test(
    html,
  ),
  'Lower Spendee header glow must fade from 0 at the status-bar bottom to current glow strength at the visible glow edge, then keep the radial falloff',
);
assert(
  /function updateSpendeeHeaderGlow\(color\) \{[\s\S]*?--spendee-header-glow/.test(html),
  'Applying a color to the Spendee header card must update the automatic header glow variable',
);
const toggleColorSelectionBlock = html.match(
  /function toggleColorSelection\(button\) \{[\s\S]*?\n    \}/,
)?.[0];
assert(toggleColorSelectionBlock, 'Missing toggleColorSelection block');
assert(
  !toggleColorSelectionBlock.includes('updateSpendeeHeaderGlow') &&
    !toggleColorSelectionBlock.includes('--spendee-header-glow') &&
    !toggleColorSelectionBlock.includes('--app-bg'),
  'Palette swatch tap must only select a color; it must not mutate the Spendee glow or app background',
);
assert(
  !html.includes('spendee-reactive-glow') && !html.includes('updateSpendeeReactiveGlow'),
  'The old palette-selection reactive background glow must be removed to avoid lag and background side effects',
);
assert(
  /if \(target\.dataset\.colorTarget === 'header-card' && \(target\.classList\.contains\('spendee-header'\) \|\| target\.classList\.contains\('common-header-card'\)\)\) \{[\s\S]*?updateSpendeeHeaderGlow\(selectionState\.selectedColor\);[\s\S]*?\}/.test(
    html,
  ),
  'Header glow may update only after applying a selected color to an A1 Spendee header card target or the B-row common header card target',
);
assert(
  /\.spendee-dashboard-screen \.bottom-nav \{[\s\S]*?left:\s*var\(--spendee-bottom-nav-side\);[\s\S]*?right:\s*var\(--spendee-bottom-nav-side\);[\s\S]*?bottom:\s*var\(--spendee-bottom-nav-bottom\);[\s\S]*?height:\s*var\(--spendee-bottom-nav-h\);[\s\S]*?border-radius:\s*24px;[\s\S]*?background:\s*var\(--bottom-nav-bg\);[\s\S]*?box-shadow:\s*var\(--spendee-soft-card-shadow\);[\s\S]*?border:\s*0;/.test(
    html,
  ),
  'Lower Spendee bottom nav must be wider than the 20px-gutter logboxes so its rounded corners sit outside the transaction column',
);
assert(
  /\.spendee-dashboard-screen \.nav-item\.active \{[\s\S]*?border-radius:\s*18px;[\s\S]*?background:\s*rgba\(6,182,212,\s*\.10\);/.test(
    html,
  ),
  'Lower Spendee active bottom nav item must be a rounded chip inside the floating nav card',
);
const lowerSpendeeHome = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen" data-screen="alt-home"[\s\S]*?<\/section>\s*<\/div>\s*<div class="screen-column">/,
)?.[0];
assert(lowerSpendeeHome, 'Missing lower Spendee home screen block');
const lowerSpendeeNav = lowerSpendeeHome.match(/<nav class="bottom-nav"[\s\S]*?<\/nav>/)?.[0];
assert(lowerSpendeeNav, 'Missing lower Spendee floating bottom nav');
assert.strictEqual(
  (lowerSpendeeNav.match(/class="nav-item/g) || []).length,
  3,
  'Lower Spendee bottom nav must use the app-style three-item navigation',
);
assert(
  lowerSpendeeNav.includes('Főoldal') &&
    lowerSpendeeNav.includes('Stats') &&
    lowerSpendeeNav.includes('Beállítások') &&
    !lowerSpendeeNav.includes('Értesítések'),
  'Lower Spendee bottom nav labels must match the app source structure and omit the notifications tab',
);

assert(
  /\.palette-grid \{[\s\S]*?grid-template-columns:\s*repeat\(16,\s*38px\);[\s\S]*?width:\s*max-content;/.test(
    html,
  ),
  'Every palette grid must use fixed 38px color-slot columns instead of stretched swatches',
);
assert(
  /\.color-swatch \{[\s\S]*?min-width:\s*38px;[\s\S]*?width:\s*38px;[\s\S]*?height:\s*38px;/.test(
    html,
  ),
  'Every palette swatch must be the same 38px width as the small color slots',
);

const swatchCount = (html.match(/class="color-swatch/g) || []).length;
assert(
  swatchCount >= 45,
  `Expected at least 45 color swatches, got ${swatchCount}`,
);

assert.strictEqual(
  (html.match(/data-palette-group="app-source"/g) || []).length,
  0,
  'Legacy app-source palette slots must be removed during cleanup',
);
assert.strictEqual(
  (html.match(/data-palette-group="proposed-neutral"/g) || []).length,
  0,
  'Legacy proposed-neutral palette slots must be removed during cleanup',
);
assert.strictEqual(
  (html.match(/data-palette-group="keyboardtest-source"/g) || []).length,
  0,
  'Legacy keyboardtest palette slots must be removed during cleanup',
);
assert.strictEqual(
  (html.match(/data-palette-role="text"/g) || []).length,
  0,
  'Legacy text-only palette slots must be removed during cleanup',
);

assert(
  /if \(selectionState\.selectedRole === 'text' \|\| target\.dataset\.colorMode === 'text'\) \{/.test(
    html,
  ),
  'Expected text-role swatches and explicit text targets to exit before background/surface recolor logic',
);

const textApplyBlock = html.match(
  /function applySelectedTextColor\(target\) \{[\s\S]*?\n    \}/,
)?.[0];
assert(textApplyBlock, 'Missing applySelectedTextColor implementation block');
assert(
  !textApplyBlock.includes('backgroundColor') &&
    !textApplyBlock.includes('setProperty(variableName'),
  'Text color application must not mutate background color or surface CSS variables',
);

assert(
  /\.vendor-search-pill \{[\s\S]*?background: var\(--vendor-search-pill-bg\);/.test(
    html,
  ),
  'Vendor search pill must read its own recolorable background CSS variable',
);

assert(
  /class="vendor-search-pill(?:\s+vendor-selector-search-pill)?"[^>]*data-color-target="vendor-search-pill"[^>]*data-color-var="--vendor-search-pill-bg"/.test(
    html,
  ),
  'Vendor search pill must write the same CSS variable that its background reads',
);

assert(
  /\.type-pill\.expense-type-pill \{[\s\S]*?background: var\(--expense-button-bg\);[\s\S]*?border-color: var\(--expense-button-bg\);/.test(
    html,
  ),
  'Expense/Kiadás type pill must read its own recolorable background CSS variable',
);
assert(
  /\.summary-pill \{[\s\S]*?background: var\(--summary-pill-bg\);/.test(html),
  'Home summary pill must read its own recolorable background CSS variable',
);
assert(
  /\.search-pill \{[\s\S]*?background: var\(--search-pill-bg\);/.test(html),
  'Home transaction search pill must read its own recolorable background CSS variable',
);

const homePanelBlocks = [
  ...html.matchAll(/<section class="home-content">[\s\S]*?<section class="log-area">/g),
].map((match) => match[0]);
assert.strictEqual(
  homePanelBlocks.length,
  6,
  'Expected lower Fluvi home, active/no-limit fastinfo stage1, fastinfo stage2, and both duplicated backheader home shells to expose isolated pill targets',
);
const homePanelExpectedVars = [
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
  {
    income: '--spendee-income-button-bg',
    expense: '--spendee-expense-button-bg',
    summary: '--spendee-summary-pill-bg',
    search: '--spendee-search-pill-bg',
  },
];
for (const [index, block] of homePanelBlocks.entries()) {
  const expectedVars = homePanelExpectedVars[index];
  assert(
    new RegExp(
      `class="type-pill active income-type-pill"[^>]*data-color-target="income-type-button"[^>]*data-color-var="${expectedVars.income}"`,
    ).test(
      block,
    ),
    `Home panel ${index + 1} Bevétel button must stay an isolated income target`,
  );
  assert(
    new RegExp(
      `class="type-pill expense-type-pill"[^>]*data-color-target="expense-type-button"[^>]*data-color-var="${expectedVars.expense}"`,
    ).test(
      block,
    ),
    `Home panel ${index + 1} Kiadás button must be an isolated expense target`,
  );
  assert(
    new RegExp(
      `class="summary-pill"[^>]*data-color-target="home-summary-pill"[^>]*data-color-var="${expectedVars.summary}"`,
    ).test(
      block,
    ),
    `Home panel ${index + 1} summary pill must be an isolated summary target`,
  );
  assert(
    new RegExp(
      `class="search-pill"[^>]*data-color-target="home-search-pill"[^>]*data-color-var="${expectedVars.search}"`,
    ).test(
      block,
    ),
    `Home panel ${index + 1} transaction search pill must be an isolated search target`,
  );
}

const selectedRow = html.match(
  /<section class="palette-section selected-palette-section" id="selectedPaletteRow">[\s\S]*?<\/section>/,
)?.[0];
assert(selectedRow, 'Missing selected palette row at the top of the palette');

const selectedSlots = [
  ...selectedRow.matchAll(/data-selected-source-slot="([^"]+)"/g),
].map((match) => match[1]);
assert.deepStrictEqual(
  selectedSlots,
  ['D1', 'N5', 'O5', 'E1', 'P5', 'A6', 'F1', 'B6', 'N3'],
  'Selected source row must be sorted lightest-to-darkest by luminance',
);

const selectedColors = [
  ...selectedRow.matchAll(/data-color="([^"]+)"/g),
].map((match) => match[1]);
assert.deepStrictEqual(
  selectedColors,
  ['#ffffff', '#fcfcfd', '#fafafa', '#f8fafc', '#f7f8fb', '#f4f6f8', '#f1f5f9', '#eef2f6', '#f4f0e8'],
  'Selected source row colors must match the requested source slots',
);

const alternativeAppPalette = html.match(
  /<section class="palette-section" id="alternativeAppPaletteRow">[\s\S]*?<\/section>/,
)?.[0];
assert(alternativeAppPalette, 'Missing alternative app palette row');
assert(
  alternativeAppPalette.includes('white #ffffff') &&
    alternativeAppPalette.includes('gray50 #f8fafc') &&
    alternativeAppPalette.includes('gray100 #f1f5f9') &&
    alternativeAppPalette.includes('gray900 #0f172a'),
  'Alternative app palette must start with real AppColors white/gray shades',
);

const alternativeSlotPalette = html.match(
  /<section class="palette-section" id="alternativeSlotPaletteRow"[^>]*>[\s\S]*?<\/section>/,
)?.[0];
assert(alternativeSlotPalette, 'Missing alternative colour slot palette row');
const logoEditorSection = html.match(
  /<section class="palette-section logo-editor-section" id="spendeeLogoEditor"[^>]*data-logo-editor[\s\S]*?<\/section>/,
)?.[0];
assert(logoEditorSection, 'Missing bottom Spendee path-level logo editor section');
assert(
  html.indexOf('id="selectedPaletteRow"') > html.indexOf('id="alternativePalette"') &&
    html.indexOf('id="selectedPaletteRow"') < html.indexOf('id="alternativeAppPaletteRow"') &&
    html.indexOf('id="alternativeAppPaletteRow"') < html.indexOf('id="alternativeSlotPaletteRow"') &&
    html.indexOf('id="alternativeSlotPaletteRow"') < html.indexOf('id="customGradientPaletteRow"') &&
    html.indexOf('id="customGradientPaletteRow"') < html.indexOf('id="spendeeLogoEditor"') &&
    html.indexOf('id="spendeeLogoEditor"') < html.indexOf('</section>\n      </section>\n    </section>\n    </section>\n  </main>'),
  'The cleaned palette order must be selected source row, app shades, current 21-slot Fluvi row, custom gradients, then logo editor',
);
assert(
  /\.logo-editor-section \{[\s\S]*?min-width:\s*var\(--screen-w\);[\s\S]*?width:\s*max\(var\(--screen-w\),\s*100%\);/.test(
    html,
  ),
  'Logo editor panel must be at least as wide as the app screen',
);
assert(
    logoEditorSection.includes('class="logo-editor-stage"') &&
    logoEditorSection.includes('class="logo-editor-svg"') &&
    logoEditorSection.includes('id="spendeeLogoEditorSvg"') &&
    logoEditorSection.includes('aria-label="Tappable Fluvi logo arcs"'),
  'Logo editor must render a large SVG stage for the tappable whole logo arcs',
);
assert(
  !logoEditorSection.includes('id="fluviLogoVariantPreview"') &&
    !logoEditorSection.includes('data-logo-variant-card') &&
    !logoEditorSection.includes('Eredeti Fluvi') &&
    !logoEditorSection.includes('App-harmonizált') &&
    !logoEditorSection.includes('Portal emissive'),
  'Logo colour recommendation preview cards must be removed while the large editor remains',
);
assert(
  !logoEditorSection.includes('data-logo-abc-scale-panel') &&
    !logoEditorSection.includes('data-logo-scale-center-slider') &&
    !logoEditorSection.includes('data-logo-scale-window-input') &&
    !logoEditorSection.includes('data-logo-scale-stop=') &&
    !logoEditorSection.includes('data-logo-scale-no-colour'),
  'The old logo A/B/C scale and its slider must be removed',
);
const customGradientPaletteStart = html.indexOf('<section class="palette-section custom-gradient-palette-section"');
const customGradientPaletteEnd = customGradientPaletteStart >= 0
  ? html.indexOf('<section class="palette-section logo-editor-section"', customGradientPaletteStart)
  : -1;
const customGradientPaletteSection = customGradientPaletteStart >= 0 &&
  customGradientPaletteEnd > customGradientPaletteStart
  ? html.slice(customGradientPaletteStart, customGradientPaletteEnd)
  : '';
assert(customGradientPaletteSection, 'Missing lower Custom gradient palette section before the logo editor');
assert.strictEqual(
  (customGradientPaletteSection.match(/data-custom-gradient-slot=/g) || []).length,
  5,
  'The lower custom gradient palette must expose exactly five custom slots',
);
assert.strictEqual(
  (customGradientPaletteSection.match(/data-custom-gradient-swatch=/g) || []).length,
  5,
  'Every custom gradient slot must expose a tappable swatch',
);
assert.strictEqual(
  (customGradientPaletteSection.match(/data-custom-gradient-boundary-slider=/g) || []).length,
  5,
  'Every custom gradient slot must expose one compact boundary slider',
);
for (const endpoint of ['left', 'right']) {
  assert.strictEqual(
    (customGradientPaletteSection.match(new RegExp(`data-custom-gradient-endpoint="${endpoint}"`, 'g')) || []).length,
    5,
    `Every custom gradient slot must expose a ${endpoint} endpoint button`,
  );
}
assert(
  html.includes('const customGradientStates =') &&
    html.includes('function buildCustomGradientCss(slotState)') &&
    html.includes('function updateCustomGradientSlot(slotId)') &&
    html.includes('function initCustomGradientPalette()') &&
    html.includes('initCustomGradientPalette();') &&
    /function applySelectedColor\(target\) \{[\s\S]*?selectionState\.selectedColor\.includes\('gradient'\)[\s\S]*?target\.style\.background = selectionState\.selectedColor;/.test(
      html,
    ),
  'Custom gradient slots must maintain state, select through the normal swatch path, and apply gradients to generic backgrounds',
);
const customGradientBoundaryRuntime = [
  extractFunctionSource('normalizeCustomGradientBoundary'),
  extractFunctionSource('buildCustomGradientCss'),
  extractFunctionSource('initCustomGradientPalette'),
].join('\n');
assert(
  customGradientBoundaryRuntime.includes('function normalizeCustomGradientBoundary(value, fallback = 50)') &&
    customGradientBoundaryRuntime.includes('Number.isFinite(numeric)') &&
    customGradientBoundaryRuntime.includes('clampValue(numeric, 0, 100)') &&
    customGradientBoundaryRuntime.includes('normalizeCustomGradientBoundary(slotState.boundary)') &&
    customGradientBoundaryRuntime.includes('normalizeCustomGradientBoundary(slider.value, slotState.boundary)') &&
    customGradientBoundaryRuntime.includes("slider?.addEventListener('change'") &&
    !customGradientBoundaryRuntime.includes('Number(slotState.boundary) || 50') &&
    !customGradientBoundaryRuntime.includes('Number(slider.value) || 50'),
  'Custom gradient boundary sliders must preserve the full 0-100 range, including values below 50',
);
assert(
  /function initSpendeeLogoEditor\(\) \{[\s\S]*?fetch\('fluvi_vector\.svg\?v=20260716-fluvi-logo-v1'\)[\s\S]*?renderLogoSvgPaths\(svg, parsedSvg, true\);[\s\S]*?document\.querySelectorAll\('\[data-logo-live-preview\]'\)\.forEach/.test(
    html,
  ),
  'Logo editor must load the Fluvi SVG asset, render the tappable editor logo and render every app mock logo as a live SVG preview',
);
assert(
  !html.includes('function getFluviLogoContinuousVariantStops') &&
    !html.includes('function applyFluviLogoContinuousVariantGradient') &&
    !html.includes('function renderFluviLogoVariantPreviews') &&
    !html.includes('renderFluviLogoVariantPreviews(parsedSvg);'),
  'Removed logo recommendation preview code must not remain in the runtime',
);
assert(
  /function renderLogoSvgPaths\(svg, parsedSvg, editable\) \{[\s\S]*?path\.dataset\.logoEditorPath = path\.id;[\s\S]*?if \(editable\) \{[\s\S]*?path\.dataset\.colorTarget = 'logo-path';[\s\S]*?path\.classList\.add\('logo-editor-path'\);[\s\S]*?\} else \{[\s\S]*?path\.classList\.add\('logo-live-preview-path'\);/.test(
    html,
  ),
  'Logo renderer must make only editor paths tappable while live-preview paths stay passive but addressable by path id',
);
assert(
  !html.includes('function initLogoAbcScale') &&
    !html.includes('function applyLogoAbcScaleToAllLogos') &&
    !html.includes('function applyLogoAbcScaleToSvg') &&
    !html.includes('logoAbcScaleState') &&
    !html.includes('initLogoAbcScale();'),
  'Removed logo A/B/C scale controller code must not remain in the runtime',
);
assert(
  /function applySelectedLogoPathColor\(target\) \{[\s\S]*?resolveLogoEditorColor\(selectionState\.selectedColor\)[\s\S]*?setLogoPathGradient\(target, resolvedColor\)[\s\S]*?syncLogoLivePreviews\(target\.dataset\.logoEditorPath, resolvedColor\)[\s\S]*?logo-path-applied/.test(
    html,
  ),
  'Applying a selected swatch to a logo path must recolor that editor path and sync every matching mock app logo path',
);
assert(
  /function syncLogoLivePreviews\(pathId, color\) \{[\s\S]*?document\.querySelectorAll\(`\[data-logo-live-preview\] \[data-logo-editor-path="\$\{pathId\}"\]`\)[\s\S]*?setLogoPathGradient\(previewPath, color\);/.test(
    html,
  ),
  'Live mock logo preview sync must update the same path id across every inline app logo preview',
);
assert(
  /function resolveLogoEditorColor\(color\) \{[\s\S]*?getComputedStyle\(document\.documentElement\)\.getPropertyValue\(variableName\)[\s\S]*?\}/.test(
    html,
  ) &&
    /function setLogoPathGradient\(target, color\) \{[\s\S]*?linearGradient[\s\S]*?stop-color[\s\S]*?target\.setAttribute\('fill', `url\(#\$\{gradientId\}\)`\)/.test(
      html,
    ),
  'Logo path recolor must resolve CSS variable palette colors and convert selected gradients into per-path SVG linearGradient fills',
);
assert(
  /function applySelectedColor\(target\) \{[\s\S]*?target\.dataset\.colorTarget === 'logo-path'[\s\S]*?applySelectedLogoPathColor\(target\);[\s\S]*?return;/.test(
    html,
  ),
  'Global color application must route logo path targets before generic background-color handling',
);
assert(
  html.includes('initSpendeeLogoEditor();'),
  'Logo editor must initialize with the rest of the color lab controllers',
);
const alternativeSlotCount =
  (alternativeSlotPalette.match(/data-palette-group="alternative-colour-slots"/g) || [])
    .length;
assert.strictEqual(
  alternativeSlotCount,
  21,
  'Alternative colour slot palette must include all 21 gradient slot colors',
);

const gradientTokenCount = (html.match(/--slot-gradient-\d+:/g) || []).length;
assert.strictEqual(gradientTokenCount, 21, 'Expected 21 Spendee-derived slot gradient tokens');

const gradientSlotReferences = (html.match(/data-color="var\(--slot-gradient-/g) || []).length;
assert.strictEqual(
  gradientSlotReferences,
  21,
  `Expected only the lower Spendee colour slot row to use 21 gradient data-color values, got ${gradientSlotReferences}`,
);

assert.strictEqual(
  (alternativeSlotPalette.match(/data-color="var\(--slot-gradient-/g) || []).length,
  21,
  'The lower Spendee slot row must contain exactly 21 gradient swatches',
);

const previousGradientTokenCount = (html.match(/--previous-slot-gradient-\d+:/g) || []).length;
assert.strictEqual(
  previousGradientTokenCount,
  0,
  'Previous Spendee gradient tokens must be removed during cleanup',
);

const originalGradientTokenCount = (html.match(/--original-slot-gradient-\d+:/g) || []).length;
assert.strictEqual(
  originalGradientTokenCount,
  0,
  'Original first-pass Spendee gradient tokens must be removed during cleanup',
);

const fabBlueGradientTokenCount = (html.match(/--fab-blue-gradient-\d+:/g) || []).length;
assert.strictEqual(
  fabBlueGradientTokenCount,
  0,
  'FAB blue extra gradient tokens must be removed during cleanup',
);

assert(
  alternativeSlotPalette.includes(
    'data-gradient-source="/storage/emulated/0/spendee/layout  avatar colour gradient.png"',
  ),
  'The lower Spendee slot row must record the analysed gradient reference image',
);

assert(
  html.includes('linear-gradient(135deg') &&
    html.includes('linear-gradient(145deg') &&
    html.includes('linear-gradient(125deg'),
  'Gradient slots should use varied diagonal multi-stop gradients based on the Spendee avatar reference',
);

const alternativeSlotSwatches = [
  ...alternativeSlotPalette.matchAll(/<button class="color-swatch"[\s\S]*?>/g),
].map((match) => match[0]);
assert.strictEqual(
  alternativeSlotSwatches.length,
  21,
  'The lower Spendee slot row must expose exactly 21 slot buttons',
);

const fixedSlots = alternativeSlotSwatches.map(
  (tag) => tag.match(/data-fixed-slot="([^"]+)"/)?.[1],
);
assert.deepStrictEqual(
  fixedSlots,
  Array.from({ length: 21 }, (_, index) => String(index + 1)),
  'Lower Spendee colour slots must be fixed-labelled 1 through 21, not auto grid labels like I7/G8/L8',
);

const renderedSlots = alternativeSlotSwatches.map(
  (tag) => tag.match(/data-slot="([^"]+)"/)?.[1],
);
assert.deepStrictEqual(
  renderedSlots,
  Array.from({ length: 21 }, (_, index) => String(index + 1)),
  'Lower Spendee swatch data-slot values must stay 1 through 21 after labelPaletteSlots skips fixed slots',
);

assert(
  /#alternativeSlotPaletteRow \.palette-grid \{[\s\S]*?grid-template-columns:\s*repeat\(7,\s*38px\);[\s\S]*?grid-auto-rows:\s*38px;/.test(
    html,
  ),
  'The lower Spendee palette must render as a fixed 3-row by 7-column grid of 38px slots',
);

const rainbowHues = alternativeSlotSwatches.map((tag) =>
  Number(tag.match(/data-rainbow-hue="([^"]+)"/)?.[1]),
);
assert.deepStrictEqual(
  rainbowHues,
  [0, 14, 28, 42, 56, 70, 84, 98, 112, 126, 140, 154, 168, 182, 196, 210, 224, 238, 252, 266, 280],
  'Lower Spendee slots must increase in rainbow hue order from 1 to 21',
);

function hueDistance(slotA, slotB) {
  const hueA = rainbowHues[slotA - 1];
  const hueB = rainbowHues[slotB - 1];
  const diff = Math.abs(hueA - hueB);
  return Math.min(diff, 360 - diff);
}
assert(
  hueDistance(1, 15) >= 120,
  'Slots 1 and 15 must be separated into different rainbow families',
);
assert(
  hueDistance(4, 10) >= 80,
  'Slots 4 and 10 must be separated into different rainbow families',
);
assert(
  hueDistance(6, 20) >= 160,
  'Slots 6 and 20 must be separated into different rainbow families',
);
assert(
  /violet|purple|orchid/i.test(alternativeSlotSwatches[18]) &&
    !/ember|brown|burnt/i.test(alternativeSlotSwatches[18]),
  'Slot 19 must be replaced with a different non-brown/non-ember rainbow family',
);

for (const [index, tag] of alternativeSlotSwatches.entries()) {
  const slotNumber = String(index + 1);
  assert(
    tag.includes(`aria-label="${slotNumber} · spendee gradient slot ${slotNumber}`),
    `Lower Spendee slot ${slotNumber} must render its visible/accessibility label as ${slotNumber}`,
  );
  assert(
    tag.includes(`var(--slot-gradient-${index})`),
    `Lower Spendee slot ${slotNumber} must map to --slot-gradient-${index}`,
  );
}

const gradientEntries = [...html.matchAll(/--slot-gradient-(\d+):\s*([^;]+);/g)]
  .map((match) => ({
    index: Number(match[1]),
    value: match[2],
    stops: [...match[2].matchAll(/#[0-9a-f]{6}/gi)].map((stop) => stop[0].toLowerCase()),
  }))
  .sort((a, b) => a.index - b.index);
assert.deepStrictEqual(
  gradientEntries.map((entry) => entry.index),
  Array.from({ length: 21 }, (_, index) => index),
  'Spendee gradients must be numbered --slot-gradient-0 through --slot-gradient-20',
);
for (const entry of gradientEntries) {
  assert.strictEqual(
    entry.stops.length,
    3,
    `--slot-gradient-${entry.index} must use exactly three explicit hex stops`,
  );
}

const allGradientStops = gradientEntries.flatMap((entry) => entry.stops);
const duplicateStops = allGradientStops.filter(
  (stop, index) => allGradientStops.indexOf(stop) !== index,
);
assert.deepStrictEqual(
  [...new Set(duplicateStops)],
  [],
  'A hex stop color used in one lower Spendee slot must not be reused in another slot',
);

const gradientSignatures = gradientEntries.map((entry) => entry.stops.join('>'));
assert.strictEqual(
  new Set(gradientSignatures).size,
  21,
  'No lower Spendee gradient may duplicate another gradient',
);
const inverseDuplicate = gradientEntries.find((entry) =>
  gradientEntries.some(
    (other) =>
      other.index !== entry.index &&
      other.stops.join('>') === entry.stops.slice().reverse().join('>'),
  ),
);
assert.strictEqual(
  inverseDuplicate,
  undefined,
  'No lower Spendee gradient may be the inverse of another slot',
);

const logboxBlocks = [...html.matchAll(/<article class="logbox"[\s\S]*?<\/article>/g)].map(
  (match) => match[0],
);
assert.strictEqual(
  logboxBlocks.length,
  54,
  'Expected five lower Fluvi home, fifteen fastinfo home-shell, ten duplicated lower backheader home-shell, and twenty-four B-row common-header A1-stack logbox rows after B1/B2/B3M bottom-fill rows',
);
for (const [index, block] of logboxBlocks.entries()) {
  assert(
    /class="avatar-46[\s\S]*class="slot-icon logbox-avatar-icon"/.test(block),
    `Logbox ${index + 1} avatar must contain a dedicated white logbox avatar icon`,
  );
  assert(
    block.includes('data-icon-color="#ffffff"') &&
      block.includes('--icon-color:#ffffff') &&
      block.includes('--icon-size:28px'),
    `Logbox ${index + 1} icon must be explicitly white and 28px inside the 46px avatar`,
  );
}

const lowerSpendeeSection = alternativeSection;
assert(lowerSpendeeSection.includes('Fluvi'), 'Lower alternative section must be labelled Fluvi');

const logboxAvatarTargetCount = (lowerSpendeeSection.match(/data-color-target="logbox-avatar-circle"/g) || [])
  .length;
assert.strictEqual(logboxAvatarTargetCount, 54, 'Expected 54 separate lower Spendee logbox avatar circle targets across the home, all fastinfo variants, both duplicated backheader home-shell screens, and all B-row common-header rows including B1/B2/B3M bottom-fill rows');

const categoryAvatarTargetCount =
  (lowerSpendeeSection.match(/data-color-target="category-avatar-circle"/g) || []).length;
assert(
  categoryAvatarTargetCount >= 7,
  `Expected lower Spendee category card/add sheet avatar circles to be separate targets, got ${categoryAvatarTargetCount}`,
);

const vendorAvatarTargetCount = (lowerSpendeeSection.match(/data-color-target="vendor-avatar-circle"/g) || [])
  .length;
assert(
  vendorAvatarTargetCount >= 12,
  `Expected at least 12 separate lower Spendee vendor avatar circle targets after the fullscreen vendor selector redesign, got ${vendorAvatarTargetCount}`,
);

assert(
  !html.includes('../../assets/icons/lucide/'),
  'Icon mask URLs must be served from repo-root /assets so browser HTTP loading works',
);

const whiteAvatarIconCount = (html.match(/data-icon-color="#ffffff"/g) || []).length;
assert(
  whiteAvatarIconCount >= 32,
  `Expected every colored avatar circle to have an explicit white icon, got ${whiteAvatarIconCount}`,
);

const groceryCategoryCardBlock = lowerCategorySelectorScreen.match(
  /<article class="category-card category-selector-card selected"[\s\S]*?<span class="card-title">Élelmiszer<\/span>[\s\S]*?<\/article>/,
)?.[0];
assert(groceryCategoryCardBlock, 'Missing Élelmiszer category selector avatar card');
assert(
  groceryCategoryCardBlock.includes('slot-icon category-avatar-icon') &&
    groceryCategoryCardBlock.includes('data-icon-color="#ffffff"'),
  'Élelmiszer colored category selector circle must contain a white app icon',
);

const vendorBlocks = [...lowerSpendeeSection.matchAll(/<article class="vendor-card vendor-selector-card[^"]*"[\s\S]*?<\/article>/g)].map(
  (match) => match[0],
);
assert(vendorBlocks.length >= 10, 'Expected compact fullscreen vendor selector cards in the lower Spendee panel');
for (const [index, block] of vendorBlocks.entries()) {
  assert(
    block.includes('vendor-card-avatar-circle') &&
      block.includes('data-color-target="vendor-avatar-circle"') &&
      block.includes('data-color-var="--vendor-avatar-bg"') &&
      block.includes('vendor-avatar-icon') &&
      block.includes('data-icon-color="#ffffff"') &&
      block.includes('url(\'/assets/icons/lucide/'),
    `Vendor card ${index + 1} must contain a white app SVG icon served from /assets`,
  );
}

const categoryBlocks = [...lowerCategorySelectorScreen.matchAll(/<article class="category-card category-selector-card[\s\S]*?<\/article>/g)].map(
  (match) => match[0],
);
assert(categoryBlocks.length >= 16, 'Expected compact category selector cards to fill the lower Spendee A2 panel');
for (const [index, block] of categoryBlocks.entries()) {
  assert(
    block.includes('category-card-avatar-circle') &&
      block.includes('data-color-target="category-avatar-circle"') &&
      block.includes('data-color-var="--category-avatar-bg"') &&
      block.includes('category-avatar-icon') &&
      block.includes('data-icon-color="#ffffff"'),
    `Category card ${index + 1} must contain a separately recolorable white-icon avatar circle`,
  );
  assert(
    !block.includes('category-selector-drag-dots') && !block.includes('category-selector-color-dot'),
    `Category card ${index + 1} must not contain removed drag handles or subtitle color dots`,
  );
}

assert(
  /function readableTextColor\(hex\) \{[\s\S]*?if \(!\(\?/.test(html) ||
    html.includes("if (!/^#?[0-9a-f]{6,8}$/i.test(hex)) return '#ffffff';"),
  'Readable text helper must safely handle gradient/var() selections',
);

const commonHeaderNavRowStart = html.indexOf(
  '<div class="common-header-row" data-section-row="common-header-dashboard"',
);
const commonHeaderNavScaleStart = html.indexOf(
  '<section class="balance-header-scale-lab common-mode-scale-lab" id="balanceHeaderScaleLab"',
);
assert(commonHeaderNavRowStart >= 0 && commonHeaderNavScaleStart > commonHeaderNavRowStart, 'Missing B-row common-header source markup before the balance scale lab');
const commonHeaderNavSourceRow = html.slice(commonHeaderNavRowStart, commonHeaderNavScaleStart);
const commonHeaderNavSourceScreens = [
  commonHeaderStage0,
  commonHeaderStage1,
  commonHeaderStage2,
].join('');

assert(
  html.includes('--common-header-stage-shortening: var(--search-pill-h);'),
  'Common header stages must define the search-pill-height shortening token',
);
assert(
  html.includes('--common-header-stage1-h: calc(284px - var(--common-header-stage-shortening));'),
  'Common header stage1 must be shortened by the search-pill height',
);
assert(
  html.includes('--common-header-stage2-bottom-anchor: calc(var(--screen-h) - var(--bottom-nav-h));'),
  'Common header stage2 bottom anchor must be the top of the legacy inline bottom nav',
);
assert(
  html.includes('--common-header-stage2-safety-top: calc(var(--common-header-stage2-bottom-anchor) - var(--common-header-search-top-gap));'),
  'Common header stage2 safety top must leave the same gap above the bottom-nav anchor as the summary/search gap',
);
assert(
  html.includes('function buildCommonHeaderBottomNav') &&
    html.includes('function ensureCommonHeaderBottomNav') &&
    html.includes('ensureCommonHeaderBottomNav(screen);'),
  'Common-header runtime cloning must ensure the restored bottom nav exists on all generated B/C/D screens',
);
assert.strictEqual(
  (commonHeaderNavSourceScreens.match(/data-common-header-bottom-nav/g) || []).length,
  3,
  'The B-row source screens must each include the restored common-header bottom nav so C/D clones inherit it',
);
assert.strictEqual(
  (commonHeaderNavSourceScreens.match(/data-common-header-fab/g) || []).length,
  3,
  'The B-row source screens must each include the centered inline common-header FAB',
);
assert.strictEqual(
  (commonHeaderNavSourceScreens.match(/data-nav-destination="dashboard"/g) || []).length,
  3,
  'Every B-row common-header source screen must expose the left Dashboard nav action',
);
assert.strictEqual(
  (commonHeaderNavSourceScreens.match(/data-nav-destination="settings"/g) || []).length,
  3,
  'Every B-row common-header source screen must expose the right Settings nav action',
);
assert(
  commonHeaderNavSourceRow.includes('data-nav-style="legacy-inline-fab"'),
  'The common-header nav must identify the legacy inline FAB design style',
);
assert(
  !html.includes('--common-header-nav-notch-size') &&
    !html.includes('--common-header-nav-notch-rise') &&
    !html.includes('.common-header-screen .common-header-bottom-nav::before') &&
    !html.includes('class="fab common-header-center-fab"'),
  'The legacy-inline common-header nav must remove the notch/bump pseudo-element and separate centered sibling FAB',
);
assert(
  /\.common-header-screen \.common-header-bottom-nav \{[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;[\s\S]*?bottom:\s*0;[\s\S]*?height:\s*var\(--bottom-nav-h\);[\s\S]*?padding:\s*var\(--bottom-nav-vpad\) var\(--bottom-nav-hpad\);[\s\S]*?border-top:\s*1px solid var\(--gray-200\);[\s\S]*?box-shadow:\s*0 -8px 16px var\(--nav-shadow\);/.test(html),
  'The common-header bottom nav must reuse the first legacy inline bar style as a full-screen-width bottom bar',
);
assert(
  /\.spendee-dashboard-screen \.bottom-nav\s*\{[\s\S]*?left:\s*var\(--spendee-bottom-nav-side\);[\s\S]*?right:\s*var\(--spendee-bottom-nav-side\);[\s\S]*?\}/.test(html) &&
    /\.spendee-dashboard-screen\.common-header-screen \.common-header-bottom-nav\s*\{[\s\S]*?left:\s*0;[\s\S]*?right:\s*0;[\s\S]*?bottom:\s*0;[\s\S]*?height:\s*var\(--bottom-nav-h\);[\s\S]*?border-radius:\s*0;[\s\S]*?\}/.test(html),
  'The common-header bottom nav must have a cascade-safe full-width override so the later Spendee floating 8px/18px/radius island rule cannot apply',
);
assert(
  /\.common-header-screen \.common-header-inline-fab \{[\s\S]*?flex:\s*0 0 58px;[\s\S]*?width:\s*58px;[\s\S]*?height:\s*58px;[\s\S]*?border-radius:\s*50%;/.test(html),
  'The common-header FAB must be a circular inline center slot inside the nav',
);
assert.strictEqual(
  (commonHeaderNavSourceScreens.match(/data-common-header-inline-fab/g) || []).length,
  3,
  'Each common-header source nav must render the center FAB inline inside the bottom nav',
);
assert(
  html.includes('--common-header-stage2-safety-top: calc(var(--common-header-stage2-bottom-anchor) - var(--common-header-search-top-gap));'),
  'Stage2 search pill bottom must keep the same gap from the bottom-nav top as the summary/search gap',
);
assert(
  /\.common-stage2-stage1-layer\s*\{[\s\S]*?bottom:\s*auto;[\s\S]*?height:\s*calc\(var\(--common-header-stage1-h\) - 114px\);[\s\S]*?\}/.test(html) &&
    !/\.common-stage2-stage1-layer\s*\{[\s\S]*?height:\s*170px;[\s\S]*?\}/.test(html),
  'B3/D3/D4 cloned stage1 content must use the same content rectangle height as B2/D2 instead of the old taller stage2 box',
);
assert(
  /\.common-header-screen \.common-header-inline-fab \{[\s\S]*?background:\s*var\(--primary\);/.test(html),
  'The common-header inline FAB must be blue like the latest screenshot',
);
assert(
  commonHeaderStage1.includes('data-balance-ratio-placement="reserve-progress-slot"') &&
    commonHeaderStage1.includes('data-fastinfo-card="balance-placeholder"') &&
    !commonHeaderStage1.includes('data-fastinfo-card="balance-ratio"') &&
    commonHeaderStage1.indexOf('data-balance-ratio-placement="reserve-progress-slot"') <
      commonHeaderStage1.indexOf('class="common-balance-stage1-card-grid"'),
  'B2 must move balance ratio, income, and expense values from the right fastinfo card into the former white progress slot',
);
assert(
  commonHeaderStage2.includes('data-balance-ratio-placement="reserve-progress-slot"') &&
    commonHeaderStage2.includes('data-fastinfo-card="balance-placeholder"') &&
    commonHeaderStage2.includes('data-stage2-extra="balance-diagnostics"') &&
    commonHeaderStage2.includes('data-balance-diagnostic-panel="scrollable"') &&
    !commonHeaderStage2.includes('data-fastinfo-card="balance-ratio"') &&
    !commonHeaderStage2.includes('data-focus-mode-stage2="balance-income-expense"') &&
    !commonHeaderStage2.includes('class="common-stage2-income-expense-layer"') &&
    !commonHeaderStage2.includes('common-stage2-graph-stack'),
  'B3 must use the same stage1 content, add the scrollable diagnostics panel, and remove the old stage2 graph stack',
);
assert(
  html.includes('function buildCommonMindScoreRibbon') &&
    html.includes('data-score-ribbon-stage0') &&
    html.includes('data-score-ribbon-path="bad-neutral-good"') &&
    html.includes('function buildCommonMindDoubleGraphContent') &&
    html.includes('data-mind-double-graph="${kind}"') &&
    html.includes('function buildCommonMindMergedBarGraphContent') &&
    html.includes('data-mind-chart-box-size="d2-stage1"') &&
    html.includes('data-mind-chart-part="${part.key}"') &&
    html.includes('function buildCommonMindStage1BoxGraphContent') &&
    !html.includes('data-screen="alt-common-header-mind-income-stage2"'),
  'Mind mode must expose a stage0 score ribbon and D2 box layout while the D4 income stage2 screen remains removed',
);
assert(
  !html.includes('data-focus-mode-stage1="mind-score-graph"'),
  'The old Mind score graph panel must be removed from stage1; only the compact score ribbon remains in stage0/core',
);
const rebuiltPortalStart = html.indexOf(
  '<div class="mind-portal-test-header-wrap" data-mind-portal-test-header>',
);
const rebuiltPortalEnd = html.indexOf(
  '<section class="palette-area structured-palette" id="alternativePalette"',
  rebuiltPortalStart,
);
const rebuiltPortalLab = html.slice(rebuiltPortalStart, rebuiltPortalEnd);
assert(rebuiltPortalStart >= 0, 'Missing standalone portal test lab');
assert(
  rebuiltPortalLab.includes('data-mind-portal-mode="dual-tide"') &&
    /<option value="dual-tide" selected>Kettős árapály<\/option>/.test(rebuiltPortalLab) &&
    rebuiltPortalLab.includes('<span data-mind-portal-mode-label>Kettős árapály</span>'),
  'The rebuilt portal must start with a visible animated energy field instead of a static-only A/B layer',
);
assert.strictEqual(
  (rebuiltPortalLab.match(/data-mind-portal-signature-slider=/g) || []).length,
  7,
  'Static portal controls must expose Traffic, Limit, Cool, Money flow, Meadow green, Soft rainbow, and Ocean blue serenity sliders',
);
for (const token of [
  'data-mind-portal-signature-slider="money-flow"',
  'data-mind-portal-signature-value="money-flow"',
  'data-mind-portal-signature-slider="meadow-green"',
  'data-mind-portal-signature-slider="soft-rainbow"',
  'data-mind-portal-signature-slider="ocean-blue-serenity"',
  '50–50',
]) {
  assert(rebuiltPortalLab.includes(token), `Missing Money-flow UI token: ${token}`);
}
assert(
  !rebuiltPortalLab.includes('data-mind-portal-money-flow-input') &&
    !(rebuiltPortalLab.match(/<label class="mind-portal-signature-row no-window-input" data-signature-kind="money-flow">[\s\S]*?<\/label>/)?.[0] || '').includes(
      'class="mind-portal-signature-window-input"',
    ),
  'Money-flow must be slider-only in the rebuilt portal and must not expose a numeric/text input beside the slider',
);
for (const color of [
  '#49cfc5',
  '#8defe5',
  '#f8e8f3',
  '#f7b2f5',
  '#d8b4fe',
]) {
  assert(html.includes(color), `Missing Money-flow palette color: ${color}`);
}
assert(
  html.includes('function applyMindPortalMoneyFlow(incomePercent)') &&
    html.includes('MindPortalEnergy.moneyFlowStopPositions') &&
    html.includes('data-mind-portal-active-palette') &&
    html.includes('data-mind-portal-active-palette-positions') &&
    html.includes("data-mind-portal-signature-source', 'money-flow'") &&
    html.includes('data-mind-portal-money-flow-income') &&
    html.includes('`${income}–${expense}`') &&
    /\.mind-portal-signature-row\[data-signature-kind="money-flow"\] input\[type="range"\]\s*\{[\s\S]*?accent-color:\s*#49cfc5;/.test(
      html,
    ),
  'Money-flow slider must drive the five-stop static income-expense gradient',
);
assert(
  !rebuiltPortalLab.includes('data-mind-portal-bg-opacity-slider') &&
    !rebuiltPortalLab.includes('data-mind-portal-motion-panel') &&
    !rebuiltPortalLab.includes('data-mind-portal-rotation-pad'),
  'The rebuilt portal must keep old header-opacity, old motion, and rotation controls removed',
);
for (const mode of [
  'static',
  'dual-tide',
  'magnetic-membrane',
  'breathing-lens',
  'cellular-field',
]) {
  assert(
    rebuiltPortalLab.includes(`<option value="${mode}"`),
    `Missing rebuilt portal dropdown option: ${mode}`,
  );
}
for (const [mode, label] of [
  ['balance-membrane', 'Balance membrán'],
  ['balance-counterflow', 'Balance ellenáram'],
  ['balance-charges', 'Balance töltések'],
]) {
  assert(
    rebuiltPortalLab.includes(`<option value="${mode}">${label}</option>`),
    `Missing Balance portal dropdown option: ${mode}`,
  );
}
assert(
  rebuiltPortalLab.indexOf('<option value="cellular-field">') <
    rebuiltPortalLab.indexOf('<option value="balance-membrane">') &&
    rebuiltPortalLab.indexOf('<option value="balance-membrane">') <
      rebuiltPortalLab.indexOf('<option value="balance-counterflow">') &&
    rebuiltPortalLab.indexOf('<option value="balance-counterflow">') <
      rebuiltPortalLab.indexOf('<option value="balance-charges">'),
  'Balance modes must append after the unchanged five-mode dropdown prefix',
);
assert.strictEqual(
  (rebuiltPortalLab.match(/data-mind-portal-idle-canvas/g) || []).length,
  1,
  'Balance fields must reuse the standalone portal canvas',
);
assert(
  html.includes('MindPortalEnergy.controlsForMode(mode)') &&
    html.includes('MindPortalEnergy.isBalanceMode(activeMode)') &&
    html.includes('MindPortalEnergy.sampleMoneyFlowField(') &&
    html.includes('MindPortalEnergy.samplePaletteColor(') &&
    html.includes('function getMindPortalActivePalette(header)') &&
    html.includes('function sampleMindPortalActivePaletteColor(header, sample)') &&
    !html.includes('applyMindPortalMoneyFlow(ratioSlider?.value || 50)'),
  'Every energy mode must keep its field schema while sampling the active color palette instead of forcing Money-flow',
);
const setMindPortalEnergyModeRuntime = extractFunctionSource('setMindPortalEnergyMode');
assert(
  !html.includes('function leaveMindPortalMoneyFlowState(header)') &&
    !/setMindPortalEnergyMode\(header,\s*'static'\)/.test(
      extractFunctionSource('applyMindPortalTestHeaderColors'),
    ) &&
    !setMindPortalEnergyModeRuntime.includes('applyMindPortalMoneyFlow') &&
    /function applyMindPortalTestHeaderColors\(source, a, b, options = \{\}\) \{[\s\S]*?data-mind-portal-active-palette/.test(
      html,
    ),
  'Changing the active color source must not reset the current energy mode, and changing mode must not force Money-flow',
);
const syncMindPortalAnimatedPaletteRuntime = extractFunctionSource(
  'syncMindPortalAnimatedPalette',
);
const wakeMindPortalEnergyFrameRuntime = extractFunctionSource(
  'wakeMindPortalEnergyFrame',
);
const scheduleMindPortalEnergyFrameRuntime = extractFunctionSource(
  'scheduleMindPortalEnergyFrame',
);
const updatePortalMessageFieldPaletteRuntime = extractFunctionSource(
  'updatePortalMessageFieldPalette',
);
assert(
  /function applyMindPortalTestHeaderColors\(source, a, b, options = \{\}\) \{[\s\S]*?header\.setAttribute\('data-mind-portal-active-palette'[\s\S]*?syncMindPortalAnimatedPalette\(header\);/.test(
    html,
  ) &&
    syncMindPortalAnimatedPaletteRuntime.includes('wakeMindPortalEnergyFrame(header, state)') &&
    syncMindPortalAnimatedPaletteRuntime.includes('messageState.messageFieldDirty = true') &&
    syncMindPortalAnimatedPaletteRuntime.includes('updatePortalMessageFieldPalette(wrap, messageState)') &&
    syncMindPortalAnimatedPaletteRuntime.includes('schedulePortalMessageFieldFrame(wrap)') &&
    syncMindPortalAnimatedPaletteRuntime.includes('syncPortalVisibleBackgroundOpacity(wrap)'),
  'Changing any testheader color source must invalidate the testheader canvas, interior overlay, message field, and visible background endpoint',
);
assert(
  wakeMindPortalEnergyFrameRuntime.includes('if (!canRenderMindPortalEnergyFrame(header, state)) return;') &&
    wakeMindPortalEnergyFrameRuntime.includes('state.lastFrameTime = 0') &&
    wakeMindPortalEnergyFrameRuntime.includes('state.lastNow = performance.now()') &&
    wakeMindPortalEnergyFrameRuntime.includes('scheduleMindPortalEnergyFrame(header, state)') &&
    scheduleMindPortalEnergyFrameRuntime.includes('if (!canRenderMindPortalEnergyFrame(header, state)) return;') &&
    scheduleMindPortalEnergyFrameRuntime.includes('if (state.frame') &&
    scheduleMindPortalEnergyFrameRuntime.includes('state.frame = 0') &&
    scheduleMindPortalEnergyFrameRuntime.includes('const keepRunning = drawMindPortalEnergyFrame(header, canvas, ctx, state, now);') &&
    scheduleMindPortalEnergyFrameRuntime.includes('if (keepRunning) scheduleMindPortalEnergyFrame(header, state);'),
  'Slider changes and mode changes must wake a stopped shared energy RAF loop only when the header is renderable',
);
assert(
  updatePortalMessageFieldPaletteRuntime.includes('getMindPortalActivePalette(header)') &&
    updatePortalMessageFieldPaletteRuntime.includes('sampleMindPortalActivePaletteStop(header') &&
    updatePortalMessageFieldPaletteRuntime.includes('--portal-message-field-scale-gradient') &&
    !updatePortalMessageFieldPaletteRuntime.includes('PortalMessageField.sampleWindow('),
  'Portal background-morph/message-field palettes must sample the active testheader palette instead of a dedicated static palette',
);
assert(
  rebuiltPortalLab.includes('data-mind-portal-mode-select') &&
    !rebuiltPortalLab.includes('data-mind-portal-mode-button') &&
    /\.mind-portal-signature-panel,\s*\.mind-portal-opacity-control,\s*\.mind-portal-mode-panel,\s*\.mind-portal-message-panel,\s*\.mind-portal-background-panel,\s*\.mind-portal-message-field-panel\s*\{[\s\S]*?width:\s*min\(360px,\s*calc\(100% - 40px\)\);[\s\S]*?\}/.test(
      html,
    ) &&
    /\.mind-portal-mode-select-row\s*\{[\s\S]*?display:\s*grid;[\s\S]*?grid-template-columns:\s*minmax\(0,\s*1fr\);[\s\S]*?\}/.test(
      html,
    ) &&
    /\.mind-portal-mode-select-row select\s*\{[\s\S]*?height:\s*34px;[\s\S]*?width:\s*100%;[\s\S]*?\}/.test(
      html,
    ) &&
    /\.mind-portal-energy-controls-scroll\s*\{[\s\S]*?max-height:\s*min\(30vh, 240px\);[\s\S]*?overflow-y:\s*auto;/.test(
      html,
    ) &&
    /select\??\.addEventListener\('change', \(\) => \{/.test(html) &&
    html.includes('setMindPortalEnergyMode(header, select.value, true)') &&
    !/\.mind-portal-mode-panel\s*\{[\s\S]*?width:\s*min\(760px/.test(html) &&
    !/max-height:\s*min\(52vh, 520px\)/.test(html),
  'The portal settings panel must match slider width, use a dropdown selector, and keep a shorter phone-screen controls viewport',
);
for (const removed of [
  'mindPortalGlobalTransform',
  'mindPortalUpdateRotationClock',
  'mindPortalLevelViewField',
  'mindPortalLegacyMeshField',
  'mindPortalYinYangField',
  'mindPortalMotionPresets',
]) {
  assert(!html.includes(removed), `Removed portal system leaked: ${removed}`);
}
assert(
  html.includes('src="./color_lab_portal_energy.js"'),
  'The color lab must load the pure portal energy module before its inline controller',
);
assert.ok(html.includes('data-portal-interior-motion-row'));
assert.ok(html.includes('data-portal-interior-motion-toggle'));
assert.ok(html.includes('data-portal-interior-motion-mode-select'));
assert.ok(html.includes('data-portal-interior-motion-mode-reset'));
assert.ok(html.includes('data-portal-interior-motion-controls-scroll'));
assert.ok(html.includes('data-portal-interior-motion-rotation-toggle'));
assert.ok(html.includes('data-portal-interior-motion-rotation-speed-range'));
assert.ok(html.includes('data-portal-interior-motion-rotation-speed-number'));
assert.ok(!html.includes('data-portal-interior-motion-effect'));
assert.ok(!html.includes('data-portal-interior-motion-strength'));
assert.ok(!html.includes('data-portal-interior-motion-speed'));
for (const value of [
  'solid-a',
  'static-matter',
  'wandering-mist',
  'living-archipelago',
  'forming-clouds',
]) {
  assert.ok(html.includes(`value="${value}"`));
}
assert.ok(html.includes('renderPortalInteriorMotion'));
assert.ok(!/portalInteriorMotion[\s\S]{0,300}requestAnimationFrame/.test(html));
const portalInteriorLifecycleFunctionNames = [
  'ensureMindPortalEnergyState',
  'syncPortalInteriorMotionControls',
  'setPortalInteriorMotionState',
  'initPortalInteriorMotionControls',
];
const portalInteriorControlLifecycle = portalInteriorLifecycleFunctionNames
  .map((functionName) => extractFunctionSource(functionName))
  .join('\n');
for (const scheduler of ['requestAnimationFrame', 'setInterval(', 'setTimeout(']) {
  assert.ok(
    !portalInteriorControlLifecycle.includes(scheduler),
    `Portal interior state/control/helper lifecycle must not create a private scheduler: ${scheduler}`,
  );
}
const portalInteriorMotionModelScript = 'src="./color_lab_portal_interior_motion.js"';
const portalInteriorMotionRendererScript =
  'src="./color_lab_portal_interior_motion_renderer.js"';
const inlineColorLabController = '<script>\n    const selectionState = {';
assert(
  html.includes(portalInteriorMotionModelScript) &&
    html.includes(portalInteriorMotionRendererScript) &&
    html.indexOf('src="./color_lab_portal_transition_player.js"') <
      html.indexOf(portalInteriorMotionModelScript) &&
    html.indexOf(portalInteriorMotionModelScript) <
      html.indexOf(portalInteriorMotionRendererScript) &&
    html.indexOf(portalInteriorMotionRendererScript) <
      html.indexOf(inlineColorLabController),
  'Portal interior motion scripts must load model-before-renderer after dependencies and before the inline controller',
);
const portalInteriorFrameRuntime = extractFunctionSource('drawMindPortalEnergyFrame');
const portalInteriorRendererCall =
  'PortalInteriorMotionRenderer.renderPortalInteriorMotion(ctx, {';
const portalInteriorRendererCallPattern =
  /\brenderPortalInteriorMotion\s*\(/g;
const portalInteriorRendererCallIndex = portalInteriorFrameRuntime.indexOf(
  portalInteriorRendererCall,
);
const portalInteriorFrameStartIndex = html.indexOf(portalInteriorFrameRuntime);
const portalInteriorDocumentCallIndex = html.indexOf(portalInteriorRendererCall);
const portalInteriorBaseFrameIndex = portalInteriorFrameRuntime.indexOf(
  'ctx.putImageData(image, 0, 0);',
);
const portalInteriorFrameFinalizationIndex = portalInteriorFrameRuntime.indexOf(
  'canvas.style.opacity = getMindPortalBaseCanvasOpacity(header);',
);
assert.strictEqual(
  (html.match(portalInteriorRendererCallPattern) || []).length,
  1,
  'The full Color Lab document must contain exactly one interior renderer invocation',
);
assert.strictEqual(
  (portalInteriorFrameRuntime.match(portalInteriorRendererCallPattern) || []).length,
  1,
  'The shared Balance frame must contain exactly one interior renderer call',
);
assert(
  portalInteriorFrameStartIndex >= 0 &&
    portalInteriorDocumentCallIndex >= portalInteriorFrameStartIndex &&
    portalInteriorDocumentCallIndex <
      portalInteriorFrameStartIndex + portalInteriorFrameRuntime.length &&
  portalInteriorBaseFrameIndex >= 0 &&
    portalInteriorRendererCallIndex > portalInteriorBaseFrameIndex &&
    portalInteriorFrameFinalizationIndex > portalInteriorRendererCallIndex,
  'The sole interior renderer call must belong to the shared Balance frame, after base pixels and before finalization',
);
const portalInteriorEligibilityMatch = portalInteriorFrameRuntime.match(
  /const\s+([A-Za-z_$][\w$]*)\s*=\s*state\.portalInteriorMotionState\?\.enabled\s*===\s*true\s*&&\s*typeof PortalInteriorMotionRenderer\s*!==\s*'undefined';/,
);
assert(
  portalInteriorEligibilityMatch,
  'Interior eligibility must require enabled state and renderer availability without being limited to Balance energy modes',
);
const portalInteriorEligibility = portalInteriorEligibilityMatch?.[1] || '';
const portalEnergyMotionEligibilityMatch = portalInteriorFrameRuntime.match(
  /const\s+([A-Za-z_$][\w$]*)\s*=\s*Boolean\(\s*settings\s*&&\s*settings\.strength > 0\s*&&\s*motionAllowed\s*\);/,
);
assert(
  portalInteriorFrameRuntime.includes('const motionAllowed = !state.reducedMotion || state.reducedMotionOverride;') &&
    portalEnergyMotionEligibilityMatch,
  'Existing Balance energy motion must have eligibility independent from interior motion',
);
const portalEnergyMotionEligibility = portalEnergyMotionEligibilityMatch?.[1] || '';
const portalInteriorElapsedTimeIndex = portalInteriorFrameRuntime.indexOf(
  'const elapsedSeconds',
);
const portalInteriorEarlyReturn = portalInteriorFrameRuntime.slice(
  portalInteriorFrameRuntime.indexOf('if ('),
  portalInteriorElapsedTimeIndex,
);
assert(
  new RegExp(
    `!${portalEnergyMotionEligibility}\\s*&&\\s*!${portalInteriorEligibility}`,
  ).test(portalInteriorEarlyReturn) &&
    !portalInteriorEarlyReturn.includes("activeMode === 'static' ||"),
  'A frame may continue when either existing energy motion or interior motion is eligible, including static mode plus interior overlay',
);
const portalInteriorPhaseAdvanceIndex = portalInteriorFrameRuntime.indexOf(
  'MindPortalEnergy.advancePhase(',
);
const portalInteriorPhaseGuardIndex = portalInteriorFrameRuntime.lastIndexOf(
  `if (${portalEnergyMotionEligibility})`,
  portalInteriorPhaseAdvanceIndex,
);
const portalInteriorPhaseGuardRuntime = extractBraceBlock(
  portalInteriorFrameRuntime,
  portalInteriorPhaseGuardIndex,
);
assert(
  portalInteriorPhaseGuardIndex > portalInteriorElapsedTimeIndex &&
    portalInteriorPhaseGuardRuntime.includes('MindPortalEnergy.advancePhase('),
  'Interior-only frames must not advance the shared energy phase',
);
const portalEnergyPulseIndex = portalInteriorFrameRuntime.indexOf('pulse = Math.max(');
const portalEnergyPulseGuardIndex = portalInteriorFrameRuntime.lastIndexOf(
  `if (${portalEnergyMotionEligibility})`,
  portalEnergyPulseIndex,
);
const portalEnergyPulseGuardRuntime = extractBraceBlock(
  portalInteriorFrameRuntime,
  portalEnergyPulseGuardIndex,
);
assert(
  portalEnergyPulseGuardIndex > portalInteriorPhaseGuardIndex &&
    portalEnergyPulseGuardRuntime.includes('pulse = Math.max(') &&
    portalEnergyPulseGuardRuntime.includes(
      'state.ripples = state.ripples.filter(',
    ),
  'Interior-only frames must neither compute a temporal pulse nor filter existing ripples',
);
const portalEnergyRippleApplicationIndex = portalInteriorFrameRuntime.indexOf(
  'state.ripples.forEach((ripple) => {',
);
const portalEnergyRippleGuardIndex = portalInteriorFrameRuntime.lastIndexOf(
  `if (${portalEnergyMotionEligibility})`,
  portalEnergyRippleApplicationIndex,
);
const portalEnergyRippleGuardRuntime = extractBraceBlock(
  portalInteriorFrameRuntime,
  portalEnergyRippleGuardIndex,
);
assert(
  portalEnergyRippleGuardIndex > portalEnergyPulseGuardIndex &&
    portalEnergyRippleGuardRuntime.includes('state.ripples.forEach((ripple) => {') &&
    portalEnergyRippleGuardRuntime.includes('sx += (dx / distance) * ring * 0.018;') &&
    portalEnergyRippleGuardRuntime.includes('sy += (dy / distance) * ring * 0.014;'),
  'Interior-only Balance base pixels must not apply ripple deformation',
);
const portalInteriorRendererGuardIndex = portalInteriorFrameRuntime.lastIndexOf(
  `if (${portalInteriorEligibility})`,
  portalInteriorRendererCallIndex,
);
const portalInteriorIntegrationRuntime = portalInteriorFrameRuntime.slice(
  portalInteriorRendererGuardIndex,
  portalInteriorFrameFinalizationIndex,
);
assert(
    portalInteriorRendererGuardIndex > portalInteriorBaseFrameIndex &&
    portalInteriorIntegrationRuntime.includes('const resolvedInteriorPalette = getMindPortalActivePalette(header);') &&
    portalInteriorIntegrationRuntime.includes('const interiorSplit = getMindPortalActivePaletteSplit(header);') &&
    portalInteriorIntegrationRuntime.includes('phase: motionAllowed') &&
    portalInteriorIntegrationRuntime.includes('state.portalInteriorMotionState.phaseByMode?.[state.portalInteriorMotionState.mode]') &&
    portalInteriorIntegrationRuntime.includes('leftColors: resolvedInteriorPalette.leftColors') &&
    portalInteriorIntegrationRuntime.includes('rightColors: resolvedInteriorPalette.rightColors') &&
    portalInteriorIntegrationRuntime.includes('split: interiorSplit') &&
    portalInteriorIntegrationRuntime.includes('transitionWidth: 0.36') &&
    !portalInteriorIntegrationRuntime.includes('currentBoundaryEdgesAt') &&
    !portalInteriorIntegrationRuntime.includes('boundary: {') &&
    !portalInteriorIntegrationRuntime.includes('leftXAt:') &&
    !portalInteriorIntegrationRuntime.includes('rightXAt:') &&
    !portalInteriorIntegrationRuntime.includes('featherPx:'),
  'The enabled Balance guard must pass a common translucent overlay contract without boundary masks',
);
const mindPortalEnergyStateRuntime = extractFunctionSource('ensureMindPortalEnergyState');
assert(
  mindPortalEnergyStateRuntime.includes("typeof PortalInteriorMotion !== 'undefined'") &&
    /portalInteriorMotionState:[\s\S]*?PortalInteriorMotion\.normalizeInteriorMotionState\(\s*\{[\s\S]*?PortalInteriorMotion\.DEFAULT_INTERIOR_MOTION_STATE,[\s\S]*?enabled:\s*true,[\s\S]*?mode:\s*'wandering-mist'/.test(
      mindPortalEnergyStateRuntime,
    ) &&
    /:\s*\{[\s\S]*?enabled:\s*true,[\s\S]*?mode:\s*'wandering-mist',[\s\S]*?settingsByMode:\s*\{},[\s\S]*?phaseByMode:\s*\{},[\s\S]*?\}/.test(
      mindPortalEnergyStateRuntime,
    ),
  'The standalone portal interior model must default to enabled wandering mist, with the same enabled fallback when optional globals are absent',
);
const portalInteriorControlSyncRuntime = extractFunctionSource(
  'syncPortalInteriorMotionControls',
);
assert(
    /data-portal-interior-motion-row[^>]*data-portal-interior-motion-enabled="true"/.test(
      rebuiltPortalLab,
    ) &&
    /<button(?=[^>]*data-portal-interior-motion-toggle)(?=[^>]*aria-pressed="true")[^>]*>BE<\/button>/.test(
      rebuiltPortalLab,
    ) &&
    /<select(?=[^>]*data-portal-interior-motion-mode-select)(?![^>]*\sdisabled(?:\s|>))[^>]*>/.test(
      rebuiltPortalLab,
    ) &&
    /<button(?=[^>]*data-portal-interior-motion-mode-reset)[^>]*>Aktív mód reset<\/button>/.test(
      rebuiltPortalLab,
    ) &&
    portalInteriorControlSyncRuntime.includes('data-portal-interior-motion-control-range') &&
    portalInteriorControlSyncRuntime.includes('PortalInteriorMotion.controlsForMode(activeMode).forEach') &&
    portalInteriorControlSyncRuntime.includes('PortalInteriorMotion.normalizeValue(meta, sourceValue)') &&
    portalInteriorControlSyncRuntime.includes('PortalInteriorMotion.normalizeRotationSpeed') &&
    portalInteriorControlSyncRuntime.includes('rotationToggle.setAttribute') &&
    portalInteriorControlSyncRuntime.includes('state.portalInteriorMotionState.rotationEnabled') &&
    portalInteriorControlSyncRuntime.includes('state.portalInteriorMotionState.rotationSpeed') &&
    portalInteriorControlSyncRuntime.includes('viewport.replaceChildren(fragment)') &&
    portalInteriorControlSyncRuntime.includes('[modeSelect, resetButton].forEach') &&
    portalInteriorControlSyncRuntime.includes('control.disabled = !enabled'),
  'Interior motion must start enabled in the test header and render dedicated Portal background-morph plus overlay rotation controls',
);
const portalInteriorInitRuntime = extractFunctionSource('initPortalInteriorMotionControls');
assert(
  portalInteriorInitRuntime.includes("row.querySelector('[data-portal-interior-motion-rotation-toggle]')") &&
    portalInteriorInitRuntime.includes("row.querySelector('[data-portal-interior-motion-rotation-speed-range]')") &&
    portalInteriorInitRuntime.includes("row.querySelector('[data-portal-interior-motion-rotation-speed-number]')") &&
    portalInteriorInitRuntime.includes('rotationEnabled: !state.portalInteriorMotionState.rotationEnabled') &&
    portalInteriorInitRuntime.includes('rotationSpeed: value') &&
    portalInteriorInitRuntime.includes('enabled: row.dataset.portalInteriorMotionEnabled !== \'false\''),
  'Interior initialization must wire the rotation toggle and speed controls into the dedicated state',
);
assert(
  /--mind-portal-color-a:[^;]+;[\s\S]*?--mind-portal-color-b:[^;]+;/.test(html) &&
    /linear-gradient\(90deg, var\(--mind-portal-color-a\) 0%, var\(--mind-portal-color-b\) 100%\)/.test(html),
  'The standalone portal must retain an exact static left-A/right-B CSS reference',
);
assert(
  html.includes('function initMindPortalEnergyControls()') &&
    html.includes('function setMindPortalEnergyMode(header, mode, userInitiated = false)') &&
    html.includes('function renderMindPortalEnergyControls(wrap, mode)') &&
    html.includes('function resetMindPortalEnergyMode(wrap)') &&
    html.includes('range.dataset.mindPortalEnergyRange = meta.key') &&
    html.includes('number.dataset.mindPortalEnergyNumber = meta.key') &&
    html.includes('Math.round((bounded - meta.min) / meta.step)') &&
    html.includes("if (number.value === '' || !Number.isFinite(Number(number.value))) return") &&
    html.includes('write(number, false)') &&
    html.includes('settingsByMode'),
  'The rebuilt portal must generate synchronized maximum-detail controls for only the active mode',
);
const mindPortalEnergyStaticStateRuntime = extractFunctionSource('ensureMindPortalEnergyState');
assert(
  /const settingsByMode = \{\s*static: MindPortalEnergy\.createModeSettings\('static'\),\s*\};/.test(
    mindPortalEnergyStaticStateRuntime,
  ) &&
    /const phaseByMode = \{\s*static: 0,\s*\};/.test(mindPortalEnergyStaticStateRuntime),
  'Static mode must own settings and phase so static testheader plus interior overlay can animate without being cleared',
);
assert(
  html.includes('function initMindPortalEnergyCanvas()') &&
    html.includes('function drawMindPortalEnergyFrame(') &&
    html.includes('MindPortalEnergy.sampleField') &&
    html.includes('MindPortalEnergy.samplePaletteColor') &&
    html.includes('MindPortalEnergy.advancePhase') &&
    html.includes("activeMode === 'static'") &&
    portalInteriorFrameRuntime.includes('settings.strength > 0') &&
    html.includes('IntersectionObserver') &&
    html.includes("window.matchMedia('(prefers-reduced-motion: reduce)')") &&
    html.includes('state.reducedMotion') &&
    html.includes('state.reducedMotionOverride') &&
    html.includes('setMindPortalEnergyMode(header, select.value, true)') &&
    html.includes("setMindPortalEnergyMode(header, select?.value || 'dual-tide', true)") &&
    !html.includes("setMindPortalEnergyMode(header, 'static');") &&
    html.includes("header.getAttribute('data-mind-portal-canvas-active') === 'true'"),
  'The rebuilt portal must use one static-aware/offscreen-aware canvas lifecycle and the pure field module',
);
assert(
  /\.mind-portal-energy-controls-scroll\s*\{[\s\S]*?max-height:\s*min\(30vh, 240px\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?-webkit-overflow-scrolling:\s*touch;[\s\S]*?touch-action:\s*pan-y;[\s\S]*?overscroll-behavior:\s*auto;[\s\S]*?\}/.test(html) &&
    html.includes('function initMindPortalControlScrollRouting()') &&
    html.includes("gesture.mode = absY > absX * 1.15 ? 'scroll' : 'slider'") &&
    html.includes('const before = viewport.scrollTop;') &&
    html.includes('viewport.scrollTop += deltaY;') &&
    html.includes('const consumed = viewport.scrollTop !== before;') &&
    html.includes("window.scrollBy({ top: deltaY, left: 0, behavior: 'auto' })"),
  'Vertical range gestures must scroll the internal active-controls viewport before falling through to page scroll',
);
assert(
  /\.mind-portal-energy-row input\[type="number"\]\s*\{[\s\S]*?touch-action:\s*pan-y;[\s\S]*?\}/.test(html) &&
    /\[data-mind-portal-mode-reset\],[\s\S]*?\[data-portal-transition-mode-reset\]\s*\{[\s\S]*?touch-action:\s*manipulation;[\s\S]*?\}/.test(html),
  'Manual inputs and reset controls must preserve vertical scrolling throughout every Portal control panel',
);
assert.strictEqual(
  (rebuiltPortalLab.match(/data-portal-collapsible-panel/g) || []).length,
  7,
  'Every standalone test-portal control container below the header must be a collapsible panel',
);
assert.strictEqual(
  (rebuiltPortalLab.match(/data-portal-panel-toggle/g) || []).length,
  7,
  'Every collapsible Portal panel must expose its own chevron toggle button',
);
assert.strictEqual(
  (rebuiltPortalLab.match(/data-portal-panel-body/g) || []).length,
  7,
  'Every collapsible Portal panel must wrap its editable content in a collapsible body',
);
assert(
  rebuiltPortalLab.includes('data-default-collapsed="false"') &&
    (rebuiltPortalLab.match(/data-default-collapsed="true"/g) || []).length >= 4,
  'Portal controls must keep the short color/opacity panels visible while default-collapsing advanced panels',
);
assert(
  /\.mind-portal-panel-toggle\s*\{[\s\S]*?touch-action:\s*manipulation;[\s\S]*?\}/.test(html) &&
    /\[data-portal-panel-collapsed="true"\]\s*\[data-portal-panel-body\]\s*\{[\s\S]*?display:\s*none;/.test(html),
  'Collapsible Portal panels must use a chevron button and remove collapsed body height from the page',
);
assert(
  html.includes('function initPortalControlPanelCollapse()') &&
    html.includes('function setPortalControlPanelCollapsed(panel, collapsed)') &&
    html.includes("button.setAttribute('aria-expanded', collapsed ? 'false' : 'true')") &&
    html.includes('initPortalControlPanelCollapse();'),
  'Portal panel collapse runtime must bind chevron buttons and keep aria-expanded synchronized',
);

const colorLabPerfScheduleRuntime = extractFunctionSource('scheduleMindPortalEnergyFrame');
const colorLabPerfWakeRuntime = extractFunctionSource('wakeMindPortalEnergyFrame');
const colorLabPerfMessageCanRenderRuntime = extractFunctionSource('portalMessageFieldCanRender');
const colorLabPerfInitCanvasRuntime = extractFunctionSource('initMindPortalEnergyCanvas');
assert(
  /\.screen-column\s*\{[\s\S]*?content-visibility:\s*auto;[\s\S]*?contain:\s*layout paint style;[\s\S]*?contain-intrinsic-size:\s*var\(--screen-w\) calc\(var\(--screen-h\) \+ 28px\);[\s\S]*?\}/.test(html) &&
    /\.phone-screen\s*\{[\s\S]*?contain:\s*layout paint style;[\s\S]*?\}/.test(html) &&
    /\.palette-area,\s*[\s\S]*?\.common-mode-scale-lab,\s*[\s\S]*?\.logo-editor-section\s*\{[\s\S]*?content-visibility:\s*auto;[\s\S]*?contain:\s*layout paint style;[\s\S]*?\}/.test(html),
  'Color Lab must use browser-level lazy layout/paint containment for offscreen screen columns, phone surfaces, palettes, and scale/logo labs',
);
assert(
  html.includes('const colorLabScrollRenderState = {') &&
    html.includes('function isColorLabHeavyRenderSuspended()') &&
    html.includes('function initColorLabScrollRenderSuspension()') &&
    html.includes("zoomViewport.addEventListener('scroll'") &&
    html.includes('setColorLabHeavyRenderSuspended(true)') &&
    html.includes('colorLabScrollRenderState.resumeDelayMs') &&
    html.includes('resumeColorLabHeavyRenderFrames();') &&
    html.includes('initColorLabScrollRenderSuspension();'),
  'Color Lab must suspend heavy render loops while the main scroll viewport is moving, then resume after a short idle delay',
);
assert(
  colorLabPerfScheduleRuntime.includes('if (!canRenderMindPortalEnergyFrame(header, state)) return;') &&
    colorLabPerfScheduleRuntime.includes('const keepRunning = drawMindPortalEnergyFrame(header, canvas, ctx, state, now);') &&
    colorLabPerfScheduleRuntime.includes('if (keepRunning) scheduleMindPortalEnergyFrame(header, state);') &&
    !/drawMindPortalEnergyFrame\(header, canvas, ctx, state, now\);\s*scheduleMindPortalEnergyFrame\(header, state\);/.test(
      colorLabPerfScheduleRuntime,
    ) &&
    colorLabPerfWakeRuntime.includes('if (!canRenderMindPortalEnergyFrame(header, state)) return;') &&
    colorLabPerfMessageCanRenderRuntime.includes('isColorLabHeavyRenderSuspended()') &&
    colorLabPerfInitCanvasRuntime.includes('colorLabRenderObserverOptions()') &&
    colorLabPerfInitCanvasRuntime.includes('if (state.visible) wakeMindPortalEnergyFrame(header, state);'),
  'Portal canvas loops must be lazy: no unconditional RAF rescheduling while offscreen, hidden, or scroll-suspended',
);

function extractFunctionSource(name) {
  const start = html.indexOf(`function ${name}(`);
  assert(start >= 0, `Missing function source for touch contract: ${name}`);
  const bodyStart = html.indexOf('{', start);
  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let index = bodyStart; index < html.length; index += 1) {
    const char = html[index];
    if (quote) {
      if (escaped) escaped = false;
      else if (char === '\\') escaped = true;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === '"' || char === "'" || char === '`') {
      quote = char;
      continue;
    }
    if (char === '{') depth += 1;
    if (char === '}' && --depth === 0) return html.slice(start, index + 1);
  }
  throw new Error(`Unclosed function source: ${name}`);
}

function extractBraceBlock(source, start) {
  assert(start >= 0, 'Missing guarded source block');
  const bodyStart = source.indexOf('{', start);
  assert(bodyStart >= 0, 'Missing guarded source block body');
  let depth = 0;
  let quote = null;
  let escaped = false;
  for (let index = bodyStart; index < source.length; index += 1) {
    const char = source[index];
    if (quote) {
      if (escaped) escaped = false;
      else if (char === '\\') escaped = true;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === '"' || char === "'" || char === '`') {
      quote = char;
      continue;
    }
    if (char === '{') depth += 1;
    if (char === '}' && --depth === 0) return source.slice(start, index + 1);
  }
  throw new Error('Unclosed guarded source block');
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

assert.strictEqual(
  sha256(extractFunctionSource('getCommonHeaderMindPortalPoint')),
  'b4a8ab273e7ec68996e0046f1cc4beaddad712d654ab409864001fd281cc4c69',
  'Portal point mapping changed despite the accepted touch contract',
);
assert.strictEqual(
  sha256(extractFunctionSource('spawnCommonHeaderMindPortalTrailPoint')),
  'e7a3714c6bce21a4e255452dc23e1d01b5e00978dbbee5c5aee43189f96c06e8',
  'Portal trail spawning changed despite the accepted touch contract',
);
assert.strictEqual(
  sha256(extractFunctionSource('initCommonHeaderMindPortalTouch')),
  '14ba0e72d512e6da470106fb76a1fa3f949e9c358cf385f091c11bfab53eca0c',
  'Portal pointer/release behavior changed despite the accepted touch contract',
);
const touchCssStart = html.indexOf(
  '    .common-header-mode[data-common-header-mode="mind"] .common-header-card[data-mind-portal-touch="true"]',
);
const touchCssEnd = html.indexOf('    @keyframes mindHeaderValueWater', touchCssStart);
assert.strictEqual(
  sha256(html.slice(touchCssStart, touchCssEnd)),
  'fb8a52694faf59a608b629b8982de81a53f8495b5ca9c49e40b796485ef66913',
  'Portal touch/trail CSS changed despite the accepted touch contract',
);

const budgetGradientCategoryPalette = html.match(
  /<section class="budget-gradient-category-palette" data-budget-gradient-category-palette[^>]*>[\s\S]*?<\/section>/,
)?.[0];
assert(budgetGradientCategoryPalette, 'Budget gradient lab must expose its category palette');
const budgetGradientHeaderLab = html.match(
  /<section class="budget-gradient-header-scale-lab common-mode-scale-lab" id="budgetGradientHeaderScaleLab"[\s\S]*?<\/section>/,
)?.[0];
assert(budgetGradientHeaderLab, 'Budget gradient lab must be a dedicated scale lab, separate from the Traffic scale');
assert(
  /<section class="balance-header-scale-lab common-mode-scale-lab" id="mindHeaderScaleLab"[\s\S]*?<\/section>\s*<div class="mind-portal-test-header-wrap" data-mind-portal-test-header>\s*<section class="budget-gradient-header-scale-lab common-mode-scale-lab" id="budgetGradientHeaderScaleLab"[\s\S]*?<\/section>\s*<section class="budget-gradient-category-palette" data-budget-gradient-category-palette[\s\S]*?<\/section>\s*<div class="mind-portal-test-row" data-portal-message-row>/.test(html),
  'The dedicated scales and centred category palette must be immediately above the Test Header, while Traffic remains outside that Header wrapper',
);
assert(
  !mindScaleLab.includes('data-budget-gradient-scale-slot') &&
    !mindScaleLab.includes('data-budget-gradient-target-slot'),
  'The existing Traffic scale must not gain budget-gradient binding targets',
);
assert(
  (budgetGradientHeaderLab.match(/data-budget-gradient-auto-stop/g) || []).length === 10 &&
    (budgetGradientHeaderLab.match(/data-budget-gradient-target-slot/g) || []).length === 1 &&
    (budgetGradientHeaderLab.match(/data-window-drag-handle/g) || []).length === 1 &&
    !budgetGradientHeaderLab.includes('data-budget-gradient-window-slider') &&
    /id="budgetGradientWindowInput"[^>]*value="28"/.test(budgetGradientHeaderLab) &&
    !budgetGradientHeaderLab.includes('data-budget-gradient-scale-slot'),
  'The dedicated colour scale must render ten automatic white-to-B bands with one right-edge target and one movable-width window handle',
);
const budgetGradientConstantScaleCss = html.match(
  /\.budget-gradient-colour-track::before\s*\{([^}]*)\}/,
)?.[1] || '';
assert(
  /inset:\s*0;/.test(budgetGradientConstantScaleCss) &&
    /linear-gradient\(90deg, #ffffff 0%, rgba\(255,255,255,0\) 100%\),\s*var\(--budget-gradient-scale-surface\);/.test(budgetGradientConstantScaleCss) &&
    !budgetGradientConstantScaleCss.includes('--budget-gradient-window-width-pct'),
  'The full colour scale must stay constant from white to the selected B surface; the movable window must not change its colour distribution',
);
assert(
  /\.budget-gradient-colour-track \.balance-window\s*\{[\s\S]*?left:\s*calc\(var\(--budget-gradient-window-left-pct\) \* 1%\);[\s\S]*?width:\s*calc\(var\(--budget-gradient-window-width-pct\) \* 1%\);[\s\S]*?\}/.test(html),
  'The visible handle must be a movable window whose width is controlled separately from the constant colour scale',
);
assert(
  /<div class="balance-window budget-gradient-window" data-reactive-window data-window-drag-handle[^>]*>\s*<span class="budget-gradient-window-grip" aria-hidden="true"><\/span>\s*<\/div>/.test(budgetGradientHeaderLab) &&
    /\.budget-gradient-window\s*\{[\s\S]*?z-index:\s*5;[\s\S]*?cursor:\s*grab;[\s\S]*?\}/.test(html) &&
    /\.budget-gradient-window-grip\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*50%;[\s\S]*?width:\s*12px;[\s\S]*?height:\s*22px;[\s\S]*?background:\s*#0f172a;[\s\S]*?\}/.test(html),
  'The movable Budget window must expose a high-contrast centre grip inside its actual movable bounds',
);
const budgetGradientTargetSlotCss = html.match(
  /\.budget-gradient-target-slot\s*\{([^}]*)\}/,
)?.[1] || '';
assert(
  /z-index:\s*6;/.test(budgetGradientTargetSlotCss),
  'The fixed right-edge category target must remain tappable above a movable window that reaches the right edge',
);
const rootCss = html.match(/:root\s*\{([\s\S]*?)\n\s*\}/)?.[1] || '';
const budgetGradientHeaderLabCss = html.match(
  /#budgetGradientHeaderScaleLab\s*\{([^}]*)\}/,
)?.[1] || '';
const budgetGradientColourTrackCss = html.match(
  /\.budget-gradient-colour-track\s*\{([^}]*)\}/,
)?.[1] || '';
assert(
  /--budget-gradient-window-left-pct:\s*36;/.test(rootCss) &&
    /--budget-gradient-window-width-pct:\s*28;/.test(rootCss) &&
    !budgetGradientHeaderLabCss.includes('--budget-gradient-window-left-pct') &&
    !budgetGradientHeaderLabCss.includes('--budget-gradient-window-width-pct') &&
    /touch-action:\s*none;/.test(budgetGradientColourTrackCss),
  'The Budget window must inherit the shared controller-owned root state and retain the same no-pan touch contract as the working Traffic scale',
);
assert(
  /\[data-mind-portal-test-header\]\s*>\s*\.budget-gradient-header-scale-lab,\s*\[data-mind-portal-test-header\]\s*>\s*\.budget-gradient-category-palette\s*\{[\s\S]*?margin-left:\s*auto;[\s\S]*?margin-right:\s*auto;[\s\S]*?\}/.test(html),
  'The dedicated scales and category palette must share the Test Header centre line',
);
assert(
  /#budgetGradientHeaderScaleLab\s*\{[\s\S]*?content-visibility:\s*visible;[\s\S]*?\}/.test(html),
  'The dedicated scale immediately above the Test Header must opt out of deferred painting',
);
assert.strictEqual(
  (budgetGradientCategoryPalette.match(/data-budget-gradient-category-slot=/g) || []).length,
  21,
  'Budget gradient lab must expose all 21 canonical category-gradient slots',
);
for (let slot = 0; slot <= 20; slot += 1) {
  assert(
    budgetGradientCategoryPalette.includes(`data-budget-gradient-category-slot="${slot}"`) &&
      budgetGradientCategoryPalette.includes(`--slot-gradient-${slot}`),
    `Budget gradient category slot ${slot} must preserve its canonical full A/B gradient token`,
  );
}
assert(
  html.includes('const budgetGradientHeaderScaleState = {') &&
    html.includes('function initBudgetGradientHeaderScaleLab()') &&
    html.includes('function initBudgetGradientCategoryBindings()') &&
    html.includes('function applyBudgetGradientHeaderPresentation()'),
  'Budget category binding must own the new dedicated scale while reusing the established input and opacity helpers',
);
const budgetGradientWindowState = html.match(
  /const budgetGradientHeaderScaleState\s*=\s*\{([\s\S]*?)\n\s*\};/,
)?.[1] || '';
const reactiveScaleStateWriter = extractFunctionSource('setReactiveScaleState');
assert(
  /cssPrefix:\s*'budget-gradient'/.test(budgetGradientWindowState) &&
    !budgetGradientWindowState.includes("cssPrefix: 'budget-gradient-window'") &&
    reactiveScaleStateWriter.includes('`--${state.cssPrefix}-window-left-pct`') &&
    reactiveScaleStateWriter.includes('`--${state.cssPrefix}-window-width-pct`'),
  'The Budget scale state prefix must generate the exact CSS variable names read by its movable window, without a duplicated window segment',
);
const budgetGradientPresentationRuntime = extractFunctionSource('applyBudgetGradientHeaderPresentation');
const budgetGradientWindowSignatureRuntime = extractFunctionSource('buildBudgetGradientWindowSignature');
const budgetGradientScaleSamplerRuntime = extractFunctionSource('sampleBudgetGradientScaleColor');
assert(
  budgetGradientPresentationRuntime.includes('budgetGradientHeaderScaleState.window') &&
    budgetGradientPresentationRuntime.includes('budgetGradientHeaderScaleState.center - (windowWidth / 2)') &&
    budgetGradientPresentationRuntime.includes('buildBudgetGradientWindowSignature(surface, windowLeft, windowRight)') &&
    budgetGradientPresentationRuntime.includes("applyMindPortalTestHeaderColors('signature-budget-gradient', signature.a, signature.b") &&
    budgetGradientPresentationRuntime.includes('fieldPercent: budgetGradientHeaderScaleState.center') &&
    !budgetGradientPresentationRuntime.includes('--budget-gradient-header-surface') &&
    !budgetGradientPresentationRuntime.includes('data-budget-gradient-active') &&
    !budgetGradientPresentationRuntime.includes('balanceScaleState') &&
    budgetGradientWindowSignatureRuntime.includes('sampleBudgetGradientScaleColor(stops, windowLeft)') &&
    budgetGradientWindowSignatureRuntime.includes('sampleBudgetGradientScaleColor(stops, windowRight)') &&
    budgetGradientScaleSamplerRuntime.includes('mixColor(\'#ffffff\', sampleBudgetGradientStops(stops, boundedPosition), boundedPosition / 100)'),
  'Budget Header presentation must sample the selected scale at the movable window edges, then publish the distinct A/B pair through the shared Portal palette owner',
);
assert(
  !html.includes('budget-gradient-header-surface') &&
    !extractFunctionSource('applyMindPortalTestHeaderColors').includes('clearBudgetGradientHeaderPresentation'),
  'Budget must not cover the shared Portal animation with a separate static Header surface',
);
assert(
  /function applyMindPortalTestHeaderColors\(source, a, b, options = \{\}\) \{[\s\S]*?data-mind-portal-test-source', source/.test(html),
  'Budget and all other Portal colour controls must publish through the same last-writer Header owner',
);
const budgetGradientBindingRuntime = extractFunctionSource('initBudgetGradientCategoryBindings');
assert(
  budgetGradientBindingRuntime.includes("document.querySelector('[data-budget-gradient-target-slot]')") &&
    budgetGradientBindingRuntime.includes("targetSlot?.addEventListener('click'") &&
    !budgetGradientBindingRuntime.includes('data-budget-gradient-scale-slot'),
  'A selected category must bind only through the dedicated right-edge target, never through the ten display bands',
);
const budgetGradientLabRuntime = extractFunctionSource('initBudgetGradientHeaderScaleLab');
assert(
  budgetGradientLabRuntime.includes("document.getElementById('budgetGradientWindowInput')") &&
    budgetGradientLabRuntime.includes("document.querySelector('[data-budget-gradient-colour-track]')") &&
    budgetGradientLabRuntime.includes('initReactiveScaleController(budgetGradientHeaderScaleState, colourTrack)') &&
    budgetGradientLabRuntime.includes("document.querySelector('[data-budget-gradient-opacity-track]')") &&
    budgetGradientLabRuntime.includes('initModeOpacityScaleController(commonHeaderOpacityStates.mind'),
  'The new movable window must reuse the established reactive scale controller so every drag synchronously updates the Header, while opacity continues to use the Mind-opacity mechanism',
);

const strictMotherChildPanel =
  commonHeaderStage2MotherChild.match(
    /<section class="common-balance-mother-child-panel"[\s\S]*?<\/section>/,
  )?.[0] || '';
const strictMotherChildStyles =
  /\.common-balance-mother-child-parent-card\s*\{[\s\S]*?border:\s*1px solid rgba\(239,63,95,\.78\);[\s\S]*?box-shadow:[\s\S]*?rgba\(239,63,95,\.18\);/.test(
    html,
  ) &&
  /\.common-balance-mother-child-layer\s*\{[\s\S]*?top:\s*calc\(96px \+ \(var\(--common-header-stage1-h\) - 114px\) \+ 12px\);[\s\S]*?overflow-y:\s*auto;[\s\S]*?pointer-events:\s*auto;/.test(
    html,
  ) &&
  /\.common-balance-mother-child-panel\s*\{[\s\S]*?border-radius:\s*17px;[\s\S]*?background:\s*rgba\(255,255,255,\.48\);[\s\S]*?backdrop-filter:\s*blur\(14px\) saturate\(1\.08\);/.test(
    html,
  ) &&
  /\.common-balance-mother-child-progress b\s*\{[\s\S]*?width:\s*var\(--balance-child-share, 43%\);/.test(
    html,
  );
const strictMotherChildScreen =
  commonHeaderStage2MotherChild.includes('data-screen="alt-common-header-stage2-mother-child"') &&
  /class="fastinfo-chart-card expense common-balance-mother-child-parent-card"[^>]*data-balance-mother-child-parent="largest-expense"[^>]*aria-current="true"/.test(
    commonHeaderStage2MotherChild,
  ) &&
  commonHeaderStage2MotherChild.includes('data-balance-mother-child-child="largest-expense"') &&
  commonHeaderStage2MotherChild.includes('class="common-balance-mother-child-layer"') &&
  strictMotherChildPanel.includes('Albérlet') &&
  strictMotherChildPanel.includes('-176 370 Ft') &&
  strictMotherChildPanel.includes('A havi kiadás 43%-a') &&
  strictMotherChildPanel.includes('Előző hónaphoz: +16%') &&
  strictMotherChildPanel.includes('Következő ismétlődő: 2026.08.01.') &&
  strictMotherChildPanel.includes('12 havi alakulás') &&
  strictMotherChildPanel.includes('class="common-balance-mother-child-trend"') &&
  !strictMotherChildPanel.includes('<article') &&
  strictMotherChildStyles &&
  !commonHeaderStage2.includes('data-balance-mother-child-child');
assert(
  strictMotherChildScreen,
  'B3M must render the strict largest-expense mother-child drilldown',
);

console.log('Color lab static checks passed');
