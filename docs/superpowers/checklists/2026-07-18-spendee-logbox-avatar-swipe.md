# Spendee Logbox Avatar And Swipe Acceptance Checklist

Date: 2026-07-18

| ID | Source instruction / reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| LB-001 | User: "a logboxok category avatarjából szedd ki a felső világos félkör alakú csíkot" | `GlossyCategoryAvatar`, `TransactionLogBox`, experimental `_SpendeeLogBox` | Transaction logbox category avatars render without the top bright semicircle highlight; non-logbox avatars keep their existing default highlight. | `flutter test test/transactions/transaction_widgets_test.dart`; `flutter test test/spendeetest/spendee_dashboard_interaction_test.dart`; `flutter analyze`. | DONE |
| LB-002 | User: "továbbá lehessen swipe" | Experimental `_SpendeeLogBox` drag handling | The experimental dashboard logbox reacts to deliberate horizontal swipe distance, so slow left/right swipes work instead of requiring a high release velocity. | `experimental logbox accepts deliberate slow right swipe`; `experimental logbox accepts deliberate slow left swipe`; full `spendee_dashboard_interaction_test.dart`; `test/web_preview/exptv2_web_preview_test.dart`; `flutter analyze`. | DONE |
| LB-003 | User workflow: run Flutter debug server and provide localhost port | Flutter web-server debug session | After verification, the local Flutter web-server is running and reachable on localhost. | Hot restart via Flutter stdin; `curl http://127.0.0.1:8766/`; `curl http://127.0.0.1:8766/main.dart.js`. | DONE |
