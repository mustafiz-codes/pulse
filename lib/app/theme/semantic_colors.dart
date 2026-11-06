import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import 'app_colors.dart';

Color leadStatusColor(LeadStatus status, PulsePalette palette) =>
    switch (status) {
      LeadStatus.newLead => palette.sky,
      LeadStatus.contacted => palette.violet,
      LeadStatus.qualified => palette.amber,
      LeadStatus.converted => palette.positive,
      LeadStatus.lost => palette.negative,
      LeadStatus.unqualified => palette.textMuted,
    };

Color dealStageColor(DealStage stage, PulsePalette palette) => switch (stage) {
  DealStage.newStage => palette.sky,
  DealStage.qualified => palette.violet,
  DealStage.discovery => palette.teal,
  DealStage.proposal => palette.amber,
  DealStage.negotiation => palette.coral,
  DealStage.won => palette.positive,
  DealStage.lost => palette.negative,
};

Color workCategoryColor(WorkCategory category, PulsePalette palette) =>
    switch (category) {
      WorkCategory.sales => palette.accent,
      WorkCategory.operations => palette.sky,
      WorkCategory.other => palette.violet,
      WorkCategory.unknown => palette.textMuted,
    };

Color outcomeColor(DealOutcome outcome, PulsePalette palette) =>
    switch (outcome) {
      DealOutcome.open => palette.sky,
      DealOutcome.won => palette.positive,
      DealOutcome.lost => palette.negative,
    };

IconData activityIcon(ActivityType type) => switch (type) {
  ActivityType.call => Icons.call_outlined,
  ActivityType.email => Icons.mail_outline_rounded,
  ActivityType.meeting => Icons.groups_outlined,
  ActivityType.demo => Icons.desktop_windows_outlined,
  ActivityType.proposal => Icons.description_outlined,
  ActivityType.negotiation => Icons.handshake_outlined,
  ActivityType.onboarding => Icons.rocket_launch_outlined,
  ActivityType.support => Icons.support_agent_rounded,
  ActivityType.admin => Icons.admin_panel_settings_outlined,
  ActivityType.internalMeeting => Icons.forum_outlined,
  ActivityType.training => Icons.school_outlined,
  ActivityType.other => Icons.more_horiz_rounded,
};

IconData workCategoryIcon(WorkCategory category) => switch (category) {
  WorkCategory.sales => Icons.trending_up_rounded,
  WorkCategory.operations => Icons.settings_suggest_outlined,
  WorkCategory.other => Icons.groups_2_outlined,
  WorkCategory.unknown => Icons.help_outline_rounded,
};

IconData leadSourceIcon(LeadSource source) => switch (source) {
  LeadSource.inbound => Icons.call_received_rounded,
  LeadSource.outbound => Icons.call_made_rounded,
  LeadSource.referral => Icons.people_alt_outlined,
  LeadSource.event => Icons.event_outlined,
  LeadSource.partner => Icons.handshake_outlined,
  LeadSource.website => Icons.language_rounded,
};
