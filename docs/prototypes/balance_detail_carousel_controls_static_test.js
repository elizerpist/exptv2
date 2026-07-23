#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', '..');
const layoutPath = path.join(root, 'balance_latest_layout.html');
const html = fs.readFileSync(layoutPath, 'utf8');

const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((match) => match[1]);
assert.equal(scripts.length, 1, 'the B3M prototype must keep one inspectable inline renderer');
for (const script of scripts) new Function(script);

const detailGhostToggleHelper = html.match(/function createTodayRedesignDetailGhostToggle\(doc, card, id\) \{[\s\S]*?(?=\n\s*function populateTodayRedesignScreen)/)?.[0];
assert.ok(detailGhostToggleHelper, 'lower detail cards need a shared ghost-toggle helper');
assert.match(detailGhostToggleHelper, /data-ghost-transaction-toggle/, 'the lower ghost control must identify its owner card');
assert.match(detailGhostToggleHelper, /data-include-ghost-transactions/, 'the lower card must expose its inclusion state');
assert.match(detailGhostToggleHelper, /aria-pressed/, 'the lower ghost control must expose its state accessibly');
assert.match(detailGhostToggleHelper, /ghost\.svg/, 'the lower ghost control must use the ghost icon');
assert.match(detailGhostToggleHelper, /addEventListener\('click'/, 'the lower ghost control must be interactive');

class FakeElement {
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
const createTodayRedesignDetailGhostToggle = Function(
  'createTodayRedesignElement',
  `${detailGhostToggleHelper}; return createTodayRedesignDetailGhostToggle;`,
)(createTodayRedesignElement);
const fakeDoc = { createElement: (tagName) => new FakeElement(tagName) };
const detailCard = fakeDoc.createElement('article');
const detailGhostToggle = createTodayRedesignDetailGhostToggle(fakeDoc, detailCard, 'top-categories');
assert.equal(detailCard.getAttribute('data-include-ghost-transactions'), 'true', 'lower cards must include ghost transactions by default');
assert.equal(detailGhostToggle.getAttribute('aria-pressed'), 'true', 'the lower ghost control must start enabled');
detailGhostToggle.click();
assert.equal(detailCard.getAttribute('data-include-ghost-transactions'), 'false', 'clicking the lower ghost control must exclude ghost transactions for that card');
assert.equal(detailGhostToggle.getAttribute('aria-pressed'), 'false', 'the lower ghost control aria state must follow exclusion');

const todayRenderer = html.match(/function populateTodayRedesignScreen\([\s\S]*?(?=\n\s*function installPulseForecastGalleryStyles)/)?.[0];
assert.ok(todayRenderer, 'the B3M-A renderer must remain inspectable');
const detailRenderer = todayRenderer.match(/const detail = createTodayRedesignElement\([\s\S]*?(?=\n\s*const actions)/)?.[0] || '';
assert.deepEqual(
  [...detailRenderer.matchAll(/createTodayRedesignDetailGhostToggle\(doc, ([a-zA-Z]+), '([^']+)'\)/g)].map((match) => [match[1], match[2]]),
  [
    ['detail', 'variable-budget'],
    ['topCategoriesDetail', 'top-categories'],
    ['topMerchantsDetail', 'top-merchants'],
    ['averageDailyDetail', 'average-daily'],
  ],
  'each of the four lower detail cards must own one ghost control',
);

const topCategoriesRenderer = detailRenderer.match(/const topCategoriesDetail = createTodayRedesignElement\([\s\S]*?(?=\n\s*const topMerchantsDetail)/)?.[0] || '';
const averageDailyRenderer = detailRenderer.match(/const averageDailyDetail = createTodayRedesignElement\([\s\S]*?(?=\n\s*const detailCarousel)/)?.[0] || '';
assert.doesNotMatch(topCategoriesRenderer, /Fix tételek kizárva/, 'Top kategóriák must not retain its stale fixed-exclusion copy');
assert.doesNotMatch(averageDailyRenderer, /Fix tételek kizárva/, 'Átlagos napi költés must not retain its stale fixed-exclusion copy');
assert.doesNotMatch(html, /stage2-redesign-top-categories-scope|stage2-redesign-average-daily-scope/, 'removed fixed-exclusion scope styles must not remain');

const topMerchantsRenderer = detailRenderer.match(/const topMerchantsDetail = createTodayRedesignElement\([\s\S]*?(?=\n\s*const averageDailyDetail)/)?.[0] || '';
assert.match(topMerchantsRenderer, /topMerchantsDetail\.append\(\s*topMerchantsTopline,\s*topMerchantsList,/, 'Top 5 kereskedő must mount its list directly below the title and dimension pills');
assert.doesNotMatch(topMerchantsRenderer, /stage2-redesign-detail-divider/, 'Top 5 kereskedő must not put a separator under the dimension pills');
assert.match(html, /\.stage2-redesign-top-merchants-detail\s*\{[\s\S]*?grid-template-rows:\s*18px minmax\(0,\s*1fr\);[\s\S]*?\}/, 'the merchant card grid must drop the removed separator row');

assert.doesNotMatch(todayRenderer, /detailCarouselIndicators|detailCarouselIndicatorButtons|data-detail-carousel-indicator|syncDetailCarouselIndicator|setActiveDetailCarouselIndex/, 'the lower carousel must not retain an indicator row or its paging state');
assert.match(todayRenderer, /detailCarousel\.append\(detail, topCategoriesDetail, topMerchantsDetail, averageDailyDetail\);/, 'the lower carousel must remain the direct four-card swipe surface');
assert.match(todayRenderer, /scrollContent\.append\(insightGrid, detailCarousel, postBudgetContent\);/, 'the post-budget content must follow the carousel directly in both modes');
assert.doesNotMatch(html, /stage2-redesign-detail-carousel-indicator/, 'the removed dots must leave no indicator CSS behind');
assert.match(html, /\.stage2-redesign-detail-ghost-toggle\s*\{[\s\S]*?position:\s*absolute;[\s\S]*?right:\s*11px;[\s\S]*?bottom:\s*10px;[\s\S]*?\}/, 'each lower ghost control must sit in its card bottom-right corner');

console.log('balance lower detail carousel ghost controls static contract passed');
