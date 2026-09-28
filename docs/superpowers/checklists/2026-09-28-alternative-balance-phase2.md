# Alternative Balance dashboard phase 2 acceptance checklist

Status legend: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

Card 3 source authority: `/storage/emulated/0/spendee/source of truth/barchart.png`.
The user explicitly corrected the original filename and approved this source.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ALT2-01 | §§3–5,22–23 | scope adapter/routing | A sealed scope-specific render adapter uses canonical scope identity; no nullable cross-scope model or financial reprojection. | pure tests | DONE |
| ALT2-02 | §§19–21,36–37 | five/four geometry | SUM/YEAR use exact five slots; MONTH/DAY keep exact four slots. | pure + mounted rect tests | DONE |
| ALT2-03 | §§1,6–10,17–18,28–31 | Card 3 renderer | Shared source-locked income/expense renderer uses chart-specific Card 3 chrome and a common Y scale. | widget + golden | DONE |
| ALT2-04 | §§7–10,38–39 | YEAR Card 3 | Exactly 12 fixed monthly pairs and labels fit without a horizontal Scrollable. | adapter + mounted fit test | DONE |
| ALT2-05 | §§11–16,40–41 | SUM Card 3 | Real years remain chronological; only the plot lane scrolls on overflow, begins at recent end once, and preserves user position. | adapter + widget test | DONE |
| ALT2-06 | §§24–27,42 | scope content | SUM/YEAR Card 3 is real while all other requested slots remain placeholders; MONTH/DAY have no Card 5 or new bars. | widget regression | DONE |
| ALT2-07 | §§32–35,43 | boundary/gesture | No bar infocards or extra repository/Query/prepared-index work; dashboard vertical behavior remains parent-owned. | focused regression | DONE |
| ALT2-08 | delivery | CI/APK | Production commit pushed; successful exact human APK is downloaded under `/storage/emulated/0/Download/fluvi` and hashed. | Actions + file/hash | DONE |

`PHYSICAL VALIDATION: PENDING — USER ONLY`
