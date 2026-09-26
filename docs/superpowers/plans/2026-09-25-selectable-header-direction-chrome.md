# Implementation plan — selectable Header and direction chrome

1. Add the appearance enums/fields/setters and RED state/tuner tests.
2. Extend the central geometry frame with the lower-handle-presence input and
   Header-integrated handle bounds; prove 20px lower-lane reclamation.
3. Reuse `DashboardCollapseHandle` for all visual styles and mount it at its
   resolved location without adding a second expansion owner.
4. Add a stateful sliding rail renderer with a pure fixed-gradient geometry
   contract, fixed semantic half buttons, and existing asset/drag behavior.
5. Transport the single mode-label visibility bit through the existing Header
   visual frame. Add one shared reserve token and use it in Balance and Mind
   values/charts only.
6. Add Mind's two-choice expanded-surface presentation to the same global
   session owner. Keep separate cards compatible; give seamless a Mind-local
   continuous geometry/radius/shadow adapter and header-led body reveal.
7. Add Budget's three-choice avatar/content presentation to that same owner.
   Keep avatar anchors fixed and make its Budget-local content surface/rail
   chrome adapt without changing Budget selection or data owners.
8. Run focused RED/GREEN cycles, then protected mode/interaction suites,
   formatting, analyzer, diff checks, exact-source CI/APK, and SCIP refresh.
