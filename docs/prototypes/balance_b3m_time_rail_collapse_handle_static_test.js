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

const interactionStyles = html.match(/function installTodayRedesignInteractionStyles\(doc\) \{[\s\S]*?(?=\n\s*function attachTodayRedesignScrollInteraction)/)?.[0];
const scrollController = html.match(/function attachTodayRedesignScrollInteraction\(screen, headerViewport, transactionViewport\) \{[\s\S]*?(?=\n\s*function installBudgetModeStyles)/)?.[0];
const createTimeScope = html.match(/function createTodayTimeScopeDrawer\(doc[^)]*\) \{[\s\S]*?(?=\n\s*function attachTodayTimeScopeDrawer)/)?.[0];
assert.ok(interactionStyles, 'the shared interaction styles must remain inspectable');
assert.ok(scrollController, 'the shared collapse controller must remain inspectable');
assert.ok(createTimeScope, 'the shared time-scope factory must remain inspectable');

const exitViewportRule = interactionStyles.match(/\[data-today-redesign-screen="true"\]\[data-today-budget-pill-behavior="exit"\] \.stage2-redesign-scroll-viewport\s*\{([^}]*)\}/)?.[1] || '';
assert.match(exitViewportRule, /overflow-y:\s*hidden;/, 'exit-mode screens must disable native full-screen vertical scrolling');

const controlRule = interactionStyles.match(/\[data-today-redesign-screen="true"\]\[data-today-budget-pill-behavior="exit"\] \.stage2-redesign-time-scope-control\s*\{([^}]*)\}/)?.[1] || '';
assert.match(controlRule, /position:\s*relative;/, 'the existing time-scope control row must position its inline handle');
assert.match(controlRule, /min-height:\s*21px;/, 'the existing time-scope control row height must remain unchanged');

const handleRule = interactionStyles.match(/\[data-today-redesign-screen="true"\]\[data-today-budget-pill-behavior="exit"\] \.stage2-redesign-collapse-handle\s*\{([^}]*)\}/)?.[1] || '';
assert.match(handleRule, /position:\s*absolute;/, 'the handle must not add another layout row');
assert.match(handleRule, /top:\s*0;/, 'the handle must stay inside the existing free control strip');
assert.match(handleRule, /left:\s*50%;/, 'the handle must be centered above the year rail');
assert.match(handleRule, /height:\s*21px;/, 'the handle hit area must fit the unchanged control-row height');
assert.match(handleRule, /touch-action:\s*none;/, 'the handle must exclusively own its vertical pointer gesture');
assert.match(handleRule, /transform:\s*translateX\(-50%\);/, 'absolute centering must not consume flow space');

const expandedDrawerRule = interactionStyles.match(/\.stage2-redesign-time-scope\[data-time-scope-drawer-state="expanded"\] \.stage2-redesign-time-scope-year-drawer\s*\{([^}]*)\}/)?.[1] || '';
const yearRailRule = interactionStyles.match(/\[data-today-redesign-screen="true"\]\[data-today-budget-pill-behavior="exit"\] \.stage2-redesign-time-scope-year-rail\s*\{([^}]*)\}/)?.[1] || '';
assert.match(expandedDrawerRule, /max-height:\s*51px;/, 'the year drawer height must not grow for the handle');
assert.match(expandedDrawerRule, /margin-top:\s*7px;/, 'the existing year-drawer offset must remain unchanged');
assert.match(yearRailRule, /min-height:\s*37px;/, 'the year-pill rail height must remain unchanged');

assert.match(createTimeScope, /const collapseHandle = createTodayRedesignElement\(doc, 'button', 'stage2-redesign-collapse-handle'\);/, 'the shared time-scope factory must create a real handle button');
assert.match(createTimeScope, /collapseHandle\.setAttribute\('data-today-collapse-handle', 'true'\);/, 'the shared controller needs a stable local handle marker');
assert.match(createTimeScope, /createTodayRedesignElement\(doc, 'i', 'stage2-redesign-collapse-handle-bar'\)/, 'the visible handle must contain the requested compact bar');
assert.match(createTimeScope, /createTodayRedesignElement\(doc, 'span', 'stage2-redesign-collapse-handle-label', 'Húzd a nézetet'\)/, 'the handle must contain a short explicit instruction');
assert.match(createTimeScope, /control\.append\(collapseHandle\);/, 'the handle must be part of the existing rail control container');

