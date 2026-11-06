# PULSE polish: units, light executive UI, animated splash

Date: 2026-11-05
Status: design for approval
Builds on: PULSE v1 (`PULSE_Sales_Command_Centre_PRD_Technical_Spec_v1.0.md`, plan `docs/superpowers/plans/2026-11-04-pulse-v1-completion.md`)

## 1. Intent

The owner is a web frontend developer learning Flutter. PULSE is the practice project they will show their CEO on their own phone, a Samsung Galaxy A26 on Android 16. The goal is for the CEO to come away thinking "this person has really learned Flutter". To get there, the app has to:

- **Look polished and professional:** clean, calm and executive, not a website squeezed onto a phone.
- **Feel native:** smooth motion, a memorable animated opening, and real platform touches.
- **Feel like their company:** the real salespeople's names and the company's real business units and products, even though every number is still mock data.

The CEO knows it is a practice project with invented numbers. Real names on fake figures are explicitly acceptable to the owner.

## 2. Goals

1. Mock data that matches the company: 5 named salespeople, 5 business units, and products within each unit.
2. A clean, light "executive" visual system across the whole app.
3. A compact header, so content starts near the top of the screen.
4. A redesigned Overview: hero band, floating hero card, KPI strip, top performers, and a breakdown by unit.
5. Units visible throughout: deal and lead tags, a unit filter, a by-unit breakdown and a unit detail screen.
6. An animated splash: a heartbeat sweep, then the logo flies into the header.
7. Everything already built keeps working: drill-downs, haptics, Hero, reduce motion, screen-reader text, offline, and small-screen behaviour.

## 3. Non-goals

- No live CRM, network calls, login or editing (unchanged from v1).
- No new chart types beyond the by-unit split bar and what v1 already has.
- No store release, app signing or app-icon redesign. Store-ready launcher icons already exist.
- No change to the KPI formulas themselves (`lib/core/analytics`). They gain a unit dimension, but they don't change meaning.

## 4. Anti-goals (failures even if it "works")

- It still looks busy: outlines on every card, glows, or several accent colours competing.
- The header eats the screen again, or the period chips wrap onto two lines.
- The splash is slow, can't be skipped, plays twice, or flashes a mismatched colour between the native splash and Flutter's first frame.
- Text clips at large font sizes, or the layout breaks at 360 px width. The v1 small-screen tests must still pass.
- It looks stretched or empty on a tablet. The owner will test on an Android tablet next.
- Existing features silently regress: drill-down navigation, the deal value Hero, swipe and long-press lead preview, the workload drill-down, chart scrubbing, or pull-to-reset.

## 5. Constraints

- Flutter 3.47.9, Dart ^3.9.2. Android `compileSdk` and `targetSdk` are pinned to 36 (Android 16). The Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 / Java 17 setup from the template stays.
- The app stays fully offline. The `DEMO DATA` marker stays visible on every analytics screen.
- Currency stays GBP. The as-of date stays 31 Oct 2026, Europe/London. History stays 12 months.
- The dataset stays deterministic. Generate it with `dart run tool/generate_demo_dataset.dart`, then `tool/validate_demo_dataset.dart` must pass with 0 errors.
- Riverpod, go_router and fl_chart stay. The Inter font stays. No new runtime dependency unless it is clearly justified; an animation package is not needed.
- TDD as in v1. `flutter analyze` must be clean, `flutter test` must pass, and the integration test must pass on a device. Goldens and screenshots are regenerated deliberately, not just accepted.
- The owner's rule: **never `git commit` or `git push`** until the owner asks. Staging is fine.

## 6. Decisions

### 6.1 Salespeople (already done)

The generator now has exactly 5 reps. Each keeps one designed edge case:

| id | Name | Built-in case |
|---|---|---|
| rep_01 | Sunny | over target |
| rep_02 | Mamun | biggest October win |
| rep_03 | Irteza | operations-heavy workload story (scenario `operational_workload`) |
| rep_04 | Krishna | March target missing ("Target unavailable") |
| rep_05 | Shahriar | small sample, almost no operational time |

**Home unit** (my call): Sunny → Cloud, Mamun → Lawyer, Irteza → HR, Krishna → Accountant, Shahriar → Global. Each rep sells mostly in their home unit (about 70%) and sometimes in others, so their figures can be compared across units. The pairings are chosen to reinforce the stories: HR is operations-heavy like Irteza, and Global is small like Shahriar's sample.

### 6.2 Business units and products (mock, owner-approved to invent)

