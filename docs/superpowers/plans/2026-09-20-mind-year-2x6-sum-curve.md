# Implementation plan: Mind Year 2x6 and Sum curve presentation

1. Establish RED tests for the three-layout selector, 2x6 MonthCard content,
   card-only border/tint controls, and independent Sum curve settings.
2. Extend the existing presentation settings controller with revision-only
   MonthCard and Sum curve fields; add tuner controls.
3. Add the 2x6 MonthCard renderer and extract the Month-compatible day-number
   overlay for use in both Month and Year without changing 4x3.
4. Extract a shared Sum year-band header and add paint-only smoothing and
   interpolation rendering to the detailed chart.
5. Add focused visual regression evidence for the 2x6 composition, run
   targeted Flutter tests in Ubuntu proot, format/analyze/boundary checks, and
   re-check every checklist item before committing.

The work is deliberately inline: rendering, settings, and test boundaries are
tightly coupled and share the same presentation owner.
