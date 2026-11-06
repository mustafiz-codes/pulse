import 'account.dart';
import 'business_unit.dart';
import 'dataset_manifest.dart';
import 'deal.dart';
import 'deal_stage_event.dart';
import 'enums.dart';
import 'insight_scenario.dart';
import 'lead.dart';
import 'sales_activity.dart';
import 'sales_target.dart';
import 'sales_user.dart';

/// Immutable aggregate of every entity in the bundled demo dataset.
///
/// Indexes are built once at load time so screens and calculators never scan
/// the full collections repeatedly.
class SalesDataset {
  SalesDataset({
    required this.manifest,
    required this.users,
    required this.accounts,
    required this.leads,
    required this.deals,
    required this.stageEvents,
    required this.activities,
    required this.targets,
    required this.scenarios,
    this.businessUnits = const [],
  }) : unitsById = {for (final unit in businessUnits) unit.id: unit},
       productsById = {
         for (final unit in businessUnits)
           for (final product in unit.products) product.id: product,
       },
       unitIdByProductId = {
         for (final unit in businessUnits)
           for (final product in unit.products) product.id: unit.id,
       },
       usersById = {for (final user in users) user.id: user},
       accountsById = {for (final account in accounts) account.id: account},
       leadsById = {for (final lead in leads) lead.id: lead},
       dealsById = {for (final deal in deals) deal.id: deal},
       activitiesById = {
         for (final activity in activities) activity.id: activity,
       },
       stageEventsByDealId = _groupSorted(
         stageEvents,
         (event) => event.dealId,
         (a, b) => a.occurredAt.compareTo(b.occurredAt),
       ),
       activitiesByDealId = _groupSorted(
         activities.where((activity) => activity.dealId != null),
         (activity) => activity.dealId!,
         (a, b) => a.startedAt.compareTo(b.startedAt),
       ),
       activitiesByLeadId = _groupSorted(
         activities.where((activity) => activity.leadId != null),
         (activity) => activity.leadId!,
         (a, b) => a.startedAt.compareTo(b.startedAt),
       ),
       activitiesByOwnerId = _groupSorted(
         activities,
         (activity) => activity.ownerId,
         (a, b) => a.startedAt.compareTo(b.startedAt),
       ),
       dealsByOwnerId = _groupSorted(
         deals,
         (deal) => deal.ownerId,
         (a, b) => a.createdAt.compareTo(b.createdAt),
       ),
       dealsByLeadId = {
         for (final deal in deals)
           if (deal.leadId != null) deal.leadId!: deal,
       },
       targetsByOwnerMonth = {
         for (final target in targets)
           '${target.ownerId}|${target.periodMonth}': target,
       };

  final DatasetManifest manifest;
  final List<SalesUser> users;
  final List<Account> accounts;
  final List<Lead> leads;
  final List<Deal> deals;
  final List<DealStageEvent> stageEvents;
  final List<SalesActivity> activities;
  final List<SalesTarget> targets;
  final List<InsightScenario> scenarios;

  /// Business units in display order, each with its products.
  final List<BusinessUnit> businessUnits;

  final Map<String, BusinessUnit> unitsById;
  final Map<String, Product> productsById;
  final Map<String, String> unitIdByProductId;

  final Map<String, SalesUser> usersById;
  final Map<String, Account> accountsById;
  final Map<String, Lead> leadsById;
  final Map<String, Deal> dealsById;
  final Map<String, SalesActivity> activitiesById;
  final Map<String, List<DealStageEvent>> stageEventsByDealId;
  final Map<String, List<SalesActivity>> activitiesByDealId;
  final Map<String, List<SalesActivity>> activitiesByLeadId;
  final Map<String, List<SalesActivity>> activitiesByOwnerId;
  final Map<String, List<Deal>> dealsByOwnerId;
  final Map<String, Deal> dealsByLeadId;
  final Map<String, SalesTarget> targetsByOwnerMonth;

  List<SalesUser> get activeUsers =>
      users.where((user) => user.active).toList(growable: false);

