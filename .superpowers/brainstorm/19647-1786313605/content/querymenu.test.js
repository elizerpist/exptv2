'use strict';

const fs = require('fs');
const vm = require('vm');

const htmlPath = process.argv[2];
if (!htmlPath) throw new Error('Pass querymenu.html as the first argument.');

const html = fs.readFileSync(htmlPath, 'utf8');
const script = html.match(/<script>([\s\S]*)<\/script>/)?.[1];
if (!script) throw new Error('querymenu.html has no executable script.');

function fakeElement() {
  return {
    innerHTML: '',
    textContent: '',
    value: '',
    style: {setProperty() {}},
    classList: {toggle() {}, add() {}, remove() {}},
    setAttribute() {},
  };
}

function runProbe() {
  const nodes = new Map();
  const document = {
    querySelector(selector) {
      if (!nodes.has(selector)) nodes.set(selector, fakeElement());
      return nodes.get(selector);
    },
    addEventListener() {},
  };
  const context = {document, structuredClone, setTimeout: () => 0, clearTimeout() {}};
  vm.createContext(context);
  vm.runInContext(
    `${script}
      const initialMainCategoryMarkup = document.querySelector('[data-category-row]').innerHTML;
      const initialMainPartnerMarkup = document.querySelector('[data-partner-row]').innerHTML;
      draft.categoryPartnerOverrides = {food: ['tesco']};
      const narrowedCount = total(filteredRecords(draft));
      restrictCategoryToChild(draft, 'food', 'tesco');
      const restoredCount = total(filteredRecords(draft));
      const restoredOverride = draft.categoryPartnerOverrides.food;
      const amountRangeAvailable = typeof amountDomain === 'function';
      let amountRangeProbe = null;
      if (amountRangeAvailable) {
        draft = clone(initial);
        const beforeAmountDomain = amountDomain(draft);
        const unboundedCount = total(filteredRecords(draft));
        draft.minimum = String(Math.ceil(beforeAmountDomain.maximum / 2));
        draft.maximum = String(Math.floor(beforeAmountDomain.maximum * 0.75));
        const boundedAmountDomain = amountDomain(draft);
        amountRangeProbe = {
          beforeAmountDomain,
          boundedAmountDomain,
          unboundedCount,
          boundedCount: total(filteredRecords(draft)),
        };
      }
      const headerSummaryAvailable =
        typeof formatPeriodSummary === 'function' &&
        typeof formatFacetSummary === 'function' &&
        typeof renderHeaderSummary === 'function';
      let headerSummaryProbe = null;
      if (headerSummaryAvailable) {
        const periodIds = (year, from, to) => Array.from(
          {length: to - from + 1},
          (_, index) => String(year) + '-' + String(from + index).padStart(2, '0'),
        );
        const nonContiguousEleven = [
          ...periodIds(2026, 1, 5),
          ...periodIds(2026, 7, 12),
        ];
        draft = {
          periods: periodIds(2026, 1, 11),
          partners: ['tesco', 'mol', 'shell'],
          categories: ['food', 'transport', 'home'],
          categoryPartnerOverrides: {},
          minimum: '',
          maximum: '',
          note: '',
        };
        renderHeaderSummary();
        headerSummaryProbe = {
          oneMonth: formatPeriodSummary(['2026-02']),
          contiguous: formatPeriodSummary(periodIds(2026, 1, 11)),
          nonContiguousEleven: formatPeriodSummary(nonContiguousEleven),
          wholeYear: formatPeriodSummary(periodIds(2026, 1, 12)),
          multipleYears: formatPeriodSummary([...periodIds(2025, 1, 12), ...periodIds(2026, 1, 2)]),
          category: formatFacetSummary(draft.categories, categoryById),
          partner: formatFacetSummary(draft.partners, (id) => partners.find((partner) => partner.id === id)),
          headerMarkup: document.querySelector('[data-query-summary-line]').innerHTML,
          headerCount: document.querySelector('[data-query-summary-count]').textContent,
        };
      }
      draft = clone(initial);
      draft.categories = ['food', 'transport', 'home'];
      draft.partners = ['tesco', 'mol', 'shell'];
      renderCategories();
      const allExplicitCategoryMarkup = document.querySelector('[data-category-row]').innerHTML;
      renderPartners();
      const allExplicitPartnerMarkup = document.querySelector('[data-partner-row]').innerHTML;
      const categoryPickerMorphAvailable =
        typeof openCategoryPicker === 'function' &&
        typeof closeCategoryPicker === 'function' &&
        typeof finishCategoryPickerEntrance === 'function';
      let categoryPickerMorphProbe = null;
      if (categoryPickerMorphAvailable) {
        draft = clone(initial);
        openCategoryPicker({dataset: {pickerSource: 'category-preview'}});
        const opened = categoryPickerOpen;
        renderCategoryPicker();
        finishCategoryPickerEntrance();
        toggleCategory('transport');
        renderCategoryPicker();
        const selectedPickerMarkup = document.querySelector('[data-category-picker-list]').innerHTML;
        closeCategoryPicker();
        renderCategories();
        categoryPickerMorphProbe = {
          opened,
          closed: !categoryPickerOpen,
          selectedPickerMarkup,
          rowsStaySteadyAfterToggle: !selectedPickerMarkup.includes('picker-row-enter'),
          returnedPreviewMarkup: document.querySelector('[data-category-row]').innerHTML,
        };
      }
      const partnerPickerMorphAvailable =
        typeof openPartnerPicker === 'function' &&
        typeof closePartnerPicker === 'function' &&
        typeof finishPartnerPickerEntrance === 'function';
      let partnerPickerMorphProbe = null;
      if (partnerPickerMorphAvailable) {
        draft = clone(initial);
        draft.partners = ['mol'];
        openPartnerPicker({dataset: {pickerSource: 'partner-add'}});
        const opened = partnerPickerOpen;
        renderPartnerPicker();
        finishPartnerPickerEntrance();
        renderPartnerPicker();
        const selectedPickerMarkup = document.querySelector('[data-partner-picker-list]').innerHTML;
        closePartnerPicker();
        renderPartners();
        partnerPickerMorphProbe = {
          opened,
          closed: !partnerPickerOpen,
          rowsStaySteadyAfterOpen: !selectedPickerMarkup.includes('picker-row-enter'),
          selectedPickerMarkup,
          returnedPreviewMarkup: document.querySelector('[data-partner-row]').innerHTML,
        };
      }
      globalThis.__probe = {
        narrowedCount,
        restoredCount,
        override: restoredOverride,
        categoryCatalogCount: categories.length,
        mainCategoryMarkup: initialMainCategoryMarkup,
        pickerCategoryMarkup: document.querySelector('[data-category-picker-list]').innerHTML,
        mainPartnerMarkup: initialMainPartnerMarkup,
        allExplicitCategoryMarkup,
        allExplicitPartnerMarkup,
        pickerPartnerMarkup: document.querySelector('[data-partner-picker-list]').innerHTML,
        amountRangeAvailable,
        amountRangeProbe,
        headerSummaryAvailable,
        headerSummaryProbe,
        categoryPickerMorphAvailable,
        categoryPickerMorphProbe,
        partnerPickerMorphAvailable,
        partnerPickerMorphProbe,
      };`,
    context,
  );
  return context.__probe;
}

