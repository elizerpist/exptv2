const assert = require('assert');
const field = require('./color_lab_portal_message_field.js');

const expectedSchemas = {
  'solid-a': [],
  'static-matter': [
    ['coverage', 'B-fedettség', 0, 80, 1, 34, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 72, '%'],
    ['scale', 'Anyagskála', 20, 180, 1, 100, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 76, '%'],
    ['detail', 'Részletesség', 0, 100, 1, 28, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 137, ''],
  ],
  'wandering-mist': [
    ['coverage', 'B-fedettség', 0, 80, 1, 36, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 74, '%'],
    ['scale', 'Ködskála', 20, 200, 1, 118, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 82, '%'],
    ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 22, '%'],
    ['curl', 'Curl erősség', 0, 100, 1, 44, '%'],
    ['morphRate', 'Alakváltozás', 0, 100, 1, 28, '%'],
    ['detail', 'Részletesség', 0, 100, 1, 24, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 311, ''],
  ],
  'living-archipelago': [
    ['islandCount', 'Szigetszám', 2, 12, 1, 6, ''],
    ['size', 'Átlagos méret', 8, 80, 1, 34, '%'],
    ['sizeVariance', 'Méreteltérés', 0, 100, 1, 42, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 78, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 66, '%'],
    ['wanderSpeed', 'Vándorlási sebesség', 0, 100, 1, 30, '%'],
    ['mergeAttraction', 'Összeolvadási vonzás', 0, 100, 1, 55, '%'],
    ['morphRate', 'Alakváltozás', 0, 100, 1, 36, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 521, ''],
  ],
  'forming-clouds': [
    ['density', 'Aktív felhősűrűség', 1, 10, 1, 4, ''],
    ['lifetime', 'Élettartam', 2, 30, 1, 14, 's'],
    ['birthOverlap', 'Születési átfedés', 0, 100, 1, 58, '%'],
    ['growth', 'Növekedés', 0, 100, 1, 46, '%'],
    ['strength', 'B-erősség', 0, 100, 1, 76, '%'],
    ['scale', 'Felhőskála', 10, 120, 1, 46, '%'],
    ['softness', 'Peremlágyság', 0, 100, 1, 78, '%'],
    ['driftSpeed', 'Sodródási sebesség', 0, 100, 1, 24, '%'],
    ['pathIrregularity', 'Útvonal-szabálytalanság', 0, 100, 1, 52, '%'],
    ['seed', 'Véletlenmag', 0, 9999, 1, 887, ''],
  ],
};

const schemaTuple = (meta) => [
  meta.key,
  meta.label,
  meta.min,
  meta.max,
  meta.step,
  meta.default,
  meta.unit,
];

const signature = (mode, settings, phase = 1.7) => (
  [0, 0.2, 0.4, 0.6, 0.8, 1].flatMap((x) =>
    [0, 0.33, 0.66, 1].map((y) => field.sampleMatter(mode, x, y, phase, settings)))
);

assert.deepStrictEqual(field.modeOrder, [
  'solid-a',
  'static-matter',
  'wandering-mist',
  'living-archipelago',
  'forming-clouds',
]);
assert.deepStrictEqual(field.modeOrder.map((id) => field.modeLabels[id]), [
  'Nincs dinamikus effekt',
  'Statikus köd/szigetek',
  'Vándorló köd',
  'Élő szigetvilág',
  'Keletkező energiafelhők',
]);
assert.deepStrictEqual(field.animatedModes, [
  'wandering-mist',
  'living-archipelago',
  'forming-clouds',
]);
assert.strictEqual(field.defaults.mode, 'wandering-mist');
assert.deepStrictEqual(field.paletteStops, [
  { position: 0, color: '#fffdfd' },
  { position: 50, color: '#ffc4e4' },
  { position: 100, color: '#8b5cf6' },
]);
assert.deepStrictEqual(field.sampleWindow(50, 68), {
  center: 50,
  windowSize: 68,
  lower: 16,
  upper: 84,
  a: '#ffebf5',
  b: '#b07df0',
});
assert.strictEqual(field.normalizeMode('invalid'), 'solid-a');
assert.strictEqual(field.sampleMatter('solid-a', 0.2, 0.8, 12, {}), 0);
assert.deepStrictEqual(field.controlsForMode('solid-a'), []);
assert.deepStrictEqual(field.createModeSettings('solid-a'), {});

for (const mode of field.modeOrder) {
  assert.deepStrictEqual(
    field.controlsForMode(mode).map(schemaTuple),
    expectedSchemas[mode],
    `${mode} schema`,
  );
}

const staticSettings = field.createModeSettings('static-matter');
assert.deepStrictEqual(
  signature('static-matter', staticSettings, 0),
  signature('static-matter', staticSettings, 900),
  'Static matter must be phase invariant',
);

for (const mode of field.modeOrder.slice(1)) {
  const controls = field.controlsForMode(mode);
  const settings = field.createModeSettings(mode);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(field.normalizeValue(meta, meta.min - 9999), meta.min);
    assert.strictEqual(field.normalizeValue(meta, meta.max + 9999), meta.max);
    assert.strictEqual(field.normalizeValue(meta, ''), meta.default);
  });
  for (const phase of [0, 0.75, 2.25]) {
    for (const [x, y] of [[0, 0], [0.13, 0.81], [0.5, 0.5], [0.92, 0.17], [1, 1]]) {
      const value = field.sampleMatter(mode, x, y, phase, settings);
      assert(Number.isFinite(value), `${mode} must return a finite mask`);
      assert(value >= 0 && value <= 1, `${mode} mask must be bounded`);
    }
  }
  for (const meta of controls) {
    const changed = {
      ...settings,
      [meta.key]: settings[meta.key] === meta.max ? meta.min : meta.max,
    };
    assert.notDeepStrictEqual(
      signature(mode, changed),
      signature(mode, settings),
      `${mode}.${meta.key} must affect the matter field`,
    );
  }
}

for (const mode of field.animatedModes) {
  const settings = field.createModeSettings(mode);
  assert.notDeepStrictEqual(
    signature(mode, settings, 0),
    signature(mode, settings, 3),
    `${mode} must move at default settings`,
  );
  assert(
    field.advancePhase(mode, 2, 1, settings) > 2,
    `${mode} phase must advance`,
  );
}
assert.strictEqual(
  field.advancePhase('static-matter', 2, 1, staticSettings),
  2,
);

for (const mode of field.modeOrder) {
  const profile = field.renderProfile(mode);
  assert(profile.renderScale > 0 && profile.renderScale <= 1);
  assert(profile.frameMs >= 16 && profile.frameMs <= 100);
}

console.log('Portal message field checks passed');
