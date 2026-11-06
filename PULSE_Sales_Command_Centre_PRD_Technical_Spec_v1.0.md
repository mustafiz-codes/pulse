# PULSE: Sales Command Centre

## Product Requirements, Project Analysis & Technical Specification

**Document version:** 1.0  
**Date:** 3 November 2026  
**Product stage:** Executive-ready, offline-first demonstration / proof of concept  
**Platform:** Flutter mobile application (Android first, iOS compatible)  
**Primary data source for v1:** Bundled, synthetic **monday CRM-style** JSON  
**Data access:** Read-only; no live Monday connection or production backend  
**Working title:** PULSE (subject to branding/trademark checks before a public launch)

> **Product statement:** Turn CRM records into a beautiful mobile sales command centre that helps business leaders understand sales results, conversion speed, pipeline bottlenecks and the amount of salesperson time diverted into operational work.

> **Essential honesty rule:** The v1 app is a **demo using sample data**, not a real-time view of a company's CRM. A persistent, unobtrusive `DEMO DATA` label and data-as-of date are mandatory. Never present synthetic figures as actual performance.

---

# 1. Executive summary

PULSE is **not another general-purpose CRM**. It is a highly polished, mobile-first _sales intelligence and executive visibility_ product that sits conceptually above an existing CRM such as monday CRM.

The immediate build has two equally important goals:

1. **Commercial story:** Let a non-technical CEO or manager immediately see what is selling, how quickly leads become customers, where deals stall, and how much selling capacity the team loses to operational duties.
2. **Product execution:** Demonstrate senior-level Flutter engineering through outstanding visual design, smooth transitions, cohesive interaction patterns, accurate calculations, reliable loading states, and testable architecture.

The first version uses **locally bundled JSON** so the product can open offline and remain completely stable during a live presentation. The architecture isolates the local data provider so that an API/monday integration can replace it later without rewriting screens.

**North-star question:** _How can the company convert more opportunities into customers, faster, while giving salespeople more time to sell?_

## 1.1 Explicit end goal

Deliver an installable, executive-ready Flutter app with a realistic end-to-end sales story:

- Open PULSE and see a clear business health overview.
- Drill into conversion speed and see which stage takes too long.
- Open a specific deal and understand its lead-to-win timeline.
- See whether the responsible salesperson also spends significant time on onboarding, support or administration.
- Compare team results fairly, considering lead volume, conversion, sales cycle and operational workload.
- End with a specific, evidence-based management question, not just a decorative chart.

The demo should feel **premium, effortless and credible**, even though the underlying data is synthetic.

## 1.2 What success is **not**

- A full Monday CRM clone.
- A CRUD-heavy application full of forms.
- An attractive dashboard whose cards contain unrelated hard-coded numbers.
- Fake 'live' updates, misleading AI insights or invented forecasts.
- A motion-heavy app that stutters or obstructs real information.

---

# 2. Project analysis and rationale

## 2.1 Problem

Traditional CRMs are strong at recording activities and managing pipelines. For executives, however, the information they need may be dispersed across boards, filters and reports. Typical dashboards answer **how much** but not necessarily **why**, **how long**, or **at what sales-capacity cost**.

Business leaders want to understand:

- Whether revenue and pipeline are progressing against goals.
- Whether lead response and conversion are getting faster or slower.
- Which stages or owners have stalled opportunities.
- Whether salespeople are performing revenue-generating work or taking on operational responsibilities.
- Whether a team ranking reflects performance or unequal opportunity allocation.

## 2.2 Proposed solution

A fast, beautifully designed _read-only intelligence layer_ for decision-makers and sales teams. PULSE calculates transparent metrics over a shared data model, visualises them with purpose-built mobile interactions, and makes it easy to move from a number to the underlying deals and activities.

## 2.3 Strategic differentiators

1. **Time-to-conversion intelligence**: not just deal stage, but lead-to-first-contact, stage dwell, sales cycle and stage bottlenecks.
2. **Sales vs Operations workload visibility**: quantifies the share of _logged activity time_ spent selling versus onboarding, support and administration.
3. **Decision-oriented drill-down**: summary metric → filtered list → underlying detail → recommended question/action.
4. **Premium mobile execution**: deliberate micro-interactions, tactile feel, attractive charts and fluid navigation.
5. **Low-risk demo delivery**: works offline; no credentials or dependency on network, external service availability or live company records.

## 2.4 Target users

| Persona              | Main decision                                               | Primary screens                            |
| -------------------- | ----------------------------------------------------------- | ------------------------------------------ |
| CEO / founder        | Is the sales engine healthy and what is restricting growth? | Overview, Conversion, Workload, Team       |
| Head of sales        | Which stage or salesperson needs attention?                 | Pipeline, Leads, Team, Deal Detail         |
| Sales manager        | Which leads and deals are stuck or underworked?             | Leads, Pipeline, Deal Detail               |
| Sales representative | What is my current pipeline and where is my time going?     | Leads, Pipeline, My Performance / Workload |

**v1 role model:** A presentation-only _View as CEO / Manager / Rep_ filter is optional. There is no genuine authorisation or private-user identity in an offline sample-data app. All included demo records remain visible in the app package.

---

# 3. Scope and product decisions

## 3.1 In scope for v1

- Single Flutter mobile application; Android release build first, iOS-compatible code.
- Original visual design system, dark-first with an equally readable light theme if polish budget allows.
- Six primary experiences: Overview, Leads, Pipeline, Deal Detail & Journey, Workload, Team Performance.
- Navigation and drill-down routes between these experiences.
- Shared filters: reporting period, owner/team, lead source and pipeline stage where applicable.
- Analytics calculated from a coherent, synthetic, locally bundled data model.
- Smooth animations, haptic feedback, skeleton loading, empty/error states and reduced-motion support.
- Simple deterministic 'insights' grounded in the bundled data.
- Repeatable showcase mode with a controlled dataset date and resettable filter state.
- Unit, widget and integration tests, performance profiling and packaged demo installation.

