const fs = require('fs');
const path = require('path');
const assert = require('assert');

const htmlPath = path.join(__dirname, 'color_lab.html');
assert(fs.existsSync(htmlPath), 'Missing docs/prototypes/color_lab.html');
const html = fs.readFileSync(htmlPath, 'utf8');
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
  '--spendee-logo-size: 79.5px',
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
  '--bottom-nav-h: 80px',
  '--fab-size: 66px',
  'data-screen="home"',
  'data-screen="category-sheet"',
  'data-screen="vendor-sheet"',
  'data-screen="add-transaction-sheet"',
  'id="legacyColorPalette"',
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
  'function handlePinchMove',
  'function handleWheelZoom',
  'data-color-target="app-background"',
  'data-color-target="sheet-background"',
  'data-color-target="add-transaction-sheet-background"',
  'data-color-target="header-card"',
  'data-color-target="magnet-strip"',
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
  'data-color-target="header-app-title-text"',
  'data-color-target="header-balance-label-text"',
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
  'id="textColorPalette"',
  'data-palette-group="keyboardtest-source"',
  'data-palette-role="text"',
  'keyboardtest/lib/main.dart',
  '#243633',
  '#cdd6f4',
  '#6c7086',
  '#1e1e2e',
  '--local-text-color',
  'function labelPaletteSlots',
  'dataset.slot = slot',
  '.color-swatch:not([data-selected-source-slot]):not([data-fixed-slot])',
  'content: attr(data-slot)',
  'stats-threshold-sheet-background',
  'CategoryColorManager',
  'CategoryIconManager',
  'data-section="legacy-design"',
  'data-section="alternative-design"',
  'data-section-row="stats-menu"',
  'data-section-row="main-menu"',
  'data-section-row="common-header-dashboard"',
  'data-screen="alt-stats-expense-dashboard"',
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
  'data-stats-tab="expense"',
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
  'class="stats-score-slider"',
  'data-score-slider="expense-magnet"',
  'class="stats-discussion-placeholder"',
  'id="legacyColorPalette"',
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
  'function buildCommonStage1AvatarStrip',
  'function buildCommonMindScoreGraphContent',
  'function buildCommonMindHeatmapContent',
  'function buildMindHeatmapYearGrid',
  'function buildMindHeatmapVariantGallery',
  'function syncCommonHeaderMindHeatmapLayer',
  'function buildCommonBudgetCategoryPieContent',
  'function syncCommonHeaderBudgetPieLayer',
  'function initMindHeatmapScreens',
  'function syncCommonHeaderStage2Stage1Layer',
  'common-budget-stage1-layer',
  'function buildCommonHeaderHandle',
  'data-focus-mode-stage1="budget-glossy-extended-info"',
  'data-focus-mode-stage1="balance-reserve-summary"',
  'data-focus-mode-stage2="balance-income-expense"',
  'common-balance-reserve-progress',
  'common-balance-ratio-row',
  'common-balance-ratio-metrics',
  'common-balance-stage1-card-grid',
  'data-stats-active-type="income"',
  'Bevétel vs kiadás',
  'Fedezi a kiadást',
  'Kevés bevétel',
  'Nullszaldó',
  'class="common-stage1-avatar-strip"',
  'data-focus-mode-stage1="mind-score-graph"',
  'common-score-svg-expanded',
  'data-reference="/storage/emulated/0/spendee/scorechart.png"',
  'common-score-axis-label',
  'common-score-month-label',
  'common-score-endpoint',
  'common-stage2-heatmap-layer',
  'common-stage2-heatmap-panel',
  'data-stage2-extra="mind-heatmap"',
  'data-heatmap-panel="score-glass"',
  'data-heatmap-header="compact-no-score"',
  'data-stage2-scrollable',
  'data-stage2-extra="budget-category-pie"',
  'common-budget-pie-stage2-layer',
  'data-budget-pie-scrollable="true"',
  'CategoryDonutChart',
  'stats-category-donut',
  'data-screen="alt-common-header-mind-heatmap-full"',
  'data-screen-height="content"',
  'data-mind-heatmap-render-target',
  'data-mind-heatmap-variant-target',
  'data-heatmap-variant-gallery',
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
  'data-score-active-type="expense"',
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
  'id="previousSlotPaletteRow"',
  'id="originalSlotPaletteRow"',
  'id="fabBlueGradientPaletteRow"',
  'id="spendeeLogoEditor"',
  'data-logo-editor',
  'id="spendeeLogoEditorSvg"',
  'path.dataset.logoEditorPath = path.id;',
  "path.dataset.colorTarget = 'logo-path';",
  'data-palette-group="alternative-app-shades"',
  'data-palette-group="alternative-colour-slots"',
  'data-palette-group="previous-colour-slots"',
  'data-palette-group="original-colour-slots"',
  'data-palette-group="fab-blue-gradients"',
  'data-reference="/storage/emulated/0/spendee/dashboard.png"',
  'data-reference="/storage/emulated/0/spendee/fastinfo.png"',
  'data-logo-source="/storage/emulated/0/spendee/final_spendeevector.svg"',
  'spendee_final_spendeevector.svg?v=20260712-path-logo-v2',
  'spendee-dashboard-screen',
  'spendee-brand-lockup',
  'spendee-logo',
  'spendee-logo-live-preview',
  'data-logo-live-preview',
  'spendee-title">spendee',
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
  '--previous-slot-gradient-0:',
  '--previous-slot-gradient-20:',
  '--original-slot-gradient-0:',
  '--original-slot-gradient-20:',
  '--fab-blue-gradient-0:',
  '--fab-blue-gradient-19:',
  'data-fab-base="#06b6d4"',
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

