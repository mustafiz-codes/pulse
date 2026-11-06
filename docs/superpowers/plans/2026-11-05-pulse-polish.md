# PULSE Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn PULSE into a light, executive-looking app that opens with an animated heartbeat splash, has a compact header, and shows the company's 5 business units and their products in realistic mock data.

**Architecture:**
- **Theme:** the existing `PulsePalette` theme extension gets new light values and becomes the default.
- **Splash:** a Flutter intro overlay sits above the router (`MaterialApp.router` `builder:`) and flies the logo onto a `GlobalKey`ed header logo.
- **Units data:** the generator writes a `business_units.json` catalogue, and every lead and deal carries a `product_id`.
- **Unit filter:** `ReportingFilter.unitId` replaces `teamId`, and `AnalyticsScope` filters by each record's own unit.
- **Unit metrics:** a new pure calculator, `unit_metrics.dart`, feeds Overview's By unit section and the new Unit detail screen.

**Tech Stack:** Flutter 3.47.9, Dart ^3.9.2, Riverpod 3, go_router 17, fl_chart 1.3, json_serializable, flutter_native_splash 2.4.

**Spec:** `docs/superpowers/specs/2026-11-05-pulse-polish-design.md`. Also read v1's `PULSE_Sales_Command_Centre_PRD_Technical_Spec_v1.0.md` for unchanged behaviour.

## Global Constraints

- Flutter 3.47.9, Dart ^3.9.2. Android `compileSdk` and `targetSdk` stay 36 (Android 16). The Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 / Java 17 setup stays.
- Fully offline. The `DEMO DATA` marker stays visible on every analytics screen.
- GBP. As-of date 31 Oct 2026, Europe/London. 12 months of history.
- Deterministic dataset. After `dart run tool/generate_demo_dataset.dart`, `dart run tool/validate_demo_dataset.dart` passes with 0 errors.
- Riverpod, go_router, fl_chart and Inter stay. No new runtime dependency.
- TDD. `flutter analyze` clean, `flutter test` green, and the integration test green on a device. Regenerate goldens deliberately: look at the diff before accepting it.
- **Never `git commit` or `git push`** until the owner asks. Every "Commit" step in this plan means `git add` the listed files only.
- **Never use the Fable model** for any subagent.
- **Light palette:**
  - Page background `#F4F5F7`. Cards white, radius 16, soft shadow, no outlines.
  - Text navy `#0F172A`. Accent blue `#2F6FEB`.
  - Hero wash `#DCE7FF` fading to the page colour.
  - Lime brand green only on the logo mark and the `DEMO` pill.
- **Reps and home units:** Sunny→cloud, Mamun→lawyer, Irteza→hr, Krishna→accountant, Shahriar→global. Unit ids are `lawyer`, `cloud`, `hr`, `accountant`, `global`, displayed in that order.
- **Intro:** about 1.8 s, once per cold start. Tap skips it. Reduce motion skips it entirely. Tests can bypass it.

## Review Focus

1. **Resume or re-entry:** after the intro finishes, switching tabs, going back to Overview, or `ref` rebuilds must never replay it (Task 2 test `intro_does_not_replay`).
2. **No header to fly to:** when the app starts on a non-shell route (`PULSE_INITIAL_ROUTE=/deals/deal_0031`), the intro fades out instead of flying and doesn't throw (Task 2 test `intro_without_header_fades`).
3. **Empty unit and period:** unit filter `global` plus 7D gives zero won deals. Every tab shows empty or "—" states with no NaN, no division errors and no overflow (Task 6 test `empty_unit_window_is_safe`).
4. **Longest tag at large text:** the longest tag, "Skilled Worker Sponsorship · Global", and the segmented switch at 360×740 with text ×1.3 don't overflow (Task 7 `unit_tag_test` and Task 9 `small_screen_test`).
5. **Reset clears everything:** Reset demo, from the menu or by pulling down, clears the unit filter as well as period, rep, source and stage (Task 6 test `reset_clears_unit`).

---

### Task 1: Light executive theme as default

**Files:**
- Modify: `lib/app/theme/app_colors.dart`
  - New light values in `PulsePalette.light`.
  - Calmer dark values.
  - New fields `heroWash`, `cardShadow`, `unitColors` (5), `avatarColors` (6).
- Modify: `lib/app/theme/app_theme.dart` (NavigationBar and card themes to match).
- Modify: `lib/app/theme/theme_mode_provider.dart`: `defaultValue: 'light'`.
- Modify: `lib/app/widgets/app_card.dart`: no border by default. Light theme uses a `cardShadow` box shadow; dark uses a 1px `border` at low alpha. `gradient` and `borderColor` remain opt-in.
- Modify: `lib/app/widgets/background.dart`: `PulseBackground({required child, bool heroWash = false})`. Plain `palette.background`. When `heroWash` is true, the top 320 logical px are a vertical gradient from `palette.heroWash` to `palette.background`, with an `AnimatedOpacity` (`context.motion(AppMotion.standard)`).
- Modify: `lib/app/bootstrap.dart`: loading and error `MaterialApp`s use `AppTheme.light()`. `_BootstrapLoadingScreen` is a plain `palette.background` screen that shows a small `CircularProgressIndicator` only after 600 ms.
- Modify: `lib/app/shell/pulse_shell.dart`: `PulseBackground(heroWash: navigationShell.currentIndex == 0, …)`.
- Test: `test/app/theme/light_theme_test.dart`

**Interfaces:**
- Produces:
  - `PulsePalette.heroWash: Color`
  - `PulsePalette.cardShadow: Color`
  - `PulsePalette.unitColors: List<Color>` (length 5)
  - `PulsePalette.avatarColors: List<Color>` (length 6)
  - `PulseBackground.heroWash: bool`
  - App default `ThemeMode.light`

