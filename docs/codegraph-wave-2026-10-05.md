# Final 3D Month wave source graph

- Indexed application: `6df3abe533964507638a48c4743e733cd22bbc52`.
- Parent: `0b5982ffaaaf6d209c2d2d101e6f788c8ada464c`.
- Exact clean detached source: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-3d-linechart-final-source`.
- SCIP 1.6.2 index SHA-256: `8c406b642bf62af6d53f6ff25fc7b6cca9e41eaa801f71d6e6244e0a307482cd`.
- Regenerated twice with identical artifact digest: `e82d6aa3d29a9b2f061ad4839c769bd88a5cc67920a6d5d26cc395b4ccf0b2bf` (sorted relative file SHA-256 lines, then SHA-256).
- 607 documents; 438,304 occurrences; 15,153 retained repository symbols;
  109,637 references and 32,191 evidence-labelled reference edges.
- Tooling suite: 15 tests PASS in Ubuntu proot. Raw index remains uncommitted.

Queries were executed for `FluviTopographicWaveChart`,
`FluviTopographicWaveTerrain`, `fluviBoundedMonotoneSegments` and
`BalanceAlternativeDailySpendCard`. The neutral bounded-control function has
exactly two production consumers: Mind's existing adapter and Month's sampler;
its test is the third reference. The chart's sole external production
constructor is the Month daily-spend card. That card has one production caller,
the actual Balance core surface. Terrain/resource references remain within the
chart library and its tests. These relationships were checked in current source.

This is a static symbol/reference graph, not runtime flow or performance proof.
The graph commit is on the separate `tooling/3d-linechart-final-graph` branch;
it does not modify or build the application. Its `[skip ci]` commit must not
start an APK delivery. The application branch retains its own acceptance,
render, timing, CI and Human-APK evidence.
