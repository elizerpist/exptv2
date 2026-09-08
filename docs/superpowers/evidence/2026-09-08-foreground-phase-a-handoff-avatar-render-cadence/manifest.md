# Frozen Drive evidence manifest

Frozen at: 2026-09-08T12:49:26Z
Repair branch: `fix/foreground-phase-a-handoff-avatar-render-cadence-codex-20260908`
Investigated application source: `fc35c1bbe280fdcecb262960eefd1e282595f7b6`

The `.docx.base64` files are the byte-faithful native Drive exports.  The
`.txt` files are their readable connector projections and may normalize line
endings; the `*-deduplicated-events.txt` files retain the first complete
event for each sequence number in source order.

## Avatar

- Title / ID: `Fluvi logs avatar fling` /
  `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`
- Drive modified timestamp: `2026-09-08T11:53:26.242Z`
- LIVE_TAIL headers:
  - `sessionId=fluvi-1788868338296445 sessionEventCount=3022 retainedCount=1000 firstRetainedSequence=2023 lastRetainedSequence=3022`
  - `sessionId=fluvi-1788868338296445 sessionEventCount=3023 retainedCount=1000 firstRetainedSequence=2024 lastRetainedSequence=3023`
- Build identity: `profile/fc35c1bbe280fdcecb262960eefd1e282595f7b6`,
  `HUMAN_DIAGNOSTIC`, readiness `ready`.
- Native export: `avatar-drive-export.docx.base64`; decoded bytes:
  `103939`; decoded SHA-256:
  `474276ed6c518ac28bfd1f77f2b159d6fb73721ee39dee01e9ba00fbd9bb12be`.
- Readable projection: `avatar-drive-export.txt`; bytes `703988`;
  SHA-256 `d0a7fa27acf8a8d8eafef021cb2bcb2ff4051c61556a98f478be62deba5e2f1c`.
- Deduplicated event stream: `avatar-deduplicated-events.txt`; bytes
  `352361`; SHA-256
  `3160dfdcfc3485ac5c959d6a734aac8c9d094cbb7dff98f11fe2421d237099c0`.
- Raw events `2000`; unique sequence numbers `1001`; duplicate events
  `999`; differing duplicate payloads `0`; deduplicated range
  `2023–3023`.
- Prompt-authoring frozen SHA-256: `11d2fad3778be8d7d09b9a07737c273796be1b07b00884623fbfec07e584734e`.
  It does not match either newly generated native-export bytes or the
  normalized text projection.  The Drive modified timestamp and all event
  identity/count checks match; no byte-level equivalence is inferred across
  export representations.

## Time

- Title / ID: `Fluvi logs time fling` /
  `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`
- Drive modified timestamp: `2026-09-08T11:55:24.677Z`
- LIVE_TAIL header:
  `sessionId=fluvi-1788868486605950 sessionEventCount=2449 retainedCount=1000 firstRetainedSequence=1450 lastRetainedSequence=2449`.
- Build identity: `profile/fc35c1bbe280fdcecb262960eefd1e282595f7b6`,
  `HUMAN_DIAGNOSTIC`, readiness `ready`.
- Native export: `time-drive-export.docx.base64`; decoded bytes:
  `50126`; decoded SHA-256:
  `d57858a03c8116526cca7120f40867335316d3adae1129be0a3bc2f8419e9aee`.
- Readable projection: `time-drive-export.txt`; bytes `341305`;
  SHA-256 `20a73576593b2230c8525c015b1cac497901623925172d0516fb4c640d2e27e8`.
- Deduplicated event stream: `time-deduplicated-events.txt`; bytes
  `341147`; SHA-256
  `eb4b4e41ac687b35080d7d985f874598457cdb076826e78e857f1dd5d8c270c3`.
- Raw events `1000`; unique sequence numbers `1000`; duplicate events
  `0`; differing duplicate payloads `0`; retained range `1450–2449`.
- Prompt-authoring frozen SHA-256: `43ed1ca04e1f4144907bc7b45a6c2c33e7b9ba37ab617b6b675966425846e18d`.
  It does not match either newly generated native-export bytes or the
  normalized text projection.  The Drive modified timestamp and all event
  identity/count checks match; no byte-level equivalence is inferred across
  export representations.

## Scope guard

These are two distinct sessions and must not be merged into one timeline.
Only these frozen copies are defect evidence for this repair cycle.
