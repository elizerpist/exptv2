# FastInfo Layout and Card Help Design

## Status and Goal

Approved in the June 4, 2026 FastInfo settings review.

Extend the FastInfo settings menu with:

1. A persisted choice between the existing `3 pill + 3 box` layout and a new
   `6 box` layout.
2. A detailed, visual explanation for every selectable FastInfo card, opened by
   tapping the card in either the settings preview or the available-card pool.

The six selected cards and their order remain identical while switching layouts.
The feature must not duplicate the long explanations as a permanently visible
list below the card pool.

## Non-Goals

- Do not add or remove FastInfo cards.
- Do not change any approved FastInfo calculation.
- Do not maintain separate card selections for the two layouts.
- Do not open card help from the live home-screen FastInfo panel.
- Do not replace the existing long-press drag-and-drop interaction.
- Do not use static screenshots for card previews or explanations.

## Layout Modes

Add a persisted `FastInfoLayoutMode` with two values:

- `mixed`: three vertically stacked pills above three side-by-side boxes.
- `sixBoxes`: three side-by-side boxes above three side-by-side boxes.

`mixed` is the default for missing or unknown persisted values, preserving the
current experience for existing users.

`FastInfoConfig` continues to own two fixed three-slot lists:

- `pills`: the upper three logical slots.
- `boxes`: the lower three logical slots.

These names remain in storage for backwards compatibility. In `sixBoxes` mode,
the `pills` list is rendered as the upper box row. Switching modes changes only
presentation; it never moves, clears, replaces, or duplicates a selected card.

The settings menu shows a two-option segmented layout selector above the preview:

- `3 pill + 3 box`
- `6 box`

Changing the selection updates the preview immediately and persists through the
existing FastInfo settings update path. The live home-screen FastInfo panel
updates from the same saved configuration.

## Panel Geometry

Keep the current `328 px` FastInfo panel height.

In `mixed` mode, retain the existing positions:

- live panel: pills begin at `54 px`, lower boxes at `202 px`;
- settings preview: pills begin at `27 px`, lower boxes at `175 px`.

In `sixBoxes` mode, use those same upper and lower start positions for the two
box rows. Each box remains `112 px` high, leaving a clear gap between rows.

The upper and lower box rows need distinct widget and drag-target keys. Upper
box drops continue to update the logical `pills` list; lower box drops continue
to update the logical `boxes` list.

## Card Help Interaction

In the FastInfo settings menu:

- A short tap on any available pool card opens its help sheet.
- A short tap on any assigned card in the preview opens the same help sheet.
- A long press on a pool card still starts drag-and-drop after the existing
  delay.
- Clear buttons and drag targets keep their current behavior. Tapping a clear
  button clears the slot without opening help.

The help surface is a large, scrollable modal bottom sheet rather than a small
centered dialog. It can be dismissed by the close button, back action, swipe,
or tapping the modal barrier.

The sheet contains:

1. Card title and a short statement of what decision the card helps with.
2. A real pill preview.
3. A real box preview.
4. Directional connector arrows and short labels identifying the meaningful
   regions in each preview.
5. A detailed explanation of the values and comparison period.
6. The exact calculation or ranking rules where applicable.
7. Missing-data behavior, such as hiding progress when no limit exists.

The sheet is informational only. Its previews do not accept drops, clear cards,
or modify the configuration.

## Real Preview and Annotation Design

The help sheet must reuse the same FastInfo pill, box, trend, avatar, progress,
and chart rendering components as the live panel. It uses the existing
deterministic preview metrics, so help never depends on the user's current data.

The annotated previews use stable semantic anchors:

- `pillValue`
- `pillTrend`
- `title`
- `primaryValue`
- `secondaryValues`
- `avatar`
- `trend`
- `visual`

Each card declares only the anchors that are meaningful for it. A dedicated
annotated-preview widget places short callout labels around the real preview and
draws connector arrows from the labels to those anchors. On narrow screens, the
labels may stack above and below the preview, but every arrow and label must
remain visible without horizontal overflow.

Annotations explain the meaning of a region, not merely repeat the rendered
text. Example callouts for `Mai költés`:

- pill value: `Mai elköltött összeg`
- pill trend: `Eltérés a 30 napos napi átlagtól`
- primary value: `Ma elköltve`
- secondary values: `Maradék napi plafon és tranzakciószám`
- visual: `Napi plafon kihasználtsága; csak havi limit esetén`

## Structured Help Metadata

Every canonical `FastInfoCardDefinition` must have complete structured help
metadata:

- short purpose;
- detailed explanation;
- calculation or ranking rule;
- comparison-period explanation;
- missing-data behavior;
- pill callouts;
- box callouts.

The metadata is keyed by the same canonical card ID used by the resolver.
Unknown IDs fail safely with generic `Nincs adat` help, but tests must ensure
all 18 selectable cards have complete metadata.
All user-facing help copy and callout labels are Hungarian.