## 3.2 Explicitly out of scope for v1

- Live monday.com API calls, webhooks, OAuth or server infrastructure.
- Production customer records, employee personal data or real commercial financial information.
- Editing leads, creating deals, sending emails, logging calls, updating CRM stages or writing back to Monday.
- Push notifications or background refresh.
- User sign-up, payments, permissions or production authentication.
- Native call recording, geolocation tracking, employee surveillance or automated productivity scoring.
- AI-generated performance explanations; deterministic indicators only.
- Financial accounting, invoicing, cash collection and recognition of realised revenue.

## 3.3 Future scope, not prerequisites

- Read-only Monday integration through a secure backend adapter.
- A managed periodic sync, historical event storage, explicit data-quality indicators and permission enforcement.
- Optional real CRM activity logging and write-back workflows.
- Organisation-specific KPI configuration, targets and data governance.
- Multi-tenant deployment and role-based access, only if commercially justified.

---

# 4. Information architecture and navigation

Keep the bottom navigation to **four items**, despite six feature screens:

1. **Overview** — executive health and insight entry points.
2. **Leads** — lead discovery and conversion readiness.
3. **Pipeline** — deals by stage.
4. **Team** — results, rankings and individual profiles.

**Contextual secondary routes:**

- `Overview → Conversion Analytics → Deal Journey`
- `Overview → Workload Analytics → Rep Activity Breakdown`
- `Leads → Lead Detail → Linked Deal Detail`
- `Pipeline → Deal Detail → Activity Timeline`
- `Team → Rep Detail → Deals / Workload`

Each major route has a stable back path, preserves relevant filters, and supports deep linking internally. Do not add a fifth bottom tab just to expose every report.

## 4.1 Screen O1 — Executive Overview

**Audience:** CEO, management.  
**Business objective:** Understand performance and find the next issue to investigate within 10 seconds.

**Hierarchy, top to bottom:**

1. Branded app bar, greeting and subtle `DEMO DATA` indicator.
2. Reporting period selector: 7 days / 30 days / Quarter / Custom demo range.
3. Primary hero metric: **Booked sales value (Won deals)**, explicitly not recognised accounting revenue.
4. Supporting KPIs: win rate, median lead-to-win time, open pipeline value, target attainment.
5. Revenue/won-value time series or weekly bar chart.
6. Conversion bottleneck card: e.g., `Proposal stage median: 9.2 days`.
7. Sales vs Operations card: segmented share of logged activity minutes.
8. `Needs attention` list: stalled stages, overdue follow-ups, uncontacted leads (only where fields allow).

**Interactions:** Animated numbers on first entry, period chips with coordinated chart transition, tap KPI → filtered list/secondary view, touch-and-hold chart scrubbing, pull-to-reset simulated loading (not network refresh).

**Acceptance:** Every number derives from the same filtered records and recalculates consistently when the reporting period changes. All metrics have definition tooltips or detail labels.

## 4.2 Screen L1 — Leads & Lead Intelligence

**Business objective:** Spot new leads, slow response and opportunities with weak follow-up.

**Components:** Search, source/status/owner filters, total lead count, `Not yet contacted` section, lead cards, age since creation, first response time, related deal indicator, next activity.

**Lead detail:** Contact/company summary, source, owner, creation date, first-contact date, timeline of recorded interactions, linked deal if created, stage/state.

**Interactions:** Filter chip transitions, expanding preview cards, smooth list reordering, swipe for read-only quick preview. **Do not make swipe actions appear to call or modify a contact unless the feature actually works.**

**Acceptance:** Lead ages use the fixed demo as-of date; conversion/lead ownership joins are correct; missing response timestamps show `Not recorded` rather than a fabricated duration.

## 4.3 Screen P1 — Sales Pipeline

**Business objective:** Understand stage distribution, value, deal age and deal velocity.

**Components:** Stage selector (New, Qualified, Discovery, Proposal, Negotiation, Won, Lost; configurable), stage counts/values, horizontal stage progress, cards with deal amount, company, owner, age in current stage, last activity.

**Design decision:** A vertical card list with a horizontally selectable stage rail is more usable on a phone than squeezing a desktop Kanban across a small screen. A polished horizontally paged stage view may be offered; it must not sacrifice readability.

**Interactions:** Spring-based stage-page transitions; deal cards expand with a shared-element animation into Deal Detail; changing filters recomputes counts and chart states.

**Read-only rule:** Do not implement actual drag-to-update stages in v1. If a drag interaction is included purely for showcase purposes, label it `Simulation`, keep changes in memory only, show a reset control, and ensure no other KPI incorrectly implies a persisted edit. Default is no drag-stage edit at all.

## 4.4 Screen D1 — Deal Detail & Conversion Journey

**Business objective:** Explain the complete path from lead to customer.

**Header:** Company, deal value, stage, owner, original lead source, created date, won/lost status.  
**Core visual:** Animated timeline of deal stage events, with elapsed time between changes.  
**Secondary sections:** Lead received, first contact, opportunity created, meetings, proposal, negotiation, latest activity, days in stage, important delays.

**Key calculations:** Time from lead creation to first contact; lead creation to won; deal creation to won; each stage's dwell time; elapsed days since last meaningful activity. Distinguish clearly between the different starting points.

**Interactions:** Card-to-detail Hero transition, section expansion, animated timeline fill, stage detail bottom sheet, drill-through to related lead and owner.

**Acceptance:** Timeline ordering is chronological and durations total correctly; won date must be at or after the start point; missing historical events are disclosed as `Stage history unavailable`.

## 4.5 Screen W1 — Sales vs Operations Workload

**Business objective:** Reveal how team capacity is allocated without wrongly equating time logged in CRM with total working hours.

**Components:** Segmented bar/donut, category breakouts, trend over period, rep comparison, deals/activities connected to each category, tracked minutes, missing-duration count and data completeness statement.

**Suggested categories:**

