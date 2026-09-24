# Acceptance checklist — Spendee ranked overview, Latest presentation, Header mode icon

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| RANK-01 | Spendee `TopCategoriesDetail` hierarchy; user requires five ranks | `balance_linked_detail_card.dart` | #1 + #2–#5 simultaneously visible, no master scroll, no overflow at production and narrow bounds | DONE |
| RANK-02 | Spendee leader anatomy | shared local ranked overview | #1 rounded-square canonical badge, name + gray metadata, divider, pink `#FB4276` large right amount | DONE |
| RANK-03 | Spendee follower anatomy | shared local ranked overview | #2–#5 circular canonical icon/color avatar, compact copy/meta, dark `#26355A` amount, no separate rank column | DONE |
| RANK-04 | User Top Category semantics | ranked metadata policy | category placement metadata only; current amount ranking stays unchanged | DONE |
| RANK-05 | User Top Partner semantics | ranked metadata policy | transaction-count ordering remains #1 despite amount display; metadata retains count + placement | DONE |
| RANK-06 | Existing local detail contract | `_RankedDetailState` | row taps/Back/stale replacement remain local; secondary detail unchanged | DONE |
| RANK-07 | Explicit exception | no new selector | no Havi/Éves/Össz state or UI | DONE |
| LATEST-01 | Spendee FastInfo header source | Balance selected Latest renderer | exact local visual spec: padding 9/7/9/18, 20px disc/header, category icon, colors, gap/title metrics | DONE |
| LATEST-02 | User default layout | `BalancePresentationSettings` + renderer | default `avatarPartner`: header then compact 15/8 badge + primary partner; no amount/date/time/category text | DONE |
| LATEST-03 | Spendee alternative | same renderer | selectable `spendeeThreeLine`: header, exact whole-HUF amount, partner secondary metrics | DONE |
| LATEST-04 | Existing Settings ownership | `BalancePresentationController` | enum/default/copy/equality/hash/revision/setter; switching changes render only and retains carousel identity/order | DONE |
| HDR-01 | User SVG sources | bundled assets + Header primitive | balance/mind/budget white local SVG icon replaces textual mode label in Header right corner | DONE |
| HDR-02 | User navigation contract | `DashboardCoreModeHost` | icon tap invokes existing forward mode switch; Header horizontal swipe no longer switches; vertical expansion remains | DONE |
| HDR-03 | owner/layer contract | Header action/host tests | icon semantics/hit area visible and interactive above Header gesture layer; no new controller/physics owner | DONE |
| HDR-04 | User follow-up: icon foreground | `DashboardHeaderVisualTuning` → `DashboardHeaderVisualFrame` → Header action | Balance/Mind/Budget icons independently select Fehér/Fekete/Lágyított; no text/chart setting is silently changed | DONE |
| HDR-05 | User follow-up: chart under-line veil | same Header visual owner → shared trend painter | Balance/Mind independently select veil enabled state and Fehér/Fekete/Lágyított color; line path/points/width and data are unchanged | DONE |
| DELIVERY-01 | Global workflow | tests + CI | focus/protected tests, formatting, analysis/diff, online exact-source signed APK download/verification, final SCIP | NOT DONE |
| DELIVERY-02 | Physical acceptance | user only | final physical validation reported PENDING — USER ONLY | BLOCKED |
