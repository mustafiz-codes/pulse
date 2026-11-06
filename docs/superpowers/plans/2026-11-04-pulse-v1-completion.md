# PULSE v1 Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every remaining gap between the current PULSE build and PRD v1.0 so the app meets §13.1 Definition of Done.

**Architecture:** The app already has data, analytics, six screens and four-tab navigation (Riverpod + go_router + fl_chart). This plan adds what's missing on top of the existing widgets: motion polish (Hero, haptics, animated reorder), Workload drill-through (P0), accessibility semantics, offline proof, an Android build and the written deliverables. No new architecture layers.

**Tech Stack:** Flutter stable / Dart ^3.9.2, flutter_riverpod 3, go_router 17, fl_chart 1.3, intl, flutter_test, integration_test.

**Spec:** `PULSE_Sales_Command_Centre_PRD_Technical_Spec_v1.0.md` (repo root). Executors read both.

## Global Constraints

- **Do not run `git commit` or `git push`.** Each task ends by staging its files and reporting. The user commits when they choose to (user CLAUDE.md).
- Read-only app: no edits to CRM data, no `Saved to CRM` feedback, no fake live updates (PRD §3.2, §8.5).
- `DEMO DATA` stays visible on every analytics screen (PRD §11.1).
- Zero denominator ⇒ `Not available` / `unavailable`, never `0%`. Missing duration ⇒ unknown, never 0 minutes (PRD §6.3).
- Workload wording: `Share of logged activity time`, not working hours (PRD §4.5).
- Every motion respects `context.reduceMotion` / `context.motion(...)` from `lib/app/theme/app_motion.dart` (PRD §7.2).
- No widget computes a KPI. Formulas live in `lib/core/analytics/` (PRD §8.2).
- No new runtime package dependencies unless a task says so.
- Gate for every task: `flutter analyze` reports no issues and `flutter test` passes.

## Review Focus

1. **Small phone with large text (360×740, textScaler 1.3).** Expect no `RenderFlex overflowed` errors on any of the four tabs. Test added in Task 1.
2. **A filter context with zero activities for a category** (for example a rep with no operations logs). Expect the drill-through sheet to show an empty state rather than crash or show `0 min`. Test added in Task 5.
3. **Reduced motion while a Hero or reorder animation is mid-flight.** Expect transitions to snap with no flight. Tests added in Tasks 3 and 4.
4. **Any code path trying a network call.** Expect the app to boot and render all tabs while any `HttpClient` creation throws. Test added in Task 8.
5. **Rapid double-tap on a deal card** (pushes two detail routes). Expect a single route, and back returns to Pipeline. Test added in Task 3.

---

### Task 0: Baseline green + checkpoint

**Files:**

- Modify: `lib/features/conversion/conversion_screen.dart:36`

Both `test/features/app_shell_test.dart:107` and `integration_test/executive_demo_flow_test.dart` expect the detail title `Conversion analytics`. The PRD calls the screen "Conversion Analytics" (§4). The screen is what needs to change, not the tests.

- [ ] **Step 1:** Run `flutter test test/features/app_shell_test.dart`. Expected: 1 FAIL, `Found 0 widgets with text "Conversion analytics"`.
- [ ] **Step 2:** Change `title: 'Conversion'` to `title: 'Conversion analytics'`.
- [ ] **Step 3:** Run `flutter analyze && flutter test`. Expected: no issues, all 28 pass.
- [ ] **Step 4:** Stage the whole working tree (`git add -A`, after checking that `.gitignore` excludes `build/` and `.dart_tool/`). Report to the user: "Baseline green, ready for first commit." **Stop and wait.** Nothing beyond the scaffold has been committed yet.

---

### Task 1: No clipped KPI content on small screens / large text

**Files:**

- Modify: `lib/app/widgets/section.dart:185-205` (`KpiCard` delta/footnote row)
- Test: `test/app/widgets/kpi_card_test.dart` (create)
- Test: `test/features/small_screen_test.dart` (create)

