# Measured Mother Card geometry

Reference viewport 412 × 892, default ordering, no physical rail, no stretch.
Values are logical layout coordinates. Old policy is the independent historical
`2e809f2` oracle. Current policy is measured through the three production
adapters. These values are not pixel-detected chart ink.

| Mode | Separation | Old body bottom | Current body bottom | Current content envelope bottom | Old trailing gap | Current trailing gap |
|---|---:|---:|---:|---:|---:|---:|
| Budget | 35% | 585.841 | 530.527 | 563.851 | 21.990 | −33.323 |
| Budget | 50% | 570.262 | 482.269 | 541.378 | 28.884 | −59.109 |
| Budget | 65% | 545.830 | 419.835 | 514.460 | 31.370 | −94.625 |
| Balance | 35% | 585.841 | 530.527 | 519.380 | 66.461 | 11.148 |
| Balance | 50% | 570.262 | 482.269 | 471.582 | 98.681 | 10.688 |
| Balance | 65% | 545.830 | 419.835 | 409.663 | 136.168 | 10.172 |
| Mind | 35% | 454.795 | 530.527 | 520.309 | −113.762 | 10.219 |
| Mind | 50% | 390.339 | 482.269 | 472.472 | −165.647 | 9.797 |
| Mind | 65% | 325.882 | 419.835 | 410.510 | −217.533 | 9.324 |

Trailing gap means body bottom minus the **unclipped** content allocation
bottom. A negative value describes allocation below the card clip, not a good
zero-gap result. Mind's old/new content trajectories differ, so its old gap
compares against the old content envelope.

Balance keeps its accepted lower analytical transform. Its trailing allocation
shrinks by 83.2%, 89.2%, and 92.5% at these three states. The remaining gap is the
existing trailing outer inset transformed with content scale.

The Summary Pill tops remain 542.650, 482.500, and 422.350. Current material
bottoms stay above each by 12.123, 0.231, and 2.515. No Summary/control coordinate
was used as input to the physical policy.

Budget keeps its accepted lower chart transform. Because that authored card
allocation continues below the Summary position during collapse, earlier
physical clipping is necessary. At the three states, 12.33%, 22.03%, and 35.54%
of the lower chart allocation height lies below the corrected physical bottom.
That is a layout-allocation fraction, not the fraction of meaningful ink cut
off. Actual nonempty 60%/40% category-donut frames were rendered and inspected
at 35%, 50%, and 65%. A paint-only trailing fade resolves the initially observed
hard donut cutline: its extent is four existing Mother Card gaps multiplied by
master separation. The accepted lower transform and its own opacity remain
unchanged. At 50% and 65% the donut fades continuously before the physical edge;
there is no sharp horizontal colored slice. The expanded populated Budget
old/new PNGs are byte-identical (SHA-256
`3549a318bf696f6536d3d089ce2c984ec7f6f45074d5179f76388db0a4c930e1`).

The shared normalized top/bottom/width timing parity test passes at 0%, 1%, 5%,
10%, 20%, 35%, 50%, 65%, 80%, 95%, and 100%. This is separate from visual evidence.

The rich Balance 35%/50%/65% frames were also rendered and inspected: the chart
positions are retained while the material now ends close beneath the chart
allocation. The old/new expanded Balance PNGs are byte-identical (SHA-256
`f2108623b608e6a519bde1db35bc32dc3c698d8abad5417c71242547cd8df35b`).
The populated Mind year frame at 50% shows the heatmap itself moving under the
Header while the range control remains inside the moving lower viewport.

The final focused Month Balance 35%/50%/65% frames were rendered and inspected
after the independent upper adapter correction. At 35% the selector caption
has reached the Header contact edge while the lower chart heading remains
approximately 47 logical units lower. At 50% the selector/caption is behind
the Header while the chart heading remains visible. The earlier observed
caption/chart-heading overlap is absent in these final frames. The selector
uses the accepted lower content origin plus its own existing upper-cascade
displacement, with its own upper inset, scale and opacity; the lower chart
transform remains unchanged.