- [ ] **Step 1: Write failing tests** in `test/app/theme/light_theme_test.dart`:
  - `app starts in light theme`: `pumpApp` Overview, then `Theme.of(context).brightness == Brightness.light` and `context.pulse.background == const Color(0xFFF4F5F7)`.
  - `light AppCard has no border and a shadow`: `find.byType(AppCard).first` → its `DecoratedBox` decoration has `border == null` and non-empty `boxShadow`.
  - `palette exposes 5 unit colours and 6 avatar colours`, for both `PulsePalette.light` and `PulsePalette.dark`.
  - `overview shows hero wash, pipeline does not`: find `PulseBackground` with `heroWash: true` on `/overview` and `false` on `/pipeline`.
- [ ] **Step 2: Run** `flutter test test/app/theme/light_theme_test.dart`. Expected: FAIL (dark default, missing fields).
- [ ] **Step 3: Implement** the file changes listed above. In `pump_app.dart`, keep tests that toggle the theme working: the toggle's tooltip text changes in Task 3, not here.
- [ ] **Step 4: Run** `flutter test`. Expected: all pass. The `brand_lockup` golden will differ: inspect `test/goldens/failures/`, then run `flutter test --update-goldens test/goldens/brand_lockup_test.dart` only if the difference is the palette change.
- [ ] **Step 5: Stage** `git add lib/app/theme lib/app/widgets/app_card.dart lib/app/widgets/background.dart lib/app/bootstrap.dart lib/app/shell/pulse_shell.dart test/app/theme test/goldens`

---

### Task 2: Animated splash — heartbeat sweep, logo flies to header

**Files:**
- Modify: `pubspec.yaml`, in the `flutter_native_splash:` block:
  - `color: "#F4F5F7"`, no `image`, and `color_dark: "#F4F5F7"`.
  - `android_12: { color: "#F4F5F7", icon_background_color: "#F4F5F7", image: "assets/branding/splash_blank.png" }`.
- Create: `assets/branding/splash_blank.png`, a 1152×1152 fully transparent PNG (Android 12 always reserves an icon).
- Regenerate: `dart run flutter_native_splash:create`. This rewrites the `android/app/src/main/res/drawable*` and `values*` splash files, and `ios/Runner/Assets.xcassets/LaunchImage*` plus `LaunchScreen.storyboard`.
- Create: `lib/app/splash/pulse_intro.dart`
- Create: `lib/app/splash/intro_controller.dart`
- Modify: `lib/app/widgets/brand.dart`. `BrandLockup(compact: true)` wraps its `PulseMark` in a `KeyedSubtree(key: pulseHeaderLogoKey)` and an `Opacity` that is 0 while `introPhaseProvider == IntroPhase.playing`.
- Modify: `lib/app/pulse_app.dart`. `MaterialApp.router(builder: (context, child) => PulseIntroHost(child: child!))`.
- Modify: `test/support/pump_app.dart`. Add `bool intro = false` and override `introEnabledProvider` with it.
- Test: `test/app/splash/pulse_intro_test.dart`

**Interfaces:**
- Produces (`intro_controller.dart`):
  - `enum IntroPhase { playing, done }`
  - `final introEnabledProvider = Provider<bool>((ref) => !const bool.fromEnvironment('PULSE_SKIP_INTRO'));`
  - `final introPhaseProvider = NotifierProvider<IntroPhaseNotifier, IntroPhase>(…)`. `build()` returns `done` when the intro is disabled, otherwise `playing`. `void finish()` sets `done`; it is idempotent.
  - `final GlobalKey pulseHeaderLogoKey = GlobalKey(debugLabel: 'pulse-header-logo');`
- Produces (`pulse_intro.dart`):
  - `class PulseIntroHost extends ConsumerStatefulWidget { const PulseIntroHost({required Widget child}); }` renders `Stack[child, if playing PulseIntroOverlay]`.
  - `class PulseIntroOverlay`.
  - `const pulseIntroDuration = Duration(milliseconds: 1800);`
  - Keys `ValueKey('pulse-intro')` and `ValueKey('pulse-intro-logo')`.
- **Timeline** (one `AnimationController(duration: pulseIntroDuration)`, with `Interval`s on 0–1):

  | Interval | Phase |
  |---|---|
  | 0.00–0.28 | blue `#2F6FEB` heartbeat path draws left to right (`CustomPainter`, `PathMetric.extractPath`) |
  | 0.28–0.39 | ping circle scales 1→5 and fades |
  | 0.33–0.42 | line fades out |
  | 0.39–0.56 | centred logo tile (70 px) plus "PULSE" plus "Sales Command Centre" fade and scale 0.92→1 |
  | 0.56–0.72 | hold |
  | 0.72–1.00 | logo tile `RectTween` from the centre rect to the global rect of `pulseHeaderLogoKey` (`curve: AppMotion.emphasized`); wordmark fades out; overlay background (`palette.background`) fades 1→0 so Overview shows through |

  When the controller completes, `finish()` runs. If `pulseHeaderLogoKey.currentContext` is null at 0.72, the logo fades in place instead of flying.
- **Skip:** a `GestureDetector(onTap)` on the overlay calls `finish()` immediately.
- **Reduce motion:** if `context.reduceMotion` is true at first build, call `finish()` in a post-frame callback and render nothing.
- **Splash heartbeat path:** points across the screen width `w` at height `h/2`: `(0,0) (0.36w,0) (0.41w,0) (0.44w,-27) (0.49w,29) (0.53w,-15) (0.56w,0) (0.61w,0) (w,0)`, with y relative to the centre.

