# B3M Time-Rail Collapse Handle Implementation Plan

**Goal:** Make the year-refinement handle the sole collapse/expand gesture owner without changing any screen geometry.

**Architecture:** Disable native vertical scrolling only on current exit-mode screen viewports, place a zero-flow handle inside the shared 21 px time-scope control row, and drive the existing `scrollTop`-based animation from pointer events bound only to that handle.

**Tech Stack:** Standalone HTML/CSS/JavaScript and Node.js static source-contract tests.

## Constraints

- Preserve every current screen, rail, card and bottom-navigation dimension.
- Preserve horizontal year selection and horizontally swipeable card panels.
- Preserve programmatic compact-pill expansion.
- Do not bind vertical collapse gestures to the year pills or the rest of the screen.
- Reuse the shared factory/controller so every clone owns independent local bindings.

### Task 1: Capture the interaction contract

- [x] Add a focused failing static test for the inline handle structure, fixed geometry, exit-mode native-scroll lock and handle-only pointer listeners.
- [x] Confirm RED against the current implementation.

### Task 2: Install the shared handle

- [x] Add the bar, short label and accessibility attributes inside the existing time-scope control row.
- [x] Add strongly scoped, zero-flow visual styles without changing the row height.

### Task 3: Transfer gesture ownership

- [x] Disable native vertical viewport scrolling only for exit-mode screens.
- [x] Bind pointer capture, drag progress, endpoint settling and click/keyboard toggle to the handle.
- [x] Preserve compact-pill expansion and the existing shared state updater.

### Task 4: Verify and publish

- [x] Run the focused contract, permanent-rail, geometry, Balance, Budget, Budget 3D, Mind, annual Mind and inline-script syntax regressions.
- [x] Run `git diff --check`, audit checklist status and staged scope.
- [ ] Commit the in-scope files and push branch `spendeetest`.
