# Pulse Plain-Language PNG Flowchart Design

**Working artifact:** `docs/prototypes/pulse_engine_panel_mockup.html`
**Asset:** `docs/prototypes/assets/pulse-egyszeru-mukodes.png`
**Source instruction:** User, 2026-07-23 — the current flowchart is too full
of foreign/technical terms; create one clear Hungarian PNG flowchart and put it
at the bottom of the HTML.

## Purpose

The existing HTML trace is a technical inspection tool. The new PNG is a
plain-language explanation for a person who wants to understand only this:

```text
Mikor lesz egy adatváltozásból üzenet, mikor vár, és mikor nem jelenik meg semmi?
```

It does not replace the existing panel or change the engine's rules. It
translates those rules into ordinary Hungarian.

## Visual direction

Create one wide, clean, high-resolution flat infographic in Hungarian. Use a
light background, dark readable text, rounded boxes, clear arrows, and a
limited teal/amber/red/green palette. It must look like a product explainer,
not a developer diagram or a dashboard screenshot.

The image shows this single readable path, with visible side exits:

1. `Megnézed a pontszámot` → `csak információ, nem üzenet`.
2. `Az adatok változnak` → `a rendszer ellenőriz`.
3. `Elég új és elég fontos?` → ha nem: `vár vagy nem jelenik meg`.
4. `Van elég ok ugyanahhoz a helyzethez?` → ha nem: `még vár`.
5. `Több üzenet közül melyik a fontosabb?` → `egy marad`.
6. `Az app nyitva van?` → ha igen: `megjelenik felül`; ha nem: `eltárolja, és appnyitáskor megmutatja`.
7. `Ugyanaz az üzenet volt már?` → `nem ismétli feleslegesen`.
8. `Ha a helyzet tényleg változik` → vissza az ellenőrzéshez.

The central, largest rule is exactly:

```text
A pontszám önmagában nem elég.
```

The image must not contain these technical terms: `domain`, `target`,
`fingerprint`, `eligibility`, `priority`, `trigger`, `source`, `selected`,
`suppressed`, `background`, `foreground`, or `header`.

## HTML placement and accessibility

Append one full-width `figure` immediately before the existing footer note.
It has `data-plain-language-flowchart`, a Hungarian `figcaption`, and an `img`
whose detailed Hungarian `alt` explains the visual's purpose. The image must
be responsive, never crop horizontally, and retain a readable white card
background.

The image is a project asset, not a remote URL or a base64 blob. No existing
group rail, Decision Trace behavior, or `balance_latest_layout.html` changes.

## Acceptance checklist

The static contract will check that the PNG exists, has a valid PNG signature,
is referenced from the bottom figure, and appears before the footer. Direct
image inspection will check that the actual generated diagram is readable,
Hungarian, and free of the prohibited jargon. Existing Pulse contracts remain
green. The user did not request screenshots; image-asset inspection is still
required because the requested deliverable is itself an image.
