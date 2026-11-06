import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.title,
    this.subtitle,
    this.meta,
    this.timeLabel,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? timeLabel;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
}

class PulseTimeline extends StatelessWidget {
  const PulseTimeline({super.key, required this.entries, this.dense = false});

  final List<TimelineEntry> entries;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    if (entries.isEmpty) {
      return Text(
        'No recorded events.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: dense ? 26 : 32,
                  child: Column(
                    children: [
                      Container(
                        width: dense ? 22 : 26,
                        height: dense ? 22 : 26,
                        decoration: BoxDecoration(
                          color: (entries[i].color ?? palette.accent)
                              .withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (entries[i].color ?? palette.accent)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          entries[i].icon ?? Icons.circle,
                          size: dense ? 11 : 13,
                          color: entries[i].color ?? palette.accent,
                        ),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: palette.border,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == entries.length - 1 ? 0 : (dense ? 16 : 20),
                    ),
                    child: _TimelineContent(entry: entries[i], dense: dense),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.entry, required this.dense});

  final TimelineEntry entry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: dense ? 12.5 : 13.5,
                ),
              ),
            ),
            if (entry.timeLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                entry.timeLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
        if (entry.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            entry.subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        if (entry.meta != null) ...[
          const SizedBox(height: 3),
          Text(
            entry.meta!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textMuted,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
    if (entry.onTap == null) return content;
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}
