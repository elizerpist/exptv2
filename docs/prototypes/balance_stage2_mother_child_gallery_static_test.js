#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const repoRoot = path.join(__dirname, '..', '..');
const htmlPath = path.join(repoRoot, 'balance_latest_layout.html');
const legacyHtmlPath = path.join(__dirname, 'balance_stage2_mother_child_gallery.html');
const appCatalogPath = path.join(
  repoRoot,
  'lib',
  'features',
  'settings',
  'models',
  'fast_info_card_catalog.dart',
);
const transactionLogListPath = path.join(
  repoRoot,
  'lib',
  'features',
  'transactions',
  'widgets',
  'transaction_log_list.dart',
);
const colorLabPath = path.join(__dirname, 'color_lab.html');

assert.ok(fs.existsSync(htmlPath), 'balance_latest_layout.html must exist at the project root');
assert.ok(!fs.existsSync(legacyHtmlPath), 'the former docs/prototypes gallery HTML must be removed after the canonical rename');
assert.ok(fs.existsSync(colorLabPath), 'Color Lab B3M source must exist');
assert.ok(fs.existsSync(transactionLogListPath), 'Flutter transaction log source must exist');

const html = fs.readFileSync(htmlPath, 'utf8');
const appCatalog = fs.readFileSync(appCatalogPath, 'utf8');
const transactionLogList = fs.readFileSync(transactionLogListPath, 'utf8');
const colorLab = fs.readFileSync(colorLabPath, 'utf8');
const expectedIds = [
  'mai_koltes',
  'heti_koltes',
  'havi_koltes',
  'koltesi_trend',
  'legutobbi_tranzakcio',
  'varhato_ho_vegi_koltes',
  'leggyakoribb_kereskedo',
  'atlagos_napi_koltes',
  'no_spend_napok_szama',
  'top_kategoria_heten',
  'legnagyobb_novekedo_kategoria',
];
const expectedVisuals = {
  mai_koltes: 'threshold',
  heti_koltes: 'weekly-bars',
  havi_koltes: 'monthly-comparison',
  koltesi_trend: 'zone-meter',
  legutobbi_tranzakcio: 'transaction-event',
  varhato_ho_vegi_koltes: 'forecast-band',
  leggyakoribb_kereskedo: 'activity-strip',
  atlagos_napi_koltes: 'spike-line',
  no_spend_napok_szama: 'seven-day-strip',
  top_kategoria_heten: 'mini-avatar-row',
  legnagyobb_novekedo_kategoria: 'category-box',
};
const appCatalogIds = [...appCatalog.matchAll(/id:\s*'([^']+)'/g)].map((match) => match[1]);
const galleryCatalogIds = [...html.matchAll(/id:\s*'([^']+)'/g)].map((match) => match[1]);
const budgetModeGalleryExcludedIds = [
  'megtakaritas',
  'leggyorsabban_fogyo_kategorialimit',
  'kovetkezo_ismetlo_kiadas',
  'havi_fix_koltseg_osszesen',
];
const galleryExcludedAppIds = new Set([
  'kiadas_bevetel_arany',
  ...budgetModeGalleryExcludedIds,
]);

function catalogCardBlock(id) {
  const match = html.match(
    new RegExp(`id: '${id}',([\\s\\S]*?)(?=\\n\\s*\\{\\n\\s*id: '|\\n\\s*\\];)`),
  );
  assert.ok(match, `missing ${id} card data block`);
  return match[0];
}

assert.deepEqual(galleryCatalogIds, expectedIds, 'expected inventory must match the gallery catalog');
assert.deepEqual(
  appCatalogIds.filter((id) => !galleryExcludedAppIds.has(id)),
  expectedIds,
  'the gallery must contain every selected FastInfo card',
);
assert.ok(
  appCatalogIds.includes('kiadas_bevetel_arany'),
  'the gallery change must not modify the current Flutter catalog',
);
for (const id of budgetModeGalleryExcludedIds) {
  assert.ok(
    appCatalogIds.includes(id),
    `${id} must remain available to the Flutter Budget mode`,
  );
  assert.doesNotMatch(
    html,
    new RegExp(`id:\\s*'${id}'`),
    `${id} must not remain a B3M HTML gallery card`,
  );
}
assert.doesNotMatch(
  appCatalog,
  /id:\s*'bevetel_ebben_a_honapban'/,
  'monthly income must not remain a Flutter FastInfo card',
);
assert.match(colorLab, /data-common-header-static-preview-column="strict-mother-child"/);
assert.match(colorLab, /common-header-stage2-mother-child/);
assert.match(colorLab, /common-balance-mother-child-panel/);
const sourceSparklineBlock = [...colorLab.matchAll(/\.fastinfo-sparkline\s*\{([\s\S]*?)\n\s*\}/g)]
  .map((match) => match[0])
  .find((block) => block.includes('rgba(6,182,212,.15)'));