function runSavedFilterProbe() {
  const nodes = new Map();
  const saved = new Map();
  const document = {
    querySelector(selector) {
      if (!nodes.has(selector)) nodes.set(selector, fakeElement());
      return nodes.get(selector);
    },
    addEventListener() {},
  };
  const localStorage = {
    getItem(key) { return saved.get(key) ?? null; },
    setItem(key, value) { saved.set(key, String(value)); },
  };
  const context = {document, localStorage, structuredClone, setTimeout: () => 0, clearTimeout() {}};
  vm.createContext(context);
  vm.runInContext(
    `${script}
      const first = saveCurrentQuery('Havi élelmiszer');
      const persistedAfterSave = JSON.parse(localStorage.getItem(savedFiltersStorageKey));
      draft.minimum = '5000';
      const dirtyBeforeUpdate = isActiveSavedQueryDirty();
      const updated = updateActiveSavedQuery();
      const dirtyAfterUpdate = isActiveSavedQueryDirty();
      const second = saveCurrentQuery('Nagybevásárlás');
      renameSavedQuery(second.id, 'Havi nagybevásárlás');
      const renamed = savedQueryById(second.id).name;
      const savedBeforeReset = savedQueries.length;
      draft = {periods: [], partners: [], categories: [], categoryPartnerOverrides: {}, minimum: '', maximum: '', note: ''};
      activeSavedQueryId = null;
      const savedAfterReset = savedQueries.length;
      const loaded = loadSavedQuery(first.id);
      deleteSavedQuery(second.id);
      globalThis.__savedProbe = {
        first,
        persistedAfterSave,
        dirtyBeforeUpdate,
        updated,
        dirtyAfterUpdate,
        renamed,
        savedBeforeReset,
        savedAfterReset,
        loaded,
        loadedMinimum: draft.minimum,
        savedAfterDelete: savedQueries.length,
      };`,
    context,
  );
  return context.__savedProbe;
}

