import '../models/deal.dart';
import '../models/deal_stage_event.dart';
import '../models/enums.dart';
import '../models/lead.dart';
import '../models/sales_activity.dart';
import '../models/sales_dataset.dart';
import '../models/sales_target.dart';

enum ValidationSeverity { error, warning }

class DataValidationIssue {
  const DataValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.entityId,
  });

  final ValidationSeverity severity;
  final String code;
  final String message;
  final String? entityId;

  @override
  String toString() {
    final id = entityId == null ? '' : ' [$entityId]';
    return '${severity.name.toUpperCase()}$id $code: $message';
  }
}

class DataValidationResult {
  const DataValidationResult({required this.issues});

  final List<DataValidationIssue> issues;

  List<DataValidationIssue> get errors => issues
      .where((issue) => issue.severity == ValidationSeverity.error)
      .toList(growable: false);

  List<DataValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ValidationSeverity.warning)
      .toList(growable: false);

  bool get isValid => errors.isEmpty;
}

class DataValidationException implements Exception {
  const DataValidationException(this.result);

  final DataValidationResult result;

  @override
  String toString() {
    final buffer = StringBuffer('Demo dataset validation failed:');
    for (final issue in result.errors.take(12)) {
      buffer.write('\n- $issue');
    }
    if (result.errors.length > 12) {
      buffer.write('\n- …and ${result.errors.length - 12} more');
    }
    return buffer.toString();
  }
}

class DataValidator {
  const DataValidator();

  DataValidationResult validate(SalesDataset dataset) {
    final issues = <DataValidationIssue>[];
    _validateManifest(dataset, issues);
    _validateCatalogue(dataset, issues);
    _validateUsers(dataset, issues);
    _validateAccounts(dataset, issues);
    _validateLeads(dataset, issues);
    _validateDeals(dataset, issues);
    _validateStageEvents(dataset, issues);
    _validateActivities(dataset, issues);
    _validateTargets(dataset, issues);
    _validateScenarios(dataset, issues);
    return DataValidationResult(issues: List.unmodifiable(issues));
  }

  void _error(
    List<DataValidationIssue> issues,
    String code,
    String message, {
    String? entityId,
  }) {
    issues.add(
      DataValidationIssue(
        severity: ValidationSeverity.error,
        code: code,
        message: message,
        entityId: entityId,
      ),
    );
  }

  void _warning(
    List<DataValidationIssue> issues,
    String code,
    String message, {
    String? entityId,
  }) {
    issues.add(
      DataValidationIssue(
        severity: ValidationSeverity.warning,
        code: code,
        message: message,
        entityId: entityId,
      ),
    );
  }

  void _validateManifest(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final manifest = dataset.manifest;
    if (!SalesDataset.supportedSchemaVersions.contains(
      manifest.schemaVersion,
    )) {
      _error(
        issues,
        'manifest.schema_version',
        'Unsupported schema version "${manifest.schemaVersion}"',
      );
    }
    if (manifest.dataKind != 'synthetic') {
      _error(
        issues,
        'manifest.data_kind',
        'v1 demo data must be synthetic, found "${manifest.dataKind}"',
      );
    }
    if (manifest.currency != 'GBP') {
      _error(
        issues,
        'manifest.currency',
        'v1 supports GBP only, found "${manifest.currency}"',
      );
    }
    if (!manifest.periodStart.isBefore(manifest.periodEnd)) {
      _error(
        issues,
        'manifest.period',
        'period_start must be before period_end',
      );
    }
    if (manifest.asOf.isBefore(manifest.periodStart)) {
      _error(
        issues,
        'manifest.as_of',
        'as_of must be at or after period_start',
      );
    }
    if (manifest.asOf.isAfter(manifest.periodEnd)) {
      _error(
        issues,
        'manifest.as_of',
        'as_of must not be after period_end for this dataset',
      );
    }
  }

  void _validateUsers(SalesDataset dataset, List<DataValidationIssue> issues) {
    final seen = <String>{};
    for (final user in dataset.users) {
      if (!seen.add(user.id)) {
        _error(
          issues,
          'users.duplicate_id',
          'Duplicate user id',
          entityId: user.id,
        );
      }
      if (user.displayName.trim().isEmpty) {
        _error(
          issues,
          'users.display_name',
          'display_name must not be empty',
          entityId: user.id,
        );
      }
      if (!dataset.unitsById.containsKey(user.homeUnitId)) {
        _error(
          issues,
          'users.unknown_home_unit',
          'Unknown home unit "${user.homeUnitId}"',
          entityId: user.id,
        );
      }
    }
  }

