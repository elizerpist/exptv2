# FastInfo Final Cards Design

## Status and Goal

Approved during the June 5-6, 2026 FastInfo card review.

Implement the reviewed 17 FastInfo cards in both box and pill presentations, make fixed/scheduled transactions explicit, update the help sheets with simple Hungarian explanations and diagrams, and support GitHub Actions as the online Android build path.

This spec supersedes the older FastInfo card-help details in `2026-06-04-fastinfo-layout-and-card-help-design.md` where the two disagree.

## Layout

- Upper FastInfo row can be rendered as `pill` or `box`.
- Lower FastInfo row can also be rendered as `pill` or `box`.
- Switching presentation never moves the selected card IDs between slots.
- Target box size is `112 x 136`.
- Target pill shape is about `350 x 38`.
- Pill anatomy: full card name on the left, main value and secondary value in the middle, compact visual on the right.

## Fixed and Scheduled Transactions

Activated transactions created from recurring ghosts must keep a stable source marker, such as `recurringTransactionId`, so FastInfo can detect scheduled items after activation.

Variable-spend metrics exclude fixed/scheduled expenses: daily ceiling, weekly pace, monthly pace/index, rolling 30-day trend, average daily spend, no-spend days, top categories, category change, category limit burn, and merchant activity.

Real all-money metrics include fixed/scheduled transactions: latest transaction, next fixed item, monthly fixed costs, monthly income, income spent ratio, and the app header balance.

Recurring income ghosts must be implemented too. Expense ghosts already exist; income ghosts need the same bridge/model path so expected-income information is not one-sided.

## Help Sheets

Every selectable FastInfo card opens a help sheet on tap.

- The top of the sheet is card-shaped and shows the same style of preview as the app.
- The sheet closes only by dragging the handle downward, close button, back, or barrier.
- Dragging inside the body scrolls the text and must not dismiss the sheet.
- Dragging the handle must not scroll the body.
- Copy is Hungarian and uses simple language: what the card shows, how it counts, what the visual means, and what happens when data is missing.
- Each sheet includes preview/callout arrows.

## Final Cards

### 1. `mai_koltes` - Mai költés

Main box value is today's real spent amount. It also shows today's transaction count, `x költhető`, a wide daily ceiling bar, and `napi átlaghoz képest:` for the comparison percentage.

Pill uses the selected G+I visual: 100% is today's variable spendable amount, fill is today's variable spend, and the daily average is a marker. If the average is over 100%, show a dashed overflow marker to the right. The 100% bar has a flat right edge.

Calculation: `daily ceiling = max(0, monthly limit - variable current-month expense before today) / remaining month days including today`. Actual displayed spent amount includes fixed items; progress and percentages exclude them.

### 2. `heti_koltes` - Heti költés

Box main value is weekly spend. The visual is seven bars, Monday to Sunday. Future days are empty. Bar color is green/yellow/red based on daily allowance usage.

Pill uses selected J. Main value is weekly spend, secondary is `időarányhoz képest <n>p`, where `p` means percentage points. Visual is a centered pace deviation meter.

Calculation: `weekly allowance = monthly expense limit / 4.345`. Pace points = `weekly variable spend / weekly allowance - elapsed week share`. Fixed items are excluded from progress, colors, and pace.

### 3. `havi_koltes` - Havi költés

This card is calendar-month based, not rolling 30 days. Box shows current month, previous month through the same day, the month before that, and a daily line chart. Spiky days must spike the line.

Pill uses selected E. Main value is monthly spend. Secondary is `előző hónap index: <n>%`. The visual compares current month-to-date to previous month-to-date, where previous month same day is 100%.

Variable percentages and line chart exclude fixed/scheduled expenses.

### 4. `megtakaritas` - Megtakarítás

Box main value is current-month actual savings. The ring is smaller so it does not clip text.

Pill uses selected C. Main value is saved amount. Secondary value is expected goal progress.

Calculation: `actual savings = max(0, current-month income - current-month expense)`. Progress = `actual savings / configured monthly savings goal`.

### 5. `koltesi_trend` - 30 napos trend

Shows last 30 days versus the previous 30 days. Both windows move every day. The card must say `fixek nélkül`.

