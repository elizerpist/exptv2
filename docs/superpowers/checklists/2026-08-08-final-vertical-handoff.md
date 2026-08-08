# Final vertical handoff + 2025 high-density seed — acceptance checklist

| ID | Requirement source | Owner / code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| VH01 | User §§0–4 | `DashboardLogBoxViewport` notification lifecycle | Source audit proves why an old update can request page 1 with `demandEpoch=0` while the cache remains `railPreview`. | DONE |
| VH02 | User §§5–12 | Stable viewport interaction session | Visible-scope change invalidates/cancels old session; an old activity cannot update cache, demand, or pixels for the new scope. | DONE |
| VH03 | User §§7–10 | Stable viewport + render binding | First genuine new-scope gesture starts one new session, starts a demand epoch, and promotes to `committedVertical` before the 24-row preview boundary. | DONE |
| VH04 | User §§13–21 | Widget regression | Deep A → sibling C → immediate first fling crosses page 0–4 without a stale update, late promotion, blank, or 24-row stop. | DONE |
| VH05 | User §§15–18 | Existing cache/render binding | New-scope ballistic continues as 24→48→… content dimensions grow; lazy/bounded paging and all rail hot paths remain unchanged. | DONE |
| VH06 | User §19–21 | Profile diagnostics | Session start/invalidation/rejection/promotion diagnostics exist; `VERTICAL_DOMAIN_PROMOTION_LATE=0` in regression flow. | DONE |
| SD01 | User §§22–31 | Native `DemoDatasetGenerator` | Deterministic 2025 data adds 12 months × 280–320 entries, each with 600–700k Ft income/expense and abs(net) ≤50k Ft, while preserving 2026 scenarios. | PARTIAL — implementation and assertions are complete; local Android unit execution is blocked by the Termux/proot AAPT2 daemon and awaits CI. |
| SD02 | User §§27–33 | Native generator/use-case tests | Categories/partners are reused, days have varied density, seed version is bumped, and Room idempotency / deterministic reports prove exact data. | PARTIAL — source tests are present; CI must execute them because local AAPT2 resource linking fails before tests run. |
| VR01 | User §§34–37 | Non-golden regression suite | 2025 year/month + month/day high density and rapid sequence prove no stale session, blank row, cache miss, controller recreation, or preview-boundary stop. | PARTIAL — 300-row stable-viewport first-gesture coverage and the existing 1k/100k bounded gates pass locally; physical 2025 validation remains pending the human APK. |
| FR01 | User §§1,18,38–40 | Frozen code audit | No diff to rail/physics, demand planner, paging request/cursor, scene-window coverage, or Summary formatter; human build retains `lib/main.dart`. | DONE |
| DL01 | User §§38–39 | GitHub Actions / artifact delivery | HUMAN_DIAGNOSTIC profile APK is built on GitHub, downloaded to `/storage/emulated/0/Download/fluvi`, SHA-256 and ZIP integrity recorded. | NOT DONE |