  /// Unit ids in catalogue order.
  List<String> get unitIds =>
      List.unmodifiable(businessUnits.map((unit) => unit.id));

  /// Unit of a product; empty when the product is unknown (the validator
  /// reports that as an error at load time).
  String unitIdOf(String productId) => unitIdByProductId[productId] ?? '';

  BusinessUnit unitFor(String unitId) => unitsById[unitId]!;

  Product productFor(String productId) => productsById[productId]!;

  SalesUser? userFor(String id) => usersById[id];

  Account? accountFor(String id) => accountsById[id];

  Lead? leadFor(String id) => leadsById[id];

  Deal? dealFor(String id) => dealsById[id];

  List<DealStageEvent> stageEventsFor(String dealId) =>
      stageEventsByDealId[dealId] ?? const <DealStageEvent>[];

  List<SalesActivity> activitiesForDeal(String dealId) =>
      activitiesByDealId[dealId] ?? const <SalesActivity>[];

  List<SalesActivity> activitiesForLead(String leadId) =>
      activitiesByLeadId[leadId] ?? const <SalesActivity>[];

  List<SalesActivity> activitiesForOwner(String ownerId) =>
      activitiesByOwnerId[ownerId] ?? const <SalesActivity>[];

  List<Deal> dealsForOwner(String ownerId) =>
      dealsByOwnerId[ownerId] ?? const <Deal>[];

  Deal? dealForLead(String leadId) => dealsByLeadId[leadId];

  SalesTarget? targetFor(String ownerId, String periodMonth) =>
      targetsByOwnerMonth['$ownerId|$periodMonth'];

  /// Returns the deal stage after the last recorded event, if history exists.
  DealStage? lastRecordedStage(String dealId) {
    final events = stageEventsFor(dealId);
    return events.isEmpty ? null : events.last.toStage;
  }

  factory SalesDataset.fromJson(Map<String, dynamic> json) {
    final manifestJson = json['manifest'];
    if (manifestJson is! Map<String, dynamic>) {
      throw const FormatException('manifest.json must contain an object');
    }
    return SalesDataset(
      manifest: DatasetManifest.fromJson(manifestJson),
      users: _parseList(json, 'users', SalesUser.fromJson),
      accounts: _parseList(json, 'accounts', Account.fromJson),
      leads: _parseList(json, 'leads', Lead.fromJson),
      deals: _parseList(json, 'deals', Deal.fromJson),
      stageEvents: _parseList(
        json,
        'deal_stage_events',
        DealStageEvent.fromJson,
      ),
      activities: _parseList(json, 'activities', SalesActivity.fromJson),
      targets: _parseList(json, 'targets', SalesTarget.fromJson),
      scenarios: _parseList(
        json,
        'insight_scenarios',
        InsightScenario.fromJson,
      ),
      businessUnits: _parseList(json, 'business_units', BusinessUnit.fromJson),
    );
  }

  static List<T> _parseList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = json[key];
    if (raw is! List) {
      throw FormatException('$key.json must contain an array');
    }
    return List<T>.unmodifiable(
      raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('$key.json contains a non-object entry');
        }
        return parse(item);
      }),
    );
  }

  static Map<String, List<T>> _groupSorted<T>(
    Iterable<T> items,
    String Function(T) keyOf,
    int Function(T, T) compare,
  ) {
    final grouped = <String, List<T>>{};
    for (final item in items) {
      grouped.putIfAbsent(keyOf(item), () => <T>[]).add(item);
    }
    for (final list in grouped.values) {
      list.sort(compare);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: List<T>.unmodifiable(entry.value),
    };
  }

  static const Set<String> supportedSchemaVersions = {'1.0.0'};

  static const Set<DealStage> terminalStages = {DealStage.won, DealStage.lost};

  static const List<DealStage> pipelineStages = [
    DealStage.newStage,
    DealStage.qualified,
    DealStage.discovery,
    DealStage.proposal,
    DealStage.negotiation,
  ];
}