  void _validateAccounts(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final seen = <String>{};
    for (final account in dataset.accounts) {
      if (!seen.add(account.id)) {
        _error(
          issues,
          'accounts.duplicate_id',
          'Duplicate account id',
          entityId: account.id,
        );
      }
      if (account.name.trim().isEmpty) {
        _error(
          issues,
          'accounts.name',
          'Account name must not be empty',
          entityId: account.id,
        );
      }
      if (account.kind == AccountKind.individual && account.sizeBand != null) {
        _error(
          issues,
          'accounts.individual_size_band',
          'Individual accounts have no company size band',
          entityId: account.id,
        );
      }
    }
  }

  void _validateCatalogue(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final units = <String>{};
    final products = <String>{};
    for (final unit in dataset.businessUnits) {
      if (!units.add(unit.id)) {
        _error(
          issues,
          'units.duplicate',
          'Duplicate unit id',
          entityId: unit.id,
        );
      }
      for (final product in unit.products) {
        if (!products.add(product.id)) {
          _error(
            issues,
            'products.duplicate',
            'Duplicate product id',
            entityId: product.id,
          );
        }
      }
    }
  }

  void _validateLeads(SalesDataset dataset, List<DataValidationIssue> issues) {
    final seen = <String>{};
    final manifest = dataset.manifest;
    for (final lead in dataset.leads) {
      if (!dataset.productsById.containsKey(lead.productId)) {
        _error(
          issues,
          'products.unknown',
          'Unknown product "${lead.productId}"',
          entityId: lead.id,
        );
      }
      if (!seen.add(lead.id)) {
        _error(
          issues,
          'leads.duplicate_id',
          'Duplicate lead id',
          entityId: lead.id,
        );
      }
      if (!dataset.accountsById.containsKey(lead.accountId)) {
        _error(
          issues,
          'leads.account_ref',
          'Unknown account "${lead.accountId}"',
          entityId: lead.id,
        );
      }
      if (!dataset.usersById.containsKey(lead.ownerId)) {
        _error(
          issues,
          'leads.owner_ref',
          'Unknown owner "${lead.ownerId}"',
          entityId: lead.id,
        );
      }
      if (lead.createdAt.isBefore(manifest.periodStart) ||
          lead.createdAt.isAfter(manifest.asOf)) {
        _error(
          issues,
          'leads.created_at',
          'created_at is outside the dataset window',
          entityId: lead.id,
        );
      }
      final firstContact = lead.firstContactedAt;
      if (firstContact != null) {
        if (firstContact.isBefore(lead.createdAt)) {
          _error(
            issues,
            'leads.first_contacted_at',
            'first_contacted_at is before created_at',
            entityId: lead.id,
          );
        }
        if (firstContact.isAfter(manifest.asOf)) {
          _error(
            issues,
            'leads.first_contacted_at',
            'first_contacted_at is after as_of',
            entityId: lead.id,
          );
        }
      }
      if (lead.status == LeadStatus.converted && lead.convertedDealId == null) {
        _error(
          issues,
          'leads.converted_deal',
          'Converted lead has no converted_deal_id',
          entityId: lead.id,
        );
      }
      if (lead.status != LeadStatus.converted && lead.convertedDealId != null) {
        _error(
          issues,
          'leads.converted_deal',
          'Non-converted lead has a converted_deal_id',
          entityId: lead.id,
        );
      }
      if (lead.convertedDealId != null) {
        final deal = dataset.dealsById[lead.convertedDealId];
        if (deal == null) {
          _error(
            issues,
            'leads.converted_deal_ref',
            'Unknown converted deal "${lead.convertedDealId}"',
            entityId: lead.id,
          );
        } else if (deal.leadId != lead.id) {
          _error(
            issues,
            'leads.converted_deal_ref',
            'Converted deal does not point back to this lead',
            entityId: lead.id,
          );
        }
      }
      if (lead.status == LeadStatus.lost && lead.lostReason == null) {
        _warning(
          issues,
          'leads.lost_reason',
          'Lost lead has no lost_reason',
          entityId: lead.id,
        );
      }
    }
  }