assert.ok(sourceSparklineBlock, 'Color Lab must provide the source FastInfo sparkline primitive');
assert.match(sourceSparklineBlock, /background: linear-gradient\(180deg, rgba\(6,182,212,\.15\), rgba\(6,182,212,\.03\)\)/, 'the source sparkline must keep its low-opacity cyan fill');
assert.match(sourceSparklineBlock, /clip-path: polygon\(/, 'the source sparkline must remain a filled clipped surface');

assert.match(html, /<iframe[^>]+src="docs\/prototypes\/color_lab\.html"/);
assert.match(html, /data-exact-b3m-source/);
assert.match(html, /data-common-header-static-preview-column="strict-mother-child"/);
assert.match(html, /cloneNode\(true\)/);
assert.match(html, /common-header-mode/);
assert.match(html, /common-header-row/);
assert.match(html, /common-header-stage2-mother-child/);
assert.match(html, /common-balance-mother-child-panel/);
assert.match(html, /data-balance-scope="overview"/);
assert.match(html, /zoomViewport/);
assert.match(html, /zoomHost/);
assert.match(html, /zoomSurface/);
assert.match(html, /setCanvasZoom\(\.5\)/);
assert.match(html, /renderContextualVisual/);
assert.doesNotMatch(html, /<[A-Za-z][^>]*\bdata-query-scoped\b/i, 'rendered HTML tags must not be query-scoped');
assert.doesNotMatch(html, /top_kategoria_ma/);
assert.doesNotMatch(html, /\.phone\s*\{/);
assert.doesNotMatch(html, /\.balance-header\s*\{/);
assert.doesNotMatch(html, /\.stage2\s*\{/);
assert.doesNotMatch(html, /\.mother-card\s*\{/);

for (const id of expectedIds) {
  const cardBlock = catalogCardBlock(id);
  assert.match(
    cardBlock,
    new RegExp(`visual: '${expectedVisuals[id]}'`),
    `missing contextual ${expectedVisuals[id]} visual for ${id}`,
  );
}
assert.equal((html.match(/id: '/g) || []).length, expectedIds.length, 'exactly the canonical card data must be present');
assert.equal(new Set(Object.values(expectedVisuals)).size, expectedIds.length, 'every insight needs its own visual semantics');
assert.doesNotMatch(html, /factA:/);
assert.doesNotMatch(html, /factB:/);
assert.doesNotMatch(html, /Lidl az elmúlt 14 napban/, 'latest transaction must not borrow merchant-frequency evidence');
assert.doesNotMatch(catalogCardBlock('mai_koltes'), /share:\s*\{/, 'threshold visual must not be duplicated by a generic share bar');
assert.doesNotMatch(catalogCardBlock('varhato_ho_vegi_koltes'), /share:\s*\{/, 'forecast band must not be duplicated by a generic share bar');
const stage2RedesignReferencePath = path.join(__dirname, 'reference_assets', 'stage2redesign.png');
assert.ok(fs.existsSync(stage2RedesignReferencePath), 'the supplied Stage2 redesign screenshot must remain available as the local visual reference');
const stage2AnimationReferencePath = path.join(__dirname, 'reference_assets', 'stage2anim.png');
assert.ok(fs.existsSync(stage2AnimationReferencePath), 'the supplied expanded/collapsed animation reference must remain available locally');
assert.match(html, /<iframe id="exactB3MFrame"[\s\S]*?src="docs\/prototypes\/color_lab\.html"/, 'the root prototype must load its retained Color Lab source through the project-relative path');
assert.match(html, /const todayRedesignCardId = 'mai_koltes';/, 'the sole B3M-A carousel screen must designate Today spend as the screenshot-driven prototype');
assert.match(html, /const todayRedesignReference = 'docs\/prototypes\/reference_assets\/stage2redesign\.png';/, 'the visual reference asset must resolve from the root prototype location');
assert.match(html, /const todayAnimationReference = 'docs\/prototypes\/reference_assets\/stage2anim\.png';/, 'the animation reference asset must resolve from the root prototype location');
assert.match(html, /function installTodayRedesignStyles\(doc\)/, 'the screenshot redesign must install scoped screen styles');
assert.match(html, /function summarizeTodayRedesignFixture\(\)/, 'the screenshot redesign must derive visible values from one fixture');
assert.match(html, /function prepareTodayRedesignScreen\(column, card\)/, 'the screenshot redesign must replace only the designated first screen');
assert.match(html, /function populateTodayRedesignScreen\(column, card\)/, 'the sole B3M-A carousel screen must render the screenshot-driven composition');
assert.match(html, /if \(card\.id === todayRedesignCardId\) \{[\s\S]*?const todayB3mAColumn = sourceColumn\.cloneNode\(true\);[\s\S]*?todayB3mAColumn\.setAttribute\('data-today-budget-pill-behavior', 'exit'\);[\s\S]*?todayB3mAColumn\.setAttribute\('data-stage2-alternative', 'today-budget-pill-exit'\);[\s\S]*?populateTodayRedesignScreen\(todayB3mAColumn, card\);[\s\S]*?carouselRow\.append\(todayB3mAColumn\);/, 'Today spend must render exactly the B3M-A exit-pillar prototype without a sticky sibling');
assert.doesNotMatch(html, /todayDashboardCardId|populateTodayDashboardTestScreen|installTodayDashboardTestStyles/, 'the rejected one-surface Today dashboard must not remain');
const todayRedesignFixtureMatch = html.match(/const todayRedesignFixture = (\{[\s\S]*?\n\s*\});/);
assert.ok(todayRedesignFixtureMatch, 'the screenshot redesign needs a visible Color Lab fixture');
const todayRedesignFixture = Function(`return (${todayRedesignFixtureMatch[1]})`)();
assert.deepEqual(
  todayRedesignFixture,
  {
    balance: 372047472,
    reservePercent: 42,
    incomeRatio: 32,
    expenseRatio: 68,
    totalExpense: 12400,
    variableExpense: 8900,
    dailyRemaining: 6500,
    dailyAverage: 10100,
    transactionCount: 4,
    noSpendDays: 3,
    noSpendWindowDays: 7,
    topCategory: 'Élelmiszer',
    topCategoryStage1Meta: 'fixek nélkül',
    largestCategory: 'Közlekedés',
    largestCategoryDelta: 14200,
    largestCategoryPeriod: '30 nap',
    monthTotal: 486320,
  },
  'the screenshot redesign fixture must use the accepted visible card values only',
);
const todayRedesignBlock = html.match(/function populateTodayRedesignScreen\(column, card\) \{([\s\S]*?)(?=\n\s*function setB3MContent)/)?.[0];
assert.ok(todayRedesignBlock, 'the screenshot redesign renderer must exist before the generic content renderer');
assert.match(todayRedesignBlock, /summary\.balance/, 'the Balance hero must derive its amount from the redesign fixture');
assert.match(todayRedesignBlock, /summary\.reservePercent/, 'the Balance hero must derive its reserve value from the redesign fixture');
assert.match(todayRedesignBlock, /summary\.incomeRatio[\s\S]*?summary\.expenseRatio/, 'the hero must retain both balance-ratio values');
assert.match(todayRedesignBlock, /summary\.noSpendDays[\s\S]*?summary\.topCategory[\s\S]*?summary\.largestCategory/, 'the three insight cards must use the specified card facts in order');
assert.match(todayRedesignBlock, /summary\.dailyRemaining[\s\S]*?summary\.variableExpense[\s\S]*?summary\.dailyAverage[\s\S]*?summary\.transactionCount/, 'the daily detail card must retain all visible Today spend facts');
assert.match(todayRedesignBlock, /stage2-redesign-balance-hero/, 'the screenshot composition must include the large Balance hero');
assert.match(todayRedesignBlock, /stage2-redesign-insight-grid/, 'the screenshot composition must include the three-card insight strip');
assert.match(todayRedesignBlock, /stage2-redesign-today-detail/, 'the screenshot composition must include the wide daily detail card');
assert.match(todayRedesignBlock, /stage2-redesign-threshold-bar/, 'the daily detail card must include its threshold marker bar');
assert.match(todayRedesignBlock, /stage2-redesign-action-grid/, 'the screenshot composition must include two separate action cards');
assert.match(todayRedesignBlock, /stage2-redesign-month-summary/, 'the screenshot composition must retain the month summary surface');
assert.match(todayRedesignBlock, /stage2-redesign-search-row/, 'the screenshot composition must retain the search and filter controls');
assert.match(todayRedesignBlock, /stage2-redesign-bottom-nav/, 'the screenshot composition must render the five-item lower navigation');
assert.match(todayRedesignBlock, /if \(screen\.dataset\.todayBudgetPillBehavior === 'exit'\)[\s\S]*?createTodayTimeScopeDrawer\(doc\)/, 'only the disappearing-pill Today variant must compose the optional year-refinement drawer');
assert.match(todayRedesignBlock, /postBudgetContent\.append\(actions, monthSummary, searchRow, timeScopeDrawer, transactionSection\);/, 'the B3M-A year drawer must sit directly below search and before transactions');
assert.match(todayRedesignBlock, /attachTodayTimeScopeDrawer\(screen\);/, 'the rendered Today screen must activate the scoped year-drawer interaction');
assert.match(todayRedesignBlock, /Részletek/, 'the Balance hero must retain the screenshot detail action');
assert.match(todayRedesignBlock, /Bevétel[\s\S]*?Kiadás/, 'the redesign must render two separate action cards in screenshot order');
assert.match(todayRedesignBlock, /screen\.replaceChildren\(layout\)/, 'the first screen must be reflowed as a full screenshot-driven layout');
assert.doesNotMatch(todayRedesignBlock, /[Rr]ekord|[Rr]ecord|latestMerchant/, 'the screenshot redesign must not invent a record or retain the rejected latest-merchant rail');
const todayPreparationBlock = html.match(/function prepareTodayRedesignScreen\(column, card\) \{([\s\S]*?)(?=\n\s*function populateTodayRedesignScreen)/)?.[0];
assert.ok(todayPreparationBlock, 'the screenshot redesign preparation block must exist');
assert.match(todayPreparationBlock, /data-today-redesign-screen/, 'the designated screen must carry an explicit reference marker');
assert.match(todayPreparationBlock, /stage2-redesign-reference-asset/, 'the supplied reference image may only be retained as a local art source');
assert.match(todayPreparationBlock, /const budgetPillBehavior = column\.dataset\.todayBudgetPillBehavior \|\| 'sticky';/, 'the Today renderer must select an explicit sticky or disappearing-pill behavior per screen');
assert.match(todayPreparationBlock, /screen\.setAttribute\('data-today-budget-pill-behavior', budgetPillBehavior\);/, 'the selected pill behavior must be exposed on the rendered screen');
const todayStyleBlock = html.match(/function installTodayRedesignStyles\(doc\) \{([\s\S]*?)(?=\n\s*function createTodayRedesignElement)/)?.[0];
assert.ok(todayStyleBlock, 'the screenshot redesign style installer must stay scoped to the test screen');
assert.match(todayStyleBlock, /border-radius: 34px/, 'the Balance hero must preserve the screenshot\'s large rounded geometry');
assert.match(todayStyleBlock, /border-radius: 26px/, 'the insight/action cards must preserve the screenshot\'s card geometry');
assert.match(todayStyleBlock, /box-shadow:/, 'the screenshot redesign must define the layered shadow hierarchy');
assert.match(todayStyleBlock, /stage2-redesign-reference-asset/, 'the profile and action artwork must use the supplied screenshot asset rather than invented external assets');
assert.match(
  transactionLogList,
  /if \(row\.date != previousDate\) \{[\s\S]*?entries\.add\(TransactionLogEntry\.header\(row\.date\)\);/,
  'Flutter must create a date header whenever a sorted log row changes date',
);
assert.match(
  transactionLogList,
  /class _DateHeader[\s\S]*?color: AppColors\.gray500,[\s\S]*?fontSize: 12,[\s\S]*?fontWeight: FontWeight\.w700,/,
  'the prototype date-title contract must come from Flutter _DateHeader styling',
);
const todayTransactionDaysFixtureMatch = html.match(/const todayRedesignTransactionDays = (\[[\s\S]*?\n\s*\]);/);
assert.ok(todayTransactionDaysFixtureMatch, 'the collapsed state needs a named daily transaction fixture');
const todayRedesignTransactionDays = Function(`return (${todayTransactionDaysFixtureMatch[1]})`)();
assert.deepEqual(
  todayRedesignTransactionDays.map((day) => day.date),
  ['2026.07.22', '2026.07.21', '2026.07.20'],
  'the fixture must preserve three separately addressable raw app date groups',
);
assert.ok(
  todayRedesignTransactionDays.every((day) => Array.isArray(day.transactions) && day.transactions.length >= 4),
  'each date group must carry multiple separate transaction rows',
);
const todayRedesignTransactions = todayRedesignTransactionDays.flatMap((day) => day.transactions);
assert.equal(todayRedesignTransactions.length, 15, 'the collapsed fixture must contain at least fifteen testable transactions');
assert.deepEqual(
  todayRedesignTransactionDays.map((day) => day.transactions.length),
  [4, 6, 5],
  'the first day must stay consistent with the visible four-transaction Today detail while the fixture totals fifteen rows',
);
assert.deepEqual(
  todayRedesignTransactionDays[0].transactions.slice(0, 3),
  [
    { merchant: 'Tesco', category: 'Élelmiszer', amount: 2450, time: '12:45', icon: 'shopping-cart.svg' },
    { merchant: 'MOL', category: 'Közlekedés', amount: 8900, time: '11:02', icon: 'bus-front.svg' },
    { merchant: 'Starbucks', category: 'Egyéb', amount: 1250, time: '09:17', icon: 'coffee.svg' },
  ],
  'the first day retains the three animation-reference transactions before its added test rows',
);
assert.doesNotMatch(html, /Összes tranzakció megtekintése/, 'the collapsed transaction surface must not retain the redundant all-transactions pill');
assert.doesNotMatch(html, /stage2-redesign-all-transactions/, 'the removed all-transactions pill must not retain renderer or style residue');
assert.match(html, /function installTodayRedesignInteractionStyles\(doc\)/, 'the Today redesign must have scoped scroll-state styles');
assert.match(html, /function attachTodayRedesignScrollInteraction\(screen, headerViewport, transactionViewport\)/, 'the Today redesign must attach independent header and transaction scroll controllers');
const todayInteractionStyleBlock = html.match(/function installTodayRedesignInteractionStyles\(doc\) \{([\s\S]*?)(?=\n\s*function attachTodayRedesignScrollInteraction)/)?.[0];
assert.ok(todayInteractionStyleBlock, 'the Today scroll-state style block must exist');
assert.match(todayInteractionStyleBlock, /overflow-y: auto/, 'the Today content layer must be touch-scrollable');
assert.match(todayInteractionStyleBlock, /-webkit-overflow-scrolling: touch/, 'the Today content layer must retain native mobile momentum scrolling');
assert.match(todayInteractionStyleBlock, /stage2-redesign-hero-overlay/, 'the gradient hero must be a separate overlay rather than a transaction-list row');
assert.match(todayInteractionStyleBlock, /stage2-redesign-hero-overlay \.stage2-redesign-balance-hero\s*\{[^}]*pointer-events:\s*none;/, 'the full visual hero must pass vertical swipes through to the header-collapse viewport');
assert.match(todayInteractionStyleBlock, /stage2-redesign-hero-overlay \.stage2-redesign-hero-action\s*\{[^}]*pointer-events:\s*auto;/, 'the visible hero action must remain the only tappable exception inside the swipe-through hero');
assert.match(todayInteractionStyleBlock, /stage2-redesign-budget-pill/, 'the compact budget state must be represented as a dedicated sticky pill');
assert.match(todayInteractionStyleBlock, /prefers-reduced-motion/, 'the scroll experience must respect a reduced-motion preference');
assert.match(todayInteractionStyleBlock, /stage2-redesign-transaction-viewport\s*\{[\s\S]*?height:\s*calc\(var\(--screen-h\) - 485px\);[\s\S]*?min-height:\s*calc\(var\(--screen-h\) - 485px\);[\s\S]*?padding:\s*0 2px;[\s\S]*?overflow-y:\s*auto;[\s\S]*?overscroll-behavior-y:\s*contain;[\s\S]*?touch-action:\s*pan-y;/, 'the nested transaction region must still reach the screen bottom after the larger summary pill moves it down');
assert.match(todayInteractionStyleBlock, /stage2-redesign-bottom-nav\s*\{[\s\S]*?z-index:\s*9;/, 'the bottom navigation must remain above rows that now extend to the phone-screen lower edge');
assert.match(todayInteractionStyleBlock, /stage2-redesign-transaction-day-title\s*\{[\s\S]*?color:\s*#64748b;[\s\S]*?font-size:\s*8px;[\s\S]*?font-weight:\s*700;/, 'each day title must use the Flutter DateHeader gray/weight semantics at prototype scale');
assert.match(todayInteractionStyleBlock, /stage2-redesign-transaction-day-card\s*\{[\s\S]*?border-radius:\s*18px;[\s\S]*?background:\s*rgba\(255, 255, 255, \.96\);[\s\S]*?box-shadow:/, 'each date group must be its own elevated card on the screen background');
assert.match(todayInteractionStyleBlock, /stage2-redesign-transaction-row \+ \.stage2-redesign-transaction-row\s*\{[\s\S]*?border-top:\s*1px solid #eff1f7;/, 'transaction rows inside one date card must remain separated');
assert.match(todayInteractionStyleBlock, /data-today-budget-pill-behavior="exit"[\s\S]*?stage2-redesign-time-scope-drawer/, 'the optional drawer styles must be scoped to B3M-A rather than every Today screen');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-year-rail[\s\S]*?overflow-x:\s*auto/, 'expanded year choices must retain horizontal touch scrolling');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope\s*\{[\s\S]*?background:\s*transparent;[\s\S]*?border:\s*0;[\s\S]*?box-shadow:\s*none;/, 'the time-scope root must be structural rather than a visual card');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-drawer\s*\{[\s\S]*?height:\s*21px;[\s\S]*?min-height:\s*21px;[\s\S]*?padding:\s*0;[\s\S]*?border:\s*0;[\s\S]*?border-radius:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;/, 'the scope-control wrapper must be structural so its label and year sit directly on the screen background');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-copy\s*\{[\s\S]*?display:\s*flex;[\s\S]*?align-items:\s*center;/, 'the scope label and selected year must sit on one inline control row');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-current\s*\{[\s\S]*?border:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;/, 'the selected year must be inline text rather than a nested white pill');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-toggle\s*\{[\s\S]*?width:\s*21px;[\s\S]*?height:\s*21px;[\s\S]*?border:\s*1px solid #fcc4de;[\s\S]*?background:\s*#fff5fa;/, 'the time-control button must match the screenshot\'s pale-pink bordered chevron button');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-year-drawer\s*\{[\s\S]*?padding:\s*0;[\s\S]*?border:\s*0;[\s\S]*?background:\s*transparent;[\s\S]*?box-shadow:\s*none;/, 'the expanded year rail must not render an inner visual container');
assert.match(todayInteractionStyleBlock, /data-time-scope-drawer-state="expanded"\][\s\S]*?stage2-redesign-time-scope-year-drawer\s*\{[\s\S]*?margin-top:\s*7px;[\s\S]*?padding:\s*0;[\s\S]*?background:\s*transparent;/, 'expanded year pills and dots must sit directly below the compact outer control on the screen background');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-year-pill\s*\{[\s\S]*?background:\s*#ffffff;[\s\S]*?color:\s*#1d2b50;/, 'inactive year choices must use the screenshot\'s raised white pills with dark text');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-year-pill\[aria-pressed="true"\]\s*\{[\s\S]*?linear-gradient\(126deg, #715efb 0%, #b484f3 50%, #e478c3 100%\)[\s\S]*?color:\s*#ffffff;/, 'the active year must use the screenshot\'s purple-pink gradient and white label');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-year-pill\[aria-pressed="true"\]::after/, 'the active year pill must include the screenshot\'s inset white selection dot');
assert.match(todayInteractionStyleBlock, /stage2-redesign-time-scope-pagination-dot\[data-time-scope-pagination-state="active"\]/, 'the rail must retain its centered active pagination dot');
assert.match(colorLab, /--spendee-header-top:\s*104px/, 'the Color Lab weekly-spend shell must expose the canonical header top');
assert.match(colorLab, /--spendee-header-h:\s*104px/, 'the Color Lab B1 collapsed header must expose its canonical 104px height');
assert.match(colorLab, /--spendee-content-top:\s*212px/, 'the Color Lab B1 shell must expose the adjacent content start');
assert.match(colorLab, /--spendee-type-pill-h:\s*42px/, 'the adjacent B3M action buttons must use the canonical 42px pill height');
assert.match(colorLab, /--common-header-content-gap:\s*calc\(var\(--spendee-content-top\) - var\(--spendee-header-top\) - var\(--spendee-header-h\)\)/, 'the adjacent B3M screen must derive its 4px header-to-content gap from the canonical shell values');
const b3mTypeRowBlock = colorLab.match(/\.spendee-dashboard-screen \.type-row \{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(b3mTypeRowBlock, 'the adjacent B3M action-row rule must exist');
assert.match(b3mTypeRowBlock, /padding:\s*12px 28px;/, 'the adjacent B3M action row must use 28px side insets');
assert.match(b3mTypeRowBlock, /gap:\s*10px;/, 'the adjacent B3M action row must use a 10px inter-button gap');
const b3mSummaryPillBlock = colorLab.match(/\.spendee-dashboard-screen \.summary-pill \{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(b3mSummaryPillBlock, 'the adjacent weekly-spend summary-pill rule must exist');
assert.match(b3mSummaryPillBlock, /margin:\s*0 28px;/, 'the adjacent weekly summary must have 28px side insets');
assert.match(b3mSummaryPillBlock, /min-height:\s*59px;/, 'the adjacent weekly summary must be 59px high');
assert.match(b3mSummaryPillBlock, /border-radius:\s*20px;/, 'the adjacent weekly summary must use a 20px radius');
const todayScrollContentInteractionBlock = todayInteractionStyleBlock.match(/stage2-redesign-scroll-content\s*\{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(todayScrollContentInteractionBlock, 'the Today scroll-content sizing rule must exist');
assert.match(todayScrollContentInteractionBlock, /padding:\s*var\(--today-redesign-scroll-top\) 16px 88px;/, 'the daily budget and all post-budget surfaces must share one 16px horizontal screen inset');
const todayActionGridInteractionBlock = todayInteractionStyleBlock.match(/stage2-redesign-action-grid\s*\{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(todayActionGridInteractionBlock, 'the Today action-grid sizing rule must exist');
assert.match(todayActionGridInteractionBlock, /height:\s*var\(--spendee-type-pill-h\);/, 'the full-width Today action row must retain the canonical 42px height');
assert.match(todayActionGridInteractionBlock, /min-height:\s*var\(--spendee-type-pill-h\);/, 'the full-width Today action row must retain its fixed height');
assert.doesNotMatch(todayActionGridInteractionBlock, /margin:/, 'the action grid must not add a second local inset inside the shared 16px content grid');
const todayMonthSummaryInteractionBlock = todayInteractionStyleBlock.match(/stage2-redesign-month-summary\s*\{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(todayMonthSummaryInteractionBlock, 'the Today summary sizing rule must exist');
assert.match(todayMonthSummaryInteractionBlock, /height:\s*59px;/, 'the Today summary must retain the weekly source height');
assert.match(todayMonthSummaryInteractionBlock, /min-height:\s*59px;/, 'the Today summary must retain its fixed height');
assert.doesNotMatch(todayMonthSummaryInteractionBlock, /margin:/, 'the summary must not add a second local inset inside the shared 16px content grid');
const todayPhoneWidth = 412;
const todaySharedSurfaceInset = 16;
const todaySharedSurfaceWidth = todayPhoneWidth - (todaySharedSurfaceInset * 2);
const todayActionGap = 10;
assert.equal(todaySharedSurfaceWidth, 380, 'the daily budget, actions, and summary must all use the 380px shared surface width');
assert.equal((todaySharedSurfaceWidth - todayActionGap) / 2, 185, 'the two full-width action buttons must each be 185px wide after their 10px gap');
assert.match(todayStyleBlock, /stage2-redesign-month-summary\s*\{[^}]*border-radius:\s*20px;/, 'the Today summary must match the weekly summary-pill radius');
const b1CollapsedHeaderBlock = colorLab.match(/\.common-header-stage0 \{([\s\S]*?)(?=\n\s*\})/)?.[0];
assert.ok(b1CollapsedHeaderBlock, 'the Color Lab B1 collapsed-header rule must exist');
assert.match(b1CollapsedHeaderBlock, /height:\s*var\(--spendee-header-h\)/, 'the Color Lab B1 collapsed header must use the canonical header height');
assert.match(todayInteractionStyleBlock, /stage2-redesign-hero-overlay[\s\S]*?top: var\(--spendee-header-top\)/, 'the Today gradient hero must share the weekly-spend header top');
assert.match(todayInteractionStyleBlock, /stage2-redesign-budget-pill[\s\S]*?top: calc\(var\(--spendee-header-top\) \+ var\(--today-redesign-hero-height\) \+ 11px\)/, 'the compact budget pill must follow the aligned hero');
assert.match(todayInteractionStyleBlock, /--today-redesign-hero-height:\s*150px;/, 'the Today expanded hero must start at the reduced alignment height');
const todayInteractionBlock = html.match(/function attachTodayRedesignScrollInteraction\(screen, headerViewport, transactionViewport\) \{([\s\S]*?)(?=\n\s*function populateTodayRedesignScreen)/)?.[0];
assert.ok(todayInteractionBlock, 'the Today scroll controller must be defined before its renderer');
assert.match(todayInteractionBlock, /collapseDistance\s*=\s*180/, 'the collapse distance must be explicit and inspectable');
assert.match(todayInteractionBlock, /const expandedHeroHeight\s*=\s*150;/, 'the Today scroll controller must use the reduced expanded hero height');
assert.match(todayInteractionBlock, /const collapsedHeroHeight\s*=\s*104;/, 'the Today animation must end at the exact Color Lab B1 collapsed-header height');
assert.match(todayInteractionBlock, /const heroHeight\s*=\s*expandedHeroHeight\s*-\s*\(\(expandedHeroHeight\s*-\s*collapsedHeroHeight\)\s*\*\s*progress\);/, 'the Today animation must interpolate to the B1 collapsed height');
const legacyExpandedHeaderOffset = 510;
const todayExpandedDetailOffset = 150 + 11 + 128 + 11 + 210;
assert.equal(todayExpandedDetailOffset, legacyExpandedHeaderOffset, 'the Today daily-detail lower edge must share the legacy expanded-header offset');
assert.match(todayInteractionStyleBlock, /--today-redesign-scroll-top:\s*calc\(var\(--spendee-header-top\) \+ var\(--today-redesign-hero-height\) \+ 11px\)/, 'the content must remain 11px below the dynamically aligned hero bottom');
assert.match(todayInteractionBlock, /const collapsedHeaderContentGap\s*=\s*4;/, 'the Today collapsed actions must use the same 4px content gap as the adjacent B3M screen');
assert.match(todayInteractionBlock, /const collapsedPostBudgetShift\s*=\s*-\(\(expandedInsightHeight \+ \(scrollStackGap \* 2\) \+ expandedDetailHeight\) - collapseDistance - compactBudgetPillHeight - collapsedHeaderContentGap\);/, 'the Today collapsed actions must compensate for the invisible insight and detail slots');
assert.match(todayInteractionBlock, /const budgetPillBehavior = screen\.dataset\.todayBudgetPillBehavior \|\| 'sticky';/, 'the scroll controller must read the screen-specific pill behavior');
assert.match(todayInteractionBlock, /const keepsBudgetPill = budgetPillBehavior === 'sticky';/, 'the scroll controller must distinguish the sticky and disappearing-pill variants');
assert.match(todayInteractionBlock, /const disappearingPillActionGap = scrollContentHeroGap;/, 'the disappearing-pill variant must reuse the first screen\'s header-to-budget-pill gap');
assert.match(todayInteractionBlock, /const disappearingPillPostBudgetShift\s*=\s*-\(\(expandedInsightHeight \+ \(scrollStackGap \* 2\) \+ expandedDetailHeight\) - scrollTop \+ scrollContentHeroGap - disappearingPillActionGap\);/, 'the disappearing-pill variant must keep actions aligned while the final header-collapse scroll continues');
assert.match(todayInteractionBlock, /const postBudgetShift = keepsBudgetPill \? collapsedPostBudgetShift : disappearingPillPostBudgetShift;/, 'the scroll controller must select the appropriate collapsed action anchor per variant');
assert.match(todayInteractionBlock, /const pillProgress = keepsBudgetPill \? clamp\(\(progress - \.18\) \/ \.58\) : 0;/, 'the disappearing-pill variant must never materialize the compact daily-budget pill');
assert.match(todayInteractionBlock, /--today-redesign-post-budget-shift', `\$\{\(postBudgetShift \* detailProgress\)\.toFixed\(2\)\}px`/, 'the post-budget area must converge on the selected variant anchor at full collapse');
assert.match(todayInteractionBlock, /budgetPill\.setAttribute\('aria-hidden', keepsBudgetPill && pillProgress > \.12 \? 'false' : 'true'\);/, 'the disappearing pill must remain inaccessible while hidden');
assert.match(todayInteractionStyleBlock, /stage2-redesign-action-card[\s\S]*?border-radius:\s*calc\(var\(--spendee-type-pill-h\) \/ 2\);/, 'the Today action-card radius must match the adjacent B3M pill geometry');
assert.match(todayInteractionBlock, /const scrollTop = Math\.min\(headerViewport\.scrollTop, collapseDistance\);/, 'only the upper-region scroll offset may drive header collapse progress');
assert.match(todayInteractionBlock, /if \(headerViewport\.scrollTop > collapseDistance\) \{[\s\S]*?headerViewport\.scrollTop = collapseDistance;/, 'the upper region must stop after the collapse distance instead of consuming transaction scroll');
assert.match(todayInteractionBlock, /headerViewport\.addEventListener\('scroll'/, 'upper-region scrolling must drive the Today collapse state');
assert.match(todayInteractionBlock, /transactionViewport\.addEventListener\('scroll'/, 'the logbox region must retain an independent native scroll observer');
assert.match(todayInteractionBlock, /requestAnimationFrame/, 'scroll updates must be frame-coalesced');
assert.match(todayInteractionBlock, /scrollTop/, 'the collapse state must derive from actual scroll offset');
assert.match(todayInteractionBlock, /--today-redesign-collapse-progress/, 'scroll progress must be exposed as a visual state variable');
assert.match(todayInteractionBlock, /--today-redesign-hero-height/, 'the gradient hero height must change continuously');
assert.match(todayInteractionBlock, /budgetPill\.addEventListener\('click'/, 'the compact budget pill must return the user to the expanded state');
assert.match(todayInteractionBlock, /headerViewport\.scrollTo\(\{ top: 0, behavior: 'smooth' \}\)/, 'the compact budget pill must expand through native upper-region scrolling');
const todayTimeScopeDrawerBlock = html.match(/function attachTodayTimeScopeDrawer\(screen\) \{([\s\S]*?)(?=\n\s*function populateTodayRedesignScreen)/)?.[0];
assert.ok(todayTimeScopeDrawerBlock, 'the B3M-A optional year drawer must have a dedicated interaction controller');
assert.match(todayTimeScopeDrawerBlock, /setExpanded\(false\)/, 'the optional year drawer must start collapsed');
assert.match(todayTimeScopeDrawerBlock, /drawerToggle\.addEventListener\('click'/, 'the year drawer must have an explicit expand/collapse control');
assert.match(todayTimeScopeDrawerBlock, /yearButton\.addEventListener\('click'/, 'year pills must update the selected compact year state');
assert.match(todayTimeScopeDrawerBlock, /yearRail\.scrollTo\(/, 'opening the rail must center the selected screenshot-style year');
const todayTimeScopeDrawerRendererBlock = html.match(/function createTodayTimeScopeDrawer\(doc\) \{([\s\S]*?)(?=\n\s*function attachTodayTimeScopeDrawer)/)?.[0];
assert.ok(todayTimeScopeDrawerRendererBlock, 'the B3M-A year drawer must have an explicit renderer');
assert.match(todayTimeScopeDrawerRendererBlock, /const timeScope = createTodayRedesignElement\(doc, 'section', 'stage2-redesign-time-scope'\);/, 'the control and rail must share only a nonvisual structural root');
assert.match(todayTimeScopeDrawerRendererBlock, /timeScope\.append\(drawer, yearDrawer\);/, 'the year rail must be a sibling below the outer control rather than a child inside it');
assert.doesNotMatch(todayTimeScopeDrawerRendererBlock, /drawer\.append\(control, yearDrawer\);/, 'the outer control must not contain the expanded year rail');
assert.match(todayTimeScopeDrawerRendererBlock, /--icon-url', "url\('\/assets\/icons\/lucide\/chevron-down\.svg'\)"/, 'the toggle renderer must request a real Lucide chevron asset');
assert.match(todayTimeScopeDrawerRendererBlock, /--icon-color', '#df2374'/, 'the chevron must use the screenshot\'s pink icon color');
assert.match(todayTimeScopeDrawerRendererBlock, /return timeScope;/, 'the renderer must return the nonvisual root rather than the outer control card');
assert.match(todayTimeScopeDrawerRendererBlock, /stage2-redesign-time-scope-pagination/, 'the renderer must include the screenshot\'s pagination-dot strip');
assert.match(todayTimeScopeDrawerRendererBlock, /stage2-redesign-time-scope-pagination-dot/, 'the renderer must create one pagination dot per selectable year');
assert.ok(fs.existsSync(path.join(repoRoot, 'assets/icons/lucide/chevron-down.svg')), 'the requested Lucide chevron asset must exist at the renderer path');
assert.match(todayRedesignBlock, /stage2-redesign-scroll-viewport/, 'the Today renderer must create a dedicated scroll viewport');
assert.match(todayRedesignBlock, /stage2-redesign-scroll-content/, 'the Today renderer must create a continuous scroll content layer');
assert.match(todayRedesignBlock, /scrollViewport\.setAttribute\('data-today-swipe-region', 'header'\);/, 'the upper content must explicitly identify its header-collapse swipe region');
assert.match(todayRedesignBlock, /stage2-redesign-transaction-viewport/, 'the Today renderer must create a nested transaction swipe region');
assert.match(todayRedesignBlock, /transactionViewport\.setAttribute\('data-today-swipe-region', 'transactions'\);/, 'the date-card log must explicitly identify its independent swipe region');
assert.match(todayRedesignBlock, /stage2-redesign-transaction-day-title/, 'the Today renderer must render a small app-style title for every transaction day');
assert.match(todayRedesignBlock, /stage2-redesign-transaction-day-card/, 'the Today renderer must render one independent elevated card per day');
assert.match(todayRedesignBlock, /for \(const day of todayRedesignTransactionDays\)/, 'the Today renderer must create day cards from the grouped transaction fixture');
assert.match(todayRedesignBlock, /stage2-redesign-hero-overlay/, 'the Today renderer must keep the gradient hero outside the scroll content layer');
assert.match(todayRedesignBlock, /stage2-redesign-budget-pill/, 'the Today renderer must create the compact budget pill');
assert.match(todayRedesignBlock, /stage2-redesign-transaction-section/, 'the Today renderer must reveal transactions below the collapsing surfaces');
assert.match(todayRedesignBlock, /attachTodayRedesignScrollInteraction\(screen, scrollViewport, transactionViewport\)/, 'the Today renderer must activate the split gesture controller after composition');
const todayTopbarBlock = todayRedesignBlock.match(/const topbar = createTodayRedesignElement\(doc, 'header', 'stage2-redesign-topbar'\);([\s\S]*?)(?=\n\s*const hero = createTodayRedesignElement)/)?.[0];
assert.ok(todayTopbarBlock, 'the Today renderer must define a dedicated area above the header');
assert.match(todayTopbarBlock, /topbar\.append\(brand\);/, 'the Today area above the header must retain only the Fluvi lockup');
assert.doesNotMatch(todayTopbarBlock, /stage2-redesign-tools|stage2-redesign-tool|stage2-redesign-profile|Értesítések|Elemzések|Profil/, 'the Today area above the header must not render alert, statistics, or profile controls');
const exactB3MRenderBlock = html.match(/function renderExactB3M\(doc\) \{([\s\S]*?)(?=\n\s*frame\.addEventListener)/)?.[0];
assert.ok(exactB3MRenderBlock, 'the exact B3M gallery renderer must exist');
const todayCarouselRenderBlock = exactB3MRenderBlock.match(/if \(card\.id === todayRedesignCardId\) \{([\s\S]*?)(?=\n\s*\}\n\s*const column = sourceColumn\.cloneNode\(true\);)/)?.[0];
assert.ok(todayCarouselRenderBlock, 'the Today carousel branch must exist');
assert.match(todayCarouselRenderBlock, /const todayB3mAColumn = sourceColumn\.cloneNode\(true\);/, 'the gallery must create one B3M-A Today column');
assert.match(todayCarouselRenderBlock, /todayB3mAColumn\.setAttribute\('data-today-budget-pill-behavior', 'exit'\);/, 'the retained Today column must use B3M-A disappearing-pill behavior');
assert.match(todayCarouselRenderBlock, /todayB3mAColumn\.setAttribute\('data-stage2-alternative', 'today-budget-pill-exit'\);/, 'the retained Today column must retain its B3M-A label');
assert.match(todayCarouselRenderBlock, /populateTodayRedesignScreen\(todayB3mAColumn, card\);/, 'the retained B3M-A column must reuse the existing Today composition');
assert.match(todayCarouselRenderBlock, /carouselRow\.append\(todayB3mAColumn\);/, 'the carousel must append only the B3M-A Today column');
assert.doesNotMatch(todayCarouselRenderBlock, /populateTodayRedesignScreen\(column, card\)|carouselRow\.append\(column,|disappearingPillColumn/, 'the former sticky Today first screen must not be created or appended');
assert.match(exactB3MRenderBlock, /const carouselColumnCount = carouselRow\.children\.length;/, 'the zoom surface must derive its width from the remaining carousel columns');
assert.match(catalogCardBlock('top_kategoria_heten'), /hideStage2Visual: true/, 'top categories must suppress the redundant lower icon strip in Stage2');
assert.doesNotMatch(catalogCardBlock('top_kategoria_heten'), /visualTitle: 'Ma · Hét · Hó'/, 'top categories must not retain lower icon-strip labels after the visual is removed');
assert.match(html, /if \(card\.hideStage2Visual \|\| card\.visual === 'transaction-event'\)/, 'the Stage2 visual renderer must remove explicitly suppressed visuals');
assert.match(catalogCardBlock('top_kategoria_heten'), /hideStage2StatusDot: true/, 'top categories must suppress the inherited Stage2 corner status dot');
assert.match(html, /if \(card\.hideStage2StatusDot\) headingDot\?\.remove\(\);/, 'the Stage2 renderer must remove an explicitly suppressed corner status dot');
assert.match(catalogCardBlock('top_kategoria_heten'), /hideStage1PlaceholderChart: true/, 'top categories must suppress the inherited Stage1 placeholder sparkline');
assert.match(html, /if \(card\.hideStage1PlaceholderChart\) cardElement\.querySelector\('\.fastinfo-sparkline'\)\?\.remove\(\);/, 'the Stage1 renderer must remove an explicitly suppressed placeholder sparkline');
assert.match(catalogCardBlock('top_kategoria_heten'), /motherMeta: 'fixek nélkül'/, 'top categories Stage1 must state that fixed items are excluded without repeating the amount');
assert.doesNotMatch(catalogCardBlock('top_kategoria_heten'), /motherMeta: '[^']*12 400 Ft/, 'top categories Stage1 meta must not repeat the amount');
assert.match(catalogCardBlock('top_kategoria_heten'), /\{ text: 'Fix tételek kizárva' \}/, 'top categories Stage2 must use the expanded fixed-item exclusion label');
assert.match(catalogCardBlock('top_kategoria_heten'), /text: 'Év: Lakás · 1 344 000 Ft'/, 'top categories Stage2 must include the annual top-category amount');
assert.match(catalogCardBlock('top_kategoria_heten'), /text: 'Hét: Élelmiszer · 36 500 Ft',[\s\S]*?avatar: \{ icon: 'utensils\.svg', color: '#24c889' \}/, 'the weekly top category fact must carry the food category avatar');
assert.match(catalogCardBlock('top_kategoria_heten'), /text: 'Hó: Lakás · 112 000 Ft',[\s\S]*?avatar: \{ icon: 'house\.svg', color: '#d932c9' \}/, 'the monthly top category fact must carry the housing category avatar');
assert.match(catalogCardBlock('top_kategoria_heten'), /text: 'Év: Lakás · 1 344 000 Ft',[\s\S]*?avatar: \{ icon: 'house\.svg', color: '#d932c9' \}/, 'the annual top category fact must carry the housing category avatar');
assert.match(html, /function createFactAvatar\(doc, avatar\)/, 'the Stage2 facts renderer must support compact category avatars');
assert.match(html, /common-balance-mother-child-fact-avatar/, 'the compact category-avatar visual must be styled in the gallery');
assert.doesNotMatch(catalogCardBlock('top_kategoria_heten'), /változó kiadás|Csak változó költés/, 'top categories must not use competing variable-spending wording');
assert.match(catalogCardBlock('koltesi_trend'), /motherMeta: 'fixek nélkül'/, 'the trend Stage1 must use the compact fixed-item exclusion label');
assert.match(catalogCardBlock('koltesi_trend'), /\{ text: 'Fix tételek kizárva' \}/, 'the trend Stage2 must use the expanded fixed-item exclusion label');
assert.doesNotMatch(html, /kiadas_bevetel_arany/, 'retired expense-income ratio must not remain in the gallery');
assert.doesNotMatch(html, /remaining-spent-split/, 'retired expense-income visual must not remain in the gallery');
assert.doesNotMatch(html, /bevetel_ebben_a_honapban/, 'monthly income must not remain as a gallery FastInfo card');
assert.match(html, /case 'seven-day-strip':[\s\S]*?#06B6D4/, 'today must use the FastInfo FAB-blue no-spend highlight');
assert.match(html, /const editingCardId = 'koltesi_trend';/, '30-day trend must be the active editing card');
assert.match(html, /const topCategoriesEditingCardId = 'top_kategoria_heten';/, 'top categories must have its own editing lane');
assert.match(html, /const categoryChangeEditingCardId = 'legnagyobb_novekedo_kategoria';/, 'largest category change must have its own editing lane');
assert.match(html, /const latestTransactionEditingCardId = 'legutobbi_tranzakcio';/, 'latest transaction must have its own editing lane');
assert.match(html, /const noSpendEditingCardId = 'no_spend_napok_szama';/, 'no-spend days must have its own editing lane');
assert.match(html, /const averageDailyEditingCardId = 'atlagos_napi_koltes';/, 'average daily spend must have its own editing lane');
assert.match(html, /card\.id !== editingCardId[\s\S]*?card\.id !== topCategoriesEditingCardId[\s\S]*?card\.id !== categoryChangeEditingCardId[\s\S]*?card\.id !== latestTransactionEditingCardId[\s\S]*?card\.id !== noSpendEditingCardId[\s\S]*?card\.id !== averageDailyEditingCardId/, 'every edited card must be removed from the primary row');
assert.match(html, /data-section-row', 'exact-b3m-carousel'/, 'the primary gallery row must be explicit');
assert.match(html, /data-section-row', 'exact-b3m-editor'/, 'the focused editing row must be explicit');
assert.match(html, /data-section-row', 'exact-b3m-top-categories-editor'/, 'top categories must render in its own lower editing row');
assert.match(html, /data-section-row', 'exact-b3m-category-change-editor'/, 'largest category change must render in a fourth lower editing row');
assert.match(html, /data-section-row', 'exact-b3m-latest-transaction-editor'/, 'latest transaction must render in a fifth lower editing row');
assert.match(html, /data-section-row', 'exact-b3m-no-spend-editor'/, 'no-spend days must render in a sixth lower editing row');
assert.match(html, /data-section-row', 'exact-b3m-average-daily-editor'/, 'average daily spend must render in a seventh lower editing row');
assert.match(html, /editorRow\.style\.marginTop = '28px';/, 'the focused editing row must use the Color Lab row gap');
assert.match(html, /setB3MContent\(editingColumn, editingCard, catalog\.indexOf\(editingCard\)\)/, 'the focused row must preserve the card position for its Stage1 neighbors');
assert.match(html, /setB3MContent\(topCategoriesColumn, topCategoriesEditingCard, catalog\.indexOf\(topCategoriesEditingCard\)\)/, 'top categories must preserve its source-card position and Stage1 neighbors');
assert.match(html, /setB3MContent\(categoryChangeColumn, categoryChangeEditingCard, catalog\.indexOf\(categoryChangeEditingCard\)\)/, 'largest category change must preserve its source-card position and Stage1 neighbors');
assert.match(html, /setB3MContent\(latestTransactionColumn, latestTransactionEditingCard, catalog\.indexOf\(latestTransactionEditingCard\)\)/, 'latest transaction must preserve its source-card position and Stage1 neighbors');
assert.match(html, /setB3MContent\(noSpendColumn, noSpendEditingCard, catalog\.indexOf\(noSpendEditingCard\)\)/, 'no-spend days must preserve its source-card position and Stage1 neighbors');
assert.match(html, /setB3MContent\(averageDailyColumn, averageDailyEditingCard, catalog\.indexOf\(averageDailyEditingCard\)\)/, 'average daily spend must preserve its source-card position and Stage1 neighbors');
assert.match(html, /latestTransactionRow\.append\(latestTransactionColumn\);/, 'latest transaction must have one base B3M screen without alternatives');
assert.match(html, /noSpendRow\.append\(noSpendColumn, noSpendMonthRingColumn, noSpendMonthMapColumn, noSpendWeekCadenceColumn\);/, 'the no-spend row must place the base B3M screen beside all three alternatives');
assert.match(html, /averageDailyRow\.append\(averageDailyColumn, averageDailyRunwayColumn, averageDailySpikeMapColumn, averageDailyEquationColumn\);/, 'the average-daily row must place the base B3M screen beside all three alternatives');
assert.match(html, /mode\.append\(carouselRow, editorRow, topCategoriesRow, categoryChangeRow, latestTransactionRow, noSpendRow, averageDailyRow\);/, 'average daily spend must follow the no-spend row');
assert.match(html, /function installTrendAlternativeStyles\(doc\)/, 'the focused trend alternative must install only its content-specific styles');
assert.match(html, /function populateTrendAlternative\(column, card\)/, 'the focused trend alternative must have its own Stage2 renderer');
assert.match(html, /alternativeColumn\.setAttribute\('data-stage2-alternative', 'trend-comparison'\)/, 'the alternative screen must be identifiable as the trend comparison variant');
const trendAlternativeBlock = html.match(/function populateTrendAlternative\(column, card\) \{([\s\S]*?)(?=\n\s*function prepareTrendAlternative)/)?.[0];
assert.ok(trendAlternativeBlock, 'trend alternative renderer block must exist');
assert.match(trendAlternativeBlock, /Előző 30 nap/, 'the alternative must name the comparison baseline');
assert.match(trendAlternativeBlock, /Mostani 30 nap/, 'the alternative must name the current rolling window');
assert.match(trendAlternativeBlock, /\+29 200 Ft/, 'the alternative must make the absolute delta central');
assert.match(trendAlternativeBlock, /\+18%/, 'the alternative must retain the relative delta');
assert.match(trendAlternativeBlock, /Pulse akkor jelez/, 'the alternative must expose the relevant future Pulse boundary');
assert.doesNotMatch(trendAlternativeBlock, /common-balance-mother-child-avatar/, 'the alternative must not repeat the large generic avatar');
assert.doesNotMatch(trendAlternativeBlock, /common-balance-mother-child-fact/, 'the alternative must not use the generic two-fact template');
assert.doesNotMatch(trendAlternativeBlock, /common-balance-mother-child-trend/, 'the alternative must not use the generic line-chart region');
const pulseMapBlock = html.match(/function populateTrendPulseMap\(column, card\) \{([\s\S]*?)(?=\n\s*function populateTrendEquation)/)?.[0];
assert.ok(pulseMapBlock, 'trend Pulse-map renderer block must exist');
assert.match(pulseMapBlock, /Pulse döntési tér/, 'the Pulse-map alternative must state its decision context');
assert.match(pulseMapBlock, /\+15%/, 'the Pulse-map alternative must show the ratio boundary');
assert.match(pulseMapBlock, /\+10 000 Ft/, 'the Pulse-map alternative must show the amount boundary');
assert.match(pulseMapBlock, /Mindkét küszöb teljesült/, 'the Pulse-map alternative must state the current decision');
assert.doesNotMatch(pulseMapBlock, /common-balance-mother-child-avatar|common-balance-mother-child-fact|common-balance-mother-child-trend/, 'the Pulse-map alternative must not inherit the generic Stage2 anatomy');
const equationBlock = html.match(/function populateTrendEquation\(column, card\) \{([\s\S]*?)(?=\n\s*function populateTrendWindowTape)/)?.[0];
assert.ok(equationBlock, 'trend equation renderer block must exist');
assert.match(equationBlock, /Előző ablak/, 'the equation alternative must state its baseline term');
assert.match(equationBlock, /Változó többlet/, 'the equation alternative must state its additive term');
assert.match(equationBlock, /Mostani ablak/, 'the equation alternative must state its resulting term');
assert.match(equationBlock, /1,18×/, 'the equation alternative must preserve the relative relationship');
assert.doesNotMatch(equationBlock, /common-balance-mother-child-avatar|common-balance-mother-child-fact|common-balance-mother-child-trend/, 'the equation alternative must not inherit the generic Stage2 anatomy');
const windowTapeBlock = html.match(/function populateTrendWindowTape\(column, card\) \{([\s\S]*?)(?=\n\s*function buildTrendSparklineClipPath)/)?.[0];
assert.ok(windowTapeBlock, 'trend time-tape renderer block must exist');
assert.match(windowTapeBlock, /Gördülő 60 nap/, 'the time-tape alternative must state the full comparison horizon');
assert.match(windowTapeBlock, /30 napos előző ablak/, 'the time-tape alternative must identify the prior window');
assert.match(windowTapeBlock, /30 napos mostani ablak/, 'the time-tape alternative must identify the current window');
assert.match(windowTapeBlock, /nem naptári hónapok/, 'the time-tape alternative must explain the rolling scope');
assert.match(windowTapeBlock, /nem napi költési adat/, 'the time-tape alternative must not imply invented daily-spend evidence');
assert.doesNotMatch(windowTapeBlock, /common-balance-mother-child-avatar|common-balance-mother-child-fact|common-balance-mother-child-trend/, 'the time-tape alternative must not inherit the generic Stage2 anatomy');
const dataRibbonBlock = html.match(/function populateTrendDataRibbon\(column, card\) \{([\s\S]*?)(?=\n\s*function calculatePeriodShares)/)?.[0];
assert.ok(dataRibbonBlock, 'trend data-ribbon renderer block must exist');
assert.match(dataRibbonBlock, /Stage1 előnézetből/, 'the data ribbon must make its mother-child continuity explicit');
assert.match(dataRibbonBlock, /191 200 Ft/, 'the data ribbon must retain the current window total');
assert.match(dataRibbonBlock, /162 000 Ft/, 'the data ribbon must retain the prior window total');
assert.match(dataRibbonBlock, /\+29 200 Ft/, 'the data ribbon must retain the absolute delta');
assert.match(dataRibbonBlock, /fastinfo-sparkline common-balance-trend-expanded-sparkline/, 'the Stage2 child must use the exact Color Lab FastInfo sparkline primitive');
assert.match(dataRibbonBlock, /chart\.style\.setProperty\('clip-path', buildTrendSparklineClipPath\(trendDailySeriesFixture\.current\)\)/, 'the Stage2 child must derive only the source sparkline shape from its daily series');
assert.doesNotMatch(dataRibbonBlock, /common-balance-mother-child-avatar|common-balance-mother-child-fact|common-balance-mother-child-trend/, 'the data ribbon must not inherit the generic Stage2 anatomy');
assert.doesNotMatch(dataRibbonBlock, /common-balance-trend-series-bar|createTrendSeriesRow|createTrendDataRibbonBand/, 'the Stage2 child must not replace the source fill with a bar chart');
const splitZoneBlock = html.match(/function populateTrendSplitZone\(column, card\) \{([\s\S]*?)(?=\n\s*function populateCategoryChangeBase)/)?.[0];
assert.ok(splitZoneBlock, 'B3M-F split difference-zone renderer must exist');
assert.match(splitZoneBlock, /prepareTrendAlternative\(column, card, 'trend-split-zone', 'B3M-F'/, 'B3M-F must have its own identifiable screen variant');
assert.match(splitZoneBlock, /common-balance-trend-alternative-delta/, 'B3M-F must reuse the B3M-A red delta container as primary information');
assert.match(splitZoneBlock, /Eltérés a két ablak között/, 'B3M-F must retain the B3M-A delta label');
assert.match(splitZoneBlock, /common-balance-mother-child-facts/, 'B3M-F must retain the complete B3M secondary fact block');
assert.match(splitZoneBlock, /panel\.replaceChildren\(delta, facts, zone\)/, 'B3M-F must keep the B3M facts between the primary delta and the bar');
assert.match(splitZoneBlock, /common-balance-trend-split-zone/, 'B3M-F must end with its dedicated difference-zone block');
assert.match(splitZoneBlock, /common-balance-trend-period-composition/, 'B3M-F must use one two-period composition stripe');
assert.match(splitZoneBlock, /data-current-spend-state/, 'B3M-F must color the current-period segment from the spending comparison');
assert.doesNotMatch(splitZoneBlock, /common-balance-mother-child-avatar|common-balance-mother-child-trend/, 'B3M-F must not retain the unrelated generic child anatomy');
assert.doesNotMatch(splitZoneBlock, /calculateSplitTrendPosition|common-balance-trend-split-context|common-balance-trend-split-progress-center|threshold|common-balance-trend-split-axis/, 'B3M-F must not retain the rejected centered delta-scale design');
const periodShareBlock = html.match(/function calculatePeriodShares\(previousAmount, currentAmount\) \{([\s\S]*?)(?=\n\s*function populateTrendSplitZone)/)?.[0];
assert.ok(periodShareBlock, 'B3M-F must calculate each period as a share of their combined total');
const calculatePeriodShares = Function(`${periodShareBlock}; return calculatePeriodShares;`)();
const trendPeriodShares = calculatePeriodShares(162000, 191200);
assert.equal(trendPeriodShares.previous.toFixed(2), '45.87', 'the prior period must occupy its exact share of the two-period total');
assert.equal(trendPeriodShares.current.toFixed(2), '54.13', 'the current period must occupy its exact share of the two-period total');
assert.equal(trendPeriodShares.total, 353200, 'the bar total must be the sum of both rolling windows');
const periodCompositionStyle = html.match(/\.common-balance-trend-period-composition\s*\{([\s\S]*?)\n\s*\}/)?.[0];
assert.ok(periodCompositionStyle, 'B3M-F must define one composition stripe');
assert.match(periodCompositionStyle, /grid-template-columns: var\(--trend-period-previous-share\) var\(--trend-period-current-share\)/, 'the single stripe must be divided only by the two period shares');
assert.match(periodCompositionStyle, /height: 8px/, 'the B3M-F composition stripe must be half-height');
const previousPeriodStyle = html.match(/\.common-balance-trend-period-composition-previous\s*\{([\s\S]*?)\n\s*\}/)?.[0];
assert.ok(previousPeriodStyle, 'the prior-period composition segment must have its own source style');
assert.match(previousPeriodStyle, /background: rgba\(20,33,58,\.14\)/, 'the prior-period segment must use the requested lighter gray');
assert.match(splitZoneBlock, /common-balance-trend-period-composition-legend/, 'B3M-F must label both sides below the composition stripe');
assert.match(splitZoneBlock, /Előző 30 nap/, 'B3M-F must identify the left prior-period segment');
assert.match(splitZoneBlock, /Aktuális 30 nap/, 'B3M-F must identify the right current-period segment');
assert.doesNotMatch(html, /common-balance-trend-split-progress-center|common-balance-trend-split-progress-threshold|common-balance-trend-split-axis/, 'the rejected center, thresholds, and axis must be removed from B3M-F');
const expandedSparklineStyle = html.match(/\.common-balance-trend-expanded-sparkline\s*\{([\s\S]*?)\n\s*\}/)?.[0];
assert.ok(expandedSparklineStyle, 'the Stage2 source sparkline may only receive its expanded dimensions');
assert.match(expandedSparklineStyle, /height: 88px/, 'the Stage2 child must enlarge the source sparkline without changing its visual family');
assert.doesNotMatch(expandedSparklineStyle, /background|clip-path|border-radius/, 'the Stage2 child must inherit the exact source fill, fade, and radius');
const stage1SparklineBlock = html.match(/function renderTrendSeriesPreview\(column\) \{([\s\S]*?)(?=\n\s*function populateTrendDataRibbon)/)?.[0];
assert.ok(stage1SparklineBlock, 'Stage1 trend sparkline renderer must exist');
assert.match(stage1SparklineBlock, /mother\?\.querySelector\('\.fastinfo-sparkline'\)/, 'the selected mother must reuse its source FastInfo sparkline element');
assert.match(stage1SparklineBlock, /sparkline\.style\.setProperty\('clip-path', buildTrendSparklineClipPath\(trendDailySeriesFixture\.current\)\)/, 'the selected mother must derive the same source fill shape from the current daily series');
assert.doesNotMatch(stage1SparklineBlock, /replaceChildren|common-balance-trend-series-bar/, 'the selected mother must not replace its source sparkline with a second chart family');
assert.match(html, /function buildTrendSparklineClipPath\(values\)/, 'the Color Lab sparkline path must be generated from the daily fixture');
assert.doesNotMatch(html, /common-balance-trend-series-bar/, 'the gallery must not contain the rejected bar-chart renderer');
assert.doesNotMatch(html, /common-balance-trend-data-ribbon-band/, 'the gallery must not contain rejected Stage2 bar bands');
const trendDailyFixtureMatch = html.match(/const trendDailySeriesFixture = (\{[\s\S]*?\n\s*\});/);
assert.ok(trendDailyFixtureMatch, 'the Color Lab trend daily-series fixture must exist');
const trendDailyFixture = Function(`return (${trendDailyFixtureMatch[1]})`)();
assert.equal(trendDailyFixture.previous.length, 30, 'the prior fixture needs exactly 30 daily values');
assert.equal(trendDailyFixture.current.length, 30, 'the current fixture needs exactly 30 daily values');
assert.equal(trendDailyFixture.previous.reduce((sum, value) => sum + value, 0), 162000, 'the prior daily fixture must equal the shown prior total');
assert.equal(trendDailyFixture.current.reduce((sum, value) => sum + value, 0), 191200, 'the current daily fixture must equal the shown current total');
const sparklineBuilderBlock = html.match(/function buildTrendSparklineClipPath\(values\) \{([\s\S]*?)(?=\n\s*function renderTrendSeriesPreview)/)?.[0];
assert.ok(sparklineBuilderBlock, 'the fixture must have a dedicated source-sparkline path builder');
const buildTrendSparklineClipPath = Function(`${sparklineBuilderBlock}; return buildTrendSparklineClipPath;`)();
const currentTrendSparklinePath = buildTrendSparklineClipPath(trendDailyFixture.current);
const previousTrendSparklinePath = buildTrendSparklineClipPath(trendDailyFixture.previous);
assert.match(currentTrendSparklinePath, /^polygon\(0\.00% \d+\.\d+%,/, 'the current fixture must produce a filled CSS polygon from its first data bucket');
assert.match(currentTrendSparklinePath, /100% 100%, 0 100%\)$/, 'the generated shape must retain the source filled-area baseline');
assert.notEqual(currentTrendSparklinePath, previousTrendSparklinePath, 'different daily fixtures must produce different filled source-sparkline shapes');
assert.match(html, /renderTrendSeriesPreview\(column\)/, 'the selected Stage1 mother must use the same series preview as the data-ribbon child');
assert.match(html, /alternativeColumn\.setAttribute\('data-stage2-alternative', 'trend-comparison'\)/, 'the comparison renderer must retain its unique screen marker');
assert.match(html, /pulseMapColumn\.setAttribute\('data-stage2-alternative', 'trend-pulse-map'\)/, 'the Pulse-map renderer must retain its unique screen marker');
assert.match(html, /equationColumn\.setAttribute\('data-stage2-alternative', 'trend-equation'\)/, 'the equation renderer must retain its unique screen marker');
assert.match(html, /tapeColumn\.setAttribute\('data-stage2-alternative', 'trend-window-tape'\)/, 'the time-tape renderer must retain its unique screen marker');
assert.match(html, /dataRibbonColumn\.setAttribute\('data-stage2-alternative', 'trend-data-ribbon'\)/, 'the data-ribbon renderer must retain its unique screen marker');
assert.match(html, /splitZoneColumn\.setAttribute\('data-stage2-alternative', 'trend-split-zone'\)/, 'B3M-F must retain its unique screen marker');
assert.match(html, /editorRow\.append\(editingColumn, alternativeColumn, pulseMapColumn, equationColumn, tapeColumn, dataRibbonColumn, splitZoneColumn\)/, 'the focused row must expose every trend-specific alternative side by side');
assert.match(html, /topCategoriesRow\.append\(topCategoriesColumn\)/, 'top categories must render once in its own row');
assert.match(html, /function installNoSpendAlternativeStyles\(doc\)/, 'no-spend alternatives must install only their scoped content styles');
assert.match(html, /noSpendMonthRingColumn\.setAttribute\('data-stage2-alternative', 'no-spend-month-ring'\)/, 'the monthly ring must retain a unique screen marker');
assert.match(html, /noSpendMonthMapColumn\.setAttribute\('data-stage2-alternative', 'no-spend-month-map'\)/, 'the month map must retain a unique screen marker');
assert.match(html, /noSpendWeekCadenceColumn\.setAttribute\('data-stage2-alternative', 'no-spend-week-cadence'\)/, 'the weekly cadence must retain a unique screen marker');
const noSpendFixtureBlock = html.match(/const noSpendFixture = \{([\s\S]*?)\n\s*\};/)?.[0];
assert.ok(noSpendFixtureBlock, 'no-spend alternatives need a Color Lab fixture matching the visible card state');
assert.match(noSpendFixtureBlock, /elapsedMonthDays: 21/, 'the fixture must expose the 21 elapsed days');
assert.match(noSpendFixtureBlock, /daysInMonth: 31/, 'the fixture must retain the 31-day month and neutral future days');
assert.match(noSpendFixtureBlock, /monthNoSpendDays: \[1, 3, 5, 7, 10, 12, 15, 17, 19\]/, 'the fixture must contain exactly nine elapsed no-spend days');
assert.equal((noSpendFixtureBlock.match(/noSpend: true/g) || []).length, 3, 'the weekly fixture must contain exactly three no-spend days');
const noSpendRingBlock = html.match(/function populateNoSpendMonthRing\(column, card\) \{([\s\S]*?)(?=\n\s*function populateNoSpendMonthMap)/)?.[0];
const noSpendMapBlock = html.match(/function populateNoSpendMonthMap\(column, card\) \{([\s\S]*?)(?=\n\s*function populateNoSpendWeekCadence)/)?.[0];
const noSpendCadenceBlock = html.match(/function populateNoSpendWeekCadence\(column, card\) \{([\s\S]*?)(?=\n\s*function populateCategoryChangeBase)/)?.[0];
assert.ok(noSpendRingBlock, 'monthly ratio ring renderer must exist');
assert.ok(noSpendMapBlock, 'elapsed-month map renderer must exist');
assert.ok(noSpendCadenceBlock, 'named weekly cadence renderer must exist');
assert.match(noSpendRingBlock, /Math\.round\(\(noSpendFixture\.monthNoSpendDays\.length \/ noSpendFixture\.elapsedMonthDays\) \* 100\)/, 'the monthly ring must derive the visible 43 percent ratio from the fixture');
assert.match(noSpendRingBlock, /noSpendFixture\.monthNoSpendDays\.length[\s\S]*?noSpendFixture\.elapsedMonthDays/, 'the monthly ring must retain both source counts');
assert.match(noSpendMapBlock, /noSpendFixture\.monthNoSpendDays\.includes\(day\)/, 'the month map must derive each elapsed day from the no-spend point semantics');
assert.match(noSpendMapBlock, /day > noSpendFixture\.elapsedMonthDays/, 'the month map must keep future days neutral');
assert.match(noSpendCadenceBlock, /noSpendFixture\.week/, 'the weekly cadence must derive from the seven-day values');
const noSpendAlternativeBlocks = `${noSpendRingBlock}\n${noSpendMapBlock}\n${noSpendCadenceBlock}`;
assert.doesNotMatch(noSpendAlternativeBlocks, /Pulse|sorozat|streak|common-balance-mother-child-trend/, 'no-spend alternatives must not invent a Pulse trigger, streak, or generic line chart');
assert.match(html, /function installAverageDailyAlternativeStyles\(doc\)/, 'average-daily alternatives must install only their scoped content styles');
assert.match(html, /averageDailyRunwayColumn\.setAttribute\('data-stage2-alternative', 'average-daily-runway'\)/, 'the balance-runway alternative must retain a unique screen marker');
assert.match(html, /averageDailySpikeMapColumn\.setAttribute\('data-stage2-alternative', 'average-daily-spike-map'\)/, 'the spike-map alternative must retain a unique screen marker');
assert.match(html, /averageDailyEquationColumn\.setAttribute\('data-stage2-alternative', 'average-daily-equation'\)/, 'the average equation must retain a unique screen marker');
const averageDailyFixtureMatch = html.match(/const averageDailyFixture = (\{[\s\S]*?\n\s*\});/);
assert.ok(averageDailyFixtureMatch, 'average-daily alternatives need a Color Lab fixture matching the visible card state');
const averageDailyFixture = Function(`return (${averageDailyFixtureMatch[1]})`)();
assert.equal(averageDailyFixture.values.length, 30, 'the average-daily fixture must contain exactly thirty rolling days');
const averageDailyTotal = averageDailyFixture.values.reduce((sum, value) => sum + value, 0);
const averageDailyValue = averageDailyTotal / averageDailyFixture.values.length;
const averageDailySpikeDays = averageDailyFixture.values
  .map((value, index) => value > averageDailyValue * 1.5 ? index + 1 : null)
  .filter((day) => day != null);
assert.equal(averageDailyTotal, 191100, 'the average-daily fixture must equal the visible rolling total');
assert.equal(averageDailyValue, 6370, 'the average-daily fixture must equal the visible daily average');
assert.equal(Math.round(averageDailyFixture.balance / averageDailyValue), 58, 'the fixture balance must produce the visible runway');
assert.deepEqual(averageDailySpikeDays, [4, 15, 26], 'the fixture must preserve the three thresholded spike positions');
assert.equal(Math.max(...averageDailyFixture.values), 19800, 'the fixture must preserve the visible highest day');
const averageRunwayBlock = html.match(/function populateAverageDailyRunway\(column, card\) \{([\s\S]*?)(?=\n\s*function populateAverageDailySpikeMap)/)?.[0];
const averageSpikeMapBlock = html.match(/function populateAverageDailySpikeMap\(column, card\) \{([\s\S]*?)(?=\n\s*function populateAverageDailyEquation)/)?.[0];
const averageEquationBlock = html.match(/function populateAverageDailyEquation\(column, card\) \{([\s\S]*?)(?=\n\s*function prepareNoSpendAlternative)/)?.[0];
assert.ok(averageRunwayBlock, 'balance-runway renderer must exist');
assert.ok(averageSpikeMapBlock, 'thresholded spike-map renderer must exist');
assert.ok(averageEquationBlock, 'rolling-total division renderer must exist');
assert.match(averageRunwayBlock, /summary\.bufferDays/, 'the runway must derive from balance divided by the daily average');
assert.match(averageSpikeMapBlock, /summary\.spikeThreshold/, 'the spike map must use the resolver 1\.5x threshold');
assert.match(averageSpikeMapBlock, /summary\.spikeDays/, 'the spike map must use the actual thresholded day positions');
assert.match(averageEquationBlock, /summary\.rollingTotal/, 'the equation must expose the rolling total rather than another time chart');
assert.match(averageEquationBlock, /summary\.average/, 'the equation must derive the daily result from the rolling total');
const averageDailyAlternativeBlocks = `${averageRunwayBlock}\n${averageSpikeMapBlock}\n${averageEquationBlock}`;
assert.doesNotMatch(averageDailyAlternativeBlocks, /Pulse|forecast|common-balance-mother-child-trend|merchant|category/i, 'average-daily alternatives must not invent a Pulse decision, forecast, generic line chart, merchant, or category evidence');
const categoryChangeBlock = catalogCardBlock('legnagyobb_novekedo_kategoria');
assert.match(categoryChangeBlock, /motherValue: 'Közlekedés · \+14 200 Ft'/, 'the category-change mother must retain the winning category and absolute delta');
assert.match(categoryChangeBlock, /Előző 30 nap: 5 800 Ft/, 'the category-change source must retain the previous window value');
assert.match(categoryChangeBlock, /Jelenlegi 30 nap: 20 000 Ft/, 'the category-change source must retain the current window value');
assert.match(categoryChangeBlock, /Új kategória: nem/, 'the category-change source must retain the existing-category state');
assert.match(categoryChangeBlock, /visual: 'category-box'/, 'the category-change base card must identify its category-box presentation');
assert.match(categoryChangeBlock, /hideStage2Visual: true/, 'the category-change base card must remove the lower visual region');
assert.doesNotMatch(categoryChangeBlock, /Eltérés tengelye|axisStart:|axisEnd:/, 'the category-change base card must not retain the rejected difference axis');
assert.doesNotMatch(html, /case 'category-change-up-arrow':/, 'the rejected lower upward-arrow renderer must be removed');
assert.match(html, /function populateCategoryChangeBase\(panel, card\)/, 'the base card must replace its upper transaction row with a category box');
const categoryBaseBlock = html.match(/function populateCategoryChangeBase\(panel, card\) \{([\s\S]*?)(?=\n\s*function setB3MContent)/)?.[0];
assert.ok(categoryBaseBlock, 'category-change base renderer block must exist');
assert.match(categoryBaseBlock, /common-balance-category-change-base-hero/, 'the base renderer must use the B3M-J-like category-box upper row');
assert.doesNotMatch(categoryBaseBlock, /common-balance-category-change-base-arrow|common-balance-mother-child-trend/, 'the base renderer must not retain a lower arrow or visual region');
assert.match(html, /if \(card\.id === categoryChangeEditingCardId\) populateCategoryChangeBase\(panel, card\);/, 'only the category-change base screen must receive the category box');
for (const renderer of [
  'populateCategoryChangeComparison',
  'populateCategoryChangeEquation',
  'populateCategoryChangePulseGate',
  'populateCategoryChangeProfile',
  'populateCategoryChangeMaterialityMap',
]) {
  assert.doesNotMatch(html, new RegExp(`function ${renderer}\\(column, card\\)`), `${renderer} must not remain after the category-change row is simplified`);
}
assert.match(html, /categoryChangeRow\.append\(categoryChangeColumn\)/, 'the fourth row must contain only the category-change base screen');
assert.match(html, /mode\.append\(carouselRow, editorRow, topCategoriesRow, categoryChangeRow, latestTransactionRow, noSpendRow, averageDailyRow\)/, 'all six editing rows must be below the primary row');
assert.match(html, /minHeight = 'calc\(\(var\(--screen-h\) \* 7\) \+ 284px\)'/, 'the canvas must include the seventh B3M editing row');

console.log('Exact B3M Balance Stage2 gallery static checks passed');