const screenCount = (html.match(/class="phone-screen/g) || []).length;
assert.strictEqual(
  screenCount,
  23,
  'Expected four legacy phone screens, the lower statistics dashboard, the three B-row common-header dashboard stages, the lower home, active/no-limit fastinfo stage1 screens, fastinfo stage2, three backheader prototypes including limit amount tap-edit, selector/editor/add screens, plus vendor editor and icon selector',
);

const legacySection = html.match(
  /<section class="screens" data-section="legacy-design"[^>]*>[\s\S]*?<\/section>\s*<section class="palette-area" id="legacyColorPalette"/,
)?.[0];
assert(legacySection, 'Missing explicit legacy design section above the old palette');

const alternativeSection = html.match(
  /<section class="alternative-design" id="alternativeDesignReview" data-section="alternative-design">[\s\S]*?<section class="palette-area structured-palette" id="alternativePalette"/,
)?.[0];
assert(
  alternativeSection,
  'Missing alternative design section with duplicated menus above its structured palette',
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
    /id="balanceWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="68"[\s\S]*?step="1"/.test(mindScaleLab) &&
    /id="limitsWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="68"[\s\S]*?step="1"/.test(balanceScaleLab) &&
    /id="coolWindowInput"[\s\S]*?type="number"[\s\S]*?min="10"[\s\S]*?max="68"[\s\S]*?step="1"/.test(budgetScaleLab) &&
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
    /function initReactiveScaleController\(state, track\) \{[\s\S]*?const windowInput = document\.getElementById\(state\.inputId\);[\s\S]*?handleWindowInput[\s\S]*?setReactiveScaleState\(state, state\.center, numericWidth\);/.test(html) &&
    /function initReactiveScaleController\(state, track\) \{[\s\S]*?windowHandle\.addEventListener\('pointerdown'/.test(html),
  'Reactive colored scale controller must initialize draggable window bodies plus numeric width inputs',
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
  /function initReactiveScaleController\(state, track\) \{[\s\S]*?const windowHandle = track\.querySelector\('\[data-window-drag-handle\]'\);[\s\S]*?track\.addEventListener\('pointerdown'[\s\S]*?setReactiveScaleState\(state, percentFromEvent\(event\), state\.window\);[\s\S]*?setReactiveScaleState\(state, state\.center, numericWidth\);/.test(
    html,
  ),
  'Reactive colored scale controller must jump on track tap, drag the center/window position, and let the user type only the window width into the same clamped state path',
);
const reactiveScaleControllerBlock = html.match(
  /function initReactiveScaleController\(state, track\) \{[\s\S]*?\n    \}/,
)?.[0];
assert(reactiveScaleControllerBlock, 'Missing draggable reactive scale controller block');
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
  'data-screen="alt-stats-expense-dashboard"',
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
  alternativeSection.indexOf('data-screen="alt-stats-expense-dashboard"') <
    alternativeSection.indexOf('data-screen="alt-home"') &&
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
  'The lower screens must be ordered as stats row, main screen row, active stage 1, no-limit stage 1, stage 2, backheader reference, higher backheader, limit amount tap-edit, category selector, vendor selector, vendor editor, add category, icon selector, then add transaction',
);

const lowerStatsExpenseScreen = alternativeSection.match(
  /<section class="phone-screen spendee-dashboard-screen spendee-stats-screen" data-screen="alt-stats-expense-dashboard"[\s\S]*?<div class="screen-title">A1/,
)?.[0];
assert(lowerStatsExpenseScreen, 'Missing lower stats expense dashboard screen above the main-menu row');
assert(
  html.indexOf('data-section-row="stats-menu"') < html.indexOf('data-section-row="main-menu"') &&
    html.indexOf('data-screen="alt-stats-expense-dashboard"') < html.indexOf('data-screen="alt-home"'),
  'Stats row must be inserted above the existing main-menu row, making the main-menu row second',
);
assert(
  lowerStatsExpenseScreen.includes('data-stats-tab="expense"') &&
    lowerStatsExpenseScreen.includes('class="app-header spendee-header stats-score-header"') &&
    lowerStatsExpenseScreen.includes('<div class="spendee-balance-label">Score</div>') &&
    lowerStatsExpenseScreen.includes('class="header-balance stats-score-value"') &&
    lowerStatsExpenseScreen.includes('82/100') &&
    lowerStatsExpenseScreen.includes('class="stats-score-slider"') &&
    lowerStatsExpenseScreen.includes('data-score-slider="expense-magnet"') &&
    lowerStatsExpenseScreen.includes('data-color-target="header-card"') &&
    lowerStatsExpenseScreen.includes('data-color-var="--spendee-header-bg"') &&
    !lowerStatsExpenseScreen.includes('class="magnet-strip"'),
  'Stats expense dashboard must replace Balance with Score, use whole-card header coloring, and model the magnet score as an in-card slider',
);
assert(
  lowerStatsExpenseScreen.includes('class="type-pill income-type-pill"') &&
    lowerStatsExpenseScreen.includes('class="type-pill active expense-type-pill"') &&
    lowerStatsExpenseScreen.includes('Bevétel') &&
    lowerStatsExpenseScreen.includes('Kiadás') &&
    lowerStatsExpenseScreen.includes('class="bottom-nav"') &&
    lowerStatsExpenseScreen.includes('<span>Stats</span>') &&
    lowerStatsExpenseScreen.includes('class="nav-item active"') &&
    lowerStatsExpenseScreen.includes('class="stats-discussion-placeholder"'),
  'Stats first screen must include income/expense tabs, active Stats bottom-nav item, and only a minimal placeholder for the undecided content',
);
assert(
  /\.alternative-design > \.screens \{[\s\S]*?flex-direction:\s*column;/.test(html) &&
    /\.stats-row,\s*\n\s*\.main-menu-row,\s*\n\s*\.common-header-row \{[\s\S]*?display:\s*flex;[\s\S]*?gap:\s*28px;/.test(html) &&
    /\.stats-score-slider \{[\s\S]*?position:\s*absolute;[\s\S]*?left:\s*18px;[\s\S]*?right:\s*18px;[\s\S]*?bottom:\s*16px;/.test(html),
  'Stats row and slider CSS must keep stats as a real row above the main-menu row and put the score slider inside the header card',
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
  'Common-header focus modes must be ordered as balance row + slider, budget row + slider, mind row + slider',
);
assert.strictEqual(
  (commonHeaderModeArea.match(/data-common-header-mode="(?:balance|budget|mind)"/g) || []).length,
  3,
  'Common-header mode area must render exactly three mode rows: balance, budget, and mind',
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
  html.indexOf('function buildCommonMindScoreGraphContent'),
);
const stage1AvatarFunction = html.slice(
  html.indexOf('function buildCommonStage1AvatarStrip'),
  html.indexOf('function buildCommonBudgetGlossyExtendedInfo'),
);
assert(
  budgetGlossyFunction.includes('data-focus-mode-stage1="budget-glossy-extended-info"') &&
    budgetGlossyFunction.includes('common-focus-budget-stack') &&
    budgetGlossyFunction.includes('common-focus-layer common-budget-stage1-layer') &&
    budgetGlossyFunction.includes('common-budget-bottom-progress') &&
    budgetGlossyFunction.includes('common-focus-budget-meta') &&
    budgetGlossyFunction.includes('Elköltve 51%') &&
    budgetGlossyFunction.includes('Maradt 61 760 Ft') &&
    budgetGlossyFunction.includes('category-limit-partition-bar') &&
    budgetGlossyFunction.includes('buildCommonStage1AvatarStrip()') &&
    budgetGlossyFunction.includes('data-focus-budget-interaction="longpress-vertical-joystick"') &&
    !budgetGlossyFunction.includes('common-focus-budget-title') &&
    !budgetGlossyFunction.includes('common-focus-budget-value') &&
    !budgetGlossyFunction.includes('63 240 / 125 000 Ft'),
  'C2 budget stage1 must keep the glossy extended-info container, but anchor spent/remaining labels and the partition progress bar together in a bottom progress block without duplicating Budget title or x/y amount',
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
  /\.common-budget-avatar-area\s*\{[\s\S]*?top:\s*4px;[\s\S]*?bottom:\s*38px;[\s\S]*?overflow:\s*visible;[\s\S]*?\}/.test(html) &&
    /\.common-budget-bottom-progress \.common-focus-partition\s*\{[\s\S]*?height:\s*10px;[\s\S]*?margin-top:\s*0;[\s\S]*?background:\s*rgba\(255,255,255,0\);[\s\S]*?box-shadow:\s*none;[\s\S]*?\}/.test(html),
  'C2/C3 budget avatar area must give the center progress circle breathing room and the partition track/padding must have zero-opacity visual background',
);
assert(
  budgetGlossyFunction.indexOf('buildCommonStage1AvatarStrip()') <
    budgetGlossyFunction.indexOf('common-budget-bottom-progress') &&
    budgetGlossyFunction.indexOf('common-focus-budget-meta') <
      budgetGlossyFunction.indexOf('category-limit-partition-bar'),
  'C2 budget avatar/content area must sit above the bottom-anchored label + partition progress block',
);
const mindGraphFunction = html.slice(
  html.indexOf('function buildCommonMindScoreGraphContent'),
  html.indexOf('function ensureCommonHeaderHandle'),
);
assert(
  [
    'data-focus-mode-stage1="mind-score-graph"',
    'data-score-active-type="expense"',
    'data-reference="/storage/emulated/0/spendee/scorechart.png"',
    'lib/features/stats/widgets/stats_fast_info_graph.dart',
    'Kiadási score trend',
    'common-score-axis-label',
    '>100<',
    '>50<',
    '>0<',
    'common-score-month-label',
    'máj.',
    'jan.',
    'common-score-path bad',
    'common-score-path neutral',
    'common-score-path good',
    'common-score-endpoint',
  ].every((token) => mindGraphFunction.includes(token)),
  'Mind mode stage1 must use the scorechart.png chart structure only: readable axis/month scale, segmented score path, and one endpoint dot based on the stats graph source',
);
assert(
  mindGraphFunction.includes('class="common-score-svg common-score-svg-expanded"') &&
    mindGraphFunction.includes('common-score-axis-label') &&
    mindGraphFunction.includes('common-score-month-label') &&
    mindGraphFunction.includes('common-score-path bad') &&
    mindGraphFunction.includes('common-score-path neutral') &&
    mindGraphFunction.includes('common-score-path good') &&
    mindGraphFunction.includes('common-score-endpoint') &&
    !mindGraphFunction.includes('common-score-chart') &&
    !mindGraphFunction.includes('common-score-zone') &&
    !mindGraphFunction.includes('<strong>82/100</strong>') &&
    !mindGraphFunction.includes('>82/100</text>') &&
    !mindGraphFunction.includes('common-score-badge'),
  'D2 score graph must be a cleaner reference-style chart: no smaller inner card, no colored background zones/plumes, no chart badge, and no duplicate chart-internal score number',
);
assert(
  /\.common-score-grid\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-score-axis\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html) &&
    /\.common-score-path\s*\{[\s\S]*?fill:\s*none;[\s\S]*?\}/.test(html),
  'D2 score chart grid, axis, and trend paths must explicitly use fill:none so SVG paths cannot render a black filled polygon over the trend',
);
assert(
  /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonBudgetGlossyExtendedInfo\(\)/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonMindScoreGraphContent\(\)/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?stage2Header\?\.querySelector\('\.common-context-layer'\)\?\.remove\(\)/.test(html) &&
    /function syncCommonHeaderStage2Stage1Layer\(row\) \{[\s\S]*?cloneNode\(true\)[\s\S]*?common-stage2-stage1-layer[\s\S]*?dataset\.stage2IncludesStage1[\s\S]*?insertAdjacentElement/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderStage2Stage1Layer\(row\)/.test(html) &&
    !/function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?buildCommonContextCarousel/.test(html),
  'Runtime cloned rows must use the budget and mind stage1 helpers, clone the active stage1 layer into stage2, and must not insert any stage3 bottom avatar carousel',
);
assert(
  /function buildCommonMindScoreGraphContent\(\) \{[\s\S]*?common-focus-score-graph/.test(html) &&
    !/function buildCommonMindScoreGraphContent\(\) \{[\s\S]*?buildCommonStage1AvatarStrip\(\)/.test(html),
  'D2 mind stage1 must keep the score graph in its glossy container without rendering category avatars',
);
const mindHeatmapFunction = html.slice(
  html.indexOf('function buildCommonMindHeatmapContent'),
  html.indexOf('function ensureCommonHeaderHandle'),
);
const mindHeatmapFullScreen = html.slice(
  html.indexOf('data-screen="alt-common-header-mind-heatmap-full"'),
  html.indexOf('id="alternativePalette"'),
);
assert(
  [
    'data-stage2-extra="mind-heatmap"',
    'common-stage2-heatmap-layer',
    'common-stage2-heatmap-panel',
    'common-stage2-heatmap-scroll',
    'data-heatmap-panel="score-glass"',
    'buildMindHeatmapYearGrid',
    'StatsYearCalendar',
    'StatsMonthCard.cardHeight',
    'StatsYearData',
    'heatmapIntensity',
    'data-heatmap-grid="year"',
    'data-heatmap-columns="3"',
    'data-heatmap-rows="4"',
  ].every((token) => mindHeatmapFunction.includes(token)),
  'D3 mind stage2 must add a scrollable minimalist yearly heatmap layer based on the app StatsYearCalendar/StatsMonthCard model',
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
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="frost"\]\s*\{[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="aurora"\]\s*\{[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\[data-heatmap-card-variant="graphite"\]\s*\{[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-variant-gallery\s*\{[\s\S]*?\}/.test(html),
  'Heatmap monthcard CSS must provide three glossy non-white variants and paint cells through a dynamic color overlay',
);
assert(
  /function buildMindHeatmapVariantGallery\(\) \{[\s\S]*?data-heatmap-variant-gallery/.test(html) &&
    /function buildMindHeatmapVariantGallery\(\) \{[\s\S]*?frost[\s\S]*?aurora[\s\S]*?graphite/.test(html) &&
    /function initMindHeatmapScreens\(\) \{[\s\S]*?data-mind-heatmap-render-target[\s\S]*?data-mind-heatmap-variant-target[\s\S]*?buildMindHeatmapVariantGallery/.test(html) &&
    mindHeatmapFullScreen.includes('data-mind-heatmap-variant-target'),
  'The full heatmap preview must include a separate monthcard variant gallery rendered by JS',
);
assert(
  /\.common-header-stage2\[data-stage2-scrollable="true"\]\s*\{[\s\S]*?overflow:\s*hidden;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-heatmap-layer\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?overflow-y:\s*auto;[\s\S]*?overscroll-behavior:\s*contain;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-heatmap-panel\s*\{[\s\S]*?border-radius:\s*17px;[\s\S]*?backdrop-filter:\s*blur\(12px\);[\s\S]*?\}/.test(html) &&
    /\.common-stage2-heatmap-panel \.mind-heatmap-month-card\s*\{[\s\S]*?background:\s*rgba\(255,255,255,\.18\);[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-head\s*\{[\s\S]*?min-height:\s*12px;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-weekdays\s*\{[\s\S]*?margin:\s*7px 0 4px;[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-grid\s*\{[\s\S]*?grid-template-columns:\s*repeat\(3,\s*minmax\(0,\s*1fr\)\);[\s\S]*?\}/.test(html) &&
    /\.mind-heatmap-month-card\s*\{[\s\S]*?border-radius:\s*16px;[\s\S]*?\}/.test(html),
  'D3 heatmap CSS must keep stage2 scroll confined to a score-chart-like glass panel and render compact 3-column month cards',
);
assert(
  /function syncCommonHeaderMindHeatmapLayer\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'mind'[\s\S]*?dataset\.stage2Scrollable = 'true'[\s\S]*?buildCommonMindHeatmapContent\(\)[\s\S]*?insertAdjacentHTML/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderStage2Stage1Layer\(row\)[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\)/.test(html),
  'Runtime D rows must attach the heatmap only to Mind stage2 after cloning the active stage1 layer',
);
assert(
  mindHeatmapFullScreen.includes('data-screen-height="content"') &&
    mindHeatmapFullScreen.includes('data-mind-heatmap-render-target') &&
    mindHeatmapFullScreen.includes('data-heatmap-preview="full-year"') &&
    /function initMindHeatmapScreens\(\) \{[\s\S]*?data-mind-heatmap-render-target[\s\S]*?buildMindHeatmapYearGrid/.test(html),
  'A separate non-phone-height D heatmap preview screen must render the complete 12-month 4x3 year grid',
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
    'buildBudgetCategoryPieSlices()',
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
assert(
  /function syncCommonHeaderBudgetPieLayer\(row,\s*definition\) \{[\s\S]*?definition\.mode !== 'budget'[\s\S]*?dataset\.stage2Scrollable = 'true'[\s\S]*?dataset\.budgetPieScrollable = 'true'[\s\S]*?buildCommonBudgetCategoryPieContent\(\)[\s\S]*?insertAdjacentHTML/.test(html) &&
    /function updateCommonHeaderModeRow\(modeSection, definition\) \{[\s\S]*?syncCommonHeaderMindHeatmapLayer\(row, definition\)[\s\S]*?syncCommonHeaderBudgetPieLayer\(row, definition\)/.test(html),
  'Runtime C rows must attach the pie layer only to Budget stage2 after stage1 cloning and make that stage2 area scrollable',
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
const commonHeaderStage2 = commonHeaderRow.slice(commonHeaderRow.indexOf('data-screen="alt-common-header-stage2"'));
assert(commonHeaderStage0 && commonHeaderStage1 && commonHeaderStage2, 'B row must contain three common-header stage screen blocks');
assert(
  commonHeaderStage0.includes('data-common-header-state="collapsed"') &&
    commonHeaderStage0.includes('data-common-header-snap="0"') &&
    commonHeaderStage0.includes('data-stage-source="A1-copy"') &&
    commonHeaderStage0.includes('class="common-header-card common-header-stage0"') &&
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
    commonHeaderStage1.includes('class="common-balance-reserve-progress"') &&
    commonHeaderStage1.includes('Tartalék') &&
    commonHeaderStage1.includes('data-balance-progress="reserve"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-row"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-title"') &&
    commonHeaderStage1.includes('balance arány') &&
    commonHeaderStage1.includes('class="common-balance-ratio-metrics"') &&
    commonHeaderStage1.includes('data-balance-ratio-metric="income"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-value income"') &&
    commonHeaderStage1.includes('32%') &&
    commonHeaderStage1.includes('bevétel') &&
    commonHeaderStage1.includes('data-balance-ratio-metric="expense"') &&
    commonHeaderStage1.includes('class="common-balance-ratio-value expense"') &&
    commonHeaderStage1.includes('68%') &&
    commonHeaderStage1.includes('kiadás') &&
    commonHeaderStage1.indexOf('class="common-balance-reserve-progress"') <
      commonHeaderStage1.indexOf('class="common-balance-ratio-row"') &&
    commonHeaderStage1.indexOf('class="common-balance-ratio-row"') <
      commonHeaderStage1.indexOf('class="common-balance-stage1-card-grid"') &&
    commonHeaderStage1.includes('class="common-balance-stage1-card-grid"') &&
    (commonHeaderStage1.match(/class="fastinfo-chart-card/g) || []).length === 3 &&
    commonHeaderStage1.includes('Havi kiadás') &&
    commonHeaderStage1.includes('Legnagyobb kiadás') &&
    commonHeaderStage1.includes('Átlagos napi költés') &&
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
  'B2 stage 1 must remove the small balance subvalue, income graph, and large centered ratio, then render a compact balance ratio row between the reserve progress and the three A1C info cards',
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
    commonHeaderStage2.includes('class="common-balance-reserve-progress"') &&
    commonHeaderStage2.includes('class="common-balance-ratio-row"') &&
    commonHeaderStage2.includes('balance arány') &&
    commonHeaderStage2.includes('class="common-balance-stage1-card-grid"') &&
    (commonHeaderStage2.match(/class="fastinfo-chart-card/g) || []).length === 3 &&
    commonHeaderStage2.includes('Havi kiadás') &&
    commonHeaderStage2.includes('Legnagyobb kiadás') &&
    commonHeaderStage2.includes('Átlagos napi költés') &&
    commonHeaderStage2.includes('data-focus-mode-stage2="balance-income-expense"') &&
    commonHeaderStage2.includes('data-stats-active-type="income"') &&
    commonHeaderStage2.includes('data-source="lib/features/stats/widgets/stats_fast_info_graph.dart"') &&
    commonHeaderStage2.includes('data-graph-count="3"') &&
    commonHeaderStage2.includes('class="common-stage2-income-expense-layer"') &&
    commonHeaderStage2.includes('class="common-focus-income-expense-graph common-stage2-graph-stack"') &&
    commonHeaderStage2.includes('Bevétel vs kiadás') &&
    commonHeaderStage2.includes('Fedezi a kiadást') &&
    commonHeaderStage2.includes('Kevés bevétel') &&
    commonHeaderStage2.includes('Nullszaldó') &&
    commonHeaderStage2.includes('class="common-income-expense-svg common-stage2-interval-svg"') &&
    commonHeaderStage2.includes('class="common-income-centerline"') &&
    (commonHeaderStage2.match(/class="common-income-bar income"/g) || []).length >= 3 &&
    (commonHeaderStage2.match(/class="common-income-bar expense"/g) || []).length >= 2 &&
    commonHeaderStage2.includes('data-stage2-graph="merged-pattern-bars"') &&
    commonHeaderStage2.includes('data-source-expense-helper="lib/features/stats/data/stats_category_scope_series.dart::_expenseHelperBars"') &&
    commonHeaderStage2.includes('data-source-income-helper="lib/features/stats/data/stats_category_scope_series.dart::_incomeThresholdExcessBars"') &&
    commonHeaderStage2.includes('class="common-pattern-combo-svg"') &&
    commonHeaderStage2.includes('class="common-pattern-centerline"') &&
    (commonHeaderStage2.match(/class="common-pattern-bar income"/g) || []).length >= 5 &&
    (commonHeaderStage2.match(/class="common-pattern-bar expense"/g) || []).length >= 5 &&
    commonHeaderStage2.indexOf('data-stage2-includes-stage1="true"') <
      commonHeaderStage2.indexOf('data-focus-mode-stage2="balance-income-expense"') &&
    commonHeaderStage2.includes('class="common-header-menu"') &&
    commonHeaderStage2.includes('class="common-header-expand-handle"'),
  'B3 stage 2 must keep the expanded header geometry and balance-only top text, duplicate the full B2 reserve summary as the stage1 layer, then place the three-layer income/pattern graph stack as the extra stage2 area below it',
);
assert(
  /\.common-stage2-income-expense-layer\s*\{[\s\S]*?height:\s*264px;[\s\S]*?\}/.test(html) &&
    /\.common-stage2-graph-stack\s*\{[\s\S]*?grid-template-rows:[\s\S]*?common-stage2-interval-svg[\s\S]*?common-pattern-combo-svg/.test(html) &&
    /\.common-pattern-centerline\s*\{[\s\S]*?stroke:[\s\S]*?\}/.test(html) &&
    /\.common-pattern-bar\.income\s*\{[\s\S]*?fill:\s*rgba\(34,197,94,[\s\S]*?\}/.test(html) &&
    /\.common-pattern-bar\.expense\s*\{[\s\S]*?fill:\s*rgba\(239,68,68,[\s\S]*?\}/.test(html),
  'B3 graph CSS must double the glossy graph height and style the merged pattern chart with a centerline plus green upward and red downward bars',
);
assert.strictEqual(
  (commonHeaderRow.match(/class="common-header-menu"/g) || []).length,
  3,
  'The three source common-header states must each render exactly one shared glossy three-bar menu button',
);
assert.strictEqual(
  (commonHeaderRow.match(/class="common-header-eye"/g) || []).length,
  0,
  'The common-header source states must not render a separate eye button; the single menu button is the only header control',
);
assert.strictEqual(
  (commonHeaderRow.match(/class="common-header-expand-handle"/g) || []).length,
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
  !commonHeaderStage0.includes('class="bottom-nav"') &&
    !commonHeaderStage1.includes('class="bottom-nav"') &&
    !commonHeaderStage2.includes('class="bottom-nav"'),
  'B row screens must not render any bottom nav; B screenshots are header/content displacement studies only',
);
assert(
  /\.common-header-stage0 \{[\s\S]*?height:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-stage1 \{[\s\S]*?height:\s*284px;/.test(html) &&
    /\.common-header-stage2 \{[\s\S]*?--common-header-h:\s*var\(--common-header-stage2-expanded-h\);[\s\S]*?height:\s*var\(--common-header-stage2-expanded-h\);/.test(html) &&
    /\.common-header-expand-handle \{[\s\S]*?bottom:\s*7px;[\s\S]*?background:\s*rgba\(255,255,255,\.86\);/.test(html) &&
    /\.spendee-dashboard-screen\.common-header-screen \.common-header-home-content \{[\s\S]*?top:\s*calc\(var\(--common-header-active-top\) \+ var\(--common-header-active-h\) \+ var\(--common-header-content-gap\)\);/.test(html),
  'B-row CSS must model the three common header snap heights, bottom handle, and pushed-down content without requiring a stage3 avatar carousel',
);
assert(
  /\.common-header-stage0-screen \.common-header-home-content,\s*\n\s*\.common-header-stage1-screen \.common-header-home-content \{[\s\S]*?bottom:\s*0;/.test(html) &&
    /\.common-header-stage0-screen \.log-area,\s*\n\s*\.common-header-stage1-screen \.log-area \{[\s\S]*?bottom:\s*0;[\s\S]*?padding-bottom:\s*16px;/.test(html),
  'B1/B2 must remove the old bottom-nav clearance so transaction logs fill the bottom of the phone',
);
assert(
  /\.common-header-screen \{[\s\S]*?--common-header-content-gap:\s*calc\(var\(--spendee-content-top\) - var\(--spendee-header-top\) - var\(--spendee-header-h\)\);[\s\S]*?--common-header-active-h:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-active-top:\s*var\(--spendee-header-top\);/.test(html) &&
    /\.common-header-stage0-screen \{[\s\S]*?--common-header-active-h:\s*var\(--spendee-header-h\);/.test(html) &&
    /\.common-header-stage1-screen \{[\s\S]*?--common-header-active-h:\s*284px;/.test(html) &&
    /\.common-header-stage2-screen \{[\s\S]*?--common-header-active-h:\s*var\(--common-header-stage2-expanded-h\);[\s\S]*?--common-header-active-top:\s*var\(--spendee-header-top\);/.test(html) &&
    !/\.common-header-stage1-screen \.common-header-home-content \{[\s\S]*?\+ 246px/.test(html) &&
    !/\.common-header-stage2-screen \.common-header-home-content \{[\s\S]*?\+ 444px/.test(html),
  'B-row content must be anchored to current header bottom plus the original A1 4px gap, not arbitrary stage offsets',
);
assert(
  /\.common-header-card \{[\s\S]*?top:\s*var\(--common-header-active-top\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-a5-submit-safe-top:\s*calc\(var\(--screen-h\) - 18px\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-safety-top:\s*var\(--common-header-a5-submit-safe-top\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-visible-stack-h:\s*calc\(var\(--spendee-type-row-h\) \+ var\(--common-header-summary-visible-h\) \+ var\(--common-header-search-top-gap\) \+ var\(--common-header-search-visible-h\)\);/.test(html) &&
    /\.common-header-screen \{[\s\S]*?--common-header-stage2-expanded-h:\s*calc\(var\(--common-header-a5-submit-safe-top\) - var\(--spendee-header-top\) - var\(--common-header-content-gap\) - var\(--common-header-stage2-visible-stack-h\)\);/.test(html) &&
    !html.includes('--common-header-stage2-lower-shift') &&
    /\.common-header-stage2-screen \.common-header-home-content \{[\s\S]*?bottom:\s*calc\(var\(--screen-h\) - var\(--common-header-stage2-safety-top\)\);[\s\S]*?overflow:\s*hidden;/.test(html),
  'B3 stage 2 must keep the header top fixed, expand header height downward to the A5 submit-button safe-top, and clip everything below the search pill',
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
      !/\.category-limit-partition-bar \{[\s\S]*?height:\s*14px;/.test(html) &&
      !/\.category-limit-partition-bar \{[\s\S]*?border:\s*1\.6px solid var\(--white\);/.test(html) &&
      !/\.category-limit-partition-bar \{[\s\S]*?border-radius:\s*0;/.test(html) &&
      !/\.category-limit-partition-bar \{[\s\S]*?border-top:\s*1\.6px solid var\(--white\);[\s\S]*?border-bottom:\s*1\.6px solid var\(--white\);/.test(html) &&
      !/\.category-limit-partition-bar \{[\s\S]*?clip-path:\s*inset\(0 round 0\);/.test(html) &&
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
assert(
  /\.spendee-backheader-card::before \{[\s\S]*?background:[\s\S]*?var\(--spendee-backheader-category-color\)[\s\S]*?opacity:\s*var\(--spendee-backheader-opacity\);[\s\S]*?z-index:\s*0;/.test(
    html,
  ) &&
    !/\.spendee-backheader-card::before \{[\s\S]*?#18ba78/.test(html) &&
    !/\.spendee-backheader-card::before \{[\s\S]*?var\(--spendee-header-bg/.test(html),
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
    /\.add-transaction-card-redesign \{[\s\S]*?height:\s*430px;[\s\S]*?border-radius:\s*26px 26px 0 0;/.test(html) &&
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

const logoAssetPath = path.join(__dirname, 'spendee_final_spendeevector.svg');
assert(fs.existsSync(logoAssetPath), 'Missing local copy of /storage/emulated/0/spendee/final_spendeevector.svg');
const logoSvg = fs.readFileSync(logoAssetPath, 'utf8');
const logoPathBlock = (pathId) =>
  logoSvg.match(new RegExp(`<path[\\s\\S]*?id="${pathId}"[\\s\\S]*?\\/>`))?.[0] || '';
assert(
  /id="spendee-card-blue-gradient"[\s\S]*?#168ccf[\s\S]*?#35b8f0/.test(logoSvg) &&
    /id="spendee-bell-gradient"[\s\S]*?#22c55e[\s\S]*?#f59e0b[\s\S]*?#ec4899/.test(logoSvg),
  'Spendee logo SVG must define blue card and green-orange-rose bell gradients',
);
assert(
  logoPathBlock('path1').includes('fill="url(#spendee-card-blue-gradient)"') &&
    logoPathBlock('path2').includes('fill="url(#spendee-card-blue-gradient)"'),
  'Spendee logo card/ring paths path1 and path2 must be blue',
);
assert(
  logoPathBlock('path3').includes('fill="url(#spendee-bell-gradient)"') &&
    logoPathBlock('path8').includes('fill="url(#spendee-bell-gradient)"') &&
    logoPathBlock('path9').includes('fill="url(#spendee-bell-gradient)"') &&
    !logoPathBlock('path3').includes('stroke=') &&
    !logoPathBlock('path8').includes('stroke=') &&
    !logoPathBlock('path9').includes('stroke='),
  'Spendee logo bell path, vibration-arc path and bell-clapper path must use the gradient fill without any border/stroke',
);
assert(
  logoPathBlock('path4').includes('fill="#dbe3ec"') &&
    logoPathBlock('path5').includes('fill="#dbe3ec"') &&
    logoPathBlock('path6').includes('fill="#dbe3ec"'),
  'Spendee logo column paths path4-path6 must be light gray',
);
assert(
  logoPathBlock('path7').includes('fill="#ec4899"'),
  'Spendee logo notification dot path7 must remain a rose accent',
);

const altHeaderTargetCount =
  (alternativeSection.match(/data-color-target="header-card"/g) || []).length;
assert.strictEqual(
  altHeaderTargetCount,
  11,
  'Alternative design must duplicate header-card recolor targets for the dashboard-like lower screens including the new stats dashboard and the three B-row common-header stages; the A2 category selector and A3 vendor selector are separate fullscreen routes',
);
const spendeeHeaderCount = (alternativeSection.match(/class="app-header spendee-header\b/g) || [])
  .length;
assert.strictEqual(
  spendeeHeaderCount,
  8,
  'All lower dashboard-like Spendee screens including the stats dashboard and except the fullscreen category/vendor selectors must use the new Spendee glass header card',
);
const spendeeBrandCount = (alternativeSection.match(/class="spendee-brand-lockup"/g) || [])
  .length;
assert.strictEqual(
  spendeeBrandCount,
  11,
  'All lower dashboard-like Spendee screens including stats, both fastinfo stage1 variants, stage2, both backheader prototypes, and the limit edit keyboard state must show the Spendee logo; the A2/A3 fullscreen selectors have their own route headers',
);
const spendeeLogoLivePreviewCount =
  (alternativeSection.match(/class="spendee-logo spendee-logo-live-preview"[^>]*data-logo-live-preview/g) || [])
    .length;
assert.strictEqual(
  spendeeLogoLivePreviewCount,
  11,
  'All lower Spendee mock logos must be inline live SVG previews that can follow logo-editor path recolors',
);
assert.strictEqual(
  (alternativeSection.match(/<img class="spendee-logo"/g) || []).length,
  0,
  'Lower Spendee mock logos must not remain static img tags because they cannot live-sync path edits',
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
  7,
  'All dashboard-like lower Spendee headers must show a small Balance label above the balance amount',
);
assert.strictEqual(
  (alternativeSection.match(/class="spendee-balance-label">Score<\/div>/g) || []).length,
  1,
  'The lower statistics dashboard must be the only dashboard-like header that replaces Balance with Score',
);
const spendeeCategoryMenuVarCount =
  (alternativeSection.match(/data-color-var="--spendee-category-menu-button-bg"/g) || [])
    .length;
assert.strictEqual(
  spendeeCategoryMenuVarCount,
  11,
  'All lower dashboard-like Spendee header category buttons, including all three B-row common-header menu buttons, must use the dedicated glass-button color variable',
);
assert(
  !legacySection.includes('spendee-header') &&
    !legacySection.includes('spendee-brand-lockup') &&
    !legacySection.includes('spendee_final_spendeevector.svg') &&
    !legacySection.includes('--spendee-category-menu-button-bg') &&
    !legacySection.includes('data-backheader-toggle'),
  'Legacy upper section must not receive the Spendee dashboard header redesign',
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
  /\.spendee-brand-lockup \{[\s\S]*?top:\s*var\(--spendee-brand-top\);[\s\S]*?left:\s*22px;/.test(html),
  'Spendee brand lockup must be positioned by the updated 48px top token',
);
assert(
  /\.spendee-logo \{[\s\S]*?width:\s*var\(--spendee-logo-size\);[\s\S]*?height:\s*var\(--spendee-logo-size\);/.test(
    html,
  ),
  'Spendee logo must be driven by the 79.5px size token, visibly larger than in the latest screenshot',
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

const sourceColorCount =
  (html.match(/data-palette-group="app-source"/g) || []).length;
assert(
  sourceColorCount >= 30,
  `Expected at least 30 app-source color slots, got ${sourceColorCount}`,
);

const proposedColorCount =
  (html.match(/data-palette-group="proposed-neutral"/g) || []).length;
assert(
  proposedColorCount >= 12,
  `Expected at least 12 proposed neutral color slots, got ${proposedColorCount}`,
);

const keyboardtestSourceColorCount =
  (html.match(/data-palette-group="keyboardtest-source"/g) || []).length;
assert(
  keyboardtestSourceColorCount >= 14,
  `Expected at least 14 keyboardtest source color slots, got ${keyboardtestSourceColorCount}`,
);

const textPaletteCount =
  (html.match(/data-palette-role="text"/g) || []).length;
assert(
  textPaletteCount >= 10,
  `Expected at least 10 text-only color slots, got ${textPaletteCount}`,
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
  7,
  'Expected one legacy home panel, lower Spendee home, active/no-limit fastinfo stage1, fastinfo stage2, and both duplicated backheader home shells to expose isolated pill targets',
);
const homePanelExpectedVars = [
  {
    income: '--income-button-bg',
    expense: '--expense-button-bg',
    summary: '--summary-pill-bg',
    search: '--search-pill-bg',
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
const previousSlotPalette = html.match(
  /<section class="palette-section" id="previousSlotPaletteRow"[^>]*>[\s\S]*?<\/section>/,
)?.[0];
assert(previousSlotPalette, 'Missing previous Spendee colour slot palette row below the current slot palette');
const originalSlotPalette = html.match(
  /<section class="palette-section" id="originalSlotPaletteRow"[^>]*>[\s\S]*?<\/section>/,
)?.[0];
assert(originalSlotPalette, 'Missing restored first/original Spendee colour slot palette row');
const fabBlueGradientPalette = html.match(
  /<section class="palette-section" id="fabBlueGradientPaletteRow"[^>]*>[\s\S]*?<\/section>/,
)?.[0];
assert(fabBlueGradientPalette, 'Missing FAB blue combined gradient palette row at the very bottom');
const logoEditorSection = html.match(
  /<section class="palette-section logo-editor-section" id="spendeeLogoEditor"[^>]*data-logo-editor[\s\S]*?<\/section>/,
)?.[0];
assert(logoEditorSection, 'Missing bottom Spendee path-level logo editor section');
assert(
  html.indexOf('id="previousSlotPaletteRow"') > html.indexOf('id="alternativeSlotPaletteRow"'),
  'The previous Spendee palette must be rendered below the current rainbow slot palette',
);
assert(
  html.indexOf('id="originalSlotPaletteRow"') > html.indexOf('id="previousSlotPaletteRow"') &&
    html.indexOf('id="originalSlotPaletteRow"') < html.indexOf('id="fabBlueGradientPaletteRow"'),
  'The restored first/original palette must be rendered below the previous palette and above the bottom FAB-blue row',
);
assert(
  html.indexOf('id="fabBlueGradientPaletteRow"') > html.indexOf('id="previousSlotPaletteRow"'),
  'The FAB blue combined gradient palette must be rendered below every slot palette row',
);
assert(
  html.indexOf('id="spendeeLogoEditor"') > html.indexOf('id="fabBlueGradientPaletteRow"') &&
    html.indexOf('id="spendeeLogoEditor"') < html.indexOf('</section>\n      </section>\n    </section>\n    </section>\n  </main>'),
  'The Spendee logo editor must be the bottom-most component below all alternative colour selector rows',
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
    logoEditorSection.includes('aria-label="Tappable Spendee logo paths"'),
  'Logo editor must render a large SVG stage for the tappable logo paths',
);
assert(
  /function initSpendeeLogoEditor\(\) \{[\s\S]*?fetch\('spendee_final_spendeevector\.svg\?v=20260712-path-logo-v2'\)[\s\S]*?renderLogoSvgPaths\(svg, parsedSvg, true\);[\s\S]*?document\.querySelectorAll\('\[data-logo-live-preview\]'\)\.forEach/.test(
    html,
  ),
  'Logo editor must load the real SVG asset, render the tappable editor logo and render every app mock logo as a live SVG preview',
);
assert(
  /function renderLogoSvgPaths\(svg, parsedSvg, editable\) \{[\s\S]*?path\.dataset\.logoEditorPath = path\.id;[\s\S]*?if \(editable\) \{[\s\S]*?path\.dataset\.colorTarget = 'logo-path';[\s\S]*?path\.classList\.add\('logo-editor-path'\);[\s\S]*?\} else \{[\s\S]*?path\.classList\.add\('logo-live-preview-path'\);/.test(
    html,
  ),
  'Logo renderer must make only editor paths tappable while live-preview paths stay passive but addressable by path id',
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
  21,
  'Expected 21 previous Spendee gradient tokens for the restored test palette',
);

const previousSlotCount =
  (previousSlotPalette.match(/data-palette-group="previous-colour-slots"/g) || []).length;
assert.strictEqual(
  previousSlotCount,
  21,
  'The restored previous Spendee palette must include all 21 previous gradient slot colors',
);

assert.strictEqual(
  (previousSlotPalette.match(/data-color="var\(--previous-slot-gradient-/g) || []).length,
  21,
  'The restored previous Spendee palette must contain exactly 21 previous gradient swatches',
);

const originalGradientTokenCount = (html.match(/--original-slot-gradient-\d+:/g) || []).length;
assert.strictEqual(
  originalGradientTokenCount,
  21,
  'Expected 21 original first-pass Spendee gradient tokens for the restored original palette',
);

assert.strictEqual(
  (originalSlotPalette.match(/data-palette-group="original-colour-slots"/g) || []).length,
  21,
  'The restored original palette must include all 21 first-pass gradient slot colors',
);

assert.strictEqual(
  (originalSlotPalette.match(/data-color="var\(--original-slot-gradient-/g) || []).length,
  21,
  'The restored original palette must contain exactly 21 first-pass gradient swatches',
);

const fabBlueGradientTokenCount = (html.match(/--fab-blue-gradient-\d+:/g) || []).length;
assert.strictEqual(
  fabBlueGradientTokenCount,
  20,
  'Expected 20 FAB blue combined gradient tokens for the bottom gradient row including pink shades',
);

const fabBlueSwatches =
  (fabBlueGradientPalette.match(/data-palette-group="fab-blue-gradients"/g) || []).length;
assert.strictEqual(
  fabBlueSwatches,
  20,
  'The bottom FAB blue palette must include 20 gradient variants including pink shades',
);

assert.strictEqual(
  (fabBlueGradientPalette.match(/data-color="var\(--fab-blue-gradient-/g) || []).length,
  20,
  'The bottom FAB blue palette must contain exactly 20 tappable FAB-gradient swatches',
);

assert(
  fabBlueGradientPalette.includes('purple turquoise') ||
    fabBlueGradientPalette.includes('lila türkiz'),
  'The bottom FAB blue palette must include a purple/turquoise combined variant',
);
assert(
  /pink|rose|rózsaszín/i.test(fabBlueGradientPalette),
  'The bottom FAB blue palette must include pink/rose shade variants',
);

assert(
  alternativeSlotPalette.includes(
    'data-gradient-source="/storage/emulated/0/spendee/layout  avatar colour gradient.png"',
  ),
  'The lower Spendee slot row must record the analysed gradient reference image',
);

assert(
  !legacySection.includes('slot-gradient') &&
    !legacySection.includes('data-color-target="logbox-avatar-circle"') &&
    !legacySection.includes('data-color-target="category-avatar-circle"') &&
    !legacySection.includes('data-color-target="vendor-avatar-circle"'),
  'Legacy upper section must stay original: no Spendee gradients or new avatar-circle targets',
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

const previousSlotSwatches = [
  ...previousSlotPalette.matchAll(/<button class="color-swatch"[\s\S]*?>/g),
].map((match) => match[0]);
assert.strictEqual(
  previousSlotSwatches.length,
  21,
  'The restored previous Spendee palette must expose exactly 21 slot buttons',
);
assert.deepStrictEqual(
  previousSlotSwatches.map((tag) => tag.match(/data-slot="([^"]+)"/)?.[1]),
  Array.from({ length: 21 }, (_, index) => String(index + 1)),
  'The restored previous Spendee palette must keep 1 through 21 slot labels',
);
assert(
  previousSlotSwatches[0].includes('var(--previous-slot-gradient-0)') &&
    previousSlotSwatches[14].includes('var(--previous-slot-gradient-14)') &&
    previousSlotSwatches[20].includes('var(--previous-slot-gradient-20)'),
  'The restored previous Spendee palette must use the previous-slot gradient variables, not the current rainbow variables',
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
  'Expected five legacy, five lower Spendee home, fifteen fastinfo home-shell, ten duplicated lower backheader home-shell, and nineteen B-row common-header A1-stack logbox rows after B1/B2 bottom-fill rows',
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
assert(lowerSpendeeSection.includes('Spendee'), 'Lower alternative section must be labelled Spendee');

const logboxAvatarTargetCount = (lowerSpendeeSection.match(/data-color-target="logbox-avatar-circle"/g) || [])
  .length;
assert.strictEqual(logboxAvatarTargetCount, 49, 'Expected 49 separate lower Spendee logbox avatar circle targets across the home, all fastinfo variants, both duplicated backheader home-shell screens, and all B-row common-header rows including B1/B2 bottom-fill rows');

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

for (const label of ['Minden kategória', 'Új kategória', 'Elelmiszer']) {
  const index = html.indexOf(label);
  assert(index >= 0, `Missing avatar label: ${label}`);
  const before = html.slice(Math.max(0, index - 380), index);
  assert(
    before.includes('slot-icon') && before.includes('data-icon-color="#ffffff"'),
    `${label} colored category circle must contain a white app icon`,
  );
}

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

console.log('Color lab static checks passed');