Problem: `KpiCard` puts `delta` and `footnote` in a single `Row`. At half-width the footnote collapses to an ellipsis ("27 closed…", "14 of 19 w…" in `screenshots/overview.png`).

- [ ] **Step 1: Write failing tests**

```dart
// kpi_card_test.dart
testWidgets('KpiCard footnote is not truncated at 170px width', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: Scaffold(
    body: Center(child: SizedBox(width: 170, child: KpiCard(
      label: 'Win rate',
      value: const Text('70%'),
      delta: const DeltaChip(value: 29, label: '+29 pts'),
      footnote: '27 closed deals in period',
    ))),
  )));
  final paragraph = tester.renderObject<RenderParagraph>(find.text('27 closed deals in period'));
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(tester.takeException(), isNull);
});
```

```dart
// small_screen_test.dart: reuse the pumpApp pattern from app_shell_test.dart
// with physicalSize 360x740 and MediaQuery textScaler TextScaler.linear(1.3).
// For each tab in ['Overview','Leads','Pipeline','Team']: tap the tab, pumpAndSettle,
// scroll to the bottom with tester.drag(find.byType(Scrollable).first, Offset(0, -4000)),
// and expect(tester.takeException(), isNull).
```

Pull `pumpApp` out of `app_shell_test.dart` into `test/support/pump_app.dart`, exporting `Future<GoRouter> pumpApp(WidgetTester, SalesDataset, {String initialLocation, Size size, double textScale})`. Later tasks reuse it.

- [ ] **Step 2:** Run `flutter test test/app/widgets/kpi_card_test.dart test/features/small_screen_test.dart`. Expected: FAIL (`didExceedMaxLines` is true, and/or overflow exceptions).
- [ ] **Step 3:** In `KpiCard`, replace the `Row(delta, footnote)` with a `Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center)`. This puts the footnote on its own line when space is short. The footnote keeps `maxLines: 2`. Fix any other overflow the small-screen test finds in the same task.
- [ ] **Step 4:** Re-run both tests, then the full suite. Expected: PASS.
- [ ] **Step 5:** Re-capture `screenshots/overview.png` on the iPhone 15 simulator and confirm visually that nothing is clipped.
- [ ] **Step 6:** Stage and report.

---

### Task 2: Haptic feedback on meaningful selection

**Files:**

- Create: `lib/app/feedback/haptics.dart`
- Modify: `lib/app/widgets/top_bar.dart` (`FilterChipButton.onTap` wrapper), `lib/app/widgets/filter_bar.dart` (`_SheetChip`, period chips), `lib/app/shell/pulse_shell.dart:38` (`onDestinationSelected`)
- Test: `test/app/feedback/haptics_test.dart`

**Interfaces:**

- Produces: `abstract final class PulseHaptics { static Future<void> selection(); static Future<void> confirm(); }`. `selection` → `HapticFeedback.selectionClick()`. `confirm` → `HapticFeedback.lightImpact()`. Tasks 4 and 5 use these.

- [ ] **Step 1: Write failing test.** Record platform calls with `tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, ...)`. Pump the app, tap the `30 days` chip, and expect the log to contain `MethodCall('HapticFeedback.vibrate', 'HapticFeedbackType.selectionClick')`. Second test: tap the `Leads` nav destination and expect the same call.
- [ ] **Step 2:** Run it. Expected: FAIL (no call recorded).
- [ ] **Step 3:** Implement `PulseHaptics`. Call `PulseHaptics.selection()` inside `FilterChipButton`'s tap handler (one place covers period chips, stage rail, ranking modes and lead status chips), in `_SheetChip`, and in `onDestinationSelected`. Use `PulseHaptics.confirm()` on `Reset demo` (`top_bar.dart:190`). Android and iOS already respect the system haptics setting, so don't add a manual check.
- [ ] **Step 4:** Run the tests and the full suite. Expected: PASS.
- [ ] **Step 5:** Stage and report.

---

### Task 3: Hero card-to-detail transition for deals

**Files:**

