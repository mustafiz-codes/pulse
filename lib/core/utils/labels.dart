import '../models/enums.dart';

extension LeadSourceLabel on LeadSource {
  String get label => switch (this) {
    LeadSource.inbound => 'Inbound',
    LeadSource.outbound => 'Outbound',
    LeadSource.referral => 'Referral',
    LeadSource.event => 'Event',
    LeadSource.partner => 'Partner',
    LeadSource.website => 'Website',
  };
}

extension LeadStatusLabel on LeadStatus {
  String get label => switch (this) {
    LeadStatus.newLead => 'New',
    LeadStatus.contacted => 'Contacted',
    LeadStatus.qualified => 'Qualified',
    LeadStatus.converted => 'Converted',
    LeadStatus.lost => 'Lost',
    LeadStatus.unqualified => 'Unqualified',
  };
}

extension DealStageLabel on DealStage {
  String get label => switch (this) {
    DealStage.newStage => 'New',
    DealStage.qualified => 'Qualified',
    DealStage.discovery => 'Discovery',
    DealStage.proposal => 'Proposal',
    DealStage.negotiation => 'Negotiation',
    DealStage.won => 'Won',
    DealStage.lost => 'Lost',
  };

  bool get isTerminal => this == DealStage.won || this == DealStage.lost;
}

extension DealOutcomeLabel on DealOutcome {
  String get label => switch (this) {
    DealOutcome.open => 'Open',
    DealOutcome.won => 'Won',
    DealOutcome.lost => 'Lost',
  };
}

extension WorkCategoryLabel on WorkCategory {
  String get label => switch (this) {
    WorkCategory.sales => 'Sales',
    WorkCategory.operations => 'Operations',
    WorkCategory.other => 'Other',
    WorkCategory.unknown => 'Unclassified',
  };
}

extension ActivityTypeLabel on ActivityType {
  String get label => switch (this) {
    ActivityType.call => 'Call',
    ActivityType.email => 'Email',
    ActivityType.meeting => 'Meeting',
    ActivityType.demo => 'Demo',
    ActivityType.proposal => 'Proposal',
    ActivityType.negotiation => 'Negotiation',
    ActivityType.onboarding => 'Onboarding',
    ActivityType.support => 'Support',
    ActivityType.admin => 'Admin',
    ActivityType.internalMeeting => 'Internal meeting',
    ActivityType.training => 'Training',
    ActivityType.other => 'Other',
  };
}

extension TimeQualityLabel on TimeQuality {
  String get label => switch (this) {
    TimeQuality.logged => 'Logged',
    TimeQuality.estimated => 'Estimated',
    TimeQuality.notRecorded => 'Not recorded',
  };
}

/// Display label for a business unit id ("lawyer" → "Lawyer", "hr" → "HR").
String unitLabel(String unitId) => switch (unitId) {
  'lawyer' => 'Lawyer',
  'cloud' => 'Cloud',
  'hr' => 'HR',
  'accountant' => 'Accountant',
  'global' => 'Global',
  _ => unitId.isEmpty ? '—' : unitId[0].toUpperCase() + unitId.substring(1),
};

String jobRoleLabel(String role) => switch (role) {
  'account_executive' => 'Account Executive',
  'sales_rep' => 'Sales Representative',
  'sales_manager' => 'Sales Manager',
  _ =>
    role
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' '),
};

String workSubcategoryLabel(String value) => switch (value) {
  'prospecting' => 'Prospecting',
  'follow_up' => 'Follow-up',
  'discovery' => 'Discovery',
  'product_demo' => 'Product demo',
  'proposal' => 'Proposal',
  'negotiation' => 'Negotiation',
  'customer_setup' => 'Customer setup',
  'implementation' => 'Implementation',
  'customer_support' => 'Support',
  'admin_processing' => 'Admin',
  'internal_meeting' => 'Internal meeting',
  'training' => 'Training',
  'unclassified' => 'Unclassified',
  _ => value.replaceAll('_', ' '),
};
