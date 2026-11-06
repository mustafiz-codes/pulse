class MetricDefinition {
  const MetricDefinition({
    required this.title,
    required this.definition,
    this.caveat,
  });

  final String title;
  final String definition;
  final String? caveat;
}

const Map<String, MetricDefinition> metricDefinitions = {
  'bookedSales': MetricDefinition(
    title: 'Booked sales value',
    definition:
        'The total value of won deals whose close date falls inside the reporting period.',
    caveat:
        'This is commercial won-deal value, not recognised or collected revenue.',
  ),
  'wonDeals': MetricDefinition(
    title: 'Won deals',
    definition: 'The number of deals marked won and closed inside the period.',
    caveat:
        'Always read alongside the sample size; small samples are volatile.',
  ),
  'winRate': MetricDefinition(
    title: 'Win rate',
    definition:
        'Won deals divided by all deals closed as won or lost inside the period.',
    caveat: 'This is a closed-deal win rate, not a lead conversion rate.',
  ),
  'targetAttainment': MetricDefinition(
    title: 'Target attainment',
    definition:
        'Booked sales value divided by the prorated won-value target for the same owners and dates.',
    caveat:
        'Monthly targets are prorated for partial months. Missing targets show as unavailable, not 0%.',
  ),
  'openPipeline': MetricDefinition(
    title: 'Open pipeline',
    definition:
        'The value of deals still open at the dataset snapshot, after owner, team, source and stage filters.',
    caveat: 'This is not a forecast, weighted pipeline or booked revenue.',
  ),
  'medianLeadToWin': MetricDefinition(
    title: 'Median lead-to-win',
    definition:
        'For won deals with an original lead, the median time from lead creation to deal close.',
    caveat:
        'Deals without a linked lead are excluded and counted in the coverage note.',
  ),
  'medianDealCycle': MetricDefinition(
    title: 'Median deal cycle',
    definition:
        'The median time from deal creation to close for deals won inside the period.',
    caveat: 'This starts at opportunity creation, not at lead creation.',
  ),
  'firstResponse': MetricDefinition(
    title: 'First response time',
    definition:
        'The median time from lead creation to first contact for leads with a recorded first-contact timestamp.',
    caveat:
        'Leads without a timestamp are shown as “Not recorded” and are never treated as zero.',
  ),
  'stageDwell': MetricDefinition(
    title: 'Stage dwell',
    definition:
        'Median time spent in a pipeline stage per visit, from stage entry to the next stage change. Open deals run to the dataset as-of date.',
    caveat:
        'Repeated stage visits count separately. Won and lost stage durations are excluded.',
  ),
  'opsShare': MetricDefinition(
    title: 'Operations share',
    definition:
        'Logged operations minutes divided by all valid logged sales, operations and other minutes.',
    caveat:
        'This is a share of logged activity time, not a share of total working hours.',
  ),
  'dataCompleteness': MetricDefinition(
    title: 'Logged-time coverage',
    definition:
        'Activities with a valid logged duration divided by all eligible activities in the period.',
    caveat:
        'Estimated durations are excluded from the headline and counted separately. Missing time is never assumed to be zero.',
  ),
  'leadConversion': MetricDefinition(
    title: 'Lead-to-customer conversion',
    definition:
        'Leads created in the cohort that have a linked won deal by the dataset as-of date, divided by eligible leads in that cohort.',
    caveat:
        'Recent cohorts are provisional because they have not had the same time to mature.',
  ),
  'leadToOpportunity': MetricDefinition(
    title: 'Lead-to-opportunity',
    definition:
        'Leads created in the cohort that became an opportunity, divided by eligible leads in the cohort.',
    caveat:
        'Open leads may still convert; cohort maturity is shown with the result.',
  ),
  'stalledDeal': MetricDefinition(
    title: 'Stalled deal',
    definition:
        'An open deal whose current stage is older than 14 days, or whose last recorded activity is older than 14 days.',
    caveat:
        'This is a rule-driven review flag, not proof that a deal is at risk.',
  ),
  'salesTime': MetricDefinition(
    title: 'Sales activity time',
    definition:
        'The sum of valid logged minutes classified as sales work in the period.',
    caveat:
        'Only recorded work is counted; the app does not infer unlogged time.',
  ),
  'operationsTime': MetricDefinition(
    title: 'Operations activity time',
    definition:
        'The sum of valid logged minutes classified as operations work, including onboarding, support and administration.',
    caveat:
        'Only recorded work is counted; the app does not infer unlogged time.',
  ),
};
