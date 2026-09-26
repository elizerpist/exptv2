# Balance carousel polish acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCP-01 | Original task §2; `balancecarousel.png` | `balance_dashboard_core_surface.dart` | Every Balance mini card renders one subdued title, one same-weight leading visual slot, primary text, and secondary text from one metric system. | Focused widget test and golden. | DONE |
| BCP-02 | Original task §1/§2.3 | shared carousel + Balance renderer | Existing controller, shared physics, focus scale, and outer card bounds remain unchanged. | Existing identity/geometry tests and source audit. | DONE |
| BCP-03 | Original task §3.1 | `balance_linked_detail_card.dart` | Top Partner and Top Category page-one rows use identical height, padding, avatar slot, text hierarchy, amount alignment, and divider rhythm. | Cross-topic mounted parity test. | DONE |
| BCP-04 | Original task §3.2/§4; `topcategory.png` | `balance_linked_detail_card.dart` | Both entity page-two states use the shared return/hero/pill/chip/distribution template and fill the production 210px envelope. | Cross-topic geometry test and compact goldens. | DONE |
| BCP-05 | Original task §5.1–§5.3 | `dashboard_shell_presentation.dart` | Ledger count is wholly visible with minimum clearance above the physical BottomNav; a SearchPill remainder is allowed only when safety requires it. | Pure resolver and real-shell rect tests. | DONE |
| BCP-06 | Original task §5.4/§6/§7 | global dashboard geometry | The stretch is shared across modes, bounded by the actual contained-FAB release and count safety, with no financial/Query/search semantic change. | Cross-mode widget tests, source and dependency audit. | DONE |
| BCP-07 | User delivery rules | branch, CI, APK | All delivered production changes are committed, pushed, verified online, then the exact human APK is downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256. | Git/Actions/artifact check. | PARTIAL |