| Unit | Products | Deal value range | Data story |
|---|---|---|---|
| Lawyer | Visa, JR (Judicial Review), AR (Administrative Review), Appeal, ILR, Citizenship | £1.5k–£8k; JR at the top | Biggest earner. JR is slow and stalls at Proposal |
| Cloud | Microsoft 365 Setup, Cloud Hosting, Backup & Recovery, Managed IT, Domain & Email | £2k–£12k | Largest open pipeline, longest cycles |
| HR | Payroll Service, HR Consultancy, Employment Contracts, Right-to-Work Checks | £800–£4k | Heavy operational follow-up after close |
| Accountant | Bookkeeping, Self-Assessment, VAT Return, Year-End Accounts, Company Formation | £300–£2.5k | High volume, small value, fast wins |
| Global | Sponsor Licence, Overseas Company Setup, Global Payroll, Skilled Worker Sponsorship | £3k–£15k | New unit with few deals, so small-sample warnings show |

Data model, my calls:

- Every lead and every deal has exactly one product, and every product belongs to exactly one unit. A deal inherits its lead's product.
- Deal titles become "<Product> — <Account name>", e.g. "Visa — Harrow Dental".
- The unit list and product catalogue are bundled data, not hard-coded in widgets. The validator checks every reference.
- **Units replace the abstract "Enterprise / Growth" teams** wherever the app groups or filters by team: the filter, the Team-tab comparison and scenario `team_id`s. A rep's "team" becomes their home unit. Unit totals for deals are counted by the deal's own unit, not the rep's home unit.
- **The Unit filter filters by each record's own unit** (my call). Choosing "Lawyer" shows Lawyer leads and deals, whoever sold them, so Unit detail and "Pipeline filtered to Lawyer" always agree. Consequences:
  - Rep rows and Top performers show each rep's figures within that unit.
  - Targets are per rep, so with a unit filter active the hero card's target bar is replaced by a quiet "No unit targets" note. It is not invented.
  - Workload counts activities by the unit of their linked deal or lead. Unlinked internal time is left out and labelled ("Internal time not assigned to a unit").
  - The `operational_workload` scenario becomes a rep-scoped scenario for Irteza with no unit filter, so its story is unchanged.