| High-level category | Examples                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------- |
| Sales               | Prospecting, outbound calls, discovery, demos, quotations/proposals, negotiation            |
| Operations          | Customer onboarding, implementation handoff, setup work, support, administrative processing |
| Other               | Internal meetings, training or unclassified recorded work                                   |

**Primary wording:** `Share of logged activity time` rather than `Share of working hours` unless verified schedules and sufficiently complete time records exist.

**Interactions:** Animated category transitions, touch-to-select segment, drill-through to the underlying activities, period and owner selection.

**Acceptance:** All shares sum to 100% of classified logged minutes; unknown-duration records do not count as zero minutes silently; missing time data produces an explicit `Insufficient logged time` state.

## 4.6 Screen T1 — Team Performance

**Business objective:** Compare outcomes with context rather than reward raw revenue alone.

**Components:** Target attainment rings, booked sales, won deals, qualified pipeline, win rate, median sales cycle, lead allocation, logged sales/operations time; rep profile and contribution charts.

**Ranking modes:** Booked sales / target attainment / win rate / median sales cycle; clear denominators and minimum-sample safeguards. These are descriptive views, **not an opaque composite productivity score**.

**Interactions:** Animated progress rings, smooth reorder on ranking-mode selection, tap person → profile, rep comparison.

**Acceptance:** Never rank somebody with one won deal as conclusively 'best at converting' without showing the sample size. Avoid identifying personal underperformance based solely on operational workload.

---

# 5. Data architecture: local Monday-style JSON

## 5.1 Two distinct data concepts

**Raw Monday format** is a vendor-specific GraphQL/board representation using boards, items and configurable column values. Those columns differ by organisation.  
**PULSE canonical JSON** is our own stable, typed, analytical schema with entities such as `leads`, `deals`, `deal_stage_events` and `activities`.

**Decision:** Build v1 against **PULSE canonical JSON**, not guessed raw Monday API response shapes. Later, create a `MondayMapper` that transforms the organisation's real boards/columns into this canonical structure.

This avoids coupling the Flutter UI to arbitrary Monday column IDs, while preserving a realistic route to genuine integration.

## 5.2 Asset structure

```text
assets/
  data/
    demo/
      manifest.json
      users.json
      accounts.json
      leads.json
      deals.json
      deal_stage_events.json
      activities.json
      targets.json
      insight_scenarios.json
  images/
    avatars/
  branding/
```

The application bundles these assets; the Flutter `rootBundle` reads the JSON at runtime. A build is required to replace bundled assets. There is no promise of live refresh.

## 5.3 Canonical data entities

### `manifest.json`

- `schema_version`: application data contract version (e.g., `1.0.0`).
- `dataset_id`: unique demo fixture identifier.
- `dataset_label`: e.g., `PULSE Executive Demo`.
- `data_kind`: always `synthetic` in v1.
- `currency`: ISO 4217 code, initially `GBP`.
- `timezone`: e.g., `Europe/London`.
- `as_of`: fixed ISO 8601 instant used for all age/time comparisons.
- `period_start`, `period_end`: start-inclusive / end-exclusive demo reporting boundaries.
- `source_description`: `Generated CRM-style sample dataset; not connected to monday.com`.

### `users.json`

`id`, `display_name`, `job_role`, `team_id`, `avatar_asset` (optional), `active`.

### `accounts.json`

`id`, `name`, `industry` (optional), `size_band` (optional). All company names fictitious.

### `leads.json`

`id`, `account_id`, `owner_id`, `source`, `status`, `created_at`, `first_contacted_at` (nullable), `converted_deal_id` (nullable), `next_follow_up_at` (nullable), `lost_reason` (nullable).

### `deals.json`

`id`, `lead_id` (nullable), `account_id`, `owner_id`, `title`, `value_minor`, `currency`, `stage`, `created_at`, `closed_at` (nullable), `outcome` (`open`, `won`, `lost`), `probability` (nullable), `last_activity_at` (nullable).

Use integer minor currency units (`value_minor`, e.g., 1250000 for £12,500.00) instead of floating-point amounts for money.

### `deal_stage_events.json`

`id`, `deal_id`, `occurred_at`, `from_stage` (nullable), `to_stage`, `source` (e.g., `synthetic_fixture`). Events must be chronologically ordered within a deal; can be sorted while loading.

### `activities.json`

`id`, `owner_id`, `lead_id` (nullable), `deal_id` (nullable), `account_id` (nullable), `type`, `work_category` (`sales`, `operations`, `other`, `unknown`), `work_subcategory`, `started_at`, `duration_minutes` (nullable), `summary` (optional), `source`, `time_quality` (`logged`, `estimated`, `not_recorded`).

**Important:** Only valid, positively logged or explicitly labelled estimated durations can support time-share charts. Keep logged and estimated amounts separate or show a clearly identified estimated-data mode. Prefer logged-only for the headline.

### `targets.json`

`owner_id`, `period_month` (YYYY-MM), `currency`, `won_value_target_minor`, optional `team_id`.

### `insight_scenarios.json`

Optional **deterministic** demo narratives with references to actual filtered metrics and record IDs, not fabricated analytics conclusions. Prefer generating insight messages from rules; hard-code only the guided presentation sequence.

## 5.4 Example canonical JSON

The following excerpt illustrates structure only; an actual app uses full arrays or per-entity files.

