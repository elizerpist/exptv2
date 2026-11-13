# Repository setup checklist

| ID | Requirement | Acceptance condition | Status |
| --- | --- | --- | --- |
| R1 | Verify GitHub and git | Existing `gh` authentication and git configuration checked without installing tools | DONE |
| R2 | Create public repository | `elizerpist/mazeball` is public, described as requested, and uses `main` | DONE |
| R3 | Local checkout | Repository exists at `/data/data/com.termux/files/home/mazeball` | DONE |
| R4 | Global agent instructions | The first non-empty candidate, `.codex/AGENTS.md`, is copied unchanged as `AGENTS.md` | DONE |
| R5 | Discover global skill roots | Existing Codex, plugin, Claude, Factory, Gemini, Antigravity, backup, and agent skill roots inspected | DONE |
| R6 | Copy requested skills | Superpowers, `structuring-apps`, Dart, and Flutter skill directories copied in full | DONE |
| R7 | Validate copied skills | Each copied skill has one readable manifest and no symlink remains; support directories are preserved | DONE |
| R8 | Security scan | No credential material found; the personal path in `flutter-feature` is intentionally published unchanged under the explicit user override | DONE with explicit override |
| R9 | License review | Dart/Flutter BSD-3-Clause license is preserved; no restrictive license was found in the other selected skill directories | DONE |
| R10 | README | Requested short README is present | DONE |
| R11 | Git ignore rules | Flutter, Dart, Gradle, build, environment, and secret artifacts are ignored | DONE |
| R12 | No application scaffold | No `flutter create`, `lib/`, `android/`, `ios/`, or platform application code was added | DONE |
| R13 | Skills inventory | `.agents/SKILLS-INVENTORY.md` lists every copied skill and manifest status | DONE |
| R14 | Commit and push | Requested commit is on the remote `main` branch | DONE |
| R15 | Final report | URL, paths, counts, list, source AGENTS, SHA, push result, and security/license status reported | DONE |
