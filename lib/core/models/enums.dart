import 'package:json_annotation/json_annotation.dart';

enum LeadSource { inbound, outbound, referral, event, partner, website }

enum LeadStatus {
  @JsonValue('new')
  newLead,
  contacted,
  qualified,
  converted,
  lost,
  unqualified,
}

enum DealStage {
  @JsonValue('new')
  newStage,
  qualified,
  discovery,
  proposal,
  negotiation,
  won,
  lost,
}

enum DealOutcome { open, won, lost }

enum WorkCategory { sales, operations, other, unknown }

enum TimeQuality {
  logged,
  estimated,
  @JsonValue('not_recorded')
  notRecorded,
}

enum ActivityType {
  call,
  email,
  meeting,
  demo,
  proposal,
  negotiation,
  onboarding,
  support,
  admin,
  @JsonValue('internal_meeting')
  internalMeeting,
  training,
  other,
}

/// Whether a customer account is a company or a private individual.
enum AccountKind {
  @JsonValue('business')
  business,
  @JsonValue('individual')
  individual,
}
