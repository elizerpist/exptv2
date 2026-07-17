const assert = require('assert');
const morph = require('./color_lab_portal_message.js');

assert.deepStrictEqual(morph.modeOrder, [
  'diffuse-focus',
  'portal-aperture',
  'energy-sweep',
  'spectral-echo',
]);
assert.deepStrictEqual(morph.modeOrder.map((mode) => morph.modeLabels[mode]), [
  'Diffúz fókusz',
  'Portal rekesz',
  'Energia-söprés',
  'Spektrális visszhang',
]);

for (const mode of morph.modeOrder) {
  const controls = morph.controlsForMode(mode);
  const settings = morph.createModeSettings(mode);
  assert(controls.length >= 7);
  assert.strictEqual(new Set(controls.map(({ key }) => key)).size, controls.length);
  controls.forEach((meta) => {
    assert.strictEqual(settings[meta.key], meta.default);
    assert.strictEqual(morph.normalizeValue(meta, meta.min - 1000), meta.min);
    assert.strictEqual(morph.normalizeValue(meta, meta.max + 1000), meta.max);
  });
}

assert.deepStrictEqual(morph.transitionOffsets(0), { outgoingEnd: 0.5, incomingStart: 0.5 });
assert.deepStrictEqual(morph.transitionOffsets(100), { outgoingEnd: 1, incomingStart: 0 });
const halfOverlap = morph.transitionOffsets(50);
assert(halfOverlap.outgoingEnd > 0.5 && halfOverlap.outgoingEnd < 1);
assert.strictEqual(
  Math.round((halfOverlap.outgoingEnd + halfOverlap.incomingStart) * 1e9) / 1e9,
  1,
);

let state = 'balance';
for (let index = 0; index < 8; index += 1) state = morph.oppositeState(state);
assert.strictEqual(state, 'balance');
assert.strictEqual(morph.oppositeState('balance'), 'message');
assert.strictEqual(morph.oppositeState('message'), 'balance');

const signatures = new Set();
for (const mode of morph.modeOrder) {
  const settings = morph.createModeSettings(mode);
  const forward = morph.buildTransition(mode, settings, 'message', false);
  const backward = morph.buildTransition(mode, settings, 'balance', false);
  assert(forward.duration >= 300 && forward.duration <= 2400);
  assert.strictEqual(forward.outgoing[0].opacity, 1);
  assert.strictEqual(forward.incoming.at(-1).opacity, 1);
  assert.strictEqual(forward.direction, 1);
  assert.strictEqual(backward.direction, -1);
  assert.strictEqual(forward.outgoing[0].offset, 0);
  assert.strictEqual(forward.outgoing.at(-1).offset, 1);
  assert.strictEqual(forward.incoming[0].offset, 0);
  assert.strictEqual(forward.incoming.at(-1).offset, 1);
  const serialized = JSON.stringify(forward);
  assert(!Object.hasOwn(forward, 'accent'), `${mode} must not own a color accent`);
  assert(!Object.hasOwn(forward, 'accentOrigin'), `${mode} must not own an accent origin`);
  assert(!/rgba\(|#[0-9a-f]{3,8}/i.test(serialized), `${mode} must not encode a color layer`);
  assert(!/background|canvas|touch|trail/i.test(serialized));
  signatures.add(JSON.stringify(forward.outgoing));
}
assert.strictEqual(signatures.size, 4);

for (const mode of morph.modeOrder) {
  const base = morph.createModeSettings(mode);
  const baseline = JSON.stringify(morph.buildTransition(mode, base, 'message', false));
  for (const meta of morph.controlsForMode(mode)) {
    const changed = {
      ...base,
      [meta.key]: base[meta.key] === meta.max ? meta.min : meta.max,
    };
    assert.notStrictEqual(
      JSON.stringify(morph.buildTransition(mode, changed, 'message', false)),
      baseline,
      `${mode}.${meta.key} must measurably affect its morph descriptor`,
    );
  }
}

const forwardDiffuse = morph.buildTransition(
  'diffuse-focus',
  morph.createModeSettings('diffuse-focus'),
  'message',
  false,
);
const backwardDiffuse = morph.buildTransition(
  'diffuse-focus',
  morph.createModeSettings('diffuse-focus'),
  'balance',
  false,
);
assert.notStrictEqual(
  forwardDiffuse.outgoing[1].transform,
  backwardDiffuse.outgoing[1].transform,
  'Directional morphs must mirror their travel when Balance returns',
);

const reduced = morph.buildTransition(
  'spectral-echo',
  morph.createModeSettings('spectral-echo'),
  'message',
  true,
);
assert.strictEqual(reduced.duration, 160);
assert.deepStrictEqual(Object.keys(reduced.outgoing[1]).sort(), ['offset', 'opacity']);
assert.deepStrictEqual(Object.keys(reduced.incoming[1]).sort(), ['offset', 'opacity']);

console.log('Portal message morph checks passed');
