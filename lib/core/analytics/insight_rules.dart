import '../utils/currency_format.dart';
import '../utils/date_format.dart';
import '../utils/labels.dart';
import 'analytics_scope.dart';
import 'conversion_metrics.dart';
import 'sales_metrics.dart';
import 'workload_metrics.dart';

enum InsightTone { neutral, attention, positive }

class Insight {
  const Insight({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.tone,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final InsightTone tone;
}

class InsightCalculator {
  const InsightCalculator();

  List<Insight> compute({
    required AnalyticsScope scope,
    required SalesMetrics sales,
    required SalesMetrics previousSales,
    required ConversionMetrics conversion,
    required WorkloadMetrics workload,
    required WorkloadMetrics previousWorkload,
  }) {
    final insights = <Insight>[];

    final slowest = conversion.slowestStage;
    if (slowest != null &&
        slowest.medianDays >= 6 &&
        slowest.sampleCount >= 8) {
      insights.add(
        Insight(
          id: 'slowest_stage',
          title: '${slowest.stage.label} is the slowest stage',
          body:
              'Deals spend a median of ${formatDurationDays(slowest.medianDays)} '
              'in ${slowest.stage.label}, based on ${slowest.sampleCount} stage '
              'visits. It may be worth reviewing what happens before the next step.',
          route: '/conversion',
          tone: InsightTone.attention,
        ),
      );
    }

    final currentResponse = conversion.medianFirstResponseHours;
    final previousResponse = previousSales.medianFirstResponseHours;
    if (currentResponse != null &&
        previousResponse != null &&
        conversion.firstResponseSample >= 20 &&
        previousSales.firstResponseSample >= 20 &&
        currentResponse > previousResponse * 1.2) {
      insights.add(
        Insight(
          id: 'first_response_slowdown',
          title: 'First response is slowing',
          body:
              'Median first response moved from ${formatDurationHours(previousResponse)} '
              'to ${formatDurationHours(currentResponse)} between matched periods.',
          route: '/conversion',
          tone: InsightTone.attention,
        ),
      );
    }

    final opsShare = workload.operationsShare;
    if (!workload.insufficient && opsShare != null && opsShare >= 0.30) {
      insights.add(
        Insight(
          id: 'operations_share',
          title:
              'Operations account for ${formatPercent(opsShare)} of logged time',
          body:
              'Based on ${workload.validActivities} logged activities in the period. '
              'Logged-time coverage is ${formatPercent(workload.coverage ?? 0)}.',
          route: '/workload',
          tone: InsightTone.neutral,
        ),
      );
    }

    if (sales.stalledDeals >= 3) {
      insights.add(
        Insight(
          id: 'stalled_deals',
          title:
              '${sales.stalledDeals} open deals have been in stage for over 14 days',
          body:
              'The pipeline contains ${sales.openDealsCount} open deals worth '
              '${formatMoneyMinor(sales.openPipelineMinor, compact: true)}. '
              'A next-step review may be worth scheduling.',
          route: '/pipeline',
          tone: InsightTone.attention,
        ),
      );
    }

    final currentWinRate = sales.winRate;
    final previousWinRate = previousSales.winRate;
    if (currentWinRate != null &&
        previousWinRate != null &&
        sales.closedDeals >= 15 &&
        previousSales.closedDeals >= 15) {
      final difference = (currentWinRate - previousWinRate) * 100;
      if (difference.abs() >= 5) {
        insights.add(
          Insight(
            id: 'win_rate_change',
            title:
                'Win rate ${difference >= 0 ? 'improved' : 'declined'} by '
                '${difference.abs().toStringAsFixed(0)} points',
            body:
                'Closed-deal win rate moved from ${formatPercent(previousWinRate)} '
                'to ${formatPercent(currentWinRate)} across ${sales.closedDeals} '
                'closed deals.',
            route: '/team',
            tone: difference >= 0
                ? InsightTone.positive
                : InsightTone.attention,
          ),
        );
      }
    }

    if (!workload.insufficient &&
        previousWorkload.operationsShare != null &&
        opsShare != null &&
        (opsShare - previousWorkload.operationsShare!).abs() >= 0.08) {
      final difference = (opsShare - previousWorkload.operationsShare!) * 100;
      insights.add(
        Insight(
          id: 'ops_share_change',
          title:
              'Operations share ${difference >= 0 ? 'rose' : 'fell'} by '
              '${difference.abs().toStringAsFixed(0)} points',
          body:
              'The share of logged operations time moved from '
              '${formatPercent(previousWorkload.operationsShare!)} to '
              '${formatPercent(opsShare)} between matched periods.',
          route: '/workload',
          tone: InsightTone.neutral,
        ),
      );
    }

    return insights.take(4).toList(growable: false);
  }
}
