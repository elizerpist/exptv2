const assert = require('assert');
const player = require('./color_lab_portal_transition_player.js');

function createScheduler() {
  let timestamp = 0;
  let nextId = 1;
  const queue = new Map();
  return {
    now: () => timestamp,
    requestFrame(callback) {
      const id = nextId;
      nextId += 1;
      queue.set(id, callback);
      return id;
    },
    cancelFrame(id) {
      queue.delete(id);
    },
    step(milliseconds) {
      timestamp += milliseconds;
      const callbacks = [...queue.values()];
      queue.clear();
      callbacks.forEach((callback) => callback(timestamp));
    },
    get pending() {
      return queue.size;
    },
  };
}

const makePlayback = (scheduler, overrides = {}) => {
  const frames = [];
  const playback = player.createPlayback({
    duration: 1000,
    startProgress: 0,
    direction: 1,
    now: scheduler.now,
    requestFrame: scheduler.requestFrame,
    cancelFrame: scheduler.cancelFrame,
    onFrame: (progress) => frames.push(Number(progress.toFixed(6))),
    ...overrides,
  });
  return { playback, frames };
};

(async () => {
  {
    const scheduler = createScheduler();
    const { playback, frames } = makePlayback(scheduler);
    assert.deepStrictEqual(frames, [0]);
    assert.strictEqual(playback.playState, 'running');
    scheduler.step(500);
    assert.strictEqual(playback.currentProgress, 0.5);
    assert.strictEqual(playback.currentTime, 500);
    scheduler.step(500);
    await playback.finished;
    assert.deepStrictEqual(frames, [0, 0.5, 1]);
    assert.strictEqual(playback.playState, 'finished');
  }

  {
    const scheduler = createScheduler();
    const { playback, frames } = makePlayback(scheduler);
    scheduler.step(600);
    assert.strictEqual(playback.currentProgress, 0.6);
    playback.reverse();
    assert.strictEqual(scheduler.pending, 1, 'Reverse must not queue a duplicate frame');
    scheduler.step(300);
    assert.strictEqual(playback.currentProgress, 0.3);
    scheduler.step(300);
    await playback.finished;
    assert.deepStrictEqual(frames, [0, 0.6, 0.3, 0]);
  }

  {
    const scheduler = createScheduler();
    const { playback, frames } = makePlayback(scheduler, {
      startProgress: 1,
      direction: -1,
    });
    assert.deepStrictEqual(frames, [1]);
    scheduler.step(1000);
    await playback.finished;
    assert.strictEqual(playback.currentProgress, 0);
    assert.deepStrictEqual(frames, [1, 0]);
  }

  {
    const scheduler = createScheduler();
    const { playback } = makePlayback(scheduler);
    const rejection = playback.finished.catch((error) => error);
    playback.cancel();
    const error = await rejection;
    assert.strictEqual(error.name, 'AbortError');
    assert.strictEqual(playback.playState, 'idle');
    assert.strictEqual(scheduler.pending, 0);
    scheduler.step(500);
    assert.strictEqual(playback.currentProgress, 0);
  }

  {
    const scheduler = createScheduler();
    const { playback, frames } = makePlayback(scheduler, {
      duration: 0,
      startProgress: 0.4,
      direction: 1,
    });
    await playback.finished;
    assert.deepStrictEqual(frames, [1]);
    assert.strictEqual(playback.currentProgress, 1);
    assert.strictEqual(playback.playState, 'finished');
    assert.strictEqual(scheduler.pending, 0);
  }

  {
    const scheduler = createScheduler();
    const { playback, frames } = makePlayback(scheduler, {
      duration: 0,
      startProgress: 0.6,
      direction: -1,
    });
    await playback.finished;
    assert.deepStrictEqual(frames, [0]);
    assert.strictEqual(playback.currentProgress, 0);
  }

  console.log('Portal transition player checks passed');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
