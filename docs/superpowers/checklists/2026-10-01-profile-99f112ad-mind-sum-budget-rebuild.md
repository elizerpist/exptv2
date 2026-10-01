# Profile `99f112ad` — Mind, SUM and Budget rebuild checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

## Rebaseline decision

The prior implementation attempt landed on the unrelated
`feature/balance-carousel-v1` line (`c52f7a68…`), while the user identified
the actual application base as `profile/99f112ad2577`:

- canonical source branch: `feature/balance-wave-defaults`
- exact base: `99f112ad25770ca4e5595d2e15975a37957a5c4f`
- base subject: `feat(balance): implement live napi4 daily insights`
- base Human Diagnostic tag: `fluvi-human-diagnostic-99f112a`

The two branches diverge at `f6d12aa32cfe919cba0c2014ec875bbc1a9752d9`.
Nothing from the prior `c52…` delivery is accepted as delivered on this base.
Every requirement from its checklist is intentionally re-opened below as
`NOT DONE`; implementation must be ported or rebuilt without overwriting the
live Balance child-card/Napi4 work already present at `99f112ad…`.

No build, APK, commit, push, or completion claim is valid until every product
row is `DONE` (unless the user explicitly approves a deferral).

## Mandatory sources and invariants

- SUM-A source of truth: `/storage/emulated/0/spendee/source of truth/suma.png`
- SUM-B source of truth: `/storage/emulated/0/spendee/source of truth/sumb.png`
- Day All-vs-slider source of truth:
  `/storage/emulated/0/spendee/source of truth/napiheatmap.png`