- Create: `lib/app/widgets/hero_tags.dart`
- Modify: `lib/features/pipeline/pipeline_screen.dart:334-460` (`_DealCard`), `lib/features/pipeline/deal_detail_screen.dart:73-110` (header `AppCard`)
- Test: `test/features/deal_hero_test.dart`

**Interfaces:**

- Produces: `String dealHeroTag(String dealId) => 'deal-card-$dealId';` plus `Widget PulseHero({required String tag, required Widget child})`. `PulseHero` wraps `Hero` with a `flightShuttleBuilder` that wraps the shuttle in `Material(type: MaterialType.transparency)` (this stops the yellow-underline text flash) and returns the bare `child` when `context.reduceMotion`.

- [ ] **Step 1: Write failing tests**
  - `deal card and detail header share a Hero tag`: pump `/pipeline`, then `expect(find.byWidgetPredicate((w) => w is Hero && w.tag == dealHeroTag(firstOpenDealId)), findsOneWidget)`. Tap the card, pump 50ms, and expect the Hero to be in flight (`find.byType(Hero)` still matches while the route animation runs). `pumpAndSettle`, then expect the detail title.
  - `reduced motion skips Hero flight`: with `MediaQueryData(disableAnimations: true)`, expect `find.byType(Hero)` to find nothing on Pipeline.
  - `double-tap pushes one deal route`: tap the card twice within 10ms, `pumpAndSettle`, tap `Back` once, and expect the Pipeline title `Stage, value and velocity`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Wrap the deal value plus company block in `_DealCard` and the matching block in the detail header with `PulseHero(tag: dealHeroTag(deal.id))`. Guard the push in `_DealCard` with a `_navigating` flag, or check `GoRouter.of(context).state.uri` before pushing, so a double-tap can't push twice. Tags must be unique per screen: if the same deal shows up twice on one screen (stage rail plus list), only the list card gets the Hero.
- [ ] **Step 4:** Run the tests and the full suite. Expected: PASS.
- [ ] **Step 5:** Run on the simulator, open and close 5 deals, and confirm the flight has no flash and the back gesture works.
- [ ] **Step 6:** Stage and report.

---

### Task 4: Animated list changes (Team reorder, Leads/Pipeline filter transitions)

**Files:**

- Create: `lib/app/widgets/animated_reorder_column.dart`
- Modify: `lib/features/team/team_screen.dart:190-210` (rank rows), `lib/features/leads/leads_screen.dart` (lead list under status chips), `lib/features/pipeline/pipeline_screen.dart` (deal list under stage rail)
- Test: `test/app/widgets/animated_reorder_column_test.dart`

**Interfaces:**

- Produces: `class AnimatedReorderColumn extends StatelessWidget { const AnimatedReorderColumn({required List<Object> ids, required Widget Function(BuildContext, int index) itemBuilder, required double itemExtent, Duration duration = AppMotion.standard}); }`. This is a `Stack` of `AnimatedPositioned(key: ValueKey(ids[i]), top: i * itemExtent)`, with height `ids.length * itemExtent` and duration `context.motion(duration)`.

- [ ] **Step 1: Write failing tests**
  - `rows glide to new positions`: pump with ids `['a','b','c']`, then rebuild with `['c','a','b']` at `itemExtent: 60`. After pumping half the duration, the top of `c` is strictly between 0 and 120. After `pumpAndSettle`, it is 0.
  - `reduced motion snaps`: same rebuild under `disableAnimations: true`. After one `pump()`, the top of `c` is 0.
- [ ] **Step 2:** Run them. Expected: FAIL (file missing).
- [ ] **Step 3:** Implement the widget. In `TeamScreen`, replace the `Column` of `_RepRankRow` + dividers with `AnimatedReorderColumn(ids: ranked.map((r) => r.user.id).toList(), itemExtent: <measured _RepRankRow height incl. divider>)`. Fix the row height (`SizedBox(height: …)`) so the extent is exact, and check it under textScale 1.3 using Task 1's small-screen test. In Leads and Pipeline, wrap the filtered list in an `AnimatedSwitcher(duration: context.motion(AppMotion.standard))` keyed on the active filter (`ValueKey(_status)` / `ValueKey(_stage)`) for a crossfade.
- [ ] **Step 4:** Run the tests, the small-screen test and the full suite. Expected: PASS.
- [ ] **Step 5:** Stage and report.