```json
{
  "manifest": {
    "schema_version": "1.0.0",
    "dataset_id": "pulse-demo-v1",
    "data_kind": "synthetic",
    "currency": "GBP",
    "timezone": "Europe/London",
    "as_of": "2026-10-31T23:59:59Z"
  },
  "users": [
    {
      "id": "rep_01",
      "display_name": "Alex Morgan",
      "job_role": "sales_rep",
      "team_id": "sales",
      "active": true
    }
  ],
  "accounts": [{ "id": "acc_01", "name": "Acme Retail", "industry": "Retail" }],
  "leads": [
    {
      "id": "lead_01",
      "account_id": "acc_01",
      "owner_id": "rep_01",
      "source": "referral",
      "status": "converted",
      "created_at": "2026-10-01T09:00:00Z",
      "first_contacted_at": "2026-10-02T10:00:00Z",
      "converted_deal_id": "deal_01",
      "next_follow_up_at": null,
      "lost_reason": null
    }
  ],
  "deals": [
    {
      "id": "deal_01",
      "lead_id": "lead_01",
      "account_id": "acc_01",
      "owner_id": "rep_01",
      "title": "Acme Retail rollout",
      "value_minor": 1250000,
      "currency": "GBP",
      "stage": "won",
      "created_at": "2026-10-03T09:00:00Z",
      "closed_at": "2026-10-23T16:00:00Z",
      "outcome": "won",
      "probability": 1.0,
      "last_activity_at": "2026-10-24T09:00:00Z"
    }
  ],
  "deal_stage_events": [
    {
      "id": "ev_01",
      "deal_id": "deal_01",
      "occurred_at": "2026-10-03T09:00:00Z",
      "from_stage": null,
      "to_stage": "qualified",
      "source": "synthetic_fixture"
    },
    {
      "id": "ev_02",
      "deal_id": "deal_01",
      "occurred_at": "2026-10-10T11:00:00Z",
      "from_stage": "qualified",
      "to_stage": "proposal",
      "source": "synthetic_fixture"
    },
    {
      "id": "ev_03",
      "deal_id": "deal_01",
      "occurred_at": "2026-10-20T09:00:00Z",
      "from_stage": "proposal",
      "to_stage": "negotiation",
      "source": "synthetic_fixture"
    },
    {
      "id": "ev_04",
      "deal_id": "deal_01",
      "occurred_at": "2026-10-23T16:00:00Z",
      "from_stage": "negotiation",
      "to_stage": "won",
      "source": "synthetic_fixture"
    }
  ],
  "activities": [
    {
      "id": "act_01",
      "owner_id": "rep_01",
      "lead_id": "lead_01",
      "deal_id": "deal_01",
      "account_id": "acc_01",
      "type": "demo",
      "work_category": "sales",
      "work_subcategory": "discovery",
      "started_at": "2026-10-08T13:00:00Z",
      "duration_minutes": 45,
      "summary": "Product walkthrough",
      "source": "synthetic_fixture",
      "time_quality": "logged"
    },
    {
      "id": "act_02",
      "owner_id": "rep_01",
      "lead_id": "lead_01",
      "deal_id": "deal_01",
      "account_id": "acc_01",
      "type": "onboarding",
      "work_category": "operations",
      "work_subcategory": "customer_setup",
      "started_at": "2026-10-24T09:00:00Z",
      "duration_minutes": 120,
      "summary": "Post-sale setup",
      "source": "synthetic_fixture",
      "time_quality": "logged"
    }
  ],
  "targets": [
    {
      "owner_id": "rep_01",
      "period_month": "2026-10",
      "currency": "GBP",
      "won_value_target_minor": 2000000
    }
  ]
}
```

## 5.5 Seed data requirements

Generate **coherent, representative histories**, not random disconnected counters:

- 6–10 fictional salespeople and 2–3 teams, if team-level comparison is desired.
- A full 6–12 month history for meaningful month-over-month and period comparisons.
- Hundreds of leads, a realistic proportion linked to deals, and a mix of open/won/lost outcomes.
- Deal values distributed realistically; show a few large outliers so median vs mean matters.
- Event sequences for each deal: plausible stage progression, delays, missing transitions in a small controlled subset.
- Activity records both before and after deal closure; classify sales, operational and other work.
- Some explicitly missing duration records to exercise the `Insufficient data` and completeness UI.
- Stable random seed for reproducible fixtures; IDs and timestamps consistent across files.
- Target values such that some reps exceed targets and others do not.
- Narrative pattern: conversion is slower at proposal for certain cohorts, and some high-volume reps have significant operational involvement. This is a _designed demonstration scenario_, not a real-world claim.
- Negative/edge cases: zero value deals, absent first-contact timestamp, no won deals for a rep, long-open deals, transferred ownership, re-entered stages, same-day conversions, and no operational logs.

**Never embed real customer names, email addresses, staff identifiers or private Monday exports in a distributable demo build without explicit permission and appropriate sanitisation.**

## 5.6 Dataset validation gates

The pre-build validation script must reject:

- Invalid JSON / schema version or unrecognised enum values.
- Duplicate IDs or broken references between entities.
- Closed timestamp before deal or lead creation.
- First-contact timestamp before lead creation.
- Negative values, negative durations, invalid currency codes or inconsistent currencies.
- Stage event timestamps out of order after normalisation, impossible stage outcome combinations, or missing mandatory events for calculated stage dwell metrics.
- Activities after the manifest's `as_of` instant unless intentionally handled as scheduled future activities.
- Won deals without a consistent closed timestamp.
- Unclassifiable owner/team references for rankings.

Provide warnings, not crashes, for intentionally incomplete optional fields and for insufficient KPI denominators.

---

# 6. Analytics and precise KPI definitions

Metrics must be **derived in Dart from raw records**, not individually hard-coded into widgets. All aggregations share a reporting filter model.

## 6.1 Reporting period and cohort rules

- `as_of` is fixed by the dataset, independent of the demo device's wall clock.
- Default reporting window: the final complete demo month or a preselected 30-day window.
- Intervals use `[start, end)` in a designated timezone, converted to UTC for comparisons.
- A metric's tooltip specifies whether it is based on **created**, **closed**, **currently open**, or **logged within period** records.
- Comparison periods must be of matching duration and compatible timezone boundaries.
- Never mix lead-created cohorts with deal-closed cohorts and present the result as one stable conversion rate.

## 6.2 Sales metrics