function runDashboardFacetProbe() {
  const nodes = new Map();
  const document = {
    querySelector(selector) {
      if (!nodes.has(selector)) nodes.set(selector, fakeElement());
      return nodes.get(selector);
    },
    addEventListener() {},
  };
  const context = {document, structuredClone, setTimeout: () => 0, clearTimeout() {}};
  vm.createContext(context);
  vm.runInContext(
    `${script}
      const available =
        typeof clearAppliedDashboardQuery === 'function' &&
        typeof removeDashboardCategoryFilter === 'function' &&
        typeof removeDashboardPartnerFilter === 'function' &&
        typeof renderDashboard === 'function';
      let result = null;
      if (available) {
        applied = clone(initial);
        applied.partners = ['mol'];
        dashboardQueryApplied = true;
        renderDashboard();
        const activeMarkup = document.querySelector('[data-dashboard-query-chip-row]').innerHTML;
        const activeCount = document.querySelector('[data-dashboard-list-count]').textContent;
        removeDashboardPartnerFilter('mol');
        renderDashboard();
        const partnerRemovalMarkup = document.querySelector('[data-dashboard-query-chip-row]').innerHTML;
        removeDashboardCategoryFilter('food');
        renderDashboard();
        const categoryRemovalMarkup = document.querySelector('[data-dashboard-query-chip-row]').innerHTML;
        clearAppliedDashboardQuery();
        renderDashboard();
        result = {
          activeMarkup,
          activeCount,
          partnerRemovalMarkup,
          categoryRemovalMarkup,
          clearedMarkup: document.querySelector('[data-dashboard-query-chip-row]').innerHTML,
          clearedCount: document.querySelector('[data-dashboard-list-count]').textContent,
          dashboardQueryApplied,
          sameScopeAfterClear: querySignature(applied) === querySignature(draft),
        };
      }
      globalThis.__dashboardFacetProbe = {available, result};`,
    context,
  );
  return context.__dashboardFacetProbe;
}

const failures = [];
const probe = runProbe();
const savedProbe = runSavedFilterProbe();
const dashboardFacetProbe = runDashboardFacetProbe();

if (probe.narrowedCount !== 15) {
  failures.push(`Expected Étel > Tesco to yield 15, got ${probe.narrowedCount}.`);
}
if (probe.restoredCount !== 26 || probe.override !== undefined) {
  failures.push(
    `Expected deselecting the final child to restore Étel's 26 inherited transactions; got ${probe.restoredCount} with override ${JSON.stringify(probe.override)}.`,
  );
}

if (!html.includes('--fluvi-selection-start') || !html.includes('--fluvi-selection-end') || !html.includes('--fluvi-action-start') || !html.includes('--fluvi-action-end')) {
  failures.push('Expected one named selection accent and one separate primary-action accent token family.');
}
if (!html.includes('.vendor-chip.selected{border-color:rgba(98,91,220,.16);background:var(--surface-selected-soft)')) {
  failures.push('Expected selected partner chips to use the shared blue-to-violet selection family as a compact tinted state.');
}
if (!html.includes('.apply{background:linear-gradient(135deg,var(--action-start),var(--action-end))')) {
  failures.push('Expected the sticky result CTA alone to use the violet-to-pink primary-action accent.');
}
if ((html.match(/soft-fluvi-surface/g) ?? []).length < 4) {
  failures.push('Expected time detail, saved filters, and advanced filters to share the same soft-surface component.');
}
if (html.includes('data-result-count')) {
  failures.push('Expected result count to stay in the compact header and CTA, not beside Kinél?.');
}

