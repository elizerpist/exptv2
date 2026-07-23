const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const htmlPath = path.join(__dirname, 'stats_common_2025_sim.html');
assert.ok(fs.existsSync(htmlPath), 'stats_common_2025_sim.html should exist');

const html = fs.readFileSync(htmlPath, 'utf8');

function contains(pattern, message) {
  assert.match(html, pattern, message);
}

function omits(pattern, message) {
  assert.doesNotMatch(html, pattern, message);
}

const scriptMatch = html.match(/<script>([\s\S]*?)<\/script>/);
assert.ok(scriptMatch, 'HTML should contain one inline script block');
new vm.Script(scriptMatch[1]);

const scriptWithoutBoot = scriptMatch[1].replace(
  /\n\s*document\.getElementById\('incomeBtn'\)\.addEventListener[\s\S]*$/,
  '\n',
);
const behaviorSandbox = {console};
vm.runInNewContext(
  `${scriptWithoutBoot}
globalThis.__incomeScoreTest = {
  scoreForVisibleValues(values) {
    return incomePatternTrendScore(values.map(value => ({visibleValue: value}))).score;
  },
  stateForVisibleValues(values) {
    return incomePatternTrendScore(values.map(value => ({visibleValue: value})));
  },
  centerlineBars(months, variant) {
    return incomeCenterlineBars(months, variant);
  },
  filteredPatternMonthIndexes(months) {
    return incomeFilteredPatternMonths(months).map(month => month.index);
  },
  incomeThresholdExcess(months) {
    return incomeThresholdExcessSeries(months);
  },
  setThresholdForTest(value) {
    threshold = value;
  },
};
`,
  behaviorSandbox,
);
const incomeScoreTest = behaviorSandbox.__incomeScoreTest;

const expenseTotalsMatch = html.match(/expense:\s*\[([^\]]+)\]/);
assert.ok(expenseTotalsMatch, 'mock monthly expense totals should be present');
const expenseTotals = expenseTotalsMatch[1]
  .split(',')
  .map(value => Number.parseInt(value.trim(), 10))
  .filter(Number.isFinite);
assert.ok(expenseTotals.some(value => value > 0), 'mock expense data should contain active months');
assert.ok(
  Math.max(...expenseTotals) <= 1200000,
  'mock expense totals should stay in a realistic range comparable to income',
);
assert.ok(
  expenseTotals.filter(value => value > 0).every(value => value >= 180000),
  'active mock expense months should remain meaningful after rescaling',
);

contains(/<section class="scope-selector" id="scopeSelector"/, 'common mode should expose a multi-category selector');
contains(/let activeScopeIds = new Set/, 'scope state should allow multiple selected categories');
contains(/function toggleScopeCategory/, 'category selector should support toggling categories');
contains(/activeScopeIds\.has\(record\.categoryId\)/, 'scoped records should be filtered by the selected category set');