The help text must describe the existing calculations without introducing a
second implementation of those calculations. The resolver remains the only
source of computed values.

## Required Help Content

### `mai_koltes` - Mai költés

- Purpose: show today's expense and whether today's spending is sustainable.
- Box information: amount spent today, remaining recommended daily ceiling,
  today's expense transaction count, and trend versus trailing 30-day average
  daily expense.
- Calculation:
  `daily ceiling = max(0, monthly limit - current-month expense before today) / remaining days including today`.
- Visual: colored ceiling progress only when a current monthly expense limit
  exists.
- Missing data: without a monthly limit, hide ceiling remaining and progress;
  without a comparison denominator, hide the percentage trend.

### `heti_koltes` - Heti költés

- Purpose: show current Monday-through-today spending and its daily shape.
- Box information: current-week expense, derived weekly allowance remaining,
  and comparison with the previous week through the same weekday.
- Calculation: `weekly allowance = monthly expense limit / 4.345`.
- Visual: seven Monday-Sunday bars; future days are visibly empty.
- Missing data: without a monthly limit, hide allowance remaining and keep bars
  neutral.

### `havi_koltes` - Havi költés

- Purpose: compare the current calendar month with the two preceding calendar
  months.
- Box information: current-month expense, limit usage and remaining amount,
  plus current-month-to-date trend versus the previous month through the same
  day.
- Visual: non-cumulative daily-expense lines for current month, previous month,
  and two months ago; spikes represent high-spend days.
- Missing data: without a monthly limit, hide limit progress and remaining
  amount.

### `megtakaritas` - Megtakarítás

- Purpose: show current-month actual savings and progress toward the configured
  savings goal.
- Calculation:
  `actual savings = max(0, current-month income - current-month expense)`;
  `goal progress = actual savings / configured goal`;
  `savings rate = actual savings / current-month income`.
- Visual: goal ring only when a positive savings goal exists.
- Missing data: show `Nincs cél` without a goal; omit savings rate without
  income.

### `koltesi_trend` - 30 napos költési trend

- Purpose: compare the most recent rolling 30 days with the immediately
  preceding 30 days.
- Box information: latest 30-day total, previous 30-day total, percentage
  change, and limit pace when a monthly limit exists.
- Visual: red upward or green downward expense trend; no chart or progress.
- Missing data: hide percentage when the previous period total is zero.

### `legutobbi_tranzakcio` - Utolsó tranzakció

- Purpose: show the newest recorded transaction at a glance.
- Box information: amount, merchant or name, category, and time.
- Visual: category color and icon avatar.
- Missing data: show that no transaction exists when history is empty.

### `varhato_ho_vegi_koltes` - Várható hó végi költés

- Purpose: estimate total expense by the end of the current calendar month.
- Calculation:
  `projected expense = current-month expense / elapsed month days * days in month`.
- Box information: projected expense, estimated remaining monthly income, and
  risk relative to a monthly limit when available.
- Visual: forecast sparkline.
- Missing data: without a limit, keep the forecast but use neutral risk styling.

### `leggyorsabban_fogyo_kategorialimit` - Kategórialimit állapot

- Purpose: identify the category closest to or furthest over its monthly limit.
- Ranking: highest current-month `spent / category limit`, then category name.
- Box information: category, spent versus limit, count near limit, and count
  over limit.
- Visual: category avatar and colored progress.
- Missing data: show no category limit when none exists.

### `leggyakoribb_kereskedo` - Leggyakoribb kereskedő

- Purpose: identify where expense transactions happen most often.
- Ranking: transaction count, then larger total expense, then merchant name.
- Box information: merchant, transaction count first, and total amount second.
- Visual: avatar from the merchant's most frequent expense category.
- Missing data: show no merchant when no named expense merchant exists.

### `atlagos_napi_koltes` - Átlagos napi költés

- Purpose: show the trailing 30-day daily spending baseline and balance runway.
- Calculation:
  `average = rolling 30-day expense / 30`;
  `runway days = max(0, shared header balance) / average`.
- Visual: trailing 30-day daily-spend sparkline.
- Missing data: omit runway when average expense is zero.

### `no_spend_napok_szama` - No-spend napok

- Purpose: show how many elapsed days in the current month had no expense.
- Calculation: count zero-expense days from month start through today.
- Visual: ring showing `no-spend days / elapsed month days`.
- Missing data: future days never count as no-spend days.

### `top_kategoria_ma` - Top kategória ma

- Purpose: identify today's largest expense category.
- Ranking: total expense amount, then transaction count, then category name.
- Box information: category, amount, and share of today's expense.
- Visual: category avatar.
- Missing data: show that today has no spending when applicable.

### `top_kategoria_heten` - Top kategória héten/hónapban

- Purpose: compare the most frequently used expense category this week and this
  month.
- Ranking: transaction count, then larger total expense, then category name.
- Box information: weekly top category as primary and monthly top category as
  secondary, including counts and amounts.
- Visual: weekly primary category avatar.
- Missing data: use the available period when only one period has data.