---

### Task 5: Workload segment selection + activity drill-through (P0)

PRD §4.5 requires touch-to-select segment and drill-through to the underlying activities. Neither exists yet.

**Files:**

- Modify: `lib/core/analytics/workload_metrics.dart` (add pure function)
- Modify: `lib/app/widgets/layout.dart:56-170` (`StackedShareBar`, `ShareLegend`)
- Create: `lib/features/workload/widgets/category_activities_sheet.dart`
- Modify: `lib/features/workload/workload_screen.dart:330-340`, `lib/features/team/rep_detail_screen.dart` (same legend → sheet)
- Test: `test/analytics/workload_metrics_test.dart` (extend), `test/features/workload_drilldown_test.dart` (create)

**Interfaces:**

- Consumes: `AnalyticsScope.activitiesInWindow` (`lib/core/analytics/analytics_scope.dart:83`; already filtered by window and owner/team).
- Produces:
  - `List<SalesActivity> activitiesForCategory(AnalyticsScope scope, WorkCategory category)`: activities in the window with `workCategory == category`, **including** missing-duration ones, sorted by `startedAt` descending.
  - `StackedShareBar(..., int? selectedIndex, ValueChanged<int>? onSegmentTap)`: unselected segments dim to alpha 0.35 when `selectedIndex != null`.
  - `ShareLegend(..., int? selectedIndex, ValueChanged<int>? onTap)`: each legend row is an `InkWell` at least 48px tall. This is the accessible non-gesture alternative.
  - `Future<void> showCategoryActivitiesSheet(BuildContext context, {required WorkCategory category, required List<SalesActivity> activities, required SalesDataset dataset})`

- [ ] **Step 1: Write failing tests**
  - Unit test: for a fixture with sales activities of 180 and 90 minutes plus one sales activity with `durationMinutes: null`, expect `activitiesForCategory(scope, WorkCategory.sales).length == 3`, the null-duration activity to be present, and the order to be newest first.
  - Unit test: a rep with no operations activities gives `activitiesForCategory(scope, WorkCategory.operations)` as `isEmpty`.
  - Widget test: pump `/workload`, tap the `Operations` legend row, and expect the sheet header `Operations activities` with a count matching the unit function for the default filter. Each row shows a duration or `Not recorded` (never `0 min`). Tapping a row with a `dealId` pushes `/deals/<id>`.
  - Widget test: with the filter set to a rep who has zero operations activities, the sheet shows `EmptyState` titled `No operations activities logged`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Implement the function, the bar/legend parameters and the sheet. The sheet header shows `<Category> activities · <n>`, with subtitle `Share of logged activity time · missing durations listed but not counted`. Rows show type label, owner, date (`date_format.dart`), duration or `Not recorded`, and an `estimated` pill when `timeQuality == estimated`. Read-only: no action buttons except opening the linked deal or lead. Hold `selectedIndex` as local state in `WorkloadScreen`, call `PulseHaptics.selection()` on tap, and reuse the sheet styling from `deal_detail_screen.dart:415-500`.
- [ ] **Step 4:** Run the tests and the full suite. Expected: PASS.
- [ ] **Step 5:** Stage and report.

---

### Task 6: Chart & ring accessibility semantics + scrubbing check

PRD §11.3: charts must be understandable by text labels, not colour alone. Today only one `Semantics(` exists in `lib/`.

**Files:**

- Modify: `lib/features/overview/widgets/booked_target_chart.dart`, `lib/features/workload/widgets/workload_trend_chart.dart`, `lib/app/widgets/layout.dart` (`StackedShareBar`, `HBar`), `lib/app/widgets/people.dart:125` (`ProgressRing`, `Sparkline`)
- Test: `test/features/chart_semantics_test.dart`

Exact label formats (use the existing `formatPercent`, `formatMoneyMinor` and `formatMinutes` helpers):

