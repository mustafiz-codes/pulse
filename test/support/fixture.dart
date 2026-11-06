import 'package:pulse/core/analytics/analytics_scope.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/account.dart';
import 'package:pulse/core/models/business_unit.dart';
import 'package:pulse/core/models/dataset_manifest.dart';
import 'package:pulse/core/models/deal.dart';
import 'package:pulse/core/models/deal_stage_event.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:pulse/core/models/insight_scenario.dart';
import 'package:pulse/core/models/lead.dart';
import 'package:pulse/core/models/sales_activity.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/core/models/sales_target.dart';
import 'package:pulse/core/models/sales_user.dart';

final DateTime testAsOf = DateTime.utc(2026, 10, 31, 23, 59, 59);

/// A small, explicit fixture for calculator tests. Unlike the bundled demo
/// fixture, every value here is deliberately easy to verify by hand.
SalesDataset buildDataset({
  List<SalesUser>? users,
  List<Account>? accounts,
  List<Lead>? leads,
  List<Deal>? deals,
  List<DealStageEvent>? stageEvents,
  List<SalesActivity>? activities,
  List<SalesTarget>? targets,
  List<InsightScenario>? scenarios,
  List<BusinessUnit>? businessUnits,
  String timezone = 'UTC',
  DateTime? asOf,
}) {
  final effectiveAsOf = asOf ?? testAsOf;
  return SalesDataset(
    manifest: DatasetManifest(
      schemaVersion: '1.0.0',
      datasetId: 'pulse-test',
      datasetLabel: 'PULSE Test Fixture',
      dataKind: 'synthetic',
      currency: 'GBP',
      timezone: timezone,
      asOf: effectiveAsOf,
      periodStart: DateTime.utc(2025, 11, 1),
      periodEnd: DateTime.utc(2026, 11, 1),
      sourceDescription: 'Hand-built calculator fixture',
    ),
    users: users ?? [testUser('rep_1')],
    accounts: accounts ?? [testAccount('acc_1')],
    leads: leads ?? const [],
    deals: deals ?? const [],
    stageEvents: stageEvents ?? const [],
    activities: activities ?? const [],
    targets: targets ?? const [],
    scenarios: scenarios ?? const [],
    businessUnits: businessUnits ?? testBusinessUnits(),
  );
}

SalesUser testUser(
  String id, {
  String? name,
  String homeUnitId = 'lawyer',
  String jobRole = 'account_executive',
  bool active = true,
}) {
  return SalesUser(
    id: id,
    displayName: name ?? 'Rep ${id.replaceAll('rep_', '')}',
    jobRole: jobRole,
    homeUnitId: homeUnitId,
    active: active,
  );
}

Account testAccount(
  String id, {
  String? name,
  AccountKind kind = AccountKind.business,
  String? sizeBand = '200-500',
}) {
  return Account(
    id: id,
    name: name ?? 'Account $id',
    kind: kind,
    industry: kind == AccountKind.business ? 'Software' : null,
    sizeBand: sizeBand,
  );
}

/// The real five-unit catalogue, so fixtures use the same ids as the app.
List<BusinessUnit> testBusinessUnits() => const [
  BusinessUnit(
    id: 'lawyer',
    label: 'Lawyer',
    products: [
      Product(id: 'visa', label: 'Visa'),
      Product(id: 'jr', label: 'JR'),
      Product(id: 'ar', label: 'AR'),
      Product(id: 'appeal', label: 'Appeal'),
      Product(id: 'ilr', label: 'ILR'),
      Product(id: 'citizenship', label: 'Citizenship'),
    ],
  ),
  BusinessUnit(
    id: 'cloud',
    label: 'Cloud',
    products: [
      Product(id: 'm365_setup', label: 'Microsoft 365 Setup'),
      Product(id: 'cloud_hosting', label: 'Cloud Hosting'),
      Product(id: 'backup_recovery', label: 'Backup & Recovery'),
      Product(id: 'managed_it', label: 'Managed IT'),
      Product(id: 'domain_email', label: 'Domain & Email'),
    ],
  ),
  BusinessUnit(
    id: 'hr',
    label: 'HR',
    products: [
      Product(id: 'payroll_service', label: 'Payroll Service'),
      Product(id: 'hr_consultancy', label: 'HR Consultancy'),
      Product(id: 'employment_contracts', label: 'Employment Contracts'),
      Product(id: 'right_to_work', label: 'Right-to-Work Checks'),
    ],
  ),
  BusinessUnit(
    id: 'accountant',
    label: 'Accountant',
    products: [
      Product(id: 'bookkeeping', label: 'Bookkeeping'),
      Product(id: 'self_assessment', label: 'Self-Assessment'),
      Product(id: 'vat_return', label: 'VAT Return'),
      Product(id: 'year_end_accounts', label: 'Year-End Accounts'),
      Product(id: 'company_formation', label: 'Company Formation'),
    ],
  ),
  BusinessUnit(
    id: 'global',
    label: 'Global',
    products: [
      Product(id: 'sponsor_licence', label: 'Sponsor Licence'),
      Product(id: 'overseas_setup', label: 'Overseas Company Setup'),
      Product(id: 'global_payroll', label: 'Global Payroll'),
      Product(id: 'skilled_worker', label: 'Skilled Worker Sponsorship'),
    ],
  ),
];