### `legnagyobb_novekedo_kategoria` - Legnagyobb kategóriaváltozás

- Purpose: identify the category with the largest change between consecutive
  rolling 30-day periods.
- Ranking: new categories first, then largest absolute percentage change, then
  current amount, then name.
- Box information: current and previous 30-day amounts.
- Visual: red upward or green downward trend and category avatar.
- Missing data: a previously absent category displays `Új`, not infinity.

### `kovetkezo_ismetlo_kiadas` - Közelgő ismétlődő kiadások

- Purpose: show the next pending recurring expense and the next seven days'
  recurring burden.
- Box information: next item name, amount, due date, next-seven-day count, and
  next-seven-day total.
- Visual: recurring item's category avatar.
- Missing data: show no upcoming recurring expense when none is pending.

### `havi_fix_koltseg_osszesen` - Havi fix költségek

- Purpose: summarize expected recurring expenses in the current month.
- Box information: total, already deducted amount, remaining fixed amount,
  largest fixed item, and budget remaining after fixed costs.
- Visual: fixed-cost/monthly-limit ring only when a monthly limit exists.
- Missing data: hide limit-dependent values without a monthly limit; show no
  fixed cost when no recurring expense exists.

### `bevetel_ebben_a_honapban` - Havi bevétel

- Purpose: show current-month income and how many average-spend days it covers.
- Calculation:
  `coverage days = current-month income / trailing 30-day average daily expense`.
- Comparison: current month through today versus previous month through the same
  calendar day.
- Visual: green upward or red downward income trend.
- Missing data: omit coverage when average expense is zero; hide percentage
  trend when previous-period income is zero.

### `kiadas_bevetel_arany` - Kiadás/bevétel arány

- Purpose: show what share of current-month income has already been spent.
- Calculation:
  `ratio = current-month expense / current-month income`;
  `cashflow = current-month income - current-month expense`.
- Box information: ratio and net monthly cashflow.
- Visual: shared green/yellow/red progress thresholds.
- Missing data: without current-month income, omit ratio and progress but still
  show cashflow.

## Architecture and Data Flow

### Persisted Configuration

`FastInfoConfig` gains the layout mode and includes it in `toMap` and `fromMap`.
The Android `ExpenseSettingsStore` preserves the same field while normalizing
the two existing fixed slot lists. Old stored JSON without the field loads as
`mixed`.

The existing bridge, repository, settings store, and shell propagation remain
the save and live-update path. No second preference key or separate layout
repository is introduced.

### Rendering

`FastInfoPanel` chooses one of two upper-row renderers from the saved mode:

- mixed upper renderer: three pills;
- six-box upper renderer: three boxes backed by the logical `pills` slots.

The lower box row is shared by both modes. Shared box rendering accepts a row
identity so upper and lower keys and drag targets do not collide.

The settings preview supplies tap callbacks. The live home panel does not, so
live FastInfo behavior remains unchanged.

### Help

The help metadata is read by a dedicated FastInfo card help sheet. The sheet
resolves deterministic preview metrics by canonical card ID and creates
temporary pill and box slots for the same card. It passes them through the
shared render components and overlays only explanatory callouts.

The settings panel owns opening the sheet because help is a settings-only
interaction. This keeps the live renderer independent of navigation and modal
presentation.

## Error and Missing-Data Handling

- Missing or unknown persisted layout values load as `mixed`.
- Switching layouts never changes slot membership, including empty slots.
- Missing preview metric data renders `Nincs adat` without preventing the sheet
  from opening.
- Missing help metadata falls back to a generic explanation, although catalog
  completeness tests must prevent this for selectable cards.
- Callouts for unavailable visual regions are omitted instead of pointing to
  empty space.
- Modal content remains vertically scrollable on compact screens and with large
  text scaling.

## Testing and Verification

### Model and Persistence Tests

- Default and unknown layout values resolve to `mixed`.
- Both layout modes round-trip through `FastInfoConfig`.
- The Android settings update path preserves the layout field.
- Switching layout leaves all six IDs and positions unchanged.
- All 18 canonical cards have complete structured help metadata.

### Widget Tests

- The selector displays both modes and immediately updates the settings preview.
- `mixed` renders three pill slots and three lower box slots.
- `sixBoxes` renders two distinct rows of three boxes with no pill surfaces.
- Upper-row drops in `sixBoxes` update the logical upper slots.
- Pool-card tap and assigned-preview-card tap open the correct help sheet.
- Pool-card long press still starts drag-and-drop.
- The help sheet renders real pill and box previews, callout arrows, calculation
  text, and missing-data text.
- Each card help sheet renders without overflow at compact and wide widths.
- Both panel layouts render without overflow at existing supported widths.

### Regression Verification

- Run targeted FastInfo model, settings, bridge, panel, and header tests.
- Run `flutter analyze`.
- Run the full Flutter test suite.
- Push `main` and verify the existing GitHub Actions Android build and release
  workflow completes successfully.
