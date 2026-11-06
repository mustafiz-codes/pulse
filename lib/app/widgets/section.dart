import 'package:flutter/material.dart';

import '../../core/analytics/metric_definitions.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'metric_info.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

/// One short screen title. The period and scope live in the header and the
/// filter summary, so titles carry no eyebrow or subtitle.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: palette.textPrimary,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.metricKey,
    this.delta,
    this.footnote,
    this.icon,
    this.accentColor,
    this.onTap,
    this.sparkline,
    this.hero = false,
  });

  final String label;
  final Widget value;
  final String? metricKey;
  final Widget? delta;
  final String? footnote;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? sparkline;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final accent = accentColor ?? palette.accent;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(hero ? 20 : 16),
      gradient: hero
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: palette.isDark ? 0.16 : 0.11),
                palette.surface,
              ],
            )
          : null,
      borderColor: hero
          ? accent.withValues(alpha: palette.isDark ? 0.3 : 0.24)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.textSecondary,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              if (metricKey != null)
                MetricInfoButton(metricKey: metricKey!, dense: true),
            ],
          ),
          SizedBox(height: hero ? 12 : 10),
          value,
          if (sparkline != null) ...[const SizedBox(height: 12), sparkline!],
          if (delta != null || footnote != null) ...[
            const SizedBox(height: 10),
            // Wrap, not Row: on narrow cards the footnote drops below the
            // delta instead of collapsing to an ellipsis.
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (delta != null) delta!,
                if (footnote != null)
                  Text(
                    footnote!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MetricLegend extends StatelessWidget {
  const MetricLegend({
    super.key,
    required this.label,
    required this.color,
    this.value,
  });

  final String label;
  final Color color;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
        if (value != null) ...[
          const SizedBox(width: 5),
          Text(
            value!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class CoverageNote extends StatelessWidget {
  const CoverageNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.tone,
  });

  final String text;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final color = tone ?? palette.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final accent = color ?? palette.sky;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.09 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String metricTitle(String key) => metricDefinitions[key]?.title ?? key;