Lead testLead({
  required String id,
  required DateTime createdAt,
  String accountId = 'acc_1',
  String ownerId = 'rep_1',
  String productId = 'visa',
  LeadSource source = LeadSource.inbound,
  LeadStatus status = LeadStatus.newLead,
  DateTime? firstContactedAt,
  String? convertedDealId,
}) {
  return Lead(
    id: id,
    accountId: accountId,
    ownerId: ownerId,
    productId: productId,
    source: source,
    status: status,
    createdAt: createdAt,
    firstContactedAt: firstContactedAt,
    convertedDealId: convertedDealId,
  );
}

Deal testDeal({
  required String id,
  required int valueMinor,
  required DealStage stage,
  required DealOutcome outcome,
  required DateTime createdAt,
  String accountId = 'acc_1',
  String ownerId = 'rep_1',
  String? leadId,
  String productId = 'visa',
  String title = 'Test deal',
  DateTime? closedAt,
  DateTime? lastActivityAt,
}) {
  return Deal(
    id: id,
    accountId: accountId,
    ownerId: ownerId,
    productId: productId,
    title: title,
    valueMinor: valueMinor,
    currency: 'GBP',
    stage: stage,
    createdAt: createdAt,
    outcome: outcome,
    leadId: leadId,
    closedAt: closedAt,
    lastActivityAt: lastActivityAt,
  );
}

DealStageEvent testStageEvent({
  required String id,
  required String dealId,
  required DateTime occurredAt,
  required DealStage toStage,
  DealStage? fromStage,
}) {
  return DealStageEvent(
    id: id,
    dealId: dealId,
    occurredAt: occurredAt,
    fromStage: fromStage,
    toStage: toStage,
    source: 'test',
  );
}

SalesActivity testActivity({
  required String id,
  required WorkCategory category,
  required DateTime startedAt,
  String ownerId = 'rep_1',
  int? durationMinutes,
  TimeQuality timeQuality = TimeQuality.logged,
  ActivityType type = ActivityType.call,
  String? dealId,
  String? leadId,
  String subcategory = 'general',
}) {
  return SalesActivity(
    id: id,
    ownerId: ownerId,
    type: type,
    workCategory: category,
    workSubcategory: subcategory,
    startedAt: startedAt,
    durationMinutes: durationMinutes,
    source: 'test',
    timeQuality: timeQuality,
    dealId: dealId,
    leadId: leadId,
  );
}

SalesTarget testTarget({
  required int valueMinor,
  String ownerId = 'rep_1',
  String periodMonth = '2026-10',
}) {
  return SalesTarget(
    ownerId: ownerId,
    periodMonth: periodMonth,
    currency: 'GBP',
    wonValueTargetMinor: valueMinor,
  );
}

AnalyticsScope testScope(
  SalesDataset dataset, {
  ReportingFilter filter = const ReportingFilter(),
  DateTime? start,
  DateTime? end,
}) {
  return AnalyticsScope(
    dataset: dataset,
    filter: filter,
    window: ReportWindow(
      start: start ?? DateTime.utc(2026, 10, 1),
      end: end ?? DateTime.utc(2026, 11, 1),
      label: 'Test window',
    ),
  );
}