| Metric                      | Definition                                                                                  | Important notes                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Booked sales value          | Sum `value_minor` for `outcome=won`, `closed_at` in period                                  | Commercial won-deal value, **not realised or recognised revenue**                                 |
| Won deals                   | Count of won deals closed in period                                                         | Include sample size                                                                               |
| Open pipeline               | Sum value of open deals as of dataset snapshot                                              | Not a forecast or booked revenue                                                                  |
| Weighted pipeline           | Sum open deal value × validated stage probability                                           | Optional; label as estimate and define probabilities                                              |
| Target attainment           | Won deal value in target period ÷ targets for same period × 100                             | Missing targets ⇒ unavailable, not 0%                                                             |
| Win rate (closed-cohort)    | Won deals ÷ (won + lost deals) among deals closed during period                             | Not lead conversion rate                                                                          |
| Lead-to-opportunity         | Leads created in cohort that became an opportunity ÷ eligible leads created in cohort       | Define cohort maturity; open/new leads may still convert                                          |
| Lead-to-customer conversion | Leads created in cohort with a linked won deal by cutoff ÷ eligible leads created in cohort | Explicit cutoff; recent cohorts are not directly comparable without maturity treatment            |
| First response time         | `first_contacted_at - lead.created_at` for contacted leads                                  | Show median and uncontacted count                                                                 |
| Median lead-to-win time     | Median(`deal.closed_at - lead.created_at`) for linked won deals                             | Exclude missing original lead or report separate coverage                                         |
| Median deal cycle           | Median(`deal.closed_at - deal.created_at`) among won deals                                  | Distinct from lead-to-win                                                                         |
| Stage dwell                 | Duration from stage entry event until next change; for open deal until `as_of`              | Account for repeated stage visits; exclude terminal Won/Lost stage duration; report data coverage |
| Stalled deal                | Open deal with stage age above configurable threshold or overdue next activity              | Rule-driven flag, **not proof of risk**                                                           |
| Sales activity time         | Sum valid logged minutes with `work_category=sales`                                         | Recorded work, not inferred work                                                                  |
| Operations activity time    | Sum valid logged minutes with `work_category=operations`                                    | Includes support/onboarding where logged                                                          |
| Operations share            | Ops logged minutes ÷ all valid logged category minutes × 100                                | Display `share of logged time`; show data coverage                                                |
| Data completeness           | Count of valid-duration activity records ÷ eligible activity records                        | Not coverage of total employee working hours                                                      |

## 6.3 Reporting safeguards

- Show `Not available` rather than calculating 0% from a zero denominator.
- Treat missing duration as unknown, not automatically zero.
- Use weighted calculations for combined team rates; do not average individual percentages to get company percentages.
- Prefer median for sales cycle and stage dwell; optionally show mean and sample size in detail.
- Show an `n` sample count for conversion and ranking metrics.
- For late-stage / open cohorts, show a provisional label or use a maturation window for fair comparisons.
- If deal ownership changes, describe the attribution policy. V1 default: attribute closed deal to owner at close **if historic ownership is present**; otherwise label as current-owner attribution and avoid false historical statements.
- Currency conversion is out of scope; use GBP-only synthetic fixture in v1.
- Targets and won values must use the same time interval and timezone.
- Total category shares should reconcile to ~100% subject only to display rounding.

## 6.4 Deterministic insights (no AI dependency)

Examples of simple, testable rules:

- `Proposal is the slowest stage`: based on the highest median dwell among stages above the sample-size threshold.
- `First-response time increased`: based on matched reporting windows and minimum eligible records.
- `Operational work accounts for 30% of logged activity`: based on valid logged durations.
- `X open deals have been in their current stage more than 14 days`: based on snapshot date and configured threshold.
- `Team conversion changed by N percentage points`: compare like-for-like eligible cohorts.

Each insight links to the records and metric definition behind it. Suppress the insight when data is missing or unreliable. Use precise language: `may be worth reviewing`, not causal claims like `operations caused the fall in sales`.

---

# 7. Interaction, motion and UI design specification

## 7.1 Brand direction

**Look:** Premium dark-first executive tool with calm fintech-level polish; confident but not flashy.  
**Palette:**

- Primary dark background: `#0B1020`
- Elevated surfaces/cards: `#182235`
- Primary accent: `#B9F576` (lime)
- Secondary chart accent: `#8ABEFF` (sky blue)
- Text: near-white on dark surfaces; appropriate neutral greys for supporting labels
- Amber for caution, red for truly critical status, green for positive status, never colour alone for meaning

**Typography:** Inter or Manrope (subject to licence and availability). Use tabular numerals for counters and currency.  
**Shape:** Cards generally 16–24 px radius; chips/bottom sheets consistently styled.  
**Spacing:** 4/8-point rhythm with generous white space and restrained shadows/borders.

## 7.2 Motion language

| Interaction      | Proposed behaviour                            | Notes                                                            |
| ---------------- | --------------------------------------------- | ---------------------------------------------------------------- |
| App entrance     | Subtle staggered card reveal                  | Avoid replaying excessively on every revisit                     |
| Hero amount      | Animated count-up                             | Respect accessibility; final value instantly obtainable          |
| Period switching | Coordinated chart shape/crossfade             | No inconsistent momentary totals                                 |
| Progress ring    | Smooth sweep to calculated target %           | Avoid animation beyond 100% without intentional visual treatment |
| Deal open        | Hero / shared-element card-to-detail          | Works with back gesture; stable IDs                              |
| Stage page       | Spring or smoothly eased transition           | No stage edit implied                                            |
| List changes     | Animated inserts/reorders                     | Preserve scroll position where sensible                          |
| Timeline         | Progressive milestone reveal                  | Chronology always clear in static state                          |
| Data breakdown   | Tap chart segment → highlighted legend/detail | Accessible non-gesture alternative                               |
| Haptics          | Light confirmation for meaningful selection   | Respect system/user accessibility preference                     |

**Motion rules:**

- Use short movement for routine navigation, longer transitions only for selected signature moments.
- Avoid simultaneous unrelated bounces, perpetual animation or distracting celebration effects.
- Visual clarity and accessibility take priority over animation complexity.
- Support reduced motion by shortening/removing non-essential transforms.

