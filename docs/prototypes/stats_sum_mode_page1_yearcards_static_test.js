const fs = require('fs');
const path = require('path');

const targetPath = path.join(__dirname, 'stats_sum_mode_page1_yearcards.html');
const referencePath = path.join(__dirname, 'stats_common_2025_final_0710.html');

const target = fs.readFileSync(targetPath, 'utf8');
const reference = fs.readFileSync(referencePath, 'utf8');

function assertIncludes(haystack, needle, label = needle) {
  if (!haystack.includes(needle)) {
    throw new Error(`Missing ${label}`);
  }
}

function assertNotIncludes(haystack, needle, label = needle) {
  if (haystack.includes(needle)) {
    throw new Error(`Forbidden ${label}`);
  }
}

function assertMatch(haystack, pattern, label = String(pattern)) {
  if (!pattern.test(haystack)) {
    throw new Error(`Missing pattern ${label}`);
  }
}

function sliceBetween(source, start, end) {
  const startIndex = source.indexOf(start);
  if (startIndex < 0) throw new Error(`Missing start marker ${start}`);
  const endIndex = source.indexOf(end, startIndex);
  if (endIndex < 0) throw new Error(`Missing end marker ${end}`);
  return source.slice(startIndex, endIndex);
}

function assertSameSnippet(start, end, label) {
  const referenceSnippet = sliceBetween(reference, start, end);
  const targetSnippet = sliceBetween(target, start, end);
  if (referenceSnippet !== targetSnippet) {
    throw new Error(`${label} differs from common Page 1 reference`);
  }
}

function assertSameSnippetWithDifferentEnd(start, referenceEnd, targetEnd, label) {
  const referenceSnippet = sliceBetween(reference, start, referenceEnd);
  const targetSnippet = sliceBetween(target, start, targetEnd);
  if (referenceSnippet !== targetSnippet) {
    throw new Error(`${label} differs from common Page 1 reference`);
  }
}

[
  ['.chart-area {', '    .error-panel {', 'FastInfo area CSS'],
  ['    .header {', '    .type-row {', 'header/magnet CSS'],
  ['    .type-row {', '    .scope-selector {', 'income/expense toggle CSS'],
  ['    .scope-selector {', '    .month-grid {', 'scope selector CSS'],
  ['    .controls {', '  </style>', 'threshold control CSS'],
  ['    function drawFastInfo(series, months) {', '    function drawHeader(series) {', 'FastInfo drawing function'],
  ['    function sliderMaxForScope() {', '    function render() {', 'slider/control functions'],
  ['    function setThreshold(raw) {', '    function resetScopeSelection() {', 'threshold setter'],
].forEach(([start, end, label]) => assertSameSnippet(start, end, label));

assertSameSnippetWithDifferentEnd(
  '    function drawHeader(series) {',
  '    function drawMonthCards(months) {',
  '    function drawYearCards(years) {',
  'header/magnet function'
);

[
  '<section class="month-grid" id="yearGrid"></section>',
  'height: 154px;',
  'grid-template-columns: repeat(6, 1fr);',
  'gap: 0;',
  'height: 70px;',
  'const transactionYears = Array.from({length: 20}',
  'let activeYear = 2025',
  'year: year',
  'function buildYears()',
  'function yearTickLabelsForGraph(years)',
  'function buildYearGraphMonths(years)',
  'function drawYearCards(years)',
  'data-year="${year.year}"',
  'class="year-cell',
  'year-months',
  'setActiveYear(Number(card.dataset.year))',
  'const years = buildYears();',
  'const graphMonths = buildYearGraphMonths(years);',
  'const series = sumSeries(graphMonths);',
  'drawFastInfo(series, graphMonths);',
  'drawYearCards(years);',
  'record.year === year',
  'record.year === activeYear',
  'const tickLabel = visibleYearLabels.has(year.year) ? String(year.year) : \'\';',
  'day.tickLabel ?? monthAxisLabels[day.month - 1]',
  'month.tickLabel ?? monthAxisLabels[month.index]',
  'if (label === \'\') return;',
  'year % 5 === 0',
].forEach(needle => assertIncludes(target, needle));

[
  /transactionYears\.forEach\(year =>[\s\S]*monthly\.expense\.forEach/,
  /incomeMonthPlans\.forEach\(plan =>[\s\S]*year: year/,
  /year\.months\.map\(month =>[\s\S]*--month-heat-color:\$\{activeColor\}/,
  /--month-heat-opacity:\$\{month\.monthHeatOpacity\.toFixed\(3\)\}/,
  /function drawYearCards\(years\)[\s\S]*grid\.style\.setProperty\('--active-color', activeColor\)/,
  /function yearTickLabelsForGraph\(years\)[\s\S]*if \(count <= 10\)[\s\S]*if \(count <= 16\)[\s\S]*year % 5 === 0[\s\S]*year % 10 === 0/,
  /function buildYearGraphMonths\(years\)[\s\S]*const visibleYearLabels = yearTickLabelsForGraph\(years\);[\s\S]*const tickLabel = visibleYearLabels\.has\(year\.year\) \? String\(year\.year\) : '';[\s\S]*const days = year\.months\.map/,
  /function render\(\)[\s\S]*const months = buildMonths\(\);[\s\S]*const years = buildYears\(\);[\s\S]*const graphMonths = buildYearGraphMonths\(years\);[\s\S]*const series = sumSeries\(graphMonths\);[\s\S]*drawFastInfo\(series, graphMonths\);[\s\S]*drawYearCards\(years\);/,
  /\.year-months \{[\s\S]*grid-template-columns: repeat\(6, 1fr\);[\s\S]*gap: 0;[\s\S]*height: 70px;/,
  /\.day\.heat::before \{[\s\S]*inset: 1px;[\s\S]*\}[\s\S]*\.year-cell\.heat::before \{[\s\S]*inset: 1px;/,
].forEach(pattern => assertMatch(target, pattern));

if (/drawFastInfo\(series, months\);/.test(target)) {
  throw new Error('Sum mode FastInfo still receives active-year months instead of adaptive year graph data');
}

assertNotIncludes(target, 'function drawMonthCards(months)', 'old month-card renderer');
assertNotIncludes(target, 'drawMonthCards(months)', 'old month-card render call');
assertNotIncludes(target, 'id="monthGrid"', 'old monthGrid id');

const transactionYearMatch = target.match(/const transactionYears = Array\.from\(\{length: 20\}, \(_, index\) => (\d+) \+ index\);/);
if (!transactionYearMatch) {
  throw new Error('Expected 20-year transaction range');
}
const firstYear = Number(transactionYearMatch[1]);
const visibleYearLabels = [firstYear, ...Array.from({length: 20}, (_, index) => firstYear + index).filter(year => year % 5 === 0), firstYear + 19];
if (new Set(visibleYearLabels).size >= 20) {
  throw new Error('20-year x-axis labels are not thinned');
}

console.log('stats_sum_mode_page1_yearcards static checks passed');
