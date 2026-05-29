# Header FastInfo and Category Picker Design

## Goal
Finish the next `exptv2` UI polish pass around the pulled transaction header, FastInfo layout, FAB long press behavior, category picking inside add/edit transaction sheets, category menu header placement, and swipe animation for the backheader category budget bar.

## Current Behavior
The FastInfo area and the header card are rendered as separate layers. At maximum pull distance the screenshot shows a visible break between the FastInfo background and the header card surface, so the two pieces do not read as one component.

The FastInfo content is anchored high inside the expanded panel. The FAB only handles a normal tap. Add/edit transaction category selection uses a dropdown-style field instead of the full category menu. The category menu header buttons are positioned near the edges in code, but their default button constraints still leave them visually too centered. The backheader category budget bar changes category after a swipe threshold, but it does not move sideways during the gesture.

## Design
Introduce a shared header pull surface that owns the visual background and shadow for the FastInfo section and the transaction header card. The header content can stay in its existing widget, but the visible surface should be drawn by one parent so the expanded header does not show a seam.

Move the FastInfo six visible elements lower by anchoring their layout closer to the bottom of the FastInfo section. This places them visually at the transition into the header card instead of near the top of the expanded area.

Add long press support to the shell FAB. Normal tap keeps opening the add transaction flow. Long press opens the new category editor flow from shell-level state so it remains available from every bottom nav tab.

Replace the add/edit transaction category dropdown interaction with a category-menu picker mode. Tapping the category field opens the existing category menu UI above the transaction sheet; selecting a category updates the form and returns to the sheet without changing the home category filter. Add, edit, and delete actions inside that picker should continue using the same category data and refresh the displayed selection immediately.

Tighten the category menu header layout so the back button is visually aligned to the modal header's left edge and the plus button to the right edge. This should be done with explicit button sizing and padding rather than relying on default `IconButton` constraints.

Update the backheader category budget stage so horizontal drag offset is visible during the gesture. On release it should animate to the next or previous category when the threshold is passed, and otherwise slide back to the current category.

## Verification
Local Flutter still cannot run in this Termux environment because the bundled Dart executable aborts with a Bionic TLS alignment error. Local verification should use file review plus lightweight checks such as `git diff --check`. The authoritative verification remains GitHub Actions, which runs `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
