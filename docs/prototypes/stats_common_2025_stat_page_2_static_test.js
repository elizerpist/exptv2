const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const htmlPath = path.join(__dirname, 'stats_common_2025_stat_page_2.html');
assert.ok(fs.existsSync(htmlPath), 'stats_common_2025_stat_page_2.html should exist');

const html = fs.readFileSync(htmlPath, 'utf8');

function contains(pattern, message) {
  assert.match(html, pattern, message);
}

function omits(pattern, message) {
  assert.doesNotMatch(html, pattern, message);
}

const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
assert.ok(scriptMatch, 'Page 2 HTML should contain one inline script block');
new vm.Script(scriptMatch[1]);
const yearSummaryTemplateMatch = html.match(/root\.innerHTML = `([\s\S]*?)`;/);
assert.ok(yearSummaryTemplateMatch, 'Page 2 should render the year summary from a dedicated template');
const yearSummaryTemplate = yearSummaryTemplateMatch[1];

contains(/<title>Közös stat 2025 - 2\. oldal<\/title>/, 'Page 2 should use Hungarian browser title copy');
contains(/<div class="app-title">Pénzfigyelő<\/div>/, 'Page 2 should use Hungarian app title copy');
contains(/<button class="chip" id="scopeChip" type="button" aria-label="aktív szűrés">MIND<\/button>/, 'Page 2 should use Hungarian all-scope chip copy');
contains(/<div class="header-label">SZŰRÉS PONTSZÁM<\/div>/, 'Page 2 should use Hungarian header score copy');
contains(/aria-label="szűrés menü"/, 'Page 2 should use Hungarian scope menu aria copy');
contains(/<section class="scope-selector" id="scopeSelector"/, 'Page 2 should preserve category scope filtering');
contains(/<input id="slider" type="range"/, 'Page 2 should preserve the threshold joystick slider');
contains(/id="incomeBtn"/, 'Page 2 should preserve income mode toggle');
contains(/id="expenseBtn"/, 'Page 2 should preserve expense mode toggle');
contains(/const incomeMonthPlans = \[/, 'Page 2 should preserve the approved income mock data');
contains(/function buildTransactions\(\)/, 'Page 2 should preserve the transaction builder');

contains(/<section class="year-summary" id="yearSummary"/, 'Page 2 should render the year summary surface where month cards used to be');
omits(/<section class="month-grid" id="monthGrid"/, 'Page 2 should not keep the old month-card grid');
omits(/function drawMonthCards\(months\)/, 'Page 2 should not render month cards');
contains(/function drawYearSummary\(months\)/, 'Page 2 should have a dedicated year summary renderer');
contains(/drawYearSummary\(months\)/, 'render should update Page 2 year summary on every state change');
omits(/drawMonthCards\(months\)/, 'render should not call the month card renderer');

contains(/function yearSummaryRecords\(months\)/, 'Year summary should derive records from live month/transaction state');
omits(/function yearSummaryVendorRecords\(months\)/, 'Vendor summary should use the same dynamic thresholded records as the rest of the year summary');
contains(/activeType/, 'Year summary should use current income or expense mode');
contains(/activeScopeIds\.has\(record\.categoryId\)/, 'Year summary should honor the selected category scope');
contains(/record\.amount >= threshold/, 'Year summary should honor the threshold slider as a minimum event filter');
contains(/function yearSummaryMetrics\(months\)/, 'Year summary should compute KPI metrics dynamically');
contains(/function categoryShare\(records\)/, 'Year summary should compute category share data');
contains(/function topVendors\(records\)/, 'Year summary should compute vendor/source progress data');
contains(/function vendorForRecord\(record\)/, 'Year summary should derive deterministic mock vendors/sources from existing data');
contains(/function donutBackground\(segments\)/, 'Year summary should render a category donut/pie from computed segments');
contains(
  /const thresholdWarning = threshold > 0 \? `/,
  'Threshold warning should render only when the threshold slider is above zero',
);
contains(
  /\$\{formatCompactHuf\(threshold\)\} alatti tranzakciók rejtve/,
  'Threshold warning should use concise Hungarian copy that says transactions below the amount are hidden',
);
contains(
  /\.threshold-warning\s*\{[\s\S]*background:\s*#fffbeb[\s\S]*color:\s*#92400e/,
  'Threshold warning should use a yellow warning treatment',
);
contains(
  /\.threshold-warning-icon::before\s*\{[\s\S]*background:\s*#fbbf24[\s\S]*clip-path:\s*polygon/,
  'Threshold warning should include a yellow triangle icon',
);
assert.equal(
  (yearSummaryTemplate.match(/\$\{thresholdWarning\}/g) || []).length,
  3,
  'Threshold warning should appear above top stats, inside the category panel, and inside the Top 5 vendor/source panel',
);
contains(
  /const hasSingleCategoryScope = selectedScopeCategories\(\)\.length === 1;/,
  'Category panel should explicitly detect the single selected category state',
);
contains(
  /const showCategoryDonut = !hasSingleCategoryScope && metrics\.categories\.length > 1;/,
  'Category panel should hide the pie chart when only one category is selected or visible',
);

contains(/Kiadási éves statisztika/, 'Expense mode should have Hungarian expense-specific summary label text');
omits(/Szűrt kiadás/, 'Expense mode should not duplicate the filtered spend total from the summary pill');
contains(/Legnagyobb kiadás/, 'Expense mode should show Hungarian largest spend KPI');
contains(/Top 5 kereskedő/, 'Expense mode should label vendor progress bars as Top 5 in Hungarian');
contains(/Napi tranzakcióátlag/, 'Page 2 should show daily transaction average as its own stat');
contains(/Napi kiadásátlag/, 'Expense mode should show daily spend average as its own stat');
contains(/Költésmentes nap/, 'Expense mode should show no-spend days as its own stat');
omits(/Kereskedők száma/, 'Expense mode should not show unique vendor count as a top stat tile');
contains(/Átlagos kiadás/, 'Expense mode should show average event amount as its own stat');
contains(/Kategória rangsor/, 'Page 2 should show Hungarian category ranking');
contains(/Szűrt kategória/, 'Single-category scope should rename the category panel to filtered category');
omits(/Top kereskedő/, 'Expense mode should not duplicate the Top 5 vendor panel in a stat box');
contains(/Bevételi éves statisztika/, 'Income mode should have Hungarian income-specific summary label text');
omits(/Szűrt bevétel/, 'Income mode should not duplicate the filtered income total from the summary pill');
contains(/Legnagyobb bevétel/, 'Income mode should show Hungarian largest income KPI');
contains(/Top 5 forrás/, 'Income mode should label source progress bars as Top 5 in Hungarian');
contains(/Napi bevételátlag/, 'Income mode should show daily income average as its own stat');
contains(/Bevételmentes nap/, 'Income mode should show no-income days as its own stat');
omits(/Források száma/, 'Income mode should not show unique source count as a top stat tile');
contains(/Átlagos bevétel/, 'Income mode should show average income event amount as its own stat');
omits(/Top forrás/, 'Income mode should not duplicate the Top 5 source panel in a stat box');
contains(/Aktuális szűrés · 2025/, 'Page 2 should show Hungarian current filter copy');
assert.equal(
  (yearSummaryTemplate.match(/class="stat-tile"/g) || []).length,
  7,
  'Year summary should render seven separate stat tiles: three highlighted primary boxes and four lower secondary boxes',
);
contains(
  /<div class="kpi-strip">[\s\S]*\$\{copy\.averageLabel\}[\s\S]*\$\{copy\.largestLabel\}[\s\S]*\$\{copy\.topMonthLabel\}[\s\S]*<\/div>\s*<div class="metric-grid">/,
  'The top stat row should contain monthly average, largest item, and top month as three primary boxes',
);
contains(
  /<div class="metric-grid">[\s\S]*\$\{copy\.dailyTxLabel\}[\s\S]*\$\{copy\.dailyAmountLabel\}[\s\S]*\$\{copy\.zeroActivityLabel\}[\s\S]*\$\{copy\.averageEventLabel\}[\s\S]*<\/div>\s*<section class="summary-panel">/,
  'The lower stat rows should keep daily transaction average, daily amount average, no-activity days, and average event amount as separate boxes',
);
contains(
  /\.kpi-strip \.stat-tile\s*\{[\s\S]*min-height:\s*78px/,
  'Top-row stat boxes should be visibly larger than the lower stat boxes',
);
contains(
  /\.stat-tile\s*\{[\s\S]*min-width:\s*0/,
  'Stat tiles should allow grid tracks to keep the right-side page padding instead of overflowing horizontally',
);
contains(
  /\.stat-value\s*\{[\s\S]*white-space:\s*normal[\s\S]*overflow-wrap:\s*anywhere/,
  'Stat values should wrap and grow the tile vertically instead of forcing the tile wider',
);
contains(
  /<div class="stat-value stat-value-stack">\s*<span class="stat-main">\$\{largestAmountLabel\}<\/span>\s*<span class="stat-sub">\$\{largestDetailLabel\}<\/span>\s*<\/div>/,
  'Largest transaction top stat should split amount and detail into two lines when needed',
);
contains(
  /<div class="stat-value stat-value-stack">\s*<span class="stat-main">\$\{formatCompactHuf\(metrics\.topMonthAmount\)\}<\/span>\s*<span class="stat-sub">\$\{metrics\.topMonthName\}<\/span>\s*<\/div>/,
  'Top month stat should show amount on the first line and month name below',
);
contains(
  /\.share-layout\s*\{[\s\S]*justify-items:\s*center/,
  'Category pie layout should center the donut above the category rows',
);
omits(/grid-template-columns:\s*104px 1fr/, 'Category panel should not use the old side-by-side donut/list layout');
contains(/\.donut\s*\{[\s\S]*width:\s*208px/, 'Category pie chart should be twice the previous size');
contains(/\.donut::after\s*\{[\s\S]*inset:\s*52px/, 'Category donut inner cutout should scale with the doubled pie size');
contains(/\.share-list\s*\{[\s\S]*width:\s*100%/, 'Category rows should occupy their own full-width vertical list below the pie');
contains(
  /const categoryDonut = showCategoryDonut\s*\? `\s*<div class="donut" style="--donut-bg:\$\{donutBackground\(metrics\.categories\)\}"><\/div>\s*`\s*:\s*'';/,
  'Category donut markup should only be produced when the current scope needs a pie chart',
);
contains(
  /const categoryPanelTitle = hasSingleCategoryScope \? 'Szűrt kategória' : copy\.categoryTitle;/,
  'Single-category scope should use a filtered-category panel title instead of category ranking',
);
contains(
  /const categoryShareLabel = hasSingleCategoryScope \? '' : `<span>\$\{Math\.round\(item\.share \* 100\)\}%<\/span>`;/,
  'Single-category scope should suppress the redundant 100% share label beside the category row',
);
contains(
  /const emptyCategoryShareLabel = hasSingleCategoryScope \? '' : '<span>0%<\/span>';/,
  'Single-category empty state should also avoid a redundant percentage label',
);
contains(
  /<div class="share-layout\$\{showCategoryDonut \? '' : ' no-donut'\}">\s*\$\{categoryDonut\}\s*<div class="share-list">\$\{categoryRows\}<\/div>\s*<\/div>/,
  'Category rows should be rendered underneath the optional pie chart',
);
contains(
  /<div class="panel-title">\$\{categoryPanelTitle\}<\/div>/,
  'Category panel title should be computed from the current category scope',
);
contains(
  /<div class="panel-title">\$\{copy\.vendorTitle\} · \$\{metrics\.vendors\.length\} \/ \$\{metrics\.uniqueVendorCount\}<\/div>/,
  'Top 5 vendor/source panel title should show visible Top 5 count out of the filtered unique vendor/source count',
);
contains(/<div class="stat-label">\$\{copy\.topMonthLabel\}<\/div>/, 'Top month should be promoted into its own stat box');
contains(/<div class="stat-label">\$\{copy\.dailyTxLabel\}<\/div>/, 'Daily transaction average should remain as a standalone stat tile');
contains(/<div class="stat-label">\$\{copy\.dailyAmountLabel\}<\/div>/, 'Daily amount average should remain as a standalone stat tile');
contains(/<div class="stat-label">\$\{copy\.zeroActivityLabel\}<\/div>/, 'No-activity days should remain as a standalone stat tile');
contains(/<div class="stat-label">\$\{copy\.averageEventLabel\}<\/div>/, 'Average event amount should remain as a standalone stat tile');
omits(/<div class="stat-label">\$\{copy\.topVendorLabel\}<\/div>/, 'Top vendor should not be duplicated because the Top 5 panel shows it');
omits(/topVendorLabel|topVendor: vendors\[0\]/, 'Top vendor single-value metric should not remain in the year summary');
omits(/<div class="stat-label">\$\{copy\.uniqueVendorLabel\}<\/div>/, 'Unique vendor/source count should not remain as a year summary stat tile');
omits(/<div class="stat-label">\$\{copy\.countLabel\}<\/div>/, 'Event count should not be duplicated because the summary pill shows it');
omits(/Kiadási tételek|Bevételi tételek/, 'Event count labels should not appear in the year summary');
omits(/<div class="panel-title">Szöveges statok<\/div>/, 'Page 2 should not render the old text stats panel');
omits(/class="insight-list"/, 'Page 2 should remove the text insight list');
contains(/Bevétel vs kiadás/, 'Income chart should use Hungarian title copy');
contains(/Fedezeti arány/, 'Income chart should use Hungarian helper title copy');
contains(/Küszöb feletti többlet/, 'Income helper chart should use Hungarian threshold excess copy');
omits(/ExpenseTracker|>ALL<|SCOPE SCORE|scope menu|scope kategóriák|Expense year summary|Income year summary|Filtered spend|Filtered income|Largest spend|Largest income|Daily tx avg|Daily spend avg|Daily income avg|No-spend days|No-income days|Unique vendors|Unique sources|Average spend|Average income|Category ranking|Top vendor|Top source|Text stats|Current filter|Income vs spend|Coverage ratio|Threshold excess/, 'Page 2 visible copy should not keep the previous English labels');
contains(/data-page-dot="2"/, 'Page 2 should expose a second-page indicator for the future swipe model');

const scriptWithoutBoot = scriptMatch[1].replace(
  /\n\s*document\.getElementById\('incomeBtn'\)\.addEventListener[\s\S]*$/,
  '\n',
);
const behaviorSandbox = {console};
vm.runInNewContext(
  `${scriptWithoutBoot}
globalThis.__page2Test = {
  setState(type, scopeIds, nextThreshold) {
    activeType = type;
    activeScopeIds = new Set(scopeIds);
    threshold = nextThreshold;
  },
  months() {
    return buildMonths();
  },
  metrics(months) {
    return yearSummaryMetrics(months);
  },
  categories(records) {
    return categoryShare(records);
  },
  vendors(records) {
    return topVendors(records);
  },
};
`,
  behaviorSandbox,
);

const page2Test = behaviorSandbox.__page2Test;
page2Test.setState('expense', ['food'], 10000);
const expenseMetrics = page2Test.metrics(page2Test.months());
assert.equal(expenseMetrics.type, 'expense', 'expense summary should report expense mode');
assert.ok(expenseMetrics.total > 0, 'expense summary should include threshold-visible spend');
assert.ok(
  expenseMetrics.records.every(record => record.type === 'expense' && record.categoryId === 'food' && record.amount >= 10000),
  'expense summary records should honor type, scope, and threshold',
);
assert.ok(expenseMetrics.dailyAverageTransactionCount > 0, 'expense summary should compute daily average transaction count');
assert.ok(expenseMetrics.dailyAverageAmount > 0, 'expense summary should compute daily average spend');
assert.ok(expenseMetrics.zeroActivityDays >= 0, 'expense summary should compute no-spend days');
assert.ok(expenseMetrics.uniqueVendorCount > 0, 'expense summary should compute unique vendor count');
assert.ok(
  expenseMetrics.vendors.length <= expenseMetrics.uniqueVendorCount,
  'expense Top 5 count should be shown against the filtered unique vendor count',
);
assert.equal(
  Math.round(expenseMetrics.averageEventAmount),
  Math.round(expenseMetrics.total / expenseMetrics.records.length),
  'expense summary should compute average event amount from filtered records',
);
assert.ok(expenseMetrics.categoryRanking.length > 0, 'expense summary should expose category ranking');
assert.equal(page2Test.categories(expenseMetrics.records)[0].label, 'Étel', 'expense category share should use category labels');
assert.ok(page2Test.vendors(expenseMetrics.records).length > 0, 'expense summary should produce top vendors');
assert.ok(page2Test.vendors(expenseMetrics.records).length <= 5, 'expense vendor list should stay limited to Top 5');
assert.equal(
  Math.round(page2Test.vendors(expenseMetrics.records).reduce((sum, vendor) => sum + vendor.share, 0) * 100),
  100,
  'expense vendor progress shares should add up to the listed Top 5 total',
);
assert.ok(
  expenseMetrics.records.every(record => record.categoryId === 'food') &&
    page2Test.vendors(expenseMetrics.records).every(vendor =>
      expenseMetrics.records.some(record => record.vendor === vendor.label && record.categoryId === 'food')
    ),
  'expense vendor list should be derived from the selected category scope only',
);

page2Test.setState('expense', ['mobility'], 0);
const mobilityNoThreshold = page2Test.metrics(page2Test.months());
page2Test.setState('expense', ['mobility'], 5000);
const mobilityWithThreshold = page2Test.metrics(page2Test.months());
assert.notDeepEqual(
  mobilityWithThreshold.vendors.map(vendor => [vendor.label, vendor.amount]),
  mobilityNoThreshold.vendors.map(vendor => [vendor.label, vendor.amount]),
  'expense vendor box should react dynamically to the threshold',
);
assert.ok(
  mobilityWithThreshold.vendors.every(vendor => vendor.color === '#0EA5E9'),
  'expense vendor progress bars should use the selected category color',
);
assert.ok(
  mobilityWithThreshold.records.every(record => record.categoryId === 'mobility' && record.amount >= 5000),
  'expense vendor records should use the selected category scope and active threshold',
);

page2Test.setState('income', ['salary'], 300000);
const incomeMetrics = page2Test.metrics(page2Test.months());
assert.equal(incomeMetrics.type, 'income', 'income summary should report income mode');
assert.ok(incomeMetrics.total > 0, 'income summary should include threshold-visible income');
assert.ok(
  incomeMetrics.records.every(record => record.type === 'income' && record.categoryId === 'salary' && record.amount >= 300000),
  'income summary records should honor type, scope, and threshold',
);
assert.ok(incomeMetrics.dailyAverageTransactionCount > 0, 'income summary should compute daily average transaction count');
assert.ok(incomeMetrics.dailyAverageAmount > 0, 'income summary should compute daily average income');
assert.ok(incomeMetrics.zeroActivityDays >= 0, 'income summary should compute no-income days');
assert.ok(incomeMetrics.uniqueVendorCount > 0, 'income summary should compute unique source count');
assert.ok(
  incomeMetrics.vendors.length <= incomeMetrics.uniqueVendorCount,
  'income Top 5 count should be shown against the filtered unique source count',
);
assert.equal(
  Math.round(incomeMetrics.averageEventAmount),
  Math.round(incomeMetrics.total / incomeMetrics.records.length),
  'income summary should compute average income event amount from filtered records',
);
assert.ok(incomeMetrics.categoryRanking.length > 0, 'income summary should expose category ranking');
assert.equal(page2Test.categories(incomeMetrics.records)[0].label, 'Fizetés', 'income category share should use source category labels');
assert.ok(page2Test.vendors(incomeMetrics.records).length > 0, 'income summary should produce top sources');
assert.ok(page2Test.vendors(incomeMetrics.records).length <= 5, 'income source list should stay limited to Top 5');
assert.equal(
  Math.round(page2Test.vendors(incomeMetrics.records).reduce((sum, vendor) => sum + vendor.share, 0) * 100),
  100,
  'income source progress shares should add up to the listed Top 5 total',
);
assert.ok(
  incomeMetrics.records.every(record => record.categoryId === 'salary') &&
    page2Test.vendors(incomeMetrics.records).every(vendor =>
      incomeMetrics.records.some(record => record.vendor === vendor.label && record.categoryId === 'salary')
    ),
  'income source list should be derived from the selected category scope only',
);