omits(/\.day\.hit::before/, 'day cells should not use the old dot pseudo-element');
omits(/class="day\$\{day\.hit \? ' hit'/, 'day cells should not render the old hit class');
contains(/\.day\.heat::before/, 'day heat should be rendered as a cell fill layer');
contains(/--day-heat-opacity/, 'day heat should use per-cell opacity');
contains(/0\.1 \+ 0\.9/, 'day heat opacity should scale from 0.1 to 1.0');

contains(/color:\s*'#[0-9A-Fa-f]{6}'/, 'categories should define colors for single-category scope');
contains(/function scopeSelectionColor/, 'scope coloring should switch between category and heatmap colors');
contains(/return selected\.length === 1\s*\?\s*selected\[0\]\.color\s*:\s*colors\.heatmap/, 'single category should use category color and multi category should use heatmap color');

contains(/formatHuf\(month\.thresholdedActiveTotal\)/, 'month secondary amount should use threshold-filtered scoped total');
omits(/formatHuf\(month\.activeTotal\)/, 'month secondary amount should not use unfiltered active total');

contains(/\.month-card\s*\{[\s\S]*background:\s*var\(--gray-50\)/, 'month cards should keep the original neutral background');
omits(/\.month-card::before/, 'month cards should not render a red or green close overlay layer');
omits(/--close-overlay/, 'month cards should not receive close overlay colors inline');

contains(/id="magnet"/, 'magnet container should be addressable for mode-specific design');
contains(/\.magnet\.expense-score \.magnet-rail[\s\S]*rgba\(220,38,38,\.76\)[\s\S]*rgba\(22,163,74,\.76\)/, 'expense magnet should use the fastfood soft-wash rail colors');
contains(/\.magnet\.expense-score \.magnet-marker[\s\S]*--magnet-score-color/, 'expense magnet marker should use score color');
contains(/function expenseMagnetScore\(months\)/, 'expense mode should compute a fastfood-style magnet score');
contains(/function scoreColor\(value\)[\s\S]*value < 45[\s\S]*colors\.expense[\s\S]*value < 60[\s\S]*colors\.orange[\s\S]*colors\.income/, 'magnet score color should use fastfood 45/60 thresholds');
contains(/expenseMagnetScore:\s*activeType === 'expense' \? expenseFastInfoSeries\.kontrollScore : null/, 'expense score should only be produced for expense mode');
contains(/const markerPosition = isExpenseMagnet\s*\?\s*series\.expenseMagnetScore \/ 100\s*:\s*isIncomeMagnet\s*\?\s*series\.incomeMagnetScore \/ 100\s*:\s*series\.driftMarker/, 'expense and income modes should bind marker position to their score while fallback keeps drift marker');
contains(/magnet\.classList\.toggle\('expense-score', isExpenseMagnet\)/, 'expense magnet design should only activate in expense mode');
contains(/magnet\.classList\.toggle\('income-score', isIncomeMagnet\)/, 'income magnet should activate the same soft-wash score design in income mode');
contains(/marker\.style\.setProperty\('--magnet-score-color', scoreColor\(series\.expenseMagnetScore\)\)/, 'expense marker color should update from score');
contains(/function render\(\)[\s\S]*const months = buildMonths\(\)[\s\S]*const series = sumSeries\(months\)[\s\S]*drawHeader\(series\)/, 'render should rebuild magnet data from current threshold state');
contains(/function setThreshold\(raw\)[\s\S]*threshold = clamp[\s\S]*render\(\)/, 'threshold slider/manual changes should trigger a live magnet rerender');

contains(/<div class="header-label">SCOPE SCORE<\/div>/, 'magnet label should be SCOPE SCORE');
omits(/HÓZÁRÁS/, 'old closing label should not remain in the common prototype');
contains(/<div class="header-value" id="headerValue">0\/100<\/div>/, 'header should show a concrete score value under the label');
contains(/\.header-value[\s\S]*top:\s*134px[\s\S]*font-size:\s*24px[\s\S]*font-weight:\s*700/, 'score value should use the linked fastfood header-value layout');
contains(/const headerScore = isExpenseMagnet \? series\.expenseMagnetScore : isIncomeMagnet \? series\.incomeMagnetScore : clamp\(series\.driftMarker \* 100, 0, 100\)/, 'header value should use expense or income score before fallback');
contains(/document\.getElementById\('headerValue'\)\.textContent = `\$\{Math\.round\(headerScore\)\}\/100`/, 'rendered header score should update as a concrete /100 value');

contains(/function expenseScopeScoreSeries\(months\)/, 'expense FastInfo should build a scope score series from months');
contains(/function drawExpenseScopeScoreFastInfo\(svg, fastInfo\)/, 'expense FastInfo should have a dedicated fastfood-style renderer');
contains(/const expenseFastInfoSeries = activeType === 'expense' \? expenseScopeScoreSeries\(months\) : null/, 'expense FastInfo data should only be produced for expense mode');
contains(/expenseFastInfoSeries,/, 'expense FastInfo series should be returned with the render series object');
contains(/if \(activeType === 'expense' && series\.expenseFastInfoSeries\)[\s\S]*drawExpenseScopeScoreFastInfo\(svg, series\.expenseFastInfoSeries\)[\s\S]*return/, 'expense mode should use the fastfood FastInfo renderer while other modes fall through');
contains(/1\. Scope score · Soft band/, 'expense FastInfo should use the linked Scope score title');
contains(/2\. Threshold excess/, 'expense FastInfo should use the linked Threshold excess helper title');
contains(/rossz[\s\S]*semleges 50[\s\S]*jó/, 'expense Scope score legend should match the linked labels');
contains(/function drawSoftScoreZones\(svg, rect\)/, 'expense Scope score should render the linked soft band background');
contains(/function drawSegmentedScorePath\(svg, rect, points/, 'expense Scope score should render segmented score path colors');
contains(/function drawThresholdExcessHistogram\(svg, rect, points, threshold, color = colors\.expense\)/, 'expense helper should render threshold excess histogram with the default expense color');
contains(/function thresholdExcessDeltas\(values, threshold\)/, 'threshold excess should be computed from current threshold');
contains(/drawThresholdExcessHistogram\(svg, chart\.helper, fastInfo\.helperAmountLine, threshold\)/, 'helper histogram should be bound to live threshold value');
contains(/drawMonthLabels\(svg, chart\.primary, fastInfo\.monthTicks\)/, 'scope score chart should use dynamic month ticks');

contains(/const incomeMonthPlans = \[/, 'income mock data should use explicit income month plans');
contains(/kind: 'micro'/, 'income mock data should include micro-income months');
contains(/kind: 'low_salary'/, 'income mock data should include lower-salary months');
contains(/kind: 'multi_salary'/, 'income mock data should include multi-salary months');
contains(/kind: 'single_large'/, 'income mock data should include one single large income month');
contains(/kind: 'weak'/, 'income mock data should include weak income months');
contains(/function buildIncomeTransactions\(output\)/, 'income transactions should be generated by a dedicated income mock builder');
contains(/function microIncomeEntries\(monthIndex, count, baseAmount, spread\)/, 'income mock data should generate micro income entries');
contains(/function incomeMagnetScore\(months\)/, 'income magnet should compute the pattern-trend income score');
contains(/function incomePatternMetrics\(months\)/, 'income score should build threshold-visible pattern metrics from the current income state');
contains(/function incomePatternTrendScore\(patterns\)/, 'income score should use the approved pattern-trend score helper');
contains(/trendAdjustment = clamp\(trendDelta \* 35, -30, 30\)/, 'income score should use the approved trend sensitivity and clamp');
contains(/score:\s*clamp\(50 \+ trendAdjustment, 0, 100\)/, 'income score should be centered on neutral 50');
contains(/noSignal:\s*true/, 'income score should expose neutral no-signal state when the threshold hides the current pattern');
omits(/0\.60 \* amountScore \+ 0\.25 \* goodMonthScore \+ 0\.15 \* freshTrendScore/, 'income score should not use the old 60/25/15 strength formula');
contains(/incomeMagnetScore:\s*activeType === 'income' \? incomeMagnetScore\(months\) : null/, 'income score should only be produced in income mode');
contains(/const isIncomeMagnet = activeType === 'income' && Number\.isFinite\(series\.incomeMagnetScore\)/, 'header should detect income magnet score mode');
contains(/\.magnet\.income-score \.magnet-rail[\s\S]*rgba\(220,38,38,\.76\)[\s\S]*rgba\(22,163,74,\.76\)/, 'income magnet should use the same soft-wash rail as expense');

omits(/fastInfoConceptIndex/, 'Income FastInfo should not keep concept-switching state when only one chart remains');
omits(/fastInfoConceptLabels/, 'Income FastInfo should not expose concept labels when only one chart remains');
omits(/function fastInfoConceptCount\(\)/, 'Income FastInfo should not keep concept wrapping helpers');
omits(/function setFastInfoConcept\(index\)/, 'Income FastInfo should not expose direct concept selection');
omits(/function shiftFastInfoConcept\(direction\)/, 'Income FastInfo should not support concept stepping when only one chart remains');
omits(/function drawConceptChrome\(svg, activeIndex\)/, 'Income FastInfo should not render concept tabs when only one chart remains');
omits(/drawIncomePatternScoreFastInfo\(svg, months\);/, 'Pattern score line chart should not remain an active FastInfo concept call');
contains(/function drawExpenseWeightedFastInfo\(svg, months\)/, 'Concept C1 should render a proposed expense-weighted bar view');
contains(/title: 'Income vs spend'/, 'Concept C1 should use the clearer income-vs-spend title without a C1 prefix');
omits(/title: 'C1 · Income vs spend'/, 'Concept C1 title should not include the C1 prefix');
contains(/goodLabel: 'Covers spend'/, 'Concept C1 should label positive bars as covering spend');
contains(/badLabel: 'Income short'/, 'Concept C1 should label negative bars as income short');
contains(/zeroLabel: 'Break-even'/, 'Concept C1 should label the centerline as break-even');
contains(/function incomeCenterlineBars\(months, variant\)/, 'C-layout variants should derive signed centerline bar data from live income and expense values');
contains(/function incomeFilteredPatternMonths\(months\)/, 'Income charts should have one filtered-pattern month source');
contains(/const observed = incomeFilteredPatternMonths\(months\)/, 'C-layout variants should use threshold-filtered pattern months for their x-axis');
contains(/const filteredIncomeMonths = activeType === 'income' \? incomeFilteredPatternMonths\(months\) : null/, 'sum series should prepare filtered income months for income reference charts');
contains(/const h1Months = activeType === 'income' \? filteredIncomeMonths : h1MonthsFor\(months\)/, 'income reference primary x-axis should use filtered pattern months');
contains(/const remainderMonths = activeType === 'income' \? filteredIncomeMonths : remainderMonthsFor\(months\)/, 'income reference helper x-axis should use filtered pattern months');
contains(/const signedValue = visibleIncome - expenseAmount/, 'C1 should compute the direct visible-income minus expense net gap');
omits(/case 'coverage_delta':/, 'C-layout variant C2 should be removed');
omits(/case 'baseline_delta':/, 'C-layout variant C3 should be removed');
omits(/case 'safe_gap':/, 'C-layout variant C4 should be removed');
omits(/case 'pattern_pressure_delta':/, 'C-layout variant C5 should be removed');
omits(/coverageDelta:/, 'C2 config should be removed');
omits(/baselineDelta:/, 'C3 config should be removed');
omits(/safeGap:/, 'C4 config should be removed');
omits(/patternPressure:/, 'C5 config should be removed');
omits(/function drawIncomePatternScoreFastInfo/, 'Old income pattern-score chart renderer should be removed');
omits(/function drawIncomeThresholdCurveFastInfo/, 'Old income threshold-curve chart renderer should be removed');
omits(/function drawIncomeStructureBandsFastInfo/, 'Old income structure-bands chart renderer should be removed');
omits(/function drawIncomeExpenseCoverFastInfo/, 'Old income expense-cover chart renderer should be removed');
omits(/function drawIncomePatternShapeFastInfo/, 'Old income pattern-shape chart renderer should be removed');
omits(/function drawIncomeBreakEvenFastInfo/, 'Old income break-even chart renderer should be removed');
omits(/case 'threshold_usefulness':/, 'C-layout variant C6 should be removed');
omits(/thresholdUsefulness/, 'C6 threshold usefulness config should be removed');
contains(/function drawIncomeCenterlineFastInfo\(svg, months, config\)/, 'C-layout variants should share one centerline red-green bar renderer');
contains(/\{label: config\.zeroLabel \|\| '0', color: colors\.text\}/, 'C-layout legend should allow C1 to use Break-even without changing the other zero labels');
contains(/function drawExpenseWeightedBars\(svg, rect, bars\)[\s\S]*drawMonthLabels\(svg, rect, bars\.map\(bar => \(\{[\s\S]*label: bar\.monthLabel,[\s\S]*position: bar\.position,[\s\S]*\}\)\)\)/, 'C1 upper chart should use the same month-label renderer and positions as the income upper chart');
omits(/function drawExpenseWeightedBars\(svg, rect, bars\)\s*\{(?:(?!function drawIncomeCenterlineFastInfo)[\s\S])*drawMonthAxisLabels\(svg, rect, bars\);/, 'C1 bars should not use the old alternate month-axis label placement');
contains(/function incomeThresholdExcessSeries\(months\)/, 'Income lower helper should build threshold-excess data from income events');
contains(/function drawAmountMinHistogram\(svg, rect, points, color = colors\.expense\)/, 'Threshold excess histogram should keep the expense default color');
contains(/function drawThresholdExcessHistogram\(svg, rect, points, threshold, color = colors\.expense\)/, 'Threshold excess histogram should be shared by expense and income with a color override');
contains(/drawThresholdExcessHistogram\(svg, chart\.helper, incomeHelper\.helperAmountLine, threshold, colors\.income\)/, 'Income C-layout lower helper should use the same threshold-excess renderer with green bars');
contains(/const incomeHelper = incomeThresholdExcessSeries\(incomeFilteredPatternMonths\(months\)\)/, 'Income threshold-excess helper should receive only threshold-filtered pattern months');
contains(/addText\(svg, '2\. Threshold excess', chart\.helper\.left, chart\.helper\.top - 8/, 'Income C-layout lower helper should use the same Threshold excess title as expense');
contains(/drawMonthLabels\(svg, chart\.helper, incomeHelper\.monthTicks\)/, 'Income C-layout lower helper should reuse threshold-excess month ticks');
omits(/addText\(svg, config\.helperTitle, chart\.helper\.left, chart\.helper\.top - 8/, 'Income lower helper should not vary by C-layout calculation');
contains(/function drawFastInfo\(series, months\)[\s\S]*if \(activeType === 'expense'\)[\s\S]*drawReferenceFastInfo\(svg, series\)[\s\S]*return/, 'expense mode should always keep the accepted reference FastInfo chart');
contains(/function drawFastInfo\(series, months\)[\s\S]*if \(activeType === 'expense'\)[\s\S]*return;[\s\S]*drawExpenseWeightedFastInfo\(svg, months\);[\s\S]*\}/, 'Income mode should directly render the single approved C1 chart');
omits(/case 0:[\s\S]*drawExpenseWeightedFastInfo\(svg, months\)/, 'Income FastInfo should not need switch routing for a single C1 chart');
omits(/case 1:[\s\S]*incomeCenterlineConfigs\.coverageDelta/, 'Concept C2 should not remain reachable from the income switch');
omits(/case 2:[\s\S]*incomeCenterlineConfigs\.baselineDelta/, 'Concept C3 should not remain reachable from the income switch');
omits(/case 3:[\s\S]*incomeCenterlineConfigs\.safeGap/, 'Concept C4 should not remain reachable from the income switch');
omits(/case 4:[\s\S]*incomeCenterlineConfigs\.patternPressure/, 'Concept C5 should not remain reachable from the income switch');
omits(/default:[\s\S]*drawExpenseWeightedFastInfo\(svg, months\)/, 'Income FastInfo should not need fallback routing for a single C1 chart');
omits(/case 5:[\s\S]*drawIncomeCenterlineFastInfo\(svg, months, incomeCenterlineConfigs\.patternPressure\)/, 'Concept C5 should no longer sit behind the old A-inclusive index');
omits(/case 6:[\s\S]*drawIncomeCenterlineFastInfo\(svg, months, incomeCenterlineConfigs\.thresholdUsefulness\)/, 'Concept C6 should not be reachable from the income concept switch');
omits(/fastInfoSvg\.addEventListener\('pointerdown'/, 'FastInfo SVG should not listen for swipe start when only one chart remains');
omits(/fastInfoSvg\.addEventListener\('pointerup'/, 'FastInfo SVG should not listen for swipe end when only one chart remains');
contains(/drawFastInfo\(series, months\)/, 'render should pass live month data into FastInfo concepts');

assert.equal(
  Math.round(incomeScoreTest.scoreForVisibleValues([500000, 500000])),
  50,
  'stable visible income pattern should stay neutral',
);
assert.equal(
  Math.round(incomeScoreTest.scoreForVisibleValues([600000, 300000])),
  33,
  '600k to 300k visible pattern drop should score around 30-35',
);
assert.equal(
  Math.round(incomeScoreTest.scoreForVisibleValues([600000, 550000])),
  47,
  '600k to 550k visible pattern drop should be a mild warning',
);
assert.equal(
  Math.round(incomeScoreTest.scoreForVisibleValues([300000, 600000])),
  73,
  '300k to 600k visible pattern improvement should score above neutral',
);
const noSignalState = incomeScoreTest.stateForVisibleValues([500000, null]);
assert.equal(noSignalState.noSignal, true, 'threshold-hidden recent pattern should be no-signal');
assert.equal(Math.round(noSignalState.score), 50, 'no-signal should stay neutral instead of treating hidden pattern as zero');

const centerlineSample = [
  {
    index: 0,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 500000,
    expenseTotal: 400000,
    activeTotal: 500000,
    thresholdedActiveTotal: 500000,
    days: [{day: 5, amount: 500000, hit: true}],
  },
  {
    index: 1,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 300000,
    expenseTotal: 400000,
    activeTotal: 300000,
    thresholdedActiveTotal: 300000,
    days: [{day: 5, amount: 300000, hit: true}],
  },
  {
    index: 2,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 460000,
    expenseTotal: 400000,
    activeTotal: 460000,
    thresholdedActiveTotal: 460000,
    days: [{day: 5, amount: 460000, hit: true}],
  },
];
incomeScoreTest.setThresholdForTest(0);
const netGapBars = incomeScoreTest.centerlineBars(centerlineSample, 'net_gap');
assert.equal(netGapBars[0].signedValue, 100000, 'net-gap C layout should show Ft surplus above the centerline');
assert.equal(netGapBars[1].signedValue, -100000, 'net-gap C layout should show Ft shortage below the centerline');

const sampleIncomePatterns = [
  {
    index: 0,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 500000,
    expenseTotal: 420000,
    activeTotal: 500000,
    thresholdedActiveTotal: 500000,
    days: [{day: 3, amount: 500000, hit: true}],
  },
  {
    index: 1,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 500000,
    expenseTotal: 390000,
    activeTotal: 500000,
    thresholdedActiveTotal: 500000,
    days: [1, 2, 3, 4, 5].map(day => ({day, amount: 100000, hit: true})),
  },
];
incomeScoreTest.setThresholdForTest(100000);
assert.deepEqual(
  incomeScoreTest.filteredPatternMonthIndexes(sampleIncomePatterns),
  [0, 1],
  'income filtered x-axis should include every month with a threshold-visible income pattern',
);
const incomeThresholdExcessAt100k = incomeScoreTest.incomeThresholdExcess(sampleIncomePatterns);
assert.deepEqual(
  incomeThresholdExcessAt100k.helperAmountLine.map(point => point.value),
  [500000, 100000, 100000, 100000, 100000, 100000],
  'income threshold-excess helper should observe threshold-visible income events',
);
assert.ok(incomeThresholdExcessAt100k.monthTicks.length >= 2, 'income threshold-excess helper should expose month ticks like expense');
incomeScoreTest.setThresholdForTest(101000);
assert.deepEqual(
  incomeScoreTest.filteredPatternMonthIndexes(sampleIncomePatterns),
  [0],
  'income filtered x-axis should omit months where the current threshold hides every income event',
);
const incomeThresholdExcessAt101k = incomeScoreTest.incomeThresholdExcess(sampleIncomePatterns);
assert.deepEqual(
  incomeThresholdExcessAt101k.helperAmountLine.map(point => point.value),
  [500000],
  'income threshold-excess helper should drop income events below the active threshold',
);
const hiddenMiddleMonthPatterns = [
  {
    index: 0,
    month: 1,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 500000,
    expenseTotal: 350000,
    activeTotal: 500000,
    thresholdedActiveTotal: 500000,
    days: [{day: 5, amount: 500000, hit: true}],
  },
  {
    index: 1,
    month: 2,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 50000,
    expenseTotal: 350000,
    activeTotal: 50000,
    thresholdedActiveTotal: 0,
    days: [{day: 5, amount: 50000, hit: false}],
  },
  {
    index: 2,
    month: 3,
    hasTransactions: true,
    scopeHasActivity: true,
    incomeTotal: 450000,
    expenseTotal: 350000,
    activeTotal: 450000,
    thresholdedActiveTotal: 450000,
    days: [{day: 5, amount: 450000, hit: true}],
  },
];
incomeScoreTest.setThresholdForTest(100000);
const incomeThresholdExcessWithHiddenMiddle = incomeScoreTest.incomeThresholdExcess(
  hiddenMiddleMonthPatterns,
);
assert.deepEqual(
  Array.from(incomeThresholdExcessWithHiddenMiddle.monthTicks.map(tick => tick.label)),
  ['Jan', 'Már'],
  'income threshold-excess helper x-axis should omit hidden middle months',
);