- `StackedShareBar`: `"<label> <pct>, …"`, segments joined by `", "`, followed by `" of logged time"` (the caller passes the suffix via a new `String semanticsSuffix` param, default `''`).
- `ProgressRing`: `"<pct> of target"`, or `"Target unavailable"` when `value == null`.
- `BookedTargetChart`: `"Booked sales chart, <n> points, latest <money> against target <money>"`.
- `WorkloadTrendChart`: `"Logged time trend, <n> periods, latest sales <minutes>, operations <minutes>, other <minutes>"`.
- `Sparkline`: wrap in `ExcludeSemantics`. It's decorative because the parent card has the number.

- [ ] **Step 1: Write failing tests.** Use `final handle = tester.ensureSemantics();`, pump `/overview`, and expect `find.bySemanticsLabel(RegExp(r'^Booked sales chart, \d+ points'))` to find one widget and `find.bySemanticsLabel(RegExp(r'of target$'))` to find widgets. Pump `/workload` and expect `find.bySemanticsLabel(RegExp(r'of logged time$'))`. Then `handle.dispose()`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Wrap each chart in `Semantics(container: true, label: …, child: ExcludeSemantics(child: chart))`. Build the label strings in the chart widget from data it already receives; don't compute new metrics.
- [ ] **Step 4:** Scrubbing check (PRD §4.1, touch-and-hold): confirm `BookedTargetChart`'s `LineTouchData` has `handleBuiltInTouches: true` and a tooltip showing period label, booked value and target. If the tooltip is missing, add `getTooltipItems`. Add a widget test: `tester.startGesture` at the chart centre, move 40px, and expect the tooltip text containing `£`. Then `gesture.up()`.
- [ ] **Step 5:** Run the tests and the full suite. Expected: PASS.
- [ ] **Step 6:** Stage and report.

---

### Task 7: Leads swipe quick preview + Overview pull-to-reset (PRD L1, O1)

**Files:**

- Create: `lib/features/leads/widgets/lead_preview_sheet.dart`
- Modify: `lib/features/leads/leads_screen.dart:307-330` (`_LeadRow`), `lib/features/overview/overview_screen.dart:34` (`ListView`)
- Test: `test/features/lead_preview_test.dart`, `test/features/overview_reset_test.dart`

**Interfaces:**

- Produces: `Future<void> showLeadPreviewSheet(BuildContext context, {required Lead lead, required SalesDataset dataset})`

Rules from PRD §4.2: the swipe must not look like it calls or modifies a contact. No phone/email icons, no red delete background. Use a neutral `surfaceAlt` background with a `visibility_outlined` icon and the label `Preview`.

- [ ] **Step 1: Write failing tests**
  - `swipe opens read-only preview`: on `/leads`, `tester.drag(find.byType(_LeadRow).first` (use a `Key('lead-row-<id>')`), `Offset(-200, 0))`, then `pumpAndSettle`. Expect the sheet to show the lead's company name, source, owner, `First response` value or `Not recorded`, and `Open lead`. Expect the row to still be in the list afterwards (not dismissed).
  - `long-press opens the same preview` (non-gesture-heavy alternative).
  - `pull-to-reset restores default filter`: set the `30 days` preset, `tester.fling(find.byType(ListView).first, Offset(0, 400), 1000)`, `pumpAndSettle`. Expect `October 2026` to show, and `reportingFilterProvider` to equal `const ReportingFilter()`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Wrap `_LeadRow` in `Dismissible(key: ..., direction: DismissDirection.endToStart, confirmDismiss: (_) async { await showLeadPreviewSheet(...); return false; })` and add `onLongPress` to its `AppCard`. Wrap the Overview `ListView` in `RefreshIndicator(onRefresh: () async { ref.read(reportingFilterProvider.notifier).reset(); PulseHaptics.confirm(); })`. No artificial delay, no snackbar claiming data was refreshed (PRD §11.1: no fake live updates). The indicator's semantics label is `Reset demo view`.
- [ ] **Step 4:** Run the tests and the full suite. Expected: PASS.
- [ ] **Step 5:** Stage and report.