const requiredDepthTokens = [
  '--bg-app',
  '--surface-main',
  '--surface-control',
  '--border-soft',
  '--shadow-surface',
  '--shadow-control',
  '--shadow-selection',
  '--shadow-action',
];
for (const token of requiredDepthTokens) {
  if (!html.includes(token)) {
    failures.push(`Expected the visual depth pass to define ${token}.`);
  }
}
if (!html.includes('--bg-app:#fff') || !html.includes('.query-sheet{background:var(--bg-app)')) {
  failures.push('Expected the query sheet to remain pure white while depth comes from inner surfaces.');
}
if (!html.includes('--surface-main:#fafbfe') || !html.includes('--surface-control:#f3f6fb')) {
  failures.push('Expected distinct section and inactive-control neutral luminance levels below the pure white sheet.');
}
if (!html.includes('.soft-fluvi-surface{border:1px solid var(--border-soft)!important')) {
  failures.push('Expected large section panels to be neutral white floating surfaces with one shared hairline.');
}
if (!html.includes('.time-chip,.vendor-chip{border:1px solid var(--border-soft)') || !html.includes('background:var(--surface-control)')) {
  failures.push('Expected inactive controls to use a crisp available-control surface and hairline.');
}
if (html.includes("choice.id!=='custom'?'<span class=\"tiny-tick\">✓</span>':''")) {
  failures.push('Expected selected fast time presets to rely on their blue-to-violet fill, not an extra checkmark.');
}
if (!html.includes('.horizontal-row,.year-row,.month-row{margin:-9px;padding:9px 9px 13px;overflow-x:auto;overflow-y:hidden;')) {
  failures.push('Expected every horizontal time/facet rail to reserve a shadow gutter inside its scroll viewport.');
}
if (!html.includes('.horizontal-row::-webkit-scrollbar,.year-row::-webkit-scrollbar,.month-row::-webkit-scrollbar{display:none}')) {
  failures.push('Expected every horizontal rail to remain scrollable without a visible browser scrollbar.');
}
if (!html.includes('.query-sheet,.query-sheet *{box-shadow:none!important}')) {
  failures.push('Expected the Query sheet to rely on clean neutral surfaces and borders, without component shadows.');
}
if (!html.includes('.sheet-footer{background:var(--bg-app);box-shadow:none}')) {
  failures.push('Expected the sticky footer to use the same pure-white surface as the sheet, without a separating shadow.');
}
if (!html.includes('.category-tile.selected .category-icon{border-color:transparent;background:linear-gradient(135deg,var(--category-start),var(--category-end))')) {
  failures.push('Expected a selected category orb to retain its category-specific visual token, not the generic selection gradient.');
}
if (!html.includes('.amount-card{background:var(--surface-inner)')) {
  failures.push('Expected the amount card to be a clean white child surface inside the neutral advanced-filter container.');
}
if (!html.includes('.category-tile .category-icon{border:1px solid var(--border-soft);background:var(--surface-control)')) {
  failures.push('Expected inactive category avatars to use the neutral control surface rather than white.');
}
if (html.includes('${entry.partner.name}<span class="tiny-tick">✓</span>')) {
  failures.push('Expected highlighted partner chips to communicate selection through their tint and category dot, not a checkmark.');
}
if (!html.includes('.category-tile.category-more .category-icon{border:1px solid var(--border-soft);background:var(--surface-inner);color:var(--selection-end)')) {
  failures.push('Expected the Kategória hozzáadása plus icon to use the same accent as Partner hozzáadása.');
}
if (!html.includes('--temporal-selection-start') || !html.includes('.time-chip.selected,.year-row button.selected,.month-row button.selected,.whole-year-button.selected{border-color:transparent;background:linear-gradient(135deg,var(--temporal-selection-start),var(--temporal-selection-end))')) {
  failures.push('Expected every selected time control to use one restrained blue-violet temporal gradient.');
}
if (html.includes("chosen.length===12?'Egész év ✓'")) {
  failures.push('Expected the selected Egész év control to rely on its temporal fill, not a checkmark.');
}
if (!html.includes('.whole-year-row{padding:5px 4px}') || !html.includes('.whole-year-button{padding:0 16px}') || !html.includes('.month-row{gap:9px}')) {
  failures.push('Expected the whole-year control and month rail to retain a small, deliberate control gap.');
}
if (!html.includes('.whole-year-button.partial{border-color:var(--border-soft);background:var(--surface-control);color:var(--text-secondary)')) {
  failures.push('Expected the partial Egész év label to remain neutral rather than turn blue.');
}
if (!html.includes('.search-pill:focus-within{background:var(--surface-control);box-shadow:none}')) {
  failures.push('Expected the search pill to preserve its visual surface on tap/focus.');
}