- [ ] **Step 1: Write failing tests** in `test/app/splash/pulse_intro_test.dart` (all via `pumpApp(..., intro: true)` unless noted):
  - `intro overlay shows on cold start`: `find.byKey(ValueKey('pulse-intro'))` findsOne at `pump()`.
  - `intro finishes after 1.8 s`: `pump(pulseIntroDuration + 50ms)`, then the overlay findsNothing and `introPhaseProvider == done`.
  - `header logo hidden during intro, visible after`: the `Opacity` above `pulseHeaderLogoKey` is 0 at 900 ms and 1 after it finishes.
  - `logo lands on header logo position`: at controller value 0.99 (`pump(1782ms)`), the rect of `ValueKey('pulse-intro-logo')` is within 2 px of the header logo rect.
  - `tap skips intro`: `tap(find.byKey(ValueKey('pulse-intro')))` then `pump()` → the overlay findsNothing.
  - `reduce motion skips intro`: `pumpApp(..., intro: true, disableAnimations: true)` then `pump()` → the overlay findsNothing.
  - `intro_does_not_replay`: after it finishes, go to the Pipeline tab and back to Overview, `pump(2s)` → the overlay findsNothing.
  - `intro_without_header_fades`: `pumpApp(initialLocation: '/deals/deal_0031', intro: true)`, `pumpAndSettle` → no exception and the overlay is gone.
  - `intro disabled by default in tests`: `pumpApp` without `intro` → the overlay findsNothing.