assert.match(scrollController, /const collapseHandle = screen\.querySelector\('\[data-today-collapse-handle="true"\]'\);/, 'every clone must resolve its own local handle');
assert.match(scrollController, /const requiresCollapseHandle = budgetPillBehavior === 'exit';/, 'only current exit-mode screens must require rail-owned collapse');
assert.match(scrollController, /\(requiresCollapseHandle && !collapseHandle\)/, 'an exit-mode clone may not silently fall back to full-screen dragging');
assert.match(scrollController, /collapseHandle\.addEventListener\('pointerdown', beginCollapseHandleDrag\);/, 'collapse dragging must begin only on the handle');
assert.match(scrollController, /collapseHandle\.addEventListener\('pointermove', updateCollapseHandleDrag\);/, 'collapse progress must be driven only by handle pointer movement');
assert.match(scrollController, /collapseHandle\.addEventListener\('pointerup', finishCollapseHandleDrag\);/, 'handle release must settle collapse progress');
assert.match(scrollController, /collapseHandle\.addEventListener\('pointercancel', finishCollapseHandleDrag\);/, 'cancelled handle gestures must settle safely');
assert.match(scrollController, /collapseHandle\.setPointerCapture\?\.\(event\.pointerId\);/, 'the handle must retain an active drag outside its small visual bounds');
assert.match(scrollController, /headerViewport\.scrollTop = clamp\(collapsePointerStartScrollTop - deltaY, 0, collapseDistance\);/, 'upward and downward handle motion must map to collapse and expand offsets');
assert.match(scrollController, /const collapseTarget = headerViewport\.scrollTop >= collapseDistance \/ 2\s*\? collapseDistance\s*:\s*0;/, 'release must settle to the nearest endpoint');
assert.match(scrollController, /collapseHandle\.addEventListener\('click', toggleCollapseFromHandle\);/, 'tap and native button keyboard activation must toggle the view');
assert.match(scrollController, /budgetPill\.addEventListener\('click', expand\);/, 'the existing compact-pill expand path must remain available');
assert.match(scrollController, /headerViewport\.addEventListener\('scroll', scheduleUpdate, \{ passive: true \}\);/, 'programmatic viewport scrolling must still drive the shared animation');
assert.doesNotMatch(scrollController, /(?:screen|headerViewport)\.addEventListener\('pointer(?:down|move|up)'/, 'the full screen and viewport must not receive collapse pointer listeners');
assert.doesNotMatch(scrollController, /(?:screen|headerViewport)\.addEventListener\('touch(?:start|move|end)'/, 'the full screen and viewport must not receive collapse touch listeners');

class MockTarget {
  constructor() {
    this.listeners = new Map();
    this.attributes = new Map();
    this.style = {
      setProperty: (name, value) => {
        this.style[name] = value;
      },
    };
  }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) || [];
    listeners.push(listener);
    this.listeners.set(type, listeners);
  }

  emit(type, overrides = {}) {
    const event = {
      type,
      isPrimary: true,
      pointerType: 'touch',
      button: 0,
      defaultPrevented: false,
      preventDefault() {
        this.defaultPrevented = true;
      },
      ...overrides,
    };
    for (const listener of this.listeners.get(type) || []) listener(event);
    return event;
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  getAttribute(name) {
    return this.attributes.get(name) || null;
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  setPointerCapture(pointerId) {
    this.pointerCapture = pointerId;
  }

  hasPointerCapture(pointerId) {
    return this.pointerCapture === pointerId;
  }

  releasePointerCapture(pointerId) {
    if (this.pointerCapture === pointerId) this.pointerCapture = null;
  }
}

const attachScrollInteraction = new Function(`${scrollController}; return attachTodayRedesignScrollInteraction;`)();
const rafQueue = [];
const timerQueue = [];
const windowRef = {
  matchMedia: () => ({ matches: false }),
  requestAnimationFrame(callback) {
    rafQueue.push(callback);
    return rafQueue.length;
  },
  setTimeout(callback) {
    timerQueue.push(callback);
    return timerQueue.length;
  },
};
const flushAnimationFrames = () => {
  while (rafQueue.length) rafQueue.shift()();
};
const flushTimers = () => {
  while (timerQueue.length) timerQueue.shift()();
};

const layout = new MockTarget();
const insightGrid = new MockTarget();
const detailCarousel = new MockTarget();
const budgetPill = new MockTarget();
const collapseHandle = new MockTarget();
const headerViewport = new MockTarget();
headerViewport.scrollTop = 0;
headerViewport.scrollTo = ({ top }) => {
  headerViewport.scrollTop = top;
  headerViewport.emit('scroll');
};
const transactionViewport = new MockTarget();
transactionViewport.scrollTop = 0;
transactionViewport.scrollHeight = 100;
transactionViewport.clientHeight = 100;

const surfaces = new Map([
  ['.stage2-redesign-layout', layout],
  ['.stage2-redesign-insight-grid', insightGrid],
  ['.stage2-redesign-detail-carousel', detailCarousel],
  ['.stage2-redesign-budget-pill', budgetPill],
  ['[data-today-collapse-handle="true"]', collapseHandle],
]);
const screen = {
  dataset: {
    todayBudgetPillBehavior: 'exit',
    todayRedesignDensity: 'time-rail-compact',
  },
  ownerDocument: { defaultView: windowRef },
  querySelector: (selector) => surfaces.get(selector) || null,
};

attachScrollInteraction(screen, headerViewport, transactionViewport);
assert.equal(screen.dataset.todayRedesignState, 'expanded', 'the controller must initialize in expanded state');
assert.equal(headerViewport.listeners.has('pointerdown'), false, 'the viewport must have no pointerdown behavior at runtime');
assert.equal(headerViewport.listeners.has('pointermove'), false, 'the viewport must have no pointermove behavior at runtime');

collapseHandle.emit('pointerdown', { pointerId: 1, clientY: 120 });
const upwardMove = collapseHandle.emit('pointermove', { pointerId: 1, clientY: 20 });
assert.equal(upwardMove.defaultPrevented, true, 'an active handle drag must consume its own vertical movement');
assert.equal(headerViewport.scrollTop, 100, 'an upward handle drag must increase collapse progress');
collapseHandle.emit('pointerup', { pointerId: 1, clientY: 20 });
flushAnimationFrames();
assert.equal(headerViewport.scrollTop, 180, 'an upward release beyond halfway must settle collapsed');
assert.equal(screen.dataset.todayRedesignState, 'collapsed', 'the shared state must report the collapsed endpoint');

flushTimers();
collapseHandle.emit('pointerdown', { pointerId: 2, clientY: 20 });
collapseHandle.emit('pointermove', { pointerId: 2, clientY: 220 });
collapseHandle.emit('pointerup', { pointerId: 2, clientY: 220 });
flushAnimationFrames();
assert.equal(headerViewport.scrollTop, 0, 'a downward handle drag must settle expanded');
assert.equal(screen.dataset.todayRedesignState, 'expanded', 'the shared state must report the expanded endpoint');

flushTimers();
collapseHandle.emit('click');
flushAnimationFrames();
assert.equal(headerViewport.scrollTop, 180, 'native button activation must toggle to collapsed');
collapseHandle.emit('click');
flushAnimationFrames();
assert.equal(headerViewport.scrollTop, 0, 'a second native button activation must toggle back to expanded');

console.log('B3M time-rail-only collapse handle static contract passed');