  void _validateDeals(SalesDataset dataset, List<DataValidationIssue> issues) {
    final seen = <String>{};
    final manifest = dataset.manifest;
    for (final deal in dataset.deals) {
      if (!seen.add(deal.id)) {
        _error(
          issues,
          'deals.duplicate_id',
          'Duplicate deal id',
          entityId: deal.id,
        );
      }
      if (!dataset.productsById.containsKey(deal.productId)) {
        _error(
          issues,
          'products.unknown',
          'Unknown product "${deal.productId}"',
          entityId: deal.id,
        );
      }
      final dealLead = deal.leadId == null
          ? null
          : dataset.leadsById[deal.leadId];
      if (dealLead != null && dealLead.productId != deal.productId) {
        _error(
          issues,
          'deals.product_mismatch',
          'Deal product differs from its lead\'s product',
          entityId: deal.id,
        );
      }
      if (!dataset.accountsById.containsKey(deal.accountId)) {
        _error(
          issues,
          'deals.account_ref',
          'Unknown account "${deal.accountId}"',
          entityId: deal.id,
        );
      }
      if (!dataset.usersById.containsKey(deal.ownerId)) {
        _error(
          issues,
          'deals.owner_ref',
          'Unknown owner "${deal.ownerId}"',
          entityId: deal.id,
        );
      }
      if (deal.leadId != null) {
        final lead = dataset.leadsById[deal.leadId];
        if (lead == null) {
          _error(
            issues,
            'deals.lead_ref',
            'Unknown lead "${deal.leadId}"',
            entityId: deal.id,
          );
        } else if (deal.createdAt.isBefore(lead.createdAt)) {
          _error(
            issues,
            'deals.created_at',
            'Deal created before its lead',
            entityId: deal.id,
          );
        }
      }
      if (deal.createdAt.isBefore(manifest.periodStart) ||
          deal.createdAt.isAfter(manifest.asOf)) {
        _error(
          issues,
          'deals.created_at',
          'created_at is outside the dataset window',
          entityId: deal.id,
        );
      }
      if (deal.valueMinor < 0) {
        _error(
          issues,
          'deals.value',
          'Deal value must not be negative',
          entityId: deal.id,
        );
      }
      if (deal.currency != manifest.currency) {
        _error(
          issues,
          'deals.currency',
          'Deal currency does not match manifest',
          entityId: deal.id,
        );
      }
      if (deal.probability != null &&
          (deal.probability! < 0 || deal.probability! > 1)) {
        _error(
          issues,
          'deals.probability',
          'Probability must be between 0 and 1',
          entityId: deal.id,
        );
      }
      final closedAt = deal.closedAt;
      switch (deal.outcome) {
        case DealOutcome.open:
          if (closedAt != null) {
            _error(
              issues,
              'deals.closed_at',
              'Open deal has a closed_at timestamp',
              entityId: deal.id,
            );
          }
          if (deal.stage == DealStage.won || deal.stage == DealStage.lost) {
            _error(
              issues,
              'deals.stage',
              'Open deal is in a terminal stage',
              entityId: deal.id,
            );
          }
          break;
        case DealOutcome.won:
          if (deal.stage != DealStage.won) {
            _error(
              issues,
              'deals.stage',
              'Won deal must have stage "won"',
              entityId: deal.id,
            );
          }
          if (closedAt == null) {
            _error(
              issues,
              'deals.closed_at',
              'Won deal has no closed_at timestamp',
              entityId: deal.id,
            );
          }
          break;
        case DealOutcome.lost:
          if (deal.stage != DealStage.lost) {
            _error(
              issues,
              'deals.stage',
              'Lost deal must have stage "lost"',
              entityId: deal.id,
            );
          }
          if (closedAt == null) {
            _error(
              issues,
              'deals.closed_at',
              'Lost deal has no closed_at timestamp',
              entityId: deal.id,
            );
          }
          break;
      }
      if (closedAt != null) {
        if (closedAt.isBefore(deal.createdAt)) {
          _error(
            issues,
            'deals.closed_at',
            'closed_at is before created_at',
            entityId: deal.id,
          );
        }
        if (closedAt.isAfter(manifest.asOf)) {
          _error(
            issues,
            'deals.closed_at',
            'closed_at is after as_of',
            entityId: deal.id,
          );
        }
      }
    }
  }