- **Customers** (my call): replace the generic account names ("Northwind Logistics") with plausible UK small-business names. Clients for personal immigration products (Visa, ILR, Citizenship, Appeal, AR, JR) are **individuals**, e.g. "Visa — Farhana Ahmed". Accounts gain a `kind` (business / individual), and individuals have no company size. The validator checks both kinds.
- **Realistic money scale** (owner's decision): deal values follow the product ranges above, so a typical month's booked sales land around **£60k–£100k**. Rep targets are rescaled to match, so attainment still varies around 100%. The old hard-coded large October wins and the £150k–£350k outlier deals are removed. Mamun's "biggest October win" stays true within the ranges, e.g. a JR or Global deal, with every other October win kept below it. The figures in the mockups and in 6.5, such as £738,000, are illustrative only.
- Keep roughly today's volumes (about 400 leads, 180 deals and 2,800 activities). The by-unit split should not be uniform: in October, Lawyer should be the largest share and Accountant the smallest by value.
- **Variety of cases.** The dataset must show:
  - a rep well ahead of target and one behind it;
  - a high win rate on very few deals;
  - lost deals, stalled deals, and leads waiting for a first contact;
  - one unit with a strong month and another with a weak one.

### 6.3 Visual system: "light executive"

- **Light is the default theme.** Dark stays available and is restyled to the same structure (my call).
- **Light palette:**
  - Page background: soft grey, about `#F4F5F7`.
  - Cards: white, radius about 16, a very soft shadow, no outlines.
  - Text: navy, about `#0F172A`. Secondary text: slate.
  - **One accent:** blue, about `#2F6FEB`. Status colours are green for up/good, red for down/bad and amber for stalled.
  - The lime brand green appears **only** in the logo mark and the `DEMO` pill.
- No glows, gradients or outlines on ordinary cards. The only gradient is the Overview hero band's soft blue wash.
- Numbers use tabular figures. Headline weights are bold, but secondary labels stay small and quiet.
- **Unit colours:** each unit gets a fixed colour (blue, soft blue, teal, amber, violet) used in the split bar and the unit tags. They must stay distinguishable in both themes.
- **Avatars:** coloured initials next to every person's name (Overview, Team, Pipeline, Leads, details), with each person keeping the same colour everywhere.

### 6.4 Header (every tab)

- **One compact row:** logo tile, "PULSE", the `DEMO` pill, then on the right the period button ("Oct 2026 ▾") and an overflow menu.
- **The overflow menu** holds presentation scenarios, Reset demo and the light/dark toggle (my call). It replaces today's play and sun icons. `docs/DEMO_SCRIPT.md` and the README are updated to match.
- **Under the header,** a one-line segmented period switch: 7D · 30D · Month · Quarter. It must not wrap at 360 px with text at ×1.3.
- **The period button** opens a sheet with the custom date range and the filters: **Unit**, Rep, Source and Stage. This merges today's Filters sheet. When any filter is active, a small summary chip appears under the switch (e.g. "Lawyer · Mamun ✕").
- **Titles:** the big eyebrow, title and subtitle stack is removed. Each tab shows one short title (e.g. "Pipeline").
- **Context line:** the "As of 31 Oct 2026 · Europe/London" context moves into the period sheet or a single quiet line (builder's call), but it must stay discoverable.

### 6.5 Overview layout (top to bottom)

1. **Hero band:** a soft blue wash behind the top of the screen (about `#DCE7FF` → page grey) that holds the header and the period switch.
2. **Floating hero card:** a white card with a soft blue-tinted shadow, sitting on the wash. It contains:
   - "Booked sales this month" (label follows the period);
   - the big centred value (figures illustrative, real scale per 6.2);
   - a delta pill, "▲ £12k vs Sep";
   - a "19 won deals" pill;
   - a thin target progress bar with "100.3% of target · £86k".

   The existing count-up and the info tooltip stay.
3. **KPI strip:** a horizontal, swipeable row of small white cards: Win rate, Lead → win, Open pipeline and Stalled. Each shows its value and delta, and tapping keeps v1's drill-throughs. The strip must have visible affordance that it scrolls; a partly visible next card is enough.
4. **Top performers:** the top 3 reps by booked value, each with an avatar, name, home-unit tag and value. "See all" goes to Team.
5. **By unit:** a split bar across the 5 units, a legend with values, and tapping a unit opens Unit detail (6.7).
6. **Everything else Overview has today,** restyled and in today's order: booked vs target chart, conversion bottleneck, sales vs operations, and so on. Pull-to-reset stays.

### 6.6 Other screens

- **Pipeline, Leads, Team, Workload, Conversion and the detail screens** get the same visual system and header. The way each one works doesn't change.
- **Deal cards and lead rows** show a product · unit tag ("Visa · Lawyer") and the owner's avatar.
- **Team** (my call):
  - The Enterprise/Growth comparison card is **removed**, not regrouped. With one rep per home unit it would only repeat the rep rows, and grouping by deal unit would duplicate Overview's By unit and Unit detail.
  - Team keeps its KPI cards and the rep ranking. Rep rows get avatars and home-unit tags, and reordering keeps its animation.
- **Filters:** every screen respects the unit filter.

### 6.7 Unit detail (new, small)

A screen reached from Overview's By unit. It shows, for the selected period:

- the unit's booked value with its delta;
- won deals;
- open pipeline;
- the top products, ranked by booked value with counts;
- the reps who sold in the unit, with avatars;
- a link to Pipeline pre-filtered to that unit.

Unit targets don't exist in the data, so there is no target ring here.

### 6.8 Animated splash: heartbeat sweep, then the logo flies to the header

- **Native splash** (`flutter_native_splash`, owner's decision): a **plain light screen with no icon**, in the page colour, on every platform. On Android 12+ that means a transparent splash icon, because the system always reserves one. This avoids the logo appearing, vanishing during the heartbeat and reappearing. The native splash colour must match the Flutter intro's first frame exactly, so nothing flashes.
- **Flutter intro,** about 1.8 s in total, once per cold start:
  1. A blue heartbeat line draws left to right across the centre (about 0.5 s).
  2. A soft ping ripples at its peak (about 0.2 s).
  3. The line fades while the logo tile, "PULSE" and "Sales Command Centre" fade and scale in at the centre (about 0.3 s), then hold briefly (about 0.3 s).
  4. The logo tile shrinks and glides into its exact position in the Overview header, as a shared-element / Hero-style flight. At the same time the wordmark fades out and Overview, with its hero band, fades up underneath (about 0.5 s).
- **Tap anywhere** skips straight to the final state.
- **Reduce motion / Remove animations:** no sweep and no flight. Show the logo briefly, or go straight to Overview.
- The intro must not delay data loading. If data isn't ready by the end, the handover waits gracefully on the logo.
- Tests and the integration test must be able to bypass the intro deterministically.

### 6.9 Tablet

At tablet widths, content must not stretch edge to edge. The builder chooses between a centred column with a sensible maximum width and a two-column arrangement for Overview's lower sections, but the screen must look intentional on a 10–11" Android tablet in portrait and landscape.

## 7. Left to the builder

- Exact colour values, spacing, radii and shadow strengths within the direction above.
- Exact animation curves and durations, within the timings above.
- File and JSON shape for units and products, as long as the references are validated.
- How the intro hands over technically: an overlay on the shell, or a route with a Hero to the header logo.
- Where the as-of context line ends up, as long as it stays discoverable.
- Tablet strategy (6.9).

## 8. Success looks like

- On a cold start on the Galaxy A26:
  1. The heartbeat sweep plays.
  2. The logo flies into the header.
  3. A clean, light Overview sits there with £ figures, real names and the 5 units.
- The CEO can tap a unit, a person or a KPI and land somewhere sensible.
- The app looks just as tidy at the largest font size, with animations off, and on the tablet.
- `flutter analyze` is clean, all tests pass, and the integration test passes on the phone.
- `docs/screenshots/` is retaken in the new look.