if (probe.categoryCatalogCount !== 10) {
  failures.push(`Expected the category picker to contain 10 categories, got ${probe.categoryCatalogCount}.`);
}
if (!probe.mainCategoryMarkup.includes('data-category="food"') || probe.mainCategoryMarkup.includes('data-picker-source="category-preview"') || !probe.mainCategoryMarkup.includes('Kategória hozzáadása')) {
  failures.push('Expected selected category preview tiles to toggle only themselves, with Kategória hozzáadása as the sole picker entry.');
}
if ((probe.mainCategoryMarkup.match(/data-open-category-picker/g) ?? []).length !== 1 || (probe.allExplicitPartnerMarkup.match(/data-open-partner-picker/g) ?? []).length !== 1) {
  failures.push('Expected only the two explicit add controls—not already selected horizontal chips—to open a full facet list.');
}
if (probe.mainCategoryMarkup.includes('Továbbiak') || probe.mainCategoryMarkup.includes('Összes') || probe.mainCategoryMarkup.includes('i-more')) {
  failures.push('Expected the category rail not to collapse explicit selections into a +N or ambiguous picker opener.');
}
if ((probe.pickerCategoryMarkup.match(/data-category=/g) ?? []).length !== 10) {
  failures.push('Expected the picker, not the main rail, to render all 10 time-valid categories.');
}
if (!['Étel', 'Közlekedés', 'Lakás'].every((name) => probe.allExplicitCategoryMarkup.includes(name)) || probe.allExplicitCategoryMarkup.includes('Továbbiak')) {
  failures.push('Expected every explicit category selection to stay in the horizontal main rail with no +N truncation.');
}

if (!html.includes('data-open-partner-picker') || !html.includes('data-partner-picker')) {
  failures.push('Expected the main partner row to morph into an in-sheet partner picker.');
}
if (!html.includes('renderPartnerPicker') || !html.includes('data-close-partner-picker')) {
  failures.push('Expected the partner picker to retain the Query draft and return to the main sheet state.');
}
if (probe.mainPartnerMarkup.includes('Tesco') || probe.mainPartnerMarkup.includes('Lidl')) {
  failures.push('Expected inherited category partners to stay out of the main partner summary row.');
}
if (!probe.mainPartnerMarkup.includes('Partner hozzáadása') || probe.mainPartnerMarkup.includes('Összes') || probe.mainPartnerMarkup.includes('i-more')) {
  failures.push('Expected the explicit-partner rail to use the clear Partner hozzáadása picker entry.');
}
if (!probe.pickerPartnerMarkup.includes('Tesco') || !probe.pickerPartnerMarkup.includes('Lidl')) {
  failures.push('Expected inherited category partners to remain available in the partner picker.');
}
if (!['Tesco', 'MOL', 'Shell'].every((name) => probe.allExplicitPartnerMarkup.includes(name)) || /\+\d+ partner/.test(probe.allExplicitPartnerMarkup)) {
  failures.push('Expected every explicit partner selection to stay in the horizontal main rail with no +N truncation.');
}

