# TwistLog V1.2 Phase 3 QA - History Insight

Use this checklist to verify the History insight chart.

Phase 3 goal: show simple opening patterns without implying medication was taken, missed, or clinically tracked.

## Scope

- Last 7 days chart at the top of History.
- Safe wording: `Daily openings`, `Last 7 days`, and opening record counts.
- Raw History list remains below the chart.

## Chart Visibility

- [ ] With no openings, History shows the empty state and no chart.
- [ ] After at least one opening, History shows the chart below the History header.
- [ ] Raw History rows still appear below the chart.
- [ ] History remains grouped by `Today`, `Yesterday`, and older date headers.

## Chart Content

- [ ] Chart title says `Daily openings`.
- [ ] Chart subtitle says `Last 7 days`.
- [ ] Summary says a count like `34 recorded`.
- [ ] Chart shows seven bars.
- [ ] X-axis labels show weekday abbreviations.
- [ ] Today's weekday label uses the orange accent.
- [ ] Days with zero openings still show a small neutral bar.
- [ ] Days with openings show orange bars.
- [ ] Bar count labels match the number of opening records for each day.
- [ ] Category chips appear below the chart.
- [ ] Category chips show Rx, Sup, H2O, and Oth counts.
- [ ] Category chips use category colors.
- [ ] Category chip counts match opening records from the last 7 days.

## Safe Wording

Confirm the chart and nearby History UI do not use:

- [ ] `taken`
- [ ] `missed`
- [ ] `adherence`
- [ ] `dose complete`
- [ ] `hydration complete`
- [ ] `water consumed`

Acceptable wording:

- `Daily openings`
- `Openings by day`
- `opening records`
- `recorded`

## Interaction / Regression

- [ ] Deleting an opening updates the chart count.
- [ ] Adding a new opening updates the chart count.
- [ ] Editing/deleting History rows still works.
- [ ] Category-colored History dots still appear correctly.
- [ ] Dark Mode chart remains readable.
- [ ] Larger Text chart remains usable.

## Sign-Off

- [ ] Simulator chart QA complete.
- [ ] Real iPhone chart QA complete.
- [ ] Safe wording check complete.