- [ ] **Step 2: Run** `flutter test test/app/splash/pulse_intro_test.dart`. Expected: FAIL (files don't exist).
- [ ] **Step 3: Implement** `intro_controller.dart`, `pulse_intro.dart`, and the `brand.dart`, `pulse_app.dart` and `pump_app.dart` changes per the Interfaces above.
- [ ] **Step 4: Run** `flutter test`. Expected: all pass.
- [ ] **Step 5: Native splash.** Create `splash_blank.png`, for example with `python3 -c "import zlib,struct;…"`, or have Dart's `image` package generate it as a dev-only script in `tool/`. Update `pubspec.yaml` and run `dart run flutter_native_splash:create`. Then `grep -rn "0B1020" android ios` must return nothing.
- [ ] **Step 6: Device check.** Run `flutter run --release -d R5CY33X6ZLW`, force-stop the app and cold-start it. You should see a plain light screen, then the heartbeat, the logo, and the flight into the header, with no flash and no logo blink. Record the result in the ledger.
- [ ] **Step 7: Stage** `git add pubspec.yaml assets/branding/splash_blank.png android/app/src/main/res ios/Runner lib/app/splash lib/app/widgets/brand.dart lib/app/pulse_app.dart test/support/pump_app.dart test/app/splash`

---

### Task 3: Compact header, segmented period switch, period and filter sheet, short titles

**Files:**
- Modify: `lib/app/widgets/top_bar.dart`. `PulseTopBar` is one row: `BrandLockup(compact)`, `DemoDataBadge(dense)`, `Spacer`, `PeriodButton`, `PulseOverflowMenu`. Remove the as-of/GBP row. Replace `PresentationMenuButton`'s icon button with `PulseOverflowMenu`; keep the scenario sheet body as `showPresentationSheet(context, ref)`.
- Modify: `lib/app/shell/pulse_shell.dart`. Delete `ThemeToggleButton`; its action moves into the menu.
- Modify: `lib/app/widgets/filter_bar.dart`:
  - `AnalyticsFilterBar` becomes `PeriodSegmentedControl` plus `FilterSummaryStrip` (active filters only).
  - `showFilterSheet` becomes `showPeriodFilterSheet(context, ref)`, containing the as-of line (`As of 31 Oct 2026 · Europe/London · GBP`), a custom range button, Team (renamed Unit in Task 5), Rep, Source and Stage.
- Modify: `lib/app/widgets/section.dart`. `PageTitle({required String title, Widget? trailing})` takes no eyebrow and no subtitle, and uses `titleLarge`, weight 700.
- Modify every screen's `PageTitle(...)` call:

  | Screen | Title |
  |---|---|
  | overview | `Executive overview` |
  | leads | `Lead intelligence` |
  | pipeline | `Sales pipeline` |
  | team | `Team performance` |
  | conversion | `Conversion analytics` |
  | workload | `Workload` |

  Move each old subtitle's useful facts, if any, into a `SectionHeader` subtitle lower down.
- Modify the tests that reference old copy (see Step 1).
- Test: `test/app/widgets/compact_header_test.dart`

**Interfaces:**
- Produces:
  - `class PeriodButton extends ConsumerWidget`. Its label is `shortWindowLabel(ReportWindow)`: `'Oct 2026'` for the thisMonth preset, `'Last 7 days'`, `'Last 30 days'`, `'Q4 2026'`-style for quarter, or `'1–15 Oct'` for custom. Tooltip `'Period and filters'`.
  - `class PulseOverflowMenu extends ConsumerWidget`. Tooltip `'More'`. `PopupMenuButton` items: `'Presentation scenarios'`, `'Reset demo'`, and `'Dark theme'` / `'Light theme'`.
  - `class PeriodSegmentedControl extends ConsumerWidget`:
    - one-line track with segments `7D`, `30D`, `Month` and `Quarter`;
    - each segment's `Semantics(label: 'Last 7 days' | 'Last 30 days' | 'This month' | 'Quarter', selected: …)`;
    - min height 40;
    - selection calls `PulseHaptics.selection()` and `setPreset`;
    - a custom range shows no segment selected.
  - `String shortWindowLabel(ReportWindow window, PeriodPreset preset)` in `lib/core/utils/date_format.dart`.

- [ ] **Step 1: Write failing tests** in `test/app/widgets/compact_header_test.dart`:
  - `header is a single row under 64 px`: the `PulseTopBar` height is ≤ 64 at 430×932.
  - `segmented switch fits one line at 360x740 x1.3`: no overflow exceptions; all 4 segments share the same `dy`.
  - `period button opens sheet with as-of line and filters`: tap `byTooltip('Period and filters')` → `find.textContaining('As of 31 Oct 2026')`, `find.text('Rep')` and `find.text('Source')`.
  - `overflow menu holds scenarios, reset, theme`: tap `byTooltip('More')` → the 3 items. Tapping `'Dark theme'` makes `Theme.of(...).brightness` dark.
  - `30D segment switches window`: tap `find.bySemanticsLabel('Last 30 days')` → `PeriodButton` shows `'Last 30 days'`.
  - `short titles`: `find.text('Executive overview')` on `/overview`, `find.text('Sales pipeline')` on `/pipeline`.

  Also update the existing tests:

  | Old | New |
  |---|---|
  | `find.text('Performance at a glance')` | `'Executive overview'` |
  | `'Stage, value and velocity'` | `'Sales pipeline'` |
  | `'Outcomes with context'` | `'Team performance'` |
  | `'Where momentum is lost'` | the new conversion section header |
  | `find.text('30 days')` | `find.bySemanticsLabel('Last 30 days')` |
  | `byTooltip('Presentation scenarios')` | open `byTooltip('More')`, then tap the `'Presentation scenarios'` item |
  | `byTooltip('Switch to light theme')` / `'Switch to dark theme'` | the menu items `'Light theme'` / `'Dark theme'` |
  | `find.text('October 2026')` (filter bar label) | `'Oct 2026'` |

  Update them in `integration_test/executive_demo_flow_test.dart` too.
- [ ] **Step 2: Run** `flutter test test/app/widgets/compact_header_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** per Files and Interfaces.
- [ ] **Step 4: Run** `flutter test`. Expected: all pass, including `small_screen_test`.
- [ ] **Step 5: Stage** the changed `lib/app`, `lib/features/*/*_screen.dart`, `lib/core/utils/date_format.dart`, `test` and `integration_test` files.

---

### Task 4: Units, products and account kinds in models, validator and generator

**Files:**
- Create: `lib/core/models/business_unit.dart`:
  - `@JsonSerializable(fieldRename: snake, createToJson: false) class BusinessUnit { id, label, List<Product> products }`
  - `class Product { id, label }`
- Modify: `lib/core/models/enums.dart`. Add `enum AccountKind { business, individual }`.
- Modify: `lib/core/models/account.dart`. Add `required AccountKind kind`.
- Modify: `lib/core/models/lead.dart` and `deal.dart`. Add `required String productId`.
- Modify: `lib/core/models/sales_user.dart`. Rename `teamId` → `homeUnitId` (JSON `home_unit_id`).
- Modify: `lib/core/models/sales_target.dart`. Remove `teamId`.
- Modify: `lib/core/models/insight_scenario.dart`. Rename `teamId` → `unitId` (JSON `unit_id`).
- Modify: `lib/core/models/sales_dataset.dart`:
  - Add `businessUnits`, `unitsById`, `productsById` and `unitIdByProductId`.
  - Add `String unitIdOf(String productId)`, `BusinessUnit unitFor(String unitId)` and `Product productFor(String productId)`.
  - Replace `teamIds` with `List<String> get unitIds`, in catalogue order.
  - Add `'business_units'` to the JSON keys.
- Modify: `lib/core/data/asset_json_data_source.dart` and `test/support/demo_dataset.dart`. Add the `'business_units'` file.
- Modify: `lib/core/data/data_validation.dart`. New error codes:
  - `products.unknown`: a lead or deal `product_id` is not in the catalogue.
  - `deals.product_mismatch`: a linked deal's `product_id` differs from its lead's.
  - `users.unknown_home_unit`
  - `scenarios.unknown_unit`
  - `accounts.individual_size_band`: an individual account has a `size_band`.
  - `products.duplicate`
- Modify: `tool/generate_demo_dataset.dart`:
  - Emit `business_units.json` with the spec 6.2 catalogue.
  - Product ids are snake-case labels: `visa`, `jr`, `ar`, `appeal`, `ilr`, `citizenship`, `m365_setup`, `cloud_hosting`, `backup_recovery`, `managed_it`, `domain_email`, `payroll_service`, `hr_consultancy`, `employment_contracts`, `right_to_work`, `bookkeeping`, `self_assessment`, `vat_return`, `year_end_accounts`, `company_formation`, `sponsor_licence`, `overseas_setup`, `global_payroll`, `skilled_worker`.
  - Add a `homeUnit` field to `UserSpec`, mapped as in Global Constraints. Each lead's unit is the owner's home unit with probability 0.70, otherwise uniform over the other 4. The product is uniform within its unit.
  - Deal `title = '${product.label} — ${account.name}'`. Deals inherit their lead's product.
  - `users.json` gets `home_unit_id`, and `team_id` is removed from users and targets.
  - Scenarios use `unit_id`.
  - **This task keeps today's value model.** Task 5 changes values and stories.
- Modify: `run build_runner` → regenerates the `*.g.dart` files.
- Modify: `test/support/fixture.dart`:
  - `testUser({String homeUnitId = 'lawyer'})`
  - `testLead({String productId = 'visa'})`, `testDeal({String productId = 'visa'})`
  - `testAccount({AccountKind kind = AccountKind.business})`
  - `buildDataset({List<BusinessUnit>? businessUnits})`, defaulting to the full catalogue via `testBusinessUnits()`.
- Modify: `lib/core/analytics/*`, `lib/core/data/repositories/team_repository.dart`, `lib/core/utils/labels.dart` and the UI callers. This is a mechanical rename of `teamId`/`teamIds` → `homeUnitId`/`unitIds`; behaviour change is Task 6. Keep `ReportingFilter.teamId` for now, but it compares against `homeUnitId`.
- Test: `test/data/business_units_test.dart`, plus an extended `test/data/dataset_validation_test.dart`.

**Interfaces:**
- Produces:
  - `BusinessUnit`, `Product` and `AccountKind`.
  - `Lead.productId`, `Deal.productId` and `SalesUser.homeUnitId`.
  - `SalesDataset.unitIdOf(productId) → String`, `unitFor(unitId) → BusinessUnit`, `productFor(productId) → Product` and `unitIds → List<String>`.
  - Fixture `testBusinessUnits()`.

- [ ] **Step 1: Write failing tests:**
  - `business_units_test.dart` `catalogue has 5 units in order with spec products`:

    ```dart
    expect(ds.businessUnits.map((u) => u.id), ['lawyer','cloud','hr','accountant','global']);
    expect(ds.unitFor('lawyer').products.map((p) => p.label),
        ['Visa','JR','AR','Appeal','ILR','Citizenship']);
    expect(ds.unitFor('global').products.map((p) => p.label),
        ['Sponsor Licence','Overseas Company Setup','Global Payroll','Skilled Worker Sponsorship']);
    ```

  - `every lead and deal has a known product; deals match their lead`, over the loaded demo dataset.
  - `deal titles start with product label`: every `deal.title` starts with `'${ds.productFor(deal.productId).label} — '`.
  - `reps have home units`: `{for (u in users) u.displayName: u.homeUnitId}` equals `{'Sunny':'cloud','Mamun':'lawyer','Irteza':'hr','Krishna':'accountant','Shahriar':'global'}`.
  - `home unit share ~70%`: for each rep, the share of their leads in the home unit is between 0.55 and 0.85.
  - Validator unit tests using `buildDataset`: an unknown product → `products.unknown`; a lead/deal product mismatch → `deals.product_mismatch`; an individual with a size band → `accounts.individual_size_band`.
- [ ] **Step 2: Run** `flutter test test/data`. Expected: FAIL.
- [ ] **Step 3: Implement** the models, dataset, validator and generator. Then run `dart run build_runner build --delete-conflicting-outputs`, `dart run tool/generate_demo_dataset.dart` and `dart run tool/validate_demo_dataset.dart`. Expected: `errors: 0`.
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: green and clean. Update the pinned counts in `dataset_validation_test.dart` to the new generator output.
- [ ] **Step 5: Stage** `lib/core`, `tool/generate_demo_dataset.dart`, `assets/data/demo`, `test/support`, `test/data`, and the renamed callers.

---

### Task 5: Realistic money scale, UK customers and data stories

**Files:**
- Modify: `tool/generate_demo_dataset.dart`:
  - **Values:** per-product value ranges in minor units, within the unit ranges of spec 6.2:

    | Unit | Value range | Products |
    |---|---|---|
    | Lawyer | £1.5k–£8k | JR is the top band (£5k–£8k) |
    | Cloud | £2k–£12k | |
    | HR | £800–£4k | |
    | Accountant | £300–£2.5k | |
    | Global | £3k–£15k | |

    Values are rounded to £50. Delete `octoberWinValues` and the £150k–£350k outliers.
  - **Volume and speed by unit** (lead weights per unit): Accountant ×1.5, Lawyer ×1.2, Cloud ×1.0, HR ×0.9, Global ×0.4.
    - Accountant cycle ×0.6 and win probability +0.15.
    - Cloud cycle ×1.5, with most open deals.
    - JR has a ×1.40 dwell at `proposal`, replacing the enterprise/outbound rule.
    - HR post-close activity is operations-weighted (0.75).
  - **October guarantee:** every rep has at least one October win. Mamun's October JR win is £7,900, and every other October win is clamped below £7,900.
  - **Targets:** rescale `baselineTargetMinor` so the October team target is £70k–£95k and each rep's October attainment lands in 0.75–1.35. Sunny is over target (≥1.10) and one rep is below 0.90. Krishna's March target stays missing; Shahriar's Nov and Dec targets stay missing.
  - **Accounts:**
    - About 70 UK small-business names built from two word lists, e.g. "Harrow Dental", "Brick Lane Bakery", "Thames Valley Logistics", with `kind: business`.
    - About 50 individuals built from first and last name lists of common UK/South Asian/European names, with `kind: individual`, `size_band: null` and `industry: null`.
    - Leads for `visa`, `ilr`, `citizenship`, `appeal`, `ar` and `jr` always use individual accounts; every other product uses business accounts.
  - **Scenarios:**
    - `conversion_bottleneck`: description "Lawyer JR deals are dwelling in Proposal.", `unit_id: lawyer`, `stage: proposal`, `focus_deal_id` = an open JR deal in proposal (the generator picks and writes it).
    - `operational_workload`: no `unit_id`, `owner_id: rep_03`.
- Test: `test/data/data_stories_test.dart`

- [ ] **Step 1: Write failing tests** in `data_stories_test.dart`, run against `loadDemoDataset()` and `AnalyticsBundle` for thisMonth:
  - `october booked sales is between £60k and £100k`.
  - `every deal value is inside its unit range`: a map `unitId → (minMinor, maxMinor)` from spec 6.2.
  - `lawyer is the biggest and accountant the smallest October unit by booked value`.
  - `cloud has the largest open pipeline value`.
  - `global has the fewest deals overall`.
  - `Mamun has the single largest October win`.
  - `Sunny is ≥110% of October target and at least one rep is below 90%`.
  - `individual products always sold to individuals`.
  - `JR median proposal dwell exceeds every other product's`, with at least 3 samples.
  - `conversion_bottleneck focus deal is an open JR deal in proposal`.
- [ ] **Step 2: Run** `flutter test test/data/data_stories_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** the generator changes. Regenerate, then validate (0 errors; 5 missing-history warnings are allowed).
- [ ] **Step 4: Run** `flutter test`. Feature tests that pin demo values (e.g. `'27 closed deals in period'`, `'42'`) may fail. Replace each pinned value with the new value only after confirming the UI computes it from the data, not because the number "looks right". List each change in the ledger.
- [ ] **Step 5: Stage** the generator, `assets/data/demo` and the tests.

---

### Task 6: Unit filter semantics and unit metrics

**Files:**
- Modify: `lib/core/analytics/reporting_filter.dart`. Rename `teamId` → `unitId` and `setTeam` → `setUnit`, update `applyScenario(... unitId)`, and make sure `reset()` clears `unitId`.
- Modify: `lib/core/analytics/analytics_scope.dart`:
  - `matchesUser` checks the owner only.
  - `matchesLead` and `matchesDeal` add `unitId == null || dataset.unitIdOf(x.productId) == unitId`.
  - `matchesActivity`: if `unitId` is set, use the unit of `activity.dealId`'s deal, else of `activity.leadId`'s lead, else exclude.
  - `matchingUsers`: if `unitId` is set, active users with at least one lead or deal in that unit; otherwise as today.
- Modify: `lib/core/analytics/target_metrics.dart`. `TargetCoverage` gets `bool get unitFiltered`. When `scope.filter.unitId != null`, return `TargetCoverage(targetMinor: null, includedOwnerMonths: 0, missingOwnerMonths: 0, unitFiltered: true)`.
- Create: `lib/core/analytics/unit_metrics.dart`
- Modify: `lib/core/analytics/analytics_bundle.dart`. Add `final List<UnitPerformance> units`, computed on a scope copy with `unitId: null`, so By unit always shows all 5.
- Modify: `lib/core/data/providers.dart`. Add `unitDetailProvider = Provider.family<UnitDetail, String>`.
- Modify: `lib/core/analytics/team_metrics.dart`. Remove the team-level comparison model and calculation, which used `teamId` groups.
- Modify: `lib/features/workload/workload_screen.dart`. When `filter.unitId != null`, show an `InfoBanner` with 'Internal time not assigned to a unit is excluded.'
- Modify: `lib/app/widgets/filter_bar.dart`. In the sheet section, rename 'Team' → 'Unit', with chips from `dataset.unitIds` using `unitFor(id).label`.
- Modify: `lib/app/widgets/top_bar.dart`. `FilterSummaryStrip` shows the unit label.
- Test: `test/analytics/unit_metrics_test.dart`, `test/analytics/unit_filter_test.dart`

**Interfaces:**
- Produces (`unit_metrics.dart`):

  ```dart
  class UnitPerformance { final String unitId; final String label;
    final int bookedMinor; final int previousBookedMinor; final int wonCount;
    final int openPipelineMinor; final int openCount; }
  class ProductPerformance { final String productId; final String label;
    final int bookedMinor; final int wonCount; final int openCount; }
  class UnitRepContribution { final String userId; final int bookedMinor; final int wonCount; }
  class UnitDetail { final UnitPerformance unit;
    final List<ProductPerformance> products; // sorted bookedMinor desc, then label
    final List<UnitRepContribution> reps; }  // sorted bookedMinor desc, zero-booked reps with open deals included
  class UnitMetricsCalculator {
    List<UnitPerformance> all(AnalyticsScope scope);       // catalogue order
    UnitDetail detail(AnalyticsScope scope, String unitId);
  }
  ```

- Produces: `ReportingFilter.unitId`, `ReportingFilterNotifier.setUnit(String?)`, `TargetCoverage.unitFiltered`, `AnalyticsBundle.units`, and `unitDetailProvider(unitId)`.

- [ ] **Step 1: Write failing tests:**
  - **`unit_filter_test.dart`**, using `buildDataset`:
    - Two reps, a lawyer deal owned by the cloud-home rep, and a cloud deal owned by the lawyer-home rep. With `unitId: 'lawyer'`, `contextDeals` contains only the lawyer deal.
    - `activity linked to lawyer deal included, unlinked excluded under unit filter`.
    - `target coverage is unitFiltered when unit set`.
    - `reset_clears_unit`: `setUnit('hr')` then `reset()` → `unitId == null`.
    - `empty_unit_window_is_safe`: demo dataset with unit `global` and last7Days. The bundle builds, `sales.winRate` is null or finite, and no `units` value is negative.
  - **`unit_metrics_test.dart`:**
    - `all() returns 5 units in catalogue order whose booked sum equals sales.bookedMinor (no unit filter)`.
    - `detail('lawyer') products sorted desc and sum to unit booked`.
    - `bundle.units ignores active unit filter`: still 5 entries with the same values.
- [ ] **Step 2: Run** `flutter test test/analytics`. Expected: FAIL.
- [ ] **Step 3: Implement** per Files and Interfaces.
- [ ] **Step 4: Run** `flutter test` and `flutter analyze`. Expected: green and clean.
- [ ] **Step 5: Stage** `lib/core`, `lib/app/widgets`, `lib/features/workload` and `test/analytics`.

---

### Task 7: Unit detail screen, UnitTag and UserAvatar

**Files:**
- Create: `lib/app/widgets/unit_tag.dart`:
  - `UnitTag({String? unitId, String? productId})`, asserting exactly one is non-null. With `productId` the unit comes from `dataset.unitIdOf(productId)` and the label is `'${product.label} · ${unit.label}'`; with `unitId` alone the label is the unit label.
  - It's a `PulsePill` with the unit colour (`palette.unitColors[catalogueIndex]`) at low alpha, `maxLines: 1`, `overflow: ellipsis`, and a semantics label with the full text.
- Create: `lib/app/widgets/user_avatar.dart`:
  - `UserAvatar({required String userId, double size = 28})` wraps `InitialsAvatar`.
  - Colour is `palette.avatarColors[index % 6]`, where the index is the user's position in `dataset.users`, so it's stable everywhere.
- Create: `lib/features/units/unit_detail_screen.dart`. `UnitDetailScreen({required String unitId})` uses `PulseDetailScaffold(title: unit.label)` and shows, from `unitDetailProvider(unitId)`:
  - the booked value with its delta;
  - won count and open pipeline as KpiCards;
  - 'Top products' rows: label, booked value, `'${won} won · ${open} open'`;
  - 'Sold by' rows: `UserAvatar`, name, booked value; a tap pushes `/team/:id`;
  - a button `'View ${unit.label} pipeline'` that calls `setUnit(unitId)` then `context.go('/pipeline')`.

  An unknown `unitId` shows an `EmptyState('Unit not found')`.
- Modify: `lib/app/router.dart`. Add `GoRoute(path: '/units/:id')` next to `/deals/:id`.
- Test: `test/features/unit_detail_test.dart`, `test/app/widgets/unit_tag_test.dart`

**Interfaces:**
- Consumes: `unitDetailProvider`, `setUnit` (Task 6); `unitFor` and `productFor` (Task 4); `unitColors` and `avatarColors` (Task 1).
- Produces: `UnitTag`, `UserAvatar`, `UnitDetailScreen`, and the route `/units/:id`.

- [ ] **Step 1: Write failing tests:**
  - `unit_tag_test`: `UnitTag(productId: 'skilled_worker')` shows `'Skilled Worker Sponsorship · Global'`; at 200 px width it ellipsizes without overflow and its semantics label is the full text.
  - `user avatar colour is stable`: the same `userId` gives the same colour in two different widgets.
  - `unit detail shows products sorted by booked value`.
  - `view pipeline button applies unit filter`: afterwards `reportingFilterProvider.unitId == 'lawyer'` and the location is `/pipeline`.
  - `unknown unit shows not found`: `/units/nope` → `'Unit not found'`.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all pass.
- [ ] **Step 5: Stage.**

---

### Task 8: Overview redesign

**Files:**
- Modify: `lib/features/overview/overview_screen.dart`. The new order is:
  1. `PageTitle('Executive overview')`
  2. `AnalyticsFilterBar`
  3. `_HeroSalesCard`
  4. `_KpiStrip`
  5. `_TopPerformersCard`
  6. `_ByUnitCard`
  7. Booked vs target chart
  8. What stands out
  9. Needs attention
  10. `_ResponsivePair` (conversion bottleneck, workload)
  11. Provenance

  Remove the old Team snapshot section; its data moves into Top performers.
- **`_HeroSalesCard`:**
  - A white `AppCard` with a blue-tinted shadow (`palette.accent.withValues(alpha: .12)`, blur 24, y 8).
  - Centred content: a label `'Booked sales · ${bundle.window.label}'`, then the `AnimatedNumber` value (size 38, tabular), then a `DeltaChip` and a `PulsePill('${won} won deals')`.
  - Below that, a `_TargetBar`: a 6 px bar with semantics label `'${pct} of target'` (or `'Target unavailable'`, or `'No unit targets'` when `unitFiltered`), and a row with the percentage and the target in £.
  - Keep the info tooltip. Remove the `ProgressRing` from this card.
- **`_KpiStrip`:**
  - A horizontal `ListView` of height 112, with 132 px wide KpiCards for Win rate, Median lead-to-win, Open pipeline and Stalled.
  - Keep v1's onTaps (stalled → `/pipeline`).
  - Padding is chosen so a partial fourth card shows at 360 px.
  - `Semantics(label: 'Key metrics, swipe for more')`.
- **`_TopPerformersCard`:** `bundle.team.ranked(RankingMode.booked).take(3)` rows of `UserAvatar`, name, `UnitTag(unitId: user.homeUnitId)` and value. 'See all' calls `context.go('/team')`, and a row tap pushes `/team/:id`.
- **`_ByUnitCard`:** `StackedShareBar` over `bundle.units`, coloured by `palette.unitColors[i]`, plus a `ShareLegend` with values. A tap pushes `'/units/$unitId'`. A selected unit filter is highlighted with `selectedIndex`.
- Test: `test/features/overview_redesign_test.dart`; update `overview_kpi_nav_test.dart` and `chart_semantics_test.dart`.

**Interfaces:**
- Consumes: `UnitTag`, `UserAvatar`, `/units/:id` (Task 7); `bundle.units`, `TargetCoverage.unitFiltered` (Task 6).

- [ ] **Step 1: Write failing tests:**
  - `hero card shows booked value centred with won pill and target bar`: `find.textContaining('won deals')`, plus `bySemanticsLabel(RegExp(r'of target$'))`.
  - `unit filter replaces target bar with No unit targets`: `setUnit('lawyer')` → `bySemanticsLabel('No unit targets')`.
  - `KPI strip scrolls horizontally and keeps drill-throughs`: drag the strip left; tap `'Open pipeline'` → `PipelineScreen`.
  - `top performers lists 3 reps with avatars and unit tags`: 3 `UserAvatar`s; the first name equals `bundle.team.ranked(RankingMode.booked).first`'s name.
  - `by unit shows all 5 units and opens unit detail`: tap the `'Lawyer'` legend item → `find.byType(UnitDetailScreen)`.
  - Update `overview_kpi_nav_test` to use the strip.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all pass.
- [ ] **Step 5: Stage.**

---

### Task 9: Units and avatars across Pipeline, Leads, Team and details

**Files:**
- Modify:
  - `pipeline_screen.dart` `_DealCard`: `UnitTag(productId)` under the title, and the owner shown as `UserAvatar` plus name.
  - `leads_screen.dart` rows and `lead_preview_sheet.dart`: `UnitTag`.
  - `deal_detail_screen.dart` and `lead_detail_screen.dart` headers: `UnitTag`.
  - `rep_detail_screen.dart` header: `UserAvatar` plus home-unit `UnitTag`.
  - `team_screen.dart`: remove the 'Team comparison' section and its widgets. `_RepRankRow` gets a `UserAvatar` and `UnitTag(unitId: homeUnitId)`. Recompute the `itemExtent` formula if the row grows, keeping v1's `MediaQuery.textScalerOf` approach.
- Test: `test/features/unit_tags_test.dart`; extend `test/features/small_screen_test.dart`.

- [ ] **Step 1: Write failing tests:**
  - `deal cards and lead rows carry unit tags`.
  - `pipeline filtered to lawyer shows only lawyer tags`: every visible `UnitTag` text ends with `· Lawyer`.
  - `team tab has no Team comparison section`: `find.text('Team comparison')` findsNothing.
  - `small_screen_test`: Pipeline, Leads, Team and `/units/global` at 360×740 ×1.3 with no overflow.
- [ ] **Step 2: Run** the tests. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all pass, including `team_reorder_test` and `deal_hero_test`.
- [ ] **Step 5: Stage.**

---

### Task 10: Tablet layout

**Files:**
- Create: `lib/app/widgets/content_width.dart`. `PulseContentWidth({required Widget child, double maxWidth = 720})` is `Align(topCenter)` plus `ConstrainedBox`.
- Modify: `lib/app/shell/pulse_shell.dart`. Wrap the `Column` of header and navigationShell in `PulseContentWidth`, while the background wash stays full width.
- Modify: `PulseDetailScaffold`. Wrap its body the same way.
- Modify: `lib/features/overview/overview_screen.dart`. At content width ≥ 680, the booked vs target chart and What stands out sit side by side via the existing `_ResponsivePair`.
- Test: `test/features/tablet_layout_test.dart`

- [ ] **Step 1: Write failing tests** at sizes 1200×800 (landscape) and 800×1280 (portrait):
  - `hero card width ≤ 720`;
  - `no overflow on all 4 tabs and /units/lawyer`;
  - `NavigationBar spans full width`.
- [ ] **Step 2: Run.** Expected: FAIL (the card is 1200 wide).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all pass.
- [ ] **Step 5: Stage.**

---

### Task 11: Docs, goldens, screenshots and the integration demo path

**Files:**
- Modify: `integration_test/executive_demo_flow_test.dart`. Use the new header menu and titles; add steps for the unit legend → Unit detail → 'View Lawyer pipeline' → deal; keep the intro disabled via the provider override.
- Modify: `docs/DEMO_SCRIPT.md`:
  - new menu location ('⋯ → Reset demo');
  - the splash moment as step 0;
  - the By unit → Lawyer step;
  - realistic money figures read from the app;
  - fix v1's step-4 "Back to Overview" wording, a deferred minor from v1.
- Modify: `README.md`. Units and products, the 5 reps, the light default, `PULSE_SKIP_INTRO`, and the `business_units.json` file in the dataset list.
- Modify: `docs/KPI_GLOSSARY.md`, regenerated via `dart run tool/export_kpi_glossary.dart` if definitions changed.
- Regenerate: `docs/screenshots/{overview,pipeline,workload,team}.png` from the iPhone 15 simulator (`flutter run -d 2B2A4DEB-E6C9-4774-9FC7-54AC3FB61469 --dart-define=PULSE_SKIP_INTRO=true` plus `xcrun simctl io booted screenshot`), and add `units.png`.
- Golden: `brand_lockup` rebaselined if Task 1 or 2 changed it, with the diff inspected.

- [ ] **Step 1: Update** the integration test, then run `flutter test integration_test -d 2B2A4DEB-E6C9-4774-9FC7-54AC3FB61469`. Expected: PASS.
- [ ] **Step 2: Update** the docs and screenshots.
- [ ] **Step 3: Run** `flutter analyze && flutter test`. Expected: clean and green.
- [ ] **Step 4: Stage.**

---

### Task 12: Device verification on the Galaxy A26 (owner present)

This is a manual task. Record results in `docs/PERFORMANCE.md` (Device table: SM A266B, Android 16).

- [ ] **Step 1: Release build** with `flutter run --release -d R5CY33X6ZLW`. Cold-start ×3 (force-stop between runs): no flash, no logo blink, intro ≤ 2 s, and a tap skips it.
- [ ] **Step 2:** Settings → Accessibility → Remove animations: no intro, Overview appears directly.
- [ ] **Step 3:** Largest font and bold text: Overview, the strip, unit tags, Unit detail and Team have no clipping.
- [ ] **Step 4:** Work through `docs/DEMO_SCRIPT.md` end to end in airplane mode.
- [ ] **Step 5: Profile build.** `flutter run --profile` with DevTools: intro and Overview scroll, worst frame noted.
- [ ] **Step 6:** Turn any finding into a failing test, fix it RED→GREEN, and re-run. Stage.
