# 339bfc3 day-rail scene coverage implementation plan

Approved design source: the user’s 339bfc3 post-settle temporal scene-window rebase specification. The work remains inline: lifecycle auditing, the focused tests and the coordinator edit share one controller-owned state machine.

1. Trace index installation, parent navigation, `settleRail`, temporal-anchor mutation, scene-window selection, preparation and activation. Capture the April gap with a focused failing test before changing runtime code.
2. Add the smallest immutable scene coverage identity plus controller-owned serialized desired/in-flight rebase state. Reuse the existing window selector, preparer and activator.
3. After successful settle, schedule a post-callback rebase only when the required year/month coverage changes. Keep old complete active coverage during preparation; activate only the latest complete matching window.
4. Add transition-only diagnostics and physical-report fields; do not alter the painter’s hard-miss behavior.
5. Prove July→April day scenes (empty and populated), distant/boundary anchors, rapid latest-wins settling and month-internal day no-op behavior. Re-run existing vertical and scale regressions.
6. Verify frozen paths, full non-golden suite and analysis; commit/push; monitor GitHub Actions; download only the normal-app HUMAN_DIAGNOSTIC artifact to `/storage/emulated/0/Download/fluvi` and verify its SHA-256 and ZIP integrity.