if (!html.includes('data-open-category-picker') || !html.includes('data-category-picker')) {
  failures.push('Expected the main category rail to morph into an in-sheet category picker.');
}
if (!html.includes('renderCategoryPicker') || !html.includes('data-close-category-picker')) {
  failures.push('Expected the category picker to retain the Query draft and return to the main sheet state.');
}
if ((html.match(/facet-picker-morph/g) ?? []).length < 2 || !html.includes('--picker-origin-x') || !html.includes('data-category-picker-count') || html.includes('<div class="picker-grabber"')) {
  failures.push('Expected category and partner lists to share one source-aware content-morph shell without a second drag handle.');
}
if (!probe.partnerPickerMorphAvailable) {
  failures.push('Expected the partner picker to use the same explicit open/close content-morph operations.');
} else {
  const partnerPicker = probe.partnerPickerMorphProbe;
  if (!partnerPicker.opened || !partnerPicker.closed || !partnerPicker.rowsStaySteadyAfterOpen || !partnerPicker.selectedPickerMarkup.includes('MOL') || !partnerPicker.selectedPickerMarkup.includes('picker-row selected') || !partnerPicker.returnedPreviewMarkup.includes('MOL')) {
    failures.push('Expected the partner picker to return through the established simple opacity transition.');
  }
}
if (!probe.categoryPickerMorphAvailable) {
  failures.push('Expected explicit category-picker open/close operations for the shared-query morph transition.');
} else {
  const categoryPicker = probe.categoryPickerMorphProbe;
  if (!categoryPicker.opened || !categoryPicker.closed || !categoryPicker.rowsStaySteadyAfterToggle || !categoryPicker.selectedPickerMarkup.includes('Közlekedés') || !categoryPicker.selectedPickerMarkup.includes('picker-row selected') || !categoryPicker.returnedPreviewMarkup.includes('Étel') || !categoryPicker.returnedPreviewMarkup.includes('Közlekedés')) {
    failures.push('Expected the category picker to return through the established simple opacity transition.');
  }
}
if (html.includes('class="category-picker facet-picker-morph"') || html.includes('class="partner-picker facet-picker-morph"') || html.includes('facetPickerClosing') || html.includes('setFacetPickerOrigin')) {
  failures.push('Expected the source-aware content-morph lifecycle to be removed in favour of the established opacity picker transition.');
}
if (!html.includes('.category-picker,.partner-picker{position:absolute;z-index:7;inset:0;background:#fff;transform:translateY(14px);opacity:0')) {
  failures.push('Expected the original shared category/partner opacity transition to remain the only picker transition.');
}

if (!probe.amountRangeAvailable) {
  failures.push('Expected one derived amount-domain owner for the two-thumb amount range.');
} else {
  const {beforeAmountDomain, boundedAmountDomain, unboundedCount, boundedCount} = probe.amountRangeProbe;
  if (beforeAmountDomain.minimum !== 0 || beforeAmountDomain.maximum <= 0) {
    failures.push(`Expected the initial amount domain to be 0 through a positive query maximum; got ${JSON.stringify(beforeAmountDomain)}.`);
  }
  if (boundedAmountDomain.maximum !== beforeAmountDomain.maximum) {
    failures.push('Expected the upper slider domain to ignore its own selected maximum and remain query-derived.');
  }
  if (boundedCount >= unboundedCount) {
    failures.push('Expected an inward two-thumb amount range to immediately reduce the live result count.');
  }
}
if (!html.includes('data-amount-min-range') || !html.includes('data-amount-max-range')) {
  failures.push('Expected two linked native range controls, one for each amount boundary.');
}

if (!probe.headerSummaryAvailable) {
  failures.push('Expected pure period/facet formatters and one derived header-summary renderer.');
} else {
  const summary = probe.headerSummaryProbe;
  const expected = {
    oneMonth: '2026 · Február',
    contiguous: '2026 · Jan–Nov',
    nonContiguousEleven: '2026 · 11 hónap',
    wholeYear: '2026 · Egész év',
    multipleYears: '2025–2026 · 14 hónap',
    category: 'Étel +2',
    partner: 'Tesco +2',
  };
  for (const [key, value] of Object.entries(expected)) {
    if (summary[key] !== value) {
      failures.push(`Expected compact ${key} summary ${JSON.stringify(value)}, got ${JSON.stringify(summary[key])}.`);
    }
  }
  if (!summary.headerMarkup.includes('summary-piece') || !summary.headerMarkup.includes('Étel +2') || !summary.headerMarkup.includes('Tesco +2')) {
    failures.push('Expected the live header renderer to use compact, individually ellipsizable summary pieces.');
  }
  if (!/tranzakció/.test(summary.headerCount)) {
    failures.push('Expected the secondary header count to be rendered from the active draft.');
  }
}
if (!html.includes('data-query-summary') || !html.includes('data-query-summary-count')) {
  failures.push('Expected a compact active-query summary area below the sheet title and above search.');
}