## 7.3 Performance targets

- **60 FPS target** for common interactions on a defined mid-range Android test device; higher refresh-rate devices should be profiled separately.
- For 60 Hz, aim for frame execution within ~16.7 ms; investigate sustained frame overrun and visible jank in Flutter DevTools **profile mode**.
- No dropped-content impression during list scroll, chart scrubbing, large pipeline transitions or Hero navigation.
- No network-dependent loading in v1. Parse assets once and cache typed records in repositories.
- Use lazy lists, memoised derived metrics, careful rebuild boundaries, and avoid expensive calculation inside `build()`.
- Precache relevant avatar/graphic assets; use vector and Flutter drawing where appropriate.
- Test a release build on physical Android hardware; an emulator alone is insufficient evidence of smoothness.

**Quality measures:** 0 crashes in scripted demo, deterministic metrics, legible on small devices, accessible labels for all charts, no clipped content in large text settings, usable in dark and light conditions.

---

# 8. Flutter technical architecture

## 8.1 Technology choices

| Concern               | Choice                                                                                                                         | Reason                                                                |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| App framework         | Flutter (stable channel), Dart                                                                                                 | Single shared Android/iOS codebase and rich custom rendering          |
| State management / DI | Riverpod                                                                                                                       | Typed, testable state and dependency injection                        |
| Navigation            | go_router                                                                                                                      | Consistent declarative routes and deep-link-ready structure           |
| Models / parsing      | json_serializable with immutable models (Freezed optional)                                                                     | Predictable schema and less manual mapping                            |
| Local source          | Flutter asset bundle + `jsonDecode`                                                                                            | Fully offline and deterministic                                       |
| Charts                | fl_chart for standard charts; `CustomPainter` where a custom design materially adds value                                      | Avoid unnecessary custom chart engineering                            |
| Animation             | Flutter implicit/explicit APIs, `Hero`, `AnimatedSwitcher`, `TweenAnimationBuilder`; Rive only for a justified signature asset | Smooth native-feeling interaction without excessive dependency weight |
| Formatting            | intl                                                                                                                           | Currency, dates, locales                                              |
| Logging / diagnostics | Flutter logging + non-sensitive structured debug flags                                                                         | Trace JSON parsing and KPI computations                               |
| Testing               | flutter_test, integration_test, unit tests, golden tests                                                                       | Prevent UI and analytics regressions                                  |
| Static analysis       | flutter_lints / project lint rules                                                                                             | Consistent code quality                                               |

Pin compatible versions during bootstrap and check current plugin support; do not pin arbitrary versions from an old specification.

## 8.2 Dependency boundaries

```text
Flutter Widgets (views)
       │
       ▼
Screen Controllers / ViewModels (Riverpod)
       │
       ▼
Analytics Services / Pure KPI Calculators
       │
       ▼
Repositories (LeadRepository, DealRepository, ActivityRepository, etc.)
       │
       ▼
Data Source Interface (SalesDataSource)
       │
       ├── AssetJsonDataSource       ← v1
       │
       └── MondayApiDataSource       ← future, via secure integration service
```

**Rules:**

- Widgets never parse raw JSON or implement KPI formulas.
- Analytics methods are pure, time-bound and fully unit-testable.
- All screens consume the same typed repository state.
- `SalesDataSource` abstraction is used from the start; do not build an elaborate plugin framework for a single demo.
- No secrets in the Flutter bundle; no Monday tokens in the repo.
- Use one shared `ReportingFilter` object, with selected period/team/owner that screens can override contextually.

## 8.3 Suggested folder structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
      app_colors.dart
      app_theme.dart
      app_typography.dart
      app_motion.dart
    widgets/
      pulse_card.dart
      metric_tile.dart
      section_header.dart
      empty_state.dart
      demo_data_banner.dart
  core/
    models/
      dataset_manifest.dart
      sales_user.dart
      account.dart
      lead.dart
      deal.dart
      deal_stage_event.dart
      sales_activity.dart
      sales_target.dart
    data/
      sales_data_source.dart
      asset_json_data_source.dart
      data_validation.dart
      repositories/
        lead_repository.dart
        deal_repository.dart
        activity_repository.dart
        team_repository.dart
    analytics/
      reporting_filter.dart
      sales_metrics.dart
      conversion_metrics.dart
      workload_metrics.dart
      insight_rules.dart
    utils/
      currency_format.dart
      date_format.dart
  features/
    overview/
      overview_screen.dart
      overview_controller.dart
      widgets/
    leads/
      leads_screen.dart
      lead_detail_screen.dart
      leads_controller.dart
      widgets/
    pipeline/
      pipeline_screen.dart
      pipeline_controller.dart
      widgets/
    deals/
      deal_detail_screen.dart
      deal_controller.dart
      widgets/
    conversion/
      conversion_screen.dart
      conversion_controller.dart
      widgets/
    workload/
      workload_screen.dart
      workload_controller.dart
      widgets/
    team/
      team_screen.dart
      rep_detail_screen.dart
      team_controller.dart
      widgets/
assets/data/demo/...
test/
  data/
  analytics/
  features/
  goldens/
integration_test/
  executive_demo_flow_test.dart
tool/
  generate_demo_dataset.dart   # optional, deterministic
  validate_demo_dataset.dart
