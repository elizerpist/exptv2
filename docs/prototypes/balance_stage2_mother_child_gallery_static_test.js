#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..');
const layoutPath = path.join(root, 'balance_latest_layout.html');
const pulsePath = path.join(__dirname, 'pulse_engine_panel_mockup.html');
const html = fs.readFileSync(layoutPath, 'utf8');
const pulseSource = fs.readFileSync(pulsePath, 'utf8');

const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((match) => match[1]);
assert.equal(scripts.length, 1, 'the B3M gallery must keep one inspectable inline renderer');
for (const script of scripts) new Function(script);

const catalogBlock = html.match(/const catalog = \[([\s\S]*?)\n\s*\];(?=\n\s*const trendCardId =)/)?.[1];
assert.ok(catalogBlock, 'the FastInfo catalog must remain explicit');
const trendCatalog = catalogBlock.match(/id: 'koltesi_trend',([\s\S]*?)(?=\n\s*\},\n\s*\{)/)?.[1];
assert.ok(trendCatalog, 'the retained 30+30-day trend catalog identity must exist');
assert.match(trendCatalog, /title: '30 napos ritmus'/, 'the upper compact box must carry the concise 30-day rhythm title');
assert.match(trendCatalog, /motherMeta: 'Ezt megelőző 30 naphoz képest'/, 'the rhythm catalog must state its preceding-30-day comparison baseline');

const upcomingRecurringCatalog = catalogBlock.match(/id: 'kovetkezo_ismetlodo_tranzakcio',([\s\S]*?)(?=\n\s*\},\n\s*\{|\n\s*\},?\s*$)/)?.[1];
assert.ok(upcomingRecurringCatalog, 'the upper rail must retain an explicit upcoming recurring transaction catalog identity');
assert.match(upcomingRecurringCatalog, /title: 'Közelgő ismétlődés'/, 'the incoming compact card must use the upcoming-recurring title');
assert.match(upcomingRecurringCatalog, /motherValue: '-3 490 Ft'/, 'the upcoming recurring card must expose its expense amount');
assert.match(upcomingRecurringCatalog, /upcomingDate: 'aug\. 4\.'/, 'the upcoming recurring card must expose its due date');
assert.match(upcomingRecurringCatalog, /categoryAvatar:\s*\{\s*icon: 'clapperboard\.svg',\s*color: '#8b5cf6',\s*label: 'Előfizetések'\s*\}/, 'the upcoming recurring card must retain its subscription category avatar');

const noSpendCatalog = catalogBlock.match(/id: 'no_spend_napok_szama',([\s\S]*?)(?=\n\s*\},\n\s*\{)/)?.[1];
assert.ok(noSpendCatalog, 'the no-spend compact card catalog identity must exist');
assert.doesNotMatch(noSpendCatalog, /változó költés nélkül|fixek nélkül|Fix tételek kizárva/, 'the no-spend compact card catalog must omit irrelevant exclusion copy');