  void _validateStageEvents(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final seen = <String>{};
    for (final event in dataset.stageEvents) {
      if (!seen.add(event.id)) {
        _error(
          issues,
          'deal_stage_events.duplicate_id',
          'Duplicate stage event id',
          entityId: event.id,
        );
      }
      final deal = dataset.dealsById[event.dealId];
      if (deal == null) {
        _error(
          issues,
          'deal_stage_events.deal_ref',
          'Unknown deal "${event.dealId}"',
          entityId: event.id,
        );
        continue;
      }
      if (event.occurredAt.isBefore(deal.createdAt)) {
        _error(
          issues,
          'deal_stage_events.occurred_at',
          'Stage event occurred before the deal was created',
          entityId: event.id,
        );
      }
      if (event.occurredAt.isAfter(dataset.manifest.asOf)) {
        _error(
          issues,
          'deal_stage_events.occurred_at',
          'Stage event occurred after as_of',
          entityId: event.id,
        );
      }
      if (deal.closedAt != null && event.occurredAt.isAfter(deal.closedAt!)) {
        _error(
          issues,
          'deal_stage_events.occurred_at',
          'Stage event occurred after the deal closed',
          entityId: event.id,
        );
      }
    }

    for (final deal in dataset.deals) {
      final events = dataset.stageEventsFor(deal.id);
      if (events.isEmpty) {
        _warning(
          issues,
          'deal_stage_events.missing',
          'No stage history is available for this deal',
          entityId: deal.id,
        );
        continue;
      }
      _validateEventSequence(deal, events, issues);
    }
  }

  void _validateEventSequence(
    Deal deal,
    List<DealStageEvent> events,
    List<DataValidationIssue> issues,
  ) {
    if (events.first.fromStage != null) {
      _error(
        issues,
        'deal_stage_events.from_stage',
        'First stage event must have a null from_stage',
        entityId: events.first.id,
      );
    }
    for (var i = 1; i < events.length; i++) {
      final previous = events[i - 1];
      final current = events[i];
      if (current.fromStage != previous.toStage) {
        _error(
          issues,
          'deal_stage_events.sequence',
          'from_stage "${current.fromStage}" does not match previous '
              'to_stage "${previous.toStage}"',
          entityId: current.id,
        );
      }
    }
    final last = events.last;
    if (last.toStage != deal.stage) {
      _error(
        issues,
        'deal_stage_events.final_stage',
        'Last stage event "${last.toStage}" does not match deal stage '
            '"${deal.stage}"',
        entityId: deal.id,
      );
    }
    if (deal.outcome == DealOutcome.open &&
        (last.toStage == DealStage.won || last.toStage == DealStage.lost)) {
      _error(
        issues,
        'deal_stage_events.terminal',
        'Open deal history reaches a terminal stage',
        entityId: deal.id,
      );
    }
    if (deal.outcome == DealOutcome.won && last.toStage != DealStage.won) {
      _error(
        issues,
        'deal_stage_events.terminal',
        'Won deal history does not end at won',
        entityId: deal.id,
      );
    }
    if (deal.outcome == DealOutcome.lost && last.toStage != DealStage.lost) {
      _error(
        issues,
        'deal_stage_events.terminal',
        'Lost deal history does not end at lost',
        entityId: deal.id,
      );
    }
  }