```

## 8.4 App lifecycle and failure states

1. Show branded splash and minimal loading indication.
2. Read manifest, verify `schema_version`, load asset data asynchronously.
3. Validate entities and generate indexes keyed by ID.
4. Compute default dashboard metrics from typed models.
5. Present overview; no fake delayed loading necessary, but transitions can play after data readiness.
6. If malformed data prevents safe display, show a proper error state with `Retry` and clear diagnostics in development; never silently substitute fake numbers.
7. Filter changes update shared state, recompute memoised derived data and animate result transitions.

## 8.5 Optional showcase scenario mechanism

Add a **presentation mode** selectable via an unobtrusive menu:

- `Executive Overview`
- `Conversion Bottleneck`
- `Operational Workload`
- `Team Comparison`

This changes navigation and filter context only; all displayed figures still come from the canonical fixture. Presenters can also tap `Reset demo` to restore initial state. Avoid modifying the data itself or showing `Saved to CRM` feedback.

---

# 9. Future Monday CRM migration path

The point of this section is **readiness**, not immediate implementation.

## 9.1 Real-world mapping steps

1. Inspect the organisation's actual Monday boards and columns for leads, contacts, deals, owners, amounts, stage and targets.
2. Document each real board ID and column ID in a **backend-side mapping config**, not hard-coded in the Flutter UI.
3. Identify sources for stage-change history, time tracking, first response and work categories; do not assume they exist or are complete.
4. Build a secure backend adapter that queries the official monday GraphQL API, manages pagination, rate limits and authorisation.
5. Normalise results to the PULSE canonical models.
6. Store and reconcile historical changes needed for dependable dwell/conversion analytics; introduce webhooks or scheduled sync as appropriate.
7. Add access controls/role scoping and source freshness badges (`last_synced_at`).
8. Replace `AssetJsonDataSource` with the remote source behind the same repositories.

## 9.2 What Monday can and cannot be assumed to provide

The official Monday API supports boards, items, columns and related objects. The exact column IDs and meaning are **account-specific**. Monday documents board activity logs and time-tracking data, but their presence, retention, access rights and suitability for our metrics must be checked against the real configuration.

A standard board export is usually **Excel**, not automatically our desired analytical JSON. Converting a Monday export to PULSE format is a mapping task; historical stage transitions and time-spent categories may require separate sources or instrumentation. API integration is a later phase, not something v1 secretly depends on.

## 9.3 Security for real data

- Never ship a permanent Monday API token in a mobile app.
- Use a server-side integration service / OAuth as appropriate.
- Do not expose all company opportunities to every salesperson.
- Define record retention, data minimisation, audit trails and permitted roles.
- Respect organisation permission settings and applicable privacy obligations.
- Sanitise exports before using them for stakeholder demo builds.

---

# 10. Work plan and milestones (ordered, without calendar promises)

## Milestone A — Contract and demo dataset

- Confirm exact KPI glossary and stage names.
- Freeze v1 data schema, dataset date and display currency.
- Generate realistic, reproducible synthetic records with a deliberate management story.
- Add schema/reference validation and metric unit tests.
- Produce a sample-data manifest and source disclaimers.

**Exit gate:** Every required metric can be computed from the fixture, with no unrelated hard-coded dashboard totals.

## Milestone B — Visual foundation

- Establish brand tokens, typography, themes, components and navigation.
- Implement four-tab shell, card styles, chart styles, motion tokens and responsive spacing.
- Build UI reference screens and ensure all states are legible.

**Exit gate:** Design system is consistent, with an exceptional Overview screen and navigation that works on a small Android phone.

## Milestone C — Core sales journey

- Implement Overview, Leads, Pipeline and Deal Detail/Journey.
- Wire shared filters and sample-data calculations.
- Polish transitions and source-of-metric drill-down.

**Exit gate:** From KPI → stage → deal → timeline, all displayed values and relationships remain coherent.

## Milestone D — Differentiation

- Implement Workload Analytics, Team Performance and insight rules.
- Add actual data-quality/coverage labels for workload and low-sample rankings.
- Refine graphs, interactions, loading/empty/error states and accessibility.

**Exit gate:** CEO can explain conversion delays and operational workload from the app without a technical walkthrough.

## Milestone E — Quality and presentation

- Run unit, widget, golden and integration tests.
- Profile on physical mid-range Android device, fix jank and layout issues.
- Verify app works entirely offline / airplane mode.
- Package an Android installable demo build; iOS build only when a signing environment is available.
- Deliver a guided 3–5 minute demo path, a one-page KPI glossary and screenshots/video if desired.

**Exit gate:** Demo runs without a network, no deceptive claims, correct totals, smooth movement, clear presentation.

## Prioritisation

**P0 / cannot cut:** Accurate data contract, Overview, Leads/Pipeline, Deal Journey, Workload, correct metric labels, offline reliability.  
**P1 / high value:** Team comparison, polished charts, Hero navigation, reduced-motion handling, automated tests.  
**P2 / optional polish:** Light theme, showcase mode, custom Rive asset, additional chart types, advanced cohort breakdowns.  
**Not for v1:** Production authentication, live Monday connection, CRM editing, messaging, AI and background sync.

---

# 11. Testing and acceptance criteria

## 11.1 Functional

- [ ] App installs and starts in airplane mode.
- [ ] Every required screen loads from the bundled JSON and never attempts a network request.
- [ ] One consistent dataset timestamp controls all relative durations.
- [ ] Changing time range/owner updates charts, counters, lists and insights coherently.
- [ ] All metric cards provide an understandable definition/label.
- [ ] Deal value and stage history agree with deal detail and pipeline summaries.
- [ ] Back navigation, screen restoration and empty states work.
- [ ] `DEMO DATA` remains visible or readily evident on every analytics screen.
- [ ] No false backend confirmations or fake live updates.

## 11.2 Unit test examples

- [ ] Zero closed deals ⇒ win rate unavailable, not divide-by-zero.
- [ ] One won and one lost deal ⇒ 50% closed-deal win rate.
- [ ] Lead created October 1, first contacted October 2 ⇒ 25 hours, not 1 day assumed without considering times.
- [ ] Open stage started October 20, `as_of` October 31 ⇒ exact stage duration calculated from instants.
- [ ] Sales 180 minutes, Ops 90, Other 30 ⇒ logged-time shares 60%, 30%, 10%.
- [ ] Activity without duration excluded from time numerator/denominator and counted in missing-duration coverage.
- [ ] Two reps with different denominators ⇒ team win rate aggregates wins/losses, not average of rates.
- [ ] Won amount stored in pence ⇒ exact GBP formatting with no float rounding bugs.
- [ ] Incomplete stage history ⇒ stage dwell unavailable with readable state.

## 11.3 Visual and motion

- [ ] 60 FPS target verified on selected physical mid-range Android device in profile/release configuration.
- [ ] No visible jank in deal Hero transitions, pipeline scrolling, animated counters or chart switching.
- [ ] Text is readable at supported accessibility scaling; buttons hit appropriate touch target sizes.
- [ ] Reduced-motion preference disables non-essential movement.
- [ ] Charts can be understood by text labels/legends, not colour alone.
- [ ] No layout overflow on small screens and with long company/customer names.
- [ ] Light/dark text contrast and colour semantics reviewed.

## 11.4 Executive demo acceptance scenario

1. Open PULSE offline and show clearly identified demo-data sales totals and target trend.
2. Open `Median lead-to-win` and identify which pipeline stage has the longest dwell.
3. Open one representative deal, follow its dated stage milestones and total cycle.
4. Open `Sales vs Operations` and inspect the time-category breakdown for its owner.
5. Open team performance and compare activity mix, allocation and outcome without simplistic judgements.
6. State the management question: _Could a better sales-to-operations handoff free selling capacity and shorten conversion time?_

**Pass condition:** The data story is coherent, fully navigable and understandable to non-technical stakeholders without needing developer narration for every number.

---

# 12. Risks, assumptions and mitigations

| Risk                                                | Impact                            | Mitigation                                                                |
| --------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------- |
| Synthetic data is mistaken for live company results | High credibility risk             | Persistent `DEMO DATA` and fixed as-of date; explicit opening explanation |
| Sales conversion definitions are ambiguous          | Misleading management conclusions | KPI glossary, fixed denominators and creation/closure cohort distinctions |
| Operations time is guessed from CRM timestamps      | Incorrect workload claims         | Only logged duration metrics; missing/estimated data labelled             |
| Team rankings reward unequal lead allocation        | Unfair appraisal impression       | Contextual measures, denominator counts, no opaque performance score      |
| Missing stage history makes timeline fictional      | Incorrect bottleneck attribution  | Seed explicit events in v1; require verified history later                |
| Flashy UI impairs usability/performance             | Weak live demo                    | Performance gate, reduced motion, restrained animation                    |
| Too much surface area dilutes polish                | Mediocre execution                | P0/P1/P2 priorities and six-screen scope                                  |
| Monday board shape differs from our assumptions     | Later integration friction        | Canonical schema + mapping adapter, never wire UI to raw column IDs       |
| Real sensitive data ships inside a demo app         | Confidentiality risk              | Fictional records only; sanitisation, no credentials                      |
| Pipeline amount treated as accounting revenue       | Faulty decision-making            | Call it `Booked sales (won deals)`; distinguish realised revenue          |
| Static dataset appears stale                        | Confusion                         | Fixed as-of date and explicit demo mode, no implied live refresh          |

## 12.1 Assumptions to validate before implementation

1. The intended audience is predominantly **sales management and executives**.
2. The initial deliverable is a **demo**, not an employee-facing production CRM.
3. GBP is the default currency; all fixture records are fictional.
4. A representative sales funnel can be modelled as Lead → Qualified → Discovery → Proposal → Negotiation → Won/Lost; final names are configurable.
5. The design will target a standard Android phone first, while preserving iOS compatibility.
6. Salespeople may be responsible for operational duties before or after close; data supports both and the app keeps these distinct.
7. No external service access or Monday account is necessary for the first demo.

---

# 13. Deliverables

1. Flutter project, documented and organised by feature.
2. Shared design system and original reusable widgets.
3. Coherent local JSON fixture and manifest, with generation/validation tooling.
4. Six polished experiences and four-tab navigation.
5. Pure, tested analytics calculators and insight rules.
6. Automated test suite and performance-test checklist/results.
7. Installable Android demo build (actual compilation/signing done in development environment).
8. README with setup, dataset replacement, known limits and future Monday adapter notes.
9. Executive demo script and KPI glossary.

## 13.1 Definition of done

PULSE is complete for v1 only when all of these are true:

- Looks and feels like a premium mobile product.
- Communicates **sales, conversion speed and operational workload** within seconds.
- Calculates its entire information story from a coherent local dataset.
- Remains honest about synthetic data and recorded-versus-unrecorded time.
- Works offline without credentials, backend, or fragile external dependencies.
- Runs smoothly on actual mobile hardware and passes business-calculation tests.
- Can later adopt real Monday data through an adapter without rewriting presentation widgets.

---

# 14. Final product vision

**PULSE should help a CEO move from observation to a better question:**

> Sales are growing, but are we converting as quickly as we could? Which stage is slowing deals? Are our salespeople spending too much time on delivery and support? Which operational handoff would release the most selling capacity?

**Ultimate long-term direction:** A trustworthy decision-making layer on top of the organisation's existing CRM, not a competing CRM that duplicates data entry.

**Immediate end goal:** Deliver a stunning, reliable, offline Flutter executive demonstration that proves the concept using realistic, internally consistent **synthetic** data.

---

# 15. Verified reference materials (for the later integration and Flutter implementation)

- Flutter architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Flutter rendering-performance guide: https://docs.flutter.dev/perf/rendering-performance
- monday platform API basics: https://developer.monday.com/api-reference/docs/basics
- monday API column values: https://developer.monday.com/api-reference/reference/column-values-v2
- monday API items: https://developer.monday.com/api-reference/reference/items
- monday API activity logs (includes preview cautions): https://developer.monday.com/api-reference/reference/activity-logs-new
- monday API time-tracking reference: https://developer.monday.com/api-reference/reference/time-tracking
- monday board export guide: https://support.monday.com/hc/en-us/articles/26989749858578-Export-from-monday-to-Excel

**End of specification v1.0.**