- Latest observed SUM regression screenshot:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261001-073824.png`
- Correct Balance source/branch base: `99f112ad25770ca4e5595d2e15975a37957a5c4f`
- Protected physical interaction floor:
  `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`
- Required source policy: `MILESTONE_COMMITS.md` and
  `docs/FLUVI_ENGINEERING_JOURNAL.md`.

Before any relevant visual implementation or validation, re-open the matching
PNG/screenshot. Production UI may not embed or render those PNGs.

## Architecture card

| Concern | Single owner / write path | Consumers | Boundary proof |
| --- | --- | --- | --- |
| Correct baseline | `feature/balance-wave-defaults` from `99f112ad…` | all implementation and final CI | ancestry / exact build marker |
| Dashboard display preferences | existing persisted display-preferences controller and store | hamburger settings, Mind, Balance | store/controller/boundary tests |
| SUM variant | one `Current/SUM-A/SUM-B` resolver | Mind SUM renderer | source screenshots + widget/golden tests |
| Temporal-card chrome | one shared SUM-derived header geometry spec | Mind SUM/Year/Month/Day | RenderBox/title-style parity tests |
| Mind amount range | existing canonical range control + live preview owner | heatmap renderers only | one mounted RangeSlider, no duplicate range state |
| Day hourly comparison | pure projection from resident `MindDayHeatmapFrame` full and selected events | Day all-vs-slider page | unit/widget tests; zero repository/query work |
| Balance child shells | persisted display preference + existing Balance composition | all four child cards | both paths preserve live `99f112ad…` content |
| Budget daily allowance | pure scaled-integer prepared analysis | Budget DAY header | unit fixtures |
| Distribution count ranking | bounded prepared Budget acquisition and presentation ranking owner | Budget Category/Partner lists | native/codec/projector/widget tests |

UI renders immutable frames and forwards intents. No leaf widget owns
persistence, Query, repository, financial computation, Time/Avatar motion or
RangeSlider state. Existing Avatar, Time and distribution PageController /
ScrollPosition identities and physics remain untouched.

## Re-opened previous SUM/settings requirements

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| SUM-01 | Hamburger setting: Current / SUM-A / SUM-B | persisted display preferences + header tuner | platform SharedPreferences adapter, controller and tuner routes pass focused tests | DONE |
| SUM-02 | Current preserves the legacy SUM renderer | SUM resolver | renderer-selection test proves Current retains legacy surface | DONE |
| SUM-03 | SUM-A matches `suma.png` | SUM composition/tokens | native reference-led renderer added; screenshot/pixel comparison remains | PARTIAL |
| SUM-04 | SUM-B keeps SUM-A months but uses the SUM-B mother-card tone and dimensional year card | SUM composition/tokens | native hybrid renderer added; screenshot/pixel comparison remains | PARTIAL |
| SUM-05 | Hamburger setting: show/hide SUM top-right layout chooser | persisted preferences + SUM header | persisted setting and reflow pass tuner/widget coverage | DONE |
| SUM-06 | Shared content-card header spec across SUM/Year/Month/Day | shared temporal card chrome | one shared header type is mounted by every temporal viewport and passes geometry coverage | DONE |
| SUM-07 | Year remains one-page/non-scroll, including 4-column non-stretched layout | Year layout solver | 4×3 constrained and direct-grid zero-scroll coverage passes | DONE |
| SUM-08 | Hamburger setting: show/hide Year mother-card top-right actions | persisted preferences + Year header | persisted visibility route passes focused coverage | DONE |
| SUM-09 | Hamburger setting: Balance child cards on/off | persisted preferences + Balance composition | on/off preserves Napi4 live contents in focused coverage | DONE |
| SUM-10 | All preceding controls are in the existing hamburger menu | header visual tuner | real header visual tuner route is exercised by widget tests | DONE |
| SUM-11 | Source PNGs remain development references only | Mind renderer | no raster asset/reference import in production source; native surfaces only | DONE |

## Re-opened previous Budget DAY requirements

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| DAY-01 | Replace only Budget DAY `Napi tempó` daily-average meaning with selected-day actual / dynamic daily allowance | budget scope analysis + header | direct presentation tests prove new values rather than relabelled pace | DONE |
| DAY-02 | Allowance = `max(0, round((monthlyLimit - spendBeforeDay) / remainingDaysInclusive))` using scaled integers | pure analysis | underspend/overspend fixtures pass | DONE |
| DAY-03 | Selected day spend is not counted twice in allowance | pure analysis | selected-day exclusion fixture passes | DONE |
| DAY-04 | Truthful current/historical/future DAY labels and unavailable state | Budget header | current/historical/future presentation tests pass | DONE |
| DAY-05 | Month/Year/SUM Budget header semantics and secondary projections stay unchanged | Budget presentation | scope regression coverage passes | DONE |
| DAY-06 | Existing HUF formatting/rounding only; no double money arithmetic | analysis/formatter | scaled-integer fixture coverage passes | DONE |

## Re-opened Budget distribution and ranking requirements

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| DIST-01 | Remove Partner Spending Rhythm renderer/footer in SUM/Year/Month/Day | Partner distribution page | no footer, placeholder, divider gap or reserved lane | NOT DONE |
| DIST-02 | Preserve non-Partner Rhythm consumers | ownership audit | no accidental rhythm data removal | NOT DONE |
| DIST-03 | Partner and Category donut bounds are equal under identical Card2 constraints | shared distribution surface | RenderBox left/top/width/height parity | NOT DONE |
| DIST-04 | No Partner-specific geometry magic layout | shared geometry | one common surface contract | NOT DONE |
| DIST-05 | Pie heading and list heading/selector occupy one shared title row | shared page surface | aligned with body columns | NOT DONE |
| DIST-06 | Compact/normal, unified/split, SUM/Year/Month/Day layouts have no overflow/blank lane | distribution test matrix | mounted layout coverage | NOT DONE |
| RANK-01 | Compact `Részesedés` / `Tranzakciószám` selector for Category and Partner lists | stable Card2 presentation owner | share default; survives rebuild/rebase | NOT DONE |
| RANK-02 | Selector is immediate presentation-only state | ranking owner | no Query/filter/avatar/focus/page/controller mutation or async work | NOT DONE |
| RANK-03 | Share ranking: exact amount descending, stable tie; percent trailing metric | immutable list projection | current behavior retained | NOT DONE |
| RANK-04 | Count ranking: exact scoped Category/Partner transaction counts including Day and selected Category target | prepared-data projector | real count, not buckets/active days | NOT DONE |
| RANK-05 | Count tie-break: count, amount, stable identity; integer trailing value | trailing metric model | no percent in count mode | NOT DONE |
| RANK-06 | Pie remains monetary share regardless of list ranking | visual bank/interaction mapping | unchanged slices and stable target identity | NOT DONE |
| COUNT-01 | Audit an existing exact count authority before adding one | prepared Budget graph | documented provenance | NOT DONE |
| COUNT-02 | If needed, add `COUNT(*)` beside existing bounded sum acquisition, not a second query | native snapshot/bridge | no per-selector acquisition | NOT DONE |
| COUNT-03 | Counts survive native, binary, Dart and projector boundaries | codec models | aggregate/category/partner/category-partner/Day round trips | NOT DONE |
| COUNT-04 | Ranking availability does not increase SQL call count | native/performance test | before/after bound proof | NOT DONE |
| RANK-07 | Legend trailing metric is semantically typed | shared legend row | percent/count cannot be confused | NOT DONE |
| RANK-08 | Selector tap performs no resident revision acquisition work | ranking performance test | zero repo/index/scene/SQL/query work | NOT DONE |

## Current Mind/SUM observations — preserved in user-provided order

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| OBS-01 | Every Mind SUM/Year/Month/Day content-card header must be exactly the SUM header: same position, font sizes, typography hierarchy and padding | shared temporal-card chrome and all four viewport parents | one `MindTemporalContentHeader` now used by all four; final screenshot parity remains | PARTIAL |
| OBS-02 | Remove the unusable static red/pink SUM rail and the resulting false lower-card/nested-card bottom; retain only the functional canonical green amount control | SUM reference surface + Mind content composition | reference renderer has no decorative rail; integration screenshot with the canonical control remains | PARTIAL |
| OBS-03 | SUM year identity cards at the left edge respond to the same live range/intensity colouring as the month cells | common SUM intensity/token resolver | frame-driven year identity intensity implemented; interactive proof remains | PARTIAL |
| OBS-04 | Add a Mind Day All-vs-slider double heatmap page identical in composition to `napiheatmap.png`: hourly full background plus selected foreground | resident Day frame projection + Day renderer/view selector | resident pure 24-hour full/selected projection and native renderer pass focused tests; final source screenshot match and canonical-slider composition remain | PARTIAL |
| OBS-05 | Build only from correct Balance base `99f112ad…`, retaining its dashboard-style unified Balance mother card and four selectable child cards | integration/branch discipline | final SHA descends from `99f112ad…`; Balance regression proves four-card live content is retained | NOT DONE |

## Protected invariants and final delivery

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| SAFE-01 | Preserve protected physical interaction floor `6e962…` | all touched code | Avatar/Time/PageView identities, positions and physics unchanged | NOT DONE |
| SAFE-02 | No Balance/Mind/Budget cross-regression outside stated scope | scope review + protected tests | exact diff/boundary suite | NOT DONE |
| TEST-01 | Red tests precede each behavior family | tests | observed meaningful RED then GREEN | NOT DONE |
| TEST-02 | Focused tests, format, analysis, diff and source-reference visual checks | validation | exact results recorded honestly | NOT DONE |
| REL-01 | One integrated application commit contains every delivered prior and current feature requirement and descends from `99f112ad…` | git | no unrelated user files | NOT DONE |
| REL-02 | One final online Human Diagnostic build after all implementation only | GitHub Actions | exact application SHA workflow clean or honestly classified | NOT DONE |
| REL-03 | Download the final Human APK to `/storage/emulated/0/Download/fluvi`, verify SHA-256 and embedded commit | delivery | APK is exact final SHA | NOT DONE |
| REL-04 | Append factual journal evidence separately with `[skip ci]` after app evidence | journal | physical validation remains USER ONLY | NOT DONE |
| REL-05 | Completion report distinguishes proven/unproven and records final git state | final handoff | no unfinished requirement claimed complete | NOT DONE |