Pill uses selected E: last 30-day variable spend, percent change, and a colored zone marker. Fixed/scheduled expenses are excluded.

### 6. `legutobbi_tranzakcio` - Utolsó tranzakció

Box and pill show category color plus icon avatar, no black initial. Box avatar is smaller so merchant/category text does not clip. Merchant and category sit under the avatar.

Calculation: newest transaction by date and time. Fixed/scheduled transactions may appear because this is a real latest-event card.

### 7. `varhato_ho_vegi_koltes` - Várható hó végi költés

Box uses selected A and removes the optimistic/expected/pessimistic text row to avoid clipping. Chart is a forecast line.

Pill uses selected A: projected month-end spend, monthly limit usage, and a fill toward the monthly limit. Variable forecast pace excludes fixed items.

### 8. `leggyorsabban_fogyo_kategorialimit` - Legszűkebb limit

Box uses category color plus icon avatar. Pill uses selected D: projected limit usage, category name, and overflow-risk visual.

Calculation: projected variable category spend divided by category limit. Fixed/scheduled expenses are excluded.

### 9. `leggyakoribb_kereskedo` - Gyakori kereskedő

Pill uses selected D: merchant transaction count, active days, and a 14-day activity strip.

Ranking: transaction count, then total amount, then most recent activity, then merchant name. Fixed/scheduled expenses are excluded.

### 10. `atlagos_napi_koltes` - Napi átlag

Pill uses selected F: trailing 30-day average, spike note, and a line with spike markers. Calculation is last 30 days variable spend divided by 30.

### 11. `no_spend_napok_szama` - Költésmentes napok

Pill uses selected D: no-spend days in the last 7 days, `elmúlt 7 nap`, and a seven-day strip. Today is highlighted with FAB blue `#06B6D4`. A fixed-only day still counts as no-spend for variable spending.

### 12. `top_kategoria_heten` - Top kategóriák

Merged daily, weekly, and monthly top-category card. Box and pill use mini category avatars plus amounts, no letters. Top category is selected by variable amount for today, week, and month. Fixed/scheduled expenses are excluded.

### 13. `legnagyobb_novekedo_kategoria` - Kategóriaváltozás

Pill uses selected C. Main value is category plus amount change, secondary is percent change, and visual is an analog centered deviation meter.

Calculation: biggest absolute category change between last 30 days and the previous 30 days. Fixed/scheduled expenses are excluded.

### 14. `kovetkezo_ismetlo_kiadas` - Következő fix

Box shows category color plus icon avatar and explicit `Időzített` marker. Pill uses selected A: next scheduled expense, days remaining, and next-seven-day scheduled load. Ranking: earliest pending due date, then larger amount, then name.

### 15. `havi_fix_koltseg_osszesen` - Havi fixek

Pill uses selected A: remaining scheduled fixed expense this month, total monthly fixed expense, and paid-versus-remaining split. Fixed/scheduled expenses only.

### 16. `bevetel_ebben_a_honapban` - Havi bevétel

Pill uses selected D: percent change versus previous month through the same day, received income, and previous/current same-day comparison bars. Recurring income ghosts support expected income, while actual received income stays based on real activated income transactions.

### 17. `kiadas_bevetel_arany` - Bevétel elköltve

Pill uses selected E, modified. Main value is `29% maradt` style remaining percentage. Secondary value is the remaining amount from income. Right-side visual: left green is remaining, right gray is already spent.

Calculation: `spent ratio = current-month actual expense / current-month actual income`; `remaining ratio = max(0, 1 - spent ratio)`. This card includes actual fixed/scheduled expenses because it shows real income usage.

## Metric Model Requirements

Avoid card-specific string parsing. Add typed fields for pill title, primary, secondary, visual kind, fixed-excluded badge, scheduled marker, marker bars, split bars, deviation meters, strips, forecast lines, mini avatar rows, and paid/remaining splits.

## Testing Requirements

Every behavior change uses red/green TDD: write failing test, run it and record the expected failure, implement the smallest useful code, rerun the same test, then run the relevant FastInfo group. Before final push, run full tests and analyzer locally when possible, then verify GitHub Actions online build.

Local Termux Flutter currently fails before tests with an ARM64 Bionic TLS alignment error, so GitHub Actions is the authoritative build environment until the local Flutter binary is replaced.