---

### Task 8: Offline proof + full executive demo integration flow

**Files:**

- Create: `test/features/offline_test.dart`
- Modify: `integration_test/executive_demo_flow_test.dart`

- [ ] **Step 1: Write the offline test.** Write `class _NoNetwork extends HttpOverrides { @override HttpClient createHttpClient(SecurityContext? c) => throw StateError('Network access attempted'); }`. Inside `HttpOverrides.runZoned(() async { ... }, createHttpClient: ...)`, or by setting `HttpOverrides.global`, pump the app with the **real asset data source** (no `salesDatasetProvider` override; use `PulseBootstrap`), visit all four tabs plus `/conversion`, `/workload`, `/deals/deal_0013`, `/leads/<first lead id>` and `/team/<first rep id>`, and expect `tester.takeException()` to be null each time.
- [ ] **Step 2:** Run it. Expected: PASS straight away (the code has no `http` usage). The test is a regression guard; if it fails, fix the cause.
- [ ] **Step 3:** Extend the integration flow to cover PRD §11.4 in order. Overview shows `DEMO DATA`. Tap the conversion bottleneck card and assert `Where momentum is lost` plus a stage name with the longest dwell. Push a deal and assert a timeline milestone. Go to `/workload`, open the `Operations` sheet (Task 5) and assert `Operations activities`. Go to the Team tab, switch ranking to `Win rate` and assert sample-size text (`n =` or `closed`). Finish back on Overview.
- [ ] **Step 4:** Run `open -a Simulator && xcrun simctl boot "iPhone 15"`, then `flutter test integration_test -d "iPhone 15"`. Expected: `All tests passed!`
- [ ] **Step 5:** Stage and report.

---

### Task 9: Android release build (needs user setup)

**Prerequisite, done by the user:** no Android SDK is installed on this machine (`adb` not found). Install Android Studio, or the command-line tools plus `platform-tools`, `build-tools`, an API 34+ platform, and accept licences (`flutter doctor --android-licenses`). `flutter doctor` must show the Android toolchain ✓.

**Files:** possibly `android/app/build.gradle(.kts)` (applicationId `com.wpc.pulse` or confirm the existing one, versionName `1.0.0`).

