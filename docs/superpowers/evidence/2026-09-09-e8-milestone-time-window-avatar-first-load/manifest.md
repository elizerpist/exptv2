# Frozen e8 direct-manipulation evidence manifest

Export timestamp: 2026-09-09 (local repair cycle). The `.base64` files are the
byte-faithful `text/plain` Google Docs exports. The adjacent `.txt` files are
readable CRLF-normalized projections used only for source/event inspection;
their bytes and hashes intentionally differ from the export.

## Avatar

- Title: `Fluvi logs avatar fling`
- Drive ID: `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`
- Drive modified timestamp at freeze: `2026-09-08T22:25:31.546Z`
- Export: `fluvi-logs-avatar-fling.text-plain.base64`
- Exact export byte count: `879465`
- Exact export SHA-256: `84061dead63d3c0395525e771dd6eb76119353695238c656ade7f21c01c4f683`
- Session/build: `fluvi-1788906284239925` / `profile/e8b73e3e9391`
- LIVE_TAIL ranges: `6205–7204`, `6206–7205`; deduplicated range `6205–7205`
- Raw copies / unique / exact duplicates / differing duplicates:
  `2000 / 1001 / 999 / 0`
- USER_MARK: `7204 avatar_fling`; `7205 avatar_filter_stuck`
- Readable normalized projection: `877463` bytes,
  `62cf0249e4e2a68f1f4b23532be39713f5f330149ff7f6edd3ab322afec9e7f9`
- Limitation: no retained `AV|FLING_STARTED`, `AV|PREVIEW_REQUESTED`,
  `BUDGET_AVATAR_MOTION_SUMMARY` or
  `AVATAR_FIRST_TARGET_PIPELINE_SUMMARY` for the marked healthy primary
  flight. Do not reconstruct its timing from later events.
- Flood audit: `COLLAPSE|LAYER=364`, `HOME|LAYER_STACK=53`,
  `COLLAPSE|GEOMETRY=53`; 470 of 1001 unique events.

## Time

- Title: `Fluvi logs time fling`
- Drive ID: `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`
- Drive modified timestamp at freeze: `2026-09-08T22:35:04.305Z`
- Export: `fluvi-logs-time-fling.text-plain.base64`
- Exact export byte count: `755535`
- Exact export SHA-256: `63ab463909c311f63d24cacb2fcf0bd1fecb08d417dfb816949d3ccdd563eb59`
- Session/build: `fluvi-1788906284239925` / `profile/e8b73e3e9391`
- LIVE_TAIL ranges: `17335–18334`, `17336–18335`; deduplicated range
  `17335–18335`
- Raw copies / unique / exact duplicates / differing duplicates:
  `2000 / 1001 / 999 / 0`
- USER_MARK: `18334 time_fling`; `18335 time_target_jump`
- Readable normalized projection: `753533` bytes,
  `118e15f4a54f05e555c90e27d58d58b57b6581b64365ae7c86256b3a0e1f759f`
- The trace contains normal exact Time Phase-A binds and no retained non-empty
  unreadable-paint event, but also 15 `preparedFrameUnavailable` rejections
  followed by canonical fallback and later post-Time Avatar exceptions.

## Relationship and retention limit

Both exports identify the same exact e8 session/build. Their retained sequence
intervals have an unobserved gap `7206–17334`; ordering across the documents
is attributable but no intervening mechanism is inferred. USER_MARK labels a
physical observation and is not root-cause proof.
