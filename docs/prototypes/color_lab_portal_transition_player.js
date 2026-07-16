(function attachPortalTransitionPlayer(root, factory) {
  const api = factory(root);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.PortalTransitionPlayer = api;
})(
  typeof globalThis === 'undefined' ? this : globalThis,
  function buildPortalTransitionPlayer(root) {
    'use strict';

    const clamp01 = (value) => Math.max(0, Math.min(1, Number.isFinite(value) ? value : 0));
    const fallbackNow = () => root?.performance?.now?.() ?? Date.now();
    const fallbackRequestFrame = (callback) => {
      if (typeof root?.requestAnimationFrame === 'function') {
        return root.requestAnimationFrame(callback);
      }
      return root.setTimeout(() => callback(fallbackNow()), 16);
    };
    const fallbackCancelFrame = (id) => {
      if (typeof root?.cancelAnimationFrame === 'function') root.cancelAnimationFrame(id);
      else root?.clearTimeout?.(id);
    };
    const abortError = () => {
      const error = new Error('Portal transition playback cancelled');
      error.name = 'AbortError';
      return error;
    };

    function createPlayback(options = {}) {
      const durationValue = Number(options.duration);
      const duration = Math.max(0, Number.isFinite(durationValue) ? durationValue : 0);
      const now = typeof options.now === 'function' ? options.now : fallbackNow;
      const requestFrame = typeof options.requestFrame === 'function'
        ? options.requestFrame
        : fallbackRequestFrame;
      const cancelFrame = typeof options.cancelFrame === 'function'
        ? options.cancelFrame
        : fallbackCancelFrame;
      const onFrame = typeof options.onFrame === 'function' ? options.onFrame : () => {};

      let progress = clamp01(Number(options.startProgress));
      let direction = Number(options.direction) < 0 ? -1 : 1;
      let state = 'running';
      let lastTimestamp = Number(now()) || 0;
      let frameId = null;
      let settled = false;
      let resolveFinished;
      let rejectFinished;
      const finished = new Promise((resolve, reject) => {
        resolveFinished = resolve;
        rejectFinished = reject;
      });

      const finish = () => {
        if (settled) return;
        settled = true;
        frameId = null;
        state = 'finished';
        resolveFinished(api);
      };
      const schedule = () => {
        if (state !== 'running' || frameId !== null) return;
        frameId = requestFrame(tick);
      };
      function tick(timestamp) {
        if (state !== 'running') return;
        frameId = null;
        const safeTimestamp = Number.isFinite(Number(timestamp)) ? Number(timestamp) : Number(now());
        const delta = Math.max(0, safeTimestamp - lastTimestamp) / duration;
        lastTimestamp = safeTimestamp;
        progress = clamp01(progress + (delta * direction));
        onFrame(progress);
        if ((direction > 0 && progress >= 1) || (direction < 0 && progress <= 0)) finish();
        else schedule();
      }

      const api = Object.freeze({
        reverse() {
          if (state !== 'running') return;
          direction *= -1;
          lastTimestamp = Number(now()) || 0;
          schedule();
        },
        cancel() {
          if (settled || state === 'idle') return;
          if (frameId !== null) cancelFrame(frameId);
          frameId = null;
          state = 'idle';
          settled = true;
          rejectFinished(abortError());
        },
        get finished() {
          return finished;
        },
        get playState() {
          return state;
        },
        get currentProgress() {
          return progress;
        },
        get currentTime() {
          return progress * duration;
        },
      });

      if (duration === 0) {
        progress = direction > 0 ? 1 : 0;
        onFrame(progress);
        finish();
      } else {
        onFrame(progress);
        schedule();
      }

      return api;
    }

    return Object.freeze({ createPlayback });
  },
);
