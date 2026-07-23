# Avatar border toggle checklist

Reference screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260720-203823.png`

Screenshot observation: the selected center avatar in the budget carousel does not visually match the neighboring avatars. The side avatars have a thin white border/stroke around the colored circular body, while the selected center avatar lacks that same border.

| ID | Source instruction or reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| AVB-001 | User instruction: "a középső stílusa nem egyezik a mellette lévővel" and latest screenshot | Budget carousel avatar rendering, selected and side avatar body/border styling | The selected center avatar and neighboring avatars use the same border policy, so the center no longer looks like a different style when borders are enabled. | `flutter test test/spendeetest/spendee_dashboard_interaction_test.dart`; updated C2/C3 goldens. | DONE |
| AVB-002 | User instruction: "rakd bele az avatarbeállításokba, user választ, vagy mindnek, vagy egynek sem" | Avatar customization menu opened from the header/background/avatar settings | Add one user-facing avatar setting that controls the thin white border globally: either every avatar has it, or no avatar has it. No per-avatar mixed state. | `avatar layout menu toggles the shared white avatar border` widget test. | DONE |
| AVB-003 | User instruction: "még ne kódolj... ha mondom hogy kódolj, csak akkor kódolj" | Workflow guard | Do not modify implementation code until the user explicitly says to code. Keep this as a recorded pending requirement while more changes are added. | Git diff review confirms only checklist/spec documentation changed before approval. | DONE |