- [ ] **Step 1:** Run `flutter doctor -v`. Expected: Android toolchain ✓.
- [ ] **Step 2:** Run `flutter build apk --release`. Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`. Debug signing is acceptable for a demo install (PRD §13 item 7). Note the size in the report.
- [ ] **Step 3:** Confirm the main manifest has no INTERNET permission (it currently doesn't; debug and profile manifests have it only for tooling): `grep -c INTERNET android/app/src/main/AndroidManifest.xml` gives `0`.
- [ ] **Step 4:** Install on a device or emulator (`flutter install --release`), switch on airplane mode, cold-start the app, and walk the §11.4 script. Record pass/fail in `docs/PERFORMANCE.md` (Task 10).
- [ ] **Step 5:** Stage any Gradle changes and report.

---

### Task 10: Deliverable docs (README, KPI glossary, demo script, perf checklist)

**Files:**

- Rewrite: `README.md`
- Create: `tool/export_kpi_glossary.dart`, `docs/KPI_GLOSSARY.md` (generated), `docs/DEMO_SCRIPT.md`, `docs/PERFORMANCE.md`
- Move: `screenshots/*.png` → `docs/screenshots/` (update any references)
- Test: `test/tool/kpi_glossary_test.dart`

**Interfaces:**

- Consumes: `metricDefinitions` (`lib/core/analytics/metric_definitions.dart:13`, a `Map<String, MetricDefinition>` with `title`, `definition`, `caveat?`).
- Produces: `String renderKpiGlossary(Map<String, MetricDefinition> defs)` in `lib/core/analytics/kpi_glossary.dart`. Output is markdown: `# PULSE KPI glossary`, then one `## <title>` per entry in map order, the definition paragraph, and `> <caveat>` when present. `tool/export_kpi_glossary.dart` writes the result to `docs/KPI_GLOSSARY.md`.

- [ ] **Step 1: Write failing test.** `renderKpiGlossary(metricDefinitions)` contains `## Booked sales value` and `> This is commercial won-deal value, not recognised or collected revenue.`, and the number of `## ` headings equals `metricDefinitions.length`. Second test: `File('docs/KPI_GLOSSARY.md').readAsStringSync() == renderKpiGlossary(metricDefinitions)`, so the doc can't drift from the code.
- [ ] **Step 2:** Run it. Expected: FAIL.
- [ ] **Step 3:** Implement the renderer and the tool, then run `dart run tool/export_kpi_glossary.dart`.
- [ ] **Step 4:** Write `README.md` with these sections: What PULSE is (demo, synthetic data, honesty rule from the PRD header) · Setup (`flutter pub get`, `dart run build_runner build`, `flutter run`) · Dataset (location, `dart run tool/generate_demo_dataset.dart`, `dart run tool/validate_demo_dataset.dart`, how to replace it) · Architecture (the §8.2 diagram, adjusted to the actual files) · Testing (unit, widget, golden, integration commands) · Known limits (§3.2 list, current-owner attribution, debug-signed APK) · Future Monday adapter (§9.1 steps, `SalesDataSource` swap point at `lib/core/data/sales_data_source.dart`).
- [ ] **Step 5:** Write `docs/DEMO_SCRIPT.md`: a 3–5 minute walkthrough following §11.4 steps 1–6, with exact taps, what to say at each screen, and the closing management question quoted verbatim from §11.4 step 6. Include an opening line stating that the data is synthetic.
- [ ] **Step 6:** Write `docs/PERFORMANCE.md`: a checklist template from §7.3 and §11.3 (device model, build mode, DevTools frame chart notes for Hero, pipeline scroll, counters, chart switching; airplane mode result; large-text result). The user fills in results after profiling.
- [ ] **Step 7:** Run `flutter analyze && flutter test`. Expected: PASS.
- [ ] **Step 8:** Stage and report.

---

### Task 11: Physical-device profiling (user + agent)

Not automatable here, because it needs a physical mid-range Android phone (PRD §7.3).

- [ ] **Step 1 (user):** Connect the device with USB debugging on.
- [ ] **Step 2:** Run `flutter run --profile -d <device>`, open DevTools Performance, and record the Hero open/close ×5, a pipeline list fling, period switching ×5, team ranking switching ×4 and the workload sheet.
- [ ] **Step 3:** For any frame >16.7ms sustained, find the widget (likely candidates: `AnalyticsBundle` recompute in `build`, fl_chart rebuilds) and fix with `select`/memoisation in `lib/core/analytics/analytics_bundle.dart`. Re-measure.
- [ ] **Step 4:** Fill in `docs/PERFORMANCE.md`. Stage and report. v1 Definition of Done (§13.1) is then reviewable.

---

## Spec coverage map

| PRD item                                                               | Task |
| ---------------------------------------------------------------------- | ---- |
| §11.1 all tests green, screens load                                    | 0, 8 |
| §7.3 / §11.3 no clipping, large text                                   | 1    |
| §7.2 haptics                                                           | 2    |
| §4.3 / §4.4 Hero card → detail                                         | 3    |
| §4.6 smooth reorder; §7.2 list changes                                 | 4    |
| §4.5 touch-select segment + drill-through (P0)                         | 5    |
| §11.3 charts readable without colour; §4.1 scrubbing                   | 6    |
| §4.2 swipe preview; §4.1 pull-to-reset                                 | 7    |
| §11.1 offline / no network; §11.4 demo scenario                        | 8    |
| §13 item 7 Android build; §10 E airplane mode                          | 9    |
| §13 items 8–9 README, glossary, demo script; §13 item 6 perf checklist | 10   |
| §7.3 physical device 60 FPS                                            | 11   |

Already done and not in this plan: data contract and validator (§5), analytics calculators (§6), six screens and router (§4), themes (§7.1), presentation scenarios and Reset demo (§8.5), bootstrap error and Retry (§8.4).