  void _validateActivities(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final seen = <String>{};
    for (final activity in dataset.activities) {
      if (!seen.add(activity.id)) {
        _error(
          issues,
          'activities.duplicate_id',
          'Duplicate activity id',
          entityId: activity.id,
        );
      }
      if (!dataset.usersById.containsKey(activity.ownerId)) {
        _error(
          issues,
          'activities.owner_ref',
          'Unknown owner "${activity.ownerId}"',
          entityId: activity.id,
        );
      }
      if (activity.leadId != null &&
          !dataset.leadsById.containsKey(activity.leadId)) {
        _error(
          issues,
          'activities.lead_ref',
          'Unknown lead "${activity.leadId}"',
          entityId: activity.id,
        );
      }
      if (activity.dealId != null &&
          !dataset.dealsById.containsKey(activity.dealId)) {
        _error(
          issues,
          'activities.deal_ref',
          'Unknown deal "${activity.dealId}"',
          entityId: activity.id,
        );
      }
      if (activity.accountId != null &&
          !dataset.accountsById.containsKey(activity.accountId)) {
        _error(
          issues,
          'activities.account_ref',
          'Unknown account "${activity.accountId}"',
          entityId: activity.id,
        );
      }
      if (activity.startedAt.isBefore(dataset.manifest.periodStart) ||
          activity.startedAt.isAfter(dataset.manifest.asOf)) {
        _error(
          issues,
          'activities.started_at',
          'started_at is outside the dataset window',
          entityId: activity.id,
        );
      }
      final duration = activity.durationMinutes;
      if (duration != null && duration < 0) {
        _error(
          issues,
          'activities.duration',
          'Duration must not be negative',
          entityId: activity.id,
        );
      }
      if (activity.timeQuality == TimeQuality.notRecorded && duration != null) {
        _error(
          issues,
          'activities.time_quality',
          'not_recorded activity has a duration',
          entityId: activity.id,
        );
      }
      if (activity.timeQuality != TimeQuality.notRecorded && duration == null) {
        _warning(
          issues,
          'activities.duration',
          'Activity has no duration but is marked ${activity.timeQuality.name}',
          entityId: activity.id,
        );
      }
    }
  }

  void _validateTargets(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final seen = <String>{};
    final monthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    for (final target in dataset.targets) {
      final key = '${target.ownerId}|${target.periodMonth}';
      if (!seen.add(key)) {
        _error(
          issues,
          'targets.duplicate',
          'Duplicate target for owner and month',
          entityId: key,
        );
      }
      if (!dataset.usersById.containsKey(target.ownerId)) {
        _error(
          issues,
          'targets.owner_ref',
          'Unknown owner "${target.ownerId}"',
          entityId: key,
        );
      }
      if (!monthPattern.hasMatch(target.periodMonth)) {
        _error(
          issues,
          'targets.period_month',
          'period_month must use YYYY-MM',
          entityId: key,
        );
      }
      if (target.wonValueTargetMinor < 0) {
        _error(
          issues,
          'targets.value',
          'Target must not be negative',
          entityId: key,
        );
      }
      if (target.currency != dataset.manifest.currency) {
        _error(
          issues,
          'targets.currency',
          'Target currency does not match manifest',
          entityId: key,
        );
      }
    }
  }

  void _validateScenarios(
    SalesDataset dataset,
    List<DataValidationIssue> issues,
  ) {
    final seen = <String>{};
    for (final scenario in dataset.scenarios) {
      if (!seen.add(scenario.id)) {
        _error(
          issues,
          'insight_scenarios.duplicate_id',
          'Duplicate scenario id',
          entityId: scenario.id,
        );
      }
      if (!scenario.route.startsWith('/')) {
        _error(
          issues,
          'insight_scenarios.route',
          'Scenario route must start with /',
          entityId: scenario.id,
        );
      }
      if (scenario.unitId != null &&
          !dataset.unitIds.contains(scenario.unitId)) {
        _error(
          issues,
          'scenarios.unknown_unit',
          'Unknown unit "${scenario.unitId}"',
          entityId: scenario.id,
        );
      }
      if (scenario.ownerId != null &&
          !dataset.usersById.containsKey(scenario.ownerId)) {
        _error(
          issues,
          'insight_scenarios.owner_ref',
          'Unknown owner "${scenario.ownerId}"',
          entityId: scenario.id,
        );
      }
      if (scenario.focusDealId != null &&
          !dataset.dealsById.containsKey(scenario.focusDealId)) {
        _error(
          issues,
          'insight_scenarios.deal_ref',
          'Unknown focus deal "${scenario.focusDealId}"',
          entityId: scenario.id,
        );
      }
    }
  }
}

extension DealValidationX on Deal {
  bool get isTerminal => stage == DealStage.won || stage == DealStage.lost;
}

extension LeadValidationX on Lead {
  bool get hasFirstContact => firstContactedAt != null;
}

extension SalesActivityValidationX on SalesActivity {
  bool get hasDuration => durationMinutes != null;
}

extension SalesTargetValidationX on SalesTarget {
  String get key => '$ownerId|$periodMonth';
}
