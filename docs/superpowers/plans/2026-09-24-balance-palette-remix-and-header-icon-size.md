# Balance palette remix and Header mode-icon size plan

1. Audit current Header visual ownership, palette catalog, tuner and the Header tap-wave gesture boundary. Record the four-family baseline and use the existing `DashboardHeaderVisualTuning` as the only extension seam.
2. Add failing catalog/tuner/engine tests for eight families, the twelve exact new scales and all semantic ordering/exclusion requirements.
3. Add the new immutable catalog data and labels only; retain the current sampler and frame transport.
4. Add failing Header visual state/tuner/host tests for the icon-size slider and icon hit region tap-wave exclusion.
5. Extend the existing visual-tuning/frame path, calculate the scale from the existing base glyph size, and suppress the parent tap-wave only for the icon hit region.
6. Run focused and protected regressions, inspect the final source and checklist, then commit and push one application change.
7. Obtain the exact-source GitHub human APK, verify its integrity/signature/embedded source identity, regenerate SCIP in the separate tooling worktree, and only then complete delivery evidence. Physical acceptance remains user-only.
