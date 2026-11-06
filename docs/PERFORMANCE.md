# PULSE performance and device checklist

Targets come from PRD §7.3 and §11.3. Fill in one table per device. Measure frame timing with DevTools → Performance on a **profile** build (`flutter run --profile -d <device>`) and do the feel checks on a **release** build. Emulator results don't count as evidence of smoothness.

## Device

| Field | Value |
|---|---|
| Device / model | |
| OS version | |
| Refresh rate | 60 Hz / 90 Hz / 120 Hz |
| Build mode | profile / release |
| PULSE build (git SHA) | |
| Date / tester | |

## Frame timing (target: no sustained frames over 16.7 ms at 60 Hz)

| Interaction | Repeats | Worst frame (ms) | Visible jank? | Notes |
|---|---|---|---|---|
| Pipeline deal card → detail Hero, and back | ×5 | | | |
| Pipeline list fling, top to bottom | ×3 | | | |
| Overview period chips (7d → 30d → month → quarter) | ×5 | | | |
| Overview hero count-up on first entry | ×1 | | | |
| Booked vs target chart touch-and-hold scrub | ×3 | | | |
| Team ranking mode switch (rows reorder) | ×4 | | | |
| Workload legend → activities sheet open/scroll | ×3 | | | |
| Leads swipe → preview sheet | ×3 | | | |

## Reliability and accessibility

| Check | Pass / fail | Notes |
|---|---|---|
| Cold start in airplane mode; all four tabs load | | |
| Full demo script (docs/DEMO_SCRIPT.md) without a crash | | |
| `DEMO DATA` visible on every analytics screen | | |
| System font size at largest: no clipped or overlapping text | | |
| Reduce motion / Remove animations on: transitions snap, numbers show final value | | |
| Screen reader: charts and target rings read a text summary | | |
| Light theme (top-bar sun icon): text contrast acceptable | | |
| Back gesture works from every drill-down | | |
| Touch targets comfortable (chips, legend rows, nav) | | |

## Findings and fixes

| Finding | Cause | Fix | Re-measured |
|---|---|---|---|
| | | | |