const trendFixtureMatch = html.match(/const trendDailySeriesFixture = (\{[\s\S]*?\n\s*\});/);
assert.ok(trendFixtureMatch, 'the compact comparison must retain its real 30-day fixture');
const trendHelperMatch = html.match(/function summarizeTrendComparisonFixture\(series = trendDailySeriesFixture\) \{[\s\S]*?(?=\n\s*function getVariableBudgetDimension)/);
assert.ok(trendHelperMatch, 'the compact comparison needs an inspectable total helper');
const summarizeTrendComparisonFixture = Function(
  'const trendDailySeriesFixture = ' + trendFixtureMatch[1] + ';' +
  trendHelperMatch[0] +
  '; return summarizeTrendComparisonFixture;',
)();
assert.deepEqual(
  summarizeTrendComparisonFixture(),
  { previousTotal: 162000, currentTotal: 191100, percentage: 18, direction: 'up' },
  'the compact box must compare the two real 30-day totals',
);
assert.deepEqual(
  summarizeTrendComparisonFixture({ previous: [100, 100], current: [50, 50] }),
  { previousTotal: 200, currentTotal: 100, percentage: 50, direction: 'down' },
  'a lower current 30-day spend total must be recognized as a negative rhythm direction',
);

const todayRenderer = html.match(/function populateTodayRedesignScreen\([\s\S]*?(?=\n\s*function installPulseForecastGalleryStyles)/)?.[0];
assert.ok(todayRenderer, 'the B3M-A renderer must remain inspectable');
const balanceHeroRenderer = todayRenderer.match(/const hero = createTodayRedesignElement\([\s\S]*?(?=\n\s*const insightGrid)/)?.[0];
assert.ok(balanceHeroRenderer, 'the balance hero renderer must remain inspectable');
assert.match(balanceHeroRenderer, /stage2-redesign-hero-label/, 'the simplified hero must retain the balance label');
assert.match(balanceHeroRenderer, /stage2-redesign-hero-amount/, 'the simplified hero must retain the balance amount');
assert.match(balanceHeroRenderer, /stage2-redesign-hero-stat-grid/, 'the simplified hero must retain its reserve and balance-ratio content');
assert.doesNotMatch(balanceHeroRenderer, /heroAction|Részletek|stage2-redesign-hero-chart|chartPath|chartDot/, 'the hero must not render the removed details button or decorative stripe');
assert.match(todayRenderer, /function populateTodayRedesignScreen\(column, card, topCategoriesCard, categoryChangeCard, latestTransactionCard, averageDailyCard, trendCard, upcomingRecurringCard\)/, 'the first screen must receive the compact trend and upcoming-recurring catalog cards');
assert.match(todayRenderer, /data-trend-comparison', '30-plus-30'/, 'the restored comparison must be mounted as a distinct upper insight box');
assert.match(todayRenderer, /trend\.setAttribute\('data-trend-direction', trendSummary\.direction\)/, 'the rhythm card must expose its semantic direction for the tone styling');
assert.match(todayRenderer, /id: 'upcoming-recurring'/, 'the upper rail must create a dedicated upcoming-recurring compact card');
assert.match(todayRenderer, /id: 'upcoming-recurring',[\s\S]*?iconGlyph: '↻',[\s\S]*?value: '',/, 'the recurring header must use the same generic repeat glyph layout as the other FastInfo cards');
assert.doesNotMatch(todayRenderer, /id: 'upcoming-recurring',[\s\S]*?icon: upcomingRecurringCard\.categoryAvatar\.icon,[\s\S]*?value: '',/, 'the recurring category avatar must not be duplicated into the header');
assert.match(todayRenderer, /upcomingRecurring\.card\.style\.setProperty\('--today-recurring-category-color', upcomingRecurringCard\.categoryAvatar\.color\)/, 'the inline mini avatar must retain the recurring category color');
assert.match(todayRenderer, /stage2-redesign-upcoming-recurring-name/, 'the upcoming-recurring card must render the transaction name');
assert.match(todayRenderer, /stage2-redesign-upcoming-recurring-amount/, 'the upcoming-recurring card must render the transaction amount');
assert.match(todayRenderer, /stage2-redesign-upcoming-recurring-date/, 'the upcoming-recurring card must render the due date');
assert.match(todayRenderer, /stage2-redesign-upcoming-recurring-mini-avatar/, 'the recurring card must render the requested mini category avatar');
assert.match(todayRenderer, /upcomingRecurring\.valueElement\.replaceChildren\(recurringName, recurringAmount\)/, 'the Netflix name and amount must remain together in the first recurring row');
assert.match(todayRenderer, /upcomingRecurring\.body\.insertBefore\(recurringMiniAvatar, upcomingRecurring\.secondaryElement\)/, 'the mini avatar must occupy its own middle row between the Netflix line and date');
assert.doesNotMatch(todayRenderer, /upcomingRecurring\.valueElement\.replaceChildren\(recurringMiniAvatar/, 'the mini avatar must not be inline with the Netflix label');
assert.match(todayRenderer, /insightGrid\.append\(noSpend, categoryChange, latestTransaction, trend, upcomingRecurring\.card\);/, 'the upper rail must add the recurring card without surfacing the buffer-days engine metric');
assert.doesNotMatch(todayRenderer, /Puffer napok|data-buffer-days-insight|createBalanceBufferDaysGauge/, 'the upper screen must not render a buffer-days box');
assert.match(todayRenderer, /detailCarousel\.append\(detail, topCategoriesDetail, topMerchantsDetail, averageDailyDetail\);/, 'the lower carousel must retain only the four approved cards');
assert.doesNotMatch(
  todayRenderer.match(/const detailCarousel = createTodayRedesignElement\([\s\S]*?scrollContent\.append/)?.[0] || '',
  /spendingRhythmDetail/,
  'the lower carousel must not mount the retired large rhythm card',
);
assert.doesNotMatch(
  html,
  /spendingRhythm|stage2-redesign-spending-rhythm/,
  'the retired rhythm fixture, renderer, and CSS must be removed rather than merely hidden',
);
assert.match(todayRenderer, /stage2-redesign-average-daily-detail/, 'the Average daily detail card must remain');
assert.match(todayRenderer, /stage2-redesign-variable-budget-dimension/, 'the three-view variable budget card must remain interactive');
assert.doesNotMatch(html, /bufferDaysFixture|createBalanceBufferDaysGauge|stage2-redesign-buffer-days|stage2-redesign-insight-card\.buffer-days/, 'the removed buffer-days FastInfo must leave no compact fixture, renderer, or CSS behind');

const upperInsightRenderer = todayRenderer.match(/const insightGrid = createTodayRedesignElement\([\s\S]*?insightGrid\.append\(noSpend, categoryChange, latestTransaction, trend, upcomingRecurring\.card\);/)?.[0] || '';
assert.equal(
  (upperInsightRenderer.match(/createTodayRedesignInsightCard\(doc,/g) || []).length,
  5,
  'the five compact B3M boxes must be rendered through one shared card helper',
);
assert.match(upperInsightRenderer, /value: `\$\{trendSummary\.percentage\}%`/, 'the 30–60 day card must use only its percentage as its metric');
assert.match(upperInsightRenderer, /secondary: trendCard\.motherMeta/, 'the rhythm card must use the catalogued preceding-30-day comparison baseline');
assert.match(upperInsightRenderer, /direction: trendSummary\.direction/, 'the 30–60 day card must render a direction arrow');
assert.doesNotMatch(upperInsightRenderer, /Mostani 30|trendSummary\.currentTotal|trendSummary\.previousTotal|változó költés nélkül|fixek nélkül|Fix tételek kizárva/, 'the compact cards must omit split rhythm totals and irrelevant fixed-exclusion copy');
assert.doesNotMatch(trendCatalog, /Ismétlődő tranzakciók nélkül|Fix tételek kizárva|fixek nélkül/, 'the compact rhythm catalog copy must not retain a fixed-exclusion qualifier');

const insightCardHelper = html.match(/function createTodayRedesignInsightCard\(doc, config\) \{[\s\S]*?(?=\n\s*function populateTodayRedesignScreen)/)?.[0];
assert.ok(insightCardHelper, 'the compact card renderer must have one shared helper');
assert.match(insightCardHelper, /data-insight-card/, 'the shared helper must identify each compact card');
assert.match(insightCardHelper, /data-include-ghost-transactions/, 'the shared helper must expose the ghost-transaction calculation state');
assert.match(insightCardHelper, /data-ghost-transaction-toggle/, 'every compact card must render its own ghost toggle');
assert.match(insightCardHelper, /aria-pressed/, 'the ghost toggle must expose its inclusion state accessibly');
assert.match(insightCardHelper, /addEventListener\('click'/, 'the ghost toggle must be interactive');
assert.match(insightCardHelper, /ghost\.svg/, 'the ghost toggle must use the ghost icon');
assert.match(insightCardHelper, /return \{ card, body, valueElement, secondaryElement, ghostToggle, setGhostTransactionsIncluded \};/, 'the shared helper must expose the body for the recurring card third middle lane');

class InsightFakeElement {
  constructor(tagName) {
    this.tagName = tagName;
    this.children = [];
    this.attributes = new Map();
    this.listeners = new Map();
    this.style = { setProperty() {} };
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  getAttribute(name) {
    return this.attributes.get(name) ?? null;
  }

  append(...children) {
    this.children.push(...children);
  }

  addEventListener(type, listener) {
    this.listeners.set(type, listener);
  }

  click() {
    this.listeners.get('click')?.();
  }
}

const createTodayRedesignElement = (doc, tagName, className, text) => {
  const element = doc.createElement(tagName);
  element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
};
const createTodayRedesignInsightCard = Function(
  'createTodayRedesignElement',
  `${insightCardHelper}; return createTodayRedesignInsightCard;`,
)(createTodayRedesignElement);
const fakeDoc = { createElement: (tagName) => new InsightFakeElement(tagName) };
const compactInsight = createTodayRedesignInsightCard(fakeDoc, {
  id: 'rhythm',
  title: '30 napos ritmus',
  icon: 'chart-candlestick.svg',
  iconColor: '#7657d9',
  value: '18%',
  secondary: 'Ezt megelőző 30 naphoz képest',
  direction: 'up',
});
assert.equal(compactInsight.card.getAttribute('data-include-ghost-transactions'), 'true', 'ghost transactions must be included by default');
assert.equal(compactInsight.ghostToggle.getAttribute('aria-pressed'), 'true', 'the ghost toggle must start enabled');
assert.equal(compactInsight.body.children[0], compactInsight.valueElement, 'the primary metric must remain the first body child');
assert.equal(compactInsight.body.children[1], compactInsight.secondaryElement, 'the date must remain the second body child before the recurring variant inserts its middle marker');
compactInsight.ghostToggle.click();
assert.equal(compactInsight.card.getAttribute('data-include-ghost-transactions'), 'false', 'clicking the ghost icon must exclude ghost transactions for that card');
assert.equal(compactInsight.ghostToggle.getAttribute('aria-pressed'), 'false', 'the ghost toggle aria state must follow the exclusion state');

assert.match(html, /\.stage2-redesign-insight-card\s*\{[\s\S]*?grid-template-rows:\s*27px minmax\(0,\s*1fr\);[\s\S]*?padding:\s*14px 13px 30px;[\s\S]*?\}/, 'all compact cards must keep their fixed outer padding and ghost-toggle reserve');
assert.doesNotMatch(html, /stage2-redesign-hero-action|stage2-redesign-hero-chart|today-redesign-hero-chart-shift/, 'the removed hero controls and decorative stripe must leave no CSS or scroll-state residue');
assert.match(html, /\.stage2-redesign-insight-card\s*\{[\s\S]*?flex:\s*0 0 calc\(\(100% - 18px\) \/ 3\);[\s\S]*?min-height:\s*128px;[\s\S]*?\}/, 'the upper rail must retain its fixed three-card geometry');
assert.match(html, /\.stage2-redesign-layout\s*\{[\s\S]*?grid-template-rows:\s*49px 201px 128px 210px 65px 41px 39px 55px;/, 'the B3M layout must retain the fixed compact-rail height');
assert.match(html, /\.stage2-redesign-insight-head\s*\{[\s\S]*?grid-template-columns:\s*27px minmax\(0,\s*1fr\);[\s\S]*?\}/, 'all compact cards must align the icon and title in one shared header row');
assert.match(html, /\.stage2-redesign-insight-body\s*\{[\s\S]*?padding-left:\s*0;[\s\S]*?justify-items:\s*center;[\s\S]*?text-align:\s*center;[\s\S]*?\}/, 'compact card body content must use the full width while remaining centered below the header');
assert.match(html, /\.stage2-redesign-insight-body\s*\{[\s\S]*?align-self:\s*stretch;[\s\S]*?grid-template-rows:\s*22px minmax\(0,\s*1fr\);[\s\S]*?align-content:\s*stretch;[\s\S]*?\}/, 'the card body must reserve a fixed primary lane and a separate secondary lane');
assert.match(html, /\.stage2-redesign-insight-value\s*\{[\s\S]*?grid-row:\s*1;[\s\S]*?align-self:\s*start;[\s\S]*?\}/, 'every primary metric must stay in the fixed upper lane');
assert.match(html, /\.stage2-redesign-insight-meta\s*\{[\s\S]*?grid-row:\s*2;[\s\S]*?align-self:\s*end;[\s\S]*?\}/, 'secondary copy must use the lower lane and grow upward only when it needs another line');
assert.match(html, /\.stage2-redesign-category-change-metrics\s*\{[\s\S]*?justify-content:\s*center;[\s\S]*?\}/, 'the category-change metric line must stay centered with the widened body');
assert.match(html, /\.stage2-redesign-insight-ghost-toggle\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?right:\s*9px;[\s\S]*?bottom:\s*8px;[\s\S]*?\}/, 'every compact card ghost control must stay in the bottom-right corner');
assert.match(html, /\.stage2-redesign-insight-card\.trend-comparison\[data-trend-direction="up"\]\s+\.stage2-redesign-insight-value,[\s\S]*?\.stage2-redesign-insight-card\.trend-comparison\[data-trend-direction="up"\]\s+\.stage2-redesign-insight-direction\s*\{[\s\S]*?color:\s*#ef4173;/, 'positive 30-day rhythm values and arrows must be red');
assert.match(html, /\.stage2-redesign-insight-card\.trend-comparison\[data-trend-direction="down"\]\s+\.stage2-redesign-insight-value,[\s\S]*?\.stage2-redesign-insight-card\.trend-comparison\[data-trend-direction="down"\]\s+\.stage2-redesign-insight-direction\s*\{[\s\S]*?color:\s*#16a36a;/, 'negative 30-day rhythm values and arrows must be green');
assert.match(html, /\.stage2-redesign-insight-card\.category-change\s+\.stage2-redesign-insight-value\s*\{[\s\S]*?color:\s*#ef4173;/, 'category-change values must remain red regardless of direction');
assert.match(html, /\.stage2-redesign-insight-icon\s*\{[\s\S]*?width:\s*27px;[\s\S]*?height:\s*27px;[\s\S]*?background:\s*#f0efff;[\s\S]*?\}/, 'every FastInfo header must share the same neutral icon frame');
assert.match(html, /\.stage2-redesign-insight-icon-glyph\s*\{[\s\S]*?color:\s*#5f55ec;[\s\S]*?\}/, 'the recurring repeat glyph must inherit the standard FastInfo header tone');
assert.doesNotMatch(html, /\.stage2-redesign-insight-card\.upcoming-recurring\s+\.stage2-redesign-insight-icon\s*\{/, 'the recurring card must not override the shared header icon layout with category color');
assert.match(html, /\.stage2-redesign-upcoming-recurring-value\s*\{[\s\S]*?display:\s*flex;[\s\S]*?width:\s*100%;[\s\S]*?justify-content:\s*center;[\s\S]*?gap:\s*6px;[\s\S]*?\}/, 'the Netflix name and amount must regain their normal primary-row spacing');
assert.match(html, /\.stage2-redesign-insight-card\.upcoming-recurring\s+\.stage2-redesign-insight-body\s*\{[\s\S]*?grid-template-rows:\s*12px 16px minmax\(10px,\s*1fr\);[\s\S]*?row-gap:\s*2px;[\s\S]*?\}/, 'the recurring card must reserve distinct Netflix, avatar, and date rows with padding between them');
assert.match(html, /\.stage2-redesign-upcoming-recurring-mini-avatar\s*\{[\s\S]*?grid-column:\s*1;[\s\S]*?grid-row:\s*2;[\s\S]*?display:\s*grid;[\s\S]*?align-self:\s*center;[\s\S]*?width:\s*16px;[\s\S]*?height:\s*16px;[\s\S]*?background:\s*var\(--today-recurring-category-color,\s*#8b5cf6\);[\s\S]*?\}/, 'the mini category avatar must occupy only the centered middle row');
assert.match(html, /\.stage2-redesign-insight-card\.upcoming-recurring\s+\.stage2-redesign-upcoming-recurring-date\s*\{[\s\S]*?grid-column:\s*1;[\s\S]*?grid-row:\s*3;[\s\S]*?align-self:\s*end;[\s\S]*?\}/, 'the recurring date must remain below the mini avatar in its own lower row');
assert.match(html, /\.stage2-redesign-upcoming-recurring-mini-avatar\s+\.slot-icon\s*\{[\s\S]*?width:\s*9px;[\s\S]*?height:\s*9px;[\s\S]*?\}/, 'the mini category avatar must remain visibly smaller than the header avatar');

assert.match(html, /const upcomingRecurringCard = catalog\.find\(\(card\) => card\.id === upcomingRecurringCardId\);/, 'the B3M renderer must resolve the recurring card from the catalog');
assert.match(html, /card\.id !== upcomingRecurringCardId/, 'the recurring compact card must not become its own B3M screen');
assert.match(html, /populateTodayRedesignScreen\(todayB3mAColumn, card, topCategoriesCard, categoryChangeCard, latestTransactionCard, averageDailyCard, trendCard, upcomingRecurringCard\);/, 'the resolved recurring card must be passed only into the B3M-A screen');

const pulseFixtureMatch = html.match(/const pulseForecastGalleryFixture = (\[[\s\S]*?\n\s*\]);/);
assert.ok(pulseFixtureMatch, 'the eight Pulse chart cards need an explicit fixture');
const pulseForecastGalleryFixture = Function('return (' + pulseFixtureMatch[1] + ')')();
assert.deepEqual(
  pulseForecastGalleryFixture.map((entry) => entry.id),
  ['PF-01', 'PF-02', 'PF-03', 'PF-04', 'PF-05', 'PF-06', 'PF-07', 'PF-08'],
  'the row must contain exactly the eight requested Pulse chart cards',
);
assert.deepEqual(
  pulseForecastGalleryFixture.map((entry) => entry.reference),
  ['HF-001', 'HF-002', 'HF-020', 'HF-005 · HF-006 · HF-007', 'HF-009 · HF-010', 'HF-011', 'HF-012 · HF-013 · HF-014', 'HF-021'],
  'the row must preserve the eight source function references',
);
assert.ok(
  pulseForecastGalleryFixture.every((entry) => entry.title && entry.chart && entry.description),
  'every Pulse card must have a title, chart key, and short explanation',
);
const balanceBufferCard = pulseForecastGalleryFixture.find((entry) => entry.id === 'PF-06');
assert.ok(balanceBufferCard, 'the Balance buffer days card must remain in the Pulse row');
assert.match(balanceBufferCard.description, /31 napos puffer/, 'the buffer card must explain the visible 31-day result');
assert.match(balanceBufferCard.description, /30 napos változó költési tempó/, 'the buffer card must name the rolling variable-spend basis');
assert.match(balanceBufferCard.description, /fix és várt tételek/, 'the buffer card must distinguish fixed and expected items from the buffer calculation');

const pulseChartRenderer = html.match(/function createPulseForecastChart\(doc, chartId, ariaLabel\) \{[\s\S]*?(?=\n\s*function createPulseForecastGallery)/)?.[0];
assert.ok(pulseChartRenderer, 'the Pulse charts need a dedicated SVG renderer');
assert.match(pulseChartRenderer, /createElementNS\('http:\/\/www\.w3\.org\/2000\/svg', 'svg'\)/, 'each Pulse visualization must be SVG');
for (const chart of pulseForecastGalleryFixture.map((entry) => entry.chart)) {
  assert.match(pulseChartRenderer, new RegExp("'" + chart + "'"), 'the SVG renderer must draw ' + chart);
}
assert.match(pulseChartRenderer, /data-pulse-buffer-zone="critical"/, 'the expanded buffer gauge must show its critical zone');
assert.match(pulseChartRenderer, /data-pulse-buffer-zone="watch"/, 'the expanded buffer gauge must show its watch zone');
assert.match(pulseChartRenderer, /data-pulse-buffer-zone="stable"/, 'the expanded buffer gauge must show its stable zone');
assert.match(pulseChartRenderer, /egyenleg ÷ rolling 30 napos változó költés/, 'the expanded buffer gauge must expose its calculation in the graphic');

const pulseGalleryRenderer = html.match(/function createPulseForecastGallery\(doc\) \{[\s\S]*?(?=\n\s*function setB3MContent)/)?.[0];
assert.ok(pulseGalleryRenderer, 'the Pulse gallery needs a separate canvas renderer');
assert.match(pulseGalleryRenderer, /data-pulse-forecast-gallery', 'true'/, 'the gallery must be directly addressable');
assert.match(pulseGalleryRenderer, /data-pulse-forecast-card', forecast\.id/, 'each card must expose its Pulse ID');
assert.match(pulseGalleryRenderer, /header,\s*createPulseForecastChart\([\s\S]*?description/, 'each card must contain only header, SVG chart, and description');
assert.doesNotMatch(pulseGalleryRenderer, /metric-strip|user-defined|<input|<select|document\.createElement\('input'\)|document\.createElement\('select'\)/, 'the B3M gallery must omit metrics and tuning controls');

assert.match(html, /installPulseForecastGalleryStyles\(doc\);/, 'the B3M canvas must install the dedicated gallery styling');
assert.match(html, /const pulseForecastGallery = createPulseForecastGallery\(doc\);\s*mode\.append\(carouselRow, pulseForecastGallery\);/, 'the gallery must be below the B3M screen row, outside the phone scroll surface');
assert.match(html, /surface\.style\.minHeight = 'calc\(var\(--screen-h\) \+ 338px\)'/, 'the canvas must reserve vertical room below the phone screens');
assert.match(html, /\.pulse-forecast-gallery-row \{[\s\S]*?display: flex;/, 'the eight cards must render on one horizontal row');
assert.match(html, /\.pulse-forecast-card \{[\s\S]*?width: 252px;/, 'the Pulse cards must use a stable compact card width');
assert.match(html, /\.pulse-forecast-description \{/, 'each chart card must have its short explanation style');

const sourceForecasts = [
  'Month-end expense forecast',
  'Monthly category limit burn',
  'Yearly category limit burn',
  'Ghost income + fixed load',
  'Cashflow ratio + saving goal',
  'Balance buffer days',
  'Behavior shift',
  'Data quality status',
];
for (const title of sourceForecasts) {
  assert.match(pulseSource, new RegExp(title.replace(/[+?]/g, '\\$&')), 'the Pulse source must contain ' + title);
  assert.ok(pulseForecastGalleryFixture.some((entry) => entry.title === title), 'the B3M gallery must copy ' + title);
}

console.log('balance B3M compact rhythm + Pulse forecast gallery static contract passed');