const sectionHeadingIcons = [
  ['time', 'i-calendar'],
  ['category', 'i-category'],
  ['partner', 'i-partners'],
];
for (const [section, icon] of sectionHeadingIcons) {
  if (!html.includes(`data-section-icon="${section}"`) || !html.includes(`href="#${icon}"`)) {
    failures.push(`Expected the ${section} section heading to have its own leading ${icon} icon.`);
  }
}
if (!html.includes('.section-title') || !html.includes('.section-icon')) {
  failures.push('Expected the shared section-title/icon styling to match the existing filter-heading hierarchy.');
}

if (!html.includes('data-saved-filters-panel') || !html.includes('data-toggle-saved-filters')) {
  failures.push('Expected bookmark-controlled Mentett szűrők panel markup, not the legacy snapshot tray.');
}
if (!html.includes('savedFiltersStorageKey') || !html.includes('localStorage')) {
  failures.push('Expected prototype-only localStorage persistence for named saved filters.');
}
if (savedProbe.persistedAfterSave[0].resultCount !== undefined || !savedProbe.persistedAfterSave[0].queryConfiguration) {
  failures.push('Expected saved filters to persist query configuration only, never a frozen result count.');
}
if (!savedProbe.dirtyBeforeUpdate || !savedProbe.updated || savedProbe.dirtyAfterUpdate) {
  failures.push('Expected a loaded saved filter to become dirty only after mutation and clean again after explicit update.');
}
if (savedProbe.renamed !== 'Havi nagybevásárlás' || savedProbe.savedBeforeReset !== savedProbe.savedAfterReset) {
  failures.push('Expected rename and current-query reset to preserve the saved-filter collection.');
}
if (!savedProbe.loaded || savedProbe.loadedMinimum !== '5000' || savedProbe.savedAfterDelete !== 1) {
  failures.push('Expected saved filter load to restore full configuration and delete to remove only the confirmed record.');
}

if (!html.includes('data-dashboard-list-count') || !html.includes('data-dashboard-query-facets') || !html.includes('data-clear-dashboard-query')) {
  failures.push('Expected applied category/partner facets and a query-close action directly above LogBoxes.');
}
if (!html.includes('data-remove-dashboard-category') || !html.includes('data-remove-dashboard-partner')) {
  failures.push('Expected every applied category and partner chip to have its own explicit remove action.');
}
const dashboardCountIndex = html.indexOf('data-dashboard-list-count');
const dashboardFacetIndex = html.indexOf('data-dashboard-query-facets');
const dashboardLogIndex = html.indexOf('data-dashboard-log');
if (!(dashboardCountIndex < dashboardFacetIndex && dashboardFacetIndex < dashboardLogIndex)) {
  failures.push('Expected the applied facet expansion to sit between the listed-transaction count and LogBoxes.');
}
if (html.includes('data-dashboard-amount-')) {
  failures.push('Expected no duplicate dashboard amount slider; the two-thumb range belongs only to Query Menu.');
}
if (!dashboardFacetProbe.available) {
  failures.push('Expected the dashboard facet expansion to use the explicit applied-query clear operation.');
} else {
  const result = dashboardFacetProbe.result;
  if (!result.activeMarkup.includes('Étel') || !result.activeMarkup.includes('MOL') || !result.activeMarkup.includes('data-remove-dashboard-category') || !result.activeMarkup.includes('data-remove-dashboard-partner') || !/tranzakció listázva/.test(result.activeCount)) {
    failures.push('Expected removable applied category/partner filter chips and the live result count above LogBoxes.');
  }
  if (result.partnerRemovalMarkup.includes('MOL') || !result.partnerRemovalMarkup.includes('Étel') || result.categoryRemovalMarkup) {
    failures.push('Expected a chip remove action to update only that applied facet while preserving the remaining horizontal rail state.');
  }
  if (result.clearedMarkup || result.dashboardQueryApplied || !result.sameScopeAfterClear || !/tranzakció listázva/.test(result.clearedCount)) {
    failures.push('Expected the dashboard close action to clear the applied query, sync the draft, and remove the facet expansion.');
  }
}

if (failures.length) {
  console.error(`FAIL query menu prototype (${failures.length})`);
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exit(1);
}

console.log('PASS query menu prototype');
